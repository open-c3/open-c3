package api::kubernetes::node;
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

get '/kubernetes/node' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl get node -o wide 2>/dev/null", 'getnode' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

$handle{getnode} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my @x = split /\n/, $x;

    my ( @title, @r ) = map{ s/-/_/g; split /\s+/, $_ } shift @x;
    splice @title,7, 0, splice @title, -2;

    map
    {
        my @col = split /\s+/, $_;
        splice @col,7, 0, splice @col, -2;
        splice @col, $#title, -1, join ' ',splice @col, $#title;
        push @r, +{ map{ $title[$_] => $col[$_]  }0..$#title };
        $r[-1]{stat} = +{  map{ $_ => 1 } split /,/, $r[-1]{STATUS} };
    }@x;

    return +{ stat => $JSON::true, data => \@r, };
};

post '/kubernetes/node/cordon' => sub {
    my $param = params();
    my $error = Format->new( 
        node => qr/^[a-zA-Z0-9][a-zA-Z0-9_\.]+$/, 1,
        cordon => [ 'in', 'cordon', 'uncordon' ], 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;
    
    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl '$param->{cordon}' '$param->{node}' 2>&1", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

get '/kubernetes/node/taint' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
        nodename => qr/^[a-zA-Z0-9\-\._]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "c3mc-k8s-node-taint -i $param->{ticketid} -n $param->{nodename} 2>/dev/null", 'getnodetaint' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

$handle{getnodetaint} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my ( @x, @r )= split /\n/, $x;
    for my $x ( @x )
    {
        my @s = split /\s+/, $x;
        push @r, +{ key => $s[0], value => $s[1], effect => $s[2] };

    }

    return +{ stat => $JSON::true, data => \@r, };
};

post '/kubernetes/node/taint' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
        nodename => qr/^[a-zA-Z0-9\-\._]+$/, 1,
        key => qr/^[a-zA-Z0-9\-\._]+$/, 1,
        value => qr/^[a-zA-Z0-9\-\._]+$/, 1,
        effect => qr/^[a-zA-Z0-9\-\._]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl taint nodes $param->{nodename} '$param->{key}=$param->{value}:$param->{effect}' 2>/dev/null", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

del '/kubernetes/node/taint' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
        nodename => qr/^[a-zA-Z0-9\-\._]+$/, 1,
        key => qr/^[a-zA-Z0-9\-\._]+$/, 1,
        effect => qr/^[a-zA-Z0-9\-\._]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl taint nodes $param->{nodename} '$param->{key}:$param->{effect}-' 2>/dev/null", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

true;
