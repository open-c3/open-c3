package OPENC3::MYDan::UDPFileServer::Client;

=head1 NAME

OPENC3::MYDan::UDPFileServer::Client 

=head1 SYNOPSIS

 use OPENC3::MYDan::UDPFileServer::Client;

 my $client = OPENC3::MYDan::UDPFileServer::Client->new( ip => '127.0.0.1', port => 65111 );
 my $gstat = $client->get( 'filename' );
 my $pstat = $client->put( '/path/file' );

=cut
use strict;
use warnings;
use File::Basename;

use Fcntl qw(:flock SEEK_END);
use Time::HiRes qw( sleep time );
use File::Basename;
use AnyEvent;
use AnyEvent::Handle::UDP;
use YAML::XS;
use File::Temp;

use base qw( OPENC3::MYDan::UDPFileServer );

our %RUN = ( %OPENC3::MYDan::UDPFileServer::RUN, RTimeout => 6 );

sub new
{
    my ( $class, %self ) = @_;
    map{ die "$_ undef" unless $self{$_} }qw( ip port );
    bless \%self, ref $class || $class;
}

sub put
{
    my $this = shift @_;
    my %run = ( %RUN, @_ );
    die "nofile\n" unless my $file = $run{file};
    die "file name format is not supported\n" unless $file =~ /^[a-zA-Z0-9\._\-]+$/;
    die "$file: not a file\n" unless -f $file;
    my $basename = File::Basename::basename $file;

    die "$file: open: $!\n" unless open my $fh => $file;

    my $size = ( stat $file )[7];

    my $buflen = $run{MTU} - $RUN{HEAD};
    my $count = int ( $size / $buflen );
    $count ++ if $size % $buflen;

    my ( $cv, $deleteid, $ctrlid, $sendcount, %data ) = ( AE::cv, 0, 0, 0 );
    my %ctrl = ( rtt => $run{RTT}, recv => 0, repeat => 0 );

    my $conn = AnyEvent::Handle::UDP->new(
        connect => [$this->{ip}, $this->{port}],
        on_recv => sub {
            my $data = shift @_;
            my $index = substr( $data, 0, $RUN{HEAD}, '' );
            return unless my ( $type, $idx ) = $index =~ /^DG([A-Z])([0-9a-f]{8})$/;
            my $id = hex $idx;

            if( $type eq 'K' )
            {
                warn "GET OK $data\n";
                $cv->send;
                return;
            }elsif( $type eq 'C' )
            {
                return if $id <= $ctrlid;
                my ( $recv, $repeat ) = split /:/, $data;
                %ctrl = ( %ctrl, id => $id, data => $data, 
                    time => time, recv => $recv, repeat => $repeat );
                $ctrlid = $id;
                return;
            }elsif( $type eq 'B' )
            {
                return if $id <= $deleteid;
                map{ delete $data{$_}; }$deleteid -1 .. $id -1;
                $deleteid = $id;
            }
        },
        rtimeout => $run{RTimeout},
        on_rtimeout => sub
        {
            print YAML::XS::Dump \@_;
            $cv->send;
            die "on_rtimeout.\n";
        },
        autoflush => 1,
        on_error => sub{
            $cv->send;
            die "udp error $_[2].\n";
        },
    );

    map{ $conn->push_send("DGA00000000$count:$basename"); } 1 .. 2;
    my ( $ctrltime, $ctrlindex, $waitRepeat, $sendSec, $ctrldata, %ctrlsendtime ) 
        = ( 0, 0, 0, $run{SendSec} );

    my $ctrlcb;
    $ctrlcb = sub {
        my $time = time;
        my $idx = sprintf "DGC%08x", $ctrlindex;
        $ctrlsendtime{$ctrlindex} = $time;
        $ctrlindex ++;
        map{ $conn->push_send($idx); }1..2;
        if( $ctrl{time} )
        {
            $ctrl{rtt} = sprintf "%0.4f", $ctrl{time} - $ctrlsendtime{$ctrl{id}};
            $ctrl{rtt} = 0.0001 if $ctrl{rtt} < 0.0001;
        }
        else
        {
            $ctrl{rtt} += 0.001;
        }

        if(  $ctrl{repeat} > 0 && $ctrl{recv} > 0 )
        {
            $waitRepeat += 0.001 * int( $ctrl{repeat} * 1000 / $ctrl{recv} );
        }
        else
        {
            $waitRepeat = 0;
        }

        if( $ctrl{recv} > 0 )
        {
            my $temp = int( $ctrl{recv} * $run{TransmitRatio} );
            $sendSec = $temp if $temp > $sendSec;
        }

        $ctrltime = sprintf "%0.6f", time - $time;
        $ctrldata = AnyEvent->timer(
            after => 1,
            cb => $ctrlcb,
        );
    };

    $ctrldata = AnyEvent->timer(
        after => 1,
        interval => 0.001,
        cb => $ctrlcb,
    );


    my ( $data_index, $sendtime, $sendinterval, $sendSec_temp, $sendSec_time, $senddata, %stime )
        = ( 0, 0, 1, 0, int time );

    my $sendcb;
    $sendcb = sub {
        my $time = time;
        my $itime = int $time;
        if( $itime ne $sendSec_time )
        {
            $sendSec_temp = 0;
            $sendSec_time = $itime;
        }
        my $i = 0;

        return if @{$conn->{buffers}} > $run{Buffers};

        my $timeout = $ctrl{rtt} + $run{SendTimeoutAddTime} + $waitRepeat;
        $timeout = $run{MaxRTO} if $timeout > $run{MaxRTO};

        for my $id ( $deleteid -1 .. $data_index -1 )
        {
            next if ( ! $data{$id} ) || ( $stime{$id} && $stime{$id} + $timeout > time );
            $i++;
            $conn->push_send($data{$id});
            $stime{$id} = time;
            $sendcount ++;
            $sendSec_temp ++;
            last if $sendSec_temp > $sendSec || $i >= $run{SendOne};
        }

        $sendtime = sprintf "%0.6f", time - $time;
        $sendinterval = sprintf "%0.3f", time - $time;
        $sendinterval = 0.001 if $sendinterval < 0.001;

        $senddata = AnyEvent->timer(
            after => $sendinterval,
            interval => $sendinterval,
            cb => $sendcb,
        );
    };

    $senddata = AnyEvent->timer(
        after => 1,
        interval => 0.001,
        cb => $sendcb,
    );

    my ( $readinterval, $readfile, $readtime ) = ( 0.001 );

    my $readcb;
    $readcb = sub {
        my $time = time;
        return if $run{ReadFileCache} < $data_index - $deleteid;
        my $n = read $fh, my ( $data ), $buflen * $run{ReadFileOneTime};

        unless( $n ) { undef $readfile; return; }

        while( my ( $d ) = substr( $data, 0, $buflen, '' ) )
        {
            last unless length $d;
            $data{$data_index} = sprintf( "DGT%08x", $data_index ).$d;
            $data_index ++;
        }
        $readtime = sprintf "%0.6f", time - $time;
        $readinterval = sprintf "%0.3f", time - $time;
        $readinterval *= 2;
        $readinterval = 0.001 if $readinterval < 0.001;
        $readfile = AnyEvent->timer(
            after => $readinterval,
            interval => $readinterval,
            cb => $readcb
        );
    };
    $readfile = AnyEvent->timer(
        after => $readinterval,
        interval => $readinterval,
        cb => $readcb
    );

    my $deleteid_ = 0;
    my $stat = AnyEvent->timer(
        after => 1,
        interval => 1,
        cb => sub {
            printf "rt: %0.3f\tri: %s\tst: %s\tsi: %s\tct: %s\t",
                map{ 1000 * $_}( $readtime, $readinterval, $sendtime, $sendinterval, $ctrltime );
            printf "rfilecache: %s\t", $data_index - $deleteid;
            printf "buffers: %s\t", scalar @{$conn->{buffers}};
            printf "rtt: %s\t", 1000*$ctrl{rtt};
            printf "speed: %0.2fM/s\t", ( $run{MTU} * ( $sendcount ) ) / ( 1024 * 1024 );
            printf "ack: %0.2fM/s\n", ( $run{MTU} * ( $deleteid - $deleteid_ ) ) / ( 1024 * 1024 );
            $deleteid_ = $deleteid;
            $sendcount = 0;
        }
    );

    $cv->recv;
}

