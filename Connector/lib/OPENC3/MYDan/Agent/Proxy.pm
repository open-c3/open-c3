package OPENC3::MYDan::Agent::Proxy;

=head1 NAME

MYDan::Agent::Proxy

=head1 SYNOPSIS

 use MYDan::Agent::Proxy;
 my $proxy = MYDan::Agent::Proxy->new( '/conf/file' );
 my %r = $proxy->search( 'node1', 'node2', '10.10.0.1', '10.10.0.2' );
 
 %r = (
      node1 => undef, node2 => undef,
      '10.10.0.1' => 'proxyip',
      '10.10.0.2' => 'proxyip',
 );

=cut

use strict;
use warnings;

use Carp;
use JSON;
use YAML::XS;
use Net::IP::Match::Regexp qw( match_ip create_iprange_regexp_depthfirst );
use Data::Validate::IP qw( is_ipv4 );
use Socket;
use MYDan::Util::Hosts;
use LWP::UserAgent;

sub new
{
    my ( $class, $conf, %self ) = splice @_, 0, 2;

    unless( $self{node} = $ENV{MYDan_Agent_Proxy_Node} )
    {
        if( my $addr =  $ENV{MYDan_Agent_Proxy_Addr} )
        {
            my ( $ua, $header, $res ) 
                = ( LWP::UserAgent->new, $ENV{MYDan_Agent_Proxy_Header} );
            $ua->default_header( map{ split /:/, $_ }split /,/, $header ) if $header;
            $ua->timeout(5);
            for( 0 .. 1 )
            {
                $res = $ua->get($addr);
                last if $res->is_success;
            }
            my $data = eval{ JSON->new->allow_nonref->utf8(1)->decode( $res->content ); };
            die "from_json fail: $@" if $@;
            $self{conf} = $data->{stat} ? $data->{data} : die "stat fail";
    
        }
        else
        {
            $conf = "$conf.private" if -f  "$conf.private";
            confess "no conf" unless $conf && -e $conf;
            $self{conf} = eval{ YAML::XS::LoadFile( $conf ) };
            confess "error: $@" if $@;
        }
    
        $self{conf} = [ $self{conf} ] if ref $self{conf} ne 'ARRAY';
        map{ confess "error: not HASH" unless ref $_; }@{$self{conf}};
    }
    bless \%self, ref $class || $class;
}

sub search
{
    my ( $this, @node, %innet, %result ) = @_;

    if( my $node = $this->{node} )
    {
        return map{ $_ => $node }@node;
    }

    for ( @{$this->{conf}} )
    {
        @node = grep{ ! defined $result{$_} }@node;
        my %r = $this->_search( $_ => @node );
        %result = ( %result, %r );
    }
    return %result;
}

sub _search
{
    my ( $this, $conf,  @node, %innet, %result ) = @_;
    map{ $result{$_} = $conf->{$_} if defined $conf->{$_} }@node;
    @node = grep{ ! defined $result{$_} }@node;

    return %result unless @node;

    my %regex;
    for ( keys %$conf )
    {
        $regex{ $1 } = $conf->{$_} if $_ =~ /^\/(.*)\/$/;
    }

    for my $regex ( sort{ length $b <=> length $a } keys %regex )
    {
        map{ $result{ $_ } = $regex{$regex} if $_ =~ /$regex/ }@node;
        @node = grep{ ! defined $result{$_} }@node;
    }

    return %result unless @node;
    for ( keys %$conf )
    {
        next unless $_ =~ /^\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d{1,2})\s*$/;
        $innet{$_} = $conf->{$_} if is_ipv4( $1 ) && $2 >=0 && $2 <= 32;
    }

    return ( %result, map{ $_ => undef }@node ) unless %innet;

    my $regexp = create_iprange_regexp_depthfirst( \%innet );

    my %hosts = MYDan::Util::Hosts->new()->match( @node );
    for( keys %hosts )
    {
        next if is_ipv4( $hosts{$_} );
        next unless my $name = gethostbyname $_;
        $hosts{$_} = inet_ntoa( $name  );
    }

    return ( %result, map{ $_ => is_ipv4( $hosts{$_} ) ? match_ip( $hosts{$_}, $regexp ) : undef }@node );
}

1;
