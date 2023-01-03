package BPM::Flow;

use warnings;
use strict;
use POSIX;

my $base = "/data/Software/mydan/JOB/bpm/config";

sub new
{
    my ( $class ) = @_;
    bless +{}, ref $class || $class;
}

sub menu
{
    my $x = eval{ YAML::XS::LoadFile "$base/menu" };
    die "load config fail:$@" if $@;
    return $x;
}

sub variable
{
    my ( $this, $bpmname ) = @_;
    my $conf = [];
    eval{
        my $pluginconf = "$base/flow/$bpmname/plugin";
        if( -f $pluginconf )
        {
            my $index = 0;
            for my $name ( $this->step( $bpmname ) )
            {
                $index ++;
                my $config = $this->subvariable( $bpmname, $index, $name );
                my $idx = 0;
                for my $opt ( @{$config->{option}} )
                {
                    push @$conf, +{ %$opt, name => "$index.".$opt->{name}, idx => $idx ++ };
                }
            }
        }
        else
        {
            $conf = YAML::XS::LoadFile "$base/flow/$bpmname/variable";
        }
    };
    die "load config fail:$@" if $@;
    return $conf;
}

sub step
{
    my ( $this, $bpmname ) = @_;
    my $pluginconf = "$base/flow/$bpmname/plugin";
    my $plugin = eval{ YAML::XS::LoadFile $pluginconf };
    die "load step fail: $@" if $@;
    return @$plugin;
}

sub subvariable
{
    my ( $this, $bpmname, $index, $name ) = @_;

    my $file = "/data/Software/mydan/Connector/pp/bpm/action/$name/data.yaml";

    map{ $file = $_ if -f $_ }( "$base/flow/$bpmname/plugin.conf/$name.yaml", "$base/flow/$bpmname/plugin.conf/$index.$name.yaml" );

    my $config = eval{ YAML::XS::LoadFile $file };
    die "load config fail: $@" if $@;
    return $config;
}

1;
