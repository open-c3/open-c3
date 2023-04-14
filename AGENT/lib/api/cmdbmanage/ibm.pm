package api::cmdbmanage::ibm;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;
use Encode qw(decode encode);

=pod

CMDB/云帐号管理/IBM/获取列表

=cut

get '/cmdbmanage/account/ibm' => sub {
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my @col = qw( id accountname username api_key vpc_name note edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_device_account_ibm", join( ',', map{"`$_`"}@col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

CMDB/云帐号管理/IBM/获取详情

=cut

get '/cmdbmanage/account/ibm/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my @col = qw( id accountname username api_key vpc_name note edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_device_account_ibm where id='$param->{id}'", join( ',', map{"`$_`"}@col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r->[0] };
};

=pod

CMDB/云帐号管理/IBM/添加或编辑帐号

=cut

post '/cmdbmanage/account/ibm' => sub {
    my $param = params();
    my $error = Format->new( 
        id           => qr/^\d+$/, 0,
        accountname  => [ 'mismatch', qr/'/ ], 1,
        username     => [ 'mismatch', qr/'/ ], 1,
        api_key      => [ 'mismatch', qr/'/ ], 1,
        vpc_name     => [ 'mismatch', qr/'/ ], 1,
        note         => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $title = $param->{id} ? "EDIT" : "ADD";
    eval{ $api::auditlog->run( user => $user, title => "$title CMDB Account IBM", content => "name:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $config = encode_base64( encode('UTF-8', $param->{config}) );

    my $r = eval{ 
        $api::mysql->execute(
           $param->{id}
              ? "update openc3_device_account_ibm set accountname='$param->{accountname}',username='$param->{username}',`api_key`='$param->{api_key}',vpc_name='$param->{vpc_name}',note='$param->{note}',edit_user='$user' where id='$param->{id}'"
              : "insert into openc3_device_account_ibm (`accountname`,`username`,`api_key`,`vpc_name`,`note`,`edit_user`)values( '$param->{accountname}','$param->{username}','$param->{api_key}', '$param->{vpc_name}','$param->{note}','$user')"
         )
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

CMDB/云帐号管理/IBM/删除帐号

=cut

del '/cmdbmanage/account/ibm/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => 'DEL CMDB Account IBM', content => "ID:$param->{id}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ $api::mysql->execute( "delete from openc3_device_account_ibm where id='$param->{id}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
