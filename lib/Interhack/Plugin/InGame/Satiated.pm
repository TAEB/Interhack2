#!/usr/bin/env perl
package Interhack::Plugin::InGame::Satiated;
use Calf::Role;

our $VERSION = '1.99_01';

# deps {{{
sub depend { [qw/Util/] }
# }}}
# attributes {{{
# }}}
# method modifiers {{{
guard 'check_input' => sub
{
    my ($self, $input) = @_;
    return 1 if !defined($input);

    #XXX: this needs to be a utility function
    if ($self->vt->row_plaintext(24) =~ /Satiated/ &&
        $input =~ /^e/ && $self->expecting_command)
    {
        my $ynq = $self->force_tab_ynq("You're satiated! Press tab to eat, any other key to cancel.");
        if (!$ynq) { return }
    }

    return 1;
};
# }}}
# methods {{{
# }}}
1;

