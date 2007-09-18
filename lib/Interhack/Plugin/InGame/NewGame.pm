#!/usr/bin/env perl
package Interhack::Plugin::InGame::NewGame;
use Calf::Role;

our $VERSION = '1.99_01';

# deps {{{
sub depend { 'Debug' }
# }}}
# attributes {{{
has in_game => (
    per_load => 1,
    isa => 'Bool',
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
            $self->load_state();
            $self->in_game(1);
        }
    }
};
# }}}

1;

