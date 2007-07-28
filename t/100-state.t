#!perl
use strict;
use warnings;
use Interhack::Test tests => 2;

{
    my $interhack = Interhack::Test->new();
    $interhack->test_attribute($$);
    $interhack->unsaved_attribute(23432);
}

{
    my $interhack = Interhack::Test->new();
    is($interhack->test_attribute, $$);
    is($interhack->unsaved_attribute, 12321);
}

