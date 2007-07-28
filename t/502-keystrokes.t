#!perl
use strict;
use warnings;
use Interhack::Test tests => 3;

my $interhack = Interhack::Test->new();
$interhack->load_plugin_ok("Keystrokes");

$interhack->typing("foo");
$interhack->iterate for 1..10;
is($interhack->keystrokes, 3);

$interhack->typing("yahoo");
$interhack->iterate for 1..10;
is($interhack->keystrokes, 8);


