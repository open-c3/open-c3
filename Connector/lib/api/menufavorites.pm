package api::menufavorites;
use Dancer ':syntax';
use Dancer qw(cookie);
use JSON qw();
use POSIX;
use api;
use uuid;
use Format;
use OPENC3::Crypt;
use OPENC3::SysCtl;

=pod

导航栏/收藏夹

=cut

any '/menufavorites' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;

    my $param = params();
    my $error = Format->new( 
        stat => qr/^\d+$/, 1,
        menu => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    eval{
        if( $param->{stat} == 1 )
        {
            $api::mysql->execute( "delete from openc3_connector_menu_favorites where user='$ssouser' and menu='$param->{menu}'" );
        }
        elsif( $param->{stat} == 2 )
        {
            $api::mysql->execute( "replace into openc3_connector_menu_favorites (`user`,`menu`) values('$ssouser','$param->{menu}')" );
        }
     };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, info => 'ok' };
};

true;
