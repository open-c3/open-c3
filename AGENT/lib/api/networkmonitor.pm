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

管理/网络监视器

=cut

get '/networkmonitor' => sub {
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my %col = (
        'openc3_agent_proxy.id'                      => 'id',
        'openc3_agent_region.name'                   => 'name',
        'openc3_agent_proxy.regionid'                => 'regionid',
        'openc3_agent_proxy.projectid'               => 'projectid',
        'openc3_agent_proxy.ip'                      => 'node',
        'openc3_agent_node_network_check.tcp_speed'  => 'tcp_speed',
        'openc3_agent_node_network_check.tcp_error'  => 'tcp_error',
        'openc3_agent_node_network_check.udp_speed'  => 'udp_speed',
        'openc3_agent_node_network_check.udp_error'  => 'udp_error',
        'openc3_agent_node_network_check.check_time' => 'check_time',
    );

    my @col  = sort keys %col;
    my @name = map{ $col{$_} }@col;

    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_agent_proxy left join openc3_agent_region on openc3_agent_proxy.regionid=openc3_agent_region.id left join openc3_agent_node_network_check on openc3_agent_proxy.ip=openc3_agent_node_network_check.node", join( ',', @col)), \@name )};

    %col = (
        'openc3_agent_project_region_relation.regionid' => 'regionid',
        'openc3_agent_agent.ip'                         => 'subnet',
    );

    @col  = sort keys %col;
    @name = map{ $col{$_} }@col;

    my %subnet;
    my $x = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_agent_agent left join openc3_agent_project_region_relation on openc3_agent_agent.relationid=openc3_agent_project_region_relation.id", join( ',', @col)), \@name )};

    for my $xx ( @$x )
    {
        $subnet{$xx->{regionid}} ||= [];
        push @{$subnet{$xx->{regionid}}}, $xx->{subnet};
    }

    for my $x ( @$r )
    {
        $x->{subnet} = $subnet{$x->{regionid}} ? join( ',', @{$subnet{$x->{regionid}}} ) : '';
    }

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
