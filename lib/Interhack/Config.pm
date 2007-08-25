#!/usr/bin/env perl
package Interhack::Config;
use Sort::Topological 'toposort';

our $VERSION = '1.99_01';
our %loaded_plugins;

# XXX: does NOT handle circular dependencies well - goes into an infinite loop
#       we'll want a new module for toposort, but it's good enough for now
sub calc_deps
{
    my %is_wanted = map {$_ => 1} @_;
    my %plugins = map {$_ => []} @_;

    open my $handle, '<', 'plugin-dependencies.txt'
        or die "Unable to open plugin-dependencies.txt for reading: $!";

    my $to_soft = 0;
    my (@soft, @hard);
    while (<$handle>)
    {
        chomp;
        $to_soft = /^# soft/../^# hard/; # soft iff between these two lines
        next unless /^\w/; # skip comments, blank lines, etc

        s/#.*//; # kill comments

        my ($plugin, @dependencies) = /\w+/g;

        push @{$plugins{$plugin}}, @dependencies;

        # now load dependencies if necessary
        if (!$to_soft && $is_wanted{$plugin})
        {
            for my $dep (@dependencies)
            {
                $is_wanted{$dep} = 1;
            }
        }
    }

    my @to_load = keys %is_wanted;
    my $children = sub { @{$plugins{$_[0]} || []} };
    return reverse toposort($children, \@to_load);
}

sub load_all_config
{
    my $interhack = shift;
    # XXX: DGL_LocalConfig and DGL_Fortune are broken at the moment until
    # Eidolos gets around to implementing wrapping subs in the same package
    my @plugins = qw/Realtime Keystrokes FloatingEye TriggerReload NewGame Macros ConfirmDirection Foodless Satiated Illiterate Eidocolors Weaponless PasteDetection QuakeConsole StripMenucolors DGameLaunch Telnet/;
    #my @plugins = qw/Realtime Keystrokes FloatingEye TriggerReload NewGame Macros ConfirmDirection Foodless Satiated Illiterate Eidocolors Weaponless PasteDetection QuakeConsole StripMenucolors DGameLaunch DGL_LocalConfig DGL_Fortune Telnet/;

    # use this plugin list to run a local copy of nethack
    #my @plugins = qw/Realtime Keystrokes FloatingEye TriggerReload NewGame Macros ConfirmDirection Foodless Satiated Illiterate Eidocolors Weaponless PasteDetection QuakeConsole StripMenucolors/;
    $interhack->load_plugins(calc_deps(@plugins));
}

1;

