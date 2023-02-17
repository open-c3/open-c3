package api::group;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;
use Util;
use uuid;

=pod

机器分批/获取列表

=cut

get '/group/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1,)->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id name note group_type group_uuid edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from `openc3_jobx_group` where projectid='$param->{projectid}' order by id desc", join( ',', @col ) ), \@col
        )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

机器分批/复制机器分批

=cut

post '/group/:projectid/copy/byname' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        fromprojectid => qr/^\d+$/, 0,
        toprojectid => qr/^\d+$/, 0,
        fromname => [ 'mismatch', qr/'/ ], 1,
        toname => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my ( $projectid, $fromprojectid, $toprojectid ) = @$param{qw( projectid fromprojectid toprojectid )};
    $fromprojectid = $projectid unless defined $fromprojectid;
    $toprojectid = $projectid unless defined $toprojectid;

    my @col = qw( id name note group_type group_uuid edit_time );
    my $x = eval{ 
        $api::mysql->query( sprintf( "select %s from `openc3_jobx_group` where name='$param->{fromname}' and projectid='$fromprojectid'", join ',', @col ),
             \@col )};

    return +{ stat => $JSON::true, info => 'The source does not exist' } unless $x && @$x > 0;

    my %col = 
    (
        list => 'node',
        percent => 'percent',
    );

    my $uuid = uuid->new()->create_str;
    my $group_type = $x->[0]{group_type};

    if( $col{$group_type} )
    {
        eval{ 
            $api::mysql->execute( 
                "insert into `openc3_jobx_group_type_$group_type` (`uuid`,`$col{$group_type}`) select '$uuid',$col{$group_type} from `openc3_jobx_group_type_$group_type` where uuid='$x->[0]{group_uuid}'")};
        return +{ stat => $JSON::false, info => $@ } if $@;
    }
    else
    {
        return +{ stat => $JSON::false, info => 'unkown plugin' };
    }

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    eval{ $api::auditlog->run( user => $user, title => 'CREATE BATCH', content => "TREEID:$param->{projectid} BATCHNAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( 
            "insert into `openc3_jobx_group` (`projectid`,`name`,`note`,`group_type`,`group_uuid`)
                values( '$toprojectid', '$param->{toname}','$x->[0]{note}', '$group_type', '$uuid' )")};
    
    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

=pod

机器分批/机器分批详情

=cut

get '/group/:projectid/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id projectid group_type group_uuid name note edit_time );
    my $r = eval{ 
        $api::mysql->query( 
             sprintf( "select %s from `openc3_jobx_group` where id='$param->{id}' and projectid='$param->{projectid}'", join ',', @col ),
             \@col
         )};

    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::false, info => "mismatch id" } unless $r && ref $r && @$r > 0;

    my %r = %{$r->[0]};
    my ( $group_type, $group_uuid ) = @r{qw( group_type group_uuid )};

    my %col =
    (
        list => [qw( node )],
        percent => [qw( percent )],
    );

    if( $col{$group_type} )
    {
        $r = eval{ 
            $api::mysql->query( 
                sprintf( "select %s from `openc3_jobx_group_type_$group_type` where uuid='$group_uuid'", 
                        join( ',', @{$col{$group_type}} ) ), $col{$group_type} )};
    
        return +{ stat => $JSON::false, info => $@ }  if $@;
        %r = ( %r, %{$r->[0]} );
    }
    else
    {
        return +{ stat => $JSON::false, info => "group type unkwon" };
    }
   
    return +{ stat => $JSON::true, data => \%r };
};

=pod

机器分批/获取机器分组内容

=cut

get '/group/:projectid/:id/node' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @node = eval{ Code->new( 'group' )->run( db => $api::mysql, id => $param->{id}) };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@node };
};

=pod

机器分批/获取机器分组内容/通过分组名查询

=cut

get '/group/:projectid/:name/node/byname' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select id from `openc3_jobx_group` where projectid='$param->{projectid}' and name='$param->{name}'" )
        )};

     return  +{ stat => $JSON::false, info => $@ } if $@;
     return  +{ stat => $JSON::true, data => [] } unless @$r;

    my @node = eval{ Code->new( 'group' )->run( db => $api::mysql, id => $r->[0][0]) };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@node };
};

