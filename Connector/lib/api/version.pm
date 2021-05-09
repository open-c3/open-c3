package api::version;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use utf8;
use Tie::File;
use Fcntl 'O_RDONLY';

get '/version/log' => sub {
    my $param = params();

    return +{ stat => $JSON::false, info => "tie fail: $!" }
        unless tie my @cont, 'Tie::File', "$RealBin/../.versionlog", mode => O_RDONLY, discipline => ':encoding(utf8)';

    my @temp = @cont[0.. ( $#cont >= 99 ? 99 : $#cont ) ];
    return +{ stat => $JSON::true, data => [ map{ my @x = split / \+0800 - /, $_; +{ time => $x[0], mesg => $x[1] } }@temp ] };
};

get '/version/name' => sub {
    my $version = `cat '$RealBin/../.versionname'`;
    chomp $version;
    return +{ stat => $JSON::true, data => $version || 'unkown' };
};

true;
