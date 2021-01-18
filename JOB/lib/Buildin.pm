package Buildin;

use warnings;
use strict;
use MYDan;

sub new
{
    my ( $class, @node ) = @_;
    bless +{ node => \@node }, ref $class || $class;
}

sub run
{
    my ( $this, %run ) = @_;

    my @node = @{$this->{node}};
    my %result = map{ $_ => '' }@node;

    my ( $cont, $argv ) = map{ $run{query}{argv}[0]{$_} }qw( cont argv );
    unless( $cont )
    {
        print "cont null\n";
        return %result;
    }

    my ( $timeout, $user ) = @run{qw( timeout sudo )};
    $timeout ||= 60;
    $user ||= 'root';

    my $build;
    if( $cont =~ /^#!([a-zA-Z0-9_]+)\b/ )
    {
        $build = $1;
    }
    else
    {
        print "cont no buildin info\n";
        return %result;
    }

    my $path = "$MYDan::PATH/JOB/buildin/$build";
    unless( -e $path )
    {
        print "nofind this buildin code\n";
        return %result;
    }

    my $nodes = join ',', sort @node;
    my $cmd = "NODE='$nodes' TIMEOUT=$timeout USER=$user $path $argv";

    print "cmd:$cmd\n";
    unless( $cmd =~ /^[a-zA-Z0-9\.\-_ '=,\/:"]+$/ )
    {
        print "cmd format error\n";
        return %result;
    }

    my @x = `$cmd`;
    chomp @x;
    map
    {
        if( $_ =~ /^([a-zA-Z0-9\-_\.]+):(.+)$/ )
        {
            my ( $n, $c ) = ( $1, $2 );
            $result{$n} .= $c if defined $result{$n};
        }
    }@x;

    map{ $result{$_} .= "--- 0\n" if $result{$_} eq 'ok'  }@node;
    return %result;
}

1;
