package api::c3mc::cicodemerge;
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

CI/代码合并

=cut

post '/c3mc/cicodemerge/:flowid/:srcbranch/:dstbranch' => sub {
    my $param = params();
    my $error = Format->new( 
        flowid    => qr/^\d+$/, 1,
        srcbranch => qr/^[a-zA-Z0-9][a-zA-Z0-9_\-\.]*$/, 1,
        dstbranch => qr/^[a-zA-Z0-9][a-zA-Z0-9_\-\.]*$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my $filter = +{};

    my $cmd = "c3mc-ci-code-merge '$param->{flowid}' '$param->{srcbranch}' '$param->{dstbranch}' 2>&1";
    my $handle = 'cicodemerge';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{cicodemerge} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;
    return +{ stat => $JSON::true, data => $x };
};

true;
