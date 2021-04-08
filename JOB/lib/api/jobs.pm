package api::jobs;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON;
use POSIX;
use MIME::Base64;
use api;
use Format;

#name
#create_user
#edit_user
#create_time_start
#create_time_end
#edit_time_start
#edit_time_end
get '/jobs/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 0,
        create_user => [ 'mismatch', qr/'/ ], 0,
        edit_user => [ 'mismatch', qr/'/ ], 0,
        create_time_start => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
        create_time_end => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
        edit_time_start => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
        create_time_end => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,

    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @where;
    push @where, "name like '%$param->{name}%'" if defined $param->{name};

    map{ push @where, "$_='$param->{$_}'" if defined $param->{$_} }qw( create_user edit_user );

    my %type = ( start => '>=', end => '<=' );
    my %time = ( start => '00:00:00', end => '23:59:59');
    for my $type ( keys %type )
    {
        for my $g ( qw( create_time edit_time ) )
        {
            my $grep = "${g}_$type";
            push @where, "$g $type{$type} '$param->{$grep} $time{$type}'" if defined $param->{$grep};
        }
    }

    my @col = qw( id uuid name create_time uuids create_user edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from jobs
                where projectid='$param->{projectid}' and status='permanent' %s order by id desc", 
                join( ',', @col ), @where ? ' and '.join( ' and ', @where ) : '' ), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;

    my ( @uuid, %hasvariable ) = map{ $_->{uuid} }@$r;
    if( @uuid )
    {
        my $v = eval{
            $api::mysql->query( sprintf "select jobuuid from variable where value='' and jobuuid in ( %s )", join ',', map{"'$_'"}@uuid );
        };
        return +{ stat => $JSON::false, info => $@ } if $@;
        map{ $hasvariable{$_->[0]} = 1 }@$v;
    }

    return +{ stat => $JSON::true, data => [ map{ +{ stepcount => scalar( split /,/, delete $_->{uuids}), hasvariable => $hasvariable{$_->{uuid}} || 0, %$_  }}@$r] };
};

get '/jobs/:projectid/count' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $r = eval{ $api::mysql->query( "select count(id) from jobs where projectid='$param->{projectid}' and status='permanent'" )};
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => +{ permanent => $r->[0][0] }};
};

