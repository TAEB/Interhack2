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
        print "\n> ";
        my $line = <>;
        last if !defined($line);
        print eval $line;
        warn $@ if $@;
    }
    print "\ec";

    ReadMode 3;

    return "\cr";
};
# }}}
# methods {{{
# }}}
1;

