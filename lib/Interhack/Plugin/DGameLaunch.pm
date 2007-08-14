#!/usr/bin/perl
package Interhack::Plugin::DGameLaunch;
use Moose::Role;
use Term::ReadKey;

our $VERSION = '1.99_01';

# attributes {{{
has rc_dir => (
    metaclass => 'DoNotSerialize',
    isa => 'Str',
    is => 'rw',
    lazy => 1,
    default => 'http://alt.org/nethack/rcfiles',
);

has dgl_line1 => (
    metaclass => 'DoNotSerialize',
    isa => 'Str',
    is => 'rw',
    lazy => 1,
    default => ' dgamelaunch - network console game launcher',
);

has dgl_line2 => (
    metaclass => 'DoNotSerialize',
    isa => 'Str',
    is => 'rw',
    lazy => 1,
    default => ' version 1.4.6',
);

has nick => (
    metaclass => 'DoNotSerialize',
    isa => 'Str',
    is => 'rw',
    lazy => 1,
    default => '',
);

has pass => (
    metaclass => 'DoNotSerialize',
    isa => 'Str',
    is => 'rw',
    lazy => 1,
    default => '',
);

has do_autologin => (
    metaclass => 'DoNotSerialize',
    isa => 'Bool',
    is => 'rw',
    lazy => 1,
    default => 0,
);

has logged_in => (
    metaclass => 'DoNotSerialize',
    isa => 'Bool',
    is => 'rw',
    lazy => 1,
    default => 0,
);
# }}}
# method modifiers {{{
after 'initialize' => sub {
    my ($self) = @_;

    $self->get_nick;
    $self->get_pass;
    $self->autologin;
    $self->clear_buffers;
    my $keep_looping = 1;
    $keep_looping = $self->dgl_iterate until !$keep_looping;
    $self->debug("Leaving DGL, starting the game");
};
# }}}
# methods {{{
# server {{{
my %servers = (
    nao       => { server => 'nethack.alt.org',
                   port   => 23,
                   name   => 'nao',
                   rc_dir => 'http://alt.org/nethack/rcfiles',
                   line1 => ' dgamelaunch - network console game launcher',
                   line2 => ' version 1.4.6',
                 },
    sporkhack => { server => 'sporkhack.nineball.org',
                   port   => 23,
                   name   => 'sporkhack',
                   rc_dir => 'http://nethack.nineball.org/rcfiles',
                   line1 => ' ** Games on this server are recorded for in-  progress viewing and playback!',
                   line2 => '',
                 },
);

