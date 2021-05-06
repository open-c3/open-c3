package api::variable;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON;
use POSIX;
use MIME::Base64;
use api;
use Format;

get '/variable/:projectid/:jobuuid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        jobuuid => qr/^[a-zA-Z0-9]+$/, 1, 
        empty => qr/^\d+$/, 0, 
        exclude => qr/^[a-zA-Z0-9,_]+$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $exclude = '';
    if( $param->{exclude} )
    {
        $exclude = sprintf "and name not in( %s )", join ',',map{ "'$_'" }split /,/,$param->{exclude};
    }

    my $w = $param->{empty} ? "and value=''" : '';
    my @col = qw( id name value describe create_user create_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_variable
                where jobuuid in ( select uuid from openc3_job_jobs where projectid='$param->{projectid}' and uuid='$param->{jobuuid}') $w $exclude", 
                    join ',',map{"`$_`"} @col ), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

#jobuuid
#name
#value
#describe
post '/variable/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        jobuuid => qr/^[a-zA-Z0-9]+$/, 1, 
        name => qr/^[a-zA-Z0-9_]+$/, 1,
        value => qr/^[a-zA-Z0-9_\.\/]+$/, 0,
        describe => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    $param->{value} = '' unless defined $param->{value};
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $r = eval{ 
       $api::mysql->execute( 
         "replace into openc3_job_variable (`jobuuid`,`name`,`value`,`describe`,`create_user`)
             select uuid,'$param->{name}','$param->{value}', '$param->{describe}', '$user'
                 from openc3_job_jobs where projectid='$param->{projectid}' and uuid='$param->{jobuuid}'")
    };

    my $x = $@ ? $@ : $r > 0 ? undef : "no update anything:$r" ;
    return $x ?  +{ stat => $JSON::false, info => $x } : +{ stat => $JSON::true, data => $r };
};

#jobuuid
#data [ +{ name => '', value => '', describe => '' } ]
post '/variable/:projectid/update' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        jobuuid => qr/^[a-zA-Z0-9]+$/, 1, 
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $x = eval{ $api::mysql->query( "select uuid from openc3_job_jobs where projectid='$param->{projectid}' and uuid='$param->{jobuuid}'" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::false, info => 'no uuid from project' } unless $x && @$x;

    return +{ stat => $JSON::false, info => 'no data in ARRAY' } unless $param->{data} && ref $param->{data} eq 'ARRAY';
    for my $d ( @{$param->{data}} )
    {
        $error = Format->new( 
            name => qr/^[a-zA-Z0-9_]+$/, 1,
            value => qr/^[a-zA-Z0-9_\.\/\-]*$/, 0,
            describe => [ 'mismatch', qr/'/ ], 1,
        )->check( %$d );
        return  +{ stat => $JSON::false, info => "check data format fail $error" } if $error;
        $d->{value} = '' unless defined $d->{value};

        if( grep{ $d->{name} eq $_ || $d->{name} =~ /^wk_/  }qw( _exit_ _appname_ _skipSameVersion_ _rollbackVersion_ _authorization_ ) )
        {
            eval{
                $api::mysql->execute( "replace into openc3_job_variable ( `jobuuid`,`name`,`value`,`describe`,`create_user` ) 
                    values('$param->{jobuuid}','$d->{name}','$d->{value}','$d->{describe}','$user')");
            };

        }
        else
        {
            eval{
                $api::mysql->execute( "update openc3_job_variable set value='$d->{value}',`describe`='$d->{describe}',create_user='$user' 
                    where jobuuid='$param->{jobuuid}' and name='$d->{name}'");
            };
        }
        return +{ stat => $JSON::false, info => $@ } if $@;

    }
    return +{ stat => $JSON::true };
};

#jobuuid
#name
del '/variable/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        jobuuid => qr/^[a-zA-Z0-9]+$/, 1, 
        name => qr/^[a-zA-Z0-9_]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $r = eval{ 
        $api::mysql->execute(
            "delete from openc3_job_variable where name='$param->{name}' and jobuuid in
                ( select uuid from openc3_job_jobs where projectid='$param->{projectid}' and uuid='$param->{jobuuid}' )")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

true;
