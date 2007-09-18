#!/usr/bin/env perl
package Interhack::Plugin::InGame::Util;
use Calf::Role qw/goto vt_like print_row restore_row force_tab_yn force_tab_ynq 
                  expecting_command extended_command attr_to_ansi/;
use Term::ReadKey;

our $VERSION = '1.99_01';
our $SUMMARY = 'Utility functions for other plugins';

# deps {{{
sub depend { 'NewGame' }
# }}}
# attributes {{{
has extended_commands => (
    per_load => 1,
    isa => 'HashRef',
    lazy => 1,
    default => sub { {} },
);
# }}}
# method modifiers {{{
# }}}
# methods {{{
# goto {{{
=head2 goto X, Y

Moves the cursor to the given (X, Y) coordinates. Like everything else dealing
with the screen, use 1-based coordinates.

=cut

sub goto
{
    my ($self, $x, $y) = @_;
    $self->to_user("\e[$y;${x}H");
}
# }}}
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

    $self->to_user("\e[s") unless $leave_cursor;
    $self->to_user("\e[${row}H$text");
    $self->to_user("\e[u") unless $leave_cursor;
    return;
} # }}}
# restore_row {{{
=head2 restore_row INT, COLOR

Restores the contents of the row as best as possible. Use this if you're drawing
on the screen temporarily (such as with force_tab_yn).

If the second argument is true, it will force all characters to be that color.
You may pass a code reference here and it will be invoked for every screen
coordinate (it's given the arguments C<$self>, C<$x>, C<$y>, and C<$char>).
It must return the C<$char> to use in that cell.

=cut

sub restore_row
{
    my $self = shift;
    my $row = shift;
    my $color = shift;

    if (ref($color) eq 'CODE')
    {
        my @chars = split //, $self->vt->row_plaintext($row);
        for (0..$#chars)
        {
            $chars[$_] = $color->($self, 1+$_, $row, $chars[$_]);
        }
        $self->print_row($row, "\e[K" . join('', @chars) . "\e[m");
        return;
    }
    elsif ($color)
    {
        $self->print_row($row, "\e[K$color"
                             . $self->vt->row_plaintext($row)
                             . "\e[m");
        return;
    }

    my @attrs = $self->vt->row_attr($row) =~ /../g;
    my @chars = split '', $self->vt->row_plaintext($row);

    for (0..$#attrs)
    {
        my %attr;
        @attr{qw/fg bg bold faint standout underline blink reverse/}
            = $self->vt->attr_unpack($attrs[$_]);
        $chars[$_] = $self->attr_to_ansi(%attr) . $chars[$_];
    }

    # not so good yet! but at least now we have only one place to fix it
    $self->print_row($row, "\e[K" . join '', @chars);
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
# force_tab_ynq {{{
=head2 force_tab_ynq STRING -> BOOLEAN

Forces the user to press tab to mean "yes" (which will return 1) or any other
key (which will return 0). The string argument will be displayed to the user
in red on the second line of the terminal.

If the user types 'q' the special value -1 will be returned.

=cut

sub force_tab_ynq
{
    my $self = shift;
    my $input = shift;

    $self->print_row(2, "\e[1;31m$input\e[m");
    my $c = ReadKey 0;
    $self->restore_row(2);
    return $c eq "\t" ? 1 : $c eq "q" ? -1 : 0;
} # }}}
# expecting_command {{{
=head2 expecting_command -> BOOLEAN

Returns 1 if the game is expecting a new command. This is at best a guess.

=cut

sub expecting_command
{
    my $self = shift;
    return 0 if !$self->in_game;
    return 0 if $self->vt->y == 1;
    return 0 if $self->vt_like(qr/--More--/, qr/\(\d+ of \d+\)/, qr/\(end\)/);
    return 1;
} # }}}
# extended_command {{{
=head2 extended_command name, code

Lets you define new extended commands. If the user types in your extended
command, the coderef will be run.

Extended commands can have arguments. The first argument passed to an extended
command is the Interhack object. The second is exactly what the user typed to
trigger it (so the command name). The third is everything that came after the
second argument.

Only one coderef may be associated with an extended command. Extended commands
that share names with those in NetHack will never be run. Do not depend on
case.

=cut

after to_user => sub
{
    my $self = shift;

    if ($self->topline =~ /^(\S+)(?:\s+(.*?))?: unknown extended command\. *$/)
    {
        if (exists $self->extended_commands->{$1})
        {
            $self->extended_commands->{$1}->($self, $1, $2);
        }
    }
};

sub extended_command
{
    my ($self, $name, $code) = @_;

    if (ref($code) ne "CODE")
    {
        $self->warn("Second argument to extended_command must be a sub.");
        return;
    }

    $self->extended_commands->{$name} = $code;
} # }}}
sub attr_to_ansi # {{{
{
    my $self = shift;
    my %args = @_;

    my $fg = 3 . ($args{fg} || 7);
    $fg =~ s/^3(3.)/$1/;

    my $bg = 4 . ($args{bg} || 0);
    $bg =~ s/^4(4.)/$1/;

    my $color = "\e[0";
    $color .= ";1" if $args{bold};
    $color .= ";2" if $args{faint};
    $color .= ";3" if $args{standout};
    $color .= ";4" if $args{underline};
    $color .= ";5" if $args{blink};
    $color .= ";7" if $args{reverse};

    $color .= ";$fg" if $fg != 37;
    $color .= ";$bg" if $bg != 40;

    return $color . 'm';
} # }}}
# }}}

1;

