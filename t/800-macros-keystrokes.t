#!perl
use strict;
use warnings;
use Interhack::Test tests => 4;

# tests the interaction of Keystrokes and Macros to make sure that no matter
# which way they are loaded, Macros are expanded before Keystrokes are counted

SKIP:
{
    my $interhack = Interhack::Test->new();
    $interhack->load_plugin_or_skip("Keystrokes", 2);
    $interhack->load_plugin_or_skip("Macros", 2);

    $interhack->typing("\ce");
    $interhack->iterate for 1..10;
    is($interhack->sent, "E-  Elbereth\n");
    is($interhack->keystrokes, 13);
}

SKIP:
{
    my $interhack = Interhack::Test->new();
    $interhack->load_plugin_or_skip("Macros", 2);
    $interhack->load_plugin_or_skip("Keystrokes", 2);

    $interhack->typing("\ce");
    $interhack->iterate for 1..10;
    is($interhack->sent, "E-  Elbereth\n");
    is($interhack->keystrokes, 13);
}

