#!/usr/bin/perl
package Interhack::Plugin::Weaponless;
use Moose::Role;

our $VERSION = '1.99_01';

# attributes {{{
has confirm_wield => (
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

    if ($self->confirm_wield && $input =~ /^w/ && $self->expecting_command)
    {
        my $ynq = $self->force_tab_ynq("Press tab or q to wield, q to stop asking, any other key to cancel.");
        if ($ynq == 0) { return }
        if ($ynq == -1)
        {
            $self->debug("Disabled 'wield' confirmations.");
            $self->confirm_wield(0)
        }
    }

    return $input;
};
# }}}
# methods {{{
# }}}
1;

