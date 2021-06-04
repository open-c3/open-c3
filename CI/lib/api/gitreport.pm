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
    my ( $usercount, $addcount, $delcount, $commitcount, %data, %user, %userchange, %userchange2 ) = ( 0, 0, 0, 0 );

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
    }
    
    my @change;
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

    map{
        my $t = POSIX::strftime( "%Y-%m-%d", localtime( time - 86400 * ( 90 - $_ ) ) );
        if( ( ! $data{$t}{add} ) && ! ( $data{$t}{add} ) )
        {
            push @change, [ $t, 0, 0 ] if $record;
        }
        else
        {
            push @change, [ $t, $data{$t}{add} || 0, $data{$t}{del} || 0 ];
            $record = 1;
        }
    } 1 .. 90;

    my %re = (
        change => \@change,
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
