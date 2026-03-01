package api::treeattr;
use Dancer ':syntax';
use Dancer qw(cookie);
use JSON qw();
use POSIX;
use api;
use uuid;
use Format;

=pod

服务树属性/获取服务树属性

=cut

get '/treeattr/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_connector_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @x = `c3mc-base-tree-attr --treeid '$param->{projectid}'`;
    chomp @x;

    my %r = map{ $_ => 'unkown' }qw( name productowner opsowner );
    for( @x )
    {
        my ( $name, $value ) = split /;/, $_, 2;
	$r{$name} = Encode::decode('utf8', $value );
    }

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \%r };
};

=pod

服务树属性/更新服务树属性

=cut

post '/treeattr/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name      => qr/^[a-zA-Z][a-zA-Z0-9_\-]*[a-zA-Z0-9]$/, 1,
	value => [ 'mismatch', qr/'/ ], 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_connector_write', $param->{projectid} ); return $pmscheck if $pmscheck;
    $param->{value} //= "";

    eval{ $api::mysql->execute( "replace into openc3_connector_tree_attr (`treeid`,`name`,`value`) values('$param->{projectid}', '$param->{name}','$param->{value}')" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
