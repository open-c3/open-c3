package api::cmd;
use Dancer ':syntax';
use FindBin qw( $RealBin );
use Util;

my ( %env, $exip, $cmdcount );

BEGIN{ 
    %env = Util::envinfo( qw( envname domainname cmdcount ) ); 
    $cmdcount = $env{cmdcount} || 1;

    $exip = `cat /etc/job.exip`;
    chomp $exip;
    die "/etc/job.exip nofind" unless $exip;
};

=pod

虚拟终端/打开虚拟终端

=cut

any '/cmd/:projectid' => sub {
    my $param = params();
    my ( $projectid, $node, $siteaddr ) = @$param{qw( projectid node siteaddr )};

    return "params undef" unless defined $projectid && defined $node;
    return "no cookie" unless my $u = cookie( $api::cookiekey );

    return "sudo name format error" if $param->{sudo} && $param->{sudo} !~ /^[a-zA-Z][0-9a-zA-Z_-]+$/;
    my $sudo = $param->{sudo} ? "&sudo=$param->{sudo}" : '';
    my $bash = $param->{bash} ? "&bash=1" : '';
    my $tail = $param->{tail} ? "&tail=1" : '';

    my $id = 1 + int rand $cmdcount;
    redirect "$siteaddr/webshell/index.html?u=$u&projectid=$projectid&node=$node$sudo$bash$tail";
    #redirect "http://cmd$id.$env{envname}.job.$env{domainname}?u=$u&projectid=$projectid&node=$node$sudo$bash$tail";
};

=pod

虚拟终端/查看操作日志

=cut

get '/cmd/:projectid/log' => sub {
    my $param = params();

    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        user => [ 'mismatch', qr/'/ ], 0,
        node => [ 'mismatch', qr/'/ ], 0,
        usr => [ 'mismatch', qr/'/ ], 0,
        cmd => [ 'mismatch', qr/'/ ], 0,
        time_start => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
        time_end => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @where;
    map{
        push @where, "$_ like '%$param->{$_}%'" if defined $param->{$_};
    }qw( user node usr cmd );

    my %type = ( start => '>=', end => '<=' );
    my %time = ( start => '00:00:00', end => '23:59:59');

    for my $type ( keys %type )
    {
        my $grep = "time_$type";
        push @where, "time $type{$type} '$param->{$grep} $time{$type}'" if defined $param->{$grep};
    }

    my @col = qw( id user node usr cmd time );

    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_cmdlog where projectid='$param->{projectid}' %s", 
                join( ',', @col ), @where? ' and '.join( ' and ', @where ):'' ), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
