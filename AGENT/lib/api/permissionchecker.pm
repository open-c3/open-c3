package api::permissionchecker;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;

=pod

AGENT/权限验证

给第三方接口提供权限检查

=cut

any '/PermissionChecker' => sub {
    my $param = params();

    my $error = Format->new(
        auth_point    => qr/^[a-z][a-z\d\-_]+$/, 1,
        tree_id       => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $noauth = api::pmscheck( $param->{auth_point}, $param->{tree_id} );

    my %user;

    if( $param->{get_userinfo} )
    {
        if( $noauth )
        {
            %user = ( username => 'unknow' );
        }
        else
        {
            my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
            %user = ( username => $user );
        }
    }

    return +{ stat => $JSON::true, data => $noauth ? 0 : 1, %user };
};

true;
