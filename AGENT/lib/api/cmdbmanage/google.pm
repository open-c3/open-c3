package api::cmdbmanage::google;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;
use Encode qw(decode encode);
use OPENC3::Crypt;

my @cryptcol = qw( credentials );
my $crypt; BEGIN{ $crypt = OPENC3::Crypt->new(); };

=pod

CMDB/云帐号管理/谷歌云/获取列表

=cut

get '/cmdbmanage/account/google' => sub {
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my @col = qw( id accountname region note edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_device_account_google", join( ',', map{"`$_`"}@col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

CMDB/云帐号管理/谷歌云/获取详情

=cut

get '/cmdbmanage/account/google/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my @col = qw( id accountname credentials region note edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_device_account_google where id='$param->{id}'", join( ',', map{"`$_`"}@col)), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;

    for my $x ( @$r ) { map{ $x->{$_} = $crypt->decode( $x->{$_} ) if $x->{$_} }@cryptcol; }

    eval{ $r->[0]{credentials} = decode("UTF-8", decode_base64( $r->[0]{credentials} ) ) if $r && @$r; };

    return +{ stat => $JSON::false, info => $@ } if $@;

    return +{ stat => $JSON::true, data => ( $r && @$r ) ? $r->[0] : +{} };

};

=pod

CMDB/云帐号管理/谷歌云/添加或编辑帐号

=cut

post '/cmdbmanage/account/google' => sub {
    my $param = params();
    my $error = Format->new( 
        id           => qr/^\d+$/, 0,
        accountname  => [ 'mismatch', qr/'/ ], 1,
        credentials  => [ 'mismatch', qr/'/ ], 1,
        region       => [ 'mismatch', qr/'/ ], 1,
        note         => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $title = $param->{id} ? "EDIT" : "ADD";
    eval{ $api::auditlog->run( user => $user, title => "$title CMDB Account Google", content => "name:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    $param->{credentials} = encode_base64( encode('UTF-8', $param->{credentials}) );

    map{ $param->{$_} = $crypt->encode( $param->{$_} ) if $param->{$_} }@cryptcol;

    my $r = eval{ 
        $api::mysql->execute(
           $param->{id}
              ? "update openc3_device_account_google set accountname='$param->{accountname}',credentials='$param->{credentials}',region='$param->{region}',note='$param->{note}',edit_user='$user' where id='$param->{id}'"
              : "insert into openc3_device_account_google (`accountname`,`credentials`,`region`,`note`,`edit_user`)values( '$param->{accountname}','$param->{credentials}', '$param->{region}','$param->{note}','$user')"
         )
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

CMDB/云帐号管理/谷歌云/删除帐号

=cut

del '/cmdbmanage/account/google/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => 'DEL CMDB Account Google', content => "ID:$param->{id}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ $api::mysql->execute( "delete from openc3_device_account_google where id='$param->{id}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
