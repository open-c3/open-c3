package api::kubernetes::nodecheck;
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
use api::kubernetes;

our %handle = %api::kubernetes::handle;

=pod

节点管理/主机节点健康检查

检查一个节点是否能连上或者是否能同步文件。

注: 该接口不应该放到kubernetes的url下，临时借用的v2版本的接口特性。

可以迁移到c3mc接口中。

=cut

get '/kubernetes/nodecheck' => sub {
    my $param = params();
    my $error = Format->new( 
        treeid => qr/^\d+$/, 1,
        node => qr/^[\d\.,]+$/, 1,
        type => [ 'in', 'call', 'sync' ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{treeid} ); return $pmscheck if $pmscheck;

    my ( $cmd, $handle ) = ( "$RealBin/../bin/node-check-mydan-$param->{type} '$param->{treeid}' '$param->{node}' 2>/dev/null", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? );
};

true;
