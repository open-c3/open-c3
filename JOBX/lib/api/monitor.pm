package api::monitor;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON;
use POSIX;
use api;

get '/monitor/metrics' => sub {
    my $param = params();

    header( 'Content-Type' => 'text/plain' ) unless $param->{json};

    my @col = qw( id time time_s stat host type key val );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from `monitor` order by id", join( ',', map{"`$_`"}@col ) ), \@col
        )};

    my $err = 0;
    my $timeout = time - 90;

    map{
        if( $_->{time_s} < $timeout )
        {
            $_->{val} = 0;
            $_->{stat} = 'timeout';
        }
        $err ++ unless $_->{stat} eq 'ok' || $_->{stat} eq 'healthy';
    }@$r;

    my $t = time;
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime( $t ) );

    unshift @$r, +{ id => 0, time => $time, time_s => $t, stat => ( $err ? 'err': 'ok' ) , host => 'openc3', type => 'system', key => 'openc3_system_error', val => $err };

    if( $param->{json} )
    {
        return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
    }
    else
    {
        return join "", map{ "$_->{key}\{host=\"$_->{host}\",type=\"$_->{type}\"\} $_->{val}\n" }@$r;
    }
};

true;
