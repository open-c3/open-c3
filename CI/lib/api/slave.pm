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

our ( $mysql, $myname, $sso, $pms, $cookiekey, $logs, $auditlog );
BEGIN{
    use lib "$RealBin/../private/lib";

    $myname = `c3mc-base-hostname`;
    chomp $myname;

    $mysql = MYDB->new( "$RealBin/../conf/conn" );

    ( $sso, $pms ) = map{ Code->new( "auth/$_" ) }qw( sso pms );

    my %env = Util::envinfo( qw( cookiekey ) );
    $cookiekey = $env{cookiekey};

    $logs = Logs->new( 'apislave' );

    $auditlog = Code->new( 'auditlog' );
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

    my $checklog = $uuid =~ /^\d+$/ ? 1 : 0;
    unless( $ENV{MYDan_DEBUG} )
    {
        my $installuuid = $uuid;
        unless( $cookie{$cookiekey} )
        {
            $conn->send("$error: nocookie");
            return;
        }

        my $user = eval{ $sso->run( cookie =>  $cookie{$cookiekey} ) };
        $logs->say( sprintf "user:$user uri:/ws?uuid=$uuid method:ws HTTP_X_FORWARDED_FOR:'' param:''", );
   
        my ( $projectid, $sql );

        if( $checklog )
        {
            $sql = "select %s from openc3_ci_project where id='$uuid'";
        }
        else
        {
            $sql = "select %s from openc3_ci_project where id in ( select projectid from openc3_ci_version where uuid='$installuuid' )";
        }

        {
             my @col = qw( groupid );
             my $r = eval{ $mysql->query( sprintf( $sql, join ',', @col ), \@col )};

             unless( $r && @$r )
             {
                 $conn->send("$error: Non-existent uuid:$installuuid");
                 return;
             }

             my $data = $r->[0];
             unless( defined $data->{groupid} && $data->{groupid} =~ /^\d+$/ )
             {
                 $conn->send("$error: groupid format error");
                 return;
             }
             $projectid = $data->{groupid};
         }


         my $p = eval{ $pms->run( cookie => $cookie{$cookiekey},
                 treeid => $projectid, point => 'openc3_ci_read' ) };
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

    my ( $file, $h ) = sprintf "$RealBin/../logs/%s/$uuid", $checklog ? 'findtags' :'build';

    system( "touch '$file'" )unless -f $file;
    unless( open $h, "<$file" )
    {
        $conn->send("$error: open file fail: $!");
        return;
    }

    my $msg = '';
    while( <$h> ) {
        $msg .=replace($_);
        if( length $msg > 10000 )
        {
            $conn->send($msg);
            $msg = '';
        }
    }
    $conn->send($msg) if $msg;

    $conn{$conn} = EV::stat $file, 10, sub {
        unless( ( $_[0]->stat)[7] )
        {
            seek $h, 0, 0;
            $conn->send('wsresetws');
        }
        my $msg = '';
        while( <$h> ) {
            $msg .=replace($_);
            if( length $msg > 10000 )
            {
                $conn->send($msg);
                $msg = '';
            }
        }
        $conn->send($msg) if $msg;

    };
  
};

websocket_on_close sub
{
    my( $conn ) = @_;
    delete $conn{$conn};
};

=pod

流水线/CI/获取CI任务日志页

HTML页面

=cut

get '/cilog/:uuid' => sub {
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

流水线/CI/停止CI任务

=cut

put '/killbuild/:uuid' => sub {
  my $uuid = params()->{uuid};
  
  return JSON::to_json( +{ stat => $JSON::false, info => 'uuid format error' } )
      unless $uuid =~ /^[a-zA-Z0-9]+$/;

  my $user = 'ci@debug';
  unless( $ENV{MYDan_DEBUG} )
  {
      return JSON::to_json( +{ stat => $JSON::false, code => 10000 } )
          unless (  cookie( $cookiekey ) || ( request->headers->{appkey} && request->headers->{appname} ) );

      $user = eval{ $sso->run( cookie => cookie( $cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) ) };
      my $uri = request->path_info;
      $logs->say( sprintf "user:$user uri:$uri method:%s HTTP_X_FORWARDED_FOR:%s param:%s", 
            request->method, request->env->{HTTP_X_FORWARDED_FOR}, YAML::XS::Dump YAML::XS::Dump request->params() );
  }

  my @col = qw( pid projectid slave status name);
  my $r = eval{ $mysql->query( sprintf( "select %s from openc3_ci_version where uuid='$uuid'", join ',', @col ), \@col )};
  return JSON::to_json( +{ stat => $JSON::false, info => "Non-existent uuid:$uuid" } ) unless $r && @$r;

  my $data = $r->[0];

  eval{ $auditlog->run( user => $user, title => 'KILL BUILD', content => "FLOWLINEID:$data->{projectid} TAG:$data->{name}" ); };
  return +{ stat => $JSON::false, info => $@ } if $@;

  return JSON::to_json( +{ stat => $JSON::false, info => "build $uuid in slave $data->{slave}" } )
      unless $data->{slave} && $data->{slave} eq $myname;
  return JSON::to_json( +{ stat => $JSON::true, info => "build $uuid has been closed, status is $data->{status}" } )
      unless $data->{status} && ( $data->{status} eq 'running' || $data->{status} eq 'ready' );

  map{ 
      return JSON::to_json( +{ stat => $JSON::false, info => "$_ format error" } )
          unless defined $data->{$_} && $data->{$_} =~ /^\d+$/
  }qw( pid projectid );

  unless( $ENV{MYDan_DEBUG} )
  {
      my $x = eval{ $mysql->query( "select groupid from openc3_ci_project where id='$data->{projectid}'" )};
      return JSON::to_json( +{ stat => $JSON::false, info =>  'nofind groupid' } ) unless $x && @$x > 0;

      my $p = eval{ $pms->run( cookie => cookie( $cookiekey ), 
          treeid => $x->[0][0], point => 'openc3_ci_control' ) };
      return JSON::to_json( +{ stat => $JSON::false, info => "get data from pms error:$@" } ) if $@;
      return JSON::to_json( +{ stat => $JSON::false, info =>  'Unauthorized' } ) unless $p;
  }

  return JSON::to_json( +{ stat => $JSON::true, info => "ci.build $uuid has been exit,nofind pid $data->{pid}" } )
      if system "kill -0 -$data->{pid} 1>/dev/null 2>&1";
#
#  my $environ = `cat /proc/$data->{pid}/environ`;
#
#  return +{ stat => $JSON::true, info => "build $uuid has been exit,nofind effective pid" }
#      unless $environ =~ /CI_BUILD_UUID=XXX${uuid}XXX/;
#
#  kill 'KILL', $data->{pid};

  system "kill -TERM -$data->{pid} 1>/dev/null 2>&1";
  sleep 1;

  system sprintf "echo -e '%s\nkill by $user' | c3mc-base-log-addtime >> $RealBin/../logs/build/$uuid", join "\n", map{ ' ' x 80 } 1 .. 8;

  return (system "kill -0 -$data->{pid} 1>/dev/null 2>&1" )
      ? JSON::to_json( +{ stat => $JSON::true,  info => "kill build succcess" } )
      : JSON::to_json( +{ stat => $JSON::false, info => "kill build fail"     } );
};

=pod

系统内置/自监控

=cut

any '/mon' => sub {
     eval{ $mysql->query( "select count(*) from openc3_ci_keepalive" )};
     return $@ ? "ERR:$@" : "ok";
};

=pod

系统内置/模块reload

=cut

any '/reload' => sub {
    my $token = `cat /etc/openc3.reload.token 2>/dev/null`; chomp $token;
    return 'err' unless request->headers->{token} && $token && request->headers->{token} eq $token;
    exit;
};

true;
