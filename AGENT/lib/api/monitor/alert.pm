package api::monitor::alert;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON;
use POSIX;
use api;
use Format;
use LWP::UserAgent;

my $exip;
BEGIN{
    $exip = `cat cat /etc/job.exip`;
    chomp $exip;
};
get '/monitor/alert/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my $ua = LWP::UserAgent->new;
    $ua->timeout( 3 );

    my $url = "http://$exip:9093/api/v2/alerts";
    my $res = $ua->get( $url );
    unless( $res->is_success )
    {
        return +{ stat => $JSON::false, info => "get alert from altermanager error: $url" };
    }
    my $data = eval{JSON::from_json $res->content};
    unless( !$@ && defined $data && ref $data eq 'ARRAY' )
    {
        return +{ stat => $JSON::false, info => "get alert from altermanager error: $url" };
    }

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => [ grep{ $_->{labels} && $_->{labels}{"fromtreeid"} && $_->{labels}{"fromtreeid"} eq $projectid }@$data ] };
};

true;
