#!/usr/bin/perl
package Interhack::Plugin::DGameLaunch;
use Moose::Role;

our $VERSION = '1.99_01';

# attributes {{{
has server_name => (
    metaclass => 'DoNotSerialize',
    isa => 'Str',
    is => 'rw',
    lazy => 1,
    default => 'nao',
);

has server_address => (
    metaclass => 'DoNotSerialize',
    isa => 'Str',
    is => 'rw',
    lazy => 1,
    default => 'nethack.alt.org',
);

has server_port => (
    metaclass => 'DoNotSerialize',
    isa => 'Int',
    is => 'rw',
    lazy => 1,
    default => 23,
);

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

has in_game => (
    metaclass => 'DoNotSerialize',
    isa => 'Bool',
    is => 'rw',
    lazy => 1,
    default => 0,
);
# }}}
# method modifiers {{{
after 'connect' => sub {
    my ($self) = @_;

    $self->get_nick;
    $self->get_pass;
    $self->autologin;
    $self->clear_buffers;
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

    if (@_ == 0) {
        $self->warn("server called with no parameters");
        return;
    }
    elsif (@_ == 1) {
        if (ref($_[0]) eq 'HASH') {
            $new_server = $_[0];
        }
        else {
            $new_server = $servers{$_[0]} or do {
                $self->warn("Unknown server '$_[0]'");
                return;
            }
        }
    }
    else {
        # XXX: test this
        #$new_server = \%@_;
        $new_server = \do {my %args = @_};
    }

    $self->server_name($new_server->{name})
        or $self->warn("Server name not set");
    $self->server_address($new_server->{server})
        or $self->warn("Server address not set");
    $self->server_port($new_server->{port})
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
    # XXX: does plain ARGV work here? or will i need to use main::ARGV?
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
        $self->pass(do { local @ARGV = "$pass_dir/" . $self->nick; <> });
        # XXX: what's the correct way to do this?
        $self->pass($1) if $self->pass =~ m{(.*)$/}
        #chomp $self->pass;
    }
} # }}}
# autologin {{{
sub autologin {
    my $self = shift;

    if ($self->do_autologin)
    {
        print {$self->socket} "l" . $self->nick . "\n";
        print {$self->socket} $self->pass . "\n" if $self->pass ne '';
    }
} # }}}
# clear_buffers {{{
sub clear_buffers {
    my $found = 0;
    while ($found < ($self->do_autologin ? 2 : 1))
    {
        next unless defined(recv($self->socket, $_, 4096, 0));
        last if /There was a problem with your last entry\./;
        my $line1 = $self->dgl_line1;
        my $line2 = $self->dgl_line2;
        if (s/^.*?(\e\[H\e\[2J\e\[1B ##\Q$line1\E..\e\[1B ##\Q$line2\E)(.*\e\[H\e\[2J\e\[1B ##\Q$line1\E..\e\[1B ##\Q$line2\E)?/$1/s) {
            $found++;
            $found++ if $2;
        }
    }
    print;
} # }}}
# }}}

1;
