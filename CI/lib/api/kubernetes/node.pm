package api::kubernetes::node;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use JSON;
use POSIX;
use api;
use Format;
use Time::Local;
use File::Temp;
use api::kubernetes;

our %handle;

get '/kubernetes/node' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid} ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    return +{ stat => $JSON::true, data => +{ kubecmd => "$kubectl get node -o wide", handle => 'getnode' }}
         if request->headers->{"openc3event"};


    my ( $cmd, $handle ) = ( "$kubectl get node -o wide", 'getnode' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    my @x = `$cmd`;
    return &{$handle{$handle}}( @x );
};

$handle{getnode} = sub
{
    my @x = split /\n/, shift;

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

    
    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid} ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    return +{ stat => $JSON::true, data => +{ kubecmd => "$kubectl  '$param->{cordon}' '$param->{node}' 2>&1;sleep 10", handle => 'setnodecordon' }}
         if request->headers->{"openc3event"};


    my ( $cmd, $handle ) = ( "$kubectl '$param->{cordon}' '$param->{node}' 2>&1", 'setnodecordon' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    my $x = `$cmd`;
    return &{$handle{$handle}}( $x ); 
};

$handle{setnodecordon} = sub
{
    my $x = shift;
    my $stat = ( $x =~ / uncordoned\n$/ || $x =~ / cordoned\n$/ ) ? $JSON::true : $JSON::false;  
    return +{ stat => $stat, info => $x, };
};

true;
