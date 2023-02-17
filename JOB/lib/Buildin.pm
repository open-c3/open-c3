package Buildin;

use warnings;
use strict;
use File::Temp;
use MYDan;
use Util;
use LWP::UserAgent;
use JSON;
use Temp;

sub new
{
    my ( $class, @node ) = @_;
    bless +{ node => \@node }, ref $class || $class;
}

sub run
{
    my ( $this, %run ) = @_;

    my @node = @{$this->{node}};
    my %result = map{ $_ => '' }@node;

    my ( $cont, $argv ) = map{ $run{query}{argv}[0]{$_} }qw( cont argv );
    unless( $cont )
    {
        print "cont null\n";
        return %result;
    }

    my ( $timeout, $ticketid, $ticketfile ) = @run{qw( timeout sudo )};
    $timeout ||= 60;
    $ticketfile ||= 0;

    if( $ticketid ) # != 0
    {
#        my %env = Util::envinfo( qw( appname appkey ) );
#        my $ua = LWP::UserAgent->new;
#        $ua->default_header( %env );
#
#        my $res = $ua->get( "http://api.ci.open-c3.org/ticket/$ticketid?detail=1" );
#
#        unless( $res->is_success )
#        {
#            #TODO 确认上层调用是否捕获这个die
#            die "get ticket fail";
#        }
#
#        my $data = eval{JSON::from_json $res->content};
#        unless ( $data->{stat} && $data->{data} && $data->{data}{ticket} && ( $data->{data}{ticket}{JobBuildin} || $data->{data}{ticket}{KubeConfig} ) ) {
#            #TODO 确认上层调用是否捕获这个die
#            die "call ticket result". $data->{info} || '';
#        }
#
#        $ticketfile = Temp->new( chmod => 0600 )->dump( $data->{data}{ticket}{JobBuildin} ) if $data->{data}{ticket}{JobBuildin};
#
        my $x = `c3mc-base-db-get -t openc3_ci_ticket ticket -f "type='JobBuildin' and id=$ticketid"`;
        chomp $x;
        $ticketfile = Temp->new( chmod => 0600 )->dump( $x ) if $x;
    }

    my $build;
    if( $cont =~ s/^#!([a-zA-Z0-9_]+)\n{0,1}// )
    {
        $build = $1;
    }
    else
    {
        print "cont no buildin info\n";
        return %result;
    }


    my $JOBUUID = $run{jobuuid} ? "JOBUUID=$run{jobuuid}" : '';

    my $CONFIGPATH = '';
    if( length $cont )
    {
        my ( $TEMP, $tempfile ) = File::Temp::tempfile();
        print $TEMP $cont;
        close $TEMP;
        $CONFIGPATH = "CONFIGPATH=$tempfile";
    }


    my $path = "$MYDan::PATH/JOB/buildin/$build";
    unless( -e $path )
    {
        print "nofind this buildin code\n";
        return %result;
    }

    my $nodes = join ',', sort @node;
    my $cmd = "TREEID='$run{treeid}' FLOWID='$run{flowid}' VERSION='$run{version}' NODE='$nodes' TIMEOUT=$timeout TICKETFILE=$ticketfile TICKETID=$run{sudo} TASKUUID=$run{taskuuid} DEPLOYENV=$run{deployenv} $JOBUUID $CONFIGPATH $path $argv";

    print "env:\nTREEID='$run{treeid}'\nFLOWID='$run{flowid}'\nVERSION='$run{version}'\nNODE='$nodes'\nTIMEOUT=$timeout\nTICKETFILE=$ticketfile\nTICKETID=$run{sudo}\nTASKUUID=$run{taskuuid}\nDEPLOYENV=$run{deployenv}\n$JOBUUID\n$CONFIGPATH\n";
    print "cmd:\n$path $argv\n";

    print "\n############################## START ##############################\n\n";

    unless( $cmd =~ /^[a-zA-Z0-9\.\-_ '=,\/:"\@]+$/ )
    {
        print "cmd format error\n";
        return %result;
    }

    my @x = `$cmd`;
    chomp @x;
    map
    {
        if( $_ =~ /^([a-zA-Z0-9\-_\.]+):(.+)$/ )
        {
            my ( $n, $c ) = ( $1, $2 );
            $result{$n} .= $c if defined $result{$n};
        }
        $result{_openc3_sys_pluginrefuse_sys_openc3_} = 1 if $_ eq '_openc3_sys_pluginstatus_sys_openc3_:refuse';
    }@x;

    map{ $result{$_} .= "--- 0\n" if $result{$_} eq 'ok'  }@node;
    return %result;
}

1;
