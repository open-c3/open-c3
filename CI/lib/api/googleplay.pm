package api::googleplay;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;
use uuid;
use DateTime;

my %key;
BEGIN{
    my $f = '/data/open-c3-data/to3part.yml';
    if( -f $f )
    {
        my $c = eval{ YAML::XS::LoadFile $f };
        warn "load $f err: $@" if $@;
        %key = %$c if $c && ref $c eq 'HASH';
    }

    $key{jobx} = $ENV{OPEN_C3_RANDOM} if $ENV{OPEN_C3_RANDOM};
};

=pod

googleplay/获取包列表

=cut

get '/googleplay/review/app_package_name' => sub {
    my $pmscheck = api::pmscheck( 'openc3_job_read', 0 ); return $pmscheck if $pmscheck;

    my $r = eval{ 
        $api::mysql->query( "SELECT DISTINCT app_package_name FROM openc3_ci_googleplay_review" )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => [ map{ +{ label => $_, value => $_ } }map{@$_ }@$r] };
};


=pod

googleplay/获取评论列表

=cut

get '/googleplay/review' => sub {
    my $param = params();
    my $error = Format->new(
        appname => qr/^[\.a-zA-Z0-9\-_]*$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', 0 ); return $pmscheck if $pmscheck;

    my @col = qw( review_id device_name comment_time_seconds thumbs_up_count thumbs_down_count reviewer_language app_version_code app_version_name android_os_version star_rating user_comment developer_comment author_name package_name app_package_name callback create_time );
    my $where = $param->{appname} ? "where app_package_name='$param->{appname}'" : "";
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_googleplay_review $where order by comment_time_seconds desc", join( ',', @col)), \@col )};


    for my $x ( @$r )
    {
        my $dt = DateTime->from_epoch(epoch => $x->{comment_time_seconds}, time_zone => 'UTC');
        $x->{comment_time} = $dt->strftime("%Y-%m-%d %H:%M:%S") . ' UTC';

        map{ 
            $x->{$_}  = Encode::decode("utf8", decode_base64( $x->{$_} ) ) if defined $x->{$_}
        }qw( user_comment developer_comment );

    }
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r  };
};

=pod

googleplay/评论上报

=cut

post '/googleplay/review/record' => sub {
    my @col = qw( review_id device_name comment_time_seconds thumbs_up_count thumbs_down_count reviewer_language app_version_code app_version_name android_os_version star_rating user_comment developer_comment author_name package_name app_package_name callback );

    my $param = params();
    my $error = Format->new( 
        map{ ( $_  => [ 'mismatch', qr/'/ ], 1, ) }grep{ !( $_ eq 'user_comment' || $_ eq 'developer_comment' ) }@col
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $appkey, $appname ) = map{ request->headers->{$_} }qw( appkey appname );
    $appname = $param->{appname} if ( ! $appname ) && $param->{appname};
    $appkey  = $param->{appkey } if ( ! $appkey  ) && $param->{appkey };

    return  +{ stat => $JSON::false, info => "key err", code => 1, msg => "key err" } unless $appkey && $appname && $key{$appname} && $key{$appname} eq $appkey;

    my $projectid = $param->{projectid};
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    map{ $param->{$_}  = encode_base64( encode('UTF-8',  $param->{$_}) ) }qw( user_comment developer_comment );

    eval{ 
        $api::mysql->execute( sprintf ("replace into openc3_ci_googleplay_review ( %s ) values( %s )", join( ',', map{"`$_`"}@col), join( ',', map{ "'$param->{$_}'" }@col ) ));
    };

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
