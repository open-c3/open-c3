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

true;
