package api::k8stree;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;

get '/k8stree/:treeid' => sub {
    my $param = params();
    my $error = Format->new( 
        treeid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{treeid} ); return $pmscheck if $pmscheck;

    my $r = eval{ $api::mysql->query( "select k8sid from openc3_ci_k8stree where treeid='$param->{treeid}'" );};
    return +{ stat => $JSON::false, info => $@ } if $@;
    my %r; map{ $r{$_->[0]} = 1 }@$r;

    my $r2 = eval{ $api::mysql->query( "select distinct ci_type_ticketid from openc3_ci_project where ci_type='kubernetes' and groupid='$param->{treeid}'" );};
    return +{ stat => $JSON::false, info => $@ } if $@;
    my %r2; map{ $r2{$_->[0]} = 1 }@$r2;

    return +{ stat => $JSON::true, data => +{ human => \%r, auto => \%r2 } };
};

post '/k8stree/:treeid/:k8sid' => sub {
    my $param = params();
    my $error = Format->new( 
        treeid => qr/^\d+$/, 1,
        k8sid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_write', $param->{treeid} ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ),
        map{ $_ => request->headers->{$_} }qw( appkey appname ));
    eval{ $api::auditlog->run( user => $user, title => 'K8STREE SET', content => "treeid:$param->{treeid} k8sid:$param->{k8sid}" ); };

    eval{ $api::mysql->execute( "insert into openc3_ci_k8stree (`treeid`,`k8sid` ) values( '$param->{treeid}', '$param->{k8sid}')"); };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

del '/k8stree/:treeid/:k8sid' => sub {
    my $param = params();
    my $error = Format->new( 
        treeid => qr/^\d+$/, 1,
        k8sid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_write', $param->{treeid} ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ),
        map{ $_ => request->headers->{$_} }qw( appkey appname ));
    eval{ $api::auditlog->run( user => $user, title => 'K8STREE DEL', content => "treeid:$param->{treeid} k8sid:$param->{k8sid}" ); };

    eval{ $api::mysql->execute( "delete from openc3_ci_k8stree where treeid='$param->{treeid}' and k8sid='$param->{k8sid}'"); };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
