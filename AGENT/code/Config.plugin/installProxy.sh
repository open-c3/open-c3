#!/data/Software/mydan/perl/bin/perl -I/data/Software/mydan/AGENT/lib -I/data/Software/mydan/AGENT/private/lib
use strict;
use warnings;
use Code;
use YAML::XS;
use FindBin qw( $RealBin );

$| ++;

=head1 SYNOPSIS

=cut

return sub
{
    my %param = @_;

    my ( $Config, $envname ) = @param{qw( Config envname )};

    $envname = $ENV{OPEN_C3_NAME} if $ENV{OPEN_C3_NAME};

    die "envinfo config undef" unless $Config->{envinfo};

    my %macro = ( %{$Config->{envinfo}}, envname => $envname );

    die "config/installProxy.sh.Template null" unless my $conf = `cat $RealBin/../config/installProxy.sh.Template`;

    die "domainname undef" unless $macro{domainname};
    for my $k ( keys %macro )
    {
        $conf =~ s#\[\[:$k:\]\]#$macro{$k}#g;
    }

    open my $H , ">$RealBin/../scripts/installProxy.sh" or die "open scripts/installProxy.sh fail:$!";
    print $H $conf;
    close $H;
}
