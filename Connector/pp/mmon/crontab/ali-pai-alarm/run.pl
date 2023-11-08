#!/data/Software/mydan/perl/bin/perl
use strict;
use warnings;

$|++;

=head1 SYNOPSIS

 $0

=cut


my $path = "/data/open-c3-data/ali-pai/tmp";
system "mkdir -p '$path'" unless -d $path;


sub doalarm
{

    my $tmp = "$path/alarm.$$.txt";

    system "./getalarm.pl 2>/dev/null > '$tmp'";

    my $tmpcont = `cat '$tmp'`;
    if( $tmpcont =~ /alarm/ )
    {
        system "cat '$tmp'|c3mc-base-sendmesg alipai";
    }

}



sub dosaving
{

    my $tmp = "$path/saving.$$.txt";

    system "./getsaving.pl 2>/dev/null > '$tmp'";

    my $tmpcont = `cat '$tmp'`;
    if( $tmpcont =~ /saving/ )
    {
        system "cat '$tmp'|c3mc-base-sendmesg alipai";
    }

}



doalarm();
dosaving();

