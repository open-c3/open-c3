#!/data/mydan/perl/bin/perl
use strict;
use warnings;

=head1 SYNOPSIS

 $0

=cut

my @treeid = `c3mc-base-treemap|awk -F';' '{print \$1}'`;
chomp @treeid;

die "maybe some error here, skip." if @treeid <= 10;

my %treeid = map{ $_ => 1 }@treeid;

my @x = `c3mc-base-db-get -t openc3_job_task projectid uuid`;
chomp @x;

my %uuid2treeid;
for( @x )
{
    my ( $treeid, $uuid )  = split /;/, $_;
    $uuid2treeid{$uuid} = $treeid;
}

for my $file ( glob "/data/open-c3-data/logs/JOB/task/*" )
{
    next unless $file =~ /\/([A-Za-z0-9]{12})[A-Za-z0-9]*$/;
    my $uuid = $1;
    my $mtime = ( stat $file )[9];
    next if $mtime + 3 * 86400 > time;
    next unless my $treeid = $uuid2treeid{$uuid};

    my $dir = "/data/open-c3-data/logs/JOB/task.archives/$treeid";
    system "mkdir -p $dir" unless -d $dir;
    system "mv '$file' '$dir/'";
}

for my $dir ( glob "/data/open-c3-data/logs/JOB/task.archives/*" )
{
    next unless $dir =~ /\/(\d+)$/;
    my $id = $1;
    system "rm -rf '$dir'" unless $treeid{$id};
}
