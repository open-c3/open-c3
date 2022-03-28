package api::kubernetes::k8sbackup;
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
use uuid;
use api::kubernetes;

our %handle = %api::kubernetes::handle;
our $datapath = "/data/glusterfs/kerbunetes_backup";

get '/kubernetes/k8sbackup' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    system "mkdir -p $datapath/$param->{ticketid}" unless -d "$datapath/$param->{ticketid}";

    my ( $cmd, $handle ) = ( "cd $datapath/$param->{ticketid} && ls 2>/dev/null", 'showk8sbackup' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? );
};

$handle{showk8sbackup} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my @data = map{ +{ NAME => $_ } }split /\n/, $x;
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@data };
};

get '/kubernetes/k8sbackup/download' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
        name => qr/^[a-zA-Z0-9][a-zA-Z0-9\-\._]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $r = eval{ $api::mysql->query( "select create_user from openc3_ci_ticket where id='$param->{ticketid}' and create_user='$user'" ); };
    return +{ stat => $JSON::false, info => "Only allow owner to download" } unless $r && @$r;

    my $path = "$datapath/$param->{ticketid}/$param->{name}";
    my $name = sprintf "K8S.%s%s.$param->{name}", uuid->new()->create_str, uuid->new()->create_str;

    return +{ stat => $JSON::false, info => "link fail: $!" } if system "ln -fsn '$path' '/data/Software/mydan/JOB/downloadpath/$name'";
    return +{ stat => $JSON::true, data => $name };
};

true;
