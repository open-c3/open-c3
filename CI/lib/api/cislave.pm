package api::cislave;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;

my $cislave;

BEGIN{
    my $f = "/data/Software/mydan/CI/cislave/conf/slave.yml";
    if( -f $f )
    {
        my $x = eval{ YAML::XS::LoadFile $f };
        die "load $f fail: $@" if $@;
        $cislave = $x if $x && ref $x eq 'ARRAY';
    }
    else
    {
        $cislave = [];
    }
};
=pod

获取CI中可用的slave列表。

=cut

get '/cislave/node' => sub {
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my @node = ( +{ host => 'master', alias => 'master' } );
    for( @$cislave )
    {
        $_->{alias} ||= $_->{host};
        push @node, $_;
    }
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@node };
};

true;
