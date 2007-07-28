#!/usr/bin/perl
package Interhack::Config;
use Moose;

our $VERSION = '1.99_01';

my %loaded_plugins;

sub load_all_config
{
    my $interhack = shift;
    my @plugins = qw/Realtime Keystrokes FloatingEye TriggerReload NewGame Macros/;
    load_plugins($interhack, @plugins);
}

sub load_plugins
{
    my ($interhack) = shift;
    my $loaded = 0;

    for my $plugin (@_)
    {
        my $class = "Interhack::Plugin::$plugin";

        if (!$loaded_plugins{$plugin})
        {
            eval { require "Interhack/Plugin/$plugin.pm" }
        }

        eval { $class->meta->apply($interhack) };
        next if $@;

        $loaded_plugins{$plugin} = 1;
        ++$loaded;
    }

    return $loaded;
}

1;

