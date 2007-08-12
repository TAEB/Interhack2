#!/usr/bin/perl
package Interhack::Plugin::ConfirmDirection;
use Moose::Role;

with "Interhack::Plugin::Util";

our $VERSION = '1.99_01';
our $SUMMARY = 'Disallows any invalid direction at a "In what direction?" prompt';

# attributes {{{
# }}}
# method modifiers {{{
around 'toserver' => sub
{
    my $orig = shift;
    my ($self, $text) = @_;

    if ($self->vt->y == 1 && $self->topline =~ /^In what direction\?/)
    {
        # TODO: check for vi keys or numpad
        unless ($text =~ /^[a1-9.<>]/ || $text =~ /^[ahjklyubn.<>]/)
        {
            my $force = $self->force_tab_yn("Press tab to send your invalid direction, any other key to cancel.");
            return unless $force;
        }
    }

    return $orig->($self, $text);
};
# }}}
# methods {{{
# }}}
1;

