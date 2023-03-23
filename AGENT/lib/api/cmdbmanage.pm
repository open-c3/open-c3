package api::cmdbmanage;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;

=pod

CMDB/管理/获取账号类型列表

=cut

get '/cmdbmanage' => sub {
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;
    my $conf = eval{ YAML::XS::LoadFile "/data/Software/mydan/AGENT/device/conf/cmdbmanage.yml" };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $conf };
};

=pod

CMDB/管理/获取某个公有云的配置

=cut

get '/cmdbmanage/:name' => sub {
    my $param = params();
    my $error = Format->new( 
        name => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $dpath = "/data/Software/mydan/AGENT/device/conf/account/$param->{name} /data/Software/mydan/AGENT/device/conf/accountx/$param->{name}x";
    $dpath = "/data/open-c3-data/device/curr/compute/idc-node/data.tsv" if $param->{name} eq 'idc-node';
    $dpath = "/data/open-c3-data/device/curr/database/$param->{name}/data.tsv" if grep{ $param->{name} eq "idc-$_" }qw( mysql redis mongodb );

    my $x = `cat $dpath`;
    utf8::decode($x);
    return +{ stat => $JSON::true, data => +{ config => $x } };
};


=pod

CMDB/管理/编辑某个公有云的配置

=cut

post '/cmdbmanage' => sub {
    my $param = params();
    my $error = Format->new( 
        name => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => "EDIT CMDBMANAGE", content => "name:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $dpath = "/data/Software/mydan/AGENT/device/conf/account/$param->{name} /data/Software/mydan/AGENT/device/conf/accountx/$param->{name}x";
    $dpath = "/data/open-c3-data/device/curr/compute/idc-node/data.tsv" if $param->{name} eq 'idc-node';
    $dpath = "/data/open-c3-data/device/curr/database/$param->{name}/data.tsv" if grep{ $param->{name} eq "idc-$_" }qw( mysql redis mongodb );

    eval{
        if( $param->{config} )
        {
            my @config = split /\n/, $param->{config};

            my @dpath = split /\s+/, $dpath;

            if( @dpath > 1 )
            {
                my ( $fh1, $fh2 );
                open( $fh1, ">", $dpath[0] ) or die "Can't open file: $!";
                open( $fh2, ">", $dpath[1] ) or die "Can't open file: $!";
                map{ print $fh1 "$_\n"; }grep{ $_ !~ /\*/ }@config;
                map{ print $fh2 "$_\n"; }grep{ $_ =~ /\*/ }@config;
                close $fh1;
                close $fh2;
 
            }
            else
            {
                my $fh;
                open( $fh, ">", $dpath ) or die "Can't open file: $!";
                map{ print $fh "$_\n"; }@config;
                close $fh;
            }
        }
        else
        {
            if( $param->{name} =~ /\-/)
            {
                system "echo -n > '$dpath'";
            }
            else
            {
                system "rm $dpath";
            }
        }
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
