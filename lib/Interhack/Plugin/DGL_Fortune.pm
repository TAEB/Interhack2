#!/usr/bin/env perl
package Interhack::Plugin::DGL_Fortune;
use Calf::Role;

our $VERSION = '1.99_01';

# attributes {{{
has fortune => (
    per_load => 1,
    isa => 'Str',
    is => 'rw',
    lazy => 1,
    default => '',
);
# }}}
# method modifiers {{{
around 'dgl_to_user' => sub
{
    my $orig = shift;
    my ($self, $text) = @_;

    my $fortune_db = $self->fortune;
    $text .= "\e[s\e[20H\e[1;30m"
           . `fortune -n200 -s $fortune_db`
           . "\e[0m\e[u";

    return $orig->($self, $text);
};
# }}}

1;

