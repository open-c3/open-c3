package OPENC3::PP::Server;

use warnings;
use strict;

sub new
{
    my ( $class, %this ) = @_;

    $0 = $this{name} if $this{name};
    $this{interval} ||= 60;
    $this{timeout} ||= 120;

    bless \%this, ref $class || $class;
}

sub run
{
    my ( $this, @cmd ) = @_;
    die unless @cmd;
    my ( $interval, $timeout ) = @$this{qw( interval timeout )};

    $ENV{PATH} .= sprintf ":%s", join ":", map{ "/data/Software/mydan/$_/pp" }qw( Connector JOB JOBX AGENT CI );

    warn "[warn]nofind pkill" if system "pkill --help 1>/dev/null";

    warn ">> start\n";

    while(1)
    {

        my $time = time;
        eval{
            my $pid;
            local $SIG{ALRM} = sub{

                if( $pid )
                {
                    system "pkill -15 -P $pid";
                    kill 'TERM', $pid;
                }

                warn "timeout alarm, pid:". $pid
            };

            alarm $timeout;

            for my $cmd ( @cmd )
            {
                unless( $pid = fork )
                {
                    exec( bash => ( -o => "pipefail", -c => $cmd ) );
                    exit 1;
                }
                else
                {
                    wait;
                    die "cmd: $cmd : $?" if $?;
                }

            }

            alarm 0;
        };

        warn "run fail: $@" if $@;

        my $due = $interval + $time - time;
        if( $due > 0 )
        {
            sleep $due;
        }
        else
        {
            warn "timeout $due.\n";
        }
    }

}

1;
