#!/usr/bin/env perl
package Interhack;
use Calf;
use Term::VT102;

use Interhack::Config;

our $VERSION = '1.99_01';

# attributes {{{
has 'running' => (
    per_load => 1,
    isa => 'Bool',
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
    default => sub { {} },
);

has 'connection' => (
    per_load => 1,
    isa => 'Str',
    required => 1,
    default => '',
);

has 'phase' => (
    per_load => 1,
    isa => 'Str',
    required => 1,
    default => '',
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
} # }}}
sub SETUP # {{{
{
    # Don't put anything in here! This is here because plugins depend on it
} # }}}
sub run # {{{
{
    my $self = shift;

    $self->apply_config('Util');
    $self->apply_config('IO');
    $self->initialize();
    $SIG{INT} = sub {};

    $self->phase($self->connection_info->{$self->connection}->{phase});
    while ($self->running) {
        my $phase = $self->phase;
        $self->debug("Starting phase $phase");
        $self->apply_config($phase);
        $self->apply_config("Display") if $phase =~ /InGame|Watching/;
        while ($self->phase eq $phase)
        {
            $self->iterate();
        }
        $self->clear_config();
    }

    $self->cleanup();
} # }}}
sub add_connection # {{{
{
    my $self = shift;
    my ($conn_name, $new_conn) = @_;

    $self->connection_info->{$conn_name} = $new_conn;
} # }}}
sub set_connection # {{{
{
    my $self = shift;
    my ($conn_name) = @_;

    $self->connection($conn_name);
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
sub check_input # {{{
{
    my ($self, $text) = @_;
    return $text;
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
    my ($phase) = @_;
    Interhack::Config::apply_config($self, $phase);
} # }}}
sub clear_config # {{{
{
    Class::Method::Modifiers::_wipeout("Interhack");
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

