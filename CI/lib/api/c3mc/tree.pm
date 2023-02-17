package api::c3mc::tree;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use JSON qw();
use POSIX;
use api;
use Format;
use Time::Local;
use File::Temp;
use api::c3mc;

our %handle = %api::kubernetes::handle;

=pod

服务树/获取子树列表

=cut

get '/c3mc/tree/subtreemap/:treeid' => sub {
    my $param = params();
    my $error = Format->new( 
        treeid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{treeid} ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $cmd = "c3mc-base-subtreemap $param->{treeid}";
    my $handle = 'subtreemap';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

$handle{subtreemap} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my @res;
    for( split /\n/, $x )
    {
        my @x = split /;/, $_, 2;
        push @res, +{ id => $x[0], name => $x[1] };
    }

    return +{ stat => $JSON::true, data => \@res };
};

true;
