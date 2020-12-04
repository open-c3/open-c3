package api::vv;
use Dancer ':syntax';
use Dancer qw(cookie);
use JSON;
use POSIX;
use api;
use Encode qw(encode);
use Format;

#node
#name
#value
#time_start
#time_end
get '/vv/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        node => [ 'mismatch', qr/'/ ], 0,
        name => [ 'mismatch', qr/'/ ], 0,
        time_start => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
        time_end => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @where;
    map{ push @where, "$_='$param->{$_}'" if defined $param->{$_}; }qw( node name );

    push @where, "update_time>='$param->{time_start} 00:00:00'" if defined $param->{time_start};
    push @where, "update_time<='$param->{time_end} 23:59:59'" if defined $param->{time_end};

    my @col = qw( id node name value update_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from vv
                where projectid='$projectid' %s", join( ',', @col ), @where ? ' and '.join( ' and ', @where ):'' ), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

#node
#name
#value
#time_start
#time_end
get '/vv/:projectid/table' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        node => [ 'mismatch', qr/'/ ], 0,
        name => [ 'mismatch', qr/'/ ], 0,
        time_start => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
        time_end => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @where;
    map{ push @where, "$_='$param->{$_}'" if defined $param->{$_}; }qw( node name );

    push @where, "update_time>='$param->{time_start} 00:00:00'" if defined $param->{time_start};
    push @where, "update_time<='$param->{time_end} 23:59:59'" if defined $param->{time_end};

    my @col = qw( id node name value update_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from vv
                where projectid='$projectid' %s", join( ',', @col ), @where ? ' and '.join( ' and ', @where ):'' ), \@col )};

    my ( %table, %title, @title );
    map{ $table{$_->{node}}{$_->{name}} = $_->{value}; $title{$_->{name}} = 1; }@$r;
    @title = sort keys %title;

    my @x = ( [ 'NODE', @title ] );
    for my $node ( keys %table )
    {
        push @x, [ $node, map{ $table{$node}{$_} }@title ];
    }
    
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@x };
};

get '/vv/:projectid/list' => sub {
    my $param = params();
    my $error = Format->new(
        projectid => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};
    my $appname = $param->{appname};

    my $r;
    if ($appname) {
        $appname = "APP_".$appname."_VERSION";
        $r = eval {
            $api::mysql->query(
                sprintf( "select distinct value from vv where projectid=$projectid and name='$appname' order by update_time desc") )};
    } else {
        $r = eval {
            $api::mysql->query(
                sprintf( "select distinct value from vv where projectid=$projectid order by update_time desc") )};
    }

    return  +{ stat => $JSON::false, info => "query data error : $@" } if $@;
    return  +{ stat => $JSON::false, info => "get data error from db" } unless defined $r && ref $r eq 'ARRAY';
    my @x = map{$_->[0]}@$r;
    my @result;
    foreach my $ss (@x) {
        if ($ss =~ /^Do_/) {
            next;
        }else{
            push @result, $ss;
        }
    }
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@result };
};


del '/vv/:projectid/:node' => sub {
    my $param = params();
    my $error = Format->new(
        projectid => qr/^\d+$/, 1,
        node => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;


    my $pmscheck = api::pmscheck( 'openc3_job_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    eval{
        $api::mysql->execute("delete from vv where projectid=$param->{projectid} and node='$param->{node}';");
     };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => "delete success" };
};

get '/vv/:projectid/analysis/version' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
    )->check( %$param );

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;


    my $projectid = $param->{projectid};

    my $time = POSIX::strftime( "%Y-%m-%d 00:00:00", localtime( time - 31536000 ) );
    my $r = eval{ 
        $api::mysql->query( "select `name`,`value` from vv where projectid='$projectid' and ( name='VERSION' or name like 'APP_%_VERSION' ) and update_time>'$time'" )};

    return  +{ stat => $JSON::false, info => $@ } if $@;
    my ( %version, @data ); 
    map{ push @{$version{$_->[0]}},$_->[1] }@$r;
   
    for my $name ( sort keys %version )
    {
        my ( $count, %data ) = ( 0 );
        map{ $data{$_}++;$count++;}@{$version{$name}};
        map{ $data{$_} = sprintf "%0.2f", 100 * $data{$_} / $count }keys %data if $count;
        push @data, +{ name => $name, data =>  \%data };
    }

    return +{ stat => $JSON::true, data => \@data };
};

true;
