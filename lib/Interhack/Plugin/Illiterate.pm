#!/usr/bin/perl
package Interhack::Plugin::Illiterate;
use Moose::Role;
with "Interhack::Plugin::Util";

our $VERSION = '1.99_01';

# attributes {{{
has confirm_literacy => (
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

    if ($self->confirm_literacy && $self->expecting_command)
    {
        if ($input =~ /^([rE])/)
        {
            my $command = $1 eq 'r' ? 'read' : 'engrave';
            my $ynq = $self->force_tab_ynq("Press tab or q to $command, q to stop asking, any other key to cancel.");
            if ($ynq == 0) { return }
            if ($ynq == -1) { $self->confirm_literacy(0) }
        }
    }

    return $input;
};
# }}}
# methods {{{
# }}}
1;
