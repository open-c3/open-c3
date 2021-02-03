package api::images;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON;
use POSIX;
use MIME::Base64;
use api;
use Format;

get '/images' => sub {
    my $param = params();

    my ( $user, $company ) = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my @col = qw( id name share describe edit_user create_user edit_time create_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from images where ( create_user='$user' or share='$company' )", join( ',', map{"`$_`"}@col)), \@col )};
    return +{ stat => $JSON::false, info => $@ } if $@;

    for my $d ( @$r )
    {
        $d->{self} = $d->{create_user} eq $user ? 1 : 0; 
        $d->{share} = $d->{share} ? 'true' : 'false';
    }
    return +{ stat => $JSON::true, data => $r };
};

get '/images/:imagesid' => sub {
    my $param = params();
    my $error = Format->new( 
        imagesid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $user, $company ) = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my @col = qw( id name share describe edit_user create_user edit_time create_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from images where id='$param->{imagesid}' and ( create_user='$user' or share='$company' or '$company'='\@app' )", join( ',', map{"`$_`"}@col)), \@col )};
    return +{ stat => $JSON::false, info => $@ } if $@;

    for my $d ( @$r )
    {
        $d->{share} = $d->{share} ? 'true' : 'false';
    }

    return +{ stat => $JSON::true, data => $r->[0] || +{} };
};

post '/images' => sub {
    my $param = params();
    my $error = Format->new( 
        name => [ 'mismatch', qr/'/ ], 1,
        describe => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $user, $company ) = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $share = $param->{share} && $param->{share} eq 'true' ? $company : '';
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    eval{ 
        $api::mysql->execute( "insert into images (`name`, `share`,`describe`,`edit_user`,`create_user`,`edit_time`,`create_time` ) values( '$param->{name}', '$share', '$param->{describe}', '$user', '$user', '$time', '$time' )");
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

post '/images/:imagesid' => sub {
    my $param = params();
    my $error = Format->new( 
        imagesid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
        describe => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $user, $company ) = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $share = $param->{share} && $param->{share} eq 'true' ? $company : '';
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    my $update = eval{ 
        $api::mysql->execute( "update images set name='$param->{name}',share='$share',`describe`='$param->{describe}',edit_user='$user',edit_time='$time' where id=$param->{imagesid} and create_user='$user'" );
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : $update ? +{ stat => $JSON::true } : +{ stat => $JSON::false, info => 'not update' } ;
};

del '/images/:imagesid' => sub {
    my $param = params();
    my $error = Format->new( 
        imagesid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $update = eval{ 
        $api::mysql->execute( "delete from images where id='$param->{imagesid}' and create_user='$user'" );
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : $update ? +{ stat => $JSON::true } : +{ stat => $JSON::false, info => 'not delete' };
};

true;
