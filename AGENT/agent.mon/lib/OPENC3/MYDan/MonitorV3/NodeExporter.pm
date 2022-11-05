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

use Sys::Hostname;

use OPENC3::MYDan::MonitorV3::NodeExporter::Collector;

sub new
{
    my ( $class, %this ) = @_;
    die "port undef" unless $this{port};

    $this{hostname} = Sys::Hostname::hostname;
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

my ( $index, %index ) = ( 0 );
sub run
{
    my $this = shift;

    my $cv = AnyEvent->condvar;

    #$AnyEvent::HTTP::TIMEOUT = 10;
    #$AnyEvent::HTTP::MAX_PER_HOST = 10000;

    tcp_server undef, $this->{port}, sub {
       my ( $fh ) = @_ or die "tcp_server: $!";

       my $idx = $index ++;
       $index{$idx} = '';

       my $handle; $handle = new AnyEvent::Handle( 
           fh => $fh,
           keepalive => 1,
           rbuf_max => 1024000,
           wbuf_max => 1024000,
           autocork => 1,

           on_eof => sub{
               warn "on_eof";
               $handle->push_shutdown();
               $handle->destroy();
               delete $index{$idx};
           },
           on_timeout => sub{
               warn "timeout";
               $handle->push_shutdown();
               $handle->destroy();
               delete $index{$idx};
           },
           timeout => 5,
           on_read => sub {
               my $self = shift;
               my $len = length $self->{rbuf};
               $self->push_read (
                   chunk => $len,
                   sub { 
                       $index{$idx} .= $_[1];
                       return unless $index{$idx} =~ /\r\n\r\n/;

                       my $data = $index{$idx};
                       if( $data =~ m#/proxy_([\d+\.\d+\.\d+\.\d+]+)_proxy# )
                       {
                           my $ip = $1;
                           
                           my $carry = $data =~ m#(carry_[a-zA-Z0-9+/=]+_carry)# ? $1 : "";
                           my $debug = $data =~ /debug=1/ ? "debug=1" : "";

                           my $url = "http://$ip:$this->{port}/metrics?c=/$carry/$debug";

                           my $monagent9100 = $data =~ /conf_monagent9100_conf/ ? 1 : 0;
                           $url = "http://$ip:9100/metrics" if $monagent9100;

                           http_get $url, sub { 
                               my $c = $_[0] || $_[1]->{URL}. " -> ".$_[1]->{Reason};

                               my $debug = $data =~ /debug=1/ ? 1 : 0;
                               my @debug;
                               if( $debug )
                               {
                                   @debug = (
                                       "# DEBUG",
                                       "# monagent9100: $monagent9100",
                                       "# Proxy HOSTNAME: $this->{hostname}"
                                   );
                               }
                               $handle->push_write( $this->_html( join "\n", "# HELP OPEN-C3 Proxy debug[$debug]", @debug, $c ) ) if $c;
                               $handle->push_shutdown();
                               $handle->destroy();
                               delete $index{$idx};
                           };
                           return;
                       }

                       if( $data =~ m#/metrics# )
                       {
                           $this->{collector}->setExt( $1 )
                               if $data =~ m#/carry_([a-zA-Z0-9+/=]+)_carry#;

                           $handle->push_write( $this->_html( $this->{collector}->get( $data =~ /debug=1/ ? 1 : 0 ) ) );
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
                                       my %tags = ( source => 'apipush' );
                                       $tags{endpoint} = $val->{endpoint} if $val->{endpoint};
                                       map{ my @x = split /=/, $_, 2; $tags{$x[0]} = $x[1]; }
                                           split( /,/, $val->{tags} )
                                               if $val->{tags};

                                       $this->{collector}->set( $val->{metric}, $val->{value} , \%tags );
                                   }
                                   else { $mesg = "error"; }
                               }
                           }

                           $handle->push_write( $this->_html( $mesg ) );
                       }
                       else
                       {
                           my $content = ' <html> <head><title>OPEN-C3 Node Exporter</title></head> <body> <h1>OPEN-C3 Node Exporter</h1> <p><a href="/metrics">Metrics</a></p> </body> </html> ';
                           $handle->push_write( $this->_html( $content, 'text/html' ) );
                       }

                       $handle->push_shutdown();
                       $handle->destroy();
                       delete $index{$idx};

                    }
               );
           },
        );
    };

    $cv->recv;
}

1;
