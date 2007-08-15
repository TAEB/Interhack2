#!/usr/bin/perl
package Interhack::Plugin::Telnet;
use Moose::Role;
use IO::Socket::INET;

our $VERSION = '1.99_01';

# attributes {{{
has server_name => (
    metaclass => 'DoNotSerialize',
    isa => 'Str',
    is => 'rw',
    lazy => 1,
    default => 'nao',
);

has telnet_server => (
    metaclass => 'DoNotSerialize',
    isa => 'Str',
    is => 'rw',
    lazy => 1,
    default => 'nethack.alt.org',
);

has telnet_port => (
    metaclass => 'DoNotSerialize',
    isa => 'Int',
    is => 'rw',
    lazy => 1,
    default => 23,
);

has 'socket' => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    isa => 'IO::Socket::INET',
    lazy => 1,
    default => sub { {} },
);
# }}}
# method modifiers {{{
around 'initialize' => sub {
    my $orig = shift;
    my $self = shift;

    $self->socket(new IO::Socket::INET(PeerAddr => $self->telnet_server,
                                       PeerPort => $self->telnet_port,
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

    if ($self->server_name =~ /termcast/)
    {
        $self->telnet_write("$IAC$DO$ECHO"
                           ."$IAC$DO$GOAHEAD")
    }
    else
    {
        $self->telnet_write("$IAC$WILL$TTYPE"
                           ."$IAC$SB$TTYPE${IS}xterm-color$IAC$SE"
                           ."$IAC$WONT$TSPEED"
                           ."$IAC$WONT$XDISPLOC"
                           ."$IAC$WONT$NEWENVIRON"
                           ."$IAC$DONT$GOAHEAD"
                           ."$IAC$WILL$ECHO"
                           ."$IAC$DO$STATUS"
                           ."$IAC$WILL$LFLOW"
                           ."$IAC$WILL$NAWS"
                           ."$IAC$SB$NAWS$IS".chr(80).$IS.chr(24)."$IAC$SE");
    }

    $self->running(1);
};

around 'from_nethack' => sub {
    my $orig = shift;
    my $self = shift;

    # the reason this is so complicated is because packets can be broken up
    # we can't detect this perfectly, but it's only an issue if an escape code
    # is broken into two parts, and we can check for that

    my $from_server;

    ITER: for (1..100)
    {
        # would block
        next ITER
            unless defined($self->telnet_read($_, 4096));

        # 0 = error
        if (length == 0)
        {
            $self->running(0);
            return;
        }

        # need to store what we read
        $from_server .= $_;

        # check for broken escape code or DEC string
        if (/ \e \[? [0-9;]* \z /x || m/ \x0e [^\x0f]* \z /x)
        {
            next ITER;
        }

        # cut it and release
        last ITER;
    }

    return $from_server;
};

around 'to_nethack' => sub {
    my $orig = shift;
    my ($self, $text) = @_;

    $self->telnet_write($text);
};
# }}}
# methods {{{
# XXX: these still aren't ideal... we really should just have higher level
# read/write functions that these just override, so that we can abstract out
# the dgl code to work with both ssh and telnet connections. i'm not quite sure
# how to handle that though, since i don't think that 'around' does exactly
# what i want. leaving it this way for now, since it's at least better than
# direct socket manipulation.
sub telnet_read { # {{{
    my $self = shift;
    my ($buf, $nbytes) = @_;

    return recv($self->socket, $_[0], $nbytes, 0);
} # }}}
sub telnet_write { # {{{
    my $self = shift;
    my ($text) = @_;

    print {$self->socket} $text;
} # }}}
# }}}

1;
