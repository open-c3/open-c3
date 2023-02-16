package api::default::auth::tree;
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

=pod

系统内置/用户服务树权限/获取列表

=cut

any '/default/auth/tree/userauth' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my    @treemap = `c3mc-base-treemap`;
    chomp @treemap;
    my    %treemap;
    map{
        my @x = split /;/, $_, 2;
        $treemap{$x[0]} = $x[1] if @x == 2;
    } @treemap;

    my $user = eval{ $api::mysql->query( "select id,name,tree,level from `openc3_connector_userauthtree`", [ 'id', 'name', 'tree', 'level' ] ) };
    return $@
      ? +{ stat => $JSON::false, info => $@ }
      : +{ stat => $JSON::true,  data => [ map{ +{ %$_, treename => $treemap{ $_->{tree} } } } @$user ] };
};

=pod

系统内置/用户服务树权限/删除权限

=cut

del '/default/auth/tree/delauth' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new(
        id => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','DEL AUTH TREE','id:$param->{id}')" ); };

    eval{ $api::mysql->execute( "delete from openc3_connector_userauthtree where id='$param->{id}'" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

系统内置/用户服务树权限/添加权限

=cut

post '/default/auth/tree/addauth' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new(
        user  => qr/^[a-zA-Z0-9\@_\.\-]+$/, 1,
        tree  => qr/^\d+$/, 1,
        level => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','SET AUTH TREE','user:$param->{user} tree:$param->{tree} level:$param->{level}')" ); };

    eval{ $api::mysql->execute( "replace into openc3_connector_userauthtree (`name`,`tree`,`level`) values( '$param->{user}', '$param->{tree}','$param->{level}')" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
