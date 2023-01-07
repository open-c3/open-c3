package api::connectorx;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Code;
use Format;

my ( $nodeinfo, $usertree, $treemap, $point, %notify, %approval );
BEGIN {
    ( $nodeinfo, $usertree, $treemap, $point )
        = map{ Code->new( "connectorx.plugin/$_" ) }qw( nodeinfo usertree treemap point ); 

    %notify = map{ $_ => Code->new( "connectorx.plugin/notify.plugin/$_" ) }qw( email sms );
    %approval = map{ $_ => Code->new( "connectorx.plugin/approval.plugin/$_" ) }qw( create query );
};

#获取服务树节点资源列表
get '/connectorx/nodeinfo/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'connector_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my @node = $param->{projectid} >= 4000000000 ? () : eval{ $nodeinfo->run( db => $api::mysql, id => $param->{projectid} ) };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@node };
};

#获取用户服务树
get '/connectorx/usertree' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;

    my $tree = eval{ $usertree->run( cookie => cookie( $api::cookiekey ) ) };

    $ssouser =~ s/\./_/g;
    my $private = eval{ $api::mysql->query( "select id,user from `openc3_connector_private` where user='$ssouser'", [ qw( id name ) ] ) };
    my $privatetree = +{ id => 4000000000, name => "private", children => $private };
    push @$tree, $privatetree;

    return $@ ? +{ stat => $JSON::false, info => $@ } :  +{ stat => $JSON::true, data => $tree };
};

sub tree2map
{
    my ( $data, $prev ) = @_;

    my %map;
    for my $d ( @$data )
    {
        if( $d->{children} )
        {
            %map = ( %map, tree2map( $d->{children}, $prev ? "$prev.$d->{name}" : $d->{name} ) );
        }
        $map{$d->{id}} = $prev ? "$prev.$d->{name}" : $d->{name};
    }
    return %map;
}

get '/connectorx/usertree/treemap' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;

    my $tree = eval{ $usertree->run( cookie => request->params->{cookie} || cookie( $api::cookiekey ) ) };
    my %map = tree2map( $tree );
    return $@ ? +{ stat => $JSON::false, info => $@ } :  +{ stat => $JSON::true, data => \%map };
};


#获取全量服务树map
get '/connectorx/treemap' => sub {
    my ( $user )= eval{ $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) ) };
    return( +{ stat => $JSON::false, info => "sso code error:$@" } ) if $@;
    return( +{ stat => $JSON::false, code => 10000 } ) unless $user;

    my $tree = eval{ $treemap->run( cookie => cookie( $api::cookiekey ) ) };
    return $@ ? +{ stat => $JSON::false, info => $@ } :  +{ stat => $JSON::true, data => $tree };
};

