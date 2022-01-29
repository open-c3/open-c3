package api::scripts;
use Dancer ':syntax';
use Dancer qw(cookie);

use Encode qw(encode);

use JSON qw();
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
#jobname
get '/scripts/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 0,
        create_user => [ 'mismatch', qr/'/ ], 0,
        edit_user => [ 'mismatch', qr/'/ ], 0,
        create_time_start => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
        create_time_end => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
        edit_time_start => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
        edit_time_end => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,

    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @where;
    push @where, "name like '%$param->{name}%'" if defined $param->{name};

    for my $grep ( qw( create_user edit_user ) )
    {
        push @where, "$grep='$param->{$grep}'" if defined $param->{$grep};
    }


    my %type = ( start => '>=', end => '<=' );
    my %time = ( start => '00:00:00', end => '23:59:59');
    for my $type ( keys %type )
    {
        for my $g ( qw( create_time edit_time ) )
        {
            my $grep = "${g}_$type";
            next unless defined $param->{$grep};
            push @where, "$g $type{$type} '$param->{$grep} $time{$type}'";
        }
    }

    my $j = eval{ $api::mysql->query( "select name,uuids from openc3_job_jobs where projectid='$projectid' and status='permanent'" ); };
    my %uuids;
    for ( @$j )
    {
        my ( $name, $uuids ) = @$_;
        map{ $uuids{$_} = $name }grep{ $_ =~ s/^cmd_// }split /,/,$uuids;
    }

    my $x = eval{ $api::mysql->query( sprintf "select scripts_cont,uuid from openc3_job_plugin_cmd where uuid in ( %s ) and scripts_type='cite'", join ',',map{"'$_'"}keys %uuids ) };
    my %x;
    map{ $x{$_->[0]}{$uuids{$_->[1]}} = 1 }@$x;

    my %jobname = map{ $_ => join ',',sort keys %{$x{$_}} }keys %x;

    my @col = qw( id projectid name type create_user create_time edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_scripts
                where projectid in ( '$projectid', 0 ) and status='available' %s", join( ',', @col), @where ? ' and '.join( ' and ', @where ): '' ), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;

    my $data = [ map{+{ %$_, jobname => $jobname{$_->{id}}||''}}@$r];
    if( defined $param->{jobname} )
    {
        return  +{ stat => $JSON::false, info => 'jobname format error' } if $param->{name} =~ /'/;
        $data = [ grep{ $_->{jobname} =~ /$param->{jobname}/ }@$data];
    }

    return +{ stat => $JSON::true, data => $data };
};


get '/scripts/:projectid/:scriptsid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        scriptsid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id name type cont create_user create_time edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_scripts 
                where id='$param->{scriptsid}' and projectid in ( '$param->{projectid}', 0 ) and status='available'", join ',', @col ), \@col )};
    my %x = %{$r->[0]};
    $x{cont} = decode_base64( $x{cont} );

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \%x };
};

#name
#type
#cont
post '/scripts/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
        type => [ 'in', 'shell', 'perl', 'python', 'php', 'buildin', 'auto' ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    $param->{cont} = encode_base64( encode('UTF-8',$param->{cont}) );

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    eval{ $api::auditlog->run( user => $user, title => 'CREATE SCRIPTS', content => "TREEID:$param->{projectid} NAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( 
            "insert into openc3_job_scripts (`projectid`,`name`,`type`,`cont`,`create_user`,`create_time`,`edit_user`,`edit_time`,`status`)
                values( $projectid, '$param->{name}','$param->{type}', '$param->{cont}', '$user','$time', '$user', '$time','available' )")};

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};


#name
#type
#cont
post '/scripts/:projectid/:scriptsid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        scriptsid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
        type => [ 'in', 'shell', 'perl', 'python', 'php', 'buildin', 'auto' ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    $param->{cont} = encode_base64( encode('UTF-8',$param->{cont}) );

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    my $scriptsname = eval{ $api::mysql->query( "select name from openc3_job_scripts where id='$param->{scriptsid}'")};
    eval{ $api::auditlog->run( user => $user, title => 'EDIT SCRIPTS', content => "TREEID:$param->{projectid} NAME:$scriptsname->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( 
            "update openc3_job_scripts set name='$param->{name}',type='$param->{type}',cont='$param->{cont}',edit_user='$user',edit_time='$time'
                where id='$param->{scriptsid}' and projectid='$param->{projectid}' and status='available'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

del '/scripts/:projectid/:scriptsid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        scriptsid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    my $t    = POSIX::strftime( "%Y%m%d%H%M%S", localtime );

    my $scriptsname = eval{ $api::mysql->query( "select name from openc3_job_scripts where id='$param->{scriptsid}'")};
    eval{ $api::auditlog->run( user => $user, title => 'DELETE SCRIPTS', content => "TREEID:$param->{projectid} NAME:$scriptsname->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute(
            "update openc3_job_scripts set status='deleted',name=concat(name,'_$t'),edit_user='$user',edit_time='$time' 
                where id='$param->{scriptsid}' and projectid='$param->{projectid}' and status='available'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

true;
