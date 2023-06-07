package AnyEvent::Ping;

use strict;
use warnings;
use 5.008_001;

our $VERSION = 0.011;

use Socket qw/SOCK_RAW/;
use Time::HiRes 'time';
use IO::Socket::INET qw/sockaddr_in inet_aton/;
use List::Util ();
require Carp;

my $ICMP_PING = 'ccnnna*';

my $ICMP_ECHOREPLY     = 0;     # Echo Reply
my $ICMP_DEST_UNREACH  = 3;     # Destination Unreachable
my $ICMP_SOURCE_QUENCH = 4;     # Source Quench
my $ICMP_REDIRECT      = 5;     # Redirect (change route)
my $ICMP_ECHO          = 8;     # Echo Request
my $ICMP_TIME_EXCEEDED = 11;    # Time Exceeded

sub new {
    my ($class, %args) = @_;

    my $interval = $args{interval};
    $interval = 0.2 unless defined $interval;

    my $timeout = $args{timeout};
    $timeout = 5 unless defined $timeout;

    my $packet_generator = $args{packet_generator};
    unless (defined $packet_generator) {
        my $packet_size = $args{packet_size};
        $packet_size = 56 unless defined $packet_size;

        $packet_generator = sub {
            &AnyEvent::Ping::generate_data_random($packet_size);
        };
    }

    my $self = bless {
        interval       => $interval,
        timeout        => $timeout,
        packet_generator => $packet_generator
    }, $class;

    # Create RAW socket
    my $socket = IO::Socket::INET->new(
        Proto    => 'icmp',
        Type     => SOCK_RAW,
        Blocking => 0
    ) or Carp::croak "Unable to create icmp socket : $!";

    $self->{_socket} = $socket;

    if (my $on_prepare = $args{on_prepare}) {
        $on_prepare->($socket);
    }

    # Create Poll object
    $self->{_poll_read} = AnyEvent->io(
        fh   => $socket,
        poll => 'r',
        cb   => sub { $self->_on_read },
    );

    # Ping tasks
    $self->{_tasks}     = [];
    $self->{_tasks_out} = [];
    $self->{_timers}    = {};

    return $self;
}

sub interval { @_ > 1 ? $_[0]->{interval} = $_[1] : $_[0]->{interval} }

sub timeout { @_ > 1 ? $_[0]->{timeout} = $_[1] : $_[0]->{timeout} }

sub error { $_[0]->{error} }

sub ping {
    my ($self, $host, $times, $cb) = @_;

    my $socket = $self->{_socket};

    my $ip = inet_aton($host);

    my $request = {
        host        => $host,
        times       => $times,
        results     => [],
        cb          => $cb,
        identifier  => int(rand 0x10000),
        destination => scalar sockaddr_in(0, $ip),
    };

    push @{$self->{_tasks}}, $request;

    push @{$self->{_tasks_out}}, $request;

    $self->_add_write_poll;

    return $self;
}

sub end {
    my $self = shift;

    delete $self->{_poll_read};
    delete $self->{_poll_write};
    delete $self->{_timers};

    while (my $request = pop @{$self->{_tasks}}) {
        $request->{cb}->($request->{results});
    }

    close delete $self->{_socket}
        if exists $self->{_socket};
}

sub generate_data_random {
    my $length = shift;

    my $data = '';
    while ($length > 0) {
        $data .= pack('C', int(rand(256)));
        $length--;
    }

    $data;
}

sub _add_write_poll {
    my $self = shift;

    return if exists $self->{_poll_write};

    $self->{_poll_write} = AnyEvent->io(
        fh   => $self->{_socket},
        poll => 'w',
        cb   => sub { $self->_send_requests },
    );
}

sub _send_requests {
    my $self = shift;

    foreach my $request (@{$self->{_tasks_out}}) {
        $self->_send_request($request);
    }

    $self->{_tasks_out} = [];
    delete $self->{_poll_write};
}

sub _on_read {
    my $self = shift;

    my $socket = $self->{_socket};
    $socket->sysread(my $chunk, 4194304, 0);

    my $icmp_msg = substr $chunk, 20;

    my ($type, $identifier, $sequence, $data);

    $type = unpack 'c', $icmp_msg;

    if ($type == $ICMP_ECHOREPLY) {
        ($type, $identifier, $sequence, $data) =
          (unpack $ICMP_PING, $icmp_msg)[0, 3, 4, 5];
    }
    elsif ($type == $ICMP_DEST_UNREACH || $type == $ICMP_TIME_EXCEEDED) {
        ($identifier, $sequence) = unpack('nn', substr($chunk, 52));
    }
    else {

        # Don't mind
        return;
    }

    # Find our task
    my $request =
      List::Util::first { $identifier == $_->{identifier} }
    @{$self->{_tasks}};

    return unless $request;

    # Is it response to our latest message?
    return unless $sequence == @{$request->{results}} + 1;

    if ($type == $ICMP_ECHOREPLY) {

        # Check data
        if ($data eq $request->{data}) {
            $self->_store_result($request, 'OK');
        }
        else {
            $self->_store_result($request, 'MALFORMED');
        }
    }
    elsif ($type == $ICMP_DEST_UNREACH) {
        $self->_store_result($request, 'DEST_UNREACH');
    }
    elsif ($type == $ICMP_TIME_EXCEEDED) {
        $self->_store_result($request, 'TIMEOUT');
    }
}

