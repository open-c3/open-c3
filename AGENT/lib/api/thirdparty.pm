package api::thirdparty;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;
use LWP::UserAgent;

use POSIX;
use Time::Local;
use File::Temp;

get '/thirdparty/gotopage/:app/:page' => sub {
    my $param = params();
    my $error = Format->new(
        app     => qr/^[a-zA-Z0-9\.]+$/, 1,
        page    => qr/^[a-zA-Z0-9\.]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read' ); return $pmscheck if $pmscheck;

    my ( $app, $page ) = @$param{ qw( app page ) };
    my    $on = `c3mc-sys-ctl sys.thirdparty.$app.on`;
    chomp $on;
    return +{ stat => $JSON::false, info => "$app inactive" } unless $on;

    my     $p = `c3mc-sys-ctl sys.thirdparty.$app.url.$page`;
    chomp  $p;
    return $p ? +{ stat => $JSON::true, data => $p } : +{ stat => $JSON::false, info => "page $app.$page undef" };
};

true;
