package api::c3mc::jumpserver;
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

堡垒机/提供数据给堡垒机

查询全量数据的时需要root权限
查询单个数据只需要read权限

其中ip查询的时会把内外网ip都查询一遍。

有过滤条件的情况下返回数据的data字段是HASH

cache: 为1时返回缓存数据，更快。

ips、uuids: 一次查询多个，用逗号分隔，返回数组

=cut

get '/c3mc/jumpserver' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid  => qr/^[a-zA-Z0-9][a-zA-Z0-9\-_]+$/, 0,
        ip    => qr/^\d+\.\d+\.\d+\.\d+$/, 0,
        uuids => qr/^[a-zA-Z0-9][a-zA-Z0-9\-_,]+$/, 0,
        ips   => qr/^[\.\d,]+$/, 0,
        cache => qr/^\d+$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my @auth = ( $param->{uuid} || $param->{ip} ) ? ( 'openc3_ci_read', 0 ) : ( 'openc3_ci_root' );
    my $pmscheck = api::pmscheck( @auth ); return $pmscheck if $pmscheck;

    my $filter = +{
        uuid  => $param->{uuid },
        ip    => $param->{ip   },
        uuids => $param->{uuids},
        ips   => $param->{ips  },
 
    };

    my $cmd = "c3mc-device-ingestion-jumpserver 2>&1";
    if( $param->{cache} )
    {
        my $cache = '/data/Software/mydan/Connector/local/jumpserver.txt';
        $cmd = "cat $cache 2>&1" if -f $cache;
    }

    my $handle = 'jumpserver';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter  }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{jumpserver} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;
    my @res;
    my @col = qw( uuid instanceId hostName ip inIP exIP os site vpc_id vpc_name product_owner ops_owner department );
    for( split /\n/, $x )
    {
        my @x = split /;/, $_;
        push @res, +{ map{ $col[$_] => $x[$_]}0.. @col -1 };
    }

    my $data = \@res;
    if( $filter->{uuid} || $filter->{ip} )
    {

        my @x;
        @x = grep{ $_->{uuid} eq $filter->{uuid} }@res if $filter->{uuid};
        @x = grep{ $_->{ip} eq $filter->{ip} || $_->{inIP} eq $filter->{ip} || $_->{exIP} eq $filter->{ip} }@res if $filter->{ip};

        $data = @x ? $x[0] : +{};
    }
    
    if( $filter->{uuids} )
    {
        my %f = map{ $_ => 1 }split /,/, $filter->{uuids};
        $data = [ grep{ $f{ $_->{uuid}} }@res ];
    }
 
    if( $filter->{ips} )
    {
        my %f = map{ $_ => 1 }split /,/, $filter->{ips};
        $data = [ grep{ $f{ $_->{ip}} || $f{ $_->{inIP}} || $f{ $_->{exIP}} }@res ];
    }
 
    return +{ stat => $JSON::true, data => $data };
};

true;
