package api::monitor;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON;
use POSIX;
use api;

get '/monitor/metrics/mysql' => sub {
    my $param = params();

    my $r = eval{ $api::mysql->query( "SHOW GLOBAL STATUS" )};
    my %r = map{ $_->[0] => $_->[1] }@$r;

    map{
        return +{ stat => $JSON::false, info => "nofind $_" } unless defined $r{$_};
    }qw( Com_select Com_insert Com_update Com_delete Slow_queries Threads_connected Innodb_buffer_pool_pages_total Innodb_buffer_pool_pages_free );

    my %re;

    $re{read} = $r{Com_select};
    $re{write} = $r{Com_insert} + $r{Com_update} + $r{Com_delete};

    $re{slow_queries} = $r{Slow_queries};
    $re{threads_connected} = $r{Threads_connected};
    $re{buffer_pool_use} = int( 100 * ( $r{Innodb_buffer_pool_pages_total} - $r{Innodb_buffer_pool_pages_free} ) / $r{Innodb_buffer_pool_pages_total} );

    return +{ stat => $JSON::true, data => \%re };
};

get '/monitor/metrics/app' => sub {
    my $param = params();

    my %re;

    my $t = eval{ $api::mysql->query( "select status,count(*) from task group by status" )};
    my %t = map{ $_->[0] => $_->[1] }@$t;
    map{ $t{$_} ||= 0 }qw( fail running success );

    $re{task_total} = 0;
    map{ $re{task_total} += $re{"task_$_"} = $t{$_} }qw( fail running success );


    my $s = eval{ $api::mysql->query( "select status,count(*) from subtask group by status" )};
    my %s = map{ $_->[0] => $_->[1] }@$s;
    map{ $s{$_} ||= 0 }qw( runnigs fail success decision ignore next );

    $re{subtask_total} = 0;
    map{ $re{subtask_total} += $re{"subtask_$_"} = $s{$_} }qw( runnigs fail success decision ignore next );

    return +{ stat => $JSON::true, data => \%re };
};

true;
