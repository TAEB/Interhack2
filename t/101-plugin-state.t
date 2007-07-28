#!perl

{ # dummy plugin {{{
    package Interhack::Plugin::Test;
    use Moose::Role;

    has saved => (
        is => 'rw',
        isa => 'Int',
        lazy => 1,
        default => sub { 101 },
    );

    has notsaved => (
        metaclass => 'DoNotSerialize',
        is => 'rw',
        isa => 'Int',
        lazy => 1,
        default => sub { 101 },
    );

    sub loaded { 1 }
} # }}}

use strict;
use warnings;
use Interhack::Test tests => 4;

# test that plugin state is saved and loaded

{
    my $interhack = Interhack::Test->new();
    $interhack->load_plugin("Test");
    ok($interhack->loaded, "plugin loaded");

    $interhack->saved(9999);
    $interhack->notsaved(9999);
    $interhack->cleanup;
}

{
    my $interhack = Interhack::Test->new();
    $interhack->load_plugin("Test");
    ok($interhack->loaded, "plugin loaded");

    is($interhack->saved, 9999);
    is($interhack->notsaved, 101);
}

