package api::c3mc::cibranch;
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

CI/获取分支列表

=cut

get '/c3mc/cibranch/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid    => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my $filter = +{};

    my $cmd = "c3mc-branch-list '$param->{projectid}' 2>&1";
    my $handle = 'cibranch';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{cibranch} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;
    return +{ stat => $JSON::true, data => [ split /\n/, $x ] };
};

=pod

CI/通过分支提交构建任务

=cut

any '/c3mc/cibranch/:projectid/:branch' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid    => qr/^\d+$/, 1,
        branch    => qr/^[a-zA-Z0-9][a-zA-Z0-9\-\._]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my $filter = +{};

    my $cmd = "c3mc-branch-make-tags '$param->{projectid}' '$param->{branch}' 2>&1";
    my $handle = 'cibranch_make';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{cibranch_make} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;
    chomp $x;
    return +{ stat => $JSON::false, info => $x } unless $x && $x =~ /^release[a-z0-9A-Z\-\._]+$/;
    return +{ stat => $JSON::true, data => $x };
};

true;
