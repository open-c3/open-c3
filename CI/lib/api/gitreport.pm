package api::gitreport;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use JSON;
use POSIX;
use MIME::Base64;
use api;
use Format;
use File::Basename;
use Time::Local;

get '/gitreport/:groupid/report' => sub {
    my $param = params();
    my $error = Format->new( 
        groupid => qr/^\d+$/, 1,
        user => qr/^[\w@\.]*$/, 0,
        data => qr/^[a-zA-Z0-9_\.\-]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid} ); return $pmscheck if $pmscheck;

    my $groupid = $param->{groupid};

    my $path = "/data/glusterfs/gitreport";
    system "mkdir -p $path" unless -d $path;

    my @data = `cat $path/$groupid/$param->{data}`;
    chomp @data;

    my $updatetime = '';
    if( -f "$path/$groupid/current" )
    {
        $updatetime = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime( (stat "$path/$groupid/current")[9] ) );
    }

    my $record = @data ? 0 : 1;
    my ( $usercount, $addcount, $delcount, $commitcount, %data, %data2, %user, %userchange, %userchange2 ) = ( 0, 0, 0, 0 );

    my @detailtable;
    for my $data ( @data )
    {
        my ( $time, $uuid, $effective, $name, $add, $del, $url ) = split /:/, $data, 7;
        my ( $date ) = split /\./, $time;

        $user{$name} ++;
        next if $param->{user} && $param->{user} ne $name;

        push @detailtable, +{ time => $time, uuid => $uuid, effective => $effective, user => $name, add => $add, del => $del, url => $url };
        next if $effective eq 'No';

        $addcount += $add;
        $delcount += $del;
        $commitcount ++;
        $userchange{$name} ++;
        $userchange2{$name} += $add;
        $userchange2{$name} += $del;

        $data{$date}{add} += $add;
        $data{$date}{del} += $del;

        $time =~ /^\d+\-\d+\-\d+\.(\d{2})/;
        my $hour = $1;
        $data2{$hour}{add} += $add;
        $data2{$hour}{del} += $del;
    }
    
    my ( @change, @change2 );
    my $allchange = $addcount + $delcount;

    my @pie;
    for my $u ( keys %userchange)
    {
        push @pie, [ $u, 0 + sprintf( "%0.2f", 100 * $userchange{$u} / $commitcount) ];
    }

    my @pie2;
    for my $u ( keys %userchange2 )
    {
        push @pie2, [ $u, 0 + sprintf( "%0.2f", 100 * $userchange2{$u} / $allchange) ];
    }
    
    my @datacol;
    if( $param->{data} =~ /^(.+)\.month$/ )
    {
        my $m = $1;
        my ( $year, $month, $day ) = split /\-/, $m;
        my $temptime = timelocal(0,0,0,1, $month-1, $year);
        map{
            my $d = POSIX::strftime( "%Y-%m-%d", localtime($temptime + ( 86400 * $_ )) );
            push @datacol, $d if $d =~ /^$m/, 
        } 0 .. 31
    }
    else
    {
        my $datadate = ( $param->{data} =~ /^(.+)\.week$/ ) ? $1 : POSIX::strftime( "%Y-%m-%d", localtime(time -  86400) );
        my ( $year, $month, $day ) = split /\-/, $datadate;

        my $temptime = timelocal(0,0,0,$day, $month-1, $year);

        map{
            push @datacol, POSIX::strftime( "%Y-%m-%d", localtime($temptime - ( 86400 * $_ )) ) ;
        } 0 .. 6;
        @datacol = reverse @datacol;
    }

    for my $t ( @datacol )
    {
        push @change, [ $t, $data{$t}{add} || 0, $data{$t}{del} || 0 ];
    }

    for my $t ( 0 .. 23 )
    {
        $t = "0$t" if $t < 10;
        push @change2, [ $t, $data2{$t}{add} || 0, $data2{$t}{del} || 0 ];
    }

    my %re = (
        change => \@change,
        change2 => \@change2,
        usercount => scalar( keys %user ),
        addcount => $addcount,
        delcount => $delcount,
        commitcount => $commitcount,
        pingtu => \@pie,
        pingtu2 => \@pie2,
        detailtable => \@detailtable,
        userlist => [ sort{ $user{$b} <=> $user{$a} }keys %user ],
        updatetime => $updatetime,
    );

    return +{ stat => $JSON::true, data => \%re };
};

get '/gitreport/:groupid/datalist' => sub {
    my $param = params();
    my $error = Format->new( 
        groupid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid} ); return $pmscheck if $pmscheck;

    my @data = sort{ $b cmp $a }map{ basename $_ }glob "/data/glusterfs/gitreport/$param->{groupid}/*";
    return +{ stat => $JSON::true, data => \@data };
};

true;
