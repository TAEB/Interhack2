#!/usr/bin/env perl
package Interhack::Plugin::IO::Pty;
use Calf::Role qw/initialize to_nethack from_nethack/;
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
sub initialize # {{{
{
    my $self = shift;

    my $conn_info = $self->connection_info->{$self->connection};
    my $cmd = $conn_info->{binary};
    $cmd .= " $conn_info->{args}" if $conn_info->{args};
    $self->debug("Spawning command '$cmd'");
    $self->pty->spawn($cmd);
    $self->running(1);
} # }}}
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

1;
