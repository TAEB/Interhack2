#!/usr/bin/perl
package Interhack::Plugin::TriggerReload;
use Moose::Role;

our $VERSION = '1.99_01';

# attributes {{{
# }}}
# method modifiers {{{
before 'toscreen' => sub
{
    my ($self, $string) = @_;

    if ($self->topline =~ /^reload: unknown extended command/)
    {
        $self->reload;
    }
};
# }}}

1;
