package OPENC3::PP::Exec;

use warnings;
use strict;

sub new
{
    my ( $class, %this ) = @_;

    $0 = $this{name} if $this{name};
    $this{timeout} ||= 60;

    bless \%this, ref $class || $class;
}

sub run
{
    my ( $this, @cmd ) = @_;
    return unless @cmd;

    warn "[warn]nofind pkill" if system "pkill --help 1>/dev/null";

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

        alarm $this->{timeout};

        for my $cmd ( @cmd )
        {
            unless( $pid = fork )
            {
                exec $cmd;
                exit 1;
            }
            else
            {
                wait;
                die if $?;
           }

        }

        alarm 0;
    };

    if( $@ )
    {
        warn "run fail: $@";
        return;
    }

    return 1;
}

1;