sub server {
    my $self = shift;
    my $new_server;

    if (@_ == 0)
    {
        $self->warn("server called with no parameters");
        return;
    }
    elsif (@_ == 1)
    {
        if (ref($_[0]) eq 'HASH')
        {
            $new_server = $_[0];
        }
        else
        {
            $new_server = $servers{$_[0]} or do {
                $self->warn("Unknown server '$_[0]'");
                return;
            }
        }
    }
    else
    {
        $new_server = \do {my %args = @_};
    }

    $self->server_name($new_server->{name})
        or $self->warn("Server name not set");
    $self->telnet_server($new_server->{server})
        or $self->warn("Server address not set");
    $self->telnet_port($new_server->{port})
        or $self->warn("Server port not set");
    $self->rc_dir($new_server->{rc_dir})
        or $self->warn("Server RC path URL not set");
    $self->dgl_line1($new_server->{line1})
        or $self->warn("Server main screen detection (line 1) not set");
    $self->dgl_line2($new_server->{line2})
        or $self->warn("Server main screen detection (line 2) not set");
} # }}}
# get_nick {{{
sub get_nick {
    my $self = shift;

    my $pass_dir = $self->config_dir . "/servers/" . $self->server_name . "/passwords";
    if (@ARGV)
    {
        for (glob("$pass_dir/*"))
        {
            local ($_) = m{.*/(\w+)};
            if (index($_, $ARGV[0]) > -1)
            {
                if ($self->nick ne '')
                {
                    $self->fatal("Ambiguous login name given: $self->nick, $_");
                }
                else
                {
                    $self->debug("Using login name $_");
                    $self->nick($_);
                }
            }
        }
        $self->do_autologin(1) unless $self->nick eq '';
    }
} # }}}
# get_pass {{{
sub get_pass {
    my $self = shift;

    my $pass_dir = $self->config_dir . "/servers/" . $self->server_name . "/passwords";
    if ($self->pass eq '')
    {
        $self->debug("Getting password from the password file");
        my $pass = do { local @ARGV = "$pass_dir/" . $self->nick; <> };
        chomp $pass;
        $self->pass($pass);
    }
} # }}}
# autologin {{{
sub autologin {
    my $self = shift;

    if ($self->do_autologin)
    {
        $self->debug("Doing autologin");
        # meh, i thought to keep these as prints for security reasons, but
        # really, any of the helper function here can be wrapped, not just
        # dgl_write_server_input, so it's really not worth it.
        $self->dgl_write_server_input("l" . $self->nick . "\n");
        $self->dgl_write_server_input($self->pass . "\n") if $self->pass ne '';
    }
} # }}}
# clear_buffers {{{
sub clear_buffers {
    my $self = shift;

    my $found = 0;
    while ($found < ($self->do_autologin ? 2 : 1))
    {
        $self->debug("Clearing out socket buffer...");
        next unless defined(recv($self->socket, $_, 4096, 0));
        last if /There was a problem with your last entry\./;
        my $line1 = $self->dgl_line1;
        my $line2 = $self->dgl_line2;
        if (s/^.*?(\e\[H\e\[2J\e\[1B ##\Q$line1\E..\e\[1B ##\Q$line2\E)(.*\e\[H\e\[2J\e\[1B ##\Q$line1\E..\e\[1B ##\Q$line2\E)?/$1/s)
        {
            $found++;
            $found++ if $2;
        }
    }
    $self->debug("Done clearing out socket buffer");
    $self->dgl_write_user_output($_);
} # }}}
# XXX: these are just a copy of the interhack main loop... we should abstract
# this out into a helper lib at some point... or maybe just have a way to do
# the Interhack.pm main loop in phases that modules can hook into... in any
# case, anyone who wants to should feel free to rewrite this
# dgl_iterate {{{
sub dgl_iterate
{
    my $self = shift;

    my $userinput = $self->dgl_read_user_input();
    if (defined($userinput))
    {
        $self->dgl_write_server_input($userinput);
        return 0 if $self->logged_in && $userinput eq 'p';
    }

    my ($serveroutput, $conn) = $self->dgl_read_server_output();
    return 0 unless $conn;
    if (defined($serveroutput))
    {
        $self->dgl_write_user_output($serveroutput);
    }
    return $self->running;
} # }}}
# dgl_read_server_output {{{
sub dgl_read_server_output
{
    my $self = shift;

    # the reason this is so complicated is because packets can be broken up
    # we can't detect this perfectly, but it's only an issue if an escape code
    # is broken into two parts, and we can check for that

    my $from_server;

    ITER: for (1..100)
    {
        # XXX: reading and writing on $self->socket should be methods in the
        # Telnet plugin; we shouldn't be directly accessing $self->socket here
        # would block
        next ITER
            unless defined(recv($self->socket, $_, 4096, 0));

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

    return ($from_server, 1);
} # }}}
# dgl_read_user_input {{{
sub dgl_read_user_input
{
    my $self = shift;
    ReadKey 0.05;
} # }}}
# dgl_write_server_input {{{
sub dgl_write_server_input {
    my ($self, $text) = @_;

    print {$self->socket} $text;
} # }}}
# dgl_write_user_output {{{
sub dgl_write_user_output {
    my ($self, $text) = @_;

    my $nick = $self->nick;
    if ($text =~ /Logged in as: $nick/) {
        $self->debug("Login detected");
        $self->logged_in(1);
    }

    print $text;
} # }}}
# }}}

1;
