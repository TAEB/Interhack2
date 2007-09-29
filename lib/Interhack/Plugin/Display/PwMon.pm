#!/usr/bin/env perl
package Interhack::Plugin::Display::PwMon;
use Calf::Role;

our $VERSION = '1.99_01';

# deps {{{
sub depend { 'Status' }
# }}}
# attributes {{{
# }}}
# private methods {{{
sub get_color { # {{{
    my ($curpw, $maxpw) = @_;
    my $color = "";

       if ($curpw     >= $maxpw) {                     }
    elsif ($curpw * 2 >= $maxpw) { $color = "\e[1;36m" }
    elsif ($curpw * 3 >= $maxpw) { $color = "\e[1;35m" }
    else                         { $color = "\e[0;35m" }

    return $color;
} # }}}
sub update_botl { # {{{
    my $self = shift;
    return if @_ == 0;

    my $color = get_color($self->pw, $self->maxpw);

    $self->botl_stats->{pwcol} = $color;
    $self->botl_stats->{pw} = $color . $self->botl_stats->{pw} . "\e[0m";
} # }}}
# }}}
# method modifiers {{{
after 'pw' => \&update_botl;
after 'maxpw' => \&update_botl;
# }}}

1;

