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

    my @col = qw( labels fingerprint caseuuid );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_ack_table where ackuuid='$param->{uuid}'", join( ',', @col)), \@col )};

    my ( $acked, $time, @res ) = ( 0, time );
    for my $x ( @$r )
    {
        map{
            my @x = split /=/, $_, 2;
            push @res, +{ name => $x[0], value => $x[1] }
        } split /,/, $x->{labels};

        my $xx = eval{ 
            $api::mysql->query( "select id from openc3_monitor_ack_active where uuid='$x->{fingerprint}' or uuid='$x->{caseuuid}' and expire>$time" ) };
        $acked = 1 if @$xx > 0;
    }

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@res, acked => $acked };
};

post '/monitor/ack/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
        ctrl => [ 'in', 'ack', 'ackcase' ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $uuid, $ctrl ) = @$param{qw( uuid ctrl )};

    my $time = time + 86400;
    eval{
        if( $ctrl eq 'ackcase' )
        {
            $api::mysql->execute( "insert into openc3_monitor_ack_active ( uuid,treeid,expire ) select `caseuuid`,treeid,'$time' from openc3_monitor_ack_table  where ackuuid='$uuid'" );
        }
        else
        {
            $api::mysql->execute( "insert into openc3_monitor_ack_active ( uuid,treeid,expire ) select `fingerprint`,treeid,'$time' from openc3_monitor_ack_table  where ackuuid='$uuid'" );
        }
    };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
