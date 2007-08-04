#!/usr/bin/perl
package Interhack::Test;
use Moose;
use Test::Builder;
use Term::VT102;
use Interhack;
use Interhack::Config;

extends 'Test::More', 'Interhack';

# Test::More requirements {{{
sub import_extra
{
    Test::More->export_to_level(2);
}
# }}}
# attributes {{{
has keyboard_in => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    isa => 'Str',
    default => '',
);

has socket_in => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    isa => 'Str',
    default => '',
);

has screen_out => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    isa => 'Str',
    default => '',
);

has socket_out => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    isa => 'Str',
    default => '',
);

has test => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    isa => 'Test::Builder',
    lazy => 1,
    default => sub { Test::Builder->new() },
);

has monitor => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    isa => 'Term::VT102',
    lazy => 1,
    default => sub { Term::VT102->new(rows => 24, cols => 80) },
);

has test_attribute => (
    is => 'rw',
    isa => 'Int',
    lazy => 1,
    default => sub { 0 },
);

has unsaved_attribute => (
    metaclass => 'DoNotSerialize',
    is => 'rw',
    isa => 'Int',
    lazy => 1,
    default => sub { 12321 },
);

has '+statefile' => (
    default => 'interhack-test.yaml',
);
# }}}
# method overrides (for Interhack-side things) {{{
override 'connect' => sub # {{{
{
    my $self = shift;

    $self->connected(1);
}; # }}}
override 'read_keyboard' => sub # {{{
{
    my $self = shift;

    if ($self->keyboard_in =~ /^(.)(.*)/s)
    {
        my $c = $1;
        $self->keyboard_in($2);
        return $c;
    }

    return;
}; # }}}
override 'read_socket' => sub # {{{
{
    my $self = shift;

    if ($self->socket_in ne '')
    {
        my $text = $self->socket_in;
        $self->socket_in('');
        return $text;
    }

    return;
}; # }}}
override 'toscreen' => sub # {{{
{
    my $self = shift;
    my $text = shift;

    $self->monitor->process($text);
    $self->screen_out($self->screen_out . $text);
}; # }}}
override 'tonao' => sub # {{{
{
    my $self = shift;
    my $text = shift;

    $self->socket_out($self->socket_out . $text);
}; # }}}
override 'load_config' => sub # {{{
{
}; # }}}
# }}}
# methods (for test-side things) {{{
sub typing # {{{
{
    my $self = shift;
    my $text = shift;
    $self->keyboard_in($self->keyboard_in . $text);
} # }}}
sub recv # {{{
{
    my $self = shift;
    my $text = shift;
    $self->socket_in($self->socket_in . $text);
} # }}}
sub recvd # {{{
{
    my $self = shift;

    my $ret = $self->screen_out;
    $self->screen_out('');
    return $ret;
} # }}}
sub sent # {{{
{
    my $self = shift;

    my $ret = $self->socket_out;
    $self->socket_out('');
    return $ret;
} # }}}
sub monitor_like # {{{
{
    my ($self, $regex, $description) = @_;
    $self->_monitor_ok($regex, $description, 1);
} # }}}
sub monitor_unlike # {{{
{
    my ($self, $regex, $description) = @_;
    $self->_monitor_ok($regex, $description, 0);
} # }}}
sub _monitor_ok # {{{
{
    my ($self, $regex, $description, $match_good) = @_;
    $description ||= "monitor matches $regex" if $match_good;
    $description ||= "monitor doesn't match $regex";

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    for (1..24)
    {
        if ($self->monitor->row_plaintext($_) =~ $regex)
        {
            $self->test->ok($match_good, $description);
            return 1;
        }
    }
    $self->test->ok(!$match_good, $description);
    return 0;
} # }}}
sub top_like # {{{
{
    my ($self, $regex, $description) = @_;
    $self->test->like($self->monitor->row_plaintext(1), $regex, $description);
} # }}}
sub top_unlike # {{{
{
    my ($self, $regex, $description) = @_;
    $self->test->unlike($self->monitor->row_plaintext(1), $regex, $description);
} # }}}
sub load_plugin_or_skip # {{{
{
    my ($self, $plugin, $howmany) = @_;
    my $loaded = $self->load_plugin($plugin);

    if (!$loaded)
    {
        Test::More::skip("plugin $plugin unavailable", $howmany);
        #last SKIP;
    }

    return $loaded;
} # }}}
# }}}

BEGIN { unlink 'interhack-test.yaml' }
END   { unlink 'interhack-test.yaml' }

1;

