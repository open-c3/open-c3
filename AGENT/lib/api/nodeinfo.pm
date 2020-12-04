package api::nodeinfo;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use JSON;
use POSIX;
use MIME::Base64;
use api;
use Code;
use Format;


my ( $code, $check );
BEGIN { ( $code, $check ) = map{ Code->new( $_ ) }qw( nodeinfo nodeinfo_check ); };

get '/nodeinfo/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @node = eval{ $code->run( db => $api::mysql, id => $param->{projectid} ) };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@node };
};

#node=node1,node2,node3
get '/nodeinfo/:projectid/check' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        node => qr/^[a-zA-Z0-9_\-\.,]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $info = eval{ $check->run( id => $param->{projectid}, node => $param->{node} ) };
    return $@ ? +{ stat => $JSON::false, info => $@ } 
        : +{ stat => $JSON::true, data => $info };
};

get '/nodeinfo/:projectid/count' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @node = eval{ $code->run( id => $param->{projectid} ) };
    return $@ ? +{ stat => $JSON::false, info => $@ } :
        +{ stat => $JSON::true, data => +{ node => scalar @node }};
};

true;
