package Temp;
use strict;
use warnings;
use Carp;
use POSIX;
use File::Temp;
use uuid;
$|++;
sub new
{
    my ( $class, %self ) = splice @_;
    bless \%self, ref $class || $class;
}
sub dump
{
    my $this = shift;
    my $string = join "\n", @_;
    my $name = sprintf "/tmp/%s.job_buildin_tmp", uuid->new()->create_str;;
    unless( -f $name )
    {
        my $tmp = File::Temp->new( SUFFIX => ".job_buildin_tmp", UNLINK => 1 );
        print $tmp $string;
        close $tmp;
        system sprintf "mv '%s' '$name'",$tmp->filename;
    }
    chmod $this->{chmod}, $name if $this->{chmod};
    return $name;
}
1;
