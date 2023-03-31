package api::c3mc::bpm;
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

BPM/获取BPM下拉选项

=cut

post '/c3mc/bpm/optionx' => sub {
    my $param = params();
    my $error = Format->new( 
        jobname  => qr/^[a-zA-Z0-9][a-zA-Z\d\-]+$/, 1,
        stepname => qr/^\d+\.[a-zA-Z0-9][a-zA-Z\d\-_\.]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', 0 ); return $pmscheck if $pmscheck;
    my ( $TEMP, $file ) = File::Temp::tempfile();
    print $TEMP YAML::XS::Dump $param;
    close $TEMP;

    my $cmd = "cat '$file'|c3mc-bpm-optionx 2>&1";
    my $filter = +{
        cmd   => $cmd,
    };

    my $handle = 'bpmoptionx';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{bpmoptionx} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, info => "run $filter->{cmd} fail: $x" } if $status;

    my $d = eval{ YAML::XS::Load Encode::encode_utf8($x);};
    return $@ ? +{ stat => $JSON::false, data => "run $filter->{cmd} data load fail: $@" } : +{ stat => $JSON::true, data => $d };
};

true;
