package api::flowreport;
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

get '/flowreport/:groupid/report' => sub {
    my $param = params();
    my $error = Format->new( 
        groupid => qr/^\d+$/, 1,
        user => qr/^[\w@\.]*$/, 0,
        data => qr/^[a-zA-Z0-9_\.\-]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid} ); return $pmscheck if $pmscheck;

    my $groupid = $param->{groupid};

    my $path = "/data/glusterfs/flowreport";
    system "mkdir -p $path" unless -d $path;

    my @data = `cat $path/$groupid/$param->{data}`;
    chomp @data;

    my $updatetime = '';
    if( -f "$path/$groupid/current" )
    {
        $updatetime = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime( (stat "$path/$groupid/current")[9] ) );
    }

    my $record = @data ? 0 : 1;
    my ( $cicount, $testcount, $deploycount, $rollbackcount, %data, %user, %userchange, %userchange2 ) = ( 0, 0, 0, 0 );

    my @detailtable;
    for my $data ( @data )
    {
        my ( $time, $type, $uuid, $groupid, $projectid, $status, $version ) = split /:/, $data;
        my ( $date ) = split /\./, $time;

        if( $type eq "ci" )
        {
            $cicount ++;
            $data{$date}{ci} ++;
        }
        if( $type eq "test" )
        {
            $testcount ++;
            $data{$date}{test} ++;
        }
        if( $type eq "deploy" )
        {
            $deploycount ++;
            $data{$date}{deploy} ++;
        }

        if( $type eq "rollback" )
        {
            $rollbackcount ++;
            $data{$date}{rollback} ++;
        }

        push @detailtable, +{ time => $time, type => $type, uuid => $uuid, groupid => $groupid, projectid => $projectid, status => $status, version => $version };
    }
    
    my @change;
   
    my $datadate = ( $param->{data} =~ /^(.+)\.week$/ ) ? $1 : POSIX::strftime( "%Y-%m-%d", localtime(time -  86400) );
    my ( $year, $month, $day ) = split /\-/, $datadate;

    my $temptime = timelocal(0,0,0,$day, $month-1, $year);

    my @datacol;
    map{
        push @datacol, POSIX::strftime( "%Y-%m-%d", localtime($temptime - ( 86400 * $_ )) ) ;
    } 0 .. 6;

    for my $t ( reverse @datacol )
    {
        push @change, [ $t, $data{$t}{ci}||0, $data{$t}{test} || 0, $data{$t}{deploy} || 0, $data{$t}{rollback} || 0 ];
    }

    my %re = (
        change => \@change,
        cicount => $cicount,
        deploycount => $deploycount,
        testcount => $testcount,
        rollbackcount => $rollbackcount,
        detailtable => \@detailtable,
        userlist => [],
        updatetime => $updatetime,
    );

    return +{ stat => $JSON::true, data => \%re };
};

get '/flowreport/:groupid/datalist' => sub {
    my $param = params();
    my $error = Format->new( 
        groupid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid} ); return $pmscheck if $pmscheck;

    my @data = sort{ $b cmp $a }map{ basename $_ }glob "/data/glusterfs/flowreport/$param->{groupid}/*";
    return +{ stat => $JSON::true, data => \@data };
};

true;
