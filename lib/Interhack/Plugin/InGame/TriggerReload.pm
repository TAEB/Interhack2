#!/usr/bin/env perl
package Interhack::Plugin::InGame::TriggerReload;
use Calf::Role 'reload';

our $VERSION = '1.99_01';

# deps {{{
sub depend { 'Util' }
# }}}
# attributes {{{
# }}}
# method modifiers {{{
sub BUILD
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
