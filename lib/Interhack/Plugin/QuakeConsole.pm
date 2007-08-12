#!/usr/bin/perl
package Interhack::Plugin::QuakeConsole;
use Moose::Role;
use Term::ReadLine;
use Term::ReadKey;
with "Interhack::Plugin::Util";

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
    return $input unless $self->expecting_command && $input =~ /^~/;

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

    $self->print_row(13, "\e[K\e[1;30m+" . ('-' x 78) . "+\e[m");
    print "\e[1;12r\e[12;1H";
    while (1)
    {
        print "> ";
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
        }
        else
        {
            $ret = eval $line;
        }

        $ret = "undef" if !defined($ret);
        print "\e[32m$ret\e[m\n";
        warn "\e[31m$@\e[m\n" if $@;
    }
    print "\ec";

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

