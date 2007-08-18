#!/usr/bin/perl
package Interhack::Plugin::FloatingEye;
use Calf::Role;

our $VERSION = '1.99_01';

# attributes {{{
# }}}
# method modifiers {{{
around 'mangle_output' => sub
{
    my $orig = shift;
    my ($self, $string) = @_;

    $string =~
        s{
            (?<!\e\[1m)   # avoid coloring shocking spheres
            \e\[          # escape code initiation
            (?:0;)? 34m   # look for dark blue of floating eyes
            ((?:\x0f)? e) # look for e with or without DEC sequence
            (?!\ -\ )     # avoid false positive with menucolors
        }
        {\e[1;36m$1}xg;

    $orig->($self, $string);
};
# }}}

1;


