#!/usr/bin/perl
package Interhack::Plugin::DGameLaunch;
use Calf::Role qw/server get_nick get_pass autologin clear_buffers/;
use Term::ReadKey;

our $VERSION = '1.99_01';

# private variables {{{
my $line1 = ' dgamelaunch - network console game launcher';
my $line2 = ' version 1.4.6';
my $pass = '';
# }}}
# attributes {{{
# }}}
# method modifiers {{{
after 'initialize' => sub {
    my ($self) = @_;

    $self->get_nick;
    $self->get_pass;
    $self->autologin;
    $self->clear_buffers;
    1 while $self->dgl_iterate;
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

# XXX: this is almost certainly the wrong place for this method, and it should
# likely be split up into multiple parts (i.e. one that initializes things like
# hostname and port, and another that initializes things like dgl nick). It's
# fine now since dgl is the only thing using the telnet code.
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
    $line1 = $new_server->{line1};
    $line2 = $new_server->{line2};
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
        open my $handle, '<', "$pass_dir/" . $self->nick or do
        {
            $self->info("No password found in $pass_dir/" . $self->nick);
            return;
        };

        my $pass = <$handle>;
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
        # to_dgl, so it's really not worth it.
        $self->to_dgl("l" . $self->nick . "\n");
        $self->to_dgl($pass . "\n") if $pass ne '';
        $pass = '';
    }
} # }}}
# clear_buffers {{{
sub clear_buffers {
    my $self = shift;

    my $found = 0;
    while ($found < ($self->do_autologin ? 2 : 1))
    {
        next unless defined($_ = $self->from_nethack_raw);
        $self->debug("Clearing out socket buffer...");
        last if /There was a problem with your last entry\./;
        if (s/^.*?(\e\[H\e\[2J\e\[1B ##\Q$line1\E..\e\[1B ##\Q$line2\E)(.*\e\[H\e\[2J\e\[1B ##\Q$line1\E..\e\[1B ##\Q$line2\E)?/$1/s)
        {
            $found++;
            $found++ if $2;
        }
    }
    $self->debug("Done clearing out socket buffer");
    $self->dgl_to_user($_);
} # }}}
# dgl_iterate {{{
sub dgl_iterate
{
    my $self = shift;

    my $userinput = $self->dgl_from_user();
    if (defined($userinput))
    {
        $self->to_dgl($userinput);
        return 0 if $self->logged_in && $userinput eq 'p';
    }

    my $serveroutput = $self->from_dgl();
    if (defined($serveroutput))
    {
        $self->dgl_to_user($serveroutput);
    }
    return $self->running;
} # }}}
# from_dgl {{{
sub from_dgl
{
    my $self = shift;

    return $self->from_nethack_raw;
} # }}}
# dgl_from_user {{{
sub dgl_from_user
{
    my $self = shift;
    return $self->from_user_raw;
} # }}}
# to_dgl {{{
sub to_dgl {
    my ($self, $text) = @_;

    $self->to_nethack_raw($text);
} # }}}
# dgl_to_user {{{
sub dgl_to_user {
    my ($self, $text) = @_;

    my $nick = $self->nick;
    if ($text =~ /Logged in as: $nick/) {
        $self->debug("Login detected");
        $self->logged_in(1);
    }

    $self->to_user_raw($text);
} # }}}
# }}}

1;
