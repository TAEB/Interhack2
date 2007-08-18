#!perl
sub update_plugin # {{{
{
    my $op = shift;
    open my $handle, '>', 't/TestReload.pm'
        or die "Unable to open t/TestReload.pm for writing: $!";
    my $plugin = << 'EOP';
package TestReload;
use Calf::Role;

around 'recv' => sub
{
    my $orig = shift;
    my ($self, $text) = @_;

    $orig->($self, '<OP>' . <OP>($text));
};

1;
EOP

    $plugin =~ s/<OP>/$op/g;
    print {$handle} $plugin;
    close $handle;
} # }}}

use lib 't';

# this must be done before use Interhack::Test
BEGIN
{
    update_plugin('uc');
}

use Interhack::Test tests => 4;

# test that plugins can have code changes without restarting Interhack or even
# losing any state

my $interhack = Interhack::Test->new();
$interhack->recv('Foo');
$interhack->iterate();
is($interhack->recvd, "Foo", "no plugin loaded yet");

ok($interhack->load_plugin_or_skip('+TestReload', 0), "plugin loaded");
$interhack->recv('Bar');
$interhack->iterate();
is($interhack->recvd, "ucBAR", "plugin loaded initially");

update_plugin('lc');
$interhack->refresh();
$interhack->recv('Baz');
$interhack->iterate();
is($interhack->recvd, "lcbaz", "plugin reloaded!");

