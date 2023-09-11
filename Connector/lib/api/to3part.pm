package api::to3part;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Code;
use Format;

my %key;
BEGIN{
    my $f = '/data/open-c3-data/to3part.yml';
    if( -f $f )
    {
        my $c = eval{ YAML::XS::LoadFile $f };
        warn "load $f err: $@" if $@;
        %key = %$c if $c && ref $c eq 'HASH';
    }

    $key{jobx} = $ENV{OPEN_C3_RANDOM} if $ENV{OPEN_C3_RANDOM};
};

=pod

第三方接口/获取用户部门信息

=cut

get '/to3part/v1/user/department' => sub {
    my $param = params();
    my $error = Format->new(
        email => qr/^[a-zA-Z0-9\.\-_@]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error", code => 1, msg => "check format fail $error" } if $error;

    my ( $appkey, $appname ) = map{ request->headers->{$_} }qw( appkey appname );

    return  +{ stat => $JSON::false, info => "key err", code => 1, msg => "key err" } unless $appkey && $appname && $key{$appname} && $key{$appname} eq $appkey;

    my $x = `c3mc-base-userinfo --user '$param->{email}'`;
    return  +{ stat => $JSON::false, info => "get userinfo fail", code => 1, msg => "get userinfo fail" } if $?;

    my $info = eval{ YAML::XS::Load $x };
    return  +{ stat => $JSON::false, info => "get userinfo error: $@", code => 1, msg => "get userinfo error:$@" } if $@;
    
    my %data = map{ $_ => "" }qw( sybLeaderId oneLeaderId twoLeaderId );
    map{ $data{$_} = $info->{$_} // "" } qw( accountId accountName mobile sybDeptName oneDeptName twoDeptName );

    my @leader = `c3mc-base-userleader --user '$param->{email}'`;
    chomp @leader;

#    $data{ twoLeaderId } = $leader[0] if @leader >= 1;
#    $data{ oneLeaderId } = $leader[1] if @leader >= 2;
#    $data{ sybLeaderId } = $leader[2] if @leader >= 3;

    $data{ sybLeaderId } = $data{ oneLeaderId } = $data{ twoLeaderId } = $leader[0] if @leader >= 1;

    return $@ ? +{ stat => $JSON::false, info => $@, code => 1, msg => $@ } :  +{ stat => $JSON::true, data => \%data, code => 0, msg => 'ok' };
};

=pod

第三方接口/获取用户信息

=cut

get '/to3part/v1/user/userinfo' => sub {
    my $co = request->headers->{token};

    my ( $user, $company, $admin, $showconnector )= eval{ $api::sso->run( cookie => $co ) };
    return( +{ stat => $JSON::false, info => "sso code error:$@" } ) if $@;
    return( +{ stat => $JSON::false, code => 10000 } ) unless $user;
    my $name = $user;
    $name =~ s/@.*//;

    return +{ name => uc( $name ), email => $user, company => $company, admin => $admin, showconnector => $showconnector };
};

true;
