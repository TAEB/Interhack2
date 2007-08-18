#!/usr/bin/perl
package Interhack::Plugin::NewGame;
use Calf::Role;

our $VERSION = '1.99_01';

# attributes {{{
has in_game => (
    per_load => 1,
    isa => 'Bool',
    is => 'rw',
    lazy => 1,
    default => 0,
);
# }}}
# method modifiers {{{
before 'mangle_output' => sub
{
    my ($self, $string) = @_;

    if (!$self->in_game)
    {
        if ($self->topline =~ /^\w+ \w+(?: \w+)?, welcome to NetHack!  You are a/)
        {
            $self->debug("New game detected!");
            $self->new_state();
            $self->in_game(1);
        }
        elsif ($self->topline =~ /^\w+ \w+(?: \w+)?, the.*?, welcome back to NetHack!/)
        {
            $self->debug("Existing game detected!");
            $self->in_game(1);
        }
    }
};
# }}}

1;

