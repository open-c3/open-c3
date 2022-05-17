package OPENC3::SysCtl;

use warnings;
use strict;

use YAML::XS;

my $dconf = '/data/Software/mydan/Connector/config/sysctl.conf';
my $pconf = '/data/open-c3-data/sysctl.conf';

sub _load
{
    my $x = shift @_;
    my $conf = eval { YAML::XS::LoadFile $x };
    die "load conf $x fail: $@" if $@;
    die unless $conf && ref $conf eq 'HASH';
    return %$conf;
}

sub new
{
    my ( $class, %this ) = @_;
    $this{data} = -f $pconf ? +{ _load($dconf), _load($pconf) } : +{ _load($dconf) };
    bless \%this, ref $class || $class;
}

sub get
{
    my ( $this, $key ) = @_;
    return $this->{data}{$key};
}

sub dump
{
    return shift->{data};
}

sub getint
{
    my ( $this, $key, $min, $max, $default ) = @_;
    my $x = $this->{data}{$key};
    return ( defined $x && $x =~ /^\d+$/ && $x >= $min && $x <= $max ) ? $x : $default;
}

1;
