package api::nodeinfo;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Code;
use Format;


my ( $code, $check );
BEGIN { ( $code, $check ) = map{ Code->new( $_ ) }qw( nodeinfo nodeinfo_check ); };

=pod

服务树机器/获取列表

=cut

get '/nodeinfo/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my @node = eval{ $code->run( db => $api::mysql, id => $param->{projectid} ) };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@node };
};

=pod

服务树机器/权限检查

node=node1,node2,node3

=cut

get '/nodeinfo/:projectid/check' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        node => qr/^[a-zA-Z0-9_\-\.,]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $info = eval{ $check->run( db => $api::mysql, id => $param->{projectid}, node => $param->{node} ) };
    return $@ ? +{ stat => $JSON::false, info => $@ } 
        : +{ stat => $JSON::true, data => $info };
};

=pod

服务树机器/总数获取

=cut

get '/nodeinfo/:projectid/count' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @node = eval{ $code->run( db => $api::mysql, id => $param->{projectid} ) };
    return $@ ? +{ stat => $JSON::false, info => $@ } :
        +{ stat => $JSON::true, data => +{ node => scalar @node }};
};

true;
