#!/usr/bin/env perl
package Interhack::Plugin::InGame::Macros;
use Calf::Role 'add_macro';

our $VERSION = '1.99_01';

# attributes {{{
has macros => (
    isa => 'HashRef',
    per_load => 1,
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
sub BUILD # {{{
{
    my $self = shift;

    while (my ($trigger, $expansion) = each %{$self->config->{plugin_options}{Macros}})
    {
        $self->add_macro($trigger, $expansion);
    }
} # }}}
sub add_macro # {{{
{
    my ($self, $trigger, $expansion) = @_;
    $trigger = chr(ord(uc $1)-ord("A")+1) if $trigger =~ /\^(.)/;
    $self->macros->{$trigger} = $expansion;
} # }}}
# }}}
1;


