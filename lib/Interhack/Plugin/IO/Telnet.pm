#!/usr/bin/env perl
package Interhack::Plugin::IO::Telnet;
use Calf::Role qw/initialize to_nethack from_nethack/;
use IO::Socket::INET;

our $VERSION = '1.99_01';

# attributes {{{
has 'socket' => (
    per_load => 1,
    isa => 'IO::Socket::INET',
    lazy => 1,
    default => sub { {} },
);
# }}}
# method overrides {{{
sub initialize {
    my $self = shift;

    my $conn_info = $self->connection_info->{$self->connection};

    $self->socket(new IO::Socket::INET(PeerAddr => $conn_info->{server},
                                       PeerPort => $conn_info->{port},
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

    if ($self->connection =~ /termcast/)
    {
        $self->to_nethack("$IAC$DO$ECHO"
                         ."$IAC$DO$GOAHEAD")
    }
    else
    {
        # XXX: this hardcoding of xterm-color is actually necessary, since we
        # do lots of manipulation of raw terminal escape codes, and changing
        # the term type will change the escape codes that the telnet server
        # sends back to us. ideally, we should be using ncurses (or
        # termcap/terminfo at the very least) to abstract this stuff out, but
        # that's a lot of effort for not much gain at the moment.
        $self->to_nethack("$IAC$WILL$TTYPE"
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

sub from_nethack {
    my $self = shift;

    # the reason this is so complicated is because packets can be broken up
    # we can't detect this perfectly, but it's only an issue if an escape code
    # is broken into two parts, and we can check for that

    my $from_server;

    for (1..100)
    {
        # would block
        my $bytes = recv($self->socket, $_, 4096, 0);
        last unless defined($from_server) ||  defined($bytes);
        next if     defined($from_server) && !defined($bytes);

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
            next;
        }

        # cut it and release
        last;
    }

    return $from_server;
}

sub to_nethack {
    my ($self, $text) = @_;

    print {$self->socket} $text;
}
# }}}

1;
