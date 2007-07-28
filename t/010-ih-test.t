#!perl
use strict;
use warnings;
use Interhack::Test tests => 16;

# But who tests the testers?

my $interhack = Interhack::Test->new();

# simple socket->monitor {{{
$interhack->recv("foo");
$interhack->iterate();
$interhack->monitor_like(qr/foo/, "recv updates monitor");
$interhack->top_like(qr/foo/, "recv updates topline");
is($interhack->recvd, "foo", "recv updates recvd");
is($interhack->recvd, "", "recvd clears itself");
# }}}
# simple keyboard->socket {{{
$interhack->typing("bar");
$interhack->iterate();
is($interhack->sent, "b", "typing updates sent 1/7");
is($interhack->sent, "",  "typing updates sent 2/7");

$interhack->iterate();
is($interhack->sent, "a", "typing updates sent 3/7");
is($interhack->sent, "",  "typing updates sent 4/7");

$interhack->iterate();
is($interhack->sent, "r", "typing updates sent 5/7");
is($interhack->sent, "",  "typing updates sent 6/7");

$interhack->iterate();
is($interhack->sent, "",  "typing updates sent 7/7");
# }}}
# escape codes to monitor {{{
$interhack->recv("\e[2Hquux");
$interhack->iterate();
$interhack->monitor_like(qr/quux/, "recv with escape codes updates monitor");
$interhack->monitor_unlike(qr/Hquux/, "monitor doesn't have escape codes");
$interhack->top_unlike(qr/quux/, "topline didn't get updated with second-line text");
is($interhack->recvd, "\e[2Hquux", "recv updates recvd");
is($interhack->recvd, "", "recvd clears itself");
# }}}