get '/jobs/:projectid/:jobuuid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        jobuuid => qr/^[a-zA-Z0-9]+$/, 1,
        name => [ 'mismatch', qr/'/ ], 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    if( $param->{jobuuid} eq 'byname' )
    {
        return  +{ stat => $JSON::true, data => +{} } unless $param->{name};
        my $fid = eval{ $api::mysql->query( "select uuid from jobs where projectid='$param->{projectid}' and name='$param->{name}'" ); };
        return  +{ stat => $JSON::false, info => $@ } if $@;
        return  +{ stat => $JSON::true, data => +{} } unless @$fid;
        $param->{jobuuid} = $fid->[0][0];
    }

    my @col = qw( id name uuid uuids mon_ids mon_status create_user create_time edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from jobs
                where uuid='$param->{jobuuid}' and projectid='$param->{projectid}' and status='permanent'", join ',', @col ), \@col )};
    my %x = %{$r->[0]};

    my ( %hash, @step, %data, %myuuid );

    for my $uuid( split  /,/, $x{uuids} )
    {
        next unless $uuid =~ /^([a-z]+)_([a-zA-Z0-9]+)$/;
        $hash{$1} = 1;
        push @{$myuuid{$1}}, $2;
        push @step, [ $1, $2 ];
    }

    if( $hash{cmd} )
    {
        my @colcmd = qw( uuid name user node_type node_cont scripts_type scripts_cont scripts_argv timeout pause );
        my $rcmd = eval{ 
            $api::mysql->query( 
                sprintf( "select %s from plugin_cmd
                    where jobuuid='$param->{jobuuid}' and uuid in( %s )", 
                        join( ',', @colcmd ), join( ',', map{ "'$_'" } @{$myuuid{cmd}}) ), \@colcmd )};

        for $r ( @$rcmd ) { 
            $r->{scripts_cont} = Encode::decode("utf8", decode_base64( $r->{scripts_cont} )) if $r->{scripts_type} ne 'cite';
            $r->{scripts_argv} = decode_base64( $r->{scripts_argv} );
            $data{cmd}{$r->{uuid}} = $r; }
    }

    if( $hash{scp} )
    {
        my @colscp = qw( uuid name user src src_type sp dst dst_type dp chown chmod timeout pause scp_delete);
        my $rscp = eval{ 
            $api::mysql->query( 
                sprintf( "select %s from plugin_scp
                    where jobuuid='$param->{jobuuid}' and uuid in( %s )",
                        join( ',', @colscp ), join( ',', map{ "'$_'" } @{$myuuid{scp}}) ), \@colscp )};

        for $r ( @$rscp ) { $data{scp}{$r->{uuid}} = $r; }
    }

    if( $hash{approval} )
    {
        my @colapproval = qw( uuid name cont approver deployenv action batches everyone );
        my $rapproval = eval{ 
            $api::mysql->query( 
                sprintf( "select %s from plugin_approval
                    where jobuuid='$param->{jobuuid}' and uuid in( %s )",
                        join( ',', @colapproval ), join( ',', map{ "'$_'" } @{$myuuid{approval}}) ), \@colapproval )};

        for $r ( @$rapproval ) { $data{approval}{$r->{uuid}} = $r; }
    }



    for ( @step )
    {
        my ( $type, $uuid ) = @$_;
        push @{$x{data}}, $data{$type}{$uuid};
    }

    return +{ stat => $JSON::true, data => \%x };
};

post '/jobs/:projectid/copy/byname' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        fromprojectid => qr/^\d+$/, 0,
        toprojectid => qr/^\d+$/, 0,
        fromname => [ 'mismatch', qr/'/ ], 1,
        toname => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my ( $projectid, $fromname, $toname, $fromprojectid, $toprojectid ) = @$param{qw( projectid fromname toname fromprojectid toprojectid )};
    $fromprojectid = $projectid unless defined $fromprojectid;
    $toprojectid = $projectid unless defined $toprojectid;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    eval{ $api::auditlog->run( user => $user, title => 'CREATE JOB', content => "TREEID:$param->{projectid} NAME:$param->{toname}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $x = $api::mysql->query( "select `uuid`,`uuids`,`status`,`mon_ids`,`mon_status` from jobs where projectid='$fromprojectid' and name='$fromname'" );
    return +{ stat => $JSON::true, info => 'The source does not exist' } unless $x && @$x > 0;
    my ( $fromuuid, $uuids, $status, $mon_ids, $mon_status ) = @{$x->[0]};

    my ( $touuid, @step ) = uuid->new()->create_str;

    for ( split /,/, $uuids )
    {
        my ( $type, $uuid ) = split /_/, $_;
        my $plugin_uuid = uuid->new()->create_str;
        if( $type eq 'cmd' )
        {
            my @plugin_col = qw( name user node_type node_cont scripts_type scripts_cont scripts_argv timeout pause jobuuid );
            eval{ $api::mysql->execute( sprintf "insert into plugin_cmd (`uuid`,%s ) select '$plugin_uuid',name,user,node_type,node_cont,scripts_type,scripts_cont,scripts_argv,timeout,pause,'$touuid' from plugin_cmd where uuid='$uuid' and jobuuid='$fromuuid'", join(',',map{"`$_`"}@plugin_col ));};
            return  +{ stat => $JSON::false, info => "insert into plugin_cmd fail. $@" } if $@;
            push @step, "cmd_$plugin_uuid";
        }
        elsif( $type eq 'scp' )
        {
            my @plugin_col = qw( name user src_type src dst_type dst sp dp chown chmod timeout pause jobuuid scp_delete);
            eval{ $api::mysql->execute( sprintf "insert into plugin_scp (`uuid`,%s ) select '$plugin_uuid',name,user,src_type,src,dst_type,dst,sp,dp,chown,chmod,timeout,pause,'$touuid',scp_delete from plugin_scp where uuid='$uuid' and jobuuid='$fromuuid'", join(',',map{"`$_`"}@plugin_col ));};
            return  +{ stat => $JSON::false, info => "insert into plugin_scp fail. $@" } if $@;
            push @step, "scp_$plugin_uuid";
        }
        elsif( $type eq 'approval' )
        {
            my @plugin_col = qw( name cont approver deployenv action batches everyone timeout pause jobuuid );
            eval{ $api::mysql->execute( sprintf "insert into plugin_approval (`uuid`,%s ) select '$plugin_uuid',name,cont,approver,deployenv,action,batches,everyone,timeout,pause,'$touuid' from plugin_approval where uuid='$uuid' and jobuuid='$fromuuid'", join(',',map{"`$_`"}@plugin_col ));};
            return  +{ stat => $JSON::false, info => "insert into plugin_approval fail. $@" } if $@;
            push @step, "approval_$plugin_uuid";
        }
        else
        {
            return +{ stat => $JSON::false, info => 'unkown plugin' };
        }
    }

    eval{ $api::mysql->execute( "insert into variable (`jobuuid`,`name`,`value`,`describe`,`create_user`) select '$touuid',name,value,`describe`,'$user' from variable where jobuuid='$fromuuid'" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $step = join ',', @step;
    eval{ 
        $api::mysql->execute( 
            "insert into jobs (`projectid`,`uuid`,`name`,`uuids`,`status`,`mon_ids`,`mon_status`,`create_user`,`create_time`,`edit_user`,`edit_time`) values ( $toprojectid, '$touuid', '$param->{toname}', '$step', '$status','$mon_ids','$mon_status', '$user','$time', '$user', '$time' )")};
    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true, uuid => $touuid };
};

#name
#permanent
#data
post '/jobs/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
        mon_ids => qr/^[a-zA-Z0-9_\,\.\/]+$/, 0,
        mon_status => [ 'mismatch', qr/'/ ], 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};
    return  +{ stat => $JSON::false, info => "data undef" } unless $param->{data};
    return  +{ stat => $JSON::false, info => "data not a array" } unless ref $param->{data} && @{$param->{data}};

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    eval{ $api::auditlog->run( user => $user, title => 'CREATE JOB', content => "TREEID:$param->{projectid} NAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my @variable;
    my $index = 0;
    for my $data ( @{$param->{data}} )
    {
        $index ++;
        my $info = "step $index";

        $error = Format->new( 
            name => [ 'mismatch', qr/'/ ], 1,
            timeout => qr/^\d+$/, 0,
            pause => [ 'mismatch', qr/'/ ], 0,
            plugin_type => [qw( in cmd scp approval  )], 1,

        )->check( %$data );
        return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;

        $data->{timeout} ||= 60;
        $data->{pause} ||= '';

        if( $data->{plugin_type} eq 'cmd' )
        {

            #name
            ##user
            ##node_type
            ##node_cont
            ##scripts_type
            ##scripts_cont
            ##scripts_argv
            ##timeout
            ##pause

            map{ push @variable, $data->{$_} }qw( node_cont scripts_argv );

            $error = Format->new( 
                user => qr/^[a-zA-Z0-9]+$/, 1,
                node_type => [qw( in builtin group variable )], 1,
                scripts_type => [qw( in cite shell perl python php buildin auto )], 1,
            )->check( %$data );
            return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
    
            if( $data->{node_type} eq 'builtin' )
            {
                $error = Format->new( 
                    node_cont => qr/^[a-zA-Z0-9\.,\-]+$/, 1,
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
            }
            elsif( $data->{node_type} eq 'group' )
            {
                $error = Format->new( 
                    node_cont => qr/^\d+$/, 1,
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
 
                my $x = $api::mysql->query( "select id from nodegroup where id=$data->{node_cont} and projectid=$param->{projectid}" );
                return  +{ stat => $JSON::false, info => "$info: get data error from db" } unless defined $x && ref $x eq 'ARRAY';
                return  +{ stat => $JSON::false, info => "$info: nodegroup id $data->{node_cont} nofind" } unless @$x;
            }
            else
            {
                $error = Format->new( 
                    node_cont => qr/^[a-zA-Z0-9\.,\-_\$]+$/, 1,
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
            }

            if( $data->{scripts_type} eq 'cite' )
            {
                $error = Format->new( 
                    scripts_cont => qr/^\d+$/, 1,
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
 
                my $x = $api::mysql->query( "select id from scripts where id=$data->{scripts_cont} and projectid in ( $param->{projectid}, 0 )" );
                return  +{ stat => $JSON::false, info => "$info: get data error from db" } unless defined $x && ref $x eq 'ARRAY';
                return  +{ stat => $JSON::false, info => "$info: scripts id $data->{scripts_cont} nofind" } unless @$x;
            }
            else
            {
                $data->{scripts_cont} = encode_base64( encode('UTF-8',$data->{scripts_cont}) );
            }

            $data->{scripts_argv} = encode_base64( encode('UTF-8', $data->{scripts_argv}) );

        }
        elsif( $data->{plugin_type} eq 'scp' )
        {

            #name
            ##user
            ##src_type
            ##src
            ##dst_type
            ##dst
            ##sp
            ##dp
            ##chown
            ##chmod
            ##timeout
            ##pause

            map{ push @variable, $data->{$_} }qw( src sp dst dp );

            $error = Format->new( 
                user => qr/^[a-zA-Z0-9]+$/, 1,
                src_type => [ qw( in builtin group fileserver variable ci )], 1,
                dst_type => [ qw( in builtin group variable )], 1,
                sp => [ 'mismatch', qr/'/ ], 0,
                dp => [ 'mismatch', qr/'/ ], 0,
                chown => qr/^[a-zA-Z0-9\-]+$/, 0,
                chmod => qr/^\d+$/, 0,
            )->check( %$data );
            return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;

            map{ $data->{$_} = '' unless defined $data->{$_};}qw( chown chmod );

            $data->{scp_delete} ||= 0;
            if( $data->{src_type} eq 'builtin' )
            {
                $error = Format->new( 
                    src => qr/^[a-zA-Z0-9\.,\-]+$/, 1
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
            }
            elsif( $data->{src_type} eq 'group' )
            {
                $error = Format->new( 
                    src => qr/^\d+$/, 1
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
 
                my $x = $api::mysql->query( "select id from nodegroup where id=$data->{src} and projectid=$param->{projectid}" );
                return  +{ stat => $JSON::false, info => "$info: get data error from db" } unless defined $x && ref $x eq 'ARRAY';
                return  +{ stat => $JSON::false, info => "$info: nodegroup id $data->{src} nofind" } unless @$x;
            }
            elsif( $data->{src_type} eq 'fileserver' )
            {
                $data->{src} = '';
                return  +{ stat => $JSON::false, info => "$info: sp format error" } if $data->{sp} =~ /\/|'/;
            }
            else
            {
                $error = Format->new( 
                    src => qr/^[a-zA-Z0-9\.,\-_\$]+$/, 1
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
            }

            if( $data->{dst_type} eq 'builtin' )
            {
                $error = Format->new( 
                    dst => qr/^[a-zA-Z0-9\.,\-]+$/, 1
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
 
            }
            elsif( $data->{dst_type} eq 'group' )
            {
                $error = Format->new( 
                    dst => qr/^\d+$/, 1
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
 
                my $x = $api::mysql->query( "select id from nodegroup where id=$data->{dst} and projectid=$param->{projectid}" );
                return  +{ stat => $JSON::false, info => "$info: get data error from db" } unless defined $x && ref $x eq 'ARRAY';
                return  +{ stat => $JSON::false, info => "$info: nodegroup id $data->{dst} nofind" } unless @$x;
            }
            else
            {
                $error = Format->new( 
                    dst => qr/^[a-zA-Z0-9\.,\-_\$]+$/, 1
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
            }

        }
        elsif( $data->{plugin_type} eq 'approval' )
        {
            $error = Format->new( 
                name => [ 'mismatch', qr/'/ ], 1, 
                cont => [ 'mismatch', qr/'/ ], 1, 
                approver => qr/^[a-zA-Z0-9,\@_\-\.]+$/, 1,
                deployenv => [ 'in', 'test', 'online', 'always' ], 1,
                action => [ 'in', 'deploy', 'rollback', 'always' ], 1,
                batches => [ 'in', 'firsttime', 'always' ], 1,
                everyone => [ 'in', 'on', 'off' ], 1,
            )->check( %$data );
            return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
        }
    }


    my $jobuuid = uuid->new()->create_str;
    $index = 0;
    my @step;
    for my $data ( @{$param->{data}} )
    {
        $index ++;
        my $info = "step $index";
        my $plugin_uuid = uuid->new()->create_str;
        $data->{jobuuid} = $jobuuid;

        if( $data->{plugin_type} eq 'cmd' )
        {
            my @plugin_col = qw( name user node_type node_cont scripts_type scripts_cont scripts_argv timeout pause jobuuid );
            eval{ $api::mysql->execute( sprintf "insert into plugin_cmd (`uuid`,%s ) values('$plugin_uuid',%s)",
                    join(',',map{"`$_`"}@plugin_col ), join(',',map{"'$data->{$_}'"}@plugin_col ));};
            return  +{ stat => $JSON::false, info => "$info: insert into plugin_cmd fail. $@" } if $@;
            push @step, "cmd_$plugin_uuid";
        }
        elsif( $data->{plugin_type} eq 'scp' )
        {
            my @plugin_col = qw( name user src_type src dst_type dst sp dp chown chmod timeout pause jobuuid scp_delete);
            eval{ $api::mysql->execute( sprintf "insert into plugin_scp (`uuid`,%s ) values('$plugin_uuid',%s)",
                    join(',',map{"`$_`"}@plugin_col ), join(',',map{"'$data->{$_}'"}@plugin_col ));};
            return  +{ stat => $JSON::false, info => "$info: insert into plugin_scp fail. $@" } if $@;
            push @step, "scp_$plugin_uuid";
        }
        elsif( $data->{plugin_type} eq 'approval' )
        {
            my @plugin_col = qw( name cont approver deployenv action batches everyone timeout pause jobuuid );
            eval{ $api::mysql->execute( sprintf "insert into plugin_approval (`uuid`,%s ) values('$plugin_uuid',%s)",
                    join(',',map{"`$_`"}@plugin_col ), join(',',map{"'$data->{$_}'"}@plugin_col ));};
            return  +{ stat => $JSON::false, info => "$info: insert into plugin_approval fail. $@" } if $@;
            push @step, "approval_$plugin_uuid";
        }

    }

    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    my $step = join ',', @step;

    my $status = $param->{permanent} ? 'permanent' : 'transient';
    my $r = eval{ 
        $api::mysql->execute( 
            "insert into jobs (`projectid`,`uuid`,`name`,`uuids`,`status`,`mon_ids`,`mon_status`,`create_user`,`create_time`,`edit_user`,`edit_time`) 
                values ( $projectid, '$jobuuid', '$param->{name}', '$step', '$status','$param->{mon_ids}','$param->{mon_status}', '$user','$time', '$user', '$time' )")};

    return +{ stat => $JSON::false, info => $@ }  if $@;

    my $variable = join " ", grep{ $_ }@variable;
    my %variable;
    map{ $variable{$_} = 1 } $variable =~ /\$([a-zA-Z][a-zA-Z0-9_]+)/g;
    map{ $variable{$_} = 1 } $variable =~ /\$\{([a-zA-Z][a-zA-Z0-9_]+)\}/g;

    eval{
        map{ $api::mysql->execute( "insert into variable (`jobuuid`,`name`,`value`,`describe`,`create_user`) values('$jobuuid','$_','','','$user')" ); }keys %variable;
    };
    return +{ stat => $JSON::false, info => $@ }  if $@;

    return +{ stat => $JSON::true, uuid => $jobuuid, data => \$r };
};


#name
#data
post '/jobs/:projectid/:jobuuid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        jobuuid => qr/^[a-zA-Z0-9]+$/, 1,
        mon_ids => qr/^[a-zA-Z0-9_\,\.\/]+$/, 0,
        mon_status => [ 'mismatch', qr/'/ ], 0,
        name => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my ( $projectid, $jobuuid )= @$param{qw(projectid jobuuid)};
    return  +{ stat => $JSON::false, info => "data undef" } unless $param->{data};
    return  +{ stat => $JSON::false, info => "data not a array" } unless ref $param->{data} && @{$param->{data}};

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    eval{ $api::auditlog->run( user => $user, title => 'EDIT JOB', content => "TREEID:$param->{projectid} NAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my @variable;
    my $index = 0;
    for my $data ( @{$param->{data}} )
    {
        $index ++;
        my $info = "step $index";

        $error = Format->new( 
            name => [ 'mismatch', qr/'/ ], 1,
            timeout => qr/^\d+$/, 0,
            pause => [ 'mismatch', qr/'/ ], 0,
            plugin_type => [qw( in cmd scp approval  )], 1,

        )->check( %$data );
        return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;

        $param->{timeout} ||= 60;
        $param->{pause} ||= '';

        if( $data->{plugin_type} eq 'cmd' )
        {

            #name
            ##user
            ##node_type
            ##node_cont
            ##scripts_type
            ##scripts_cont
            ##scripts_argv
            ##timeout
            ##pause

            map{ push @variable, $data->{$_} }qw( node_cont scripts_argv );

            $error = Format->new( 
                user => qr/^[a-zA-Z0-9]+$/, 1,
                node_type => [qw( in builtin group variable )], 1,
                scripts_type => [qw( in cite shell perl python php buildin auto )], 1,
            )->check( %$data );
            return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
 
            if( $data->{node_type} eq 'builtin' )
            {
                $error = Format->new( 
                    node_cont => qr/^[a-zA-Z0-9\.,\-]+$/, 1,
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
            }
            elsif( $data->{node_type} eq 'group' )
            {
                $error = Format->new( 
                    node_cont => qr/^\d+$/, 1,
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
 
                my $x = $api::mysql->query( "select id from nodegroup where id=$data->{node_cont} and projectid=$param->{projectid}" );
                return  +{ stat => $JSON::false, info => "$info: get data error from db" } unless defined $x && ref $x eq 'ARRAY';
                return  +{ stat => $JSON::false, info => "$info: nodegroup id $data->{node_cont} nofind" } unless @$x;
            }
            else
            {
                $error = Format->new( 
                    node_cont => qr/^[a-zA-Z0-9\.,\-_\$]+$/, 1,
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
            }

            if( $data->{scripts_type} eq 'cite' )
            {
                $error = Format->new( 
                    scripts_cont => qr/^\d+$/, 1,
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
 
                my $x = $api::mysql->query( "select id from scripts where id=$data->{scripts_cont} and projectid in ( $param->{projectid}, 0 )" );
                return  +{ stat => $JSON::false, info => "$info: get data error from db" } unless defined $x && ref $x eq 'ARRAY';
                return  +{ stat => $JSON::false, info => "$info: scripts id $data->{scripts_cont} nofind" } unless @$x;
            }
            else
            {
                $data->{scripts_cont} = encode_base64( encode('UTF-8',$data->{scripts_cont}) );
            }

            $data->{scripts_argv} = encode_base64( encode('UTF-8', $data->{scripts_argv}) );

        }
        elsif( $data->{plugin_type} eq 'scp' )
        {

            #name
            ##user
            ##src_type
            ##src
            ##dst_type
            ##dst
            ##sp
            ##dp
            ##chown
            ##chmod
            ##timeout
            ##pause

            map{ push @variable, $data->{$_} }qw( src sp dst dp );

            $error = Format->new( 
                user => qr/^[a-zA-Z0-9]+$/, 1,
                src_type => [ qw( in builtin group fileserver variable ci )], 1,
                dst_type => [ qw( in builtin group variable )], 1,
                sp => [ 'mismatch', qr/'/ ], 0,
                dp => [ 'mismatch', qr/'/ ], 0,
                chown => qr/^[a-zA-Z0-9\-]+$/, 0,
                chmod => qr/^\d+$/, 0,
            )->check( %$data );
            return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;

            map{ $data->{$_} = '' unless defined $data->{$_};}qw( chown chmod );

            if( $data->{src_type} eq 'builtin' )
            {
                $error = Format->new( 
                    src => qr/^[a-zA-Z0-9\.,\-]+$/, 1
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
 
            }
            elsif( $data->{src_type} eq 'group' )
            {
                $error = Format->new( 
                    src => qr/^\d+$/, 1
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
 
                my $x = $api::mysql->query( "select id from nodegroup where id=$data->{src} and projectid=$param->{projectid}" );
                return  +{ stat => $JSON::false, info => "$info: get data error from db" } unless defined $x && ref $x eq 'ARRAY';
                return  +{ stat => $JSON::false, info => "$info: nodegroup id $data->{src} nofind" } unless @$x;
            }
            elsif( $data->{src_type} eq 'fileserver' )
            {
                $data->{src} = '';
                return  +{ stat => $JSON::false, info => "$info: sp format error" } if $data->{sp} =~ /\/|'/;
            }
            else
            {
                $error = Format->new( 
                    src => qr/^[a-zA-Z0-9\.,\-_\$]+$/, 1
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
            }

            if( $data->{dst_type} eq 'builtin' )
            {
                $error = Format->new( 
                    dst => qr/^[a-zA-Z0-9\.,\-]+$/, 1
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
 
            }
            elsif( $data->{dst_type} eq 'group' )
            {
                $error = Format->new( 
                    dst => qr/^\d+$/, 1
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
 
                my $x = $api::mysql->query( "select id from nodegroup where id=$data->{dst} and projectid=$param->{projectid}" );
                return  +{ stat => $JSON::false, info => "$info: get data error from db" } unless defined $x && ref $x eq 'ARRAY';
                return  +{ stat => $JSON::false, info => "$info: nodegroup id $data->{dst} nofind" } unless @$x;
            }
            else
            {
                $error = Format->new( 
                    dst => qr/^[a-zA-Z0-9\.,\-_\$]+$/, 1
                )->check( %$data );
                return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
            }

        }
        elsif( $data->{plugin_type} eq 'approval' )
        {
            $error = Format->new( 
                name => [ 'mismatch', qr/'/ ], 1, 
                cont => [ 'mismatch', qr/'/ ], 1, 
                approver => qr/^[a-zA-Z0-9,\@_\-\.]+$/, 1,
                deployenv => [ 'in', 'test', 'online', 'always' ], 1,
                action => [ 'in', 'deploy', 'rollback', 'always' ], 1,
                batches => [ 'in', 'firsttime', 'always' ], 1,
                everyone => [ 'in', 'on', 'off' ], 1,
            )->check( %$data );
            return  +{ stat => $JSON::false, info => "$info: check format fail $error" } if $error;
        }
 

    }


    $index = 0;
    my @step;
    for my $data ( @{$param->{data}} )
    {
        $index ++;
        my $info = "step $index";
        my $plugin_uuid = uuid->new()->create_str;
        $data->{jobuuid} = $jobuuid;

        if( $data->{plugin_type} eq 'cmd' )
        {
            my @plugin_col = qw( name user node_type node_cont scripts_type scripts_cont scripts_argv timeout pause jobuuid );
            eval{ $api::mysql->execute( sprintf "replace into plugin_cmd (`uuid`,%s ) values('$plugin_uuid',%s)",
                    join(',',map{"`$_`"}@plugin_col ), join(',',map{"'$data->{$_}'"}@plugin_col ));};
            return  +{ stat => $JSON::false, info => "$info: insert into plugin_cmd fail" } if $@;
            push @step, "cmd_$plugin_uuid";
        }
        elsif( $data->{plugin_type} eq 'scp' )
        {
            my @plugin_col = qw( name user src_type src dst_type dst sp dp chown chmod timeout pause jobuuid scp_delete);
            eval{ $api::mysql->execute( sprintf "replace into plugin_scp (`uuid`,%s ) values('$plugin_uuid',%s)",
                    join(',',map{"`$_`"}@plugin_col ), join(',',map{"'$data->{$_}'"}@plugin_col ));};
            return  +{ stat => $JSON::false, info => "$info: insert into plugin_scp fail" } if $@;
            push @step, "scp_$plugin_uuid";
        }
        elsif( $data->{plugin_type} eq 'approval' )
        {
            my @plugin_col = qw( name cont approver deployenv action batches everyone timeout pause jobuuid );
            eval{ $api::mysql->execute( sprintf "insert into plugin_approval (`uuid`,%s ) values('$plugin_uuid',%s)",
                    join(',',map{"`$_`"}@plugin_col ), join(',',map{"'$data->{$_}'"}@plugin_col ));};
            return  +{ stat => $JSON::false, info => "$info: insert into plugin_approval fail. $@" } if $@;
            push @step, "approval_$plugin_uuid";
        }


    }


    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    my $step = join ',', @step;

    my $r = eval{ 
        $api::mysql->execute( 
            "update jobs set name='$param->{name}',uuids='$step', mon_ids='$param->{mon_ids}',mon_status='$param->{mon_status}',edit_user='$user',edit_time='$time' where uuid='$jobuuid'")};


    return +{ stat => $JSON::false, info => $@ }  if $@;

    my $variable = join " ", grep{ $_ }@variable;
    my %variable;
    map{ $variable{$_} = 1 } $variable =~ /\$([a-zA-Z][a-zA-Z0-9_]+)/g;
    map{ $variable{$_} = 1 } $variable =~ /\$\{([a-zA-Z][a-zA-Z0-9_]+)\}/g;

    eval{
        my $v = $api::mysql->query( "select name from variable where jobuuid='$jobuuid'" );
        my %v = map{ $_->[0] => 1  }@$v;
        map{ 
            if( $v{$_} &&  $variable{$_} )
            {
                delete $v{$_};
                delete $variable{$_};
            }
        }(keys %variable),(keys %v);
        map{ $api::mysql->execute( "insert into variable (`jobuuid`,`name`,`value`,`describe`,`create_user`) values('$jobuuid','$_','','','$user')" ); }keys %variable;
        $api::mysql->execute( sprintf "delete from variable where jobuuid='$jobuuid' and name in ( %s )", join ',',map{"'$_'"}keys %v ) if keys %v;
    };

    return +{ stat => $JSON::false, info => $@ }  if $@;

    return +{ stat => $JSON::true, data => \$r };

};

del '/jobs/:projectid/:jobuuid' => sub {
    my $param = params();

    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        jobuuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my ( $projectid, $jobuuid )= @$param{qw(projectid jobuuid)};

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    my $t    = POSIX::strftime( "%Y%m%d%H%M%S", localtime );

    my $jobsname = eval{ $api::mysql->query( "select name from jobs where uuid='$param->{jobuuid}'")};
    eval{ $api::auditlog->run( user => $user, title => 'DELETE JOB', content => "TREEID:$param->{projectid} NAME:$jobsname->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute(
            "update jobs set status='deleted',name=concat(name,'_$t'),edit_user='$user',edit_time='$time' 
                where uuid='$jobuuid' and projectid='$projectid' and status='permanent'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

del '/jobs/:projectid/:name/byname' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my ( $projectid, $name )= @$param{qw(projectid name)};

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    my $t    = POSIX::strftime( "%Y%m%d%H%M%S", localtime );

    eval{ $api::auditlog->run( user => $user, title => 'DELETE JOB', content => "TREEID:$param->{projectid} NAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{ 
        $api::mysql->execute(
            "update jobs set status='deleted',name=concat(name,'_$t'),edit_user='$user',edit_time='$time' 
                where name='$name' and projectid='$projectid' and status='permanent'");
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
