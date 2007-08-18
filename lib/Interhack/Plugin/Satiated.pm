#!/usr/bin/perl
package Interhack::Plugin::Satiated;
use Calf::Role;

our $VERSION = '1.99_01';

# attributes {{{
# }}}
# method modifiers {{{
around 'check_input' => sub
{
    my $orig = shift;
    my ($self, $input) = @_;

    $input = $orig->($self, $input);
    return unless defined $input;

    #XXX: this needs to be a utility function
    if ($self->vt->row_plaintext(24) =~ /Satiated/ &&
        $input =~ /^e/ && $self->expecting_command)
    {
        my $ynq = $self->force_tab_ynq("You're satiated! Press tab to eat, any other key to cancel.");
        if (!$ynq) { return }
    }

    return $input;
};
# }}}
# methods {{{
# }}}
1;

