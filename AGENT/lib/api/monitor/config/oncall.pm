package api::monitor::config::oncall;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;

my $path = "/data/open-c3-data/glusterfs/oncall";

=pod

监控系统/值班组/获取列表

=cut

get '/monitor/config/oncall' => sub {
    my $pmscheck = api::pmscheck( 'openc3_agent_read', 0 ); return $pmscheck if $pmscheck;

    my @col = qw( id name description edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_oncall", join( ',', map{ "`$_`" }@col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

监控系统/值班组/获取值班组配置

=cut

get '/monitor/config/oncall/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', 0 ); return $pmscheck if $pmscheck;

    my @col = qw( id name description edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_oncall where id='$param->{id}'", join( ',', @col)), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{
        my %user;
        my $file = "$path/conf/$r->[0]{name}";
        my @c = YAML::XS::LoadFile $file;
        $r->[0]{config} =  `cat '$file'`;
        for my $c ( @c )
        {
            next unless $c->{queue} && ref $c->{queue} eq 'ARRAY';
            map{ $user{$_} ++ }@{$c->{queue}};
        }
        $r->[0]{user} = [ sort keys %user ];
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r->[0] };
};

=pod

监控系统/值班组/获取日历

=cut

get '/monitor/config/oncall/cal/:name' => sub {
    my $param = params();
    my $error = Format->new( 
        name => qr/^[a-zA-Z][a-zA-Z0-9\.\-_]+$/, 1,
        user => qr/^[a-zA-Z][a-zA-Z0-9\.\-_\@]+$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', 0 ); return $pmscheck if $pmscheck;

    my $user = $param->{user} ? "-u '$param->{user}'" : "";
    my $out = `c3mc-oncall-cal '$param->{name}' $user`;

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $out };
};

=pod

监控系统/值班组/获取值班表

=cut

get '/monitor/config/oncall/list/:name' => sub {
    my $param = params();
    my $error = Format->new( 
        name => qr/^[a-zA-Z][a-zA-Z0-9\.\-_]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', 0 ); return $pmscheck if $pmscheck;

    my $out = `c3mc-oncall-list -d 30 '$param->{name}'`;
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $out };
};

=pod

监控系统/值班组/修改值班组配置

=cut

post '/monitor/config/oncall' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 0,
        name => qr/^[a-zA-Z][a-zA-Z0-9\.\-_]*$/, 1,
        description => [ 'mismatch', qr/'/ ], 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my ( $id, $name, $description, $config ) = @$param{qw( id name description config )};
    eval{ YAML::XS::Load $config; };
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{
        my $title = $id ? "UPDATE" : "ADD";
        $api::auditlog->run( user => $user, title => "$title MONITOR CONFIG ONCALL", content => "NAME:$name DESCRIPTION:$description" );
        if( $param->{id} )
        {
            $api::mysql->execute( "update openc3_monitor_config_oncall set `name`='$name',description='$description' where id='$id'" );
        }
        else
        {
            $api::mysql->execute( "insert into openc3_monitor_config_oncall (`name`,`description`,`edit_user`) values('$name','$description','$user')" );
        }
    };

    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{
        my $tmp = File::Temp->new( SUFFIX => ".oncall", UNLINK => 0 );
        print $tmp $config;
        close $tmp;
        system sprintf "mv '%s' '$path/conf/$name'",$tmp->filename;

        die "make $name fail" if system "c3mc-oncall-make $name";
    };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

监控系统/值班组/删除值班组配置

=cut

del '/monitor/config/oncall/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $cont = eval{ $api::mysql->query( "select `name`,`description` from openc3_monitor_config_oncall where id='$param->{id}'")};
    my $c = $cont->[0];
    eval{ $api::auditlog->run( user => $user, title => 'DEL MONITOR CONFIG ONCALL', content => "NAME:$c->[0] DESCRIPTION:$c->[1]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    map{
        my $file = "$path/$_/$c->[0]";
        if( -f $file )
        {
            unlink $file or return +{ stat => $JSON::false, info => "unlink file: $!" };
        }
    }qw( conf data );

    my $r = eval{ 
        $api::mysql->execute(
            "delete from openc3_monitor_config_oncall where id='$param->{id}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
