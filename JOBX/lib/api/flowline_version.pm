package api::flowline_version;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;
use Util;
use uuid;

get '/flowline_version/:flowlineid' => sub {
    my $param = params();
    my $error = Format->new( flowlineid => qr/^\d+$/, 1,)->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my @col = qw( jobxuuid version create_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from `openc3_jobx_flowline_version` where flowlineid='$param->{flowlineid}'", join( ',', @col ) ), \@col
        )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => @$r ? $r->[0] : +{} };
};

true;
