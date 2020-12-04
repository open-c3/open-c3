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
    my ( $class, $type, $taskuuid, $db ) = @_;
    confess "type error" unless defined $type && $type =~ /^[a-zA-Z0-9\._]+$/;

    bless +{ type => $type, uuid => $taskuuid, db => $db }, ref $class || $class;
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
#    map{ notice( "jobsys $this->{type} $_") }@_;
    map{ $this->_write( "INFO jobsys $this->{type} $_" ) }@_;
}

sub err
{
    my $this = shift;
    map{ $this->_write( "ERROR jobsys $this->{type} $_" ) }@_;
#    map{ error( "jobsys $this->{type} $_") }@_;
}

sub die
{
    my $this = shift;
#    map{ error( "jobsys $this->{type} $_") }@_;
    map{ $this->_write( "FAIL jobsys $this->{type} $_" ) }@_;

    if( defined $this->{uuid} )
    {
        my $reason = join ',', @_;
        $reason =~ s/'//g;
        $reason ||= 'die, unkown';
        $reason = substr $reason, 0, 100 if length $reason > 100;
        eval{ $this->{db}->execute( "update task set reason='$reason' where uuid='$this->{uuid}' and reason is null" );};
#        error( "jobsys update task $this->{uuid} reason fail:$@" ) if $@;
        $this->_write( "FAIL jobsys update task $this->{uuid} reason fail:$@" );
    }
    die join ',', @_;
}

1;
