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
# vt_like {{{
=head2 vt_like REGEXES -> INT

Returns whether any line of text on the VT (which is exactly the output from
NAO) matches any of the regular expressions. The return value will be the row
with the smallest index which matched. If there was no match, zero will be
returned.

=cut

sub vt_like
{
    my $self = shift;

    for my $row (1..24)
    {
        for my $regex (@_)
        {
            return $row if $self->vt->row_plaintext($row) =~ $regex;
        }
    }
    return 0;
} # }}}
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
# restore_row {{{
=head2 restore_row INT

Restores the contents of the row as best as possible. Use this if you're drawing
on the screen temporarily (such as with force_tab_yn).

=cut

sub restore_row
{
    my $self = shift;
    my $row = shift;

    # not so good yet! but at least now we have only one place to fix it
    $self->print_row(2, "\e[K");
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
    $self->restore_row(2);
    return $c eq "\t" ? 1 : 0;
} # }}}
# }}}
1;

