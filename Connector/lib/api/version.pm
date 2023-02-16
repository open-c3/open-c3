package api::version;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use utf8;
use Tie::File;
use Fcntl 'O_RDONLY';

=pod

系统版本/获取更新内容

=cut

get '/version/log' => sub {
    my $param = params();

    return +{ stat => $JSON::false, info => "tie fail: $!" }
        unless tie my @cont, 'Tie::File', "$RealBin/../.versionlog", mode => O_RDONLY, discipline => ':encoding(utf8)';

    my @temp = @cont[0.. ( $#cont >= 99 ? 99 : $#cont ) ];
    return +{ stat => $JSON::true, data => [ map{ my @x = split / \+0800 - /, $_; +{ time => $x[0], mesg => $x[1] } }@temp ] };
};

=pod

系统版本/获取当前版本号

=cut

get '/version/name' => sub {
    my %version;
    for my $x ( qw( name uuid time ) )
    {
        my    $xx = `cat '$RealBin/../.version$x'`;
        chomp $xx;
        $version{ $x } = $xx || 'unkown';
    }

    return +{ stat => $JSON::true, data => \%version };
};

true;
