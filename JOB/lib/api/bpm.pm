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
        bpmname => qr/^[a-zA-Z\d]+$/, 1,
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
                my $config = YAML::XS::LoadFile  "/data/Software/mydan/Connector/pp/bpm/action/$name/data.yaml";
                for my $opt ( @{$config->{option}} )
                {
                    push @$conf, +{ %$opt, name => "$index.".$opt->{name} };
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

true;
