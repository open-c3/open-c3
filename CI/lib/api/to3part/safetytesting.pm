package api::to3part::safetytesting;
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

my %key;
BEGIN{
    my $f = '/data/open-c3-data/to3part.yml';
    if( -f $f )
    {
        my $c = eval{ YAML::XS::LoadFile $f };
        warn "load $f err: $@" if $@;
        %key = %$c if $c && ref $c eq 'HASH';
    }
};

=pod

第三方接口/获取所有需要安全检测的资源信息

=cut

get '/to3part/safetytesting' => sub {
    my $param = params();
 
    my ( $appkey, $appname ) = map{ request->headers->{$_} }qw( appkey appname );
    $appname = $param->{appname} if ( ! $appname ) && $param->{appname};
    $appkey  = $param->{appkey } if ( ! $appkey  ) && $param->{appkey };

    return  +{ stat => $JSON::false, info => "key err", code => 1, msg => "key err" } unless $appkey && $appname && $key{$appname} && $key{$appname} eq $appkey;

    my $filter = +{};

    my $cmd = "c3mc-device-ingestion-safetytesting 2>&1";
    my $handle = 'safetytesting';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter  }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{safetytesting} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;
    my @res;
    my @col = qw( cloudtype uuid instance_name lanip wanip yewu_owner yunwei_owner expire );
    for( split /\n/, $x )
    {
        my @x = split /;/, $_;
        push @res, +{ map{ $col[$_] => $x[$_] // "" }0.. @col -1 };
    }

    return +{ stat => $JSON::true, data => \@res };
};

true;
