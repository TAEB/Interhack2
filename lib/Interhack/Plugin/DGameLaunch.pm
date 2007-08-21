#!/usr/bin/perl
package Interhack::Plugin::DGameLaunch;
use Calf::Role qw/server get_nick get_pass autologin clear_buffers
                  dgl_iterate from_dgl dgl_from_user to_dgl dgl_to_user/;
use Term::ReadKey;

our $VERSION = '1.99_01';

# private variables {{{
my $pass = '';
# }}}
# attributes {{{
has do_autologin => (
    per_load => 1,
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

has logged_in => (
    per_load => 1,
    is => 'rw',
    isa => 'Bool',
    default => 0,
);
# }}}
# method modifiers {{{
after 'initialize' => sub {
    my ($self) = @_;

    $self->get_nick;
    if ($self->do_autologin) {
        $self->get_pass;
        $self->autologin;
    }
    $self->clear_buffers;
    1 while $self->dgl_iterate;
    $self->debug("Leaving DGL, starting the game");
};
# }}}
# methods {{{
# get_nick {{{
sub get_nick {
    my $self = shift;

    my $conn_info = $self->connection_info->{$self->connection};
    my $pass_dir = $self->config_dir . "/servers/" . $conn_info->{name} . "/passwords";
    if (@ARGV)
    {
        my $found_nick = '';
        for (glob("$pass_dir/*"))
        {
            local ($_) = m{.*/(\w+)};
            if (index($_, $ARGV[0]) > -1)
            {
                if ($found_nick ne '')
                {
                    $self->fatal("Ambiguous login name given: $found_nick, $_");
                }
                else
                {
                    $self->debug("Using login name $_");
                    $found_nick = $_;
                }
            }
        }
        $conn_info->{nick} = $found_nick if $found_nick;
    }
    $self->do_autologin(1) if $conn_info->{nick};
} # }}}
# get_pass {{{
sub get_pass {
    my $self = shift;

    my $conn_info = $self->connection_info->{$self->connection};
    my $pass_dir = $self->config_dir . "/servers/" . $conn_info->{name} . "/passwords";
    if ($pass eq '')
    {
        $self->debug("Getting password from the password file");
        open my $handle, '<', "$pass_dir/" . $conn_info->{nick} or do
        {
            $self->info("No password found in $pass_dir/" . $conn_info->{nick});
            return;
        };

        $pass = <$handle>;
        chomp $pass if $pass;
    }
} # }}}
# autologin {{{
sub autologin {
    my $self = shift;

    my $conn_info = $self->connection_info->{$self->connection};
    $self->debug("Doing autologin");
    # meh, i thought to keep these as prints for security reasons, but
    # really, any of the helper function here can be wrapped, not just
    # to_dgl, so it's really not worth it.
    $self->to_dgl("l" . $conn_info->{nick} . "\n");
    $self->to_dgl($pass . "\n") if $pass;
    $pass = '';
} # }}}
# clear_buffers {{{
sub clear_buffers {
    my $self = shift;

    my $conn_info = $self->connection_info->{$self->connection};
    my $found = 0;
    while ($found < ($self->do_autologin ? 2 : 1))
    {
        next unless defined($_ = $self->from_nethack_raw);
        $self->debug("Clearing out socket buffer...");
        last if /There was a problem with your last entry\./;
        my $line1 = $conn_info->{line1};
        my $line2 = $conn_info->{line2};
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

    if ($text =~ /Logged in as: /) {
        $self->debug("Login detected");
        $self->logged_in(1);
    }

    $self->to_user_raw($text);
} # }}}
# }}}

1;
