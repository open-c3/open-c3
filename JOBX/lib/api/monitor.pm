package api::monitor;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON;
use POSIX;
use api;

get '/monitor' => sub {
    my $pmscheck = api::pmscheck( 'openc3_jobx_write', 0 ); return $pmscheck if $pmscheck;

    my @col = qw( id time time_s stat host type key val );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from `monitor`", join( ',', map{"`$_`"}@col ) ), \@col
        )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
