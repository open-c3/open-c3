package api::loginext;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use api;

our %data;
BEGIN{
    my @key = qw(
        default
        google.on
        google.client_id
        google.domain
    );

    for my $k ( @key )
    {
        my $x = `c3mc-sys-ctl 'sys.loginext.$k'`;
        chomp $x;
        my @k = split /\./, $k, 2;
        if( @k > 1 )
        {
            $data{$k[0]}{$k[1]} = $x;
        }
        else
        {
            $data{$k} = $x;
        }
    }
};

=pod

登录扩展/获取概览

=cut

get '/loginext' => sub {
    return +{
        stat => $JSON::true,
        data => \%data,
    };
};

true;
