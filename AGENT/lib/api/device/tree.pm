package api::device::tree;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON   qw();
use POSIX;
use api;
use OPENC3::Tree;

=pod

CMDB/资源绑定服务树

=cut

any '/device/tree/bind/:type/:subtype/:uuid/:tree' => sub {
    my $param = params();
    my $error = Format->new(
        type       => qr/^[a-z\d\-_]+$/, 1,
        subtype    => qr/^[a-z\d\-_]+$/, 1,
        uuid       => qr/^[a-z\d\-_\.\:]+$/, 1,
        tree       => qr/^[a-zA-Z\d\-_\.\,]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    for ( split /,/, $param->{tree} )
    {
         return  +{ stat => $JSON::false, info => "tree format errr" }
             unless ( $_ =~ /^[a-zA-Z][a-zA-Z0-9\-_\.]*[a-zA-Z0-9]$/ || $_ eq 'x' ) && $_ !~ /\.\./;
    }

    my $pmscheck = api::pmscheck( 'openc3_job_root' );
    return $pmscheck if $pmscheck;

    $param->{tree} = OPENC3::Tree::compress( $param->{tree} );

    eval{
        $api::mysql->execute(
            sprintf "replace into openc3_device_bindtree(`type`,`subtype`,`uuid`,`tree`) values( '$param->{type}', '$param->{subtype}', '$param->{uuid}', '%s' )",
                $param->{tree} eq 'x' ? '' : $param->{tree}
        )
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } :  +{ stat => $JSON::true };
};

true;
