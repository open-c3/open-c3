package api::nodegroup;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON;
use POSIX;
use MIME::Base64;
use api;
use Format;
use Util;

#name
#plugin
#jobname
#create_user
#edit_user
#create_time_start
#create_time_end
#edit_time_start
#edit_time_end
get '/nodegroup/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 0,
        plugin => qr/[a-zA-Z0-9]+/, 0,
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
    map{ push @where, "$_='$param->{$_}'" if defined $param->{$_} }qw( plugin create_user edit_user );

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

    my $j = eval{
        $api::mysql->query(
            "select name,uuids from jobs where projectid='$param->{projectid}' and status='permanent'" ); };
    my %uuids;

    for ( @$j )
    {
        my ( $name, $uuids ) = @$_;
        map{ $uuids{$1}{$2} = $name if $_ =~ /^([a-z]+)_(.+)$/ }split /,/,$uuids;
    }

    my %x;
    for( $uuids{cmd} )
    {
        my $x = eval{ $api::mysql->query( 
                sprintf "select node_cont,uuid from plugin_cmd where uuid in ( %s ) and node_type='group'", 
                    join ',',map{"'$_'"}keys %{$uuids{cmd}} ) };
        map{ $x{$_->[0]}{$uuids{cmd}{$_->[1]}} = 1 }@$x;
    }
    for( $uuids{scp} )
    {
        my $x = eval{ 
            $api::mysql->query(
                sprintf "select src_type,src,dst_type,dst,uuid from plugin_cmd 
                    where uuid in ( %s ) and ( src_type='group' or dst_type='group' )", 
                        join ',',map{"'$_'"}keys %{$uuids{scp}} ) };
        map{
            $x{$_->[1]}{$uuids{scp}{$_->[4]}} = 1 if $_->[0] eq 'group';
            $x{$_->[3]}{$uuids{scp}{$_->[4]}} = 1 if $_->[2] eq 'group';
        }@$x;
    }

    my %jobname = map{ $_ => join ',',sort keys %{$x{$_}} }keys %x;

    my @col = qw( id name plugin create_user create_time edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from nodegroup
                where projectid='$param->{projectid}' and status='available' %s order by id desc", 
                    join( ',', @col ), @where ? ' and '.join( ' and ', @where ) : '' ), \@col )};


    return +{ stat => $JSON::false, info => $@ } if $@;

    my $data = [ map{+{ %$_, jobname => $jobname{$_->{id}}||''}}@$r];
    if( defined $param->{jobname} )
    {
        return  +{ stat => $JSON::false, info => 'jobname format error' } if $param->{name} =~ /'/;
        $data = [ grep{ $_->{jobname} =~ /$param->{jobname}/ }@$data];
    }

    return +{ stat => $JSON::true, data => $data };

};


get '/nodegroup/:projectid/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id name plugin params create_user create_time edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from nodegroup 
                where id='$param->{id}' and projectid='$param->{projectid}' and status='available'",
                    join ',', @col ), \@col )};

    my %x = %{$r->[0]};
    $x{params} = YAML::XS::Load decode_base64( $x{params} );

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \%x };
};

get '/nodegroup/:projectid/:id/nodelist' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $r = eval{ 
        $api::mysql->query(
            "select count(*) from nodegroup
                where id='$param->{id}' and projectid='$param->{projectid}' and status='available'" )};
    return  +{ stat => $JSON::false, info => $@ } if $@;

    return  +{ stat => $JSON::false, info => 'nofind the nodegroup in project' } unless $r->[0][0] && $r->[0][0] == 1;
    my @node = eval{ Code->new( 'nodegroup' )->run( db => $api::mysql, id => $param->{id}) };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@node };
};


#name
#plugin
#params
post '/nodegroup/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
        plugin => qr/[a-zA-Z0-9]+/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    $param->{params} = encode_base64( encode('UTF-8', YAML::XS::Dump $param->{params}) );

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ));
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    my $r = eval{ 
        $api::mysql->execute( 
            "insert into nodegroup (`projectid`,`name`,`plugin`,`params`,`create_user`,`create_time`,`edit_user`,`edit_time`,`status`)
                values( '$param->{projectid}', '$param->{name}','$param->{plugin}', '$param->{params}', '$user','$time', '$user', '$time','available' )")};

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

#name
#plugin
#params
post '/nodegroup/:projectid/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
        plugin => qr/[a-zA-Z0-9]+/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    $param->{params} = encode_base64( encode('UTF-8', YAML::XS::Dump $param->{params}) );

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    my $r = eval{ 
        $api::mysql->execute( 
            "update nodegroup set name='$param->{name}',plugin='$param->{plugin}',
                params='$param->{params}',edit_user='$user',edit_time='$time'
                    where id='$param->{id}' and projectid='$param->{projectid}' and status='available'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

del '/nodegroup/:projectid/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    my $t    = Util::deleteSuffix();

    my $r = eval{ 
        $api::mysql->execute(
            "update nodegroup set status='deleted',name=concat(name,'_$t'),edit_user='$user',edit_time='$time' 
                where id='$param->{id}' and projectid='$param->{projectid}' and status='available'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

true;
