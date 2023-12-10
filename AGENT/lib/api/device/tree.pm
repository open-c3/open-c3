package api::device::tree;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON   qw();
use POSIX;
use api;
use OPENC3::Tree;

=pod

CMDB/资源绑定服务树/全量

=cut

any '/device/tree/bind/:type/:subtype/:uuid/:tree' => sub {
    my $param = params();
    my $error = Format->new(
        type       => qr/^[a-z\d\-_]+$/, 1,
        subtype    => qr/^[a-z\d\-_]+$/, 1,
        uuid       => qr/^[a-zA-Z\d\-_\.\:]+$/, 1,
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

=pod

CMDB/资源绑定服务树/增量/拷贝

=cut

any '/device/tree/copy/:type/:subtype/:uuid/:tree' => sub {
    my $param = params();
    my $error = Format->new(
        type       => qr/^[a-z\d\-_]+$/, 1,
        subtype    => qr/^[a-z\d\-_]+$/, 1,
        uuid       => qr/^[a-zA-Z\d\-_\.\:]+$/, 1,
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

    my $t = eval{ $api::mysql->query( "select tree from openc3_device_bindtree where type='$param->{type}' and subtype='$param->{subtype}' and uuid='$param->{uuid}'" )};
    return +{ stat => $JSON::false, info => "get treeinfo from db fail: $@" } if $@;

    my $oldtree = '';
    $oldtree = $t->[0][0] if $t && ref $t eq 'ARRAY' && @$t == 1;

    $param->{tree} = "$param->{tree},$oldtree" if length $oldtree > 0;

    $param->{tree} = OPENC3::Tree::compress( $param->{tree} );

    eval{
        $api::mysql->execute(
            sprintf "replace into openc3_device_bindtree(`type`,`subtype`,`uuid`,`tree`) values( '$param->{type}', '$param->{subtype}', '$param->{uuid}', '%s' )",
                $param->{tree} eq 'x' ? '' : $param->{tree}
        )
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } :  +{ stat => $JSON::true };
};

=pod

CMDB/资源绑定服务树/增量/移动

=cut

any '/device/tree/move/:type/:subtype/:uuid/:fromtree/:totree' => sub {
    my $param = params();
    my $error = Format->new(
        type       => qr/^[a-z\d\-_]+$/, 1,
        subtype    => qr/^[a-z\d\-_]+$/, 1,
        uuid       => qr/^[a-zA-Z\d\-_\.\:]+$/, 1,
        fromtree   => qr/^[a-zA-Z\d\-_\.]+$/, 1,
        totree     => qr/^[a-zA-Z\d\-_\.]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    for ( ( $param->{fromtree}, $param->{totree} ))
    {
         return  +{ stat => $JSON::false, info => "tree format errr" }
             unless ( $_ =~ /^[a-zA-Z][a-zA-Z0-9\-_\.]*[a-zA-Z0-9]$/ || $_ eq 'x' ) && $_ !~ /\.\./;
    }

    my $pmscheck = api::pmscheck( 'openc3_job_root' );
    return $pmscheck if $pmscheck;

    my $t = eval{ $api::mysql->query( "select tree from openc3_device_bindtree where type='$param->{type}' and subtype='$param->{subtype}' and uuid='$param->{uuid}'" )};
    return +{ stat => $JSON::false, info => "get treeinfo from db fail: $@" } if $@;

    my $oldtree = '';
    $oldtree = $t->[0][0] if $t && ref $t eq 'ARRAY' && @$t == 1;


    my %tree;
    if( length $oldtree > 0 )
    {
        %tree = map{ $_ => 1 }split /,/, $oldtree;
        if( delete $tree{$param->{fromtree}} )
        {
            $tree{$param->{totree}} = 1;
        }
        else
        {
            return +{ stat => $JSON::false, info => "nofind tree in db: $param->{fromtree}" };
        }
    }
    else
    {
        return +{ stat => $JSON::false, info => "nofind tree in db" };
    }

    my $newtree = OPENC3::Tree::compress( join ',', keys %tree );

    eval{
        $api::mysql->execute(
            sprintf "replace into openc3_device_bindtree(`type`,`subtype`,`uuid`,`tree`) values( '$param->{type}', '$param->{subtype}', '$param->{uuid}', '%s' )",
                $newtree eq 'x' ? '' : $newtree
        )
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } :  +{ stat => $JSON::true };
};

true;
