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

    my $cpulimit = OPENC3::SysCtl->new()->getintx( 'ci.default.cpulimit', 0.01, 32,    2    );
    my $memlimit = OPENC3::SysCtl->new()->getint ( 'ci.default.memlimit', 4,    32768, 2048 );
    my $memtotal = OPENC3::SysCtl->new()->getint ( 'ci.available.mem',    2048, 32768, 8192 );

    my @col  = qw(
        project.name project.groupid project.id project.cpulimit project.memlimit
        version.name version.status version.slave
    );

    my @colx = map{ my $x = $_ ; $x =~ s/\./_/g; $x } @col;
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_version as version left join openc3_ci_project as project on project.id=version.projectid where version.status='init' or version.status='running'", join( ',', @col)), \@colx )};

    my $usedmem = 0;
    for my $x ( @$r )
    {
        $x->{project_cpulimit} ||= $cpulimit;
        $x->{project_memlimit} ||= $memlimit;
        $usedmem += $x->{project_memlimit};
    }

    return $@
        ? +{ stat => $JSON::false, info => $@ }
        : +{
            stat => $JSON::true,
            data => $r ||[],
            mem  => { total => $memtotal, used => $usedmem, free => $memtotal - $usedmem },
        };
};

true;
