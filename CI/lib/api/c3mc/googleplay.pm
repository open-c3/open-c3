package api::c3mc::googleplay;
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

GooglePlay/回复评论

=cut

post '/c3mc/googleplay/review/reply' => sub {
    my $param = params();
    my $error = Format->new( 
        review_id  => qr/^.+$/, 1,
        text       => qr/.+/, 1,
        callback   => qr/^.+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', 0 ); return $pmscheck if $pmscheck;
    my ( $TEMP, $file ) = File::Temp::tempfile();
    print $TEMP YAML::XS::Dump $param;
    close $TEMP;

    my $cmd = "cat '$file'|c3mc-googleplay-review-reply 2>&1";
    my $filter = +{
        cmd   => $cmd,
    };

    my $handle = 'googleplayreviewreply';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{googleplayreviewreply} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, info => "run $filter->{cmd} fail: $x" } if $status;

    my $d = eval{ Encode::encode_utf8($x);};
    return $@ ? +{ stat => $JSON::false, data => "run $filter->{cmd} data load fail: $@" } : +{ stat => $JSON::true, data => $d };
};

true;
