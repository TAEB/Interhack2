#!/usr/bin/perl
package Interhack::Plugin::NewGame;
use Moose::Role;

our $VERSION = '1.99_01';

# attributes {{{
# }}}
# method modifiers {{{
after 'toscreen' => sub
{
    my ($self, $string) = @_;

    if ($self->topline =~ /^\w+ \w+, welcome to NetHack!  You are a/)
    {
        $self->new_state();
    }
};
# }}}

1;

