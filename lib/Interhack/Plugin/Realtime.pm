#!/usr/bin/perl
package Interhack::Plugin::Realtime;
use Moose::Role;

our $VERSION = '1.99_01';

# attributes {{{
has realtime => (
    isa => 'Int',
    is => 'rw',
    lazy => 1,
    default => 0,
);

has previous_time => (
    metaclass => 'DoNotSerialize',
    isa => 'Int',
    is => 'rw',
    lazy => 1,
    default => sub { time },
);
# }}}
# method modifiers {{{
after 'write_game_input' => sub
{
    my ($self) = @_;

    my $time = time;
    my $prev = $self->previous_time;
    $self->previous_time($time);

    my $diff = $time - $prev;
    $diff = 10
        if $diff > 10;

    $self->realtime($self->realtime + $diff);
};

before 'cleanup' => sub
{
    my ($self) = @_;

    warn "Realtime: ".$self->serialize_time."\n";
};
# }}}
# new methods {{{
sub serialize_time
{
    my $self = shift;

    my $seconds = $self->realtime;
    my $hours = int($seconds / 3600);
    $hours %= 3600;
    my $minutes = int($seconds / 60);
    $seconds %= 60;

    sprintf '%d:%02d:%02d', $hours, $minutes, $seconds;
}
# }}}

1;

