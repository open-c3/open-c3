package api::device::extcol;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON   qw();
use POSIX;
use api;

any '/device/extcol/:type/:subtype/:uuid/:name' => sub {
    my $param = params();
    my $error = Format->new(
        type       => qr/^[a-z\d\-_]+$/, 1,
        subtype    => qr/^[a-z\d\-_]+$/, 1,
        uuid       => qr/^[a-z\d\-_]+$/, 1,
        name       => qr/^[a-zA-Z\d\-_\.\,]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $data = $param->{data} // '';
    $data =~ s/'//g;
    $data =~ s/;//g;
    $data =~ s/\t//g;

    my $pmscheck = api::pmscheck( 'openc3_job_root' );
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
