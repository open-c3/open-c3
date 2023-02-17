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

our %conn;

our ( $mysql, $myname, $sso, $pms, $cookiekey, $logs );
BEGIN{
    use lib "$RealBin/../private/lib";

    $myname = `c3mc-base-hostname`;
    chomp $myname;

    $mysql = MYDB->new( "$RealBin/../conf/conn" );

    ( $sso, $pms ) = map{ Code->new( "auth/$_" ) }qw( sso pms );

    my %env = Util::envinfo( qw( cookiekey ) );
    $cookiekey = $env{cookiekey};

    $logs = Logs->new( 'apislave' );
};

sub replace
{
    my $s = shift;
    $s =~ s/.\[1m.\[31m/<font color="#FF0000">/g;
    $s =~ s/.\[1m.\[32m/<font color="#00FF00">/g;
    $s =~ s/\[31m.\[42m/<font color="#0000FF">/g;
    $s =~ s/\[0m.\[0m/<\/font>/g;
    return $s;
}


websocket_on_open sub {
    my( $conn, $env ) = @_;
    my ( $HTTP_COOKIE, $QUERY_STRING ) = @$env{qw( HTTP_COOKIE QUERY_STRING )};

    my %cookie = map{ split /=/, $_, 2 }split /;\s*/, $HTTP_COOKIE;
    my %query = map{ split /=/, $_, 2 } split /&/, $QUERY_STRING;

    my $uuid = $query{uuid};
    my $error = 'open log fail:';
    unless( defined $uuid && $uuid =~ /^[a-zA-Z0-9]+$/ )
    {
        $conn->send("$error uuid format error");
        return;
    }

    unless( $ENV{MYDan_DEBUG} )
    {
        unless( $cookie{$cookiekey} )
        {
            $conn->send("$error: nocookie");
            return;
        }

        my $user = eval{ $sso->run( cookie =>  $cookie{$cookiekey} ) };
        $logs->say( sprintf "user:$user uri:/ws?uuid=$uuid method:ws HTTP_X_FORWARDED_FOR:'' param:''", );
   
         my @col = qw( projectid );
         my $r = eval{ $mysql->query( sprintf( "select %s from openc3_jobx_task where uuid='$uuid'", join ',', @col ), \@col )};

         unless( $r && @$r )
         {
             $conn->send("$error: Non-existent uuid:$uuid");
             return;
         }

         my $data = $r->[0];
         unless( defined $data->{projectid} && $data->{projectid} =~ /^\d+$/ )
         {
             $conn->send("$error: projectid format error");
             return;
         }
         my $projectid = $data->{projectid};

         my $p = eval{ $pms->run( cookie => $cookie{$cookiekey},
                 treeid => $projectid, point => 'openc3_jobx_read' ) };
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
    }

    my ( $file, $h ) = "$RealBin/../logs/task/$uuid";

    system( "touch '$file'" )unless -f $file;
    unless( open $h, "<$file" )
    {
        $conn->send("$error: open file fail: $!");
        return;
    }

    while( <$h> ) { $conn->send(replace($_)); }

    $conn{$conn} = EV::stat $file, 10, sub {
        while( <$h> ) { $conn->send(replace($_)); }
    };
  
};

websocket_on_close sub
{
    my( $conn ) = @_;
    delete $conn{$conn};
};

=pod

JOBX/slave/获取任务日志

返回的是html页面

=cut

get '/log/:uuid' => sub {
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

JOBX/模块监控

=cut

any '/mon' => sub {
     eval{ $mysql->query( "select count(*) from openc3_jobx_keepalive" )};
     return $@ ? "ERR:$@" : "ok";
};

=pod

JOBX/模块reload

=cut

any '/reload' => sub {
    my $token = `cat /etc/openc3.reload.token 2>/dev/null`; chomp $token;
    return 'err' unless request->headers->{token} && $token && request->headers->{token} eq $token;
    exit;
};

true;
