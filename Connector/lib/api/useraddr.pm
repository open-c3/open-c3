package api::useraddr;
use Dancer ':syntax';
use Dancer qw(cookie);
use JSON qw();
use POSIX;
use api;
use uuid;
use Format;
use OPENC3::Crypt;
use OPENC3::SysCtl;

my ( $crypt, $desensitized );
BEGIN{
    $crypt        = OPENC3::Crypt->new();
    $desensitized = OPENC3::SysCtl->new()->get( 'sys.userinfo.desensitized' );
};

=pod

管理/地址簿/获取地址簿列表

=cut

get '/useraddr' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my @col = qw( id user email phone edit_user edit_time voicemail );
    my $addr = eval{ $api::mysql->query( sprintf( "select %s from `openc3_connector_useraddr`", join( ',', @col ) ), \@col ) };

    for my $u ( @$addr )
    {
        map{ $u->{$_} = $crypt->decode( $u->{$_} ) if $u->{$_} }qw( email phone voicemail );
        map{
            $u->{$_} =~ s/^(.{3}).+(.{4})$/$1****$2/      if $u->{$_} && $u->{$_} =~ /^\d+$/;
            $u->{$_} =~ s/^.{3}(.+)@.{2}(.+)$/***$1@**$2/ if $u->{$_} && $u->{$_} =~ /@/;
        }qw( email phone voicemail ) if $desensitized;
    }
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $addr };
};

=pod

管理/地址簿/提交新地址簿

=cut

post '/useraddr' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new( 
        user      => qr/^[a-zA-Z0-9\.\@_\-]+$/, 1,
        email     => qr/^[a-zA-Z0-9\.\@_\-]+$/, 1,
        phone     => qr/^[a-zA-Z0-9:\.\@_\-]+$/, 1,
        voicemail => qr/^[a-zA-Z0-9\.\@_\-]+$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    $param->{voicemail} ||= '';
    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','CREATE USERADDR','USER:$param->{user} EMAIL:$param->{email} PHONE:$param->{phone} VOICEMAIL:$param->{voicemail}')" ); };

    map{ $param->{$_} = $crypt->encode( $param->{$_} ) if $param->{$_} }qw( email phone voicemail );
 
    eval{ $api::mysql->execute( "replace into openc3_connector_useraddr (`user`,`email`,`phone`,`voicemail`,`edit_user`) values('$param->{user}','$param->{email}','$param->{phone}','$param->{voicemail}', '$ssouser')" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, info => 'ok' };
};

=pod

管理/地址簿/删除地址簿

=cut

del '/useraddr/:id' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new( id => qr/^\d+$/, 1 )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my @col = qw( id user email phone edit_user edit_time voicemail );
    my $addr = eval{ $api::mysql->query( sprintf( "select %s from `openc3_connector_useraddr` where id='$param->{id}'", join( ',', @col ) ), \@col ) };

    return +{ stat => $JSON::false, info => "nofind the id" } unless $addr && @$addr > 0;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','DELETE USERADDR','USER:$addr->[0]{user} EMAIL:$addr->[0]{email} PHONE:$addr->[0]{phone}') VOICEMAIL:$addr->[0]{voicemail}')" ); };

    eval{ $api::mysql->execute( "delete from openc3_connector_useraddr where id='$param->{id}'" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
