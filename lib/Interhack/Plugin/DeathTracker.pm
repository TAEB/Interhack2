#!/usr/bin/env perl
package Interhack::Plugin::DeathTracker;
use Calf::Role;

our $VERSION = '1.99_01';

# attributes {{{
has last_turn_killed => (
    isa => 'HashRef',
    is => 'rw',
    default => sub { {} },
);
has kills => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);
# }}}
# method modifiers {{{
before 'mangle_output' => sub
{
    my ($self, $text) = @_;

    for ($self->topline =~ /You kill the ([^!]+)!/g)
    {
        $self->kills($self->kills + 1);
        $self->last_turn_killed->{$1} = $self->turn;
    }
};
# }}}
# methods {{{
# }}}
1;

