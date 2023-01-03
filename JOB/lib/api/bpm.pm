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
use BPM::Flow;

get '/bpm/menu' => sub {
    my $pmscheck = api::pmscheck( 'openc3_agent_read' ); return $pmscheck if $pmscheck;

    my $conf = eval{ BPM::Flow->new()->menu() };

    return $@ ? +{ stat => $JSON::false, info => "get menu fail:$@" } : +{ stat => $JSON::true, data => $conf };
};

get '/bpm/variable/:bpmname' => sub {
    my $param = params();
    my $error = Format->new(
        bpmname => qr/^[a-zA-Z\d][a-zA-Z\d\-]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_agent_read' ); return $pmscheck if $pmscheck;

    my $conf = eval{ BPM::Flow->new()->variable( $param->{bpmname} )};
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
    my $var = eval{ BPM::Task::Config->new()->get( $param->{bpmuuid} ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $var };
};

post '/bpm/var/:bpmuuid' => sub {
    my $param = params();
    my $error = Format->new( 
        bpmuuid => qr/^[a-zA-Z\d]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', 0 ); return $pmscheck if $pmscheck;

    return +{ stat => $JSON::false, info => $@ } if $@;
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ BPM::Task::Config->new()->resave( $param->{bpm_variable}, $user, $param->{bpmuuid} ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

post '/bpm/optionx' => sub {
    my $param = params();
    my $error = Format->new( 
        jobname  => qr/^[a-zA-Z0-9][a-zA-Z\d\-]+$/, 1,
        stepname => qr/^\d+\.[a-zA-Z0-9][a-zA-Z\d\-]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', 0 ); return $pmscheck if $pmscheck;

    return +{ stat => $JSON::false, info => $@ } if $@;
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $step = eval{ YAML::XS::LoadFile "/data/Software/mydan/JOB/bpm/config/flow/$param->{jobname}/plugin" };
    return +{ stat => $JSON::false, info => "load step fail:$@" } if $@;

    my ( $stepindex, $varname ) = split /\./, $param->{stepname};

    my $pluginname = $step->[$stepindex-1];
    return +{ stat => $JSON::false, info => "nofind plugin name" } unless $pluginname;

    my $config = BPM::Flow->new()->subvariable( $param->{jobname}, $stepindex, $pluginname );

    my $stepconfig;
    for ( @{ $config->{option}} )
    {
        $stepconfig = $_ if $_->{name} eq $varname;
    }
    return +{ stat => $JSON::false, info => "nofind stepconfig" } unless $stepconfig;

    my $command = $stepconfig->{command};
    return +{ stat => $JSON::false, info => "nofind command" } unless $command;

    my $currvar = $param->{bpm_variable};
    my %var;
    for my $k ( keys %$currvar )
    {
        my ( $ti, $tk ) = split /\./, $k;
        next unless $ti eq $stepindex;
        $var{$tk} = $currvar->{$k};
    }

    my $json = eval{JSON::to_json \%var };
    die "var to json fail: $@" if $@;

    my ( $TEMP, $tempfile ) = File::Temp::tempfile();
    print $TEMP $json;
    close $TEMP;

    my @x = `cat '$tempfile'|$command`;
    chomp @x;
    my @data;
    for my $name ( @x )
    {
        my $alias = $name;
        if( $name =~ /;/ )
        {
            ( $name, $alias ) = split /;/, $name, 2;
        }
        push @data, +{ name => $name, alias => $alias };
    }
    return +{ stat => $JSON::true, data => \@data };
};

true;
