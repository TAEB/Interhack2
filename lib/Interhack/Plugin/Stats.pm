#!/usr/bin/env perl
package Interhack::Plugin::Stats;
use Calf::Role;

our $VERSION = '1.99_01';

# attributes {{{
has turn => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);
# }}}
# method modifiers {{{
before 'mangle_output' => sub
{
    my ($self, $text) = @_;

    if ($self->vt->row_plaintext(24) =~ /\bT:(\d+)\b/)
    {
        $self->turn($1);
    }
};
# }}}
# methods {{{
# }}}
1;

