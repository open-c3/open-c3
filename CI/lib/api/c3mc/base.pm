package api::c3mc::base;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use JSON qw();
use POSIX;
use api;
use Format;
use Time::Local;
use File::Temp;
use api::c3mc;

our %handle = %api::kubernetes::handle;

=pod

BASE/获取用户领导信息

=cut

get '/c3mc/base/userleader' => sub {
    my $param = params();
    my $error = Format->new( 
        user    => qr/^[a-zA-Z0-9][a-zA-Z0-9\.\-_\@]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my $cmd = "c3mc-base-userleader --user '$param->{user}' 2>&1";
    my $handle = 'userleader';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

$handle{userleader} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;
    my %res;
    my @cont = split /\n/, $x;
    $res{leader1} = $cont[0] if @cont >= 1;
    $res{leader2} = $cont[1] if @cont >= 2;

    return +{ stat => $JSON::true, data => \%res };
};

true;
