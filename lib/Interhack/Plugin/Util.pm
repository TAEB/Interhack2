#!perl
package Interhack::Plugin::Util;
use Moose::Role;
use Term::ReadKey;

our $VERSION = '1.99_01';
our $SUMMARY = 'Utility functions for other plugins';

# attributes {{{
# }}}
# method modifiers {{{
# }}}
# methods {{{
# print_row # {{{
=head2 print_row INT, STRING[, BOOLEAN]

Prints the specified string on the specified row of the terminal. The row is
1-based. The optional boolean specifies whether to save and reload the cursor
position (which is the default, false). A true value will let you the caller
deal with it (please be careful).

=cut

sub print_row
{
    my $self = shift;
    my $row = shift;
    my $text = shift;
    my $leave_cursor = shift;

    print "\e[s" unless $leave_cursor;
    print "\e[${row}H$text";
    print "\e[u" unless $leave_cursor;
    return;
} # }}}
# force_tab_yn {{{
=head2 force_tab_yn STRING -> BOOLEAN

Forces the user to press tab to mean "yes" (which will return 1) or any other
key (which will return 0). The string argument will be displayed to the user
in red on the second line of the terminal.

=cut

sub force_tab_yn
{
    my $self = shift;
    my $input = shift;

    $self->print_row(2, "\e[1;31m$input\e[m");
    my $c = ReadKey 0;
    $self->print_row(2, "\e[K");
    return $c eq "\t" ? 1 : 0;
} # }}}
# }}}
1;

