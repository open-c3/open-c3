package api::default::leader;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use uuid;
use Format;
use Digest::MD5;

=pod

系统内置/用户领导/获取列表

=cut

get '/default/leader' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $user = eval{ $api::mysql->query( "select id,user,leader1,leader2 from `openc3_connector_userleader`", [ 'id','user', 'leader1', 'leader2' ] ) };
    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true, data => $user };
};

=pod

系统内置/用户领导/添加用户

=cut

post '/default/leader' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new(
        user    => qr/^[a-zA-Z0-9\@_\.\-]+$/, 1,
        leader1 => qr/^[a-zA-Z0-9\@_\.\-]+$/, 1,
        leader2 => qr/^[a-zA-Z0-9\@_\.\-]+$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $leader1 = $param->{leader1};
    my $leader2 = $param->{leader2} ? $param->{leader2} : $param->{leader1};

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','ADD Leader','USER:$param->{user}')" ); };

    eval{ $api::mysql->execute( "replace into openc3_connector_userleader (`user`,`leader1`,`leader2`) values( '$param->{user}', '$leader1', '$leader2' )" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

系统内置/用户领导/删除用户

=cut

del '/default/leader' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new(
        user => qr/^[a-zA-Z0-9\@_\.\-]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','DEL Leader','USER:$param->{user}')" ); };

    eval{ $api::mysql->execute( "delete from openc3_connector_userleader where user='$param->{user}'" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
