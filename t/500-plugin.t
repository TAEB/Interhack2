#!perl

{
    package Interhack::Plugin::Test;
    use Moose::Role;

    sub loaded { 1 }
}

use strict;
use warnings;
use Interhack::Test tests => 2;

# test that we can load plugins OK, and things are detected to be be bad if we
# can't find a plugin

my $interhack = Interhack::Test->new();

SKIP:
{
    $interhack->load_plugin_or_skip("Test", 1);
    ok($interhack->loaded);
}

SKIP:
{
    $interhack->load_plugin_or_skip("NonexistentPlugin", 1);
    ok($interhack->eat_flaming_death);
}

