#!/usr/bin/env perl
package Interhack::Plugin::InGame::NothingHappens;
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

    if ($self->topline =~ /^Nothing happens\./)
    {
        $self->force_tab("Press tab to continue.", .5);
    }

    return 1;
};
# }}}
# methods {{{
# }}}
1;

