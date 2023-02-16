package api::dockershell;
use Dancer ':syntax';
use FindBin qw( $RealBin );
use Util;

my ( %env, $dockershellcount, $exip );
BEGIN{ 
    %env = Util::envinfo( qw( envname domainname dockershellcount ) );
    $dockershellcount = $env{dockershellcount} || 1;

    $exip = `cat /etc/ci.exip`;
    chomp $exip;
    die "/etc/ci.exip nofind" unless $exip;
};

=pod

CI/进入构建调试的shell中

=cut

any '/dockershell' => sub {
    my $param = params();
    my ( $image, $projectid, $tag, $siteaddr ) = @$param{qw( image projectid tag siteaddr )};

    return "params undef" unless $image && $projectid;
    return "no cookie" unless my $u = cookie( $api::cookiekey );

    $tag = defined $tag ? "&tag=$tag" : '';
    my $id = 1 + int rand $dockershellcount;
    redirect "$siteaddr/webshell/index.html?u=$u&image=$image&projectid=$projectid$tag";
    #redirect "http://dockershell$id.$env{envname}.ci.$env{domainname}?u=$u&image=$image&tree=$tree$tag";
};

true;
