#!/data/Software/mydan/perl/bin/perl
use strict;
use warnings;
use MYDan;
use MYDan::Util::OptConf;

$| ++;

=head1 SYNOPSIS

 $0 --username foo --password 123456

=cut

my $option = MYDan::Util::OptConf->load();
my %o = $option->get( qw( username=s password=s ) )->dump();
$option->assert( qw( username password  ) );

my $e = $o{username} eq 'root' ? '' : "-e MYSQL_USER='$o{username}' -e MYSQL_PASS='$o{password}'";

die "start fail: $!" if system "docker run -itd --restart=always --name open-c3-database -e MYSQL_ROOT_PASSWORD='$o{password}' $e -v $MYDan::PATH/Installer/C3/mysql/init/:/docker-entrypoint-initdb.d/ -v /data/open-c3-data/mysql-data:/var/lib/mysql -v $MYDan::PATH/Installer/C3/mysql/conf/my.cnf:/etc/my.cnf -p 3306:3306 mysql:5.5";
