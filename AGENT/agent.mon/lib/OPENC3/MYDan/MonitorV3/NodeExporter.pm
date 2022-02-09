package OPENC3::MYDan::MonitorV3::NodeExporter;

use warnings;
use strict;
use Carp;
use JSON;

use YAML::XS;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::HTTP;
use OPENC3::MYDan::MonitorV3::NodeExporter::Collector;
use MIME::Base64;

our $extendedMonitor = +{};
our $carryerror = 0;
our $promeerror = 0;

sub new
{
    my ( $class, %this ) = @_;
    die "port undef" unless $this{port};

    $this{collector} = OPENC3::MYDan::MonitorV3::NodeExporter::Collector->new();
    bless \%this, ref $class || $class;
}

sub _html
{
    my ( $this, $content, $type ) = @_;
    $type ||= 'text/plain';
    my $length = length $content;
    my @h = (
        "HTTP/1.0 200 OK",
        "Content-Length: $length",
        "Content-Type: $type",
    );

    return join "\n",@h, "", $content;
}

sub getResponseProxy
{
    my ( $this, $content ) = @_;
    return $this->_html( "# HELP DEBUG By Proxy\n". $content );
}

sub getResponse
{
    my ( $this, $debug ) = @_;
    $this->{collector}->refresh();

    my @debug;
    if( $debug )
    {
        @debug = map{"# $_"}split /\n/, YAML::XS::Dump $extendedMonitor;
        unshift @debug, "# DEBUG";
    }

    my $content = join "\n",
        "# HELP OPEN-C3 Node Exporter debug[$debug]",
        @debug,
        $this->{collector}->format;

    return $this->_html( $content );
}

sub getResponseRoot
{
    my $this = shift;
    my $content = 
'
<html>
    <head><title>OPEN-C3 Node Exporter</title></head>
    <body>
        <h1>OPEN-C3 Node Exporter</h1>
        <p><a href="/metrics">Metrics</a></p>
    </body>
</html>
';
    return $this->_html( $content, 'text/html' );
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

                           http_get "http://$ip:$this->{port}/metrics/$carry", sub { 
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
                           $handle->push_write($this->getResponse( $data =~ /debug=1/ ? 1 : 0 ));
                           $handle->push_shutdown();
                           $handle->destroy();
                           delete $index{$idx};
                       }
                       elsif( $data =~ m#POST /v1/push HTTP/# )
                       {
                           my $mesg = "success";

                           my $d = ( split /\n/, $data)[-1];
                           my $v = eval{JSON::decode_json $d};
                           if($@)
                           {
                               warn "error: $@" if $@;
                               $mesg = "error: $@\n";
                           }
                           else
                           {
                               for my $val ( @$v )
                               {
                                   if ( $val->{metric} && $val->{metric} =~ /^[a-zA-Z0-9\.\-_]+$/ 
                                     && defined $val->{value} && ( $val->{value} =~ /^[-+]?\d+$/ || $val->{value} =~ /^[-+]?\d+\.\d+$/ )
                                     && ( ( ! $val->{tags} ) || ( $val->{tags} && $val->{tags} =~ /^[a-zA-Z0-9\.\-_=,]+$/ ) )
                                     && ( ( ! $val->{endpoint} ) || ( $val->{endpoint} && $val->{endpoint} =~ /^[a-zA-Z0-9\.\-_=,]+$/ ) )
                                   )
                                   {
                                       my %tags;
                                       $tags{endpoint} = $val->{endpoint} if $val->{endpoint};
                                       map{ my @x = split /=/, $_, 2; $tags{$x[0]} = $x[1]; }
                                           split( /,/, $val->{tags} )
                                               if $val->{tags};

                                       $this->{collector}->set( $val->{metric}, $val->{value} , \%tags );
                                   }
                                   else { $mesg = "error"; }
                               }
                           }

                           $handle->push_write($this->_html( $mesg ));
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
        interval => 10,
        cb => sub { 
            return unless my $carry = $this->{carry};
            my $exmonitor = eval{ YAML::XS::Load decode_base64( $carry ) };
            warn "node exporter carry data err: $@" if $@;
            if( $exmonitor && ref $exmonitor eq 'HASH' )
            {
                $extendedMonitor = $exmonitor;
                $carryerror = 0;
            }
            else
            {
                $carryerror = 1;
            }
        }
    );

    return \%timer;
}

1;
