#!perl

{ # dummy plugins {{{
    package Interhack::Plugin::Test;
    use Calf::Role 'loaded';

    sub loaded { 1 }
    around 'recvd' => sub { my ($orig, $self) = @_; '1' . $orig->($self ) };
}

{
    package Interhack::Plugin::Test2;
    use Calf::Role 'loaded2';

    sub loaded2 { 1 }
    around 'recvd' => sub { my ($orig, $self) = @_; '2' . $orig->($self ) };
} # }}}

use Interhack::Test tests => 9;

# test that we can load plugins OK, and things are detected to be be bad if we
# can't find a plugin
# also make sure we can load plugins in different orders, even in the same app

my $interhack = Interhack::Test->new();

SKIP:
{
    $interhack->load_plugin_or_skip("Test", 2);
    ok($interhack->loaded, "new method mixed in");

    $interhack->recv("foo");
    $interhack->iterate();
    is($interhack->recvd, "1foo", "method modifier worked");
}

SKIP:
{
    $interhack->load_plugin_or_skip("NonexistentPlugin", 1);
    ok($interhack->eat_flaming_death, "THIS SHOULD NEVER BE RUN");
}

SKIP:
{
    $interhack = Interhack::Test->new();
    $interhack->load_plugin_or_skip("Test", 3);
    $interhack->load_plugin_or_skip("Test2", 3);
    ok($interhack->loaded);
    ok($interhack->loaded2);

    $interhack->recv("bar");
    $interhack->iterate();

    my $recvd = $interhack->recvd;
    diag "plugins are being applied multiple times"
        if $recvd =~ /[21]{3}/;

    is($recvd, "21bar", "Test2 wraps Test's modifiers");
}

SKIP:
{
    $interhack = Interhack::Test->new();
    $interhack->load_plugin_or_skip("Test2", 3);
    $interhack->load_plugin_or_skip("Test", 3);
    ok($interhack->loaded);
    ok($interhack->loaded2);

    $interhack->recv("baz");
    $interhack->iterate();
    is($interhack->recvd, "12baz", "Test wraps Test2's modifiers");
}
