package api::watcher;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;
use uuid;
use OPENC3::SysCtl;

get '/watcher' => sub {
    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my $cpulimit = OPENC3::SysCtl->new()->getintx( 'ci.default.cpulimit', 0.01, 32,     2    );
    my $memlimit = OPENC3::SysCtl->new()->getint ( 'ci.default.memlimit', 4,    32768,  2048 );
    my $memtotal = OPENC3::SysCtl->new()->getint ( 'ci.available.mem',    2048, 327680, 8192 );

    my @col  = qw(
        project.name project.groupid project.id project.cpulimit project.memlimit
        version.name version.status version.slave version.queueid version.uuid
    );

    my @colx = map{ my $x = $_ ; $x =~ s/\./_/g; $x } @col;
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_version as version left join openc3_ci_project as project on project.id=version.projectid 
                where version.status='init' or version.status='running' or version.status='ready' order by version.queueid", join( ',', @col)), \@colx )};

    my $memused = 0;
    my ( @ready, @running );
    for my $x ( @$r )
    {
        $x->{project_cpulimit} ||= $cpulimit;
        $x->{project_memlimit} ||= $memlimit;
        $memused += $x->{project_memlimit} if $x->{'version_status'} eq 'running';
        push @ready,   $x if ( $x->{'version_status'} eq 'ready' || $x->{'version_status'} eq 'init' );
        push @running, $x if $x->{'version_status'} eq 'running';
    }

    return $@
        ? +{ stat => $JSON::false, info => $@ }
        : +{
            stat => $JSON::true,
            data => +{ 
                ready   => \@ready,
                running => \@running,
                mem     => +{ total => $memtotal, used => $memused, free => $memtotal - $memused },
            }
        };
};

post '/watcher/jump/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ),
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'WATCHER JUMP', content => "uuid:$param->{uuid}" ); };

    my $r = eval{ $api::mysql->query( "select queueid from openc3_ci_version where status='ready'" )};
    my @queueid = sort map{ @$_ }@$r;
    return  +{ stat => $JSON::true } unless @queueid;

    my $minid = $queueid[0] - 1;
    eval{ $api::mysql->execute( "update openc3_ci_version set queueid='$minid' where uuid='$param->{uuid}'" ); }; 
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
