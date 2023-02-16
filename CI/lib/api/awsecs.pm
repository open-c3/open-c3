package api::awsecs;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;

=pod

AWS/ECS/获取服务列表

=cut

get '/awsecs/:treeid' => sub {
    my $param = params();
    my $error = Format->new( treeid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{treeid} ); return $pmscheck if $pmscheck;

    my @col = qw( id ticketid region cluster service taskdef);
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_awsecs", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r  };
};

true;
