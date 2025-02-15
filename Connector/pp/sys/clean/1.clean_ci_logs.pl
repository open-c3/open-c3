#!/data/mydan/perl/bin/perl
use strict;
use warnings;

=head1 SYNOPSIS

 $0

=cut

my @flowid = `c3mc-base-db-get -t openc3_ci_project id`;
chomp @flowid;

die "maybe some error here, skip." if @flowid <= 10;

my %flowid = map{ $_ => 1 }@flowid;

for my $file ( glob "/data/open-c3-data/logs/CI/findtags/*" )
{
    next unless $file =~ /\/(\d+)$/;
    unlink $file unless $flowid{$1};
}

my @x = `c3mc-base-db-get -t openc3_ci_version projectid uuid`;
chomp @x;

my %uuid2flowid;
for( @x )
{
    my ( $flowid, $uuid )  = split /;/, $_;
    $uuid2flowid{$uuid} = $flowid;
}

for my $file ( glob "/data/open-c3-data/logs/CI/build/*" )
{
    next unless $file =~ /\/([A-Za-z0-9]{12})$/;
    my $uuid = $1;
    my $mtime = ( stat $file )[9];
    next if $mtime + 3 * 86400 > time;
    next unless my $flowid = $uuid2flowid{$uuid};

    my $dir = "/data/open-c3-data/logs/CI/build.archives/$flowid";
    system "mkdir $dir" unless -d $dir;
    system "mv '$file' '$dir/'";
}

for my $dir ( glob "/data/open-c3-data/logs/CI/build.archives/*" )
{
    next unless $dir =~ /\/(\d+)$/;
    my $id = $1;
    system "rm -rf '$dir'" unless $flowid{$id};
}
