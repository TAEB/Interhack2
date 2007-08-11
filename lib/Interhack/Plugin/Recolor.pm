#!/usr/bin/perl
package Interhack::Plugin::Recolor;
use Moose::Role;

our $VERSION = '1.99_01';

our %colormap = # {{{
(
    # the color NH uses as black.. dark blue most of the time, but you
    # can override it with \e[1;30m if you want the real thing
    nhblack        => "\e[0;34m",

    black          => "\e[0;30m",
    bblack         => "\e[1;30m",
    "bold&black"   => "\e[1;30m",
    "black&bold"   => "\e[1;30m",
    bblack         => "\e[1;30m",
    darkgray       => "\e[1;30m",
    darkgrey       => "\e[1;30m",

    red            => "\e[0;31m",
    bred           => "\e[1;31m",
    "bold&red"     => "\e[1;31m",
    "red&bold"     => "\e[1;31m",
    orange         => "\e[1;31m",

    green          => "\e[0;32m",
    bgreen         => "\e[1;32m",
    "bold&green"   => "\e[1;32m",
    "green&bold"   => "\e[1;32m",

    brown          => "\e[0;33m",
    bbrown         => "\e[1;33m",
    "bold&brown"   => "\e[1;33m",
    "brown&bold"   => "\e[1;33m",
    yellow         => "\e[1;33m",
    darkyellow     => "\e[1;33m",

    blue           => "\e[0;34m",
    bblue          => "\e[1;34m",
    "bold&blue"    => "\e[1;34m",
    "blue&bold"    => "\e[1;34m",

    purple         => "\e[0;35m",
    bpurple        => "\e[1;35m",
    "bold&purple"  => "\e[1;35m",
    "purple&bold"  => "\e[1;35m",
    magenta        => "\e[0;35m",
    bmagenta       => "\e[1;35m",
    "bold&magenta" => "\e[1;35m",
    "magenta&bold" => "\e[1;35m",

    cyan           => "\e[0;36m",
    bcyan          => "\e[1;36m",
    "bold&cyan"    => "\e[1;36m",
    "cyan&bold"    => "\e[1;36m",

    white          => "\e[0;37m",
    bwhite         => "\e[1;37m",
    gray           => "\e[0;37m",
    grey           => "\e[0;37m",
    "bold&white"   => "\e[1;37m",
    "white&bold"   => "\e[1;37m",
); # }}}

# attributes {{{
has recolors => (
    metaclass => 'DoNotSerialize',
    isa => 'ArrayRef',
    is => 'rw',
    lazy => 1,
    default => sub { [] },
);
# }}}
# method modifiers {{{
around 'toscreen' => sub
{
    my $orig = shift;
    my ($self, $string) = @_;

    for (@{$self->recolors})
    {
        $string =~ s/($_->[0])/$_->[1]$1\e[m/g;
    }

    $orig->($self, $string);
};
# }}}
# methods {{{
sub recolor # {{{
{
    my ($self, $regex, $newcolor) = @_;
    push @{$self->recolors}, [ $regex => color_to_escape($newcolor) ];
} # }}}
sub color_to_escape # {{{
{
    my $color = shift;
    return $colormap{$color} || $color;
} # }}}
# }}}

1;

