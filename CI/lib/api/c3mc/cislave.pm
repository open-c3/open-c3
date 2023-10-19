package api::c3mc::cislave;
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

提交发布任务

ci的slave节点会调用该接口

=cut

post '/c3mc/cislave/c3mc-jobx-task-run' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid  => [ 'mismatch', qr/'/ ], 1,
        name       => [ 'mismatch', qr/'/ ], 1,
        group      => [ 'mismatch', qr/'/ ], 1,
        user       => [ 'mismatch', qr/'/ ], 1,
        variablekv => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my $cmd = "c3mc-jobx-task-run '$param->{projectid}' '$param->{name}' '$param->{group}' --user '$param->{user}' --variablekv '$param->{variablekv}' 2>&1";
    my $handle = 'c3mc-jobx-task-run';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

$handle{'c3mc-jobx-task-run'} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;
    chomp $x;
    return +{ stat => $JSON::false, info => $x } unless $x && $x =~ /^[a-zA-Z0-9]{12}$/;
    return +{ stat => $JSON::true, data => $x };
};

=pod

获取发布任务状态

ci的slave节点会调用该接口

=cut

post '/c3mc/cislave/c3mc-jobx-task-stat' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my $cmd = "c3mc-jobx-task-stat '$param->{uuid}' 2>&1";
    my $handle = 'c3mc-jobx-task-stat';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

$handle{'c3mc-jobx-task-stat'} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;
    chomp $x;
    return +{ stat => $JSON::false, info => $x } unless $x && $x =~ /^[a-zA-Z0-9]+$/;
    return +{ stat => $JSON::true, data => $x };
};

true;