#内部权限对接: point/treeid/cookie
get '/connectorx/point' => sub {
    my $param = params();
    my $error = Format->new(
        point => qr/^[a-z0-9_]+$/, 1,
        treeid => qr/^\d+$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;


    my $stat = eval{ $point->run( %$param, db => $api::mysql ) };
    return $@ ? +{ stat => $JSON::false, info => $@ } :  +{ stat => $JSON::true, data => $stat };
};

# 内部连接器查询用户名称
get '/connectorx/username' => sub {
    #cookie appname appkey
    my $param = params();
    my ( $user, $company ) = eval{ $api::sso->run( %$param ) };

    return( +{ stat => $JSON::false, info => "sso code error:$@" } ) if $@;
    return( +{ stat => $JSON::true, data => +{ user  => $user, company => $company } } );
};

#cookie的key名称
get '/connectorx/cookiekey' => sub {
    return +{ stat => $JSON::true, data => $api::cookiekey };
};

#获取用户信息，前端使用
get '/connectorx/sso/userinfo' => sub {
    my $co = cookie( $api::cookiekey );
    $co = request->headers->{token} if ( !$co ) && request->headers->{token};

    my ( $user, $company, $admin, $showconnector )= eval{ $api::sso->run( cookie => $co, map{ $_ => request->headers->{$_} }qw( appkey appname ) ) };
    return( +{ stat => $JSON::false, info => "sso code error:$@" } ) if $@;
    return( +{ stat => $JSON::false, code => 10000 } ) unless $user;
    my $name = $user;
    $name =~ s/@.*//;

    my $privatename = $user;
    $privatename =~ s/\./_/g;

    my $match = eval{ $api::mysql->query( "select id from openc3_connector_private where user='$privatename'" )};
    eval{ $api::mysql->execute( "insert into openc3_connector_private (`user`,`edit_user`) values('$privatename','$privatename')" ); } if $match && @$match == 0;

    return +{ name => uc( $name ), email => $user, company => $company, admin => $admin, showconnector => $showconnector };
};

#给审批插件用
get '/connectorx/approve/sso/userinfo' => sub {
    my ( $user, $company, $admin, $showconnector )= eval{ $api::approvesso->run( cookie => cookie( $api::cookiekey ) ) };
    return( +{ stat => $JSON::false, info => "sso code error:$@" } ) if $@;
    return( +{ stat => $JSON::false, code => 10000 } ) unless $user;
    my $name = $user;
    $name =~ s/@.*//;

    return +{ name => uc( $name ), email => $user, company => $company, admin => $admin, showconnector => $showconnector };
};
#  给审批插件用 内部连接器查询用户名称
get '/connectorx/approve/username' => sub {
    #cookie appname appkey
    my $param = params();
    my ( $user, $company ) = eval{ $api::approvesso->run( %$param ) };

    return( +{ stat => $JSON::false, info => "sso code error:$@" } ) if $@;
    return( +{ stat => $JSON::true, data => +{ user  => $user, company => $company } } );
};

any '/connectorx/approve/ssologout' => sub {
    my $param = params();
    my $redirect = eval{ $api::approvessologout->run( cookie => cookie( $api::cookiekey ) ) };
    set_cookie( $api::cookiekey => '', http_only => 0, expires => -1 );
    return +{ stat => $JSON::false, info => "sso code error:$@" } if $@;
    return +{ stat => $JSON::true, info => 'ok', data => '/#/login' };
};

#前端跳转登录
any '/connectorx/sso/loginredirect' => sub {
    my $param = params();
    my $ssocallback = $api::ssoconfig->{ssocallback};
    if( $ssocallback =~ /^\// && $param->{siteaddr} )
    {
        $ssocallback = "$param->{siteaddr}$ssocallback";
    }

    $ssocallback =~ s/\$\{siteaddr\}/$param->{siteaddr}/g if $param->{siteaddr};

    redirect $ssocallback . ( $param->{callback} || '' );
};

#前端跳转修改密码
any '/connectorx/sso/chpasswdredirect' => sub {
    my $param = params();
    my $ssochpasswd = $api::ssoconfig->{ssochpasswd};
    if( $ssochpasswd =~ /^\// && $param->{siteaddr} )
    {
        $ssochpasswd = "$param->{siteaddr}$ssochpasswd";
    }
    redirect $ssochpasswd;
};

any '/connectorx/ssologout' => sub {
    my $param = params();
    my $redirect = eval{ $api::ssologout->run( cookie => cookie( $api::cookiekey ) ) };
    $redirect =~ s/\$\{siteaddr\}/$param->{siteaddr}/g if $redirect && $param->{siteaddr};
    set_cookie( $api::cookiekey => '', http_only => 0, expires => -1 );
    return +{ stat => $JSON::false, info => "sso code error:$@" } if $@;
    return +{ stat => $JSON::true, info => 'ok', data => $redirect };
};
#
any '/connectorx/notify' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;

    my $param = params();
    return +{ stat => $JSON::false, info => 'no data' }
        unless $param->{data} && ref $param->{data} eq 'ARRAY';

    my ( $idx ,@error ) = 0;
    for my $d ( @{$param->{data}} )
    {
        $idx ++;
        unless( ref $d eq 'HASH' )
        {
            push @error, "fromat error [idx:$idx]";
            next;
        }
        unless( $d->{type})
        {
            push @error, "type undef [idx:$idx]";
            next;
        }
        unless( $notify{$d->{type}} )
        {
            push @error, "nofind plugin $d->{type} [idx:$idx]";
            next;
        }

        eval{ $notify{$d->{type}}->run( %$d, db => $api::mysql ) };
        push( @error, "run plugin fail: $@ [idx:$idx]" ) if $@

    }

    return @error ? +{ stat => $JSON::false, info => sprintf "Err: %s", join ';', @error  } : +{ stat => $JSON::true, info => 'ok' };
};

post '/connectorx/approval' => sub {
    my $param = params();
    my $error = Format->new(
        content => qr/.+/, 1,
        submitter => qr/^[a-zA-Z0-9\@_\.\-]+$/, 1,
        approver => qr/^[a-zA-Z0-9\@_\.\-]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $uuid = eval{ $approval{create}->run( %$param ) };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $uuid };
};

get '/connectorx/approval' => sub {
    my $param = params();
    my $error = Format->new(
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $data = eval{ $approval{query}->run( %$param ) };
    #data = +{ status => $status, reason => 'null' }
    
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $data };
};

post '/connectorx/auditlog' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;

    my $param = params();
    my $error = Format->new(
        user => qr/^[a-zA-Z0-9\@_\.\-]+$/, 1,
        title => [ 'mismatch', qr/'/ ], 1,
        content => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$param->{user}','$param->{title}','$param->{content}')" ); };

    return $@ ? +{ stat => $JSON::false, info => "run auditlog fail:$@"  } : +{ stat => $JSON::true, info => 'ok' };
};

get '/connectorx/auditlog' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $param = params();
    my $error = Format->new(
        time => qr/^[0-9: \-]+$/, 0,
        user => qr/^[a-zA-Z0-9\@_\.\-]+$/, 0,
        title => [ 'mismatch', qr/'/ ], 0,
        content => [ 'mismatch', qr/'/ ], 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my @where;
    push @where, "user='$param->{user}'" if $param->{user};
    push @where, "time like '$param->{time}%'" if $param->{time};
    push @where, "title like '%$param->{title}%'" if $param->{title};
    push @where, "content like '%$param->{content}%'" if $param->{content};

    my $where = @where ? sprintf( "where %s", join ' and ', @where ) : '';

    my $mesg = eval{ $api::mysql->query( "select time,user,title,content from `openc3_connector_auditlog` $where order by time desc limit 1000", [ 'time', 'user', 'title', 'content' ] ) };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $mesg };
};

any '/connectorx/setcookie' => sub {
    my $param = params();
    my ( $cookie, $redirect ) = @$param{qw( cookie c3redirect )};

    if( $cookie )
    {
        set_cookie( $api::cookiekey => $cookie, http_only => 0, expires => time + 8 * 3600 );
        redirect $redirect;
    }
    else
    {
        set_cookie( $api::cookiekey => '', http_only => 0, expires => -1 );
        redirect $redirect;
    }
};

true;
