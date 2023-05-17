package api::navigation;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;
use Util;

=pod

  导航栏/获取导航栏列表,全局菜单

=cut

get '/navigation/menu' => sub {
    my $param = params();

    my $pmscheck = api::pmscheck( 'openc3_connector_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( name describe url );

    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_connector_navigation where `show`=1", join( ',', map{"`$_`"}@col ) ), \@col )};

    map{$_->{url} = decode_base64( $_->{url} ); $_->{icon} = 'navigation' }@$r;

    my @x = `c3mc-base-db-get --table openc3_job_bpm_menu name alias '\`describe\`' --filter '\`show\`=1'`;
    chomp @x;
    for ( @x )
    {
        utf8::decode( $_ );
        my ( $url, $name, $describe ) = split /;/, $_, 3;
        push @$r, +{ name => $name, describe => $describe, url => "/#/bpm/4000000000/0?name=$url", icon => 'bpm' };
    }

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

  导航栏/获取导航栏列表

=cut

get '/navigation/config' => sub {
    my $param = params();

    my $pmscheck = api::pmscheck( 'openc3_connector_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id name describe url show time );

    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_connector_navigation", join( ',', map{"`$_`"}@col ) ), \@col )};

    map{$_->{url} = decode_base64( $_->{url} );}@$r;
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

  导航栏/获取导航栏详情

=cut

get '/navigation/config/:navigationid' => sub {
    my $param = params();
    my $error = Format->new( 
        navigationid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_connector_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id name describe url show time );
    my $r = eval{ 
        $api::mysql->query( sprintf( "select %s from openc3_connector_navigation where id='$param->{navigationid}'", join ',', map{"`$_`"}@col ), \@col )}; 
    my %x = %{$r->[0]};
    $x{url} = decode_base64( $x{url} );

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \%x };
};

=pod

  导航栏/创建导航栏

=cut

post '/navigation/config' => sub {
    my $param = params();
    my $error = Format->new( 
        name => [ 'mismatch', qr/'/ ], 1,
        describe => [ 'mismatch', qr/'/ ], 1,
        show => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_connector_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ));
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$user','CREATE NAVIGATION','NAME:$param->{name}')" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $url = encode_base64( $param->{url});
    my $r = eval{ 
        $api::mysql->execute( 
            "insert into openc3_connector_navigation (`name`,`describe`,`url`,`show` )
                values( '$param->{name}','$param->{describe}', '$url','$param->{show}' )")};

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

=pod

  导航栏/编辑导航栏

=cut

post '/navigation/config/:navigationid' => sub {
    my $param = params();
    my $error = Format->new( 
        navigationid => qr/^\d+$/, 1,

        name => [ 'mismatch', qr/'/ ], 1,
        describe => [ 'mismatch', qr/'/ ], 1,
        show => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_connector_write', $param->{projectid} ); return $pmscheck if $pmscheck;


    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ));
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$user','EDIT NAVIGATION','NAME:$param->{name}')" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $url = encode_base64( $param->{url});
    my $r = eval{ 
        $api::mysql->execute( 
            "update openc3_connector_navigation set name='$param->{name}',`describe`='$param->{describe}', url='$url',`show`='$param->{show}' where id='$param->{navigationid}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

=pod

  导航栏/删除导航栏

=cut

del '/navigation/config/:navigationid' => sub {
    my $param = params();
    my $error = Format->new( 
        navigationid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_connector_delete', $param->{projectid} ); return $pmscheck if $pmscheck;


    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ));
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    my $navigationname = eval{ $api::mysql->query( "select name from openc3_connector_navigation where id='$param->{navigationid}'")};
    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$user','DELETE NAVIGATION','NAME:$navigationname->[0][0]')" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute(
            "delete from openc3_connector_navigation where id='$param->{navigationid}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

true;
