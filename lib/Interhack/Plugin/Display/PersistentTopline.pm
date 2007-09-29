#!/usr/bin/env perl
package Interhack::Plugin::Display::PersistentTopline;
use Calf::Role;

our $VERSION = '1.99_01';
our $SUMMARY = 'Greys out the top line instead of clearing it.';

# deps {{{
sub depends { 'Util' }
# }}}
# attributes {{{
has previous_topline =>
(
    isa => 'Str',
    default => '',
);

has displaying_previous_topline =>
(
    isa => 'Bool',
    default => 0,
);
# }}}
# method modifiers {{{
after to_user => sub
{
    my $self = shift;
    if ($self->topline =~ /\S/)
    {
        $self->previous_topline($self->topline);
        $self->displaying_previous_topline(0);
    }
    else
    {
        if (!$self->displaying_previous_topline)
        {
            $self->displaying_previous_topline(1);
            $self->print_row(1, "\e[1;30m".$self->previous_topline."\e[m");
        }
    }
};
# }}}
# methods {{{
# }}}

1;
