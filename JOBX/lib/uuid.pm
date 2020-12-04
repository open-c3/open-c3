package uuid;

use warnings;
use strict;

sub new
{
    my ( $class, %this ) = @_;

    $this{chars} ||= [ "A" .. "Z", "a" .. "z", 0 .. 9 ];
    $this{end} ||= [ "a" .. "z" ];
    $this{length} ||= 12;
    bless \%this, ref $class || $class;
}

sub create_str
{
    my $this = shift;

    my ( $chars, $end, $length ) = @$this{qw( chars end length )};
    join("", @$chars[ map { rand @$chars } ( 1 .. $length - 1 ) ]).$end->[rand @$end];
}

sub get_rollback_uuid
{
    my $uuid = shift;
    $uuid =~ s/\w$/\U$&/;
    return $uuid;
}

sub get_deploy_uuid
{
    my $uuid = shift;
    $uuid =~ s/\w$/\L$&/;
    return $uuid;
}

sub get_role
{
    my $uuid = shift;
    return $uuid =~ /[a-z]$/ ? 'deploy' : 'rollback';
}

1;
