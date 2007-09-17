#!/usr/bin/env perl
package Interhack;
use Calf;
use IO::Pty::Easy;
use Term::ReadKey;
use Term::VT102;

use Interhack::Config;

our $VERSION = '1.99_01';

# attributes {{{
has 'running' => (
    per_load => 1,
    isa => 'Bool',
);

has 'pty' => (
    per_load => 1,
    isa => 'IO::Pty::Easy',
    default => sub { IO::Pty::Easy->new() },
);

has 'config' => (
    per_load => 1,
    isa => 'HashRef',
);

has 'vt' => (
    per_load => 1,
    isa => 'Term::VT102',
    default => sub { Term::VT102->new(rows => 24, cols => 80) },
);

has 'topline' => (
    per_load => 1,
    isa => 'Str',
    default => '',
    trigger => sub { study $_[1] },
);

has 'statefile' => (
    per_load => 1,
    isa => 'Str',
    required => 1,
    default => 'interhack.yaml',
);

# XXX: this should go into the Config role once it is written
has 'config_dir' => (
    per_load => 1,
    isa => 'Str',
    required => 1,
    default => "$ENV{HOME}/.interhack2",
);

has 'connection_info' => (
    per_load => 1,
    isa => 'HashRef',
    required => 1,
    default => sub
    {
        { `hostname` => { type   => "local",
                          name   => `hostname`,
                          binary => "nethack",
                          # XXX: is it too early to do this?
                          # will we want interhack-specific args?
                          args   => "@ARGV",
                        },
        }
    },
);

has 'connection' => (
    per_load => 1,
    isa => 'Str',
    required => 1,
    default => `hostname`,
);
# }}}
# methods {{{
sub BUILD # {{{
{
    my $self = shift;
    my %args = @_;

    $self->apply("Calf::Storage");
    $self->apply("Calf::Pluggable");
    $self->apply("Calf::Refresh");

    $self->load_config();
    $self->apply_config();
} # }}}
sub SETUP # {{{
{
    # Don't put anything in here! This is here because plugins depend on it
} # }}}
sub run # {{{
{
    my $self = shift;
    $self->initialize();
    $SIG{INT} = sub {};

    while ($self->running)
    {
        $self->iterate();
    }

    $self->cleanup();
} # }}}
sub set_connection # {{{
{
    my $self = shift;

    if (@_ == 0)
    {
        $self->warn("set_connection called with no parameters");
        return;
    }
    elsif (@_ == 1)
    {
        if (ref($_[0]) eq 'HASH')
        {
            my $new_conn = $_[0];

            unless ($new_conn->{name}) {
                $self->warn("Connections must have a name");
                return;
            }
            # XXX: this works since connection_info is a hashref, right?
            $self->connection_info->{$new_conn->{name}} = $new_conn;
            $self->connection($new_conn->{name});
        }
        else
        {
            # XXX: can this be a trigger? can triggers be used like that?
            unless ($self->connection_info->{$_[0]}) {
                $self->warn("Unknown server '$_[0]'");
                return;
            }
            $self->connection($_[0]);
        }
    }
    else
    {
        my $new_conn = \do {my %args = @_};

        unless ($new_conn->{name}) {
            $self->warn("Connections must have a name");
            return;
        }
        # XXX: this works since connection_info is a hashref, right?
        $self->connection_info->{$new_conn->{name}} = $new_conn;
        $self->connection($new_conn->{name});
    }
} # }}}
sub initialize # {{{
{
    my $self = shift;

    my $conn_info = $self->connection_info->{$self->connection};
    unless ($conn_info->{type} eq "local") {
        $self->warn("Unknown connection type $conn_info->{type}");
        return;
    }
    my $cmd = $conn_info->{binary};
    $cmd .= " $conn_info->{args}" if $conn_info->{args};
    $self->pty->spawn($cmd);
    $self->running(1);
} # }}}
sub iterate # {{{
{
    my $self = shift;

    my $userinput = $self->from_user();
    $userinput = $self->check_input($userinput);
    if (defined($userinput))
    {
        $self->to_nethack($userinput);
    }

    my $gameoutput = $self->from_nethack();
    if (defined($gameoutput))
    {
        $self->parse($gameoutput);
    }
} # }}}
sub from_user # {{{
{
    my $self = shift;
    ReadKey 0.05;
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
sub parse # {{{
{
    my ($self, $text) = @_;

    $self->vt->process($text);
    $self->topline( $self->vt->row_plaintext(1) );
    $self->to_user($self->mangle_output($text));
} # }}}
sub mangle_output # {{{
{
    my ($self, $text) = @_;
    return $text;
} # }}}
sub to_user # {{{
{
    my $self = shift;
    my ($text) = @_;

    print $text;
} # }}}
sub check_input # {{{
{
    my ($self, $text) = @_;
    return $text;
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
sub cleanup # {{{
{
    my $self = shift;
    $self->save_state();
} # }}}
sub save_state # {{{
{
    my $self = shift;
    $self->store(shift || $self->statefile);
} # }}}
sub new_state # {{{
{
    my $self = shift;
    unlink shift || $self->statefile;
} # }}}
sub load_state # {{{
{
    my $self = shift;
    eval { $self->load(shift || $self->statefile) };
} # }}}
sub load_config # {{{
{
    my $self = shift;
    Interhack::Config::load_all_config($self);
} # }}}
sub apply_config # {{{
{
    my $self = shift;
    Interhack::Config::apply_config($self);
} # }}}
# }}}

# documentation # {{{

=head1 NAME

Interhack - improved NetHack interface

=head1 VERSION

Version 1.99_01

=head1 SYNOPSIS

This package is merely for the benefit of the interhack binary. You shouldn't
be using this module. Unless you know what you're doing. . .

=cut

=head1 AUTHORS

=over 4

=item Shawn M Moore, C<< <sartak at gmail.com> >>

=item Jordan Lewis, C<< <jordanthelewis at gmail.com> >>

=item Jesse Luehrs, C<< <jluehrs2 at uiuc.edu> >>

=back

=head1 BUGS

On the offchance a bug is discovered (yeah right), please report it via RT,
either C<bug-interhack at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Interhack>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to Stevan Little for Moose!

=head1 COPYRIGHT & LICENSE

Copyright 2007, the Interhack DevTeam.

This program is free software; you can redistribute it and/or modify it
under the terms of the BSD license.

=cut

# }}}

1; # End of Interhack

