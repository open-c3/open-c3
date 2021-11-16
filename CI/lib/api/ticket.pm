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
    my $param = params();
    my $error = Format->new( 
        type => [ 'in', 'SSHKey', 'UsernamePassword', 'JobBuildin', 'KubeConfig' ], 0,
        projectid => qr/^\d+$/, 0,
        ticketid => qr/^\d+$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $where = $param->{type} ? "and type='$param->{type}'" : '';
    my $or = $param->{projectid} ? "or id in ( select ticketid from openc3_ci_project where id='$param->{projectid}') or id in ( select follow_up_ticketid from openc3_ci_project where id='$param->{projectid}')" : "";
    $or .= $param->{ticketid} ? " or id='$param->{ticketid}' " : "";

    my @col = qw( id name type share ticket describe edit_user create_user edit_time create_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_ticket where ( create_user='$user' or share='$company' $or ) $where", join( ',', map{"`$_`"}@col)), \@col )};
    return +{ stat => $JSON::false, info => $@ } if $@;

    for my $d ( @$r )
    {
        my $t = $d->{ticket};
        $d->{self} = $d->{create_user} eq $user ? 1 : 0; 

        if( $d->{type} eq 'UsernamePassword' )
        {
            my ( $n ) = split /_:separator:_/, $t;
            $d->{ticket} = +{ Username => $n, Password => '********' }
        }

        if( $d->{type} eq 'JobBuildin' || $d->{type} eq 'SSHKey' || $d->{type} eq 'KubeConfig' )
        {
            $d->{ticket} = +{ $d->{type} => '********' }
        }
        $d->{share} = $d->{share} ? 'true' : 'false';
    }
    return +{ stat => $JSON::true, data => $r };
};

get '/ticket/KubeConfig' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my @col = qw( id name type share ticket describe edit_user create_user edit_time create_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_ticket where type = 'KubeConfig'", join( ',', map{"`$_`"}@col)), \@col )};
    return +{ stat => $JSON::false, info => $@ } if $@;

    for my $d ( @$r )
    {
        my $t = $d->{ticket};
        $d->{self} = $d->{create_user} eq $user ? 1 : 0; 

        if( $d->{type} eq 'UsernamePassword' )
        {
            my ( $n ) = split /_:separator:_/, $t;
            $d->{ticket} = +{ Username => $n, Password => '********' }
        }

        if( $d->{type} eq 'JobBuildin' || $d->{type} eq 'SSHKey' || $d->{type} eq 'KubeConfig' )
        {
            $d->{ticket} = +{ $d->{type} => '********' }
        }
        $d->{share} = $d->{share} ? 'true' : 'false';
        $d->{auth} = ( $d->{self} || $d->{share} eq $company ) ? 'X' : 'R';
    }
    return +{ stat => $JSON::true, data => $r };
};

get '/ticket/:ticketid' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my @col = qw( id name type share ticket describe edit_user create_user edit_time create_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_ticket where id='$param->{ticketid}' and ( create_user='$user' or share='$company' or '$company'='\@app' )", join( ',', map{"`$_`"}@col)), \@col )};
    return +{ stat => $JSON::false, info => $@ } if $@;

    for my $d ( @$r )
    {
        my $t = $d->{ticket};

        my $show = ( ( $d->{create_user} eq $user || $company eq '@app' ) && $param->{detail} ) ? 1 : 0;

        if( $d->{type} eq 'UsernamePassword' )
        {
            my ( $n, $p ) = split /_:separator:_/, $t;
            $p = '********' unless $show;
            $d->{ticket} = +{ Username => $n, Password => $p }
        }

        if( $d->{type} eq 'JobBuildin' || $d->{type} eq 'SSHKey' )
        {
            $t = '********' unless $show;
            $d->{ticket} = +{ $d->{type} => $t }
        }

        if( $d->{type} eq 'KubeConfig' )
        {
            my ( $v, $c ) = split /_:separator:_/, $t, 2;
            $c = '********' unless $show;
            $d->{ticket} = +{ $d->{type} => $c, kubectlVersion => $v }
        }

        $d->{share} = $d->{share} ? 'true' : 'false';
    }

    return +{ stat => $JSON::true, data => $r->[0] || +{} };
};


post '/ticket' => sub {
    my $param = params();
    my $error = Format->new( 
        name => [ 'mismatch', qr/'/ ], 1,
        type => [ 'in', 'SSHKey', 'UsernamePassword', 'JobBuildin', 'KubeConfig' ], 1,
        describe => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'CREATE TICKET', content => "NAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $share = $param->{share} && $param->{share} eq 'true' ? $company : '';
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
    if( $param->{type} eq 'JobBuildin' )
    {
        return  +{ stat => $JSON::false, info => "check format fail ticket" }
            unless $token = $param->{ticket}{JobBuildin};
    }
    if( $param->{type} eq 'KubeConfig' )
    {
        return  +{ stat => $JSON::false, info => "check format fail ticket" }
            unless $param->{ticket}{KubeConfig} && $param->{ticket}{kubectlVersion} && $param->{ticket}{kubectlVersion} =~ /^v\d+\.\d+\.\d+$/;
        $token = "$param->{ticket}{kubectlVersion}_:separator:_$param->{ticket}{KubeConfig}";
    }
 
    return  +{ stat => $JSON::false, info => "abnormal ticket format" } if $token =~ /\*{8}/;
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    eval{ 
        $api::mysql->execute( "insert into openc3_ci_ticket (`name`,`type`, `share`, `ticket`,`describe`,`edit_user`,`create_user`,`edit_time`,`create_time` ) values( '$param->{name}', '$param->{type}', '$share', '$token', '$param->{describe}', '$user', '$user', '$time', '$time' )");
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

post '/ticket/:ticketid' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
        type => [ 'in', 'SSHKey', 'UsernamePassword', 'JobBuildin', 'KubeConfig' ], 1,
        describe => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $user, $company ) = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'EDIT TICKET', content => "TICKETID:$param->{ticketid} NAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $share = $param->{share} && $param->{share} eq 'true' ? $company : '';

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
    if( $param->{type} eq 'JobBuildin' )
    {
        return  +{ stat => $JSON::false, info => "check format fail ticket" }
            unless $token = $param->{ticket}{JobBuildin};
    }
    if( $param->{type} eq 'KubeConfig' )
    {
        return  +{ stat => $JSON::false, info => "check format fail ticket" }
            unless $param->{ticket}{KubeConfig} && $param->{ticket}{kubectlVersion} && $param->{ticket}{kubectlVersion} =~ /^v\d+\.\d+\.\d+$/;
        $token = "$param->{ticket}{kubectlVersion}_:separator:_$param->{ticket}{KubeConfig}";
    }
 
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    return  +{ stat => $JSON::false, info => "abnormal ticket format" } if $token =~ /\*{8}/;

    my $update = eval{ 
        $api::mysql->execute( "update openc3_ci_ticket set name='$param->{name}',type='$param->{type}',share='$share',ticket='$token',`describe`='$param->{describe}',edit_user='$user',edit_time='$time' where id=$param->{ticketid} and create_user='$user'" );
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : $update ? +{ stat => $JSON::true } : +{ stat => $JSON::false, info => 'not update' } ;
};

del '/ticket/:ticketid' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $ticketname = eval{ $api::mysql->query( "select name from openc3_ci_ticket where id='$param->{ticketid}'")};
    eval{ $api::auditlog->run( user => $user, title => 'DELETE TICKET', content => "TICKETID:$param->{ticketid} NAME:$ticketname->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $update = eval{ 
        $api::mysql->execute( "delete from openc3_ci_ticket where id='$param->{ticketid}' and create_user='$user'" );
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : $update ? +{ stat => $JSON::true } : +{ stat => $JSON::false, info => 'not delete' };
};

true;
