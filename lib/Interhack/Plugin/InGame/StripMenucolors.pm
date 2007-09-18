#!/usr/bin/env perl
package Interhack::Plugin::InGame::StripMenucolors;
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
            \e\[     # escape code starter
            [0-9;]*  # any amount of colorcodes
            m        # color command

            (        # capture the first few chars of the item
                \ ?  # match a space, maybe (most menus have one)
                .    # the slot indicator of the item
                \    # literal space
                -
                \    # literal space
            )
        }
        {\e[0m$1}xg;

    $orig->($self, $string);
};
# }}}

1;
