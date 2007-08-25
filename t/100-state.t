#!/usr/bin/env perl
use Interhack::Test tests => 2;

{
    my $interhack = Interhack::Test->new();
    $interhack->test_attribute($$);
    $interhack->unsaved_attribute(23432);

    $interhack->cleanup();
}

{
    my $interhack = Interhack::Test->new();
    $interhack->load_state();
    is($interhack->test_attribute, $$);
    is($interhack->unsaved_attribute, 12321);
}

