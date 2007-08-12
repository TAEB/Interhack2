#!/usr/bin/perl
package Interhack::Plugin::PasteDetection;
use Moose::Role;
use Term::ReadKey;
with "Interhack::Plugin::Util";

our $VERSION = '1.99_01';

# attributes {{{
has paste_queue => (
    metaclass => 'DoNotSerialize',
    isa => 'Str',
    is => 'rw',
    lazy => 1,
    default => sub { '' },
);
# }}}
# method modifiers {{{
around 'read_keyboard' => sub
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


