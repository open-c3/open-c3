package api::cmdbmanage::idcnode;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;
use Digest::MD5;
use Encode qw(decode encode);
use OPENC3::Crypt;

my @cryptcol = qw( secretkey );
my $crypt; BEGIN{ $crypt = OPENC3::Crypt->new(); };

=pod

CMDB/资源/IDC节点/获取列表

=cut

my @rescol = qw( serial_number asset_number resource_type sub_type brand model usage status city rack_column rack_number rack_start_position rack_end_position warranty_start_date warranty_end_date gpu gpu_model gpu_specification cpu_model cpu_frequency memory_channel_count memory_slot_count memory_specification memory_count non_raid_disk_type non_raid_disk_size non_raid_disk_count non_raid_disk_capacity raid_type raid_disk_type raid_disk_size raid_disk_count raid_disk_capacity raid_card_model raid_card_count raid_card_bandwidth network_card_details public_ip private_ip server_name operating_system_type operating_system_version operating_system_bit out_of_band_management_mac out_of_band_management_ip alarm_recipient remarks purchase_time purchaser purchase_contract_number purchase_price invoice_number capitalization_date resource_display_name edit_user edit_time data_center_area memory_size cpu_physical_count cpu_cores_per_chip instance_type product_owner ops_owner department );

my @needfulcol = qw( asset_number server_name resource_type private_ip operating_system_type status city data_center_area memory_size cpu_physical_count cpu_cores_per_chip );

get '/cmdbmanage/resource/idcnode' => sub {
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my @col = ( 'id', @needfulcol, 'edit_user', 'edit_time', 'instance_type' );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_device_resource_idcnode", join( ',', map{"`$_`"}@col)), \@col )};

    for my $x ( @$r ) { map{ $x->{$_} = $crypt->decode( $x->{$_} ) if $x->{$_} }@cryptcol; }

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

CMDB/资源/IDC节点/获取详情

=cut

get '/cmdbmanage/resource/idcnode/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my @col = ( 'id', @rescol );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_device_resource_idcnode where id='$param->{id}'", join( ',', map{"`$_`"}@col)), \@col )};

    for my $x ( @$r ) { map{ $x->{$_} = $crypt->decode( $x->{$_} ) if $x->{$_} }@cryptcol; }

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r->[0] };
};

=pod

CMDB/资源/IDC节点/添加或编辑资源

=cut

post '/cmdbmanage/resource/idcnode' => sub {
    my $param = params();
    my @col = grep{ $_ ne 'edit_time' }grep{ $_ ne 'edit_user' }@rescol;
    my $error = Format->new( 
	id => qr/^\d+$/, 0,
        map{ $_ => [ 'mismatch', qr/'/ ], 0, }@col,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    $error = Format->new( 
	asset_number         => qr/^[a-zA-Z0-9][a-zA-Z\d\-_\.:]+$/, 0,
	server_name         => qr/^[a-zA-Z0-9][a-zA-Z\d\-_\.:]+$/, 1,
	resource_type         => qr/^[a-zA-Z0-9][a-zA-Z\d\-_\.:\s]+$/, 1,
	private_ip         => qr/^\d+\.\d+\.\d+\.\d+$/, 1,
	operating_system_type         => qr/^[a-zA-Z0-9][a-zA-Z\d\-_\.:]+$/, 1,
	status         => qr/^[a-zA-Z0-9][a-zA-Z\d\-_\.:]+$/, 1,
	city         => qr/^.+$/, 1,
	data_center_area         => qr/^.+$/, 1,
	memory_size         => qr/^\d+$/, 1,
	cpu_physical_count         => qr/^\d+$/, 1,
	cpu_cores_per_chip         => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    return  +{ stat => $JSON::false, info => "check format fail, public_ip error" }
        if length( $param->{public_ip} ) && $param->{public_ip} !~ /^\d+\.\d+\.\d+\.\d+$/;

    @col = grep{ $_ ne 'edit_time' }@rescol;

    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $title = $param->{id} ? "EDIT" : "ADD";
    eval{ $api::auditlog->run( user => $user, title => "$title CMDB Resource IDCNode", content => "name:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    map{ $param->{$_} = $crypt->encode( $param->{$_} ) if $param->{$_} }@cryptcol;

    $param->{asset_number} = "i-" . substr Digest::MD5->new()->add( join ',', time, YAML::XS::Dump $param )->hexdigest(), 0, 12;
    $param->{edit_user} = $user;

    $param->{instance_type} = sprintf "%sC%sG", $param->{cpu_physical_count} * $param->{cpu_cores_per_chip}, $param->{memory_size}//0;

    my $r = eval{ 
        $api::mysql->execute(
           $param->{id}
              ? sprintf( "update openc3_device_resource_idcnode set %s where id='$param->{id}'", join ',', map{ "`$_`='$param->{$_}'" } grep{ $_ ne 'asset_number' }@col )
              : sprintf( "insert into openc3_device_resource_idcnode (%s)values( %s )", join(',', map{"`$_`"}@col), join(',', map{"'$param->{$_}'"}@col) )
         )
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

CMDB/资源/IDC节点/删除资源

=cut

del '/cmdbmanage/resource/idcnode/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => 'DEL CMDB Resource IDCNode', content => "ID:$param->{id}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ $api::mysql->execute( "delete from openc3_device_resource_idcnode where id='$param->{id}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
