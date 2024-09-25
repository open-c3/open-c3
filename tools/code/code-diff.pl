#!/usr/bin/env perl

use strict;
use warnings;

my ( $type, $clear ) = @ARGV;

$clear = $clear && $clear eq 'clear' ? 1 : 0;

my $path;
if( $type && $type eq 'x' )
{
    $path = "/home/open-c3/code/open-c3";
}
else
{
    my $name = 'open-c3-code-diff';
       $path = "/data/$name";

    if( ! -d $path )
    {
        die "clone git error: $!" if system "cd /data && git clone https://github.com/open-c3/open-c3.git $name";
    }

    die "git pull error: $!" if system "cd $path && git pull";

}

my @x = `git pull 2>&1`;
chomp @x;

my $group = "";
my %data;
for my $x ( @x )
{
    if( $x=~ /^\S/ )
    {
        $group = $x;
        next;
    }
    $data{$group}{$x}++;
}

my $merge = $data{"error: Your local changes to the following files would be overwritten by merge:"};
my $untracked = $data{"error: The following untracked working tree files would be overwritten by merge:"};


if( $merge )
{
    for my $file ( sort keys %{$merge} )
    {
        $file =~ s/^\s+//;
        print "git checkout '$file'\n" if $clear;
        if( -f $file )
        {
            my $x = "## vimdiff '$file' '$path/$file'";
            my $t = 180 - length $x > 0 ? '#' x ( 180 - length $x ) : '';
            my @xx = `diff '$path/$file' '$file'`;
            print "\n\n","$x $t\n", @xx if @xx;
            
        }
        else
        {
            warn "merge file: $file , not a file\n";
        }
    }
}

if( $untracked )
{
    for my $file ( sort keys %{$untracked} )
    {
        $file =~ s/^\s+//;
        print "rm -f '$file'\n" if $clear;
        if( -f $file )
        {
            my $x = "## vimdiff '$file' '$path/$file'";
            my $t = 180 - length $x > 0 ? '#' x ( 180 - length $x ) : '';
            my @xx = `diff '$path/$file' '$file'`;
            print "\n\n","$x $t\n", @xx if @xx;
            
        }
        else
        {
            warn "new file: $file , not a file\n";
        }
    }
}

print "git pull\n" if $clear;
