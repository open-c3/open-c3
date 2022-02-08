package OPENC3::MYDan::MonitorV3::NodeExporter;

use warnings;
use strict;
use Carp;

use YAML::XS;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::HTTP;
use OPENC3::MYDan::MonitorV3::NodeExporter::Collector;
use MIME::Base64;

our $extendedMonitor = +{};

sub new
{
    my ( $class, %this ) = @_;
    die "port undef" unless $this{port};

    $this{collector} = OPENC3::MYDan::MonitorV3::NodeExporter::Collector->new();
    bless \%this, ref $class || $class;
}

sub getResponseProxy
{
    my ( $this, $content ) = @_;
    $content = "#HELP DEBUG By Proxy\n". $content;
    my $length = length $content;
    my @h = (
        "HTTP/1.0 200 OK",
        "Content-Length: $length",
        "Content-Type: text/plain",
    );

    return join "\n",@h, "", $content;
}

sub getResponse
{
    my $this = shift;
    $this->{collector}->refresh();
    my $content = "#HELP DEBUG port:$this->{port}\n". $this->{collector}->format;
    my $length = length $content;
    my @h = (
        "HTTP/1.0 200 OK",
        "Content-Length: $length",
        "Content-Type: text/plain",
    );

    return join "\n",@h, "", $content;
}

sub getResponseRoot
{
    my $this = shift;
    my $content = 
'
<html>
    <head><title>MYDan Node Exporter</title></head>
    <body>
        <h1>MYDan Node Exporter</h1>
        <p><a href="/metrics">Metrics</a></p>
    </body>
</html>
';
    my $length = length $content;
    my @h = (
        "HTTP/1.0 200 OK",
        "Content-Length: $length",
        "Content-Type: text/html",
    );

    return join "\n",@h, "", $content;
}

sub run
{
    my $this = shift;
    my $cv = AnyEvent->condvar;
    my $ct = $this->runInCv();
    $cv->recv;
}

my ( $index, %index ) = ( 0 );
sub runInCv
{
    my $this = shift;

#$AnyEvent::HTTP::TIMEOUT = 10;
#$AnyEvent::HTTP::MAX_PER_HOST = 10000;

    tcp_server undef, $this->{port}, sub {
       my ( $fh ) = @_ or die "tcp_server: $!";

       my $idx = $index ++;
       $index{$idx} ++;

       my $handle; $handle = new AnyEvent::Handle( 
           fh => $fh,
           keepalive => 1,
           rbuf_max => 1024000,
           wbuf_max => 1024000,
           autocork => 1,
           on_read => sub {
               my $self = shift;
               my $len = length $self->{rbuf};
               $self->push_read (
                   chunk => $len,
                   sub { 
                       my $data = $_[1];
                       if( $data =~ m#/proxy_([\d+\.\d+\.\d+\.\d+]+)_proxy# )
                       {
                           my $ip = $1;
                           
                           my $carry = "";
                           if( $data =~ m#(carry_[a-zA-Z0-9+/=]+_carry)# )
                           {
                               $carry = $1;
                           }

                           http_get "http://$ip:$this->{port}/metrics$carry", sub { 
                               my $c = $_[0] || $_[1]->{URL}. " -> ".$_[1]->{Reason};
                               $handle->push_write($this->getResponseProxy($c)) if $c;
                               $handle->push_shutdown();
                               $handle->destroy();
                               delete $index{$idx};
                           };
                       }
                       elsif( $data =~ m#/metrics# )
                       {
                           if( $data =~ m#/carry_([a-zA-Z0-9+/=]+)_carry# )
                           {
                               $this->{carry} = $1;
                           }
                           $handle->push_write($this->getResponse());
                           $handle->push_shutdown();
                           $handle->destroy();
                           delete $index{$idx};
                       }
                       else
                       {
                           $handle->push_write($this->getResponseRoot());
                           $handle->push_shutdown();
                           $handle->destroy();
                           delete $index{$idx};
                       }
                    }
               );
           },
        );
    };

    my %timer;
    $timer{carryUpdate} = AnyEvent->timer(
        after => 1, 
        interval => 1,
        cb => sub { 
            return unless my $carry = $this->{carry};
            my $exmonitor = eval{ YAML::XS::Load decode_base64($carry) };
            $extendedMonitor = $exmonitor if $exmonitor && ref $exmonitor eq 'HASH';
        }
    );

    $timer{debug} = AnyEvent->timer(
        after => 1, 
        interval => 1,
        cb => sub { 
            printf "index: $index cache: %d\n", scalar  keys %index;
        }
    );

    return \%timer;
}

1;
