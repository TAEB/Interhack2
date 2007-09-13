#!/usr/bin/env perl
package Interhack::Config;
use Sort::Topological 'toposort';
use YAML 'LoadFile';

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

    my $config = LoadFile($interhack->config_dir . "/config.yaml");
    $interhack->config($config);
}

sub apply_config
{
    my $interhack = shift;
    my $config = $interhack->config;

    my %all_plugins = $interhack->find_plugins($interhack->config_dir . "/plugins/");
    my @plugins;

    if (exists $config->{plugins}{include})
    {
        for (@{$config->{plugins}{include}})
        {
            if (!exists $all_plugins{$_})
            {
                warn "No plugin $_ found.";
                next;
            }

            push @plugins, $all_plugins{$_};
        }
    }
    elsif (exists $config->{plugins}{exclude})
    {
        delete $all_plugins{$_} for @{$config->{plugins}{exclude}};
        @plugins = values %all_plugins;
    }

    local @INC = ($interhack->config_dir . "/plugins/", @INC);
    for my $plugin (@plugins)
    {
        my $package = $plugin;
        $package =~ s{::}{/}g;
        $package .= '.pm';
        require($package) or die "Unable to load plugin '$plugin': $@";

        # look at $package::dependencies
        push @roles, $plugin;
    }

    # sort @roles according to dependencies

    $interhack->apply('Interhack::Plugin::Util');

    for my $role (@roles)
    {
        $interhack->apply($role);
    }
}

1;