=pod

机器分批/创建

=cut

post '/group/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
        note => [ 'mismatch', qr/'/ ], 0,
        group_type => qr/[a-zA-Z0-9]+/, 1,
        
        node => qr/[a-zA-Z0-9_\-\.:;]+/, 0,
        percent => qr/[a-zA-Z0-9%:]+/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    $param->{note} = '' unless defined $param->{note};

    my %col = 
    (
        list => [qw( node )],
        percent => [qw( percent )],
    );

    my $uuid = uuid->new()->create_str;
    if( $col{$param->{group_type}} )
    {
        map{ return +{ stat => $JSON::false, info => "$_ undef" }  unless defined $param->{$_} }@{$col{$param->{group_type}}};

        eval{
            $api::mysql->execute( sprintf "insert into openc3_jobx_group_type_$param->{group_type} (`uuid`,%s) values('$uuid',%s)", 
                join(',',map{"`$_`"}@{$col{$param->{group_type}}}),
                join(',',map{"'$param->{$_}'"}@{$col{$param->{group_type}}}),
            );
        };
        return +{ stat => $JSON::false, info => $@ } if $@;
    }
    else
    {
        return +{ stat => $JSON::false, info => "group type unkwon" };
    }

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => 'CREATE BATCH', content => "TREEID:$param->{projectid} BATCHNAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( 
            "insert into `openc3_jobx_group` (`projectid`,`name`,`note`,`group_type`,`group_uuid`)
                values( '$param->{projectid}', '$param->{name}','$param->{note}', '$param->{group_type}', '$uuid' )")};
    
    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

=pod

机器分批/编辑

=cut

post '/group/:projectid/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
        note => [ 'mismatch', qr/'/ ], 0,
        group_type => qr/[a-zA-Z0-9]+/, 1,
        node => qr/[a-zA-Z0-9_\-\.:;]+/, 0,
        percent => qr/[a-zA-Z0-9%:]+/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    $param->{note} = '' unless defined $param->{note};

    my %col = 
    (
        list => [qw( node )],
        percent => [qw( percent )],
    );

    my $uuid = uuid->new()->create_str;
    if( $col{$param->{group_type}} )
    {
        map{ return +{ stat => $JSON::false, info => "$_ undef" }  unless defined $param->{$_} }@{$col{$param->{group_type}}};

        eval{
            $api::mysql->execute( sprintf "insert into openc3_jobx_group_type_$param->{group_type} (`uuid`,%s) values('$uuid',%s)", 
                join(',',map{"`$_`"}@{$col{$param->{group_type}}}),
                join(',',map{"'$param->{$_}'"}@{$col{$param->{group_type}}}),
            );
        };
        return +{ stat => $JSON::false, info => $@ } if $@;
    }
    else
    {
        return +{ stat => $JSON::false, info => "group type unkwon" };
    }

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => 'EDIT BATCH', content => "TREEID:$param->{projectid} BATCHNAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( 
            "update `openc3_jobx_group` set name='$param->{name}',note='$param->{note}',group_type='$param->{group_type}',group_uuid='$uuid' where id='$param->{id}' and projectid='$param->{projectid}'"
                )};
    
    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

=pod

机器分批/删除

=cut

del '/group/:projectid/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $batchname = eval{ $api::mysql->query( "select name from `openc3_jobx_group` where id='$param->{id}' and projectid='$param->{projectid}'")};
    eval{ $api::auditlog->run( user => $user, title => 'DELETE BATCH', content => "TREEID:$param->{projectid} BATCHNAME:$batchname->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( "delete from `openc3_jobx_group` where id='$param->{id}' and projectid='$param->{projectid}'")
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

=pod

机器分批/删除/通过名称删除

=cut

del '/group/:projectid/:name/byname' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => 'DELETE BATCH', content => "TREEID:$param->{projectid} BATCHNAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{ 
        $api::mysql->execute( "delete from `openc3_jobx_group` where name='$param->{name}' and projectid='$param->{projectid}'")
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
