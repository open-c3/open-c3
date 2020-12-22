package api::ticket;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON;
use POSIX;
use MIME::Base64;
use api;
use Format;

get '/ticket' => sub {
    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my @col = qw( id name type ticket describe edit_user create_user edit_time create_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from ticket", join( ',', map{"`$_`"}@col)), \@col )};
    return +{ stat => $JSON::false, info => $@ } if $@;

    for my $d ( @$r )
    {
        my $t = $d->{ticket};
        if( $d->{type} eq 'SSHKey' )
        {
            $t = substr( $t, 0, 100). "\n********\n" .substr($t, -100, 100);
            $d->{ticket} = +{ SSHKey => $t }
        }

        if( $d->{type} eq 'UsernamePassword' )
        {
            my ( $n, $p ) = split /_:separator:_/, $t;
            $p = '********';
            $d->{ticket} = +{ Username => $n, Password => $p }
        }

    }
    return +{ stat => $JSON::true, data => $r };
};

get '/ticket/:ticketid' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my @col = qw( id name type ticket describe edit_user create_user edit_time create_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from ticket where id='$param->{ticketid}'", join( ',', map{"`$_`"}@col)), \@col )};
    return +{ stat => $JSON::false, info => $@ } if $@;

    for my $d ( @$r )
    {
        my $t = $d->{ticket};
        if( $d->{type} eq 'SSHKey' )
        {
            $t = substr( $t, 0, 100). "\n********\n" .substr($t, -100, 100);
            $d->{ticket} = +{ SSHKey => $t }
        }

        if( $d->{type} eq 'UsernamePassword' )
        {
            my ( $n, $p ) = split /_:separator:_/, $t;
            $p = '********';
            $d->{ticket} = +{ Username => $n, Password => $p }
        }

    }


    return +{ stat => $JSON::true, data => $r->[0] || +{} };
};


post '/ticket' => sub {
    my $param = params();
    my $error = Format->new( 
        name => [ 'mismatch', qr/'/ ], 1,
        type => [ 'in', 'SSHKey', 'UsernamePassword' ], 1,
        describe => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    return  +{ stat => $JSON::false, info => "check format fail ticket" } unless $param->{ticket} && ref $param->{ticket} eq 'HASH';

    my $token = '';
    if( $param->{type} eq 'SSHKey' )
    {
        return  +{ stat => $JSON::false, info => "check format fail ticket" }
            unless $token = $param->{ticket}{SSHKey};
    }
    if( $param->{type} eq 'UsernamePassword' )
    {
        return  +{ stat => $JSON::false, info => "check format fail ticket" }
            unless $param->{ticket}{Username} && $param->{ticket}{Password};
        $token = "$param->{ticket}{Username}_:separator:_$param->{ticket}{Password}";
    }
    
    return  +{ stat => $JSON::false, info => "abnormal ticket format" } if $token =~ /\*{8}/;
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    eval{ 
        $api::mysql->execute( "insert into ticket (`name`,`type`, `ticket`,`describe`,`edit_user`,`create_user`,`edit_time`,`create_time` ) values( '$param->{name}', '$param->{type}', '$token', '$param->{describe}', '$user', '$user', '$time', '$time' )");
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

post '/ticket/:ticketid' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
        type => [ 'in', 'SSHKey', 'UsernamePassword' ], 1,
        describe => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    return  +{ stat => $JSON::false, info => "check format fail ticket" } unless $param->{ticket} && ref $param->{ticket} eq 'HASH';

    my $token = '';
    if( $param->{type} eq 'SSHKey' )
    {
        return  +{ stat => $JSON::false, info => "check format fail ticket" }
            unless $token = $param->{ticket}{SSHKey};
    }
    if( $param->{type} eq 'UsernamePassword' )
    {
        return  +{ stat => $JSON::false, info => "check format fail ticket" }
            unless $param->{ticket}{Username} && $param->{ticket}{Password};
        $token = "$param->{ticket}{Username}_:separator:_$param->{ticket}{Password}";
    }
    
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    return  +{ stat => $JSON::false, info => "abnormal ticket format" } if $token =~ /\*{8}/;

    eval{ 
        $api::mysql->execute( "update ticket set name='$param->{name}',type='$param->{type}',ticket='$token',`describe`='$param->{describe}',edit_user='$user',edit_time='$time' where id=$param->{ticketid} " );
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

del '/ticket/:ticketid' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    eval{ 
        $api::mysql->execute( "delete from ticket where id='$param->{ticketid}'" );
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
