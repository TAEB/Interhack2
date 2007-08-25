#!/usr/bin/env perl
use Interhack::Test tests => 4;

# tests the interaction of Keystrokes and Macros to make sure that no matter
# which way they are loaded, Macros are expanded before Keystrokes are counted

SKIP:
{
    my $interhack = Interhack::Test->new(no_state => 1);
    $interhack->load_plugin_or_skip("Keystrokes", 2);
    $interhack->load_plugin_or_skip("Macros", 2);

    $interhack->add_macro("\ce", "E-  Elbereth\n");

    $interhack->typing("\ce");
    $interhack->iterate for 1..20;
    is($interhack->sent, "E-  Elbereth\n");
    is($interhack->keystrokes, 13);
}

SKIP:
{
    my $interhack = Interhack::Test->new(no_state => 1);
    $interhack->load_plugin_or_skip("Macros", 2);
    $interhack->load_plugin_or_skip("Keystrokes", 2);

    $interhack->add_macro("\ce", "E-  Elbereth\n");

    $interhack->typing("\ce");
    $interhack->iterate for 1..20;
    is($interhack->sent, "E-  Elbereth\n");
    is($interhack->keystrokes, 13);
}

