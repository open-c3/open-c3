package api::loginext::google;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use uuid;
use Format;
use Digest::MD5;
use point;
use api::loginext;

my ( $ssocookie );
BEGIN{
    $ssocookie = `c3mc-sys-ctl sys.sso.cookie`;
    chomp $ssocookie;
};

=pod

登录扩展/google登录

=cut

post '/loginext/google' => sub {
    my $param = params();
    my $error = Format->new(
        credential => qr/^[a-zA-Z0-9\@_\.\-_]+$/, 1,
    )->check( %$param );

    my $makeErrUrl = sub
    {
        my $err = shift @_;
        return sprintf "%s/loginext/google.html?toastrError=$err&%s", $api::loginext::data{'google'}{'domain'}, join '&', map{ "$_=$api::loginext::data{'google'}{$_}" }keys %{$api::loginext::data{'google'}};
    };

    return redirect &$makeErrUrl( "check format fail $error" ) if $error;

    return redirect &$makeErrUrl( "Google login not on,Please have the admin open it" ) unless $api::loginext::data{'google'}{'on'};

    my ( $domain, $err ) = @$param{qw( domain )};

    my $ip = '0.0.0.0';
    my $time = time;

    for( qw( HTTP_X_FORWARDED_FOR HTTP_X_REAL_IP REMOTE_ADDR ) )
    {
        my $x = request->env->{$_};
        if( $x && $x =~ /^\s*(\d+\.\d+\.\d+\.\d+)\b/ )
        {
            $ip = $1;
            last;
        }
    }

    my $tt = time - 300;
    my $pwErr = eval{ $api::mysql->query( "select count(*) from `openc3_connector_user_login_audit` where ip='$ip' and  action='pwErr' and t>'$tt'" ) };
    return redirect &$makeErrUrl( "Err: $@" ) if $@;
    return redirect &$makeErrUrl( "Your IP access is too frequent, please try again later" ) unless $pwErr && $pwErr->[0][0] < 50;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);

    my $res = $ua->get( "https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=$param->{credential}" );
    return redirect &$makeErrUrl( sprintf "call www.googleapis.com fail, code: %s", $res->code ) unless $res->is_success;

    my $dat = eval{ JSON::from_json( $res->decoded_content ) };
    return redirect &$makeErrUrl( "call www.googleapis.com no json" ) if $@;

    my $user = $dat->{email};
    return redirect &$makeErrUrl( "call www.googleapis.com nofind user" ) unless $user;

    my @chars = ( "A" .. "Z", "a" .. "z", 0 .. 9 );
    my $keys = join("", @chars[ map { rand @chars } ( 1 .. 64 ) ]);

    my $uuid = Digest::MD5->new->add(time)->hexdigest;

    eval{
        my $x  = $api::mysql->query( "select id from openc3_connector_userinfo where name='$user'" );
        $api::mysql->execute( "insert into openc3_connector_userinfo(name) value('$user')" ) unless @$x;
    };
    return redirect &$makeErrUrl( "Err: $@" ) if $@;

    eval{ $api::mysql->execute( sprintf "update openc3_connector_userinfo set expire=%d,sid='%s' where name='%s'", time + 7 * 86400, $keys, $user ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my %domain;
    if( $ssocookie && $domain && $domain =~ /[a-z]/ )
    {
        my @x = reverse split /\./, $domain;
        %domain = ( domain => ".$x[1].$x[0]") if @x >= 3;
    }

    set_cookie( $api::cookiekey => $keys, http_only => 0, expires => time + 8 * 3600, %domain );

    eval{ $api::mysql->execute( "insert into openc3_connector_user_login_audit( `user`,`uuid`,`action`,`ip`,`t` ) values('$user','$uuid','login','$ip','$time')" ); };
    return redirect &$makeErrUrl( "Err: $@" ) if $@;

    redirect $api::loginext::data{'google'}{'domain'};
};

true;
