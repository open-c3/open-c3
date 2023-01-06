package api::c3mc::cmdb;
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

get '/c3mc/cmdb' => sub {
    my $param = params();
    my $error = Format->new( 
        type    => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+$/, 1,
        subtype => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+$/, 1,
        alias   => qr/^\d+$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my $filter = +{
        type    => $param->{type   },
        subtype => $param->{subtype},
        alias   => $param->{alias  },
    };

    my $cmd = "c3mc-device-cat curr '$param->{type}' '$param->{subtype}' 2>&1";
    my $handle = 'cmdb';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{cmdb} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;
    my @res;
    my @cont = split /\n/, $x;
    return +{ stat => $JSON::true, data => [] } unless @cont > 1;

    my %alias;
    unless( $filter->{alias} )
    {
        my $alias = eval{ YAML::XS::LoadFile "/data/open-c3-data/device/curr/$filter->{type}/$filter->{subtype}/alias.yml" };
        return +{ stat => $JSON::false, info => "load alias error: $@" } if $@;
        return +{ stat => $JSON::false, info => "load alias error: No Hash" } unless $alias && ref $alias eq 'HASH';

        %alias = map{ $alias->{$_} => $_ } keys %$alias;
    }

    my @col = map{ $alias{$_} || $_ }split /\t/, shift @cont;
    for( @cont )
    {
        my @x = split /\t/, $_;
        push @res, +{ map{ $col[$_] => $x[$_]}0.. @col -1 };
    }

    return +{ stat => $JSON::true, data => \@res };
};

true;
