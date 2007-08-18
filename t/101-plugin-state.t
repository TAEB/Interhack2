#!perl

{ # dummy plugin {{{
    package Interhack::Plugin::Test;
    use Calf::Role 'loaded';

    has saved => (
        is => 'rw',
        isa => 'Int',
        lazy => 1,
        default => sub { 101 },
    );

    has notsaved => (
        per_load => 1,
        is => 'rw',
        isa => 'Int',
        lazy => 1,
        default => sub { 101 },
    );

    has default_true => (
        is => 'rw',
        isa => 'Bool',
        lazy => 1,
        default => 1,
    );
    sub loaded { 1 }
} # }}}

use Interhack::Test tests => 5;

# test that plugin state is saved and loaded

{
    my $interhack = Interhack::Test->new();
    $interhack->load_plugin("Test");
    ok($interhack->loaded, "plugin loaded");

    $interhack->saved(9999);
    $interhack->notsaved(9999);
    $interhack->default_true(0);
    $interhack->cleanup;
}

{
    my $interhack = Interhack::Test->new();
    $interhack->load_plugin("Test");
    ok($interhack->loaded, "plugin loaded");

    is($interhack->saved, 9999);
    is($interhack->notsaved, 101);
    is($interhack->default_true, 0);
}

