#!/usr/bin/perl
package Interhack::Plugin::Keystrokes;
use Moose::Role;

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
around 'read_keyboard' => sub
{
    my $orig = shift;
    my ($self) = @_;

    my $c = $orig->($self);
    $self->keystrokes($self->keystrokes + length($c))
        if defined($c);
    return $c;
};

around 'toscreen' => sub
{
    my $orig = shift;
    my ($self, $text) = @_;

    my $keys = $self->keystrokes;
    $text =~ s/ S:\d+/ K:$keys/;

    $orig->($self, $text);
};

before 'cleanup' => sub
{
    my ($self) = @_;

    warn $self->keystrokes . " keystrokes this session.\n";
};
# }}}

1;

