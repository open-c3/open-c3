package api::default::tree;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;
use Util;

=pod

系统内置/获取服务树map信息

=cut

get '/default/tree/map' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_read' ); return $pmscheck if $pmscheck;

    my $param = params();

    my $map = eval{ $api::mysql->query( "select id,name,len,update_time from openc3_connector_tree")};
    return  +{ stat => $JSON::false, info => $@ } if $@;

    return +{ stat => $JSON::true, data => [ map{ +{ id => $_->[0], name => $_->[1], len => $_->[2], update_time => $_->[3] } }@$map ] };
};

sub maketree
{
    my ( $data, $id, $name ) = @_;
    my ( $name1, $name2 )= split /\./, $name, 2;

    unless( defined $name2 )
    {
        push @$data, +{ id => $id, name => $name };
        return $data;
    }
    else
    {
        for my $d ( @$data )
        {
            if( $d->{name} eq $name1 )
            {
                $d->{children} = [] unless defined $d->{children};
                $d->{children} = maketree( $d->{children}, $id, $name2 );
                return $data;
            }
        }
        return $data;   
    }
};

=pod

系统内置/获取服务树结构

=cut

get '/default/tree' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_read' ); return $pmscheck if $pmscheck;

    my $param = params();

    my $map = eval{ $api::mysql->query( "select id,name from openc3_connector_tree order by len")};
    return  +{ stat => $JSON::false, info => $@ } if $@;

    my $data = [];
    for ( @$map )
    {
        my ( $id, $name ) = @$_;
        $data = maketree( $data, $id, $name );
    }

    return +{ stat => $JSON::true, data => $data };
};


=pod

系统内置/在跟节点上创建服务树节点

=cut

post '/default/tree' => sub {
    my $param = params();
    my $error = Format->new( 
        name => qr/^[a-zA-Z][a-zA-Z0-9_\-]*$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_write' ); return $pmscheck if $pmscheck;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','ADD TREE','name:$param->{name}')" ); };

    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    eval{ $api::mysql->execute( "insert into openc3_connector_tree (`name`,`len`,`update_time`) values( '$param->{name}', 1, '$time' )")};
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ $api::mysql->query( "select id from openc3_connector_tree where name='$param->{name}'")};
    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::false, info => 'get id err' } unless $r && @$r > 0;

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r->[0][0] };
};

=pod

系统内置/在普通节点上创建服务树节点

=cut

post '/default/tree/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => qr/^[a-zA-Z][a-zA-Z0-9_\-]*$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_write' ); return $pmscheck if $pmscheck;

    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    my $p = eval{ $api::mysql->query( "select name,len from openc3_connector_tree where id=$param->{projectid}")};
    return  +{ stat => $JSON::false, info => $@ } if $@;
    return  +{ stat => $JSON::false, info => "project nofind" } if @$p <= 0;

    my ( $father, $len ) = @{$p->[0]};

    my $name = "$father.$param->{name}";
    $len ++;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','ADD TREE','projectid:$param->{projectid} name:$param->{name}')" ); };

    eval{ $api::mysql->execute( "insert into openc3_connector_tree (`name`,`len`,`update_time`) values( '$name', $len, '$time' )")};
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ $api::mysql->query( "select id from openc3_connector_tree where name='$name'")};
    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::false, info => 'get id err' } unless $r && @$r > 0;

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r->[0][0] };
};

=pod

系统内置/删除服务树节点

=cut

del '/default/tree/:treeid' => sub {
    my $param = params();
    my $error = Format->new( 
        treeid => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_delete' ); return $pmscheck if $pmscheck;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','DEL TREE','treeid:$param->{treeid}')" ); };

    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    my $n = eval{ $api::mysql->query( "select name from openc3_connector_tree where id=$param->{treeid}")};
    return  +{ stat => $JSON::false, info => $@ } if $@;
    return  +{ stat => $JSON::false, info => "nofind treeinfo" } if @$n <= 0;

    my $name = $n->[0][0];

    my $p = eval{ $api::mysql->query( "select name from openc3_connector_tree where name='$name' or name like '$name.%'")};
    return  +{ stat => $JSON::false, info => $@ } if $@;
    return  +{ stat => $JSON::false, info => "nofind treeinfo" } if @$p <= 0;
    return  +{ stat => $JSON::false, info => "It's not a leaf node", x => $p } if @$p > 1;

    eval{ $api::mysql->execute( "delete from openc3_connector_tree where id='$param->{treeid}'")};
    return +{ stat => $JSON::false, info => $@ } if $@;

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true , x=>  "delete from tree where id='$param->{treeid}'"};
};

true;
