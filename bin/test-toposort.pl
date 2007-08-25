#!/usr/bin/env perl
use strict;
use warnings;
use Sort::Topological 'toposort';

sub calc_deps
{
    my $interhack = shift;
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

print "Load order: " . join(', ', calc_deps(undef, @ARGV)), "\n";

