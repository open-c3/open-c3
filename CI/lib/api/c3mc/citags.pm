package api::c3mc::citags;
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

CI/获取Tags列表

=cut

get '/c3mc/citags/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid    => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my $filter = +{};

    my $cmd = "c3mc-tags-list '$param->{projectid}' 2>&1";
    my $handle = 'citags';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{citags} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;
    return +{ stat => $JSON::true, data => [ split /\n/, $x ] };
};

=pod

CI/通过Tags提交构建任务

=cut

any '/c3mc/citags/:projectid/:tags' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid    => qr/^\d+$/, 1,
        tags         => qr/^[a-zA-Z0-9][a-zA-Z0-9\-\._]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my $filter = +{};

    my $cmd = "c3mc-tags-make-tags '$param->{projectid}' '$param->{tags}' 2>&1";
    my $handle = 'citags_make';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{citags_make} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;
    chomp $x;
    return +{ stat => $JSON::false, info => $x } unless $x && $x =~ /^release[a-z0-9A-Z\-\._]+$/;
    return +{ stat => $JSON::true, data => $x };
};

true;
