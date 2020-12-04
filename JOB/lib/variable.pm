package variable;

use warnings;
use strict;

use DBI;
use Dancer::Plugin::Database::Core;
use YAML::XS;

our %DATA; 

sub new
{
    my ( $class, %this ) = @_;

    die "db undef" unless $this{db};

    bless \%this, ref $class || $class;
}

sub relpace
{
    my ( $this, $var ) = @_;
    my ( $variable, $db, $jobuuid ) = @$this{qw( variable db jobuuid )};

    my ( @x, @fail );
    return $var unless defined $var && $var =~ /\$/;

    if( $variable && ref $variable eq 'HASH' )
    {
        return $var unless @x = (( $var =~/\$\{([a-zA-Z][a-zA-Z0-9_]+)\}/g ), ($var =~ /\$([a-zA-Z][a-zA-Z0-9_]+)\b/g ));

        for( @x )
        {
            next unless defined $variable->{$_} && $variable->{$_} ne '';
            $var =~ s/\$$_\b/$variable->{$_}/g;
            $var =~ s/\$\{$_\}/$variable->{$_}/g;
        }
    }

    return $var unless @x = (( $var =~/\$\{([a-zA-Z][a-zA-Z0-9_]+)\}/g ), ($var =~ /\$([a-zA-Z][a-zA-Z0-9_]+)\b/g ));

    die( sprintf "variable undef:%s", join ',',@x ) unless $jobuuid;

    unless( defined $DATA{$jobuuid} )
    {
		my $x = eval{ $db->query( "select name,value from variable  where jobuuid='$jobuuid'" );};
        die( "get variable fail:$@" ) if $@;
        die( "get variable fail" ) unless defined $x && ref $x eq 'ARRAY';
		$DATA{$jobuuid} = +{ map{ $_->[0] => $_->[1] }@$x };
    }

    my %x = %{$DATA{$jobuuid}};

    for( @x )
    {
        next unless defined $x{$_} && $x{$_} ne '';
        $var =~ s/\$$_\b/$x{$_}/g;
        $var =~ s/\$\{$_\}/$x{$_}/g;
    }

    return $var unless @x = (( $var =~/\$\{([a-zA-Z][a-zA-Z0-9_]+)\}/g ), ($var =~ /\$([a-zA-Z][a-zA-Z0-9_]+)\b/g ));
    die( sprintf "variable undef:%s", join ',',@x );

    return $var;
}

sub wk
{
    my ( $this, $projectid ) = @_;
    my ( $variable, $db, $jobuuid ) = @$this{qw( variable db jobuuid )};

    if( $jobuuid && ! defined $DATA{$jobuuid} )
    {
        my $x = eval{ $db->query( "select name,value from variable  where jobuuid='$jobuuid'" );};
        die( "get variable fail:$@" ) if $@;
        die( "get variable fail" ) unless defined $x && ref $x eq 'ARRAY';
	$DATA{$jobuuid} = +{ map{ $_->[0] => $_->[1] }@$x };
    }

    my ( %x, %var, @fail );
    %x = %{$DATA{$jobuuid}} if $jobuuid && $DATA{$jobuuid};
    map{ delete $x{$_} if $_ !~ /^wk_/ }keys %x;

    %var = %$variable if $variable && ref $variable eq 'HASH';
    for my $k ( keys %x )
    {
	if( defined $var{$k} && $var{$k} ne '' )
	{
            $x{$k} = $var{$k};
        }
        
        push( @fail, $k ) unless defined $x{$k} && $x{$k} ne '';
    }

    die( sprintf "variable wk undef:%s", join ',',@fail ) if @fail;
    $x{wk_treeid} = $projectid;
    return \%x;
}

sub get
{
    my ( $this, $var ) = @_;
    my ( $variable, $db, $jobuuid ) = @$this{qw( variable db jobuuid )};

    return undef unless defined $var;
    return $variable->{$var} if $variable && ref $variable eq 'HASH' && defined $variable->{$var};

    return undef unless defined $jobuuid;

    unless( defined $DATA{$jobuuid} )
    {
		my $x = eval{ $db->query( "select name,value from variable  where jobuuid='$jobuuid'" );};
        die( "get variable fail:$@" ) if $@;
        die( "get variable fail" ) unless defined $x && ref $x eq 'ARRAY';
		$DATA{$jobuuid} = +{ map{ $_->[0] => $_->[1] }@$x };
    }

    my %x = %{$DATA{$jobuuid}};

    return defined $x{$var} ? $x{$var} : undef;
}


1;
