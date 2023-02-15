package api::variable;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;
use Digest::MD5;

=pod

作业/变量/获取变量token

在需要自动更新变量内容时，需要创建一个token

=cut

get '/variable/:projectid/:jobuuid/token' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        jobuuid => qr/^[a-zA-Z0-9]+$/, 1, 
        name => qr/^[a-zA-Z0-9,_]+$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_root' ); return $pmscheck if $pmscheck;

    my $file = "/data/open-c3-data/job.variable.token";
    unless( -f $file )
    {
        system "seq 1 5|xargs -i{} date +%N|xargs -n 10|sed 's/ //g' > $file";
    }
    my $x = `cat $file`;
    chomp $x;
    my $md5 = Digest::MD5->new->add( join "::", $x, @$param{qw( projectid jobuuid name )} )->hexdigest;

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $md5 };
};

=pod

作业/变量/更新变量的下拉框列表

=cut

any '/variable/update/:projectid/:jobuuid/:token/:name/:option' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        jobuuid => qr/^[a-zA-Z0-9]+$/, 1, 
        token => qr/^[a-zA-Z0-9]+$/, 1, 
        name => qr/^[a-zA-Z0-9,_]+$/, 1,
        option => qr/^[a-zA-Z0-9,_\.\-@]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $file = "/data/open-c3-data/job.variable.token";
    return +{ stat => $JSON::false, info => "token error" } unless -f $file;
    my $x = `cat $file`;
    chomp $x;
    my $md5 = Digest::MD5->new->add( join "::", $x, @$param{qw( projectid jobuuid name )}  )->hexdigest;

    return +{ stat => $JSON::false, info => "token error" } if $md5 ne $param->{token};

    eval{
        $api::mysql->execute( "update openc3_job_variable set `option`='$param->{option}'
            where jobuuid='$param->{jobuuid}' and name='$param->{name}'");
    };
 
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

作业/变量/获取作业变量

=cut

get '/variable/:projectid/:jobuuid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        jobuuid => qr/^[a-zA-Z0-9]+$/, 1, 
        empty => qr/^\d+$/, 0, 
        exclude => qr/^[a-zA-Z0-9,_]+$/, 0,
        env => [ 'in', 'test', 'online' ], 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $exclude = '';
    if( $param->{exclude} )
    {
        $exclude = sprintf "and name not in( %s )", join ',',map{ "'$_'" }split /,/,$param->{exclude};
    }

    my $w = $param->{empty} ? "and value=''" : '';

    my $envwhere = '';
    if( $param->{env} )
    {
        $envwhere = sprintf "and `env`!='%s'", $param->{env} eq 'test' ? 'online' : 'test';
    }

    my @col = qw( id name value describe option create_user create_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_variable
                where jobuuid in ( select uuid from openc3_job_jobs where projectid='$param->{projectid}' and uuid='$param->{jobuuid}') $w $envwhere $exclude order by `describe`", 
                    join ',',map{"`$_`"} @col ), \@col )};

    return  +{ stat => $JSON::false, info => $@ } if $@;

    my %defaultdescribe = (
        tester   =>  Encode::decode("utf8", '1.测试审批人'),
        approver =>  Encode::decode("utf8", '2.OA审批人 或 领导审批人'),
        checker  =>  Encode::decode("utf8", '3.发布前确认人'),
        tagger   =>  Encode::decode("utf8", '4.触发人,发布前确认人'),
        '_pip_'  =>  Encode::decode("utf8", '5.指定IP发布'),
    );
    for( @$r )
    {
        next if $_->{describe};
        $_->{describe} = $defaultdescribe{$_->{name}} if $defaultdescribe{$_->{name}};
    }

    if( $param->{usrext} )
    {
        for( @$r )
        {
            next unless $_->{option} && $_->{option} =~ /_\@[a-zA-Z0-9_\-\.]+_/;
            my @opt = split /,/, $_->{option};
            my @tmp;
            for my $x ( @opt )
            {
                if( $x && $x =~ /^_(\@[a-zA-Z0-9_\-\.]+)_$/ )
                {
                    my    @x = `echo '$1'|sed 's/,/ /g'|xargs -n 1|c3mc-app-usrext`;
                    chomp @x;
                    push @tmp, @x;
                }
                else
                {
                    push @tmp, $x;
                }
            }
            $_->{option} = join ',', @tmp;
        }
    }

    return +{ stat => $JSON::true, data => [ sort{ $a->{describe} cmp $b->{describe} }@$r ] };
};

=pod

作业/变量/提交作业变量

=cut

