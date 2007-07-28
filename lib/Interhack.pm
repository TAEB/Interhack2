#!/usr/bin/perl
package Interhack;
use Moose;
use IO::Socket::INET;
use Term::ReadKey;
use Term::VT102;
use Module::Refresh;
use MooseX::Storage;

use Interhack::Config;

our $VERSION = '1.99_01';

with Storage('format' => 'YAML', 'io' => 'File');

# attributes {{{
has 'connected' => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    isa => 'Bool',
);

has 'socket' => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    isa => 'IO::Socket::INET',
    lazy => 1,
    default => sub { {} },
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
# }}}
# methods {{{
sub BUILD # {{{
{
    my $self = shift;
    $self->load_config();
    $self->load_state();
} # }}}
sub run # {{{
{
    my $self = shift;
    $self->connect;

    while ($self->connected)
    {
        $self->iterate();
    }

    $self->cleanup();
} # }}}
sub connect # {{{
{
    my $self = shift;

    my ($server, $port) = ('nethack.alt.org', 23);
    $self->socket(new IO::Socket::INET(PeerAddr => $server,
                                       PeerPort => $port,
                                       Proto => 'tcp'));
    die "Could not create socket: $!\n" unless $self->socket;
    $self->socket->blocking(0);

    my $IAC = chr(255);
    my $SB = chr(250);
    my $SE = chr(240);
    my $WILL = chr(251);
    my $WONT = chr(252);
    my $DO = chr(253);
    my $DONT = chr(254);
    my $TTYPE = chr(24);
    my $TSPEED = chr(32);
    my $XDISPLOC = chr(35);
    my $NEWENVIRON = chr(39);
    my $IS = chr(0);
    my $GOAHEAD = chr(3);
    my $ECHO = chr(1);
    my $NAWS = chr(31);
    my $STATUS = chr(5);
    my $LFLOW = chr(33);

    if ($server =~ /noway\.ratry\.ru/)
    {
        print {$self->socket} "$IAC$DO$ECHO"
                             ."$IAC$DO$GOAHEAD"
    }
    else
    {
        print {$self->socket} "$IAC$WILL$TTYPE"
                             ."$IAC$SB$TTYPE${IS}xterm-color$IAC$SE"
                             ."$IAC$WONT$TSPEED"
                             ."$IAC$WONT$XDISPLOC"
                             ."$IAC$WONT$NEWENVIRON"
                             ."$IAC$DONT$GOAHEAD"
                             ."$IAC$WILL$ECHO"
                             ."$IAC$DO$STATUS"
                             ."$IAC$WILL$LFLOW"
                             ."$IAC$WILL$NAWS"
                             ."$IAC$SB$NAWS$IS".chr(80).$IS.chr(24)."$IAC$SE";
    }

    $self->connected(1);
} # }}}
sub iterate # {{{
{
    my $self = shift;

    my $fromkeyboard = $self->read_keyboard();
    if (defined($fromkeyboard))
    {
        $self->tonao($fromkeyboard);
    }

    my $fromsocket = $self->read_socket();
    if (defined($fromsocket))
    {
        $self->parse($fromsocket);
    }
} # }}}
sub read_keyboard # {{{
{
    my $self = shift;
    ReadKey 0.05;
} # }}}
sub read_socket # {{{
{
    my $self = shift;

    my $from_nao;

    ITER: for (1..100)
    {
        # would block
        next ITER
            unless defined(recv($self->socket, $_, 4096, 0));

        # 0 = error
        if (length == 0)
        {
            $self->connected(0);
            return;
        }

        # need to store what we read
        $from_nao .= $_;

        # check for broken escape code or DEC string
        if (/ \e \[? [0-9;]* \z /x || m/ \x0e [^\x0f]* \z /x)
        {
            next ITER;
        }

        # cut it and release
        last ITER;
    }

    return $from_nao;
} # }}}
sub parse # {{{
{
    my ($self, $text) = @_;

    $self->vt->process($text);
    $self->topline( $self->vt->row_plaintext(1) );
    $self->toscreen($text);
} # }}}
sub toscreen # {{{
{
    my ($self, $text) = @_;

    print $text;
} # }}}
sub tonao # {{{
{
    my ($self, $text) = @_;

    print {$self->socket} $text;
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
    $self->store(shift || 'interhack.yaml');
} # }}}
sub load_state # {{{
{
    my $self = shift;

    # first let's make sure we're not recursing due to BUILD
    do
    {
        my $level = 1;
        while (my @caller = caller($level++))
        {
            return if $caller[3] eq 'Interhack::load_state';
        }
    };

    my $newself = Interhack->load(shift || 'interhack.yaml')
        if -r 'interhack.yaml';

    $self->steal_state_from($newself);
} # }}}
sub steal_state_from # {{{
{
    my $self = shift;
    my $newself = shift;

    # disclaimer: I AM A BAD HUMAN BEING
    # load is a class method. I need it to be an instance method
    # there's no sane way to replace $self so what we do is
    # we take all the attributes that were serialized and stuff their values
    # into $self. it's totally not pretty. but this is what meta-object
    # programming is about! :)
    while (my ($k, $v) = each %$newself)
    {
        my $metaclass = blessed($newself->meta->get_attribute($k));
        next if $metaclass =~ /DoNotSerialize/;
        $self->{$k} = $v;
    }
} # }}}
sub new_state # {{{
{
    my $self = shift;
    unlink 'interhack.yaml';
    my $newself = Interhack->new();

    $self->steal_state_from($newself);
} # }}}
sub load_config # {{{
{
    my $self = shift;
    Interhack::Config::load_all_config();
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

