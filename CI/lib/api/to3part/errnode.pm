package api::to3part::errnode;
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

    $key{jobx} = $ENV{OPEN_C3_RANDOM} if $ENV{OPEN_C3_RANDOM};
};

=pod

监控/获取所有异常的主机ip

=cut

get '/to3part/errnode' => sub {
    my $param = params();
    my $error = Format->new()->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my ( $appkey, $appname ) = map{ request->headers->{$_} }qw( appkey appname );
    $appname = $param->{appname} if ( ! $appname ) && $param->{appname};
    $appkey  = $param->{appkey } if ( ! $appkey  ) && $param->{appkey };

    return  +{ stat => $JSON::false, info => "key err", code => 1, msg => "key err" } unless $appkey && $appname && $key{$appname} && $key{$appname} eq $appkey;

    my $filter = +{};
    my $cmd = "c3mc-mon-agent-install-errnode 2>&1";
    my $handle = 'to3part_errnode';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter  }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{to3part_errnode} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;
    return +{ stat => $JSON::true, data => [ grep{/^\d+\.\d+\.\d+\.\d+$/}split /\n/, $x ] };
};

true;
