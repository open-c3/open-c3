package api::slave;
use Dancer2;
use Dancer2::Plugin::WebSocket;
use EV;
use FindBin qw( $RealBin );
use MYDB;
use Code;
use Logs;
use Util;

set show_errors => 1;
set serializer  => 'JSON';

our %conn;

our ( $mysql, $myname, $sso, $pms, $cookiekey, $logs, $auditlog );
BEGIN{
    use lib "$RealBin/../private/lib";

    $myname = `c3mc-base-hostname`;
    chomp $myname;

    $mysql = MYDB->new( "$RealBin/../conf/conn" );
    ( $sso, $pms ) = map{ Code->new( "auth/$_" ) }qw( sso pms );

    my %env    = Util::envinfo( qw( cookiekey ) );
    $cookiekey = $env{cookiekey};
    $logs      = Logs->new( 'apislave' );
    $auditlog  = Code->new( 'auditlog' );
};

sub replace
{
    my $s = shift;
    $s =~ s/.\[1m.\[31m/<font color="#FF0000">/g;
    $s =~ s/.\[1m.\[32m/<font color="#00FF00">/g;
    $s =~ s/\[31m.\[42m/<font color="#0000FF">/g;
    $s =~ s/\[0m.\[0m/<\/font>/g;
    $s =~ s/\n/<br>/g;
    return $s;
}


websocket_on_open sub {
    my( $conn, $env ) = @_;
    my ( $HTTP_COOKIE, $QUERY_STRING ) = @$env{qw( HTTP_COOKIE QUERY_STRING )};

    my %cookie = map{ split /=/, $_, 2 } split /;\s*/, $HTTP_COOKIE;
    my %query  = map{ split /=/, $_, 2 } split /&/,    $QUERY_STRING;

    my $uuid  = $query{uuid};
    my $error = 'open log fail:';
    unless( defined $uuid && $uuid =~ /^[a-zA-Z0-9]+$/ )
    {
        $conn->send("$error uuid format error");
        return;
    }

    my $taskuuid = substr $uuid, 0, 12;
    unless( $cookie{$cookiekey} )
    {
        $conn->send("$error: nocookie");
        return;
    }

    my $user = eval{ $sso->run( cookie =>  $cookie{$cookiekey} ) };
    $logs->say( sprintf "user:$user uri:/ws?uuid=$uuid method:ws HTTP_X_FORWARDED_FOR:'' param:''", );
   
    my @col = qw( projectid );
    my $r = eval{ $mysql->query( sprintf( "select %s from openc3_job_task where uuid='$taskuuid'", join ',', @col ), \@col )};

    unless( $r && @$r )
    {
        $conn->send("$error: Non-existent uuid:$taskuuid");
        return;
    }

    my $data = $r->[0];
    unless( defined $data->{projectid} && $data->{projectid} =~ /^\d+$/ )
    {
        $conn->send("$error: projectid format error");
        return;
    }

    my $p = eval{ $pms->run( cookie => $cookie{$cookiekey},
             treeid => $data->{projectid}, point => 'openc3_job_read' ) };
    if( $@ )
    {
         $conn->send("$error: pms code error:$@");
         return;
    }
    unless( $p )
    {
         $conn->send("$error: Unauthorized");
         return;
    }

    my ( $file, $h ) = "$RealBin/../logs/task/$uuid";

    system( "touch '$file'" )unless -f $file;
    unless( open $h, "<$file" )
    {
        $conn->send("$error: open file fail: $!");
        return;
    }

    my ( $n, $buf );
    while( $n = sysread( $h, $buf, 102400 ) ) { $conn->send(replace($buf));}

    $conn{$conn} = EV::stat $file, 10, sub {
        my $x='';
        while( $n = sysread( $h, $buf, 102400 ) ) { $x .= $buf}
        $conn->send(replace($x)) if $x;
    };
  
};

websocket_on_close sub
{
    my( $conn ) = @_;
    delete $conn{$conn};
};

=pod

SLAVE/获取任务日志HTML页面

=cut

get '/tasklog/:uuid' => sub {
  my $uuid = params()->{uuid};
  my $ws_url = request->env->{HTTP_X_REAL_IP}
            ? sprintf( "ws://%s/slave/$myname/ws", request->env->{HTTP_HOST} )
            : websocket_url;

  return <<"END";
    <html>
      <head><script>
          var urlMySocket = "$ws_url?uuid=$uuid";
          var mySocket = new WebSocket(urlMySocket);
          mySocket.onmessage = function (evt) {
            setMessageInnerHTML(evt.data);
          };
          mySocket.onopen = function(evt) {
            console.log("opening");
          };
          function setMessageInnerHTML(innerHTML) {
              document.getElementById('message').innerHTML += innerHTML + '<br/>';
           }
    </script></head>
    <body style="background:#000; color:#FFF" ><div id="message"></div></body>
  </html>
END
};

=pod

SLAVE/通过任务UUID停止任务

=cut

del '/killtask/:uuid' => sub {
    my $uuid = params()->{uuid};
  
    return +{ stat => $JSON::false, info => 'uuid format error' }
        unless $uuid =~ /^[a-zA-Z0-9]+$/;

    return +{ stat => $JSON::false, code => 10000 }
        unless ( cookie( $cookiekey ) || ( request->headers->{appkey} && request->headers->{appname} ) );

    my $user = eval{
        $sso->run(
            cookie  => cookie( $cookiekey ),
            map{ $_ => request->headers->{$_} }qw( appkey appname )
         )
    };

    my @col = qw( pid projectid slave status name );
    my $r   = eval{ $mysql->query( sprintf( "select %s from openc3_job_task where uuid='$uuid'", join ',', @col ), \@col )};
    return +{ stat => $JSON::false, info => "Non-existent uuid:$uuid" } unless $r && @$r;

    my $data = $r->[0];

    return +{ stat => $JSON::false, info => "task $uuid in slave $data->{slave}" }
        unless $data->{slave} && $data->{slave} eq $myname;

    return +{ stat => $JSON::true, info => "task $uuid has been closed, status is $data->{status}" }
        if $data->{status} && ( $data->{status} eq 'success' || $data->{status} eq 'fail' );

    map{ 
        return +{ stat => $JSON::false, info => "$_ format error" }
            unless defined $data->{$_} && $data->{$_} =~ /^\d+$/
    }qw( pid projectid );

    my $authorization = eval{ $mysql->query( "select id from openc3_job_variable where jobuuid in ( select jobuuid from openc3_job_task where uuid='$uuid' ) and name='_authorization_' and value='true'" ); };
    return  +{ stat => $JSON::false, info => "get _authorization_ info fail: $@" } if $@;
    return  +{ stat => $JSON::false, info => "get _authorization_ error from db" } unless defined $authorization && ref $authorization eq 'ARRAY';

    my $point = @$authorization > 0 ? 'openc3_job_control' : 'openc3_job_write';

    my $p = eval{ $pms->run( cookie => cookie( $cookiekey ), 
        treeid => $data->{projectid},
        point  => $point,
        map{ $_ => request->headers->{$_} }qw( appkey appname ) )
    };
    return +{ stat => $JSON::false, info => "get data from pms error:$@" }     if $@;
    return +{ stat => $JSON::false, info => 'Unauthorized'               } unless $p;

    return +{ stat => $JSON::true, info => "task $uuid has been exit,nofind pid $data->{pid}" }
        unless kill( 0, $data->{pid} );

    eval{ $auditlog->run( user => $user, title => 'KILL JOB TASK', content => "TREEID:$data->{projectid} TASKUUID:$uuid NAME:$data->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $killinfo = defined $user && $user =~ /^[a-zA-Z0-9\.\-\@_]+$/ ? "killed by $user" : 'killed';
    system "echo '$killinfo' >> $RealBin/../logs/task/$uuid; killall -9 job_worker_task_$uuid 1>/dev/null 2>&1";
    eval{ $mysql->execute( "update openc3_job_task set reason='$killinfo' where uuid='$uuid' and reason is null" ); };

    return kill( 0, $data->{pid} )
        ? +{ stat => $JSON::false, info => "kill task fail" }
        : +{ stat => $JSON::true, info => "kill task succcess" };
};

=pod

SLAVE/获取自身监控状态

=cut

any '/mon' => sub {
     eval{ $mysql->query( "select count(*) from openc3_job_keepalive" )};
     return $@ ? +{ status => "ERR:$@" } : { status => "ok" };
};

=pod

SLAVE/reload服务

=cut

any '/reload' => sub {
    my $token = `cat /etc/openc3.reload.token 2>/dev/null`; chomp $token;
    return +{ 'err' => 'token null' } unless request->headers->{token} && $token && request->headers->{token} eq $token;
    exit;
};

true;
