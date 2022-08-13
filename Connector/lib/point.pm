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

    return ( undef, 1 ) if $l{$userlevel};
    return ( undef, 0 ) unless defined $treeid;
    return _point( $db, $point ,$treeid, $user );
};

sub _point
{
    my ( $db, $point , $treeid, $user ) = @_;

    my %level = %pointT;

    return ( undef, 0 ) unless $level{$point};

    my %l = map{ $_ => 1 }@{ $level{$point} };

    my $u = eval{
        $db->query(
            sprintf "select max(level) from `openc3_connector_userauthtree` where name='$user' and tree in ( %s )",
                join ',', $treeid, _gettreeids( $treeid )
        )
    };
    return ( $@ ) if $@;

    my $userlevel = ( $u && @$u > 0 ) ? $u->[0][0] : 0;

    return $l{$userlevel} ? ( undef, 1 ) : ( undef, 0 );
};

sub _gettreeids
{
    my $id = shift @_;

    my    %tree;
    my    $name;
    my    @tree = `c3mc-base-treemap cache`;
    chomp @tree;
    map{
        my @x = split /;/, $_, 2;
        $tree{ $x[1] } = $x[0] if @x    == 2;
        $name          = $x[1] if $x[0] eq $id;
    } @tree;

    return () unless $name;

    my @x = split /\./, $name;

    my @id;
    pop @x;
    while( @x )
    {
        my $x = $tree{ join '.', @x };
        push @id, $x if $x;
        pop @x;
        
    }
    return @id;
}

1;
