package api::assignment;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use MIME::Base64;
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;
use Util;

=pod

协助操作/获取我的协助操作列表

=cut

get '/assignment/byme' => sub {
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my @col = qw( id type name submitter handler url method data submit_reason handle_reason status remarks create_time finish_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_assignment
                where submitter='$user' order by id desc limit 100", join( ',', map{ ( $_ eq 'remarks' || $_ eq 'data' )? "CONVERT($_ USING utf8) as $_" : $_ }@col ) ), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;

    map{ $_->{data} = eval{ YAML::XS::Load decode_base64( $_->{data} ) } }@$r;
    return +{ stat => $JSON::true, data => $r };
};

=pod

协助操作/获取需要我协助操作的列表

=cut

get '/assignment/tome' => sub {
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my @col = qw( id type name submitter handler url method data submit_reason handle_reason status remarks create_time finish_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_assignment
                where handler='$user' order by id desc limit 100", join( ',', map{ ( $_ eq 'remarks' || $_ eq 'data' )? "CONVERT($_ USING utf8) as $_" : $_ }@col ) ), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;
    map{ $_->{data} = eval{ YAML::XS::Load decode_base64( $_->{data} ) } }@$r;
    return +{ stat => $JSON::true, data => $r };
};

=pod

协助操作/获取一个操作的详情

=cut

get '/assignment/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my @col = qw( id type name submitter handler url method data submit_reason handle_reason status remarks create_time finish_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_assignment where id='$param->{id}' and ( submitter='$user' or handler='$user' )", join ',', map{ ( $_ eq 'remarks' || $_ eq 'data' )? "CONVERT($_ USING utf8) as $_" : $_ }@col), \@col )};


    return +{ stat => $JSON::false, info => $@ } if $@;

    $r->[0]{data} = eval{ YAML::XS::Load decode_base64( $r->[0]{data} ) };
    return +{ stat => $JSON::true, data => $r->[0] };
};

=pod

协助操作/提交一个协助操作

=cut

post '/assignment' => sub {
    my $param = params();
    my $error = Format->new( 
        type => [ 'in', 'kubernetes' ], 1,
        name => [ 'mismatch', qr/'/ ], 1,
        handler => [ 'mismatch', qr/'/ ], 1,
        url => [ 'mismatch', qr/'/ ], 1,
        method => [ 'in', 'POST' ], 1,
        submit_reason => [ 'mismatch', qr/'/ ], 1,
        remarks => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

##submitter
##data
##handle_reason
##status
#create_time
##finish_time

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'ASSIGNMENT', content => "NAME:$param->{name}" ); };

    my $data = eval{ encode_base64( encode('UTF-8', YAML::XS::Dump $param->{data} )); };
    return +{ stat => $JSON::false, info => "post.data encode err:$@" } if $@;

    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    my $r = eval{ $api::mysql->execute( "insert into openc3_ci_assignment (`type`,`name`,`submitter`,`handler`,`url`,`method`,`data`,`submit_reason`,`handle_reason`,`status`,`remarks`,`create_time`,`finish_time`) values('$param->{type}','$param->{name}','$user','$param->{handler}','$param->{url}','$param->{method}','$data','$param->{submit_reason}','','todo','$param->{remarks}','$time','$time') ")};

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

=pod

协助操作/操作一个需要我协助的操作

=cut

post '/assignment/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
        status => [ 'in', 'fail', 'success', 'refuse', 'cancel', 'close' ], 1,
        handle_reason => [ 'mismatch', qr/'/ ], 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'ASSIGNMENT', content => "ID:$param->{id} STATUS:$param->{status}" ); };

    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    eval{
        if ( $param->{status} eq 'cancle' )
        {
             $api::mysql->execute( "update openc3_ci_assignment set status='$param->{status}',finish_time='$time' where id='$param->{id}' and submitter='$user' and status='todo' ");
        }
        else
        {
             $api::mysql->execute( "update openc3_ci_assignment set status='$param->{status}',finish_time='$time' where id='$param->{id}' and handler='$user' and ( status='todo' or status='fail' )");
             my $handle_reason = $param->{handle_reason} // '';
             $api::mysql->execute( "update openc3_ci_assignment set handle_reason='$handle_reason' where id='$param->{id}' and handler='$user' and handle_reason=''");
        }
    };

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
