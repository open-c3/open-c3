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

系统内置/判断服务树是否能释放/CI相关

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
            sprintf "select status from openc3_ci_project where id in ( %s )", join ',', @id
            )};

    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::false, info => $@ } unless $r && ref $r eq 'ARRAY';
    return 'true' unless @$r > 0;
    return $r->[0][0] ? 'false' : 'true';
};

true;