sub _store_result {
    my ($self, $request, $result) = @_;

    my $results = $request->{results};

    # Clear request specific data
    delete $self->{_timers}->{$request};

    push @$results, [$result, time - $request->{start}];

    if (@$results == $request->{times} || $result eq 'ERROR') {

        # Cleanup
        my $tasks = $self->{_tasks};
        for my $i (0 .. scalar @$tasks) {
            if ($tasks->[$i] == $request) {
                splice @$tasks, $i, 1;
                last;
            }
        }

        # Testing done
        $request->{cb}->($results);

        undef $request;
    }

    # Perform another check
    else {

        # Setup interval timer before next request
        $self->{_timers}{$request} = AnyEvent->timer(
            after => $self->interval,
            cb    => sub {
                delete $self->{_timers}{$request};
                push @{$self->{_tasks_out}}, $request;
                $self->_add_write_poll;
            }
        );
    }
}

sub _send_request {
    my ($self, $request) = @_;

    my $checksum   = 0x0000;
    my $identifier = $request->{identifier};
    my $sequence   = @{$request->{results}} + 1;
    my $data       = $self->{packet_generator}->();

    my $msg = pack $ICMP_PING,
      $ICMP_ECHO, 0x00, $checksum,
      $identifier, $sequence, $data;

    $checksum = $self->_icmp_checksum($msg);

    $msg = pack $ICMP_PING,
      0x08, 0x00, $checksum,
      $identifier, $sequence, $data;

    $request->{data} = $data;

    $request->{start} = time;

    $self->{_timers}->{$request}->{timer} = AnyEvent->timer(
        after => $self->timeout,
        cb    => sub {
            $self->_store_result($request, 'TIMEOUT');
        }
    );

    my $socket = $self->{_socket};

    $socket->send($msg, 0, $request->{destination}) or
        $self->_store_result($request, 'ERROR');
}

sub _icmp_checksum {
    my ($self, $msg) = @_;

    my $res = 0;
    foreach my $int (unpack "n*", $msg) {
        $res += $int;
    }

    # Add possible odd byte
    $res += unpack('C', substr($msg, -1, 1)) << 8
      if length($msg) % 2;

    # Fold high into low
    $res = ($res >> 16) + ($res & 0xffff);

    # Two times
    $res = ($res >> 16) + ($res & 0xffff);

    return ~$res;
}

1;
__END__

=head1 NAME

AnyEvent::Ping - ping hosts with AnyEvent

=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::Ping;

    my $host  = shift || '4.2.2.2';
    my $times = shift || 4;
    my $package_s = shift || 56;
    my $c = AnyEvent->condvar;

    my $ping = AnyEvent::Ping->new;

    print "PING $host $package_s(@{[$package_s+8]}) bytes of data\n";
    $ping->ping($host, $times, sub {
        my $results = shift;
        foreach my $result (@$results) {
            my $status = $result->[0];
            my $time   = $result->[1];
            printf "%s from %s: time=%f ms\n", 
                $status, $host, $time * 1000;
        };
        $c->send;
    });

    $c->recv;
    $ping->end;

=head1 DESCRIPTION

L<AnyEvent::Ping> is an asynchronous AnyEvent pinger.

=head1 ATTRIBUTES

L<AnyEvent::Ping> implements the following attributes.

=head2 C<interval>

    my $interval = $ping->interval;
    $ping->interval(1);

Interval between pings, defaults to 0.2 seconds.

=head2 C<timeout>
    
    my $timeout = $ping->timeout;
    $ping->timeout(3);

Maximum response time, defaults to 5 seconds.

=head2 C<error>

    my $error = $ping->error;

Last error message.

=head1 METHODS

L<AnyEvent::Ping> implements the following methods.

=head2 C<new>

    my $ping = AnyEvent::Ping->new(%options)

Constructs AnyEvent::Ping object. Following options can be passed:

=head3 C<interval>

=head3 C<timeout>

=head3 C<on_prepare>

In some cases you need to "tune" the socket before it is used to ping (for
exmaple, to bind it on a given IP address).

    my $ping = AnyEvent::Ping->new(
        on_prepare => sub {
            my $socket = shift;
            ...
    });

=head3 C<packet_generator>

Generates the data to be sent.

    my $ping = AnyEvent::Ping->new(
        packet_generator => sub {
            &AnyEvent::Ping::generate_data_random($packet_size);
    });

=head3 C<packet_size>

You can set the number of data bytes to be sent, if packet generation function
is not set. The default is 56, which translates into 64 ICMP data bytes when
combined with the 8 bytes of ICMP header data.

    my $ping = AnyEvent::Ping->new(packet_size => 56);

Each packet will be generated with generate_data_random() like this:

    &AnyEvent::Ping::generate_data_random($packet_size);

=head2 C<ping>

    $ping->ping($ip, $n => sub {
        my $results = shift;

        foreach my $result (@$results){
            my ($status, $time) = @$result;
            ...
        };
    });

Perform a ping of a given $ip address $n times.

=head2 C<end>

    $ping->end;

Ends all pings and releases resources.

=head1 SEE ALSO

L<AnyEvent>, L<AnyEvent::FastPing>

=head1 AUTHOR

Sergey Zasenko, C<undef@cpan.org>.

=head1 CREDITS

Kirill (qsimpleq)

Sebastien Deseille (sdeseille)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2015, Sergey Zasenko

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.12.

=cut
