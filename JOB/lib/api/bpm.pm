package api::bpm;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;
use LWP::UserAgent;

use POSIX;
use Time::Local;
use File::Temp;

get '/bpm/menu' => sub {
    my $pmscheck = api::pmscheck( 'openc3_agent_read' ); return $pmscheck if $pmscheck;

    my $conf = eval{ YAML::XS::LoadFile '/data/Software/mydan/JOB/bpm/config/menu' };

    return $@ ? +{ stat => $JSON::false, info => "load config fail:$@" } : +{ stat => $JSON::true, data => $conf };
};

get '/bpm/variable/:bpmname' => sub {
    my $param = params();
    my $error = Format->new(
        bpmname => qr/^[a-zA-Z\d][a-zA-Z\d\-]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_agent_read' ); return $pmscheck if $pmscheck;

    my $conf = [];
    eval{
        my $pluginconf = "/data/Software/mydan/JOB/bpm/config/flow/$param->{bpmname}/plugin";
        if( -f $pluginconf )
        {
            my $plugin = YAML::XS::LoadFile $pluginconf;
            my $index = 0;
            for my $name ( @$plugin )
            {
                $index ++;
                my $pluginfile = "/data/Software/mydan/Connector/pp/bpm/action/$name/data.yaml";
                my $pluginfileself = "/data/Software/mydan/JOB/bpm/config/flow/$param->{bpmname}/plugin.conf/$name.yaml";
                $pluginfile = $pluginfileself if -f $pluginfileself;

                $pluginfileself = "/data/Software/mydan/JOB/bpm/config/flow/$param->{bpmname}/plugin.conf/$index.$name.yaml";
                $pluginfile = $pluginfileself if -f $pluginfileself;

                my $config = YAML::XS::LoadFile $pluginfile;
                my $idx = 0;
                for my $opt ( @{$config->{option}} )
                {
                    push @$conf, +{ %$opt, name => "$index.".$opt->{name}, idx => $idx ++ };
                }
            }
        }
        else
        {
            $conf = YAML::XS::LoadFile "/data/Software/mydan/JOB/bpm/config/flow/$param->{bpmname}/variable";
        }
    };
    return $@ ? +{ stat => $JSON::false, info => "load config fail:$@" } : +{ stat => $JSON::true, data => $conf };
};

get '/bpm/log/:bpmuuid' => sub {
    my $param = params();
    my $error = Format->new( 
        bpmuuid => qr/^[a-zA-Z\d]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', 0 ); return $pmscheck if $pmscheck;

    my @col = qw( id step info time );
    my $r = eval{ $api::mysql->query( sprintf( "select %s from openc3_job_bpm_log where bpmuuid='$param->{bpmuuid}'", join ",", @col ), \@col )}; 

    return +{ stat => $JSON::false, info => $@ } if $@;

    my %res;
    for( @$r )
    {
        my $step = $_->{step};
        $res{$step} ||= [];
        push @{ $res{$step} }, $_;
    }
    return +{ stat => $JSON::true, data => \%res };
};

get '/bpm/var/:bpmuuid' => sub {
    my $param = params();
    my $error = Format->new( 
        bpmuuid => qr/^[a-zA-Z\d]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', 0 ); return $pmscheck if $pmscheck;

    my $file = "/data/Software/mydan/JOB/bpm/task/$param->{bpmuuid}";
    my $efile = "/data/Software/mydan/JOB/bpm/task/$param->{bpmuuid}.data/data.yaml";
    $file = $efile if -f $efile;
    my $var = eval{ YAML::XS::LoadFile $file };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $var };
};

post '/bpm/var/:bpmuuid' => sub {
    my $param = params();
    my $error = Format->new( 
        bpmuuid => qr/^[a-zA-Z\d]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', 0 ); return $pmscheck if $pmscheck;

    my $bpmuuid = $param->{bpmuuid};

    my $var = eval{ YAML::XS::LoadFile "/data/Software/mydan/JOB/bpm/task/$param->{bpmuuid}" };
    return +{ stat => $JSON::false, info => $@ } if $@;
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $path = "/data/Software/mydan/JOB/bpm/task/$bpmuuid.data";
    mkdir $path unless -f $path;
    my $tempuuid = sprintf "%s%04d", POSIX::strftime( "%Y%m%d%H%M%S", localtime ), int rand 10000;
    if( $param->{bpm_variable} )
    {
        $param->{bpm_variable}{_jobname_ } = $var->{_jobname_};
        $param->{bpm_variable}{_user_    } = $user;
        $param->{bpm_variable}{_bpmuuid_ } = $bpmuuid;
        eval{ YAML::XS::DumpFile "$path/data.$tempuuid.yaml", $param->{bpm_variable} };
        return +{ stat => $JSON::false, info => $@ } if $@;
        return +{ stat => $JSON::false, info => "link fail" } if system "ln -fsn data.$tempuuid.yaml $path/data.yaml";
    }

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
