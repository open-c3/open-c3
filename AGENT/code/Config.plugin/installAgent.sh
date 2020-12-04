#!/data/Software/mydan/perl/bin/perl -I/data/Software/mydan/AGENT/lib -I/data/Software/mydan/AGENT/private/lib
use strict;
use warnings;
use Code;
use YAML::XS;
use FindBin qw( $RealBin );
use MYDan;

$| ++;

=head1 SYNOPSIS

=cut

return sub
{
    my %param = @_;

    my ( $Config, $envname ) = @param{qw( Config envname )};

    die "envinfo config undef" unless $Config->{envinfo};

    my %macro = ( %{$Config->{envinfo}}, envname => $envname );

    die "config/installAgent.sh.Template null" unless my $conf = `cat $RealBin/../config/installAgent.sh.Template`;

    die "domainname undef" unless $macro{domainname};
    for my $k ( keys %macro )
    {
        $conf =~ s#\[\[:$k:\]\]#$macro{$k}#g;
    }

    open my $H , ">$RealBin/../scripts/installAgent.sh" or die "open scripts/installAgent.sh fail:$!";
    print $H $conf;
    close $H;

    die "link c3_${envname}.pub fail!" if system "ln -fsn $MYDan::PATH/etc/agent/auth/c3_${envname}.pub $RealBin/../scripts/c3_${envname}.pub";
}
