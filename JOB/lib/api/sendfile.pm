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
        path => qr/^[a-zA-Z0-9:_\/ @\.\-]+$/, 1,
        sudo => qr/^[a-zA-Z0-9:_\/@\.\-]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;
    my ( $host, $path ) = split /\//, $param->{path}, 2;

    my %env = Util::envinfo( qw( appname appkey ) );

    my @x = `MYDan_Agent_Proxy_Addr=http://api.agent.open-c3.org/proxy/$param->{projectid} MYDan_Agent_Proxy_Header="appname:$env{appname},appkey:$env{appkey}" /data/Software/mydan/dan/tools/rcall --sudo '$param->{sudo}' -r '$host' exec 'ls -lh "/$path"' --verbose`;
    chomp @x;
    my %type = ( d => 'dir', l => 'link', '-' => 'file' );

    my @data = ( +{ type => 'parent', info => '..', path => '..' } );
    map{
        Encode::_utf8_on($_);
        $_ =~ s/^([^:]+)://;
        my %x = ( info => $_ );
        my $host = $1;  
        $x{host} = $host;
        $_ =~ /^([\w\-])/;
        $x{type} = $type{$1} || 'other';
        my @p = split /\s+/, $_, 9;
        $x{path} = $type{$1} ? pop @p : '';
        push @data, \%x;
    }@x;

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@data };
};

post '/sendfile/unlink/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        path => qr/^[a-zA-Z0-9:_\/ @\.\-\(\)]+$/, 1,
        sudo => qr/^[a-zA-Z0-9:_\/@\.\-]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;
    my ( $host, $path ) = split /\//, $param->{path}, 2;

    my %env = Util::envinfo( qw( appname appkey ) );

    my @x = `MYDan_Agent_Proxy_Addr=http://api.agent.open-c3.org/proxy/$param->{projectid} MYDan_Agent_Proxy_Header="appname:$env{appname},appkey:$env{appkey}" /data/Software/mydan/dan/tools/rcall --sudo '$param->{sudo}' -r '$host' exec 'rm "/$path"' --verbose 2>&1`;
    chomp @x;
    my $x = join '', @x;

    return $x ? +{ stat => $JSON::false, info => $x } : +{ stat => $JSON::true, info => 'ok' };
};

true;
