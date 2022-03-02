package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::Path;

use strict;
use warnings;
use Carp;
use POSIX;
use OPENC3::MYDan::MonitorV3::NodeExporter::Collector;

our %declare = (
    node_path => 'path exist',
    node_path_check => 'path match content',
);

our $collectorname = 'node_path';

sub co
{
    my $extpath = $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::extendedMonitor->{path};
    my ( $error, @path, @stat ) = ( 0 );
    @path = @$extpath if $extpath && ref $extpath eq 'ARRAY';

    for my $path ( @path )
    {
        my @check = split /\|/, $path;
        if ( @check < 2 ) { $error = 1; next; }

        unless( $check[0] && ( $check[0] eq 'file' || $check[0] eq 'dir' || $check[0] eq 'link' ) )
        {
            warn "monitor path $check[0]";
            $error = 1;
            next;
        }

        unless( $check[1] && $check[1] =~ /^\/[\/a-zA-Z0-9\.\-_]+$/ )
        {
            warn "monitor path $check[1]";
            $error = 1;
            next;
        }

        if( @check >= 3 && $check[2] !~ /^[\/a-zA-Z0-9 \.\-_]+$/ )
        {
            warn "monitor path $check[2]";
            $error = 1;
            next;
        }

        if( $check[0] eq 'file' )
        {
            push @stat, +{ name => 'node_path', value => -f $check[1] ? 1 : 0 ,lable => +{ type => 'file', path => $check[1] } };
        }
        elsif( $check[0] eq 'dir' )
        {
            push @stat, +{ name => 'node_path', value => -d $check[1] ? 1 : 0 , lable =>  +{ type => 'dir', path => $check[1] } };
        }
        elsif( $check[0] eq 'link' )
        {
            my $link = -l $check[1] ? 1 : 0;
            push @stat, +{ name => 'node_path', value => $link , lable => +{ type => 'link', path => $check[1] } };
            if( $check[2] )
            {
                my $match = 0;
                if( $link )
                {
                    $match = index( readlink( $check[1] ), $check[2] ) < 0 ? 0 : 1;
                }
                push @stat, +{ name => 'node_path_check', value => $match, lable => +{ type => 'link', path => $check[1], check => $check[2] } };
            }
        }
    }

    push @stat, +{ name => 'node_collector_error', value => $error, lable => +{ collector => $collectorname } };
    return @stat;
}

1;
