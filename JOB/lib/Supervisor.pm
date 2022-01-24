package Supervisor;
use strict;
use warnings;
use Carp;
use YAML::XS;

use POSIX qw( :sys_wait_h );
use AnyEvent::Loop;
use AnyEvent;

use LWP::UserAgent;

use IPC::Open3;
use Symbol 'gensym';
use Time::TAI64 qw/unixtai64n/;

my %RUN = ( size => 10000000, keep => 5 );
our %time;

our %proc;
sub new
{
    my ( $class, %this ) = @_;
    map{ confess "$_ undef" unless $this{$_}; }qw( cmd log );

    unless( -d $this{log} )
    {
        die "mkdir $this{log} fail: $!" if system "mkdir -p '$this{log}'";
    }
    bless \%this, ref $class || $class;
}

my %intime;
sub intime
{
    my ( $logH, $idx ) = @_;
    $intime{$idx} = [] unless $intime{$idx};
    push @{$intime{$idx}}, time;
    return unless @{$intime{$idx}} > $RUN{"count$idx"};

    my $first = shift @{$intime{$idx}};
    my $intime = $RUN{"intime$idx"} - ( time - $first );
    return unless $intime > 0;

    syswrite( $logH, unixtai64n(time). " [SLEEP: $intime sec LEVEL $idx]\n" );
    sleep $intime;
}

sub run
{
    my $this = shift  @_;
    %RUN = ( %RUN, @_ );

    our ( $cmd, $log, $http, $check ) = @$this{qw( cmd log http check )};

    my ( $i, $cv ) = ( 0, AnyEvent->condvar );

    our ( $logf, $logH, $errH ) = ( "$log/current" );
    
    confess "open log: $!" unless open $logH, ">>$logf"; 
    if( $this->{err} )
    {
        confess "open log: $!" unless open $errH, ">>$this->{err}"; 
    }
    $logH->autoflush;


    my ( $count, $cb ) = ( 0 );
    $cb = sub {
        map{ intime( $logH, $_ ) } 1 .. 3;
        
        my ( $err, $wtr, $rdr ) = gensym;

        my $pid = IPC::Open3::open3( undef, $rdr, $err, "$cmd" );
       

        $proc{child} = AnyEvent->child ( pid => $pid, cb => $cb );
        $count ++;

        syswrite( $logH, unixtai64n(time). " [START:$count]\n" );


        $proc{pid} = $pid;
        $proc{rdr} = AnyEvent->io (
            fh => $rdr, poll => "r",
            cb => sub {
                my $input;my $n = sysread $rdr, $input, 102400;
                delete $proc{rdr} and return unless $n;
                chomp $input;
                syswrite( $logH, unixtai64n(time). " [STDOUT] $input\n" );
            }
        );
        $proc{err} = AnyEvent->io (
            fh => $err, poll => "r", 
            cb => sub {
                my $input;my $n = sysread $err, $input, 102400;
                delete $proc{err} and return unless $n;
                chomp $input;

                syswrite( $logH, unixtai64n(time). " [STDERR] $input\n" ); 
                if( $this->{err} )
                {
                    syswrite( $errH, POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime ). " $input\n" ); 
                }
            }
        );
    };

    &$cb;

    my $tt = AnyEvent->timer(
        after => 30,
        interval => 60,
        cb => sub {
            my $size = ( stat "$log/current" )[7];
            return if defined $size && $size < $RUN{size};
            if( -f "$log/current" )
            {
                my $num = $this->_num();
                system "mv '$log/current' '$log/log.$num'";
            }
	        confess "open log: $!" unless open $logH, ">>$logf"; 
	        $logH->autoflush;
        }
    );

    my $ht = AnyEvent->timer(
        after => 60,
        interval => 30,
        cb => sub {

            my $ua = LWP::UserAgent->new();
            $ua->agent('Mozilla/9 [en] (Centos; Linux)');
            $ua->timeout( 5 );

            my $res = $ua->get( $http );

            my $status = $check ? ( $res->is_success && $res->content =~ /$check/ ) ? 'ok' : 'fail'
                                : ( $res->code() == 200 ) ? 'ok' : 'fail';

            print $logH unixtai64n(time), " [CHECK] $status\n";
            kill 'KILL', $proc{pid} if $status eq 'fail' && $proc{pid};
             
        }
    ) if $http;


    $cv->recv;
    return $this;
}

sub _num
{
    my ( $log, %time ) = shift->{log};
    for my $num ( 1 .. $RUN{keep} )
    {
       return $num unless $time{$num} = ( stat "$log/log.$num" )[10];
    }
    return ( sort{ $time{$a} <=> $time{$b} } keys %time )[0];
}

1;
