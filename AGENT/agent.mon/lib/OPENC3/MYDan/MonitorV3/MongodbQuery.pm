package OPENC3::MYDan::MonitorV3::MongodbQuery;

use warnings;
use strict;
use Carp;

use YAML::XS;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::HTTP;
use MIME::Base64;

my $cmc;
BEGIN
{
    system "mkdir -p /data/open-c3-data/mongodb-exporter-v3/cache";
    $cmc = 1 if $ENV{C3_MongodbQuery_Container};
};

my ( %proxy, %carry );

sub new
{
    my ( $class, %this ) = @_;
    die "port undef" unless $this{port};

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
    my ( $this, $content, $addr, $proxy, $url, $debug  ) = @_;
    my @debug;

    if( $debug )
    {
        $proxy ||= 'Null';
        @debug = (
            "# DEBUG",
            "# ADDR: $addr",
            "# PROXY: $proxy",
            "# URL: $url",
        );
    }

    $content = join "\n",
        "# HELP OPEN-C3 MongodbQuery debug[$debug]",
        @debug,
        $content;

    return $this->_html( $content );
}

sub getResponseRoot
{
    my $this = shift;
    my $content = 
'
<html>
    <head><title>OPEN-C3 Mongodb Query</title></head>
    <body>
        <h1>OPEN-C3 Mongodb Query</h1>
    </body>
</html>
';

    return $this->_html( $content, 'text/html' );
}

my ( $index, %index ) = ( 0 );

sub run
{
    my $this = shift;

    my $loadproxy = sub { 
            my $proxy = eval{ YAML::XS::LoadFile $this->{proxy} };

            if ( $@ ) { warn "load proxy file fail: $@"; return; }
            unless( $proxy && ref $proxy eq 'HASH' ) { warn "load proxy file no HASH"; return; }

            %proxy = %$proxy;
        };

    &$loadproxy() if $this->{proxy};
    my $proxyUpdate = AnyEvent->timer(
        after    => 3, 
        interval => 6,
        cb       => $loadproxy,
    ) if $this->{proxy}; 

    my $loadcarry = sub { 
            my $carry = eval{ YAML::XS::LoadFile $this->{carry} };

            if ( $@ ) { warn "load carry file fail: $@"; return; }
            unless( $carry && ref $carry eq 'HASH' ) { warn "load carry file no HASH"; return; }

            %carry = %$carry;
        };

    &$loadcarry() if $this->{carry};
    my $carryUpdate = AnyEvent->timer(
        after    => 5, 
        interval => 6,
        cb       => $loadcarry,
    ) if $this->{carry}; 

    #$AnyEvent::HTTP::TIMEOUT = 10;
    $AnyEvent::HTTP::MAX_PER_HOST = 512;
    my $cv = AnyEvent->condvar;
    tcp_server undef, $this->{port}, sub {
       my ( $fh ) = @_ or die "tcp_server: $!";

       my $idx = $index ++;
       $index{$idx} = +{ time => time };
       my $handle; $handle = new AnyEvent::Handle( 
           fh        => $fh,
           keepalive => 1,
           rbuf_max  => 1024000,
           wbuf_max  => 1024000,
           autocork  => 1,
           on_eof    => sub{
               printf "close $idx: timeoiut %s\n", time - $index{$idx}{time};
               $handle->destroy();
               delete $index{$idx};
           },
           on_read   => sub {
               my $self = shift;
               my $len = length $self->{rbuf};
               $self->push_read (
                   chunk => $len,
                   sub { 
                       my $data = $_[1];

                       print "$data\n" if $cmc;
                       if( $data =~ m#/query_([a-z0-9][a-z0-9\-\.]+[a-z0-9]):(\d+)_query# )
                       {
                           my ( $ip, $port ) = ( $1, $2 );
                           my $addr = "$ip:$port";

                           my %exp = ( ip => $ip, port => $port, user => "", password => "" );

                           if( $data =~ m#carry_([a-zA-Z0-9+/=]+)_carry#  )
                           {
                               my $carry = $1;
                               my $exp = eval{ YAML::XS::Load decode_base64( $carry ) };
                               warn "mongodb query carry data err: $@" if $@;
                               %exp = ( %exp, %$exp ) if $exp && ref $exp eq 'HASH';
                           }

                           if( $carry{$addr} && ref $carry{$addr} )
                           {

                               %exp = ( %exp, %{$carry{$addr} } );

                               $carry{$addr} = encode_base64( YAML::XS::Dump $carry{$addr} );
                               $carry{$addr} =~ s/\n//g;
                           }

                           my $url;
                           if( $proxy{$addr} )
                           {
                               my $carry = $carry{$addr}      ? "carry_$carry{$addr}_carry" : "";
                               my $debug = $data =~ /debug=1/ ? "debug=1"                 : "";
                               $url = "http://$proxy{$addr}:65115/mongodb/metrics/query_${addr}_query/$carry/$debug";
                           }
                           else
                           {
                               $url = "http://openc3-mongodb-exporter-v3-$ip-$port:9001/metrics";
                               eval{
                                   YAML::XS::DumpFile "/data/open-c3-data/mongodb-exporter-v3/cache/$addr", \%exp;
                               };
                               warn "ERROR dump fail: $@" if $@;
                           }

                           return if $index{$idx}{http_get};
                           $index{$idx}{http_get} = http_get $url, sub { 
                               my $tmpurl = $_[1]->{URL};
                               $tmpurl =~ s/carry_.*_carry/carry_xxx_carry/;
                               my $c = $_[0] || $tmpurl. " -> ".$_[1]->{Reason};
                               return if $handle && $handle->destroyed;
                               $handle->push_write($this->getResponseProxy($c, $addr, $proxy{$addr}, $tmpurl, $data =~ /debug=1/ ? 1 : 0 )) if $c;
                               $handle->push_shutdown();
                               $handle->destroy();
                               delete $index{$idx};
                           };
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

    $cv->recv;
}

1;
