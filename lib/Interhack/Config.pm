#!/usr/bin/perl
package Interhack::Config;
use Moose;

our $VERSION = '1.99_01';
our %loaded_plugins;

sub load_all_config
{
    my $interhack = shift;
    my @plugins = qw/Realtime Keystrokes FloatingEye TriggerReload NewGame Macros ConfirmDirection/;
    load_plugins($interhack, @plugins);
}

sub load_plugin
{
    my ($interhack, $plugin) = @_;

    return if $loaded_plugins{$plugin};

    my $class = "Interhack::Plugin::$plugin";
    my $package = blessed $interhack;

    {
        package Interhack;
        with $class;
    }

    #$package->meta->add_role($class->meta);
    $loaded_plugins{$plugin} = 1;
}

sub load_plugins
{
    my ($interhack) = shift;
    my $loaded = 0;

    for my $plugin (@_)
    {
        eval { load_plugin($interhack, $plugin) };
        ++$loaded if !$@;
    }

    return $loaded;
}

1;

