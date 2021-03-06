#!/usr/bin/env perl
package Interhack::Plugin::InGame::Foodless;
use Calf::Role;

our $VERSION = '1.99_01';

# deps {{{
sub depend { qw/Debug Util/ }
# }}}
# attributes {{{
has confirm_eat => (
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

    return 1;
};
# }}}
# methods {{{
# }}}
1;

