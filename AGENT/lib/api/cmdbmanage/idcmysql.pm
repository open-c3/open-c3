package api::cmdbmanage::idcmysql;
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

CMDB/资源/IDCMysql/获取列表

=cut

my @rescol = qw( uuid instance_name ip_address port status version cluster_name install_path data_dir host_ip charset max_connections backup_policy edit_user edit_time );

my @needfulcol = qw( uuid instance_name ip_address port status version cluster_name );

get '/cmdbmanage/resource/idcmysql' => sub {
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my @col = ( 'id', @needfulcol, 'edit_user', 'edit_time' );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_device_resource_idcmysql", join( ',', map{"`$_`"}@col)), \@col )};

    for my $x ( @$r ) { map{ $x->{$_} = $crypt->decode( $x->{$_} ) if $x->{$_} }@cryptcol; }

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

CMDB/资源/IDCMysql/获取详情

=cut

get '/cmdbmanage/resource/idcmysql/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my @col = ( 'id', @rescol );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_device_resource_idcmysql where id='$param->{id}'", join( ',', map{"`$_`"}@col)), \@col )};

    for my $x ( @$r ) { map{ $x->{$_} = $crypt->decode( $x->{$_} ) if $x->{$_} }@cryptcol; }

    return +{ stat => $JSON::false, info => $@ } if $@;
    my %d = @$r ? %{$r->[0]}: +{};
    map{ delete $d{$_} if defined $d{$_} && 0 == length $d{$_}}keys %d;
    return : +{ stat => $JSON::true, data => \%d };
};

=pod

CMDB/资源/IDCMysql/添加或编辑资源

=cut

post '/cmdbmanage/resource/idcmysql' => sub {
    my $param = params();
    my @col = grep{ $_ ne 'edit_time' }grep{ $_ ne 'edit_user' }@rescol;
    my $error = Format->new( 
	id => qr/^\d+$/, 0,
        map{ $_ => [ 'mismatch', qr/'/ ], 0, }@col,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    $error = Format->new( 
	uuid             => qr/^[a-zA-Z0-9][a-zA-Z\d\-_\.:]+$/, 0,
	instance_name    => qr/^[a-zA-Z0-9][a-zA-Z\d\-_\.:]+$/, 0,
	ip_address       => qr/^\d+\.\d+\.\d+\.\d+$/, 1,
	port             => qr/^\d+$/, 1,
	status           => qr/^[a-zA-Z0-9][a-zA-Z\d\-_\.:]+$/, 1,
	version          => qr/^[a-zA-Z0-9][a-zA-Z\d\-_\.:\s]+$/, 0,
	cluster_name     => qr/^[a-zA-Z0-9][a-zA-Z\d\-_\.:]+$/, 0,

	install_path     => qr/^[a-zA-Z0-9][a-zA-Z\d\-_\.:\s]+$/, 0,
	data_dir         => qr/^[a-zA-Z0-9][a-zA-Z\d\-_\.:\s]+$/, 0,
	host_ip          => qr/^\d+\.\d+\.\d+\.\d+$/, 0,
	charset          => qr/^[a-zA-Z0-9][a-zA-Z\d\-_\.:\s]+$/, 0,
	max_connections  => qr/^\d+$/, 0,
	backup_policy    => qr/^[a-zA-Z0-9][a-zA-Z\d\-_\.:\s]+$/, 0,

    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    @col = grep{ $_ ne 'edit_time' }@rescol;

    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $title = $param->{id} ? "EDIT" : "ADD";
    eval{ $api::auditlog->run( user => $user, title => "$title CMDB Resource IDCMysql", content => "name:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    map{ $param->{$_} = $crypt->encode( $param->{$_} ) if $param->{$_} }@cryptcol;

    $param->{uuid} = "i-" . substr Digest::MD5->new()->add( join ',', time, YAML::XS::Dump $param )->hexdigest(), 0, 12;
    $param->{edit_user} = $user;

    my $r = eval{ 
        $api::mysql->execute(
           $param->{id}
              ? sprintf( "update openc3_device_resource_idcmysql set %s where id='$param->{id}'", join ',', map{ "`$_`='$param->{$_}'" } grep{ $_ ne 'uuid' }@col )
              : sprintf( "insert into openc3_device_resource_idcmysql (%s)values( %s )", join(',', map{"`$_`"}@col), join(',', map{"'$param->{$_}'"}@col) )
         )
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

CMDB/资源/IDCMysql/删除资源

=cut

del '/cmdbmanage/resource/idcmysql/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => 'DEL CMDB Resource IDCMysql', content => "ID:$param->{id}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ $api::mysql->execute( "delete from openc3_device_resource_idcmysql where id='$param->{id}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
