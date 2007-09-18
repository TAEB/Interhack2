#!/usr/bin/env perl
package Interhack::Plugin::InGame::ConfirmDirection;
use Calf::Role;

our $VERSION = '1.99_01';
our $SUMMARY = 'Disallows any invalid direction at a "In what direction?" prompt';

# deps {{{
sub depend { 'Util' }
# }}}
# attributes {{{
# }}}
# method modifiers {{{
guard 'to_nethack' => sub
{
    my ($self, $text) = @_;
    return 1 if !defined($text);

    if ($self->vt->y == 1 && $self->topline =~ /^In what direction\?/)
    {
        # TODO: check for vi keys or numpad
        unless ($text =~ /^[\e\n1-9.<>]/ || $text =~ /^[\e\nhjklyubn.<>]/)
        {
            my $force = $self->force_tab_yn("Press tab to send your invalid direction, any other key to cancel.");
            return unless $force;
        }
    }

    return 1;
};
# }}}
# methods {{{
# }}}
1;

