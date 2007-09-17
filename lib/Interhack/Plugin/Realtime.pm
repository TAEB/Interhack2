#!/usr/bin/env perl
package Interhack::Plugin::Realtime;
use Calf::Role 'serialize_time';

our $VERSION = '1.99_01';

# attributes {{{
has realtime => (
    isa => 'Int',
    lazy => 1,
    default => 0,
);

has previous_time => (
    per_load => 1,
    isa => 'Int',
    lazy => 1,
    default => sub { time },
);
# }}}
# method modifiers {{{
after 'to_nethack' => sub
{
    my ($self) = @_;

    my $time = time;
    my $prev = $self->previous_time;
    $self->previous_time($time);

    my $diff = $time - $prev;
    $diff = 10
        if $diff > 10;

    $self->realtime($self->realtime + $diff);
    $self->botl_stats->{realtime} = $self->serialize_time;
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

