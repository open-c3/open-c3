package BPM::Task::Config;

use warnings;
use strict;
use POSIX;
use JSON;

my $base = "/data/Software/mydan/JOB/bpm/task";
sub new
{
    my ( $class ) = @_;
    bless +{}, ref $class || $class;
}

sub save
{
    my ( $this, $config, $user, $jobname ) = @_;

    my $bpmuuid = sprintf "BPM%s%04d", POSIX::strftime( "%Y%m%d%H%M%S", localtime ), int rand 10000;
    $config->{_user_   } = $user;
    $config->{_editor_ } = $user;
    $config->{_jobname_} = $jobname;
    $config->{_bpmuuid_} = $bpmuuid;
    eval{ YAML::XS::DumpFile "$base/$bpmuuid", $config };
    die "dump config error: $@" if $@;
    return $bpmuuid;
}

sub resave
{
    my ( $this, $config, $user, $uuid ) = @_;
    my $var = eval{ YAML::XS::LoadFile "$base/$uuid" };
    die "load config fail: $@" if $@;

    my $path = "$base/$uuid.data";
    mkdir $path unless -f $path;

    my $tempuuid = sprintf "%s%04d", POSIX::strftime( "%Y%m%d%H%M%S", localtime ), int rand 10000;
    $config->{_user_   } = $var->{_user_};
    $config->{_editor_ } = $user;
    $config->{_jobname_} = $var->{_jobname_};
    $config->{_bpmuuid_} = $uuid;
 
    eval{ YAML::XS::DumpFile "$path/data.$tempuuid.yaml", $config };
    die "save config fail: $@" if $@;

    die "link fail" if system "ln -fsn data.$tempuuid.yaml $path/data.yaml";
}

sub savevar
{
    my ( $this, $uuid, $k, $v ) = @_;

    my $path = "$base/$uuid.data";
    mkdir $path unless -f $path;

    system "echo '$k: $v' >> '$path/var'";
}

sub get
{
    my ( $this, $uuid ) = @_;

    my $file = "$base/$uuid";
    my $efile = "$base/$uuid.data/data.yaml";
    $file = $efile if -f $efile;

    # C3TODO 230313 BPM表单，面对数字类型的数据load方式优化
    # 用YAML::XS 直接load会导致数字类型加载进来后，在接口上得到的是字符串类型，这样会导致前端的显示异常
    # 这里使用了yaml2json进行转换，看是否有其它更好的方式

    #my $var = eval{ YAML::XS::LoadFile $file };
    my $var = eval{ my $xx = `cat '$file'|yaml2json`; die "cat err" if $?; JSON::decode_json ( $xx // '' ) };
    die "load $file fail: $@" if $@;
    my $varfile = "$base/$uuid.data/var";
    if( -f $varfile )
    {
        my    @x = `cat '$varfile'`;
        chomp @x;
        my ( %tmp, %var );
        for( @x )
        {
            next unless $_ =~ /^\s*([a-zA-Z0-9][a-zA-Z0-9\-\._]+):\s*([a-zA-Z0-9][a-zA-Z0-9\-\._,]+)$/;
            my ( $k, $v ) = ( $1, $2 );
            $var{$k} ||= [];
            push( @{$var{$k}}, $v ) unless $tmp{$k}{$v} ++;
        }
        map{ $var->{"var.$_"} = join ",", @{$var{$_}}; }keys %var;
    }

    return $var;
}

1;
