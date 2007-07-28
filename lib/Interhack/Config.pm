#!/usr/bin/perl
package Interhack::Config;
use Moose;

our $VERSION = '1.99_01';

sub load_all_config
{
    my $interhack = shift;
    my @plugins = qw/Realtime Keystrokes FloatingEye TriggerReload NewGame Macros/;
    load_plugins($interhack, @plugins);
}

sub load_plugin
{
    my ($interhack, $plugin) = @_;

    my $class = "Interhack::Plugin::$plugin";
    Class::MOP::load_class($class);
    $class->meta->apply($interhack);
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

