#!/usr/bin/env perl
package Interhack::Plugin::InGame::PasteDetection;
use Calf::Role;
use Term::ReadKey;

our $VERSION = '1.99_01';

# Sun May 06 2007
# [20:55:13] <doy> Eidolos: maybe somehow detect accidental pastes into the nh window?
# [20:55:21] <toft> good idea
# [20:55:23] <toft> irssi does it
# [20:55:24] <doy> would probably be hard to do that though
# [21:00:08] <Eidolos> can anyone think of anything else for this helper?
# [21:00:37] <doy> Eidolos: scroll up
# [21:00:47] <Eidolos> oh, the paste detection? meh
# [21:00:52] <Eidolos> no way I could code that! :)

# deps {{{
sub depend { 'Util' }
# }}}
# attributes {{{
has paste_queue => (
    per_load => 1,
    isa => 'Str',
    lazy => 1,
    default => sub { '' },
);
# }}}
# method modifiers {{{
around 'from_user' => sub
{
    my $orig = shift;
    my ($self) = @_;

    if (length $self->paste_queue)
    {
        my $c = substr($self->paste_queue, 0, 1);
        $self->paste_queue(substr($self->paste_queue, 1));
        return $c;
    }

    my $c = $orig->($self);
    return if !defined($c);

    my $queue = '';
    while (defined(my $nc = ReadKey -1))
    {
        $queue .= $nc;
    }
    if (length $queue)
    {
        my $paste = $self->force_tab_yn("Press tab to paste, any other key to cancel.");
        $self->paste_queue($queue) if $paste;
    }

    return $c;
};
# }}}
# methods {{{
# }}}
1;


