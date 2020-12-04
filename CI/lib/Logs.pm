package Logs;
use warnings;
use strict;
use Carp;
use FindBin qw( $RealBin );
use POSIX;
#use Logger::Syslog;

$|++;

our $H;
BEGIN{
    my $temp = "/var/log/open-c3.log";
    open $H, ">>", $temp or die "open $temp fail: $!";
};

sub new
{
    my ( $class, $type ) = @_;
    confess "type error" unless defined $type && $type =~ /^[a-zA-Z0-9\._]+$/;

    bless +{ type => $type }, ref $class || $class;
}

sub _write
{
    my ( $this, @mesg ) = @_;
    my $time = POSIX::strftime( "%Y-%m-%d_%H:%M:%S", localtime );
    map{
        my $t = $_ =~ /\n$/ ? '' : "\n";
        print $H "$time: ". $_ . $t;
    } @mesg;
}

sub say
{
    my $this = shift;
#    map{ notice( "cisys $this->{type} $_") }@_;
    map{ $this->_write( "INFO cisys $this->{type} $_" ) }@_;
}

sub err
{
    my $this = shift;
    map{ $this->_write( "ERROR cisys $this->{type} $_" ) }@_;
#    map{ error( "cisys $this->{type} $_") }@_;
}

sub die
{
    my $this = shift;
#    map{ error( "cisys $this->{type} $_") }@_;
    map{ $this->_write( "FAIL cisys $this->{type} $_" ) }@_;
    die join ',', @_;
}

1;
