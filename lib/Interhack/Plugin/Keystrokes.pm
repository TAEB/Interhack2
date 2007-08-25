#!/usr/bin/env perl
package Interhack::Plugin::Keystrokes;
use Calf::Role;

our $VERSION = '1.99_01';

# attributes {{{
has keystrokes => (
    isa => 'Int',
    is => 'rw',
    lazy => 1,
    default => 0,
);
# }}}
# method modifiers {{{
around 'to_nethack' => sub
{
    my $orig = shift;
    my ($self, $text) = @_;

    $self->keystrokes($self->keystrokes + length($text));

    return $orig->($self, $text);
};

before 'cleanup' => sub
{
    my ($self) = @_;

    warn $self->keystrokes . " keystrokes this session.\n";
};
# }}}

1;

