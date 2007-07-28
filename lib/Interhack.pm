#!/usr/bin/perl
package Interhack;
use Moose;
use IO::Socket::INET;
use Term::ReadKey;
use Term::VT102;
use Interhack::Config;

our $VERSION = '1.99_01';

# attributes {{{
has 'connected' => (
    is => 'rw',
    isa => 'Bool',
);

has 'socket' => (
    is => 'rw',
    isa => 'IO::Socket::INET',
    lazy => 1,
    default => sub { {} },
);

has 'config' => (
    is => 'rw',
    isa => 'Interhack::Config',
);

has 'vt' => (
    is => 'rw',
    isa => 'Term::VT102',
    default => sub { Term::VT102->new(rows => 24, cols => 80) },
);

has 'topline' => (
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
    Interhack::Config::load_all_config();

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
} # }}}
# }}}

1;

