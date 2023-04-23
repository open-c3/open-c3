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

=pod

BPM/获取bpm列表

=cut

get '/bpm/menu' => sub {
    my $pmscheck = api::pmscheck( 'openc3_agent_read' ); return $pmscheck if $pmscheck;

    my $conf = eval{ BPM::Flow->new()->menu() };

    return $@ ? +{ stat => $JSON::false, info => "get menu fail:$@" } : +{ stat => $JSON::true, data => $conf };
};

=pod

BPM/获取bpm流程的变量

=cut

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

=pod

BPM/获取bpm流程中的日志

=cut

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

=pod

BPM/获取bpm某个流程的变量

=cut

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

=pod

BPM/编辑流程

=cut

post '/bpm/var/:bpmuuid' => sub {
    my $param = params();
    my $error = Format->new( 
        bpmuuid => qr/^[a-zA-Z\d]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', 0 ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    return +{ stat => $JSON::false, info => "nofind user" } unless $user;

    my @x = `c3mc-bpm-optionx-opapprover`;
    chomp @x;
    return +{ stat => $JSON::false, info => "Unauthorized" } unless grep{ $user eq $_ }@x;

    eval{ BPM::Task::Config->new()->resave( $param->{bpm_variable}, $user, $param->{bpmuuid} ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

BPM/获取bpm流程保护信息

=cut

get '/bpm/protect/:bpmuuid' => sub {
    my $param = params();
    my $error = Format->new( 
        bpmuuid => qr/^[a-zA-Z\d]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', 0 ); return $pmscheck if $pmscheck;

    my @col = qw( stat info operator );
    my $r = eval{ $api::mysql->query( sprintf( "select %s from openc3_job_bpm_protect where bpmuuid='$param->{bpmuuid}'", join ",", @col ), \@col )}; 

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => @$r ? $r->[0] : +{ stat => 'safe' } };
};

=pod

BPM/BPM流程保护审批意见

=cut

post '/bpm/protect/:bpmuuid' => sub {
    my $param = params();
    my $error = Format->new( 
        bpmuuid => qr/^[a-zA-Z\d]+$/, 1,
        opinion => [ 'in', 'agree', 'refuse' ], 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    return +{ stat => $JSON::false, info => "nofind user" } unless $user;

    eval{ $api::mysql->execute( "update openc3_job_bpm_protect set stat='$param->{opinion}',operator='$user' where bpmuuid='$param->{bpmuuid}' and stat='danger'" )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
