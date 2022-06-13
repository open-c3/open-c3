package api::monreport;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;
use File::Basename;
use Time::Local;

get '/monreport/:groupid/report' => sub {
    my $param = params();
    my $error = Format->new( 
        groupid => qr/^\d+$/, 1,
        data    => qr/^[a-zA-Z0-9_\.\-]*$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid} ); return $pmscheck if $pmscheck;

    my $selectdata = ( $param->{data} && $param->{data} =~ /^\d{4}-\d{2}$/ ) ? $param->{data} : POSIX::strftime( "%Y-%m", localtime );
    my $datafile = "/data/glusterfs/monreport/$selectdata";
    my @data = `cat $datafile`;
    chomp @data;
    my $datacount = scalar @data;

    my $updatetime = -f $datafile ? POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime( (stat $datafile)[9] ) ) : '';

    my ( %data, %severity, @detailtable, %pingtu1, %pingtu2, %pingtu3, %pingtu4 );

    for my $data ( @data )
    {
        my ( $time, $fromtreeid, $severity, $instance, $alertname ) = split /;/, $data, 5;
        $alertname   = Encode::decode('utf8', $alertname );
        my ( $date ) = split /\s+/, $time;

        push @detailtable, +{ time => $time, fromtreeid => $fromtreeid, severity => $severity, instance => $instance, alertname => $alertname };

        $data{$date}{$severity} ++;

        $severity{$severity} ++;

        $pingtu1{ $severity              } ++;
        $pingtu2{ $instance              } ++;
        $pingtu3{ $alertname             } ++;
        $pingtu4{ "$instance.$alertname" } ++;
    }
    
    my $top10 = sub{
        my %data = @_;
        if( keys %data > 10 )
        {
            my @sort = sort{ $data{$b} <=> $data{$a} }keys %data;
            my %save;   map{ $save{$_} ++ } @sort[0..9];
            for my $k ( keys %data )
            {
                next if $save{$k};
                $data{other} += delete $data{$k};
            }
        }
        return %data;
    };

    %pingtu2 = &$top10( %pingtu2 );
    %pingtu3 = &$top10( %pingtu3 );
    %pingtu4 = &$top10( %pingtu4 );
    my @pie1 = map{ [ $_, 0 + sprintf( "%0.2f", 100 * $pingtu1{$_} / $datacount) ] }keys %pingtu1;
    my @pie2 = map{ [ $_, 0 + sprintf( "%0.2f", 100 * $pingtu2{$_} / $datacount) ] }keys %pingtu2;
    my @pie3 = map{ [ $_, 0 + sprintf( "%0.2f", 100 * $pingtu3{$_} / $datacount) ] }keys %pingtu3;
    my @pie4 = map{ [ $_, 0 + sprintf( "%0.2f", 100 * $pingtu4{$_} / $datacount) ] }keys %pingtu4;
    
    my @datacol;
    my ( $year, $month ) = split /\-/, $selectdata;
    my $temptime = timelocal(0,0,0,1, $month-1, $year);
    map{
        my $d = POSIX::strftime( "%Y-%m-%d", localtime($temptime + ( 86400 * $_ )) );
        push @datacol, $d if $d =~ /^$selectdata/, 
    } 0 .. 31;

    my @change;
    for my $t ( @datacol )
    {
        push @change, [ $t, $data{$t}{level1} || 0, $data{$t}{level2} || 0, $data{$t}{level3} || 0,$data{$t}{level4} || 0 ];
    }

    my %re = (
        updatetime => $updatetime,

        count1 => $severity{level1} // 0,
        count2 => $severity{level2} // 0,
        count3 => $severity{level3} // 0,
        count4 => $severity{level4} // 0,

        change => \@change,

        pingtu1 => \@pie1,
        pingtu2 => \@pie2,
        pingtu3 => \@pie3,
        pingtu4 => \@pie4,

        detailtable => \@detailtable,
    );

    return +{ stat => $JSON::true, data => \%re };
};

get '/monreport/:groupid/datalist' => sub {
    my $param = params();
    my $error = Format->new( 
        groupid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid} ); return $pmscheck if $pmscheck;

    my @data = `cd /data/glusterfs/monreport && ls`;
    chomp @data;
    @data = reverse @data;
    return +{ stat => $JSON::true, data => [grep{/^20\d{2}\-\d{2}$/}@data] };
};

true;
