package OPENC3::PP::Pipe;

use warnings;
use strict;

sub system
{
    my $cmd = shift @_;
    unless( fork )
    {
        exec( bash => ( -o => "pipefail", -c => $cmd ) );
        exit 1;
    }
    else
    {
         wait;
         return $? ? "cmd: $cmd : $?" : undef;
    }
}

1;
