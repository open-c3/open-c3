package api::monitor;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use api;

=pod

系统内置/数据库监控状态

=cut

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

=pod

系统内置/模块监控状态

=cut

get '/monitor/metrics/app' => sub {
    my $param = params();

    my %re;

    my $p = eval{ $api::mysql->query( "select status,count(*) from openc3_agent_proxy group by status" )};
    my %p = map{ $_->[0] => $_->[1] }grep{ $_->[0] }@$p;
    map{ $p{$_} ||= 0 }qw( fail success );

    $re{proxy_total} = 0;
    map{ $re{proxy_total} += $re{"proxy_$_"} = $p{$_} }qw( fail success );

    my $a = eval{ $api::mysql->query( "select status,count(*) from openc3_agent_proxy group by status" )};
    my %a = map{ $_->[0] => $_->[1] }grep{ $_->[0] }@$a;
    map{ $a{$_} ||= 0 }qw( fail success );

    $re{agent_total} = 0;
    map{ $re{agent_total} += $re{"agent_$_"} = $a{$_} }qw( fail success );

    my $c = eval{ $api::mysql->query( "select count(*) from `openc3_agent_check` where status='on'" )};
    $re{check_total} = $c->[0][0];

    return +{ stat => $JSON::true, data => \%re };
};

true;
