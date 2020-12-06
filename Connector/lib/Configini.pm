package Configini;
use warnings;
use strict;

my $config;
BEGIN{
    use YAML::XS;
    $config = eval{ YAML::XS::LoadFile "/data/Software/mydan/Connector/config.inix" };
    die "load config.ini/current fail: $@" if $@;
};


sub config
{
    return $config;
}

sub get
{
    my $name = shift @_;
    return $config->{$name};
}

sub env
{
    my $name = shift @_;
    my $conf = $config->{$name};
    return () unless $conf && ref $conf eq 'HASH';
    $conf->{appkey} = $ENV{OPEN_C3_RANDOM} if $conf->{appkey} && $conf->{appkey} eq 'c3random' && $ENV{OPEN_C3_RANDOM};
    return %$conf;
}

1;
