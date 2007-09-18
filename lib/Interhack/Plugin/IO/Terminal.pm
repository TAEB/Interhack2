#!/usr/bin/env perl
package Interhack::Plugin::IO::Terminal;
use Calf::Role qw/to_user from_user/;
use Term::ReadKey;

our $VERSION = '1.99_01';

# attributes {{{
# }}}
# methods {{{
sub to_user # {{{
{
    my $self = shift;
    my ($text) = @_;

    print $text;
} # }}}
sub from_user # {{{
{
    my $self = shift;
    ReadKey 0.05;
} # }}}
# }}}
# method modifiers {{{
# }}}

1;
