#!perl

{
    package Interhack::Plugin::Test;
    use Moose::Role;

    sub loaded { 1 }
}

use strict;
use warnings;
use Interhack::Test tests => 3;

# test that we can load plugins OK, and things are detected to be be bad if we
# can't find a plugin

my $interhack = Interhack::Test->new();
$interhack->load_plugin_ok("Test");
ok($interhack->loaded);

TODO:
{
    local $TODO = "this is supposed to fail!";
    $interhack->load_plugin_ok("NonexistentPlugin");
}

