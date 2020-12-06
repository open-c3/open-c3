package Config;
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
    return $config->{$name} && ref $config->{$name} eq 'HASH' ? %{$config->{$name}} : ();
}

1;
