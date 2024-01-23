package api::device::extcol;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON   qw();
use POSIX;
use api;

=pod

CMDB/获取扩增字段

=cut

get '/device/extcol/:type/:subtype/:uuid/:name' => sub {
    my $param = params();
    my $error = Format->new(
        type       => qr/^[a-z\d\-_]+$/, 1,
        subtype    => qr/^[a-z\d\-_]+$/, 1,
        uuid       => qr/^[a-zA-Z\d\-_\.:]+$/,   1,
        name       => qr/^[a-zA-Z\d\-_\.\,]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read' );
    return $pmscheck if $pmscheck;

    my $r = eval{ $api::mysql->query( "select data from openc3_device_extcol where type='$param->{type}' and subtype='$param->{subtype}' and uuid='$param->{uuid}' and name='$param->{name}'" )};

    return $@ ? +{ stat => $JSON::false, info => $@ } :  +{ stat => $JSON::true, data => @$r ? $r->[0][0] : "" };
};

=pod

CMDB/编辑扩增字段

=cut

post '/device/extcol/:type/:subtype/:uuid/:name' => sub {
    my $param = params();
    my $error = Format->new(
        type       => qr/^[a-z\d\-_]+$/, 1,
        subtype    => qr/^[a-z\d\-_]+$/, 1,
        uuid       => qr/^[a-zA-Z\d\-_\.:]+$/,   1,
        name       => qr/^[a-zA-Z\d\-_\.\,]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $data = $param->{data} // '';
    $data =~ s/'//g;
    $data =~ s/;//g;
    $data =~ s/\t//g;
    $data =~ s/\n//g;

    my $pmscheck = api::pmscheck( 'openc3_job_control', $param->{treeid} && $param->{treeid} =~ /^\d+$/ ? $param->{treeid} : 0 );
    return $pmscheck if $pmscheck;

    eval{
        $api::mysql->execute(
            sprintf "replace into openc3_device_extcol(`type`,`subtype`,`uuid`,`name`,`data`) values( '$param->{type}', '$param->{subtype}', '$param->{uuid}', '%s', '%s' )",
                $param->{name} , $data
        )
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } :  +{ stat => $JSON::true };
};

true;
