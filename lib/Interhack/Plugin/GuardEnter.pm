#!/usr/bin/env perl
package Interhack::Plugin::GuardEnter;
use Calf::Role;

our $VERSION = '1.99_01';

# attributes {{{
# }}}
# method modifiers {{{
guard 'check_input' => sub
{
    my ($self, $input) = @_;
    return 1 if !defined($input);
    return not ($input =~ /^\n/ && $self->expecting_command);
};
# }}}
# methods {{{
# }}}
1;

