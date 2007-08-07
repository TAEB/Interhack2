#!/usr/bin/perl
package Interhack::Plugin::Foodless;
use Moose::Role;
with "Interhack::Plugin::Util";

our $VERSION = '1.99_01';

# attributes {{{
has confirmeat => (
    isa => 'Int', # XXX MooseX::Storage 0.05 (current) can't handle Bool
    is => 'rw',
    lazy => 1,
    default => 0,
);
# }}}
# method modifiers {{{
around 'check_input' => sub
{
    my $orig = shift;
    my ($self, $input) = @_;

    $input = $orig->($self, $input);
    return unless defined $input;

    if ($self->confirmeat && $self->expecting_command && $input =~ /^e/)
    {
        my $ynq = $self->force_tab_ynq("Press tab or q to eat, q to stop asking, any other key to cancel.");
        if ($ynq == 0) { return }
        if ($ynq == -1) { $self->confirmeat(0) }
    }

    return $input;
};
# }}}
# methods {{{
# }}}
1;

