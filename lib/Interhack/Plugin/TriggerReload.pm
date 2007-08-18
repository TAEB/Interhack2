#!/usr/bin/perl
package Interhack::Plugin::TriggerReload;
use Calf::Role 'reload';

our $VERSION = '1.99_01';

# attributes {{{
# }}}
# method modifiers {{{
sub SETUP
{
    my $self = shift;
    $self->extended_command(reload => \&reload);
}
# }}}
# methods {{{
sub reload
{
    my $self = shift;
    $self->topline(''); # avoid infinite recursion :)
    $self->refresh;
}
# }}}

1;
