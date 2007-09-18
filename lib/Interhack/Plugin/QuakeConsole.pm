#!/usr/bin/env perl
package Interhack::Plugin::QuakeConsole;
use Calf::Role;
use Term::ReadKey;

our $VERSION = '1.99_01';

# deps {{{
sub depend
{
    my @deps = qw/Util/;
    return \@deps;
}
# }}}
# attributes {{{
# }}}
# method modifiers {{{
around 'check_input' => sub
{
    my $orig = shift;
    my ($self, $input) = @_;

    $input = $orig->($self, $input);
    return unless defined $input;
    return $input unless $input =~ /^~/ && $self->expecting_command;

    ReadMode 0;
    my ($x, $y) = ($self->vt->x, $self->vt->y);

    for (1..12)
    {
        $self->print_row($_, "\e[K");
    }
    for (14..24)
    {
        $self->restore_row($_, "\e[1;30m");
    }

    $self->print_row(13, "\e[K"
                       . "\e[1;37m+"
                       . "\e[1;30m" . ('-' x 50)
                       . "\e[1;37m[ "
                       . "\e[1;36mI\e[0;36mnterhack \e[1;36mC\e[0;36monsole"
                       . " \e[1;37m]"
                       . "\e[1;30m" . ('-' x 7)
                       . "\e[1;37m+"
                       . "\e[m");

    $self->to_user("\e[1;12r\e[12;1H");
    while (1)
    {
        $self->to_user("> ");
        my $line = <>;
        last if !defined($line);
        chomp $line;
        last if $line eq ":q";
        next if $line =~ /^\s*$/;

        my $ret;

        if ($line =~ /^#(\S+)(?:\s+(.*?))?$/)
        {
            if (exists $self->extended_commands->{$1})
            {
                if ($1 eq "reload")
                {
                    $ret = "Do NOT use #reload in the console!";
                }
                else
                {
                    $ret = $self->extended_commands->{$1}->($self, $1, $2);
                }
            }
            else
            {
                $ret = "Unknown extended command: $1.";
            }
            eval {}; # clear $@
        }
        else
        {
            $ret = eval $line;
        }

        $ret = "undef" if !defined($ret);
        $self->to_user("\e[32m$ret\e[m\n");
        warn "\e[31m$@\e[m\n" if $@;
    }

    $self->to_user("\ec"); # remove scrolling

    ReadMode 3;

    for (1..24)
    {
        $self->restore_row($_);
    }
    $self->goto($x, $y);

    return;
};
# }}}
# methods {{{
# }}}
1;

