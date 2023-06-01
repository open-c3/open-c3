package OPENC3::MYDan::MonitorV3::FalconMigrate;

use warnings;
use strict;
use Carp;

use YAML::XS;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;

my ( $i, $error, %index ) = ( 0, 0 );
my $version;

sub new
{
    my ( $class, %this ) = @_;

    $this{port} ||= 9999;

    $version = 40 + ( 2 - scalar @{$this{server}} );

    bless \%this, ref $class || $class;
}

sub clean 
{
    my $this = shift;
    for my $index ( keys %index )
    {
        if( $index{$index}{timeout} < time )
        {
            delete $index{$index};
            next;
        }

        if( $index{$index}{handle_s} ) 
        {

            if( $index{$index}{handle_c}->destroyed() )
            {
               for my $id ( 1 .. @{$this->{server}} )
               {
                   $index{$index}{handle_s}{$id}->destroy() if $index{$index}{handle_s}{$id} && ! $index{$index}{handle_s}{$id}->destroyed();
               }
 
            }

            my $handle_s_destroyed = 0;
            for my $id ( 1 .. @{$this->{server}} )
            {
                $handle_s_destroyed ++ if ( $index{$index}{handle_s}{$id} &&  $index{$index}{handle_s}{$id}->destroyed() ) || ( $index{$index}{m} && $index{$index}{m}{$id} && $index{$index}{m}{$id} eq 2 );
            }
 

            $index{$index}{handle_c}->destroy() if  ! $index{$index}{handle_c}->destroyed() && $handle_s_destroyed eq @{$this->{server}};

            if( $index{$index}{handle_c}->destroyed() && $handle_s_destroyed eq @{$this->{server}} )
            {
                 delete $index{$index};
            }
        }
        else
        {
            delete $index{$index} if $index{$index}{handle_c}->destroyed();
        }
    }
}

sub allocate
{
    my $this = shift;

    $this->clean();

    my ( $idx ) = sort{ $a <=> $b } grep{ ! $index{$_}{m} && $index{$_}{handle_c_data} }keys %index;
    return unless $idx;

    my $sid = 0;
    map{ $sid ++; $this->_allocate( $idx, $_, $sid ); }@{$this->{server}};
}

sub _allocate
{
    my ( $this, $idx, $server, $sidx ) = @_;


    my ( $host, $port ) = split /:/, $server;

    return if $index{$idx}{m}{$sidx};
    $index{$idx}{m}{$sidx} = 1;

    tcp_connect $host, $port, sub {
        my ( $fh, $tip, $tport ) = @_;

        my $index = $idx;
        my $srv   = $server;
        my $sid   = $sidx;

        unless( $fh )
        {
            print "tcp_connect $host:$port err $!\n";
            $index{$index}{m}{$sid} = 2;
            return;
        }

        $index{$index}{m}{$sid} = 3;

        my $handle; $handle = new AnyEvent::Handle( 
            fh => $fh,
            keepalive => 1,
            rbuf_max  => 1024000,
            wbuf_max  => 1024000,
            autocork  => 1,
            on_eof => sub{
               if( $index{$index}{sended} && $index{$index}{sended} eq $sid )
               {
                   $index{$index}{handle_c}->destroy() unless $index{$index}{handle_c}->destroyed();
               }
               $this->allocate();

            },
            on_read => sub {
                my $self = shift;
	        my $len = length $self->{rbuf};

                $self->push_read (
                    chunk => $len,
                    sub { 
                        $index{$index}{sended} = $sid unless $index{$index}{sended};
                        $index{$index}{handle_c}->push_write($_[1]) if $sid eq $index{$index}{sended};
                    }
                );
            },
            on_error => sub {

               delete $index{$index}{handle_s}{$sid};
               delete $index{$index}{m}{$sid};

               $this->allocate();
             },
        );

        $handle->push_write($index{$index}{handle_c_data}) if $index{$index}{handle_c_data};
        $index{$index}{handle_s}{$sid} = $handle;
    };
    return 1;
}

sub getHtml
{
    my $content = shift;
    my $length = length $content;
    my @h = (
        "HTTP/1.0 200 OK",
        "Content-Length: $length",
        "Content-Type: text/plain",
    );

    return join "\n",@h, "", $content;
}

sub run
{
    my $this = shift;

    my $cv = AnyEvent->condvar;

    tcp_server undef, $this->{port}, sub {
       my ( $fh, $tip, $tport ) = @_ or die "tcp_server: $!";

       my $index = ++ $i;

       my $handle; $handle = new AnyEvent::Handle( 
           fh => $fh,
           keepalive => 1,
           rbuf_max  => 1024000,
           wbuf_max  => 1024000,
           autocork  => 1,
           on_eof => sub{
               for my $id ( 1 .. @{$this->{server}} )
               {
                   $index{$index}{handle_s}{$id}->destroy() if $index{$index}{handle_s}{$id} && ! $index{$index}{handle_s}{$id}->destroyed();
               }
 
               $this->allocate();
           },
           on_read => sub {
               my $self = shift;
	       my $len = length $self->{rbuf};
               $self->push_read (
                   chunk => $len,
                   sub { 


                       if( $_[1] =~ m#GET /status/ HTTP/# )
                       {
                           $handle->push_write(getHtml("version: $version\nerror: $error\naccepts: $i\n"));
                           $handle->push_shutdown();
                           $handle->destroy();
                           return;
                       }

                       $index{$index}{handle_c_data} .= $_[1];

                       for my $id ( 1 .. @{$this->{server}} )
                       {
                           $index{$index}{handle_s}{$id}->push_write($_[1]) if $index{$index}{handle_s}{$id};
                       }
                       $this->allocate();
                   }
               );
           },
           on_error => sub {

               $error ++;
               for my $id ( 1 .. @{$this->{server}} )
               {
                   $index{$index}{handle_s}{$id}->destroy() if $index{$index}{handle_s}{$id} && ! $index{$index}{handle_s}{$id}->destroyed();
               }
 
               $this->allocate();
            },
        );

        $index{$index}{handle_c} = $handle;
        $index{$index}{timeout} = time + 900;

        $this->allocate();
    };

    my $ti = AnyEvent->timer(
        after    => 1, 
        interval => 15,
        cb => sub { 
            $this->allocate();
        }
    ); 

    $cv->recv;
}

1;
