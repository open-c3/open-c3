package api::ticket;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;

=pod

凭据/获取凭据列表

=cut

get '/ticket' => sub {
    my $param = params();
    my $error = Format->new( 
        type => [ 'in', 'SSHKey', 'UsernamePassword', 'JobBuildin', 'KubeConfig', 'Harbor' ], 0,
        projectid => qr/^\d+$/, 0,
        ticketid => qr/^\d+$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $where = $param->{type} ? "and type='$param->{type}'" : '';
    my $or = $param->{projectid} ? "or id in ( select ticketid from openc3_ci_project where id='$param->{projectid}') or id in ( select follow_up_ticketid from openc3_ci_project where id='$param->{projectid}')" : "";
    $or .= $param->{ticketid} ? " or id='$param->{ticketid}' " : "";

    my @col = qw( id name type subtype share ticket describe edit_user create_user edit_time create_time pod_shell_relaxed edit_share );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_ticket where ( create_user='$user' or share='$company' or edit_share='$user' or edit_share like '%%,$user,%%' or edit_share like '$user,%%' or edit_share like '%%,$user'  $or or share like '%%_T_${company}_T_%%' or share like '%%_P_${user}_P_%%' or share like '%%_TR_${company}_TR_%%' or share like '%%_PR_${user}_PR_%%' ) $where", join( ',', map{"`$_`"}@col)), \@col )};
    return +{ stat => $JSON::false, info => $@ } if $@;

    for my $d ( @$r )
    {
        my $t = $d->{ticket};
        $d->{self} = $d->{create_user} eq $user ? 1 : 0; 

        $d->{self} = 2 if $d->{edit_share} eq $user || $d->{edit_share} =~ /,$user,/ || $d->{edit_share} =~ /^$user,/ || $d->{edit_share} =~ /,$user$/;

        if( $d->{type} eq 'UsernamePassword' )
        {
            my ( $n ) = split /_:separator:_/, $t;
            $d->{ticket} = +{ Username => $n, Password => '********' }
        }

        if( $d->{type} eq 'Harbor' )
        {
            my ( $s, $n ) = split /_:separator:_/, $t;
            $d->{ticket} = +{ Server => $s, Username => $n, Password => '********' }
        }

        if( $d->{type} eq 'JobBuildin' || $d->{type} eq 'SSHKey' || $d->{type} eq 'KubeConfig' )
        {
            $d->{ticket} = +{ $d->{type} => '********' }
        }
        $d->{share} = $d->{share} ? $d->{share} =~ /:oo:/ ? 'O' : 'T' : 'P';
    }
    return +{ stat => $JSON::true, data => $r };
};

=pod

凭据/获取凭据列表

只返回K8S的部分

=cut

get '/ticket/KubeConfig' => sub {
    my $param = params();
    my $error = Format->new( 
        treeid => qr/^\d+$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my @col = qw( id name type subtype share ticket describe edit_user create_user edit_time create_time pod_shell_relaxed edit_share );
    my $greptreeid = "";
    if( $param->{treeid} && $param->{treeid} ne '4000000000' )
    {
        $greptreeid = " and ( id in ( select distinct ci_type_ticketid from openc3_ci_project where ci_type='kubernetes' and groupid='$param->{treeid}') or id in ( select k8sid from openc3_ci_k8stree where treeid='$param->{treeid}' ) ) ";
    }
    my $r = eval{ 
        $api::mysql->query( 
            sprintf(
                 "select %s from openc3_ci_ticket where type = 'KubeConfig' $greptreeid and ( " . 
                     "( create_user ='$user' or share = '$company' or share like '%%_T_${company}_T_%%' or share like '%%_P_${user}_P_%%' or share like '%%_TR_${company}_TR_%%' or share like '%%_PR_${user}_PR_%%' ) ".
                     " or ( id in ( select ticketid from openc3_ci_k8s_namespace_auth where user='$user')) " .
                  " )",
                  join( ',', map{"`$_`"}@col)),
             \@col
        )
    };
    return +{ stat => $JSON::false, info => $@ } if $@;

    for my $d ( @$r )
    {
        my $t = $d->{ticket};
        $d->{self} = $d->{create_user} eq $user ? 1 : 0; 

        if( $d->{type} eq 'UsernamePassword' )
        {
            my ( $n ) = split /_:separator:_/, $t;
            $d->{ticket} = +{ Username => $n, Password => '********' }
        }

        if( $d->{type} eq 'JobBuildin' || $d->{type} eq 'SSHKey' || $d->{type} eq 'KubeConfig' )
        {
            $d->{ticket} = +{ $d->{type} => '********' }
        }
        $d->{auth} =
            ( $d->{self} || $d->{share} eq $company || $d->{share} =~ /_T_${company}_T_/ || $d->{share} =~ /_P_${user}_P_/ )
             ? 'X' : ( $d->{share} =~ /_TR_${company}_TR_/ || $d->{share} =~ /_PR_${user}_PR_/  ) ? 'R' : 'ns';
        $d->{share} = $d->{share} ? $d->{share} =~ /:oo:/ ? 'O' : 'T' : 'P';
    }
    return +{ stat => $JSON::true, data => $r };
};

=pod

凭据/获取单个凭据详情

=cut

get '/ticket/:ticketid' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my @col = qw( id name type subtype share ticket describe edit_user create_user edit_time create_time pod_shell_relaxed edit_share );
    my $r = eval{ 
## @app 为通过appkey、appname调用方式
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_ticket where id='$param->{ticketid}' and ( create_user='$user' or share='$company' or '$company'='\@app' or edit_share='$user' or edit_share like '%%,$user,%%' or edit_share like '$user,%%' or edit_share like '%%,$user' or share like '%%_T_${company}_T_%%' or share like '%%_P_${user}_P_%%' or share like '%%_TR_${company}_TR_%%' or share like '%%_PR_${user}_PR_%%' )", join( ',', map{"`$_`"}@col)), \@col )};
    return +{ stat => $JSON::false, info => $@ } if $@;

    for my $d ( @$r )
    {
        my $t = $d->{ticket};

        my $show = (
               ( 
                      $d->{create_user} eq $user || $company eq '@app'
                   || $d->{edit_share}  eq $user || $d->{edit_share} =~ /,$user,/ || $d->{edit_share} =~ /^$user,/ || $d->{edit_share} =~ /,$user$/
               )
               && $param->{detail}
           ) ? 1 : 0;

        if( $d->{type} eq 'UsernamePassword' )
        {
            my ( $n, $p ) = split /_:separator:_/, $t;
            $p = '********' unless $show;
            $d->{ticket} = +{ Username => $n, Password => $p }
        }

        if( $d->{type} eq 'Harbor' )
        {
            my ( $s, $n, $p ) = split /_:separator:_/, $t;
            $p = '********' unless $show;
            $d->{ticket} = +{ Server => $s, Username => $n, Password => $p }
        }

        if( $d->{type} eq 'JobBuildin' || $d->{type} eq 'SSHKey' )
        {
            $t = '********' unless $show;
            $d->{ticket} = +{ $d->{type} => $t }
        }

        if( $d->{type} eq 'KubeConfig' )
        {
            my ( $v, $c, $p ) = split /_:separator:_/, $t, 3;
            $c = '********' unless $show;
            $d->{ticket} = +{ $d->{type} => $c, kubectlVersion => $v, proxyAddr => $p }
        }

        if( $d->{share} =~ /:oo:/ )
        {
            my @share = split /:oo:/, $d->{share};
            for my $type ( qw( T P TR PR ) )
            {
                my @s = grep{ /^_${type}_[a-zA-Z0-9@\-_\.]+_${type}_$/ }@share;
                map{ $_ =~ s/^_${type}_//; $_ =~ s/_${type}_$//; }@s;
                $d->{"share_$type"} = join "\n", @s;
            }
        }
        $d->{share} = $d->{share} ? $d->{share} =~ /:oo:/ ? 'O' : 'T' : 'P';
    }

    return +{ stat => $JSON::true, data => $r->[0] || +{} };
};

=pod

凭据/创建

=cut

post '/ticket' => sub {
    my $param = params();
    my $error = Format->new( 
        name => [ 'mismatch', qr/'/ ], 1,
        type => [ 'in', 'SSHKey', 'UsernamePassword', 'JobBuildin', 'KubeConfig', 'Harbor' ], 1,
        subtype => [ 'mismatch', qr/'/ ], 0,
        describe => [ 'mismatch', qr/'/ ], 1,
        pod_shell_relaxed => qr/^\d+$/, 0,
        edit_share => [ 'mismatch', qr/'/ ], 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    if( $param->{type} eq 'KubeConfig' )
    {
        my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;
    }

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'CREATE TICKET', content => "NAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $subtype = $param->{subtype} // 'default';
    my $pod_shell_relaxed = $param->{pod_shell_relaxed} // '0';
    my $edit_share = $param->{edit_share} // '';
    my $share;
    if( $param->{share} eq 'P' )
    {
        $share = '';
    }
    elsif( $param->{share} eq 'T' )
    {
        $share = $company;
    }
    elsif( $param->{share} eq 'O' )
    {
        my @share;
        for my $type ( qw( T P TR PR ) )
        {
            push @share, ( map{ "_${type}_${_}_${type}_" }grep{ /^[a-zA-Z0-9@\-_\.]+$/ }split /\n/, $param->{"share_$type"} ) if defined $param->{"share_$type"};
        }
        $share = join ':oo:', "", @share, "";

    }
    else {
        return  +{ stat => $JSON::false, info => "share error" };
    }

    return  +{ stat => $JSON::false, info => "check format fail ticket" } unless $param->{ticket} && ref $param->{ticket} eq 'HASH';

    my $token = '';
    if( $param->{type} eq 'SSHKey' )
    {
        return  +{ stat => $JSON::false, info => "check format fail ticket" }
            unless $token = $param->{ticket}{SSHKey};
    }
    if( $param->{type} eq 'UsernamePassword' )
    {
        return  +{ stat => $JSON::false, info => "check format fail ticket" }
            unless $param->{ticket}{Username} && $param->{ticket}{Password};
        $token = "$param->{ticket}{Username}_:separator:_$param->{ticket}{Password}";
    }
    if( $param->{type} eq 'Harbor' )
    {
        return  +{ stat => $JSON::false, info => "check format fail ticket" }
            unless $param->{ticket}{Server} &&  $param->{ticket}{Username} && $param->{ticket}{Password};
        $token = "$param->{ticket}{Server}_:separator:_$param->{ticket}{Username}_:separator:_$param->{ticket}{Password}";
    }
 
    if( $param->{type} eq 'JobBuildin' )
    {
        return  +{ stat => $JSON::false, info => "check format fail ticket" }
            unless $token = $param->{ticket}{JobBuildin};
    }
    if( $param->{type} eq 'KubeConfig' )
    {
        return  +{ stat => $JSON::false, info => "check format fail ticket" }
            unless $param->{ticket}{KubeConfig} && $param->{ticket}{kubectlVersion} && $param->{ticket}{kubectlVersion} =~ /^v\d+\.\d+\.\d+$/;

        $token = "$param->{ticket}{kubectlVersion}_:separator:_$param->{ticket}{KubeConfig}";
        if( $param->{ticket}{proxyAddr} && $param->{ticket}{proxyAddr} =~ /^[a-zA-Z0-9:\.@]+$/ )
        {
            $token .= "_:separator:_$param->{ticket}{proxyAddr}";
        }
    }
 
    return  +{ stat => $JSON::false, info => "abnormal ticket format" } if $token =~ /\*{8}/;
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    eval{ 
        $api::mysql->execute( "insert into openc3_ci_ticket (`name`,`type`, `subtype`,`share`, `ticket`,`describe`,`edit_user`,`create_user`,`edit_time`,`create_time`, `pod_shell_relaxed`, `edit_share` ) values( '$param->{name}', '$param->{type}', '$subtype', '$share', '$token', '$param->{describe}', '$user', '$user', '$time', '$time', '$pod_shell_relaxed', '$edit_share' )");
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

凭据/编辑

=cut

post '/ticket/:ticketid' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
        type => [ 'in', 'SSHKey', 'UsernamePassword', 'JobBuildin', 'KubeConfig', 'Harbor' ], 1,
        subtype => [ 'mismatch', qr/'/ ], 0,
        describe => [ 'mismatch', qr/'/ ], 1,
        pod_shell_relaxed => qr/^\d+$/, 0,
        edit_share => [ 'mismatch', qr/'/ ], 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $user, $company ) = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'EDIT TICKET', content => "TICKETID:$param->{ticketid} NAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $subtype = $param->{subtype} // 'default';
    my $pod_shell_relaxed = $param->{pod_shell_relaxed} // '0';
    my $edit_share = $param->{edit_share} // '';

    my $share;
    if( $param->{share} eq 'P' )
    {
        $share = '';
    }
    elsif( $param->{share} eq 'T' )
    {
        $share = $company;
    }
    elsif( $param->{share} eq 'O' )
    {
        my @share;
        for my $type ( qw( T P TR PR ) )
        {
            push @share, ( map{ "_${type}_${_}_${type}_" }grep{ /^[a-zA-Z0-9@\-_\.]+$/ }split /\n/, $param->{"share_$type"} ) if defined $param->{"share_$type"};
        }
        $share = join ':oo:', "", @share, "";
    }
    else
    {
        return  +{ stat => $JSON::false, info => "share error" };
    }

    return  +{ stat => $JSON::false, info => "check format fail ticket" } unless $param->{ticket} && ref $param->{ticket} eq 'HASH';

    my $token = '';
    if( $param->{type} eq 'SSHKey' )
    {
        return  +{ stat => $JSON::false, info => "check format fail ticket" }
            unless $token = $param->{ticket}{SSHKey};
    }
    if( $param->{type} eq 'UsernamePassword' )
    {
        return  +{ stat => $JSON::false, info => "check format fail ticket" }
            unless $param->{ticket}{Username} && $param->{ticket}{Password};
        $token = "$param->{ticket}{Username}_:separator:_$param->{ticket}{Password}";
    }
    if( $param->{type} eq 'Harbor' )
    {
        return  +{ stat => $JSON::false, info => "check format fail ticket" }
            unless $param->{ticket}{Server} && $param->{ticket}{Username} && $param->{ticket}{Password};
        $token = "$param->{ticket}{Server}_:separator:_$param->{ticket}{Username}_:separator:_$param->{ticket}{Password}";
    }
    if( $param->{type} eq 'JobBuildin' )
    {
        return  +{ stat => $JSON::false, info => "check format fail ticket" }
            unless $token = $param->{ticket}{JobBuildin};
    }
    if( $param->{type} eq 'KubeConfig' )
    {
        return  +{ stat => $JSON::false, info => "check format fail ticket" }
            unless $param->{ticket}{KubeConfig} && $param->{ticket}{kubectlVersion} && $param->{ticket}{kubectlVersion} =~ /^v\d+\.\d+\.\d+$/;
        $token = "$param->{ticket}{kubectlVersion}_:separator:_$param->{ticket}{KubeConfig}";
        if( $param->{ticket}{proxyAddr} && $param->{ticket}{proxyAddr} =~ /^[a-zA-Z0-9:\.@]+$/ )
        {
            $token .= "_:separator:_$param->{ticket}{proxyAddr}";
        }
    }
 
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    return  +{ stat => $JSON::false, info => "abnormal ticket format" } if $token =~ /\*{8}/;

    my $update = eval{ 
        $api::mysql->execute( "update openc3_ci_ticket set name='$param->{name}',type='$param->{type}',subtype='$subtype',share='$share',ticket='$token',`describe`='$param->{describe}',edit_user='$user',edit_time='$time',pod_shell_relaxed='$pod_shell_relaxed',edit_share='$edit_share' where id=$param->{ticketid} and ( create_user='$user' or edit_share='$user' or edit_share like '%%,$user,%%' or edit_share like '$user,%%' or edit_share like '%%,$user' )" );
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : $update ? +{ stat => $JSON::true } : +{ stat => $JSON::false, info => 'not update' } ;
};

=pod

凭据/删除

=cut

del '/ticket/:ticketid' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $ticketname = eval{ $api::mysql->query( "select name from openc3_ci_ticket where id='$param->{ticketid}'")};
    eval{ $api::auditlog->run( user => $user, title => 'DELETE TICKET', content => "TICKETID:$param->{ticketid} NAME:$ticketname->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $update = eval{ 
        $api::mysql->execute( "delete from openc3_ci_ticket where id='$param->{ticketid}' and create_user='$user'" );
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : $update ? +{ stat => $JSON::true } : +{ stat => $JSON::false, info => 'not delete' };
};

true;
