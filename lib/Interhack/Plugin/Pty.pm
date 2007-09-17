#!/usr/bin/env perl
package Interhack::Plugin::Pty;
use Calf::Role qw/to_nethack from_nethack/;
use IO::Pty::Easy;

our $VERSION = '1.99_01';

# attributes {{{
has 'pty' => (
    per_load => 1,
    isa => 'IO::Pty::Easy',
    default => sub { IO::Pty::Easy->new() },
);
# }}}
# methods {{{
sub to_nethack # {{{
{
    my $self = shift;
    my ($text) = @_;

    my $ret = $self->pty->write($text, 0);
    if (defined($ret) && $ret == 0) {
        $self->running(0);
        return;
    }
} # }}}
sub from_nethack # {{{
{
    my $self = shift;

    my $output = $self->pty->read(0);
    if (defined($output) && $output eq '') {
        $self->running(0);
        return;
    }

    return $output;
} # }}}
# }}}
# method modifiers {{{
around 'initialize' => sub
{
    my $orig = shift;
    my $self = shift;

    my $conn_info = $self->connection_info->{$self->connection};
    unless ($conn_info->{type} eq "local") {
        return $orig->($self);
    }
    my $cmd = $conn_info->{binary};
    $cmd .= " $conn_info->{args}" if $conn_info->{args};
    $self->pty->spawn($cmd);
    $self->running(1);
};
# }}}

1;
