package api::selfhealing::task;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;

use Time::Local;

sub gettime
{
    my $t = shift;
    return $t unless $t =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)\.\d+Z$/;
    my $x = timelocal($6,$5,$4,$3,$2-1,$1);
    return POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime( $x + 8 * 3600) );
}

get '/selfhealing/task' => sub {
    my $param = params();
    my $pmscheck = api::pmscheck( 'openc3_agent_read', 0 ); return $pmscheck if $pmscheck;

    my @col = qw( id instance fingerprint startsAt alertname jobname taskuuid taskstat healingchecktime healingstat create_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_self_healing_task", join( ',', map{ "`$_`" }@col)), \@col )};

    map{ $_->{time} = gettime($_->{startsAt}) }@$r;
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
