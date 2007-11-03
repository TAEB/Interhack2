#!/usr/bin/env perl
package Interhack::Plugin::InGame::OldCorpse;
use Calf::Role;

our $VERSION = '1.99_01';

# Sun May 06 2007
# [00:28:56] <toft> hey I have a good idea for interhack.. might be unreasonably hard though: corpse age tracking
# [00:29:03] <toft> no more friggin accidental FoodPois XD
# [00:29:05] <Eidolos> heh
# [00:29:24] <Eidolos> yeah that's too hard
# [00:29:28] <toft> nod
# [00:29:52] <toft> I'm probably the only one who ever gets foidpois anyway so
# [00:29:55] <Eidolos> haha
# [00:29:57] <Eidolos> yeahh

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

