package api::monitor;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use api;

get '/monitor/metrics' => sub {
    my $param = params();

    header( 'Content-Type' => 'text/plain' ) unless $param->{json};

    my @col = qw( id time time_s stat host type key val );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from `openc3_jobx_monitor` order by id", join( ',', map{"`$_`"}@col ) ), \@col
        )};

    my $err = 0;
    my $timeout = time - 90;

    map{
        if( $_->{time_s} < $timeout )
        {
            $_->{val} = 0;
            $_->{stat} = 'timeout';
        }
        $err ++ unless $_->{stat} eq 'ok' || $_->{stat} eq 'healthy';
    }@$r;

    my $t = time;
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime( $t ) );

    unshift @$r, +{ id => 0, time => $time, time_s => $t, stat => ( $err ? 'err': 'ok' ) , host => 'openc3', type => 'system', key => 'openc3_system_error', val => $err };

    if( $param->{json} )
    {
        return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
    }
    else
    {
        return join "", map{ "$_->{key}\{host=\"$_->{host}\",type=\"$_->{type}\"\} $_->{val}\n" }@$r;
    }
};

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

    my $t = eval{ $api::mysql->query( "select status,count(*) from openc3_jobx_task group by status" )};
    my %t = map{ $_->[0] => $_->[1] }@$t;
    map{ $t{$_} ||= 0 }qw( fail running success );

    $re{task_total} = 0;
    map{ $re{task_total} += $re{"task_$_"} = $t{$_} }qw( fail running success );


    my $s = eval{ $api::mysql->query( "select status,count(*) from openc3_jobx_subtask group by status" )};
    my %s = map{ $_->[0] => $_->[1] }@$s;
    map{ $s{$_} ||= 0 }qw( runnigs fail success decision ignore next );

    $re{subtask_total} = 0;
    map{ $re{subtask_total} += $re{"subtask_$_"} = $s{$_} }qw( runnigs fail success decision ignore next );

    return +{ stat => $JSON::true, data => \%re };
};

true;
