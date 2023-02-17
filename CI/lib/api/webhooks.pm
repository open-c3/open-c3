package api::dockershell;
use FindBin qw( $RealBin );
use Dancer ':syntax';
use JSON qw();
use POSIX;
use YAML::XS;
use FindBin qw( $RealBin );
use Time::HiRes qw( gettimeofday );
use Data::Dumper;
use File::Basename;
use Digest::MD5;
set serializer => 'JSON';
our $VERSION = '0.1';
use Logs;

=pod

流水线/webhook

git的回调地址

=cut

any '/webhooks' => sub {
    my $logs = Logs->new( 'webhooks' );
    my %param = request->params;

    my $uuid = $param{checkout_sha} || $param{before};
    my $look = Dumper request;
    return "checkout_sha $look" unless $uuid && $uuid =~ /^[a-z0-9]{40}$/;

    map{ return "no $_" unless $param{$_} && $param{$_} =~ /^[a-z0-9]{40}$/  }qw( before after );

    $uuid.='_1' if $param{before} =~ /^0{40}$/;
    $uuid.='_0' if $param{after} =~ /^0{40}$/;
    $param{TOKEN} = request->env->{HTTP_X_GITLAB_TOKEN};

    my $file = "$RealBin/../logs/webhooks_data/$uuid";

    YAML::XS::DumpFile $file, \%param;

    system "flock -w 1 -x /tmp/$uuid $RealBin/../bin/webhooks -u $uuid 1>/$RealBin/../logs/webhooks_logs/$uuid 2>&1";
};

true;
