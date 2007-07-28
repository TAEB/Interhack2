#!perl
use strict;
use warnings;
use Interhack::Test tests => 2;

my $interhack = Interhack::Test->new();

SKIP:
{
    $interhack->load_plugin_or_skip("Macros", 2);
    $interhack->add_macro("\ce", "E-  Elbereth\n");

    $interhack->typing("\ce");
    $interhack->iterate for 1..10;
    is($interhack->sent, "E-  Elbereth\n");

    $interhack->typing("w\ce");
    $interhack->iterate for 1..10;
    is($interhack->sent, "wE-  Elbereth\n");
}


