package MYDB;

use warnings;
use strict;

use DBI;
use Dancer::Plugin::Database::Core;
use YAML::XS;

our %DEFAULT = 
(
    driver => 'mysql',
    host => '127.0.0.1',
    port => 3306,
    connection_check_threshold => 30,
    dbi_params => {
        mysql_enable_utf8 => 1,
        RaiseError => 0,
        AutoCommit => 1,
        on_connect_do => ["SET NAMES 'utf8'", "SET CHARACTER SET 'utf8'" ]
    },
    log_queries => 0
);


sub new
{
    my ($class, $conf, %this ) = splice @_, 0, 2;

    eval{$conf = YAML::XS::LoadFile $conf};
    die "MYDB load conf fail:$@" if $@;
    die "conf no HASH" unless ref $conf eq 'HASH';
 
    $this{dbh} = Dancer::Plugin::Database::Core::_get_connection( { %DEFAULT, %$conf  },sub{},sub{} );
    bless \%this, ref $class || $class;
}

sub query
{
    my ( $this, $sql, $col ) = @_;

    my $sth = $this->{dbh}->prepare( $sql );
    $sth->execute();
    my $r = $sth->fetchall_arrayref;

    return $r unless $col;

    my $re = [];
    for my $x ( @$r )
    {
        push @$re, +{ map{ $col->[$_] => $x->[$_] }0..@$col-1}
    }
    return $re;

}

sub execute
{
    my $this = shift;
    my $sth = $this->{dbh}->prepare( shift );
    $sth->execute();
}

1;
