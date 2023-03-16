package api::bpm::k8sapptpl;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;

=pod

BPM/管理/获取k8s应用模版列表

=cut

my $dir = '/data/Software/mydan/Connector/pp/bpm/action/kubernetes-apply/template';

get '/bpm/k8sapptpl' => sub {
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;
    my $conf = [];
    my @x = `cd $dir && ls`;
    chomp @x;
    for( @x )
    {
        push @$conf, +{ name => $_, type => $_ =~ /demo$/ ? 'buildin': 'custom' };
    }
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $conf };
};

=pod

BPM/管理/获取某个k8s应用模版的内容

=cut

get '/bpm/k8sapptpl/:name' => sub {
    my $param = params();
    my $error = Format->new( 
        name => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $dpath = "$dir/$param->{name}";

    my $x = `cat '$dpath'`;
    utf8::decode($x);
    return +{ stat => $JSON::true, data => +{ config => $x } };
};


=pod

BPM/管理/编辑某个模版

=cut

post '/bpm/k8sapptpl' => sub {
    my $param = params();
    my $error = Format->new( 
        name => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => "EDIT K8SAPPTPL", content => "name:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $dpath = "$dir/$param->{name}";

    eval{
        if( $param->{config} )
        {
            $param->{config} .= "\n" unless $param->{config} =~ /\n$/;
            my $fh;
            open( $fh, ">", $dpath ) or die "Can't open file: $!";
            print $fh $param->{config};
            close $fh;
        }
        else
        {
            die "unlink fail" if system "rm '$dpath'";
        }

        die "config-make fail" if system "/data/Software/mydan/Connector/pp/bpm/action/kubernetes-apply/config-make";
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
