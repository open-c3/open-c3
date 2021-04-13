package api::sendfile;
use Dancer ':syntax';
use JSON;
use api;
use Format;
use Util;
use Encode;
use Util;

#path
get '/sendfile/list/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        path => qr/^[a-zA-Z0-9:_\/ @\.]+$/, 1,
        sudo => qr/^[a-zA-Z0-9:_\/@\.]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;
    my ( $host, $path ) = split /\//, $param->{path}, 2;

    my %env = Util::envinfo( qw( appname appkey ) );

    my @x = `MYDan_Agent_Proxy_Addr=http://api.agent.open-c3.org/proxy/$param->{projectid} MYDan_Agent_Proxy_Header="appname:$env{appname},appkey:$env{appkey}" /data/Software/mydan/dan/tools/rcall --sudo '$param->{sudo}' -r '$host' exec 'ls -l "/$path"' --verbose`;
    chomp @x;
    my %type = ( d => 'dir', l => 'link', '-' => 'file', host => 'default' );

    my @data = ( +{ type => 'parent', info => '..', path => '..' } );
    map{
        Encode::_utf8_on($_);
        $_ =~ s/^([^:]+)://;
        my %x = ( info => $_ );
        my $host = $1;  
        $x{host} = $host;
        $_ =~ /^([\w\-])/;
        $x{type} = $type{$1} || 'other';
        my @p = split /\s+/, $_;
        $x{path} = pop @p;
        push @data, \%x;
    }@x;

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@data };
};

true;
