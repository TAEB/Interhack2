#!/usr/bin/perl
package Interhack;
use Moose;
use IO::Pty::Easy;
use Term::ReadKey;
use Term::VT102;
use Module::Refresh;
use MooseX::Storage;

use Interhack::Config;

our $VERSION = '1.99_01';

with Storage('format' => 'YAML', 'io' => 'File');

# attributes {{{
has 'running' => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    isa => 'Bool',
);

has 'pty' => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    isa => 'IO::Pty::Easy',
);

has 'config' => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    isa => 'Interhack::Config',
);

has 'vt' => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    isa => 'Term::VT102',
    default => sub { Term::VT102->new(rows => 24, cols => 80) },
);

has 'topline' => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    isa => 'Str',
    default => '',
    trigger => sub { study $_[0] },
);

has 'statefile' => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => 'interhack.yaml',
);

# XXX: this should go into the Config role once it is written
has 'config_dir' => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => "$ENV{HOME}/.interhack2",
);
# }}}
# methods {{{
sub BUILD # {{{
{
    my $self = shift;

    $self->load_config();
    $self->load_state();

    Module::Refresh->new();
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
sub initialize # {{{
{
    my $self = shift;

    $self->pty(new IO::Pty::Easy(handle_pty_size => 0));
    $self->pty->spawn("nethack");

    $self->running(1);
} # }}}
sub iterate # {{{
{
    my $self = shift;

    my $userinput = $self->read_user_input();
    $userinput = $self->check_input($userinput);
    if (defined($userinput))
    {
        $self->write_game_input($userinput);
    }

    my $gameoutput = $self->read_game_output();
    if (defined($gameoutput))
    {
        $self->parse($gameoutput);
    }
} # }}}
sub read_user_input # {{{
{
    my $self = shift;
    ReadKey 0.05;
} # }}}
sub read_game_output # {{{
{
    my $self = shift;

    my $buf;
    # 0 == undef? perl is ridiculous
    my $ret = $self->pty->read($buf, 0);
    if (defined($ret) && $ret == 0) {
        $self->running(0);
        return;
    }
    return $buf;
} # }}}
sub parse # {{{
{
    my ($self, $text) = @_;

    $self->vt->process($text);
    $self->topline( $self->vt->row_plaintext(1) );
    $self->write_user_output($self->mangle_output($text));
} # }}}
sub mangle_output # {{{
{
    my ($self, $text) = @_;
    return $text;
} # }}}
sub write_user_output # {{{
{
    my ($self, $text) = @_;

    print $text;
} # }}}
sub check_input # {{{
{
    my ($self, $text) = @_;
    return $text;
} # }}}
sub write_game_input # {{{
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
sub reload # {{{
{
    my $self = shift;

    $self->save_state();
    Module::Refresh->refresh();
    $self->load_state();
} # }}}
sub save_state # {{{
{
    my $self = shift;
    $self->store(shift || $self->statefile);
} # }}}
sub load_state # {{{
{
    my $self = shift;
    my $file = shift || $self->statefile;

    # first let's make sure we're not recursing due to BUILD
    do
    {
        my $level = 1;
        while (my @caller = caller($level++))
        {
            return if $caller[3] =~ /::load_state$/;
        }
    };

    my $newself = blessed($self)->load(shift || $file)
        if -r $file;

    return unless $newself;

    $self->steal_state_from($newself);
} # }}}
sub steal_state_from # {{{
{
    my $self = shift;
    my $newself = shift;

    # load is a class method. I need it to be an instance method
    # there's no sane way to replace $self so what we do is
    # we take all the attributes that were serialized and stuff their values
    # into $self. it's totally not pretty. but this is what meta-object
    # programming is about! :)

    for my $k ($newself->meta->get_attribute_list)
    {
        my $metaclass = $newself->meta->get_attribute($k);
        next if blessed($metaclass) =~ /DoNotSerialize/;

        if (defined(my $selfmeta = $self->meta->get_attribute($k)))
        {
            my $value = $metaclass->get_value($newself);
            $selfmeta->set_value($self, $value);
        }
        else
        {
            $self->meta->add_attribute($metaclass);
        }
    }
} # }}}
sub new_state # {{{
{
    my $self = shift;
    unlink shift || $self->statefile;
    my $newself = blessed($self)->new();

    $self->steal_state_from($newself);
} # }}}
sub load_config # {{{
{
    my $self = shift;
    Interhack::Config::load_all_config($self);
} # }}}
sub load_plugin # {{{
{
    my ($self, $plugin) = @_;
    my $loaded = eval
    {
        Interhack::Config::load_plugin($self, $plugin);
    };
    warn $@ if $@ && blessed($self) ne 'Interhack::Test';
    return !$@;
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
either C<bug-carp-repl at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Carp-REPL>.  I will be
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

