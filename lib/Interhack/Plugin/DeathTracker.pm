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
# }}}
# method modifiers {{{
before 'mangle_output' => sub
{
    my ($self, $text) = @_;

    for ($self->topline =~ /You kill the ([^!]+)!/g)
    {
        $self->last_turn_killed->{$1} = $self->turn;
    }
};
# }}}
# methods {{{
# }}}
1;

