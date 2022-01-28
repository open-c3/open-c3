package api::monitor;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
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

    my $p = eval{ $api::mysql->query( "select status,count(*) from openc3_ci_project group by status" )};
    my %p = map{ $_->[0] => $_->[1] }@$p;
    map{ $p{$_} ||= 0 }(1 , 0 );
    
    my $v = eval{ $api::mysql->query( "select status,count(*) from openc3_ci_version group by status" )};
    my %v = map{ $_->[0] => $_->[1] }@$v;
    map{ $v{$_} ||= 0 }qw( done fail running success );

    my %re;
    $re{project_total} = $p{0} + $p{1};
    $re{project_active} = $p{1};

    $re{build_total}  = 0;
    map{ $re{build_total} += $re{"build_$_"} = $v{$_} }qw( done fail running success );

    return +{ stat => $JSON::true, data => \%re };
};

true;
