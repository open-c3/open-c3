package api::monitor;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON;
use POSIX;
use api;

get '/monitor' => sub {
    my @col = qw( id time time_s stat host type key val );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from `monitor`", join( ',', map{"`$_`"}@col ) ), \@col
        )};

    my $timeout = time - 90;
    map{ $_->{stat} = 'timeout' if $_->{time_s} < $timeout }@$r;

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

get '/monitor/metrics' => sub {
    header( 'Content-Type' => 'text/plain' );

    my @col = qw( id time time_s stat host type key val );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from `monitor`", join( ',', map{"`$_`"}@col ) ), \@col
        )};

    my $timeout = time - 90;
    map{ $_->{val} = 0 if $_->{time_s} < $timeout }@$r;

    return join "", map{ "$_->{key}\{host=\"$_->{host}\",type=\"$_->{type}\"\} $_->{val}\n" }@$r;
};

true;
