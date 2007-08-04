#!/usr/bin/perl
package Interhack::Plugin::ConfirmDirection;
use Moose::Role;

our $VERSION = '1.99_01';
our $SUMMARY = 'Disallows any invalid direction at a "In what direction?" prompt';

# attributes {{{
# }}}
# method modifiers {{{
around 'tonao' => sub
{
    my $orig = shift;
    my ($self, $text) = @_;

    if ($self->topline =~ /^In what direction\?/)
    {
        # TODO: check for vi keys or numpad
        # TODO: this wants to be a force_tab_yn
        return unless $text =~ /^[a1-9.<>]/ || $text =~ /^[ahjklyubn.<>]/;
    }

    return $orig->($self, $text);
};
# }}}
# methods {{{
# }}}
1;

