package api::monitor::caseinfo;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;

=pod

监控系统/case/获取我的事件列表

=cut

get '/monitor/caseinfo/mycase' => sub {
    my $param = params();

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my @col = qw(
        openc3_monitor_caseinfo.treeid
        openc3_monitor_caseinfo.ackuuid
        openc3_monitor_caseinfo.instance
        openc3_monitor_caseinfo.fingerprint
        openc3_monitor_caseinfo.caseuuid
        openc3_monitor_caseinfo.casestat
        openc3_monitor_caseinfo.title
        openc3_monitor_caseinfo.content
        openc3_monitor_caseinfo.edit_time

        openc3_monitor_usercase.user
    );
    my $expire = time - 86400 * 90;
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_usercase,openc3_monitor_caseinfo where openc3_monitor_usercase.caseuuid=openc3_monitor_caseinfo.caseuuid and openc3_monitor_caseinfo.casestat ='firing' and user='$user' and mtime>$expire order by openc3_monitor_caseinfo.id desc", join( ',', @col)), \@col )};

    my @res;
    for my $x ( @$r )
    {
        my %x;
        for my $k ( keys %$x )
        {
            my $alias = $k; $alias =~ s/^[^.]+\.//;
            $x{$alias} = $x->{$k};
        }
        push @res, \%x;
    }
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@res };
};

=pod

监控系统/case/获取全局事件列表

=cut

get '/monitor/caseinfo/allcase' => sub {
    my $param = params();

    my @col = qw(
        treeid
        ackuuid
        instance
        fingerprint
        caseuuid
        casestat
        title
        content
        edit_time
    );
    my $expire = time - 86400 * 90;
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_caseinfo where casestat='firing' and mtime>$expire order by id desc", join( ',', @col)), \@col )};

    for my $x ( @$r )
    {
        ( undef, $x->{startat} ) = split /\./, $x->{caseuuid}, 2;
    }
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
