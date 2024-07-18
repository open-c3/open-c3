package api::c3mc::serviceanalysis;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use JSON qw();
use POSIX;
use api;
use Format;
use Time::Local;
use File::Temp;
use api::c3mc;

our %handle = %api::kubernetes::handle;

=pod

监控/服务分析/获取数据

=cut

any '/c3mc/serviceanalysis/tree' => sub {
    my $param = params();
    my $error = Format->new( 
        search => qr/^\d+\.[a-zA-Z0-9][a-zA-Z\d\-_\.]+$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', 0 ); return $pmscheck if $pmscheck;

    my $cmd = "cat /data/Software/mydan/Connector/pp/service-analysis/tree.data | c3mc-base-map2tree 2>&1";
    my $filter = +{};

    my $handle = 'serviceanalysistree';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{serviceanalysistree} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, info => "fail: $x" } if $status;

    my $d = eval{ YAML::XS::Load Encode::encode_utf8($x);};
    return $@ ? +{ stat => $JSON::false, data => "data load fail: $@" } : +{ stat => $JSON::true, data => $d };
};

true;
