#!/usr/bin/env perl
package Interhack::Config;
use Sort::Topological 'toposort';
use YAML 'LoadFile';

our $VERSION = '1.99_01';
our %loaded_plugins;

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
    my %deps;
    for my $plugin (@plugins)
    {
        my $package = $plugin;
        $package =~ s{::}{/}g;
        $package .= '.pm';
        require($package) or die "Unable to load plugin '$plugin': $@";

        # look at $package::dependencies
        $deps{$plugin} = eval "${plugin}::depend";
        push @roles, $plugin;
    }
    my $children = sub { map {"Interhack::Plugin::$_"} @{$deps{$_[0]} || []} };
    # XXX: does NOT handle circular dependencies well - goes into an infinite
    # loop. we'll want a new module for toposort, but it's good enough for now
    my @sorted = toposort($children, \@roles);

    for my $role (reverse @sorted)
    {
        $interhack->apply($role);
    }
}

1;

