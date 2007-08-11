#!/usr/bin/perl
package Interhack::Plugin::NewGame;
use Moose::Role;

our $VERSION = '1.99_01';

# attributes {{{
has in_game => (
    metaclass => 'DoNotSerialize',
    isa => 'Bool',
    is => 'rw',
    lazy => 1,
    default => 0,
);
# }}}
# method modifiers {{{
after 'toscreen' => sub
{
    my ($self, $string) = @_;

    if (!$self->in_game)
    {
        if ($self->topline =~ /^\w+ \w+, welcome to NetHack!  You are a/)
        {
            $self->new_state();
            $self->in_game(1);
        }
        elsif ($self->topline =~ /^\w+ \w+, the.*?, welcome back to NetHack!/)
        {
            $self->new_state();
            $self->in_game(1);
        }
    }
};
# }}}

1;

