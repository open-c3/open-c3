package api::monitor::config::rule;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;
use URI::Escape;

=pod

监控系统/监控策略/获取列表

=cut

get '/monitor/config/rule/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my $where = $projectid ? " where projectid='$projectid'" : "";
    my @col = qw( id alert expr for severity summary description value model metrics method threshold edit_user edit_time bindtreesql job subgroup nocall nomesg nomail );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_rule
                $where", join( ',', map{ "`$_`" }@col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

监控系统/监控策略/获取单个策略的配置

=cut

get '/monitor/config/rule/:projectid/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @col = qw( id alert expr for severity summary description value model metrics method threshold edit_user edit_time bindtreesql job subgroup nocall nomesg nomail );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_rule where projectid='$projectid' and id='$param->{id}'", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r->[0] };
};

=pod

监控系统/监控策略/创建或编辑策略

=cut

post '/monitor/config/rule/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 0,
        alert => [ 'mismatch', qr/'/ ], 1,
        expr => [ 'mismatch', qr/'/ ], 0,
        for => qr/^[a-zA-Z0-9]*$/, 0,
        severity => qr/^[a-zA-Z0-9]+$/, 1,
        summary => [ 'mismatch', qr/'/ ], 0,
        description => [ 'mismatch', qr/'/ ], 0,
        value => [ 'mismatch', qr/'/ ], 0,
        model => [ 'in', 'simple', 'custom', 'bindtree', 'bindetree' ], 1,
        metrics => [ 'mismatch', qr/'/ ], 0,
        method => [ 'mismatch', qr/'/ ], 0,
        threshold => [ 'mismatch', qr/'/ ], 0,
        bindtreesql => [ 'mismatch', qr/'/ ], 0,
        job         => [ 'mismatch', qr/'/ ], 0,
        subgroup => qr/^[a-zA-Z0-9]*$/, 0,

        nocall => qr/^\d*$/, 0,
        nomesg => qr/^\d*$/, 0,
        nomail => qr/^\d*$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    if( $param->{model} eq 'simple' )
    {
        return  +{ stat => $JSON::false, info => "check format fail" } unless $param->{metrics} && $param->{method};
        $param->{threshold} ||= 0;
        my $job = $param->{job} ? ",job=\"$param->{job}\"" : "";
        $param->{expr} = "$param->{metrics}\{treeid_$param->{projectid}!=\"\"$job\} $param->{method} $param->{threshold}";
    }
    elsif( $param->{model} eq 'bindtree' || $param->{model} eq 'bindetree' )
    {
        return  +{ stat => $JSON::false, info => "check format fail" } unless $param->{bindtreesql};

        $param->{bindtreesql} =~ /by\s*\(\s*([a-z][a-z0-9_\-\.]+[a-z0-9])\s*\)/;
        my $by = $1;
        return  +{ stat => $JSON::false, info => "Expr format fail, Does not contain a string like: by(instance)" } unless $by;

        my $tidname = $param->{model} eq 'bindtree' ? "tid" : "eid";
        $param->{expr} = "$param->{bindtreesql} and  ( sum(treeinfo{$tidname=\"$param->{projectid}\"}) by($by))";
    }
    else
    {
        return  +{ stat => $JSON::false, info => "check format fail" } unless $param->{expr};
    }

    my $pmscheck = api::pmscheck( 'openc3_agent_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $tempexpr = URI::Escape::uri_escape( $param->{expr} );
    my $x = `c3mc-prometheus-check-expr '$tempexpr' 2>&1`;
    return +{ stat => $JSON::false, info => $x } if $?;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    map{ $param->{$_} = '' unless defined $param->{$_}; }qw( for summary description value );

    my ( $id, $projectid, $alert, $expr, $for, $severity, $summary, $description, $value, $model, $metrics, $method, $threshold, $bindtreesql, $job, $subgroup, $nocall, $nomesg, $nomail )
        = @$param{qw( id projectid alert expr for severity summary description value model metrics method threshold bindtreesql job subgroup nocall nomesg nomail )};

    $nocall = $nocall && $nocall eq '1' ? 1 : 0;
    $nomesg = $nomesg && $nomesg eq '1' ? 1 : 0;
    $nomail = $nomail && $nomail eq '1' ? 1 : 0;

    eval{
        my $title = $id ? "UPDATE" : "ADD";
        $api::auditlog->run( user => $user, title => "$title MONITOR CONFIG RULE", content => "TREEID:$projectid ALERT:$alert EXPR:$expr FOR:$for SEVERITY:$severity SUMMARY:$summary DESCRIPTION:$description VALUE:$value JOB:$job" );
        if( $param->{id} )
        {
            $api::mysql->execute( "update openc3_monitor_config_rule set `alert`='$alert',`expr`='$expr',`for`='$for',`severity`='$severity',summary='$summary',description='$description',`value`='$value',edit_user='$user',model='$model',metrics='$metrics',method='$method',threshold='$threshold',bindtreesql='$bindtreesql',job='$job',subgroup='$subgroup',nocall='$nocall',nomesg='$nomesg',nomail='$nomail' where projectid='$projectid' and id='$id'" );
        }
        else
        {
            $api::mysql->execute( "insert into openc3_monitor_config_rule (`projectid`,`alert`,`expr`,`for`,`severity`,`summary`,`description`,`value`,`edit_user`,`model`,`metrics`,`method`,`threshold`,`bindtreesql`,`job`,`subgroup`,`nocall`,`nomesg`,`nomail`)
                values('$projectid','$alert','$expr','$for','$severity','$summary','$description','$value','$user','$model','$metrics','$method','$threshold','$bindtreesql','$job','$subgroup','$nocall','$nomesg','$nomail')" );
        }
    };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

监控系统/监控策略/删除策略

=cut

del '/monitor/config/rule/:projectid/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $cont = eval{ $api::mysql->query( "select `alert`,`expr`,`for`,`severity`,`summary`,`description`,`value` from openc3_monitor_config_rule where id='$param->{id}'")};
    my $c = $cont->[0];
    eval{ $api::auditlog->run( user => $user, title => 'DEL MONITOR CONFIG RULE', content => "TREEID:$param->{projectid} ALERT:$c->[0] EXPR:$c->[1] FOR:$c->[2] SEVERITY:$c->[3] SUMMARY:$c->[4] DESCRIPTION:$c->[5] VALUE:$c->[6]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute(
            "delete from openc3_monitor_config_rule where id='$param->{id}' and projectid='$param->{projectid}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

监控系统/监控策略/清空服务树节点的策略

=cut

del '/monitor/config/rule/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    eval{ $api::auditlog->run( user => $user, title => 'DEL MONITOR CONFIG RULE', content => "TREEID:$param->{projectid} clean tree monitor rule" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute(
            "delete from openc3_monitor_config_rule where projectid='$param->{projectid}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

监控系统/监控策略/根据服务树复制策略

=cut

post '/monitor/config/rule/copy/:fromid/:toid' => sub {
    my $param = params();
    my $error = Format->new( 
        fromid => qr/^\d+$/, 1,
        toid   => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read',  $param->{fromid} ); return $pmscheck if $pmscheck;
       $pmscheck = api::pmscheck( 'openc3_agent_write', $param->{toid}   ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    $api::auditlog->run( user => $user, title => "MONITOR CONFIG RULE COPY", content => "TREEID:$param->{toid} from: $param->{fromid}" );

    eval{
        die "user format error: $user" if $user =~ /'/;
        die "copy rule fail: $!" if system "c3mc-mon-rule-dump -t $param->{fromid} | c3mc-mon-rule-load -t $param->{toid} -u '$user'";
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

my $ruletpl = "/data/Software/mydan/AGENT/lib/api/monitor/config/rule.tpl";

=pod

监控系统/监控策略/获取模版列表

=cut

get '/monitor/config/ruletpl/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @x = `cd $ruletpl && ls`;
    chomp @x;

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@x };
};

=pod

监控系统/监控策略/同步模版

=cut

post '/monitor/config/ruletpl/sync/:projectid/:tplname' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        tplname   => qr/^[a-zA-Z0-9][a-zA-Z0-9_\-\@\.]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read',  $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    $api::auditlog->run( user => $user, title => "MONITOR CONFIG RULE COPY", content => "TREEID:$param->{projectid} from tpl: $param->{tplname}" );

    eval{
        die "user format error: $user" if $user =~ /'/;
        die "copy rule fail: $!" if system "cat '$ruletpl/$param->{tplname}' | c3mc-mon-rule-load -t $param->{projectid} -u '$user'";
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

监控系统/监控策略/保存模版

=cut

post '/monitor/config/ruletpl/save/:projectid/:tplname' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        tplname   => qr/^[a-zA-Z0-9][a-zA-Z0-9_\-\@\.]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read',  $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    $api::auditlog->run( user => $user, title => "MONITOR SAVE RULE TPL", content => "TREEID:$param->{projectid} save tpl: $param->{tplname}" );

    eval{
        die "user format error: $user" if $user =~ /'/;
        die "copy rule fail: $!" if system "c3mc-mon-rule-dump -t $param->{projectid} > '$ruletpl/usr.$user.$param->{tplname}'";
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
