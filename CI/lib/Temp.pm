package Temp;
use strict;
use warnings;
use Carp;
use POSIX;
use Data::Dumper;
use File::Temp;
use Digest::MD5;
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
    my $user = `id -u`; chomp $user;
    my $name = sprintf "/tmp/%s.$user.ci_tmp", Digest::MD5->new->add( $string )->hexdigest;
    unless( -f $name )
    {
        my $tmp = File::Temp->new( SUFFIX => ".ci_tmp", UNLINK => 0 );
        print $tmp $string;
        close $tmp;
        system sprintf "mv '%s' '$name'",$tmp->filename;
    }
    chmod $this->{chmod}, $name if $this->{chmod};
    return $name;
}
1;
