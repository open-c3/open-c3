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

my $authstrict;
BEGIN{
    my $x = `c3mc-sys-ctl sys.device.auth.strict`;
    chomp $x;
    $authstrict = defined $x && $x eq '0' ? 0 : 1;
};

=pod

CMDB/获取CMDB数据

=cut

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

=pod

CMDB/获取菜单

=cut

get '/c3mc/cmdb/menu' => sub {
    my $param = params();
    my $error = Format->new( 
        treeid       => qr/^\d+$/, 1,
        timemachine  => qr/^[a-z0-9][a-z0-9\-]+[a-z0-9]$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my $pmscheck;
    if( $authstrict )
    {                                                                                                    
          $pmscheck = $param->{treeid} == 0                                                              
            ? api::pmscheck( 'openc3_job_root'                    )                                      
            : api::pmscheck( 'openc3_job_write', $param->{treeid} );                                     
    }                                                                                                    
    else 
    {                                                                                                    
          $pmscheck = api::pmscheck( 'openc3_job_read', $param->{treeid} );                              
    }                                                                                                    
    return $pmscheck if $pmscheck;  

    my $cmd = "c3mc-device-menu '$param->{treeid}' '$param->{timemachine}'";
    my $handle = 'cmdb_menu';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

$handle{cmdb_menu} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;
    my $data = eval{ YAML::XS::Load $x };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $data };
};


true;
