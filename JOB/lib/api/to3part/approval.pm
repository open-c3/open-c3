package api::to3part::approval;
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

my %key;
BEGIN{
    my $f = '/data/open-c3-data/to3part.yml';
    if( -f $f )
    {
        my $c = eval{ YAML::XS::LoadFile $f };
        warn "load $f err: $@" if $@;
        %key = %$c if $c && ref $c eq 'HASH';
    }
};

=pod

第三方接口/提交审批

=cut

post '/to3part/v1/approval' => sub {
    my $param = params();
    my $error = Format->new( 
        user_id          => [ 'mismatch', qr/'/ ], 0,
        special_approver => [ 'mismatch', qr/'/ ], 1,
        title            => [ 'mismatch', qr/'/ ], 1,
        apply_note       => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error", code => 1, msg => "check format fail $error" } if $error;

    my ( $appkey, $appname ) = map{ request->headers->{$_} }qw( appkey appname );

    return  +{ stat => $JSON::false, info => "key err", code => 1, msg => "key err" } unless $appkey && $appname && $key{$appname} && $key{$appname} eq $appkey;

    my $puuid = uuid->new()->create_str;
    my $muuid = uuid->new()->create_str;
    my $user  = $param->{special_approver};
    my $submitter = $param->{user_id} // 'sys@app';
    my $cont = $param->{apply_note};
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    my $approvalname = $param->{title};
    my $everyone = 1;
    my $tempeo = $everyone ? 'YES' :'NO';
    eval{
        $api::mysql->execute(
            "insert into openc3_job_approval (`taskuuid`,`uuid`,`user`,`submitter`,`cont`,`opinion`,`remarks`,`create_time`,`notifystatus`,`oauuid`,`name`,`everyone`)values('$puuid','$muuid','$user','$submitter','$cont','unconfirmed', '','$time', 'null', '0','$approvalname', '$tempeo' )"
        );
    };

    return $@
        ? +{ stat => $JSON::false, info => $@, code => 1, msg => "Err: $@" }
        : +{ stat => $JSON::true, code => 0, mesg => 'ok', data => +{ djbh => $puuid, "msg" => "ok" } };
};

=pod

第三方接口/查询审批的状态

=cut

get '/to3part/v1/approval' => sub {
    my $param = params();
    my $error = Format->new(
        djbh => qr/^[a-zA-Z0-9\.\-_@]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error", code => 1, msg => "check format fail $error" } if $error;

    my ( $appkey, $appname ) = map{ request->headers->{$_} }qw( appkey appname );

    return  +{ stat => $JSON::false, info => "key err", code => 1, msg => "key err" } unless $appkey && $appname && $key{$appname} && $key{$appname} eq $appkey;

    my $x = eval{ $api::mysql->query( "select opinion from openc3_job_approval where taskuuid='$param->{djbh}'" ) };

    return +{ stat => $JSON::false, info => $@, code => 1, msg => $@ } if $@;

    return +{ stat => $JSON::true, code => 0, msg => 'ok', data => +{ isend => 0, data => undef } } unless @$x > 0;

    my $opinion = $x->[0][0];
    my $isend = ( $opinion eq 'agree' || $opinion eq 'refuse' ) ? 1 : 0;
    my $actionname = Encode::decode( 'utf8', "待办"   );
       $actionname = Encode::decode( 'utf8', "同意"   ) if $opinion eq 'agree';
       $actionname = Encode::decode( 'utf8', "不同意" ) if $opinion eq 'refuse';
    return +{ stat => $JSON::true, code => 0, msg => 'ok', data => +{ isend => $isend, data => [ { actionname => $actionname } ]} }
};

true;
