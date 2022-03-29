#!/data/Software/mydan/perl/bin/perl -I/data/Software/mydan/CI/lib -I/data/Software/mydan/CI/private/lib
use strict;
use warnings;
use FindBin qw( $RealBin );
use MYDan::Util::OptConf;
use uuid;

=head1 SYNOPSIS

 $0 [--repository 726939051292.dkr.ecr.us-east-1.amazonaws.com/xxx]
 $0 [--repository 726939051292.dkr.ecr.us-east-1.amazonaws.com/xxx] [--dockerfile Dockerfile_web (default(Dockerfile))]
 $0 [--repository 726939051292.dkr.ecr.us-east-1.amazonaws.com/xxx] [--dockerfile Dockerfile_web (default(Dockerfile))] [--registry 726939051292,726939051293]
 $0 [--build '--build-arg http_proxy=http://10.10.1.2:8118']

=cut

my $option = MYDan::Util::OptConf->load();
my %o = $option->set(  dockerfile => 'Dockerfile' )->get( qw( repository=s dockerfile=s registry=s build=s ) )->dump();
$option->assert( 'repository' );

map{ die "$_ format error.\n" unless $o{$_} =~ /^[a-zA-Z0-9_\.\/\-:]+$/; }qw( repository dockerfile );

$o{region} = $o{repository} =~ /dkr\.ecr\.([a-z0-9-]+)\.amazonaws\.com/ ? $1 : die "nofind region";
$o{registry} =~ s/,/ /g if $o{registry};

my $ticket = $ENV{TICKETFILE} ? "AWS_CONFIG_FILE=$ENV{TICKETFILE}" : '';

die "PROJECTID error" unless defined $ENV{PROJECTID} && $ENV{PROJECTID} =~ /^\d+$/;
die "VERSION error" unless $ENV{VERSION} && $ENV{VERSION} =~ /^[a-zA-Z0-9:\.\-_]+$/;

my $path = "/data/glusterfs/ci_repo/$ENV{PROJECTID}/$ENV{VERSION}";
my $temp = "/data/ci-scripts_temp/" . uuid->new()->create_str;

die "mkdir temp fail:$!" if system "mkdir -p '$temp'";

if (-f $path )
{
    die "untar fail: $!" if system "tar -zxf '$path' -C '$temp'";
}
elsif( -d $path )
{
    die "rsync fail: $!" if system "rsync -aP --delete $path/ $temp/";
} else {
    die "nofind ci_repo"
}

chdir $temp or die "chdir fail";

my $registryids = $o{registry} ? "--registry-ids $o{registry}" : "";
my $password = `$ticket aws ecr get-login-password --region '$o{region}' $registryids`;
chomp $password;

my @addr = split /\//, $o{repository};
die "get aws ecr password format error" unless $password && $password =~ /^[a-zA-Z0-9=]+$/;
die "login fail" if system "docker login -u AWS -p '$password' 'https://$addr[0]'";

print "[INFO]docker login success.\n";

my $dockerfilestr = `cat '$o{dockerfile}'`;
if( $dockerfilestr =~ /^FROMOPENC3/ )
{
    chomp $dockerfilestr;
    die "get FROMOPENC3 image name fail" unless $dockerfilestr =~ /^FROMOPENC3: ([a-zA-Z0-9\/\-:\._]+)$/;
    my $fromopenc3 = $1;
    die "docker tag fail:$!" if system "docker tag '$fromopenc3' '$o{repository}:$ENV{VERSION}'";
    print "[INFO]docker tag done.\n";

    die "docker rmi fail: $!" if system "docker rmi '$fromopenc3'";
    print "[INFO]docker rmi imageceche done.\n";
}
else
{
    my $buildarg = $o{build} || '';
    print "docker build -t '$o{repository}:$ENV{VERSION}' -f '$o{dockerfile}' $buildarg .\n";
    die "docker build fail:$!" if system "docker build -t '$o{repository}:$ENV{VERSION}' -f '$o{dockerfile}' $buildarg .";
    print "[INFO]docker build done.\n";
}

print "docker push $o{repository}:$ENV{VERSION}\n";
die "docker push fail: $!" if system "docker push $o{repository}:$ENV{VERSION}";
print "[INFO]docker push done.\n";

print "docker push $o{repository}:latest\n";
die "docker tag latest fail: $!" if system "docker tag $o{repository}:$ENV{VERSION} $o{repository}:latest";
die "docker push fail: $!" if system "docker push $o{repository}:latest";
print "[INFO]docker push done.\n";

die "docker rmi fail: $!" if system "docker rmi $o{repository}:$ENV{VERSION}";
die "docker rmi fail: $!" if system "docker rmi $o{repository}:latest";
print "[INFO]docker rmi done.\n";

die "remove temp fail:$!" if system "rm -rf '$temp'";