post '/variable/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        jobuuid => qr/^[a-zA-Z0-9]+$/, 1, 
        name => qr/^[a-zA-Z0-9_]+$/, 1,
        value => qr/^[a-zA-Z0-9_\.\/\-,@]*$/, 0,
        describe => [ 'mismatch', qr/'/ ], 1,
        option => qr/^[a-zA-Z0-9_\.\/\-,@]*$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    $param->{value} = '' unless defined $param->{value};
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => 'UPDATE JOB VARIABLE', content => "TREEID:$param->{projectid} NAME:$param->{name}" ); };

    my $r = eval{ 
       $api::mysql->execute( 
         "replace into openc3_job_variable (`jobuuid`,`name`,`value`,`describe`,`option`,`create_user`)
             select uuid,'$param->{name}','$param->{value}', '$param->{describe}','$param->{option}', '$user'
                 from openc3_job_jobs where projectid='$param->{projectid}' and uuid='$param->{jobuuid}'")
    };

    my $x = $@ ? $@ : $r > 0 ? undef : "no update anything:$r" ;
    return $x ?  +{ stat => $JSON::false, info => $x } : +{ stat => $JSON::true, data => $r };
};

=pod

作业/变量/更新作业变量

data [ +{ name => '', value => '', describe => '', option => '' } ]

=cut

post '/variable/:projectid/update' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        jobuuid => qr/^[a-zA-Z0-9]+$/, 1, 
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    eval{ $api::auditlog->run( user => $user, title => 'UPDATE JOB VARIABLE', content => "TREEID:$param->{projectid} JOBUUID:$param->{jobuuid}" ); };

    my $x = eval{ $api::mysql->query( "select uuid from openc3_job_jobs where projectid='$param->{projectid}' and uuid='$param->{jobuuid}'" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::false, info => 'no uuid from project' } unless $x && @$x;

    return +{ stat => $JSON::false, info => 'no data in ARRAY' } unless $param->{data} && ref $param->{data} eq 'ARRAY';
    for my $d ( @{$param->{data}} )
    {
        $error = Format->new( 
            name => qr/^[a-zA-Z0-9_]+$/, 1,
            value => qr/^[a-zA-Z0-9_\.\/\-,@]*$/, 0,
            describe => [ 'mismatch', qr/'/ ], 1,
            option => qr/^[a-zA-Z0-9_\.\/\-,@;]*$/, 0,
        )->check( %$d );
        return  +{ stat => $JSON::false, info => "check data format fail $error" } if $error;
        $d->{value} = '' unless defined $d->{value};

        if( grep{ $d->{name} eq $_ || $d->{name} =~ /^wk_/  }qw( _exit_ _appname_ _skipSameVersion_ _rollbackVersion_ _authorization_ _nodebatch_ _pip_ ) )
        {
            eval{
                $api::mysql->execute( "replace into openc3_job_variable ( `jobuuid`,`name`,`value`,`describe`,`option`,`create_user` ) 
                    values('$param->{jobuuid}','$d->{name}','$d->{value}','$d->{describe}','$d->{option}','$user')");
            };

        }
        else
        {
            eval{
                $api::mysql->execute( "update openc3_job_variable set value='$d->{value}',`describe`='$d->{describe}',`option`='$d->{option}',create_user='$user' 
                    where jobuuid='$param->{jobuuid}' and name='$d->{name}'");
            };
        }
        return +{ stat => $JSON::false, info => $@ } if $@;

    }
    return +{ stat => $JSON::true };
};

=pod

作业/变量/删除变量

=cut

del '/variable/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        jobuuid => qr/^[a-zA-Z0-9]+$/, 1, 
        name => qr/^[a-zA-Z0-9_]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_delete', $param->{projectid} ); return $pmscheck if $pmscheck;
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    eval{ $api::auditlog->run( user => $user, title => 'DELETE JOB VARIABLE', content => "TREEID:$param->{projectid} JOBUUID:$param->{jobuuid} NAME:$param->{name}" ); };

    my $r = eval{ 
        $api::mysql->execute(
            "delete from openc3_job_variable where name='$param->{name}' and jobuuid in
                ( select uuid from openc3_job_jobs where projectid='$param->{projectid}' and uuid='$param->{jobuuid}' )")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

=pod

作业/变量/通过变量id删除变量

=cut

del '/variable/byid/:jobid' => sub {
    my $param = params();
    my $error = Format->new( 
        jobid => qr/^\d+$/, 1,
        name => qr/^[a-zA-Z0-9_]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    eval{ $api::auditlog->run( user => $user, title => 'DELETE JOB VARIABLE', content => "JOBID:$param->{jobid} NAME:$param->{name}" ); };

    my $r = eval{ 
        $api::mysql->execute(
            "delete from openc3_job_variable where name='$param->{name}' and jobuuid in
                ( select uuid from openc3_job_jobs where id='$param->{jobid}' )")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
