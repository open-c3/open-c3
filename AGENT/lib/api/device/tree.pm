package api::device::tree;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON   qw();
use POSIX;
use api;

my $datapath = '/data/open-c3-data/device/curr';

any '/device/tree/bind/:type/:subtype/:uuid/:tree' => sub {
    my $param = params();
    my $error = Format->new(
        type       => qr/^[a-z\d\-_]+$/, 1,
        subtype    => qr/^[a-z\d\-_]+$/, 1,
        uuid       => qr/^[a-z\d\-_]+$/, 1,
        tree       => qr/^[a-zA-Z][a-z\d\-_\.\,]*$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_root' );
    return $pmscheck if $pmscheck;

    my $file = "$datapath/$param->{type}/$param->{subtype}/treeow.txt";

    my $tree = $param->{tree} eq 'x' ? '' : $param->{tree};
    system "echo '$param->{uuid}:$tree' >> $file";
    return +{ stat => $JSON::true };
};

true;
