#!/data/Software/mydan/perl/bin/perl
use strict;
use warnings;

$|++;

=head1 SYNOPSIS

 $0

=cut


my $path = "/data/open-c3-data/ali-pai/tmp";
system "mkdir -p '$path'" unless -d $path;


sub donotify
{

    my $tmp = "$path/notify.$$.txt";

    system "./getnotify.pl 2>/dev/null > '$tmp'";

    my $tmpcont = `cat '$tmp'`;
    if( $tmpcont =~ /notify/ )
    {
        system "cat '$tmp'|c3mc-base-sendmesg alipai";
    }

}


donotify();

