package api::monitor::alert;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;
use LWP::UserAgent;

use POSIX;
use Time::Local;

sub gettime
{
    my $t = shift;
    return $t unless $t =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)\.\d+Z$/;
    my $x = timelocal($6,$5,$4,$3,$2-1,$1);
    return POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime( $x + 8 * 3600) );
}

get '/monitor/alert/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my $ua = LWP::UserAgent->new;
    $ua->timeout( 3 );

    my $url = "http://OPENC3_ALERTMANAGER_IP:9093/api/v2/alerts";
    my $res = $ua->get( $url );
    unless( $res->is_success )
    {
        return +{ stat => $JSON::false, info => "get alert from altermanager error: $url" };
    }
    my $data = eval{JSON::decode_json $res->content};
    unless( !$@ && defined $data && ref $data eq 'ARRAY' )
    {
        return +{ stat => $JSON::false, info => "get alert from altermanager error: $url" };
    }

    map{ $_->{generatorURL} =~ s#http://[a-z0-9]+:9090/#$param->{siteaddr}/third-party/monitor/prometheus/# }@$data if $param->{siteaddr};

    map{
        $_->{annotations}{summary} =~ s#(\d+\.\d)\d+%#$1%#;
        $_->{annotations}{description} =~ s#(\d+\.\d)\d+%#$1%#;
        $_->{annotations}{value} =~ s#(\d+\.\d)\d+%#$1%#;
        $_->{startsAt} = gettime( $_->{startsAt} );
    }@$data;

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => [ grep{ $_->{labels} && $_->{labels}{"fromtreeid"} && $_->{labels}{"fromtreeid"} eq $projectid }@$data ] };
};

true;
