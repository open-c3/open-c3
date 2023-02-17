package api::inherit;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;

=pod

服务树/获取服务树继承关系

=cut

get '/inherit/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id projectid inheritid create_time fullname);
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_agent_inherit where projectid='$param->{projectid}'", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => @$r ? $r->[0] : +{} };
};

true;
