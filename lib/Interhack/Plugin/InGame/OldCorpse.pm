#!/usr/bin/env perl
package Interhack::Plugin::InGame::OldCorpse;
use Calf::Role;

our $VERSION = '1.99_01';

# deps {{{
sub depend { 'Util' }
# }}}
# attributes {{{
# }}}
# method modifiers {{{
guard 'check_input' => sub
{
    my ($self, $input) = @_;
    return 1 if !defined($input);

    if ($input =~ /^y/i && $self->topline =~ /^There is an? (.*?) corpse here; eat it\?/)
    {
        my $dt = $self->turn - ($self->last_turn_killed->{$1}||0);
        return 1 if $dt < 50;
        return 1 if $1 =~ /lizard/ || $1 =~ /lichen/;
        return $self->force_tab_yn("Warning! That monster type was killed $dt turns ago [tab to continue]");
    }

    return 1;
};
# }}}
# methods {{{
# }}}
1;

