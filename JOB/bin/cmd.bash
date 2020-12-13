#!/data/Software/mydan/perl/bin/perl -I/data/Software/mydan/JOB/lib -I/data/Software/mydan/JOB/private/lib
use strict;
use warnings;
use MYDan::Util::OptConf;

use FindBin qw( $RealBin );
use MYDB;
use Util;

use AnyEvent;  
use AnyEvent::Impl::Perl;  
use AnyEvent::Socket;  
use AnyEvent::Handle;  
  
use MYDan::Agent::Client;
use MYDan::Util::OptConf;
use IO::Socket;
use Term::ReadKey;
use POSIX qw( :sys_wait_h );
use Data::UUID;
use IO::Poll qw( POLLIN POLLHUP POLLOUT POLLERR);
use Term::Size;
use Sys::Hostname;


$MYDan::Util::OptConf::THIS = 'agent';

=head1 SYNOPSIS

 $0 [--host host] [--user foo] [--sudo sudoer ] [--projectid 1]

    [--timeout seconds (default 500)]
    [--max number (default 128)] \

    
=cut

my $option = MYDan::Util::OptConf->load();
my %o = $option->set( timeout => 900 )->get( qw( host=s user=s sudo=s timeout=i max=i projectid=i ) )->dump( 'agent' );
$option->assert( qw( host user sudo projectid ) );

my $db = MYDB->new( "$RealBin/../conf/conn" );
my $host = delete $o{host};

my $command = '';
my $audit = sub
{
    my $cmd = shift;
    $command .= $cmd;

    my @cmd = split /\n+/, $command;
    if( my $end = pop @cmd )
    {
        if( $command =~ /\n$/ )
        {
            push @cmd, $end;
            $command = '';
        }
        else
        {
            $command = $end;
        }
    }
    map{
        $_ =~ s/'/"/g;
        $db->execute( "insert into cmdlog (`projectid`,`user`,`node`,`usr`,`cmd`) values('$o{projectid}','$o{user}','$host','$o{sudo}','$_')" );
    }@cmd;
};

my %env = Util::envinfo( qw( envname domainname appname appkey ) );

$ENV{MYDan_Agent_Proxy_Addr} = "http://api.agent.open-c3.org/proxy/$o{projectid}";
$ENV{MYDan_Agent_Proxy_Header} = "appname:$env{appname},appkey:$env{appkey}";

my $cv = AE::cv;  

my %proxy = MYDan::Agent::Proxy->new()->search( $host );
my $proxy = $proxy{$host};

$o{ictrl} = $o{cmd} ? 1 : 0  unless defined $o{ictrl};
$o{user} = `id -un` and chop $o{user}  unless $o{user};

my $uuid = Data::UUID->new->create_str();
my $md5 = Digest::MD5->new()->add( hostname.$$.time.rand 100000 )->hexdigest();

my ($cols, $rows) = Term::Size::chars *STDOUT{IO};

my %query = (
    env => +{ TERM => 'linux' },
    code => 'shell',
    argv => [ $proxy ? undef : '127.0.0.1', $o{port}, $uuid, $rows, $cols, $md5, $o{cmd}, $o{ictrl} ],
    map{ $_ => $o{$_} }qw( user sudo )
);

my %result = MYDan::Agent::Client->new( 
    $host 
)->run( %o, query => \%query ); 

my $call = $result{$host};
die "call fail:$call\n" 
    unless $call && $call =~ /--- 0\n$/;

my $soc = IO::Socket::INET->new(
    PeerAddr => $proxy || $host,
    PeerPort => $o{port},
    Proto    => 'tcp'
);

die( sprintf "Connect %s fail\n", $proxy || $host ) unless $soc;

my $head = "MYDanConnect_::${md5}::_MYDanConnect";
syswrite( $soc, $head, length $head );

$soc->blocking(0);

my $poll = IO::Poll->new();
$poll->mask( $soc => POLLIN  );
$poll->mask( \*STDIN => POLLIN );

ReadMode(4);

syswrite( $soc, $uuid, 36 );

while ( $poll->handles && $soc ) {
    $poll->poll();
    for my $handle ( $poll->handles( POLLIN ) ) 
    {
        my ( $data, $byte );
        if ( $handle eq $soc )
        {
            if ( $byte = sysread( $soc, $data, 1024 ) ) { syswrite( STDOUT, $data, $byte ); }
            else { $soc->shutdown(2); last; }
        }

        if( ( $handle eq \*STDIN )
            &&  ( $byte = sysread( STDIN, $data, 1024 ) ) )
        {
            syswrite( $soc, $data, $byte );
            &$audit( $data );
        }
    }
    if( $poll->handles( POLLHUP | POLLERR) )
    {
        $soc->shutdown( 2 );
        last;
    }
}

ReadMode(0);
exit 0;
