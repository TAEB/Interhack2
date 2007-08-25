#!/usr/bin/env perl
use Interhack::Test tests => 2;

my $interhack = Interhack::Test->new();

SKIP:
{
    $interhack->load_plugin_or_skip("Keystrokes", 2);

    $interhack->typing("foo");
    $interhack->iterate for 1..10;
    is($interhack->keystrokes, 3);

    $interhack->typing("yahoo");
    $interhack->iterate for 1..10;
    is($interhack->keystrokes, 8);
}


