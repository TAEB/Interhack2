#!/usr/bin/perl
package Interhack::Plugin::Macros;
use Moose::Role;

our $VERSION = '1.99_01';

# attributes {{{
has macros => (
    isa => 'HashRef',
    is => 'rw',
    lazy => 1,
    default => sub { {} },
);
# }}}
# method modifiers {{{
around 'from_user' => sub
{
    my $orig = shift;
    my ($self) = @_;

    my $c = $orig->($self);
    return if !defined($c);

    return $self->macros->{$c}
        if exists $self->macros->{$c};

    return $c;
};
# }}}
# methods {{{
sub add_macro # {{{
{
    my ($self, $trigger, $expansion) = @_;
    $self->macros->{$trigger} = $expansion;
} # }}}
# }}}
1;


