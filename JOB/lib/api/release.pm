package api::release;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;

=pod

查询服务树节点是否可以释放

=cut

get '/release' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d[\d,]*$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my @id = split /,/, $param->{id};

    my $r = eval{ 
        $api::mysql->query( 
            sprintf "select count(*) from openc3_job_crontab where status='available' and jobuuid in ( select uuid from openc3_job_jobs where projectid in ( %s ) )", join ',', @id
            )};

    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::false, info => $@ } unless $r && ref $r eq 'ARRAY' && @$r > 0;
    return $r->[0][0] ? 'false' : 'true';
};

true;
