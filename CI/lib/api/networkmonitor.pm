package api::networkmonitor;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;

=pod

系统管理/网络监控

监控代理的网络情况

=cut

get '/networkmonitor' => sub {
    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my %col = (
        'openc3_ci_project.id'                      => 'flowid',
        'openc3_ci_project.groupid'                 => 'treeid',
        'openc3_ci_project.name'                    => 'name',
        'openc3_ci_flow_network_check.test_nodes'   => 'test_nodes',
        'openc3_ci_flow_network_check.test_error'   => 'test_error',
        'openc3_ci_flow_network_check.online_nodes' => 'online_nodes',
        'openc3_ci_flow_network_check.online_error' => 'online_error',
    );

    my @col  = sort keys %col;
    my @name = map{ $col{$_} }@col;

    my $r = eval{ 
        $api::mysql->query( 
            sprintf(
                 "select %s from openc3_ci_project left join openc3_ci_flow_network_check on openc3_ci_project.id=openc3_ci_flow_network_check.flowid",
                  join( ',', @col)
            ), \@name
       )
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
