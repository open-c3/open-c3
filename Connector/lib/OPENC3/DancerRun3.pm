package OPENC3::DancerRun3;

use warnings;
use strict;

use Capture::Tiny qw/capture_stderr/;

sub run3
{
    my $cmd = shift @_;

    my ( $exit, @stdout ) = ( 1 );
    my $stderr = capture_stderr {
         @stdout = `$cmd`;
         $exit = $?;
    };
    chomp @stdout;
    return ( $exit, $stderr, @stdout );
}

1;
