#!/usr/bin/env perl
use Interhack::Test tests => 6;

my $interhack = Interhack::Test->new();

SKIP:
{
    $interhack->load_plugin_or_skip("FloatingEye", 6);

    for my $input ("\e[34me", "\e[0;34me")
    {
        (my $escaped = $input) =~ s/\e/\\e/;

        $interhack->recv($input);
        $interhack->iterate();
        is($interhack->recvd, "\e[1;36me", "transformed basic $escaped");
    }

    $interhack->recv("\e[1;34me");
    $interhack->iterate();
    is($interhack->recvd, "\e[1;34me", "didn't transform shocking sphere");

    $interhack->recv("foobar\e[34me\e[mbaz");
    $interhack->iterate();
    is($interhack->recvd, "foobar\e[1;36me\e[mbaz", "transformed within a string");

    $interhack->recv("\e[34me - dinner\e[m");
    $interhack->iterate();
    is($interhack->recvd, "\e[34me - dinner\e[m", "didn't transform what looks like a menucolored item");

    $interhack->recv("\x0eqqqq\e[\e[34m\x0fe\x0e\e[mqqqq\x0f");
    $interhack->iterate();
    is($interhack->recvd, "\x0eqqqq\e[\e[1;36m\x0fe\x0e\e[mqqqq\x0f", "transformed even with DEC on");
}

