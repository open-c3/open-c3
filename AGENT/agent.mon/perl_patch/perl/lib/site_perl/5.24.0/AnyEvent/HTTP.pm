=head1 NAME

AnyEvent::HTTP - simple but non-blocking HTTP/HTTPS client

=head1 SYNOPSIS

   use AnyEvent::HTTP;

   http_get "http://www.nethype.de/", sub { print $_[1] };

   # ... do something else here

=head1 DESCRIPTION

This module is an L<AnyEvent> user, you need to make sure that you use and
run a supported event loop.

This module implements a simple, stateless and non-blocking HTTP
client. It supports GET, POST and other request methods, cookies and more,
all on a very low level. It can follow redirects, supports proxies, and
automatically limits the number of connections to the values specified in
the RFC.

It should generally be a "good client" that is enough for most HTTP
tasks. Simple tasks should be simple, but complex tasks should still be
possible as the user retains control over request and response headers.

The caller is responsible for authentication management, cookies (if
the simplistic implementation in this module doesn't suffice), referer
and other high-level protocol details for which this module offers only
limited support.

=head2 METHODS

=over 4

=cut

package AnyEvent::HTTP;

use common::sense;

use Errno ();

use AnyEvent 5.0 ();
use AnyEvent::Util ();
use AnyEvent::Handle ();

use base Exporter::;

our $VERSION = 2.25;

our @EXPORT = qw(http_get http_post http_head http_request);

our $USERAGENT          = "Mozilla/5.0 (compatible; U; AnyEvent-HTTP/$VERSION; +http://software.schmorp.de/pkg/AnyEvent)";
our $MAX_RECURSE        =  10;
our $PERSISTENT_TIMEOUT =   3;
our $TIMEOUT            = 300;
our $MAX_PER_HOST       =   4; # changing this is evil

our $PROXY;
our $ACTIVE = 0;

my %KA_CACHE; # indexed by uhost currently, points to [$handle...] array
my %CO_SLOT;  # number of open connections, and wait queue, per host

=item http_get $url, key => value..., $cb->($data, $headers)

Executes an HTTP-GET request. See the http_request function for details on
additional parameters and the return value.

=item http_head $url, key => value..., $cb->($data, $headers)

Executes an HTTP-HEAD request. See the http_request function for details
on additional parameters and the return value.

=item http_post $url, $body, key => value..., $cb->($data, $headers)

Executes an HTTP-POST request with a request body of C<$body>. See the
http_request function for details on additional parameters and the return
value.

=item http_request $method => $url, key => value..., $cb->($data, $headers)

Executes a HTTP request of type C<$method> (e.g. C<GET>, C<POST>). The URL
must be an absolute http or https URL.

When called in void context, nothing is returned. In other contexts,
C<http_request> returns a "cancellation guard" - you have to keep the
object at least alive until the callback get called. If the object gets
destroyed before the callback is called, the request will be cancelled.

The callback will be called with the response body data as first argument
(or C<undef> if an error occurred), and a hash-ref with response headers
(and trailers) as second argument.

All the headers in that hash are lowercased. In addition to the response
headers, the "pseudo-headers" (uppercase to avoid clashing with possible
response headers) C<HTTPVersion>, C<Status> and C<Reason> contain the
three parts of the HTTP Status-Line of the same name. If an error occurs
during the body phase of a request, then the original C<Status> and
C<Reason> values from the header are available as C<OrigStatus> and
C<OrigReason>.

The pseudo-header C<URL> contains the actual URL (which can differ from
the requested URL when following redirects - for example, you might get
an error that your URL scheme is not supported even though your URL is a
valid http URL because it redirected to an ftp URL, in which case you can
look at the URL pseudo header).

The pseudo-header C<Redirect> only exists when the request was a result
of an internal redirect. In that case it is an array reference with
the C<($data, $headers)> from the redirect response. Note that this
response could in turn be the result of a redirect itself, and C<<
$headers->{Redirect}[1]{Redirect} >> will then contain the original
response, and so on.

If the server sends a header multiple times, then their contents will be
joined together with a comma (C<,>), as per the HTTP spec.

If an internal error occurs, such as not being able to resolve a hostname,
then C<$data> will be C<undef>, C<< $headers->{Status} >> will be
C<590>-C<599> and the C<Reason> pseudo-header will contain an error
message. Currently the following status codes are used:

=over 4

=item 595 - errors during connection establishment, proxy handshake.

=item 596 - errors during TLS negotiation, request sending and header processing.

=item 597 - errors during body receiving or processing.

=item 598 - user aborted request via C<on_header> or C<on_body>.

=item 599 - other, usually nonretryable, errors (garbled URL etc.).

=back

A typical callback might look like this:

   sub {
      my ($body, $hdr) = @_;

      if ($hdr->{Status} =~ /^2/) {
         ... everything should be ok
      } else {
         print "error, $hdr->{Status} $hdr->{Reason}\n";
      }
   }

Additional parameters are key-value pairs, and are fully optional. They
include:

=over 4

=item recurse => $count (default: $MAX_RECURSE)

Whether to recurse requests or not, e.g. on redirects, authentication and
other retries and so on, and how often to do so.

Only redirects to http and https URLs are supported. While most common
redirection forms are handled entirely within this module, some require
the use of the optional L<URI> module. If it is required but missing, then
the request will fail with an error.

=item headers => hashref

The request headers to use. Currently, C<http_request> may provide its own
C<Host:>, C<Content-Length:>, C<Connection:> and C<Cookie:> headers and
will provide defaults at least for C<TE:>, C<Referer:> and C<User-Agent:>
(this can be suppressed by using C<undef> for these headers in which case
they won't be sent at all).

You really should provide your own C<User-Agent:> header value that is
appropriate for your program - I wouldn't be surprised if the default
AnyEvent string gets blocked by webservers sooner or later.

Also, make sure that your headers names and values do not contain any
embedded newlines.

=item timeout => $seconds

The time-out to use for various stages - each connect attempt will reset
the timeout, as will read or write activity, i.e. this is not an overall
timeout.

Default timeout is 5 minutes.

=item proxy => [$host, $port[, $scheme]] or undef

Use the given http proxy for all requests, or no proxy if C<undef> is
used.

C<$scheme> must be either missing or must be C<http> for HTTP.

If not specified, then the default proxy is used (see
C<AnyEvent::HTTP::set_proxy>).

Currently, if your proxy requires authorization, you have to specify an
appropriate "Proxy-Authorization" header in every request.

Note that this module will prefer an existing persistent connection,
even if that connection was made using another proxy. If you need to
ensure that a new connection is made in this case, you can either force
C<persistent> to false or e.g. use the proxy address in your C<sessionid>.

=item body => $string

The request body, usually empty. Will be sent as-is (future versions of
this module might offer more options).

=item cookie_jar => $hash_ref

Passing this parameter enables (simplified) cookie-processing, loosely
based on the original netscape specification.

The C<$hash_ref> must be an (initially empty) hash reference which
will get updated automatically. It is possible to save the cookie jar
to persistent storage with something like JSON or Storable - see the
C<AnyEvent::HTTP::cookie_jar_expire> function if you wish to remove
expired or session-only cookies, and also for documentation on the format
of the cookie jar.

Note that this cookie implementation is not meant to be complete. If
you want complete cookie management you have to do that on your
own. C<cookie_jar> is meant as a quick fix to get most cookie-using sites
working. Cookies are a privacy disaster, do not use them unless required
to.

When cookie processing is enabled, the C<Cookie:> and C<Set-Cookie:>
headers will be set and handled by this module, otherwise they will be
left untouched.

=item tls_ctx => $scheme | $tls_ctx

Specifies the AnyEvent::TLS context to be used for https connections. This
parameter follows the same rules as the C<tls_ctx> parameter to
L<AnyEvent::Handle>, but additionally, the two strings C<low> or
C<high> can be specified, which give you a predefined low-security (no
verification, highest compatibility) and high-security (CA and common-name
verification) TLS context.

The default for this option is C<low>, which could be interpreted as "give
me the page, no matter what".

See also the C<sessionid> parameter.

=item sessionid => $string

The module might reuse connections to the same host internally (regardless
of other settings, such as C<tcp_connect> or C<proxy>). Sometimes (e.g.
when using TLS or a specfic proxy), you do not want to reuse connections
from other sessions. This can be achieved by setting this parameter to
some unique ID (such as the address of an object storing your state data
or the TLS context, or the proxy IP) - only connections using the same
unique ID will be reused.

=item on_prepare => $callback->($fh)

In rare cases you need to "tune" the socket before it is used to
connect (for example, to bind it on a given IP address). This parameter
overrides the prepare callback passed to C<AnyEvent::Socket::tcp_connect>
and behaves exactly the same way (e.g. it has to provide a
timeout). See the description for the C<$prepare_cb> argument of
C<AnyEvent::Socket::tcp_connect> for details.

=item tcp_connect => $callback->($host, $service, $connect_cb, $prepare_cb)

In even rarer cases you want total control over how AnyEvent::HTTP
establishes connections. Normally it uses L<AnyEvent::Socket::tcp_connect>
to do this, but you can provide your own C<tcp_connect> function -
obviously, it has to follow the same calling conventions, except that it
may always return a connection guard object.

The connections made by this hook will be treated as equivalent to
connections made the built-in way, specifically, they will be put into
and taken from the persistent connection cache. If your C<$tcp_connect>
function is incompatible with this kind of re-use, consider switching off
C<persistent> connections and/or providing a C<sessionid> identifier.

There are probably lots of weird uses for this function, starting from
tracing the hosts C<http_request> actually tries to connect, to (inexact
but fast) host => IP address caching or even socks protocol support.

=item on_header => $callback->($headers)

When specified, this callback will be called with the header hash as soon
as headers have been successfully received from the remote server (not on
locally-generated errors).

It has to return either true (in which case AnyEvent::HTTP will continue),
or false, in which case AnyEvent::HTTP will cancel the download (and call
the finish callback with an error code of C<598>).

This callback is useful, among other things, to quickly reject unwanted
content, which, if it is supposed to be rare, can be faster than first
doing a C<HEAD> request.

The downside is that cancelling the request makes it impossible to re-use
the connection. Also, the C<on_header> callback will not receive any
trailer (headers sent after the response body).

Example: cancel the request unless the content-type is "text/html".

   on_header => sub {
      $_[0]{"content-type"} =~ /^text\/html\s*(?:;|$)/
   },

=item on_body => $callback->($partial_body, $headers)

When specified, all body data will be passed to this callback instead of
to the completion callback. The completion callback will get the empty
string instead of the body data.

It has to return either true (in which case AnyEvent::HTTP will continue),
or false, in which case AnyEvent::HTTP will cancel the download (and call
the completion callback with an error code of C<598>).

The downside to cancelling the request is that it makes it impossible to
re-use the connection.

This callback is useful when the data is too large to be held in memory
(so the callback writes it to a file) or when only some information should
be extracted, or when the body should be processed incrementally.

It is usually preferred over doing your own body handling via
C<want_body_handle>, but in case of streaming APIs, where HTTP is
only used to create a connection, C<want_body_handle> is the better
alternative, as it allows you to install your own event handler, reducing
resource usage.

=item want_body_handle => $enable

When enabled (default is disabled), the behaviour of AnyEvent::HTTP
changes considerably: after parsing the headers, and instead of
downloading the body (if any), the completion callback will be
called. Instead of the C<$body> argument containing the body data, the
callback will receive the L<AnyEvent::Handle> object associated with the
connection. In error cases, C<undef> will be passed. When there is no body
(e.g. status C<304>), the empty string will be passed.

The handle object might or might not be in TLS mode, might be connected
to a proxy, be a persistent connection, use chunked transfer encoding
etc., and configured in unspecified ways. The user is responsible for this
handle (it will not be used by this module anymore).

This is useful with some push-type services, where, after the initial
headers, an interactive protocol is used (typical example would be the
push-style twitter API which starts a JSON/XML stream).

If you think you need this, first have a look at C<on_body>, to see if
that doesn't solve your problem in a better way.

=item persistent => $boolean

Try to create/reuse a persistent connection. When this flag is set
(default: true for idempotent requests, false for all others), then
C<http_request> tries to re-use an existing (previously-created)
persistent connection to same host (i.e. identical URL scheme, hostname,
port and sessionid) and, failing that, tries to create a new one.

Requests failing in certain ways will be automatically retried once, which
is dangerous for non-idempotent requests, which is why it defaults to off
for them. The reason for this is because the bozos who designed HTTP/1.1
made it impossible to distinguish between a fatal error and a normal
connection timeout, so you never know whether there was a problem with
your request or not.

When reusing an existent connection, many parameters (such as TLS context)
will be ignored. See the C<sessionid> parameter for a workaround.

=item keepalive => $boolean

Only used when C<persistent> is also true. This parameter decides whether
C<http_request> tries to handshake a HTTP/1.0-style keep-alive connection
(as opposed to only a HTTP/1.1 persistent connection).

The default is true, except when using a proxy, in which case it defaults
to false, as HTTP/1.0 proxies cannot support this in a meaningful way.

=item handle_params => { key => value ... }

The key-value pairs in this hash will be passed to any L<AnyEvent::Handle>
constructor that is called - not all requests will create a handle, and
sometimes more than one is created, so this parameter is only good for
setting hints.

Example: set the maximum read size to 4096, to potentially conserve memory
at the cost of speed.

   handle_params => {
      max_read_size => 4096,
   },

=back

Example: do a simple HTTP GET request for http://www.nethype.de/ and print
the response body.

   http_request GET => "http://www.nethype.de/", sub {
      my ($body, $hdr) = @_;
      print "$body\n";
   };

Example: do a HTTP HEAD request on https://www.google.com/, use a
timeout of 30 seconds.

   http_request
      HEAD    => "https://www.google.com",
      headers => { "user-agent" => "MySearchClient 1.0" },
      timeout => 30,
      sub {
         my ($body, $hdr) = @_;
         use Data::Dumper;
         print Dumper $hdr;
      }
   ;

Example: do another simple HTTP GET request, but immediately try to
cancel it.

   my $request = http_request GET => "http://www.nethype.de/", sub {
      my ($body, $hdr) = @_;
      print "$body\n";
   };

   undef $request;

=cut

#############################################################################
# wait queue/slots

sub _slot_schedule;
sub _slot_schedule($) {
   my $host = shift;

   while ($CO_SLOT{$host}[0] < $MAX_PER_HOST) {
      if (my $cb = shift @{ $CO_SLOT{$host}[1] }) {
         # somebody wants that slot
         ++$CO_SLOT{$host}[0];
         ++$ACTIVE;

         $cb->(AnyEvent::Util::guard {
            --$ACTIVE;
            --$CO_SLOT{$host}[0];
            _slot_schedule $host;
         });
      } else {
         # nobody wants the slot, maybe we can forget about it
         delete $CO_SLOT{$host} unless $CO_SLOT{$host}[0];
         last;
      }
   }
}

# wait for a free slot on host, call callback
sub _get_slot($$) {
   push @{ $CO_SLOT{$_[0]}[1] }, $_[1];

   _slot_schedule $_[0];
}

#############################################################################
# cookie handling

# expire cookies
sub cookie_jar_expire($;$) {
   my ($jar, $session_end) = @_;

   %$jar = () if $jar->{version} != 2;

   my $anow = AE::now;

   while (my ($chost, $paths) = each %$jar) {
      next unless ref $paths;

      while (my ($cpath, $cookies) = each %$paths) {
         while (my ($cookie, $kv) = each %$cookies) {
            if (exists $kv->{_expires}) {
               delete $cookies->{$cookie}
                  if $anow > $kv->{_expires};
            } elsif ($session_end) {
               delete $cookies->{$cookie};
            }
         }

         delete $paths->{$cpath}
            unless %$cookies;
      }

      delete $jar->{$chost}
         unless %$paths;
   }
}
 
# extract cookies from jar
sub cookie_jar_extract($$$$) {
   my ($jar, $scheme, $host, $path) = @_;

   %$jar = () if $jar->{version} != 2;

   $host = AnyEvent::Util::idn_to_ascii $host
      if $host =~ /[^\x00-\x7f]/;

   my @cookies;

   while (my ($chost, $paths) = each %$jar) {
      next unless ref $paths;

      # exact match or suffix including . match
      $chost eq $host or ".$chost" eq substr $host, -1 - length $chost
         or next;

      while (my ($cpath, $cookies) = each %$paths) {
         next unless $cpath eq substr $path, 0, length $cpath;

         while (my ($cookie, $kv) = each %$cookies) {
            next if $scheme ne "https" && exists $kv->{secure};

            if (exists $kv->{_expires} and AE::now > $kv->{_expires}) {
               delete $cookies->{$cookie};
               next;
            }

            my $value = $kv->{value};

            if ($value =~ /[=;,[:space:]]/) {
               $value =~ s/([\\"])/\\$1/g;
               $value = "\"$value\"";
            }

            push @cookies, "$cookie=$value";
         }
      }
   }

   \@cookies
}
 
# parse set_cookie header into jar
sub cookie_jar_set_cookie($$$$) {
   my ($jar, $set_cookie, $host, $date) = @_;

   %$jar = () if $jar->{version} != 2;

   my $anow = int AE::now;
   my $snow; # server-now

   for ($set_cookie) {
      # parse NAME=VALUE
      my @kv;

      # expires is not http-compliant in the original cookie-spec,
      # we support the official date format and some extensions
      while (
         m{
            \G\s*
            (?:
               expires \s*=\s* ([A-Z][a-z][a-z]+,\ [^,;]+)
               | ([^=;,[:space:]]+) (?: \s*=\s* (?: "((?:[^\\"]+|\\.)*)" | ([^;,[:space:]]*) ) )?
            )
         }gcxsi
      ) {
         my $name = $2;
         my $value = $4;

         if (defined $1) {
            # expires
            $name  = "expires";
            $value = $1;
         } elsif (defined $3) {
            # quoted
            $value = $3;
            $value =~ s/\\(.)/$1/gs;
         }

         push @kv, @kv ? lc $name : $name, $value;

         last unless /\G\s*;/gc;
      }

      last unless @kv;

      my $name = shift @kv;
      my %kv = (value => shift @kv, @kv);

      if (exists $kv{"max-age"}) {
         $kv{_expires} = $anow + delete $kv{"max-age"};
      } elsif (exists $kv{expires}) {
         $snow ||= parse_date ($date) || $anow;
         $kv{_expires} = $anow + (parse_date (delete $kv{expires}) - $snow);
      } else {
         delete $kv{_expires};
      }

      my $cdom;
      my $cpath = (delete $kv{path}) || "/";

      if (exists $kv{domain}) {
         $cdom = $kv{domain};

         $cdom =~ s/^\.?/./; # make sure it starts with a "."

         next if $cdom =~ /\.$/;

         # this is not rfc-like and not netscape-like. go figure.
         my $ndots = $cdom =~ y/.//;
         next if $ndots < ($cdom =~ /\.[^.][^.]\.[^.][^.]$/ ? 3 : 2);

         $cdom = substr $cdom, 1; # remove initial .
      } else {
         $cdom = $host;
      }

      # store it
      $jar->{version} = 2;
      $jar->{lc $cdom}{$cpath}{$name} = \%kv;

      redo if /\G\s*,/gc;
   }
}

#############################################################################
# keepalive/persistent connection cache

# fetch a connection from the keepalive cache
sub ka_fetch($) {
   my $ka_key = shift;

   my $hdl = pop @{ $KA_CACHE{$ka_key} }; # currently we reuse the MOST RECENTLY USED connection
   delete $KA_CACHE{$ka_key}
      unless @{ $KA_CACHE{$ka_key} };

   $hdl
}

sub ka_store($$) {
   my ($ka_key, $hdl) = @_;

   my $kaa = $KA_CACHE{$ka_key} ||= [];

   my $destroy = sub {
      my @ka = grep $_ != $hdl, @{ $KA_CACHE{$ka_key} };

      $hdl->destroy;

      @ka
         ? $KA_CACHE{$ka_key} = \@ka
         : delete $KA_CACHE{$ka_key};
   };

   # on error etc., destroy
   $hdl->on_error ($destroy);
   $hdl->on_eof   ($destroy);
   $hdl->on_read  ($destroy);
   $hdl->timeout  ($PERSISTENT_TIMEOUT);

   push @$kaa, $hdl;
   shift @$kaa while @$kaa > $MAX_PER_HOST;
}

#############################################################################
# utilities

# continue to parse $_ for headers and place them into the arg
sub _parse_hdr() {
   my %hdr;

   # things seen, not parsed:
   # p3pP="NON CUR OTPi OUR NOR UNI"

   $hdr{lc $1} .= ",$2"
      while /\G
            ([^:\000-\037]*):
            [\011\040]*
            ((?: [^\012]+ | \012[\011\040] )*)
            \012
         /gxc;

   /\G$/
     or return;

   # remove the "," prefix we added to all headers above
   substr $_, 0, 1, ""
      for values %hdr;

   \%hdr
}

#############################################################################
# http_get

our $qr_nlnl = qr{(?<![^\012])\015?\012};

our $TLS_CTX_LOW  = { cache => 1, sslv2 => 1 };
our $TLS_CTX_HIGH = { cache => 1, verify => 1, verify_peername => "https" };

# maybe it should just become a normal object :/

sub _destroy_state(\%) {
   my ($state) = @_;

   $state->{handle}->destroy if $state->{handle};
   %$state = ();
}

sub _error(\%$$) {
   my ($state, $cb, $hdr) = @_;

   &_destroy_state ($state);

   $cb->(undef, $hdr);
   ()
}

our %IDEMPOTENT = (
   DELETE		=> 1,
   GET			=> 1,
   HEAD			=> 1,
   OPTIONS		=> 1,
   PUT			=> 1,
   TRACE		=> 1,

   ACL			=> 1,
   "BASELINE-CONTROL"	=> 1,
   BIND			=> 1,
   CHECKIN		=> 1,
   CHECKOUT		=> 1,
   COPY			=> 1,
   LABEL		=> 1,
   LINK			=> 1,
   MERGE		=> 1,
   MKACTIVITY		=> 1,
   MKCALENDAR		=> 1,
   MKCOL		=> 1,
   MKREDIRECTREF	=> 1,
   MKWORKSPACE		=> 1,
   MOVE			=> 1,
   ORDERPATCH		=> 1,
   PROPFIND		=> 1,
   PROPPATCH		=> 1,
   REBIND		=> 1,
   REPORT		=> 1,
   SEARCH		=> 1,
   UNBIND		=> 1,
   UNCHECKOUT		=> 1,
   UNLINK		=> 1,
   UNLOCK		=> 1,
   UPDATE		=> 1,
   UPDATEREDIRECTREF	=> 1,
   "VERSION-CONTROL"	=> 1,
);

sub http_request($$@) {
   my $cb = pop;
   my ($method, $url, %arg) = @_;

   my %hdr;

   $arg{tls_ctx} = $TLS_CTX_LOW  if $arg{tls_ctx} eq "low" || !exists $arg{tls_ctx};
   $arg{tls_ctx} = $TLS_CTX_HIGH if $arg{tls_ctx} eq "high";

   $method = uc $method;

   if (my $hdr = $arg{headers}) {
      while (my ($k, $v) = each %$hdr) {
         $hdr{lc $k} = $v;
      }
   }

   # pseudo headers for all subsequent responses
   my @pseudo = (URL => $url);
   push @pseudo, Redirect => delete $arg{Redirect} if exists $arg{Redirect};

   my $recurse = exists $arg{recurse} ? delete $arg{recurse} : $MAX_RECURSE;

   return $cb->(undef, { @pseudo, Status => 599, Reason => "Too many redirections" })
      if $recurse < 0;

   my $proxy   = exists $arg{proxy} ? $arg{proxy} : $PROXY;
   my $timeout = $arg{timeout} || $TIMEOUT;

   my ($uscheme, $uauthority, $upath, $query, undef) = # ignore fragment
      $url =~ m|^([^:]+):(?://([^/?#]*))?([^?#]*)(?:(\?[^#]*))?(?:#(.*))?$|;

   $uscheme = lc $uscheme;

   my $uport = $uscheme eq "http"  ?  80
             : $uscheme eq "https" ? 443
             : return $cb->(undef, { @pseudo, Status => 599, Reason => "Only http and https URL schemes supported" });

   $uauthority =~ /^(?: .*\@ )? ([^\@]+?) (?: : (\d+) )?$/x
      or return $cb->(undef, { @pseudo, Status => 599, Reason => "Unparsable URL" });

   my $uhost = lc $1;
   $uport = $2 if defined $2;

   $hdr{host} = defined $2 ? "$uhost:$2" : "$uhost"
      unless exists $hdr{host};

   $uhost =~ s/^\[(.*)\]$/$1/;
   $upath .= $query if length $query;

   $upath =~ s%^/?%/%;

   # cookie processing
   if (my $jar = $arg{cookie_jar}) {
      my $cookies = cookie_jar_extract $jar, $uscheme, $uhost, $upath;

      $hdr{cookie} = join "; ", @$cookies
         if @$cookies;
   }

   my ($rhost, $rport, $rscheme, $rpath); # request host, port, path

   if ($proxy) {
      ($rpath, $rhost, $rport, $rscheme) = ($url, @$proxy);

      $rscheme = "http" unless defined $rscheme;

      # don't support https requests over https-proxy transport,
      # can't be done with tls as spec'ed, unless you double-encrypt.
      $rscheme = "http" if $uscheme eq "https" && $rscheme eq "https";

      $rhost   = lc $rhost;
      $rscheme = lc $rscheme;
   } else {
      ($rhost, $rport, $rscheme, $rpath) = ($uhost, $uport, $uscheme, $upath);
   }

   # leave out fragment and query string, just a heuristic
   $hdr{referer}      = "$uscheme://$uauthority$upath" unless exists $hdr{referer};
   $hdr{"user-agent"} = $USERAGENT                     unless exists $hdr{"user-agent"};

   $hdr{"content-length"} = length $arg{body}
      if length $arg{body} || $method ne "GET";

   my $idempotent = $IDEMPOTENT{$method};

   # default value for keepalive is true iff the request is for an idempotent method
   my $persistent = exists $arg{persistent} ? !!$arg{persistent} : $idempotent;
   my $keepalive  = exists $arg{keepalive}  ? !!$arg{keepalive}  : !$proxy;
   my $was_persistent; # true if this is actually a recycled connection

   # the key to use in the keepalive cache
   my $ka_key = "$uscheme\x00$uhost\x00$uport\x00$arg{sessionid}";

   $hdr{connection} = ($persistent ? $keepalive ? "keep-alive, " : "" : "close, ") . "Te"; #1.1
   $hdr{te}         = "trailers" unless exists $hdr{te}; #1.1

   my %state = (connect_guard => 1);

   my $ae_error = 595; # connecting

   # handle actual, non-tunneled, request
   my $handle_actual_request = sub {
      $ae_error = 596; # request phase

      my $hdl = $state{handle};

      $hdl->starttls ("connect") if $uscheme eq "https" && !exists $hdl->{tls};

      # send request
      $hdl->push_write (
         "$method $rpath HTTP/1.1\015\012"
         . (join "", map "\u$_: $hdr{$_}\015\012", grep defined $hdr{$_}, keys %hdr)
         . "\015\012"
         . $arg{body}
      );

      # return if error occurred during push_write()
      return unless %state;

      # reduce memory usage, save a kitten, also re-use it for the response headers.
      %hdr = ();

      # status line and headers
      $state{read_response} = sub {
         return unless %state;

         for ("$_[1]") {
            y/\015//d; # weed out any \015, as they show up in the weirdest of places.

            /^HTTP\/0*([0-9\.]+) \s+ ([0-9]{3}) (?: \s+ ([^\012]*) )? \012/gxci
               or return _error %state, $cb, { @pseudo, Status => 599, Reason => "Invalid server response" };

            # 100 Continue handling
            # should not happen as we don't send expect: 100-continue,
            # but we handle it just in case.
            # since we send the request body regardless, if we get an error
            # we are out of-sync, which we currently do NOT handle correctly.
            return $state{handle}->push_read (line => $qr_nlnl, $state{read_response})
               if $2 eq 100;

            push @pseudo,
               HTTPVersion => $1,
               Status      => $2,
               Reason      => $3,
            ;

            my $hdr = _parse_hdr
               or return _error %state, $cb, { @pseudo, Status => 599, Reason => "Garbled response headers" };

            %hdr = (%$hdr, @pseudo);
         }

         # redirect handling
         # relative uri handling forced by microsoft and other shitheads.
         # we give our best and fall back to URI if available.
         if (exists $hdr{location}) {
            my $loc = $hdr{location};

            if ($loc =~ m%^//%) { # //
               $loc = "$uscheme:$loc";

            } elsif ($loc eq "") {
               $loc = $url;

            } elsif ($loc !~ /^(?: $ | [^:\/?\#]+ : )/x) { # anything "simple"
               $loc =~ s/^\.\/+//;

               if ($loc !~ m%^[.?#]%) {
                  my $prefix = "$uscheme://$uauthority";

                  unless ($loc =~ s/^\///) {
                     $prefix .= $upath;
                     $prefix =~ s/\/[^\/]*$//;
                  }

                  $loc = "$prefix/$loc";

               } elsif (eval { require URI }) { # uri
                  $loc = URI->new_abs ($loc, $url)->as_string;

               } else {
                  return _error %state, $cb, { @pseudo, Status => 599, Reason => "Cannot parse Location (URI module missing)" };
                  #$hdr{Status} = 599;
                  #$hdr{Reason} = "Unparsable Redirect (URI module missing)";
                  #$recurse = 0;
               }
            }

            $hdr{location} = $loc;
         }

         my $redirect;

         if ($recurse) {
            my $status = $hdr{Status};

            # industry standard is to redirect POST as GET for
            # 301, 302 and 303, in contrast to HTTP/1.0 and 1.1.
            # also, the UA should ask the user for 301 and 307 and POST,
            # industry standard seems to be to simply follow.
            # we go with the industry standard. 308 is defined
            # by rfc7538
            if ($status == 301 or $status == 302 or $status == 303) {
               $redirect = 1;
               # HTTP/1.1 is unclear on how to mutate the method
               unless ($method eq "HEAD") {
                  $method = "GET";
                  delete $arg{body};
               }
            } elsif ($status == 307 or $status == 308) {
               $redirect = 1;
            }
         }

         my $finish = sub { # ($data, $err_status, $err_reason[, $persistent])
            if ($state{handle}) {
               # handle keepalive
               if (
                  $persistent
                  && $_[3]
                  && ($hdr{HTTPVersion} < 1.1
                      ? $hdr{connection} =~ /\bkeep-?alive\b/i
                      : $hdr{connection} !~ /\bclose\b/i)
               ) {
                  ka_store $ka_key, delete $state{handle};
               } else {
                  # no keepalive, destroy the handle
                  $state{handle}->destroy;
               }
            }

            %state = ();

            if (defined $_[1]) {
               $hdr{OrigStatus} = $hdr{Status}; $hdr{Status} = $_[1];
               $hdr{OrigReason} = $hdr{Reason}; $hdr{Reason} = $_[2];
            }

            # set-cookie processing
            if ($arg{cookie_jar}) {
               cookie_jar_set_cookie $arg{cookie_jar}, $hdr{"set-cookie"}, $uhost, $hdr{date};
            }

            if ($redirect && exists $hdr{location}) {
               # we ignore any errors, as it is very common to receive
               # Content-Length != 0 but no actual body
               # we also access %hdr, as $_[1] might be an erro
               $state{recurse} =
                  http_request (
                     $method  => $hdr{location},
                     %arg,
                     recurse  => $recurse - 1,
                     Redirect => [$_[0], \%hdr],
                     sub {
                        %state = ();
                        &$cb
                     },
                  );
            } else {
               $cb->($_[0], \%hdr);
            }
         };

         $ae_error = 597; # body phase

         my $chunked = $hdr{"transfer-encoding"} =~ /\bchunked\b/i; # not quite correct...

         my $len = $chunked ? undef : $hdr{"content-length"};

         # body handling, many different code paths
         # - no body expected
         # - want_body_handle
         # - te chunked
         # - 2x length known (with or without on_body)
         # - 2x length not known (with or without on_body)
         if (!$redirect && $arg{on_header} && !$arg{on_header}(\%hdr)) {
            $finish->(undef, 598 => "Request cancelled by on_header");
         } elsif (
            $hdr{Status} =~ /^(?:1..|204|205|304)$/
            or $method eq "HEAD"
            or (defined $len && $len == 0) # == 0, not !, because "0   " is true
         ) {
            # no body
            $finish->("", undef, undef, 1);

         } elsif (!$redirect && $arg{want_body_handle}) {
            $_[0]->on_eof   (undef);
            $_[0]->on_error (undef);
            $_[0]->on_read  (undef);

            $finish->(delete $state{handle});

         } elsif ($chunked) {
            my $cl = 0;
            my $body = "";
            my $on_body = (!$redirect && $arg{on_body}) || sub { $body .= shift; 1 };

            $state{read_chunk} = sub {
               $_[1] =~ /^([0-9a-fA-F]+)/
                  or return $finish->(undef, $ae_error => "Garbled chunked transfer encoding");

               my $len = hex $1;

               if ($len) {
                  $cl += $len;

                  $_[0]->push_read (chunk => $len, sub {
                     $on_body->($_[1], \%hdr)
                        or return $finish->(undef, 598 => "Request cancelled by on_body");

                     $_[0]->push_read (line => sub {
                        length $_[1]
                           and return $finish->(undef, $ae_error => "Garbled chunked transfer encoding");
                        $_[0]->push_read (line => $state{read_chunk});
                     });
                  });
               } else {
                  $hdr{"content-length"} ||= $cl;

                  $_[0]->push_read (line => $qr_nlnl, sub {
                     if (length $_[1]) {
                        for ("$_[1]") {
                           y/\015//d; # weed out any \015, as they show up in the weirdest of places.

                           my $hdr = _parse_hdr
                              or return $finish->(undef, $ae_error => "Garbled response trailers");

                           %hdr = (%hdr, %$hdr);
                        }
                     }

                     $finish->($body, undef, undef, 1);
                  });
               }
            };

            $_[0]->push_read (line => $state{read_chunk});

         } elsif (!$redirect && $arg{on_body}) {
            if (defined $len) {
               $_[0]->on_read (sub {
                  $len -= length $_[0]{rbuf};

                  $arg{on_body}(delete $_[0]{rbuf}, \%hdr)
                     or return $finish->(undef, 598 => "Request cancelled by on_body");

                  $len > 0
                     or $finish->("", undef, undef, 1);
               });
            } else {
               $_[0]->on_eof (sub {
                  $finish->("");
               });
               $_[0]->on_read (sub {
                  $arg{on_body}(delete $_[0]{rbuf}, \%hdr)
                     or $finish->(undef, 598 => "Request cancelled by on_body");
               });
            }
         } else {
            $_[0]->on_eof (undef);

            if (defined $len) {
               $_[0]->on_read (sub {
                  $finish->((substr delete $_[0]{rbuf}, 0, $len, ""), undef, undef, 1)
                     if $len <= length $_[0]{rbuf};
               });
            } else {
               $_[0]->on_error (sub {
                  ($! == Errno::EPIPE || !$!)
                     ? $finish->(delete $_[0]{rbuf})
                     : $finish->(undef, $ae_error => $_[2]);
               });
               $_[0]->on_read (sub { });
            }
         }
      };

      # if keepalive is enabled, then the server closing the connection
      # before a response can happen legally - we retry on idempotent methods.
      if ($was_persistent && $idempotent) {
         my $old_eof = $hdl->{on_eof};
         $hdl->{on_eof} = sub {
            _destroy_state %state;

            %state = ();
            $state{recurse} =
               http_request (
                  $method    => $url,
                  %arg,
                  recurse    => $recurse - 1,
                  persistent => 0,
                  sub {
                     %state = ();
                     &$cb
                  }
               );
         };
         $hdl->on_read (sub {
            return unless %state;

            # as soon as we receive something, a connection close
            # once more becomes a hard error
            $hdl->{on_eof} = $old_eof;
            $hdl->push_read (line => $qr_nlnl, $state{read_response});
         });
      } else {
         $hdl->push_read (line => $qr_nlnl, $state{read_response});
      }
   };

   my $prepare_handle = sub {
      my ($hdl) = $state{handle};

      $hdl->on_error (sub {
         _error %state, $cb, { @pseudo, Status => $ae_error, Reason => $_[2] };
      });
      $hdl->on_eof (sub {
         _error %state, $cb, { @pseudo, Status => $ae_error, Reason => "Unexpected end-of-file" };
      });
      $hdl->timeout_reset;
      $hdl->timeout ($timeout);
   };

   # connected to proxy (or origin server)
   my $connect_cb = sub {
      my $fh = shift
         or return _error %state, $cb, { @pseudo, Status => $ae_error, Reason => "$!" };

      return unless delete $state{connect_guard};

      # get handle
      $state{handle} = new AnyEvent::Handle
         %{ $arg{handle_params} },
         fh       => $fh,
         peername => $uhost,
         tls_ctx  => $arg{tls_ctx},
      ;

      $prepare_handle->();

      #$state{handle}->starttls ("connect") if $rscheme eq "https";

      # now handle proxy-CONNECT method
      if ($proxy && $uscheme eq "https") {
         # oh dear, we have to wrap it into a connect request

         my $auth = exists $hdr{"proxy-authorization"}
            ? "proxy-authorization: " . (delete $hdr{"proxy-authorization"}) . "\015\012"
            : "";

         # maybe re-use $uauthority with patched port?
         $state{handle}->push_write ("CONNECT $uhost:$uport HTTP/1.0\015\012$auth\015\012");
         $state{handle}->push_read (line => $qr_nlnl, sub {
            $_[1] =~ /^HTTP\/([0-9\.]+) \s+ ([0-9]{3}) (?: \s+ ([^\015\012]*) )?/ix
               or return _error %state, $cb, { @pseudo, Status => 599, Reason => "Invalid proxy connect response ($_[1])" };

            if ($2 == 200) {
               $rpath = $upath;
               $handle_actual_request->();
            } else {
               _error %state, $cb, { @pseudo, Status => $2, Reason => $3 };
            }
         });
      } else {
         delete $hdr{"proxy-authorization"} unless $proxy;

         $handle_actual_request->();
      }
   };

   _get_slot $uhost, sub {
      $state{slot_guard} = shift;

      return unless $state{connect_guard};

      # try to use an existing keepalive connection, but only if we, ourselves, plan
      # on a keepalive request (in theory, this should be a separate config option).
      if ($persistent && $KA_CACHE{$ka_key}) {
         $was_persistent = 1;

         $state{handle} = ka_fetch $ka_key;
#         $state{handle}->destroyed
#            and die "AnyEvent::HTTP: unexpectedly got a destructed handle (1), please report.";#d#
         $prepare_handle->();
#         $state{handle}->destroyed
#            and die "AnyEvent::HTTP: unexpectedly got a destructed handle (2), please report.";#d#
         $rpath = $upath;
         $handle_actual_request->();

      } else {
         my $tcp_connect = $arg{tcp_connect}
                           || do { require AnyEvent::Socket; \&AnyEvent::Socket::tcp_connect };

         $state{connect_guard} = $tcp_connect->($rhost, $rport, $connect_cb, $arg{on_prepare} || sub { $timeout });
      }
   };

   defined wantarray && AnyEvent::Util::guard { _destroy_state %state }
}

sub http_get($@) {
   unshift @_, "GET";
   &http_request
}

sub http_head($@) {
   unshift @_, "HEAD";
   &http_request
}

sub http_post($$@) {
   my $url = shift;
   unshift @_, "POST", $url, "body";
   &http_request
}

=back

=head2 DNS CACHING

AnyEvent::HTTP uses the AnyEvent::Socket::tcp_connect function for
the actual connection, which in turn uses AnyEvent::DNS to resolve
hostnames. The latter is a simple stub resolver and does no caching
on its own. If you want DNS caching, you currently have to provide
your own default resolver (by storing a suitable resolver object in
C<$AnyEvent::DNS::RESOLVER>) or your own C<tcp_connect> callback.

=head2 GLOBAL FUNCTIONS AND VARIABLES

=over 4

=item AnyEvent::HTTP::set_proxy "proxy-url"

Sets the default proxy server to use. The proxy-url must begin with a
string of the form C<http://host:port>, croaks otherwise.

To clear an already-set proxy, use C<undef>.

When AnyEvent::HTTP is loaded for the first time it will query the
default proxy from the operating system, currently by looking at
C<$ENV{http_proxy>}.

=item AnyEvent::HTTP::cookie_jar_expire $jar[, $session_end]

Remove all cookies from the cookie jar that have been expired. If
C<$session_end> is given and true, then additionally remove all session
cookies.

You should call this function (with a true C<$session_end>) before you
save cookies to disk, and you should call this function after loading them
again. If you have a long-running program you can additionally call this
function from time to time.

A cookie jar is initially an empty hash-reference that is managed by this
module. Its format is subject to change, but currently it is as follows:

The key C<version> has to contain C<2>, otherwise the hash gets
cleared. All other keys are hostnames or IP addresses pointing to
hash-references. The key for these inner hash references is the
server path for which this cookie is meant, and the values are again
hash-references. Each key of those hash-references is a cookie name, and
the value, you guessed it, is another hash-reference, this time with the
key-value pairs from the cookie, except for C<expires> and C<max-age>,
which have been replaced by a C<_expires> key that contains the cookie
expiry timestamp. Session cookies are indicated by not having an
C<_expires> key.

Here is an example of a cookie jar with a single cookie, so you have a
chance of understanding the above paragraph:

   {
      version    => 2,
      "10.0.0.1" => {
         "/" => {
            "mythweb_id" => {
              _expires => 1293917923,
              value    => "ooRung9dThee3ooyXooM1Ohm",
            },
         },
      },
   }

=item $date = AnyEvent::HTTP::format_date $timestamp

Takes a POSIX timestamp (seconds since the epoch) and formats it as a HTTP
Date (RFC 2616).

=item $timestamp = AnyEvent::HTTP::parse_date $date

Takes a HTTP Date (RFC 2616) or a Cookie date (netscape cookie spec) or a
bunch of minor variations of those, and returns the corresponding POSIX
timestamp, or C<undef> if the date cannot be parsed.

=item $AnyEvent::HTTP::MAX_RECURSE

The default value for the C<recurse> request parameter (default: C<10>).

=item $AnyEvent::HTTP::TIMEOUT

The default timeout for connection operations (default: C<300>).

=item $AnyEvent::HTTP::USERAGENT

The default value for the C<User-Agent> header (the default is
C<Mozilla/5.0 (compatible; U; AnyEvent-HTTP/$VERSION; +http://software.schmorp.de/pkg/AnyEvent)>).

=item $AnyEvent::HTTP::MAX_PER_HOST

The maximum number of concurrent connections to the same host (identified
by the hostname). If the limit is exceeded, then additional requests
are queued until previous connections are closed. Both persistent and
non-persistent connections are counted in this limit.

The default value for this is C<4>, and it is highly advisable to not
increase it much.

For comparison: the RFC's recommend 4 non-persistent or 2 persistent
connections, older browsers used 2, newer ones (such as firefox 3)
typically use 6, and Opera uses 8 because like, they have the fastest
browser and give a shit for everybody else on the planet.

=item $AnyEvent::HTTP::PERSISTENT_TIMEOUT

The time after which idle persistent connections get closed by
AnyEvent::HTTP (default: C<3>).

=item $AnyEvent::HTTP::ACTIVE

The number of active connections. This is not the number of currently
running requests, but the number of currently open and non-idle TCP
connections. This number can be useful for load-leveling.

=back

=cut

our @month   = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
our @weekday = qw(Sun Mon Tue Wed Thu Fri Sat);

sub format_date($) {
   my ($time) = @_;

   # RFC 822/1123 format
   my ($S, $M, $H, $mday, $mon, $year, $wday, $yday, undef) = gmtime $time;

   sprintf "%s, %02d %s %04d %02d:%02d:%02d GMT",
      $weekday[$wday], $mday, $month[$mon], $year + 1900,
      $H, $M, $S;
}

sub parse_date($) {
   my ($date) = @_;

   my ($d, $m, $y, $H, $M, $S);

   if ($date =~ /^[A-Z][a-z][a-z]+, ([0-9][0-9]?)[\- ]([A-Z][a-z][a-z])[\- ]([0-9][0-9][0-9][0-9]) ([0-9][0-9]?):([0-9][0-9]?):([0-9][0-9]?) GMT$/) {
      # RFC 822/1123, required by RFC 2616 (with " ")
      # cookie dates (with "-")

      ($d, $m, $y, $H, $M, $S) = ($1, $2, $3, $4, $5, $6);

   } elsif ($date =~ /^[A-Z][a-z][a-z]+, ([0-9][0-9]?)-([A-Z][a-z][a-z])-([0-9][0-9]) ([0-9][0-9]?):([0-9][0-9]?):([0-9][0-9]?) GMT$/) {
      # RFC 850
      ($d, $m, $y, $H, $M, $S) = ($1, $2, $3 < 69 ? $3 + 2000 : $3 + 1900, $4, $5, $6);

   } elsif ($date =~ /^[A-Z][a-z][a-z]+ ([A-Z][a-z][a-z]) ([0-9 ]?[0-9]) ([0-9][0-9]?):([0-9][0-9]?):([0-9][0-9]?) ([0-9][0-9][0-9][0-9])$/) {
      # ISO C's asctime
      ($d, $m, $y, $H, $M, $S) = ($2, $1, $6, $3, $4, $5);
   }
   # other formats fail in the loop below

   for (0..11) {
      if ($m eq $month[$_]) {
         require Time::Local;
         return eval { Time::Local::timegm ($S, $M, $H, $d, $_, $y) };
      }
   }

   undef
}

sub set_proxy($) {
   if (length $_[0]) {
      $_[0] =~ m%^(http):// ([^:/]+) (?: : (\d*) )?%ix
         or Carp::croak "$_[0]: invalid proxy URL";
      $PROXY = [$2, $3 || 3128, $1]
   } else {
      undef $PROXY;
   }
}

# initialise proxy from environment
eval {
   set_proxy $ENV{http_proxy};
};

=head2 SHOWCASE

This section contains some more elaborate "real-world" examples or code
snippets.

=head2 HTTP/1.1 FILE DOWNLOAD

Downloading files with HTTP can be quite tricky, especially when something
goes wrong and you want to resume.

Here is a function that initiates and resumes a download. It uses the
last modified time to check for file content changes, and works with many
HTTP/1.0 servers as well, and usually falls back to a complete re-download
on older servers.

It calls the completion callback with either C<undef>, which means a
nonretryable error occurred, C<0> when the download was partial and should
be retried, and C<1> if it was successful.

   use AnyEvent::HTTP;

   sub download($$$) {
      my ($url, $file, $cb) = @_;

      open my $fh, "+<", $file
         or die "$file: $!";

      my %hdr;
      my $ofs = 0;

      if (stat $fh and -s _) {
         $ofs = -s _;
         warn "-s is ", $ofs;
         $hdr{"if-unmodified-since"} = AnyEvent::HTTP::format_date +(stat _)[9];
         $hdr{"range"} = "bytes=$ofs-";
      }

      http_get $url,
         headers   => \%hdr,
         on_header => sub {
            my ($hdr) = @_;

            if ($hdr->{Status} == 200 && $ofs) {
               # resume failed
               truncate $fh, $ofs = 0;
            }

            sysseek $fh, $ofs, 0;

            1
         },
         on_body   => sub {
            my ($data, $hdr) = @_;

            if ($hdr->{Status} =~ /^2/) {
               length $data == syswrite $fh, $data
                  or return; # abort on write errors
            }

            1
         },
         sub {
            my (undef, $hdr) = @_;

            my $status = $hdr->{Status};

            if (my $time = AnyEvent::HTTP::parse_date $hdr->{"last-modified"}) {
               utime $time, $time, $fh;
            }

            if ($status == 200 || $status == 206 || $status == 416) {
               # download ok || resume ok || file already fully downloaded
               $cb->(1, $hdr);

            } elsif ($status == 412) {
               # file has changed while resuming, delete and retry
               unlink $file;
               $cb->(0, $hdr);

            } elsif ($status == 500 or $status == 503 or $status =~ /^59/) {
               # retry later
               $cb->(0, $hdr);

            } else {
               $cb->(undef, $hdr);
            }
         }
      ;
   }

   download "http://server/somelargefile", "/tmp/somelargefile", sub {
      if ($_[0]) {
         print "OK!\n";
      } elsif (defined $_[0]) {
         print "please retry later\n";
      } else {
         print "ERROR\n";
      }
   };

=head3 SOCKS PROXIES

Socks proxies are not directly supported by AnyEvent::HTTP. You can
compile your perl to support socks, or use an external program such as
F<socksify> (dante) or F<tsocks> to make your program use a socks proxy
transparently.

Alternatively, for AnyEvent::HTTP only, you can use your own
C<tcp_connect> function that does the proxy handshake - here is an example
that works with socks4a proxies:

   use Errno;
   use AnyEvent::Util;
   use AnyEvent::Socket;
   use AnyEvent::Handle;

   # host, port and username of/for your socks4a proxy
   my $socks_host = "10.0.0.23";
   my $socks_port = 9050;
   my $socks_user = "";

   sub socks4a_connect {
      my ($host, $port, $connect_cb, $prepare_cb) = @_;

      my $hdl = new AnyEvent::Handle
         connect    => [$socks_host, $socks_port],
         on_prepare => sub { $prepare_cb->($_[0]{fh}) },
         on_error   => sub { $connect_cb->() },
      ;

      $hdl->push_write (pack "CCnNZ*Z*", 4, 1, $port, 1, $socks_user, $host);

      $hdl->push_read (chunk => 8, sub {
         my ($hdl, $chunk) = @_;
         my ($status, $port, $ipn) = unpack "xCna4", $chunk;

         if ($status == 0x5a) {
            $connect_cb->($hdl->{fh}, (format_address $ipn) . ":$port");
         } else {
            $! = Errno::ENXIO; $connect_cb->();
         }
      });

      $hdl
   }

Use C<socks4a_connect> instead of C<tcp_connect> when doing C<http_request>s,
possibly after switching off other proxy types:

   AnyEvent::HTTP::set_proxy undef; # usually you do not want other proxies

   http_get 'http://www.google.com', tcp_connect => \&socks4a_connect, sub {
      my ($data, $headers) = @_;
      ...
   };

=head1 SEE ALSO

L<AnyEvent>.

=head1 AUTHOR

   Marc Lehmann <schmorp@schmorp.de>
   http://home.schmorp.de/

With many thanks to Дмитрий Шалашов, who provided countless
testcases and bugreports.

=cut

1

