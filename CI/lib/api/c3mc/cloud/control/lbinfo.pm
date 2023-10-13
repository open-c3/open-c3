package api::c3mc::cloud::control::lbinfo;
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

云资源/控制/lb信息/获取资源lb后端信息

=cut

get '/c3mc/cloud/control/lbinfo/get/:type/:subtype/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        type    => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+$/,  1,
        subtype => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+$/,  1,
        uuid    => qr/^[a-zA-Z0-9][a-zA-Z0-9\-_\.]+$/, 1,
        table   => qr/^\d+$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my $filter = +{ table => $param->{table} ? 1 : 0 };

    my $cmd = "c3mc-cloud-control --type '$param->{type}' --subtype '$param->{subtype}' --uuid '$param->{uuid}' --ctrl get-backend-servers x 2>&1";
    my $handle = 'cloud_lbinfo_get';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{cloud_lbinfo_get} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;

    if( $filter->{table} )
    {
        my $d = eval{ YAML::XS::Load $x };
        return +{ stat => $JSON::false, info => "load data fail: $@" } if $@;

        my %title;
        for my $dd ( @$d )
        {
            for my $k ( keys %$dd )
            {
                $title{$k} ++;
                $dd->{$k} = join( ',', @{$dd->{$k}} ) if ref $dd->{$k} eq 'ARRAY';
            }
        }

        return +{ stat => $JSON::true, data => $d, title => [ sort keys %title ] };
    }
    else
    {
        my $d = eval{ YAML::XS::Dump YAML::XS::Load $x };
        return +{ stat => $JSON::false, info => "load data fail: $@" } if $@;

        return +{ stat => $JSON::true, data => $d };
    }
};

true;
