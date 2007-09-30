#!/usr/bin/env perl
package Interhack::Plugin::PreGame::DGL_Fortune;
use Calf::Role;

our $VERSION = '1.99_01';

# deps {{{
sub depend { 'DGameLaunch' }
# }}}
# attributes {{{
has fortune => (
    per_load => 1,
    isa => 'Str',
    lazy => 1,
    default => '',
);
# }}}
# private variables {{{
my $prev_screen = '';
# }}}
# method modifiers {{{
around 'to_user' => sub
{
    my $orig = shift;
    my $self = shift;
    my ($text) = @_;

    # XXX: hack... avoiding infinite recursion
    return $orig->($self, $text) if $text eq "\e[2J";

    if ($self->current_screen =~ /login|logged_in/) {
        my $fortune_db = $self->fortune;
        $text .= "\e[s\e[20H\e[1;30m"
               . `fortune -n200 -s $fortune_db`
               . "\e[0m\e[u";
    }
    elsif ($prev_screen =~ /login|logged_in/) {
        $self->to_user("\e[2J");
    }

    $prev_screen = $self->current_screen;

    return $orig->($self, $text);
};
# }}}

1;

