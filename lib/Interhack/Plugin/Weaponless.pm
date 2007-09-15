#!/usr/bin/env perl
package Interhack::Plugin::Weaponless;
use Calf::Role;

our $VERSION = '1.99_01';

# attributes {{{
has confirm_wield => (
    isa => 'Bool',
    lazy => 1,
    default => 1,
);
# }}}
# method modifiers {{{
guard 'check_input' => sub
{
    my ($self, $input) = @_;
    return 1 if !defined($input);

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

    return 1;
};
# }}}
# methods {{{
# }}}
1;

