package api::release;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;

get '/release' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d[\d,]*$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $ua = LWP::UserAgent->new;

    for my $api ( qw( job ci ) )
    {
        my $res = $ua->get( "http://api.$api.open-c3.org/release?id=$param->{id}" );
        return "call api.$api fail" unless $res->is_success;

        my $stat = $res->decoded_content;

        if( $stat eq 'false' )
        {
            return 'false';
        }
        elsif( $stat ne 'true' )
        {
            return "get mesg $stat from api.$api"
        }
    }

    return 'true';
};

true;
