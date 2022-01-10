package OPENC3::MYDan::UDPFileServer::Server;

=head1 NAME

OPENC3::MYDan::UDPFileServer::Server

=head1 SYNOPSIS

 use OPENC3::MYDan::UDPFileServer::Server;

 my $server = OPENC3::MYDan::UDPFileServer::Server->new( ip => '0.0.0.0', port => 65111 );
 $server->run();

=cut
use strict;
use warnings;

use Fcntl qw(:flock SEEK_END);
use Time::HiRes qw( sleep time );
use AnyEvent;
use AnyEvent::Handle::UDP;
use YAML::XS;
use File::Temp;

use base qw( OPENC3::MYDan::UDPFileServer );

our %RUN = ( %OPENC3::MYDan::UDPFileServer::RUN, Timeout => 6 );

sub new
{
    my ( $class, %self ) = @_;
    $self{ip} ||= '0.0.0.0';
    die "port undef" unless $self{port};
    bless \%self, ref $class || $class;
}

sub run
{
    my $this = shift @_;
    my %run = ( %RUN, @_ );

    my $buflen = $run{MTU} - $RUN{HEAD};
    my ( $cv, %recv, %send ) = ( AE::cv );
    my $server = AnyEvent::Handle::UDP->new(
        bind => [$this->{ip}, $this->{port}],
        on_recv => sub {
            my ($data, $handle, $name) = @_;
            my $index = substr( $data, 0, $RUN{HEAD}, '' );
            return unless my ( $action, $type, $idx ) = $index =~ /^D([A-Z])([A-Z])([0-9a-f]{8})$/;
            my $id = hex $idx;

            if( $action eq 'G' )
            {
                if( $type eq 'C' )
                {
                    return unless $recv{$name}{recv_sec};
                    map{ $handle->push_send("$index$recv{$name}{recv_sec}:$recv{$name}{repeat_sec}", $name) }1 .. 2;
                    return;

                }elsif( $type eq 'A' )
                {
                    map{ $handle->push_send($index, $name) }1 .. 2;
                    my ( $count, $dp ) = split /:/, $data;
                    $dp = 'tempfile' unless $dp && $dp =~ /^[a-zA-Z0-9\._\-]+$/;
                    unless( $recv{$name}{filename} )
                    {
                        my $fh = File::Temp->new( DIR => '.', SUFFIX => ".udp.mydan", UNLINK => 0 );
                        my ( $port, $host ) = AnyEvent::Socket::unpack_sockaddr($name);
                        $host = AnyEvent::Socket::format_address( $host );

                        $recv{$name} = +{
                            host => $host,
                            port => $port,
                            fh => $fh,
                            dp => $dp,
                            filename => $fh->filename,
                            stat => AnyEvent->timer(
                                after => 1,
                                interval => 1,
                                cb => sub{
                                    map{ $recv{$name}{$_.'_sec'} = $recv{$name}{$_} - $recv{$name}{$_.'_'}; }qw( recv repeat );
                                    printf "$recv{$name}{host}:$recv{$name}{port} $recv{$name}{dp} PUT => count: %s\tcache:%s\tackto: %s\trecv: %s/s\trepeat: %s/s\n",
                                    $recv{$name}{count},scalar( keys %{$recv{$name}{data}} ), map{ $recv{$name}{$_} }qw( ackto recv_sec repeat_sec );
                                    map{ $recv{$name}{$_.'_'} =  $recv{$name}{$_}; }qw( recv repeat );
                                }
                            ),
                            ack => AnyEvent->timer(
                                after => $run{ACKInterval},
                                interval => $run{ACKInterval},
                                cb => sub{
                                    $recv{$name}{send} ++;
                                    $handle->push_send( sprintf( "DGB%08x", $recv{$name}{ackto} ), $name );
                                }
                            ),

                            writefile => AnyEvent->timer(
                                after => $run{WriteFileInterval},
                                interval => $run{WriteFileInterval},
                                cb => sub{
                                    if( $run{WriteFileWidth} < $recv{$name}{ackto} - $recv{$name}{writeto} )
                                    {
                                        for( $recv{$name}{writeto} .. $recv{$name}{writeto} + $run{WriteFileWidth} -1  )
                                        {
                                            syswrite( $recv{$name}{fh}, delete $recv{$name}{data}{$_} );
                                        }
                                        $recv{$name}{writeto} += $run{WriteFileWidth};
                                        return;
                                    }
                                    if( $recv{$name}{ackto} eq $recv{$name}{count} )
                                    {
                                        for my $id ( sort{ $a <=> $b } keys %{$recv{$name}{data}} )
                                        {
                                            syswrite( $recv{$name}{fh}, delete $recv{$name}{data}{$id} );
                                        }
                                        close $fh;

                                        map{ delete $recv{$name}{$_}; }qw( writefile stat ack data id );

                                        die "rename fail: $!\n" if system "mv '$recv{$name}{filename}' '$recv{$name}{dp}'";
                                        printf "$recv{$name}{host}:$recv{$name}{port} $recv{$name}{dp} PUT => done.\n";
                                        $handle->push_send("DGK000000000", $name);
                                        delete $recv{$name};
                                    }
                                }
                            ),

                            count => $count,
                            map{ $_ => 0 }qw( acktime recv recv_ recv_sec repeat repeat_ repeat_sec send ackto writeto )
                        };
                    }
                    return;
                }

                $recv{$name}{recv}++;
                if( $recv{$name}{id}{$id} )
                {
                    $recv{$name}{repeat}++;
                    return;
                }

                $recv{$name}{id}{$id} = 1;
                $recv{$name}{data}{$id} = $data;

                return unless defined $recv{$name}{ackto} && $id == $recv{$name}{ackto};
                $recv{$name}{ackto}++;
                for( $recv{$name}{ackto} .. $recv{$name}{count} )
                {
                    last unless $recv{$name}{id}{$_};
                    $recv{$name}{ackto} ++;
                }

            }else
            {
                if( $type eq 'A' )
                {
                    return if $send{$name};

                    my ($port, $host) = AnyEvent::Socket::unpack_sockaddr($name);
                    $host = AnyEvent::Socket::format_address( $host );

                    my $file = $data;
                    print "$host:$port GET <= file: $file\n";

                    unless( $file =~ /^[a-zA-Z0-9\._\-]+$/ )
                    {
                        map{ $handle->push_send("$index$file: file name format not support", $name) }1..2;
                        return;
                    }

                    unless( -f $file )
                    {
                        map{ $handle->push_send("$index$file: not a file", $name) }1..2;
                        return;
                    }

                    my $fh;
                    unless( open $fh => $file )
                    {
                        map{ $handle->push_send("$index$file: open: $!", $name) }1..2;
                        return;
                    }

                    my $size = ( stat $file )[7];

                    my $count = int ( $size / $buflen );
                    $count ++ if $size % $buflen;

                    map{ $handle->push_send("${index}ok:$count", $name) }1..2;

                    $send{$name} = +{
                        fh => $fh,
                        host => $host,
                        port => $port,
                        filename => $file,
                        deleteid => 0,
                        ctrlid => 0,
                        sendcount => 0,
                        ctrltime => 0,
                        ctrlindex => 0,
                        waitRepeat => 0,
                        sendSec => $run{SendSec},
                        data => +{},
                        ctrlsendtime => +{},
                        ctrl => +{ rtt => $run{RTT}, recv => 0, repeat => 0 },
                        data_index => 0,
                        sendtime => 0,
                        sendinterval => 1,
                        sendSec_temp => 0,
                        sendSec_time => int time,
                        stime => +{},
                        readinterval => 0.001,
                    };

                    $send{$name}{ctrlcb} = sub {
                        my $time = time;
                        my $idx = sprintf "DPC%08x", $send{$name}{ctrlindex};
                        $send{$name}{ctrlsendtime}{$send{$name}{ctrlindex}} = $time;
                        $send{$name}{ctrlindex} ++;
                        map{ $handle->push_send($idx, $name) }1..2;
                        if( $send{$name}{ctrl}{time} )
                        {
                            $send{$name}{ctrl}{rtt} = sprintf "%0.4f",
                                $send{$name}{ctrl}{time} - $send{$name}{ctrlsendtime}{$send{$name}{ctrl}{id}};
                            $send{$name}{ctrl}{rtt} = 0.0001 if $send{$name}{ctrl}{rtt} < 0.0001;
                        }
                        else
                        {
                            $send{$name}{ctrl}{rtt} += 0.001;
                        }

                        if( $send{$name}{ctrl}{repeat} > 0 && $send{$name}{ctrl}{recv} > 0 )
                        {
                            $send{$name}{waitRepeat} += 0.001 * int( $send{$name}{ctrl}{repeat} * 1000 / $send{$name}{ctrl}{recv} );
                        }
                        else
                        {
                            $send{$name}{waitRepeat} = 0;
                        }

                        if( $send{$name}{ctrl}{recv} > 0 )
                        {
                            my $sendSec = int( $send{$name}{ctrl}{recv} * $run{TransmitRatio} );
                            $send{$name}{sendSec} = $sendSec if $sendSec > $send{$name}{sendSec};
                        }

                        $send{$name}{ctrltime} = sprintf "%0.6f", time - $time;

                        $send{$name}{ctrldata} = AnyEvent->timer(
                            after => 1,
                            cb => $send{$name}{ctrlcb},
                        );
                    };
                    $send{$name}{ctrldata} = AnyEvent->timer(
                        after => 1,
                        interval => 0.001,
                        cb => $send{$name}{ctrlcb},
                    );

                    $send{$name}{sendcb} = sub {
                        my $time = time;
                        my $itime = int $time;
                        if( $itime ne $send{$name}{sendSec_time} )
                        {
                            $send{$name}{sendSec_temp} = 0;
                            $send{$name}{sendSec_time} = $itime;
                        }
                        my $i = 0;

                        return if scalar @{$handle->{buffers}} > $run{Buffers};

                        my $timeout = $send{$name}{ctrl}{rtt} + $run{SendTimeoutAddTime} + $send{$name}{waitRepeat};
                        $timeout = $run{MaxRTO} if $timeout > $run{MaxRTO};
                        for my $id ( $send{$name}{deleteid} - 1 .. $send{$name}{data_index} - 1 )
                        {
                            next if ( ! $send{$name}{data}{$id} ) || ( $send{$name}{stime}{$id} && $send{$name}{stime}{$id} + $timeout > time );
                            $i++;
                            $handle->push_send($send{$name}{data}{$id}, $name);
                            $send{$name}{stime}{$id} = time;
                            $send{$name}{sendcount} ++;
                            $send{$name}{sendSec_temp} ++;
                            last if $send{$name}{sendSec_temp} > $send{$name}{sendSec} || $i >= $run{SendOne};
                        }

                        $send{$name}{sendtime} = sprintf "%0.6f", time - $time;
                        $send{$name}{sendinterval} = sprintf "%0.3f", time - $time;
                        $send{$name}{sendinterval} = 0.001 if $send{$name}{sendinterval} < 0.001;

                        $send{$name}{senddata} = AnyEvent->timer(
                            after => $send{$name}{sendinterval},
                            interval => $send{$name}{sendinterval},
                            cb => $send{$name}{sendcb},
                        );
                    };

                    $send{$name}{senddata} = AnyEvent->timer(
                        after => 1,
                        interval => 0.001,
                        cb => $send{$name}{sendcb},
                    );

                    $send{$name}{readcb} = sub {
                        my $time = time;
                        return if $run{ReadFileCache} < $send{$name}{data_index} - $send{$name}{deleteid};
                        my $n = read $send{$name}{fh}, my ( $data ), $buflen * $run{ReadFileOneTime};
                        return delete $send{$name}{readfile} unless $n;

                        while( my ( $d ) = substr( $data, 0, $buflen, '' ) )
                        {
                            last unless length $d;
                            $send{$name}{data}{$send{$name}{data_index}} = sprintf( "DPT%08x", $send{$name}{data_index} ).$d;
                            $send{$name}{data_index} ++;
                        }
                        $send{$name}{readtime} = sprintf "%0.6f", time - $time;
                        $send{$name}{readinterval} = sprintf "%0.3f", time - $time;
                        $send{$name}{readinterval} *= 2;
                        $send{$name}{readinterval} = 0.001 if $send{$name}{readinterval} < 0.001;

                        $send{$name}{readfile} = AnyEvent->timer(
                            after => $send{$name}{readinterval},
                            interval => $send{$name}{readinterval},
                            cb => $send{$name}{readcb}
                        );
                    };

                    $send{$name}{readfile} = AnyEvent->timer(
                        after => $send{$name}{readinterval},
                        interval => $send{$name}{readinterval},
                        cb => $send{$name}{readcb}
                    );

                    $send{$name}{deleteid_} = 0;
                    $send{$name}{stat} = AnyEvent->timer(
                        after => 1,
                        interval => 1,
                        cb => sub {
                            printf "$send{$name}{host}:$send{$name}{port} $send{$name}{filename} GET => rt: %0.3f\tri: %s\tst: %s\tsi: %s\tct: %s\t",
                                map{ 1000 * $send{$name}{$_}; }qw( readtime readinterval sendtime sendinterval ctrltime );
                            printf "rfilecache: %s\t", $send{$name}{data_index} - $send{$name}{deleteid};
                            printf "buffers: %s\t", scalar @{$handle->{buffers}};
                            printf "rtt: %s\t", 1000*$send{$name}{ctrl}{rtt};
                            printf "speed: %0.2fM/s\t", ( ( $run{MTU} * ( $send{$name}{sendcount} )) / ( 1024 * 1024 ) );
                            printf "ack: %0.2fM/s\n",  ( ( $run{MTU} * ( $send{$name}{deleteid} - $send{$name}{deleteid_} )) / ( 1024 * 1024 ) );

                            $send{$name}{deleteid_} = $send{$name}{deleteid};
                            $send{$name}{sendcount} = 0;
                        }
                    );

                    return;
                }
                elsif( $type eq 'K' )
                {
                    warn "GET OK $data\n";
                    delete $send{$name};
                    return;
                }elsif( $type eq 'C' )
                {
                    return if $id <= $send{$name}{ctrlid};
                    my ( $recv, $repeat ) = split /:/, $data;
                    $send{$name}{ctrl} = +{ %{$send{$name}{ctrl}}, id => $id, data => $data, time => time, recv => $recv, repeat => $repeat };
                    $send{$name}{ctrlid} = $id;
                    return;
                }elsif( $type eq 'B' )
                {
                    return if ( ! defined $send{$name}{deleteid} ) || $id <= $send{$name}{deleteid};
                    map{ delete $send{$name}{data}{$_}; }$send{$name}{deleteid} -1 .. $id -1;
                    $send{$name}{deleteid} = $id;
                }
            }
        },

        autoflush => 1,
        on_error => sub{
            print YAML::XS::Dump \@_;
            die "error $_[2].\n";
        },
    );

    my $clean = AnyEvent->timer(
        after => 1,
        interval => 1,
        cb => sub {
            my $time = int time;

            for my $name ( keys %recv )
            {
                my $r = $recv{$name}{recv} || 0;

                if( ( ! $recv{$name}{cleantime} ) || ( $r ne $recv{$name}{cleanrecv} ) )
                {
                    $recv{$name}{cleantime} = $time;
                    $recv{$name}{cleanrecv} = $r;
                }
                elsif( $recv{$name}{cleantime} + $run{Timeout} < $time )
                {
                    printf "%s:%s %s PUT <= timeout.\n", map{ $recv{$name}{$_} }qw( host port dp ) if $recv{$name}{host} ;
                    delete $recv{$name};
                }
            }

            for my $name ( keys %send )
            {
                my $r = $send{$name}{deleteid} || 0;

                if( ( ! $send{$name}{cleantime} ) || ( $r ne $send{$name}{cleanrecv} ) )
                {
                    $send{$name}{cleantime} = $time;
                    $send{$name}{cleanrecv} = $r;
                }
                elsif( $send{$name}{cleantime} + $run{Timeout} < $time )
                {
                    printf "%s:%s %s GET => timeout.\n", map{ $send{$name}{$_} }qw( host port filename ) if $send{$name}{host};
                    delete $send{$name};
                }
            }
   
        }
    );

    $cv->recv;
}

1;