sub get
{
    my $this = shift @_;
    my %run = ( %RUN, @_ );
    die "file undef\n" unless my $file = $run{file};
    die "file name format is not supported\n" unless $file =~ /^[a-zA-Z0-9\._\-]+$/;

    my ( $cv, %data, %temp_cache ) = ( AE::cv );

    my $conn;
    $conn = AnyEvent::Handle::UDP->new(
        connect => [$this->{ip}, $this->{port}],
        on_recv => sub {
            my $data = shift @_;
            my $index = substr( $data, 0, $RUN{HEAD}, '' );
            $temp_cache{recv}++;
            return unless my ( $type, $idx ) = $index =~ /^DP([A-Z])([0-9a-f]{8})$/;
            my $id = hex $idx;

            if( $type eq 'C' )
            {
                map{ $conn->push_send("$index$temp_cache{recv_sec}:$temp_cache{repeat_sec}") } 1 .. 2;
                return;

            }elsif( $type eq 'A' )
            {
                my ( $t, $count ) = split /:/, $data;
                unless( $t && $t eq 'ok' )
                {
                    warn "GET $file error: $data\n";
                    $cv->send;
                    return;
                }

                return if $temp_cache{fh};

                warn "GET $data\n";

                my $fh = File::Temp->new( DIR => '.', SUFFIX => ".udp.mydan", UNLINK => 0 );   

                %temp_cache = (
                    fh => $fh,
                    dp => $file,
                    filename => $fh->filename,
                    stat => AnyEvent->timer(
                        after => 1,
                        interval => 1,
                        cb => sub{
                            $temp_cache{recv_sec} = $temp_cache{recv} - $temp_cache{recv_};
                            $temp_cache{repeat_sec} = $temp_cache{repeat} - $temp_cache{repeat_};

                            printf "$temp_cache{dp} => count: %s\tcachequeue:%s\tackto: %s\trecv: %s/s\trepeat: %s/s\n",
                                $temp_cache{count},scalar( keys %{$temp_cache{data}}), $temp_cache{ackto}, $temp_cache{recv_sec}, $temp_cache{repeat_sec};

                            $temp_cache{recv_} =  $temp_cache{recv};
                            $temp_cache{repeat_} =  $temp_cache{repeat};
                        }
                    ),
                    ack => AnyEvent->timer(
                        after => $run{ACKInterval},
                        interval => $run{ACKInterval},
                        cb => sub{
                            $conn->push_send( sprintf "DPB%08x", $temp_cache{ackto} );
                            $temp_cache{send} ++;
                        }
                    ),

                    writefile => AnyEvent->timer(
                        after => $run{WriteFileInterval},
                        interval => $run{WriteFileInterval},
                        cb => sub{
                            if( $run{WriteFileWidth} < $temp_cache{ackto} - $temp_cache{writeto} )
                            {
                                for( $temp_cache{writeto} .. $temp_cache{writeto} + $run{WriteFileWidth} -1  )
                                {
                                    syswrite( $temp_cache{fh}, delete $temp_cache{data}{$_});
                                }
                                $temp_cache{writeto} += $run{WriteFileWidth};
                                return;
                            }

                            if( $temp_cache{ackto} eq $temp_cache{count} )
                            {
                                for my $id ( sort{ $a <=> $b } keys %{$temp_cache{data}} )
                                {
                                    syswrite( $temp_cache{fh}, delete $temp_cache{data}{$id} );
                                }
                                close $fh;

                                map{ delete $temp_cache{$_}; }qw( writefile stat ack id );

                                die "rename fail: $!\n" if system "mv '$temp_cache{filename}' '$temp_cache{dp}'";
                                print "$temp_cache{dp} => done.\n";
                                $conn->push_send("DPK00000000");
                                $cv->send;
                            }
                        }
                    ),

                    count => $count,
                    map{ $_ => 0 }qw( acktime recv recv_ recv_sec repeat repeat_ repeat_sec send ackto writeto )
                );

                return;
            }
            if( $temp_cache{id}{$id} )
            {
                $temp_cache{repeat}++;
                return;
            }

            $temp_cache{id}{$id} = 1;
            $temp_cache{data}{$id} = $data;

            return unless $id == $temp_cache{ackto};
            $temp_cache{ackto}++;
            for( $temp_cache{ackto} .. $temp_cache{count} )
            {
                last unless $temp_cache{id}{$_};
                $temp_cache{ackto} ++;
            }
        },
        rtimeout => $run{RTimeout},
        on_rtimeout => sub
        {
            print YAML::XS::Dump \@_;
            $cv->send;
            die "on_rtimeout.\n";
        },
        autoflush => 1,
        on_error => sub{
            $cv->send;
            die "udp error $_[2].\n";
        },
    );

    map{ $conn->push_send("DPA00000000$file"); } 1 .. 2;

    $cv->recv;
}

1;
