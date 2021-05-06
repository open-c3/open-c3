package api::nodelist;
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
#inip
#exip
#create_user
#edit_user
#create_time_start
#create_time_end
get '/nodelist/:projectid' => sub {
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
    map{ push @where, "$_ like '%$param->{$_}%'" if defined $param->{$_}; }qw( name inip exip );
    map{ push @where, "$_='$param->{$_}'" if defined $param->{$_}; }qw( create_user edit_user );

    my %type = ( start => '>=', end => '<=' );
    my %time = ( start => '00:00:00', end => '23:59:59');
    for my $type ( keys %type )
    {
        for my $g ( qw( create_time ) )
        {
            my $grep = "${g}_$type";
            push @where, "$g $type{$type} '$param->{$grep} $time{$type}'" if defined $param->{$grep};
        }
    }

    my @col = qw( id name inip exip create_user create_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_nodelist
                where projectid='$param->{projectid}' and status='available' %s",
                    join( ',', @col), @where ? ' and '.join( ' and ',@where ):'' ), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r || []};
};

post '/nodelist/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => qr/^\d+\.\d+\.\d+\.\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
#TODO    my $check = eval{ Code->new( "checkcreateip" )->run( ip => $param->{name}, name => $user );};
#    if( $@ ){
#            warn "check ip error: $@\n";
#    }
#    if ( ! $check) {
#        return  +{ stat => $JSON::false, info => "have no permission to add this server" };
#    }

    eval{ $api::auditlog->run( user => $user, title => 'ADD NODELIST', content => "TREEID:$param->{projectid} NAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $inip = ( $param->{name} =~ /^(172|10)\.\d+\.\d+\.\d+$/ ) ? $param->{name} : '';
    my $exip = ( $param->{name} =~ /^\d+\.\d+\.\d+\.\d+$/ &&  $param->{name} !~ /^(172|10)\.\d+\.\d+\.\d+$/  ) ? $param->{name} : '';

    my $r = eval{ 
        $api::mysql->execute( 
            "insert into openc3_job_nodelist (`projectid`,`name`,`inip`,`exip`,`create_user`,`create_time`,`edit_user`,`edit_time`,`status`)
                values( '$param->{projectid}', '$param->{name}', '$inip','$exip','$user','$time', '$user', '$time','available' )")};

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

del '/nodelist/:projectid/:id' => sub {
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

    my $nodelistname = eval{ $api::mysql->query( "select name from openc3_job_nodelist where id='$param->{id}'")};
    eval{ $api::auditlog->run( user => $user, title => 'DEL NODELIST', content => "TREEID:$param->{projectid} NAME:$nodelistname->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute(
            "update openc3_job_nodelist set status='deleted',name=concat(name,'_$t'),edit_user='$user',edit_time='$time' 
                where id='$param->{id}' and projectid='$param->{projectid}' and status='available'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

true;
