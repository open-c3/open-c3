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
        stepname => qr/^\d+\.[a-zA-Z0-9][a-zA-Z\d\-_\.]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', 0 ); return $pmscheck if $pmscheck;

    return +{ stat => $JSON::false, info => $@ } if $@;
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $step = eval{ YAML::XS::LoadFile "/data/Software/mydan/JOB/bpm/config/flow/$param->{jobname}/plugin" };
    return +{ stat => $JSON::false, info => "load step fail:$@" } if $@;

    my ( $stepindex, $varname ) = split /\./, $param->{stepname}, 2;
    my $grp = '';
    if( $varname =~ /^(\d+)\./)
    {
        ( $grp, $varname ) = split /\./, $varname, 2;
    }

    my $pluginname = $step->[$stepindex-1];
    return +{ stat => $JSON::false, info => "nofind plugin name" } unless $pluginname;

    my $config = BPM::Flow->new()->subvariable( $param->{jobname}, $stepindex, $pluginname );

    my $stepconfig;
    for ( @{ $config->{option}} )
    {
        $stepconfig = $_ if $_->{name} eq $varname;
    }
    return +{ stat => $JSON::false, info => "nofind stepconfig: $varname" } unless $stepconfig;

    my $command = $stepconfig->{command};
    return +{ stat => $JSON::false, info => "nofind command" } unless $command;

    my $currvar = $param->{bpm_variable};
    my %var;

    #BPM TODO, 传入的数据过多，这个是把所有插件的数据压扁传入选项命令中.
    #其后会有一层覆盖，用本插件本步骤的进行覆盖，极端情况下可能会有子步骤变量缺失，
    #但是确用了全局变量，需要明确是外部变量，格式如 x.var
    for my $k ( keys %$currvar )
    {
        my $tk = $k;
        $tk =~ s/^\d+\.//;
        $tk =~ s/^\d+\.//;
        $var{$tk} = $currvar->{$k};
    }

    for my $k ( keys %$currvar )
    {
        my ( $ti, $tk ) = split /\./, $k, 2;
        next unless $ti eq $stepindex;
        if( $grp )
        {
            my $tgrp;
            ( $tgrp, $tk ) = split /\./, $tk, 2;
            next unless $tgrp eq $grp;
        }
        $var{$tk} = $currvar->{$k};
    }

    if( ref $command eq 'ARRAY' )
    {
        my @data;
        if( $command->[0] eq 'list' && $command->[1] )
        {
            my %uniq;
            for my $k ( sort keys %$currvar )
            {
                my $tk = $k;
                $tk =~ s/^\d+\.//;
                $tk =~ s/^\d+\.//;
                next if $uniq{$currvar->{$k}} ++;
                push @data, +{ name => $currvar->{$k}, alias => $currvar->{$k} } if $tk eq $command->[1];
            }
        }
        return +{ stat => $JSON::true, data => \@data };
    }

    my $json = eval{JSON::to_json \%var };
    die "var to json fail: $@" if $@;

    my ( $TEMP, $tempfile ) = File::Temp::tempfile();
    print $TEMP $json;
    close $TEMP;

    my @x = `cat '$tempfile'|$command`;
    if( $? )
    {
        return +{ stat => $JSON::false, info => \@x };
    }
    chomp @x;
    my @data;
    for ( @x )
    {
        my $name =  Encode::decode('utf8', $_ );
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
