package api::c3mc::jumpserver;
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

get '/c3mc/jumpserver' => sub {
    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my $cmd = "c3mc-device-ingestion-jumpserver 2>&1";
    my $handle = 'jumpserver';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

$handle{jumpserver} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;
    my @res;
    my @col = qw( UUID InstanceId HostName IP InIP ExIP OS Site VpcId VpcName );
    for( split /\n/, $x )
    {
        my @x = split /;/, $_;
        push @res, +{ map{ $col[$_] => $x[$_]}0.. @col -1 };
    }

    return +{ stat => $JSON::true, data => \@res };
};

true;
