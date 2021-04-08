package api::rely;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON;
use POSIX;
use MIME::Base64;
use api;
use Format;

get '/rely/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $projectid = $param->{projectid};

    my $x = eval{ $api::mysql->query( "select groupid from project where id='$projectid'") };
    return  +{ stat => $JSON::false, info => $@ } if $@;
    return  +{ stat => $JSON::false, info => "nofind groupid" } unless $x && @$x > 0;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', $x->[0][0] ); return $pmscheck if $pmscheck;


    my @col = qw( id path addr ticketid edit_user edit_time tags );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from rely where projectid='$projectid'", join( ',', @col)), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;

    map{ $_->{password}  = decode_base64( $_->{password}  ) if defined $_->{password} }@$r;

    my $ticket = eval{ $api::mysql->query( "select id,name from ticket" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my %ticket; map{ $ticket{$_->[0]} = $_->[1] }@$ticket;
    for my $rely ( @$r )
    {
        $rely->{ticketname} = $rely->{ticketid} ? $ticket{$rely->{ticketid}} : '';
    }

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r ||[]  };
};

post '/rely/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        path => qr/^[a-zA-Z0-9]([a-zA-Z0-9_\-\/]|\.(?!\.))*$/, 0,
        addr => [ 'mismatch', qr/'/ ], 1,
        ticketid => qr/^[a-zA-Z0-9_]+$/, 0,
        tags => qr/^[a-zA-Z0-9_\-\.]+$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $projectid = $param->{projectid};

    my $x = eval{ $api::mysql->query( "select groupid from project where id='$projectid'") };
    return  +{ stat => $JSON::false, info => $@ } if $@;
    return  +{ stat => $JSON::false, info => "nofind groupid" } unless $x && @$x > 0;
    my $pmscheck = api::pmscheck( 'openc3_ci_write', $x->[0][0] ); return $pmscheck if $pmscheck;

    $param->{password}  = encode_base64( encode('UTF-8',  $param->{password}) );

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ),
        map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => 'ADD RELY', content => "FLOWLINEID:$param->{projectid} ADDR:$param->{addr}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my @col = qw( path addr ticketid tags );
    eval{ 
        $api::mysql->execute( 
            sprintf "insert into rely (`projectid`,`edit_user`,%s) values( '$projectid','$user', %s )", 
            join(',',map{"`$_`"}@col), join(',',map{"'$param->{$_}'"}@col)
        );
    };

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

del '/rely/:projectid/:relyid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        relyid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $projectid, $relyid ) = @$param{qw( projectid relyid )};

    my $x = eval{ $api::mysql->query( "select groupid from project where id='$projectid'") };
    return  +{ stat => $JSON::false, info => $@ } if $@;
    return  +{ stat => $JSON::false, info => "nofind groupid" } unless $x && @$x > 0;
    my $pmscheck = api::pmscheck( 'openc3_ci_delete', $x->[0][0] ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ),
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $addr = eval{ $api::mysql->query( "select addr from rely where id='$param->{relyid}'")};
    eval{ $api::auditlog->run( user => $user, title => 'DEL RELY', content => "FLOWLINEID:$param->{projectid} ADDR:$addr->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( "delete from rely where id='$relyid' and projectid='$projectid'" );
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

true;
