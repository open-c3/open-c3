package api::approval;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;
use Util;

get '/approval' => sub {
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my @col = qw( id taskuuid uuid name opinion remarks create_time finishtime submitter oauuid notifystatus );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_approval
                where user='$user' order by id desc limit 100", join( ',', @col ) ), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true, data => $r };
};

post '/approval' => sub {
    my $param = params();
    my $error = Format->new( 
        opinion => [ 'in', 'agree', 'refuse' ], 1,
        uuid => qr/^[a-zA-Z0-9]{12}$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'USR APPROVAL', content => "UUID:$param->{uuid} OPINION:$param->{opinion}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    my $r = eval{ $api::mysql->execute( "update openc3_job_approval set opinion='$param->{opinion}',finishtime='$time' where uuid='$param->{uuid}' and user='$user' and opinion='unconfirmed'")};

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

get '/approval/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]{12}$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my @col = qw( id taskuuid name cont opinion remarks create_time finishtime submitter oauuid notifystatus user );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_approval
                where taskuuid in ( select taskuuid from openc3_job_approval where user='$user' and uuid='$param->{uuid}')", join( ',', @col ) ), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true, data => $r };
};

get '/approval/control/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]{12}$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my @col = qw( id taskuuid name cont opinion remarks create_time finishtime submitter oauuid notifystatus user );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_approval
                where taskuuid in ( select taskuuid from openc3_job_approval where uuid='$param->{uuid}')", join( ',', @col ) ), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true, data => $r };
};

get '/approval/control/status/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]{12}$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my @col = qw( id taskuuid uuid name cont opinion remarks create_time finishtime submitter oauuid notifystatus user );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_approval where uuid='$param->{uuid}' ", join( ',', @col ) ), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true, data => @$r ? $r->[0] : +{} };
};


post '/approval/control' => sub {
    my $param = params();
    my $error = Format->new( 
        opinion => [ 'in', 'agree', 'refuse' ], 1,
        uuid => qr/^[a-zA-Z0-9]{12}$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::auditlog->run( user => 'openapi', title => 'KEY APPROVAL', content => "UUID:$param->{uuid} OPINION:$param->{opinion}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    my $r = eval{ $api::mysql->execute( "update openc3_job_approval set opinion='$param->{opinion}',finishtime='$time' where uuid='$param->{uuid}' and opinion='unconfirmed'")};

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};


any '/approval/fast/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]{12}$/, 1,
        opinion => [ 'in', 'agree', 'refuse' ], 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    if( $param->{opinion} )
    {
        eval{ $api::auditlog->run( user => 'openapi', title => 'KEY APPROVAL', content => "UUID:$param->{uuid} OPINION:$param->{opinion}" ); };
        return "err: $@" if $@;

        my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
        my $r = eval{ $api::mysql->execute( "update openc3_job_approval set opinion='$param->{opinion}',finishtime='$time' where uuid='$param->{uuid}' and opinion='unconfirmed'")};

        return "err: $@" if $@;
    }

    my @col = qw( id taskuuid uuid name cont opinion remarks create_time finishtime submitter oauuid notifystatus user );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_approval where uuid='$param->{uuid}' ", join( ',', @col ) ), \@col )};

    return "err: $@" if $@;
    my $data = @$r ? $r->[0] : +{};
    $data->{cont} =~ s/\n/<br>/g;

    my ( $agree, $refuse, $stat ) = map{ Encode::decode("utf8", $_ ) }qw( 同意 拒绝 状态 );

    my $statuscolor = '#24b0a0';
    $statuscolor = 'green' if $data->{opinion} && $data->{opinion} eq 'agree';
    $statuscolor = 'red' if $data->{opinion} && $data->{opinion} eq 'refuse';

    my $status = Encode::decode("utf8", 
        $data->{opinion}
        ? ( $data->{opinion} eq 'agree' ? '同意' : ( $data->{opinion} eq 'refuse' ? '拒绝' : '未审批' ))
        : '空'
    );

    my ( $agreecolor, $refusecolor, $disabled ) = ( $data->{opinion} && ( $data->{opinion} eq 'agree' || $data->{opinion} eq 'refuse') )
        ? ( '#777', '#777', 'disabled="disabled"' )
        : ( 'green', 'red', '' );

  return <<"END";
    <html>
       <head>
           <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
       </head>
       <body style="font-size: 40;">
           $data->{create_time} <br>
           $data->{name} <hr>
           $data->{cont} <hr>
           $stat: <a style="color: $statuscolor" >$status</a> <hr> 
           <form action="" method="post">
               <button name="opinion" value="agree" style="text-align:center;vertical-align:middle;width:49%;height:100px;font-size: 40;color: $agreecolor;" $disabled>$agree</button>
               <button name="opinion" value="refuse" style="text-align:center;vertical-align:middle;width:49%;height:100px;font-size: 40;color: $refusecolor;" $disabled>$refuse</button>
           </form>
      </body>
  </html>
END
};

true;
