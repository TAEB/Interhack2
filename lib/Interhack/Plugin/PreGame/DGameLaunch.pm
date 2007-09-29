#!/usr/bin/env perl
package Interhack::Plugin::PreGame::DGameLaunch;
use Calf::Role;

our $VERSION = '1.99_01';

# deps {{{
sub depend { 'Debug' }
# }}}
# private variables {{{
my $pass = '';
# }}}
# attributes {{{
has logged_in => (
    per_load => 1,
    isa => 'Bool',
    default => 0,
);
# }}}
# method modifiers {{{
after 'initialize' => sub {
    my ($self) = @_;

    if (get_nick($self)) {
        get_pass($self);
        autologin($self);
        clear_buffers($self, 2);
    }
    else {
        clear_buffers($self, 1);
    }
};

after 'to_user' => sub {
    my ($self, $text) = @_;

    if ($text =~ /Logged in as: /) {
        $self->debug("Login detected");
        $self->logged_in(1);
    }
};

after 'to_nethack' => sub {
    my ($self, $text) = @_;

    if ($text eq 'p' && $self->logged_in) {
        $self->debug("Starting the game");
        $self->phase('InGame');
    }
};
# }}}
# methods {{{
# get_nick {{{
sub get_nick {
    my $self = shift;

    my $conn_info = $self->connection_info->{$self->connection};
    my $pass_dir = $self->config_dir . "/servers/" . $self->connection . "/passwords";
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
    return 1 if $conn_info->{nick};
    return 0;
} # }}}
# get_pass {{{
sub get_pass {
    my $self = shift;

    my $conn_info = $self->connection_info->{$self->connection};
    my $pass_dir = $self->config_dir . "/servers/" . $self->connection . "/passwords";
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
    my ($main_screens) = @_;

    my $conn_info = $self->connection_info->{$self->connection};
    my $found = 0;
    while ($found < $main_screens)
    {
        next unless defined($_ = $self->from_nethack);
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
    $self->to_user($_);
} # }}}
# }}}

1;
