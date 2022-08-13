package point;
use warnings;
use strict;

my %pointG = (
    openc3_job_root          => [          3 ],
    openc3_jobx_root         => [          3 ],
    openc3_ci_root           => [          3 ],
    openc3_agent_root        => [          3 ],
    openc3_connector_root    => [          3 ],
);

my %pointT = (
    openc3_job_read          => [ 0, 1, 2, 3 ],
    openc3_job_write         => [       2, 3 ],
    openc3_job_delete        => [       2, 3 ],
    openc3_job_vssh          => [       2, 3 ],
    openc3_job_vsshnobody    => [    1, 2, 3 ],
    openc3_job_control       => [    1, 2, 3 ],

    openc3_jobx_read         => [ 0, 1, 2, 3 ],
    openc3_jobx_write        => [       2, 3 ],
    openc3_jobx_delete       => [       2, 3 ],
    openc3_jobx_control      => [    1, 2, 3 ],

    openc3_ci_read           => [ 0, 1, 2, 3 ],
    openc3_ci_write          => [       2, 3 ],
    openc3_ci_delete         => [       2, 3 ],
    openc3_ci_control        => [    1, 2, 3 ],

    openc3_agent_read        => [ 0, 1, 2, 3 ],
    openc3_agent_write       => [       2, 3 ],
    openc3_agent_delete      => [       2, 3 ],

    openc3_connector_read    => [ 0, 1, 2, 3 ],
    openc3_connector_write   => [       2, 3 ],
    openc3_connector_delete  => [       2, 3 ],
);

sub point
{
    my ( $db, $point , $treeid, $user ) = @_;

    #level
    #0: login 1: dev 2:ops 3:admin
    my %level = ( %pointG, %pointT );

    my %l = map{ $_ => 1 }@{  $level{$point}  };

    return ( "point $point undef" ) unless %l;

    return ( '', 1 ) if $l{0};

    my $u = eval{ $db->query( "select level from `openc3_connector_userauth` where name='$user'" ) };
    return ( $@ ) if $@;

    my $userlevel = ( $u && @$u > 0 ) ? $u->[0][0] : 0;

    return $l{$userlevel} ? ( undef, 1 ) : ( undef, 0 );
};

1;
