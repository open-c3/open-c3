package api::c3mc;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use POSIX;
use Format;
use Time::Local;
use File::Temp;
use Digest::MD5;

our %handle;
$handle{c3mcshowinfo} = sub { return +{ info => shift, stat => shift ? $JSON::false : $JSON::true }; };
$handle{c3mcshowdata} = sub { return +{ data => shift, stat => shift ? $JSON::false : $JSON::true }; };

true;
