package api::monitor::ack;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;

get '/monitor/ack/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $uuid = substr( $param->{uuid}, 0, 12 );

    my @col = qw( id labels fingerprint caseuuid );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_ack_table where ackuuid='$uuid'", join( ',', @col)), \@col )};

    my ( $acked, $time, @res ) = ( 0, time );
    my $amackid = 0;
    for my $x ( @$r )
    {
        $amackid = $x->{id};
        map{
            my @x = split /=/, $_, 2;
            push @res, +{ name => $x[0], value => $x[1] }
        } split /,/, $x->{labels};

        my $xx = eval{ 
            $api::mysql->query( "select id from openc3_monitor_ack_active where ( uuid='$x->{fingerprint}' or uuid='$x->{caseuuid}' ) and type='G' and expire>$time" ) };
        $acked = 1 if @$xx > 0;
    }

    my $info = `amtool --alertmanager.url=http://openc3-alertmanager:9093 silence`;
    my $amacked = $info =~ m#by-c3-ack-\($amackid\)# ? 1 : 0;
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@res, acked => $acked, amacked => $amacked };
};

post '/monitor/ack/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
        ctrl => [ 'in', 'ack', 'ackcase', 'ackam' ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $u, $ctrl ) = @$param{qw( uuid ctrl )};
    my ( $uuid, $usertoken ) = ( substr( $u, 0, 12 ), substr( $u, 12 ) );
    my $user = `c3mc-base-user-temp-token  -get '$usertoken'`;
    chomp $user;
    return  +{ stat => $JSON::false, info => "check format fail $error" } unless $user && $user =~ /^[a-zA-Z0-9][a-zA-Z0-9@\.\-_\/]+[a-zA-Z0-9]$/;

    my $time = time + 86400;
    my $type = $param->{type} && $param->{type} eq 'P' ? 'P' : 'G';
    eval{
        if( $ctrl eq 'ackcase' )
        {
            $api::mysql->execute( "insert into openc3_monitor_ack_active ( uuid,type,treeid,edit_user,expire ) select `caseuuid`,'$type',treeid,'$user','$time' from openc3_monitor_ack_table  where ackuuid='$uuid'" );
        }
        elsif( $ctrl eq 'ackam' )
        {
            my $x = $api::mysql->query( "select labels,id from openc3_monitor_ack_table where ackuuid='$uuid'" );
            die "nofind your ackuuid" unless $x && @$x > 0;
            my @x;
            for( split /,/, $x->[0][0] )
            {
                next if $_ =~ /'/;
                my @xx = split /=/, $_, 2;
                push @x, "$1=$xx[1]" if $xx[0] =~ /^labels\.(.+)$/;
            }
            
            system( sprintf "c3mc-mon-alertmanager-silence -c 'by-c3-ack-($x->[0][1])' -u '$user' %s", join ' ', map{ "'$_'" }@x  ) if @x;
        }
        else
        {
            $api::mysql->execute( "insert into openc3_monitor_ack_active ( uuid,type,treeid,edit_user,expire ) select `fingerprint`,'$type',treeid,'$user','$time' from openc3_monitor_ack_table  where ackuuid='$uuid'" );
        }
    };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
