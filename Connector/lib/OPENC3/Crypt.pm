package OPENC3::Crypt;
use warnings;
use strict;

use OPENC3::SysCtl;
use Crypt::RC4::XS;

sub _rc4_encrypt_hex ($$) {
    my ($key, $data) = ($_[0], $_[1]);
    return join('',unpack('H*',RC4($key, $data)));
}

sub _rc4_decrypt_hex ($$) {
    my ($key, $data) = ($_[0], $_[1]);
    return RC4($key, pack('H*',$data));
}

sub new
{
    my ( $class, %this ) = @_;
    $this{passwd} = OPENC3::SysCtl->new()->get( 'sys.base.crypt.passwd' );
    bless \%this, ref $class || $class;
}

sub encode
{
    my ( $this, $mesg ) = @_;
    return $this->{passwd} ? _rc4_encrypt_hex( $this->{passwd}, $mesg ) : $mesg;
}

sub decode
{
    my ( $this, $mesg ) = @_;
    return $this->{passwd} ? _rc4_decrypt_hex( $this->{passwd}, $mesg ) : $mesg;
}

1;
