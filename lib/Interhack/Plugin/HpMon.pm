#!/usr/bin/env perl
package Interhack::Plugin::HpMon;
use Calf::Role;

our $VERSION = '1.99_01';

# attributes {{{
# }}}
# private methods {{{
sub get_color {
    my ($curhp, $maxhp) = @_;
    my $color = "";

       if ($curhp * 7 <= $maxhp || $curhp <= 5) { $color = "\e[1;30m" }
    elsif ($curhp     >= $maxhp)                { $color = ""         }
    elsif ($curhp * 2 >= $maxhp)                { $color = "\e[1;32m" }
    elsif ($curhp * 3 >= $maxhp)                { $color = "\e[1;33m" }
    elsif ($curhp * 4 >= $maxhp)                { $color = "\e[0;31m" }
    else                                        { $color = "\e[1;31m" }

    return $color;
}

sub strip_color {
    my ($text) = @_;

    # XXX: necessary?
    #$text =~ s/\e[\d+(?:;\d+)m(.*?)\e[0m/$1/;
    return $text;
}

sub update_botl {
    my $self = shift;
    return if @_ == 0;

    $self->botl_stats->{hp} = get_color($self->hp, $self->maxhp) . strip_color($self->botl_stats->{hp}) . "\e[0m";
}
# }}}
# method modifiers {{{
after 'hp' => \&update_botl;
after 'maxhp' => \&update_botl;
# }}}

1;
