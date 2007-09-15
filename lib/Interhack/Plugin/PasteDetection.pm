#!/usr/bin/env perl
package Interhack::Plugin::PasteDetection;
use Calf::Role;
use Term::ReadKey;

our $VERSION = '1.99_01';

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


