package api::kubernetes;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use POSIX;
use Format;
use Time::Local;
use File::Temp;
use Digest::MD5;

sub getKubectlCmd($$$$$)
{
    my ( $db, $ticketid, $user, $company, $checkauth ) = @_;

    my $and = "create_user='$user' or share='$company' or share like '%_T_${company}_T_%' or share like '%_P_${user}_P_%'";
    $and .= " or share like '%_TR_${company}_TR_%' or share like '%_PR_${user}_PR_%'" unless $checkauth;

    my $r = eval{ $db->query( "select ticket,create_user,share  from openc3_ci_ticket where id='$ticketid' and ( $and ) " ); };
    die "no auth\n" unless $r && @$r;
    my ( $version, $ticket, $proxy ) = split /_:separator:_/, $r->[0][0], 3;

#    die "no auth\n" if $checkauth && ! ( $r->[0][1] eq $user || $r->[0][2] eq $company ); 

    die "version format error in ticket" unless $version =~ /^v\d+\.\d+\.\d+$/;
    my $kubectl = $version eq 'v0.0.0' ? "kubectl" : "kubectl_$version";
    my $proxyenv = $proxy && $proxy =~ /^[a-zA-Z0-9:\.@]+$/ ? "HTTPS_PROXY='socks5://$proxy'" : "";

    my $md5 = Digest::MD5->new->add( $ticket )->hexdigest;
    my $kubeconfig = "/data/Software/mydan/tmp/kubeconfig_${ticketid}_$md5";
    return "KUBECONFIG=$kubeconfig $proxyenv $kubectl" if -f $kubeconfig;

    my $fh = File::Temp->new( UNLINK => 0, SUFFIX => '.config', TEMPLATE => "/data/Software/mydan/tmp/kubeconfig_${ticketid}_XXXXXXXX" );
    print $fh $ticket;
    close $fh;

    die "rename fail: $!" if system "mv '$fh' '$kubeconfig'";
    return "KUBECONFIG=$kubeconfig $proxyenv $kubectl";
}

sub getKubectlAuth($$$$$)
{
    my ( $db, $ticketid, $user, $company, $checkauth ) = @_;

    my @ns;
    my $and = "create_user='$user' or share='$company' or share like '%_T_${company}_T_%' or share like '%_P_${user}_P_%'";
    $and .= " or share like '%_TR_${company}_TR_%' or share like '%_PR_${user}_PR_%'" unless $checkauth;

    my $r = eval{ $db->query( "select ticket,create_user,share  from openc3_ci_ticket where id='$ticketid' and ( $and ) " ); };
    unless( $r && @$r )
    {
        my $sql = 
           $checkauth 
            ? "select namespace from openc3_ci_k8s_namespace_auth where ticketid='$ticketid' and user='$user' and auth='rw'"
            : "select namespace from openc3_ci_k8s_namespace_auth where ticketid='$ticketid' and user='$user'";

        my $x = eval{ $db->query( $sql ); };
        die "get info err: $@" if $@;
        die "no auth\n" unless $x && @$x;
        @ns = map{ @$_ }@$x;

        $r = eval{ $db->query( "select ticket,create_user,share  from openc3_ci_ticket where id='$ticketid'" ); };
    }
    my ( $version, $ticket, $proxy ) = split /_:separator:_/, $r->[0][0], 3;

#    die "no auth\n" if $checkauth && ! ( $r->[0][1] eq $user || $r->[0][2] eq $company ); 

    die "version format error in ticket" unless $version =~ /^v\d+\.\d+\.\d+$/;
    my $kubectl = $version eq 'v0.0.0' ? "kubectl" : "kubectl_$version";
    my $proxyenv = $proxy && $proxy =~ /^[a-zA-Z0-9:\.@]+$/ ? "HTTPS_PROXY='socks5://$proxy'" : "";

    my $md5 = Digest::MD5->new->add( $ticket )->hexdigest;
    my $kubeconfig = "/data/Software/mydan/tmp/kubeconfig_${ticketid}_$md5";
    return ( "KUBECONFIG=$kubeconfig $proxyenv $kubectl", @ns ) if -f $kubeconfig;

    my $fh = File::Temp->new( UNLINK => 0, SUFFIX => '.config', TEMPLATE => "/data/Software/mydan/tmp/kubeconfig_${ticketid}_XXXXXXXX" );
    print $fh $ticket;
    close $fh;

    die "rename fail: $!" if system "mv '$fh' '$kubeconfig'";
    return ( "KUBECONFIG=$kubeconfig $proxyenv $kubectl", @ns );
}

our %handle;
$handle{showinfo} = sub { return +{ info => shift, stat => shift ? $JSON::false : $JSON::true }; };
$handle{showdata} = sub { return +{ data => shift, stat => shift ? $JSON::false : $JSON::true }; };

sub rowfilter
{
    my ( $filter, @row ) = @_;
    if( 
        $filter && ref $filter eq 'HASH' && $filter->{rowfilter}  &&
        $filter->{rowfilter}{key} && @{$filter->{rowfilter}{key}} &&
        $filter->{rowfilter}{col} && @{$filter->{rowfilter}{col}}
    )
    {
        my @key = @{$filter->{rowfilter}{key}};
        my @col = @{$filter->{rowfilter}{col}};

        my %key = map{ $_ => 1 }@key;
        my @new = ();
        for my $row ( @row )
        {
            push @new, $row if grep{$key{$row->{$_}}}@col;
        }
        @row = @new;

    }
    return @row;
}

$handle{showtable} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my ( @x, @r ) = split /\n/, $x;
    my @title = split /\s+/, shift @x;
    for( @x )
    {
        my @col = split /\s+/;
        my %tmp = map { $title[$_] => $col[$_] } 0 .. $#title;
        push @r, \%tmp;
    }
    @r = rowfilter( $filter, @r );
    return +{ stat => $JSON::true, data => \@r, };
};

true;
