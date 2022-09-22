package api::monitor::config::rule;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;

get '/monitor/config/rule/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my $where = $projectid ? " where projectid='$projectid'" : "";
    my @col = qw( id alert expr for severity summary description value model metrics method threshold edit_user edit_time bindtreesql );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_rule
                $where", join( ',', map{ "`$_`" }@col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

get '/monitor/config/rule/:projectid/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @col = qw( id alert expr for severity summary description value model metrics method threshold edit_user edit_time bindtreesql );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_rule where projectid='$projectid' and id='$param->{id}'", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r->[0] };
};

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
        model => [ 'in', 'simple', 'custom', 'bindtree' ], 1,
        metrics => [ 'mismatch', qr/'/ ], 0,
        method => [ 'mismatch', qr/'/ ], 0,
        threshold => [ 'mismatch', qr/'/ ], 0,
        bindtreesql => [ 'mismatch', qr/'/ ], 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    if( $param->{model} eq 'simple' )
    {
        return  +{ stat => $JSON::false, info => "check format fail" } unless $param->{metrics} && $param->{method};
        $param->{threshold} ||= 0;
        $param->{expr} = "$param->{metrics}\{treeid_$param->{projectid}!=\"\"\} $param->{method} $param->{threshold}";
    }
    elsif( $param->{model} eq 'bindtree' )
    {
        return  +{ stat => $JSON::false, info => "check format fail" } unless $param->{bindtreesql};

        return  +{ stat => $JSON::false, info => "Expr format fail, Does not contain a string like: by(instance)" } unless $param->{bindtreesql} =~ /by\s*\(\s*instance\s*\)/;
        $param->{expr} = "$param->{bindtreesql} and  ( sum(treeinfo{tid=\"$param->{projectid}\"}) by(instance))";
    }
    else
    {
        return  +{ stat => $JSON::false, info => "check format fail" } unless $param->{expr};
    }

    my $pmscheck = api::pmscheck( 'openc3_agent_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    map{ $param->{$_} = '' unless defined $param->{$_}; }qw( for summary description value );

    my ( $id, $projectid, $alert, $expr, $for, $severity, $summary, $description, $value, $model, $metrics, $method, $threshold, $bindtreesql ) = @$param{qw( id projectid alert expr for severity summary description value model metrics method threshold bindtreesql)};

    eval{
        my $title = $id ? "UPDATE" : "ADD";
        $api::auditlog->run( user => $user, title => "$title MONITOR CONFIG RULE", content => "TREEID:$projectid ALERT:$alert EXPR:$expr FOR:$for SEVERITY:$severity SUMMARY:$summary DESCRIPTION:$description VALUE:$value" );
        if( $param->{id} )
        {
            $api::mysql->execute( "update openc3_monitor_config_rule set `alert`='$alert',`expr`='$expr',`for`='$for',`severity`='$severity',summary='$summary',description='$description',`value`='$value',edit_user='$user',model='$model',metrics='$metrics',method='$method',threshold='$threshold',bindtreesql='$bindtreesql' where projectid='$projectid' and id='$id'" );
        }
        else
        {
            $api::mysql->execute( "insert into openc3_monitor_config_rule (`projectid`,`alert`,`expr`,`for`,`severity`,`summary`,`description`,`value`,`edit_user`,`model`,`metrics`,`method`,`threshold`,`bindtreesql`)
                values('$projectid','$alert','$expr','$for','$severity','$summary','$description','$value','$user','$model','$metrics','$method','$threshold','$bindtreesql')" );
        }
    };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

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

true;
