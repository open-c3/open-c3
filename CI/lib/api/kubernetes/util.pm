package api::kubernetes::util;
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

our %handle = %api::kubernetes::handle;

#kubectl get node --show-labels
#用于亲和性的标签选择
#name = node, pod, node_pod
get '/kubernetes/util/labels/:name' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
        name => qr/^[a-z][a-z_]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my $cmd = join ' && ', map{ "$kubectl get $_ -A --show-labels 2>/dev/null" }split /_/, $param->{name};
    my $handle = 'getlabels';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? );
};

$handle{getlabels} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my @x = split /\n/, $x;
    my %label;
    for( @x )
    {
        my ( $label ) = reverse split /\s+/, $_;
        map{ my ( $k, $v ) = split /=/, $_, 2; $label{$k}{$v} = 1 if defined $v }split /,/, $label;
    }

    my %res;
    $res{key} = [ sort keys %label ];
    
    for my $key ( keys %label )
    {
        $res{value}{$key} = [ sort keys %{$label{$key}} ];
    }
    return +{ stat => $JSON::true, data => \%res };
};

true;
