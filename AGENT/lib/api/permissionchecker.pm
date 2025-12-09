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
        auth_point   => qr/^[a-z][a-z\d\-_]+$/, 1,
        tree_id       => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( $param->{auth_point}, $param->{tree_id} );
    
    return +{ stat => $JSON::true, data => $pmscheck ? 0 : 1 };
};

true;
