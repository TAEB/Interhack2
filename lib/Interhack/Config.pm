#!/usr/bin/perl
package Interhack::Config;
use Moose;

our $VERSION = '1.99_01';
our %loaded_plugins;

sub load_all_config
{
    do
    {
        package Interhack;

        for my $plugin (qw/Realtime Keystrokes FloatingEye TriggerReload NewGame/)
        {
            with "Interhack::Plugin::$plugin"
                unless $loaded_plugins{$plugin}++;
        }
    };
}

1;

