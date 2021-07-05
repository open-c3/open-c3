#!/data/Software/mydan/perl/bin/perl -I/data/Software/mydan/CI/lib -I/data/Software/mydan/CI/private/lib
use strict;
use warnings;
use FindBin qw( $RealBin );
use MYDan::Util::OptConf;
use uuid;

=head1 SYNOPSIS

 $0 [--repository harbor-china.open-c3.com/test/openc3-test]
 $0 [--repository harbor-china.open-c3.com/test/openc3-test] [--dockerfile Dockerfile_web (default(Dockerfile))]

=cut

my $option = MYDan::Util::OptConf->load();
my %o = $option->set(  dockerfile => 'Dockerfile' )->get( qw( repository=s dockerfile=s ) )->dump();
$option->assert( 'repository' );

map{ die "$_ format error.\n" unless $o{$_} =~ /^[a-zA-Z0-9_\.\/\-:]+$/; }qw( repository dockerfile );

die "TUSERNAME error" unless defined $ENV{TUSERNAME} && $ENV{TUSERNAME} =~ /^[a-zA-Z0-9:\.\-_]+$/;
die "TPASSWORD error" unless defined $ENV{TPASSWORD} && $ENV{TPASSWORD} =~ /^[a-zA-Z0-9,:\.\-_;\/=\+]+$/;
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

my @addr = split /\//, $o{repository};
die "login fail" if system "docker login -u '$ENV{TUSERNAME}' '$addr[0]' -p '$ENV{TPASSWORD}'";
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
    print "[INFO]docker rmi imagecache done.\n";
}
else
{
    die "docker build fail:$!" if system "docker build -t '$o{repository}:$ENV{VERSION}' -f '$o{dockerfile}' .";
    print "[INFO]docker build done.\n";
}

print "docker push $o{repository}:$ENV{VERSION}\n";
die "docker push fail: $!" if system "docker push $o{repository}:$ENV{VERSION}";
print "[INFO]docker push done.\n";

die "docker rmi fail: $!" if system "docker rmi $o{repository}:$ENV{VERSION}";
print "[INFO]docker rmi done.\n";

die "remove temp fail:$!" if system "rm -rf '$temp'";
