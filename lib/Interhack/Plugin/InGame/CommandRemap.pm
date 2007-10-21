#!/usr/bin/env perl
package Interhack::Plugin::InGame::CommandRemap;
use Calf::Role 'add_remap';

our $VERSION = '1.99_01';

# deps {{{
sub depend { qw/Util/ }
# }}}
# attributes {{{
has remappings => (
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

    if ($self->expecting_command && exists $self->remappings->{$c})
    {
        $c = $self->remappings->{$c};
    }

    return $c;
};
# }}}
# methods {{{
sub BUILD # {{{
{
    my $self = shift;

    while (my ($trigger, $expansion) = each %{$self->config->{plugin_options}{COmmandRemap}})
    {
        $self->add_remap($trigger, $expansion);
    }
} # }}}
sub add_remap # {{{
{
    my ($self, $trigger, $expansion) = @_;
    $trigger = chr(ord(uc $1)-ord("A")+1) if $trigger =~ /\^(.)/;
    $self->remappings->{$trigger} = $expansion;
} # }}}
# }}}

1;

