#!/usr/bin/perl
package Interhack::Config;
use Moose;

our $VERSION = '1.99_01';

sub load_all_config
{
    do
    {
        package Interhack;
        with "Interhack::Plugin::$_"
            for qw/Realtime Keystrokes FloatingEye/;
    };
}

1;

