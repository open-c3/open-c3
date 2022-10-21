package api::device::chpassword;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON   qw();
use POSIX;
use api;

any '/device/chpassword' => sub {
    my $param = params();
    my $error = Format->new(
        dbtype    => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+[a-zA-Z0-9]$/, 1,
        dbaddr    => qr/^[a-zA-Z0-9][a-zA-Z0-9\-:\.]+[a-zA-Z0-9]$/, 1,
        #passwd
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    if( grep{ $_ eq $param->{dbtype} }qw( redis )  )
    {
        $param->{passwd} = "_:$param->{passwd}";
    }
    if( grep{ $_ eq $param->{dbtype} }qw( mysql redis mongodb )  )
    {
        return  +{ stat => $JSON::false, info => "auth format error:  username:password" }  unless $param->{passwd} && $param->{passwd} =~ /^[a-zA-Z0-9_\.]+:.+/;
    }

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $dbpath = "/data/open-c3-data/device/curr/auth/$param->{dbtype}";
    return  +{ stat => $JSON::false, info => "noauth to change $param->{dbtype} passwd" } if ! -f "$dbpath.auth/$user";

    system( "mkdir -p $dbpath" ) unless -d $dbpath;

    if( $param->{passwd} )
    {
        eval{ YAML::XS::DumpFile "$dbpath/$param->{dbaddr}", $param->{passwd} };
    }
    else
    {
        unlink "$dbpath/$param->{dbaddr}";
    }

    return $@ ? +{ stat => $JSON::false, info => $@ } :  +{ stat => $JSON::true };
};

true;
