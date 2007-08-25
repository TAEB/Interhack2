#!/usr/bin/env perl
package Interhack::Plugin::Foodless;
use Calf::Role;

our $VERSION = '1.99_01';

# attributes {{{
has confirm_eat => (
    isa => 'Bool',
    is => 'rw',
    lazy => 1,
    default => 1,
);
# }}}
# method modifiers {{{
around 'check_input' => sub
{
    my $orig = shift;
    my ($self, $input) = @_;

    $input = $orig->($self, $input);
    return unless defined $input;

    if ($self->confirm_eat && $input =~ /^e/ && $self->expecting_command)
    {
        my $ynq = $self->force_tab_ynq("Press tab or q to eat, q to stop asking, any other key to cancel.");
        if ($ynq == 0) { return }
        if ($ynq == -1)
        {
            $self->debug("Disabled 'eat' confirmations.");
            $self->confirm_eat(0);
        }
    }

    return $input;
};
# }}}
# methods {{{
# }}}
1;

