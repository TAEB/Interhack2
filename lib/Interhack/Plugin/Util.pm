#!perl
package Interhack::Plugin::Util;
use Moose::Role;
use Term::ReadKey;
use Log::Log4perl;

our $VERSION = '1.99_01';
our $SUMMARY = 'Utility functions for other plugins';

# attributes {{{
has extended_commands => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    default => sub { {} },
);

has logger => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    lazy => 1,
    default => sub
    {
        my $self = shift;
        Log::Log4perl->init($self->config_dir . "/log4perl.conf");
        Log::Log4perl->get_logger("Interhack");
    }
);
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

    my @attrs = split '', $self->vt->row_attr($row);
    my @chars = split '', $self->vt->row_plaintext($row);

    for (0..$#attrs)
    {
        my ($fg, $bg, $bold, $faint, $standout, $underline, $blink, $reverse)
            = $self->vt->attr_unpack($attrs[$_]);
        next unless $fg;

        $bold = $bold ? '1;' : '';
        my $escape = "\e[$bold${fg}m";
        $chars[$_] = $escape . $chars[$_] . "\e[m";
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

after toscreen => sub
{
    my $self = shift;

    while (my ($name, $code) = each %{$self->extended_commands})
    {
        if ($self->topline =~ /^(\Q$name\E)(?:\s+(.*?))?: unknown extended command\. *$/)
        {
            $code->($self, $1, $2);
        }
    }
};

sub extended_command
{
    my ($self, $name, $code) = @_;
    $self->extended_commands->{$name} = $code;
} # }}}
# logging {{{
sub debug
{
    my $self = shift;
    $self->logger->debug(@_);
}
sub info
{
    my $self = shift;
    $self->logger->info(@_);
}
sub warn
{
    my $self = shift;
    $self->logger->warn(@_);
}
sub error
{
    my $self = shift;
    $self->logger->error(@_);
}
sub fatal
{
    my $self = shift;
    $self->logger->fatal(@_);
}
# }}}
# }}}
1;

