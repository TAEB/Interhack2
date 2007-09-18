#!/usr/bin/env perl
package Interhack::Config;
use Sort::Topological 'toposort';
use YAML 'LoadFile';

our $VERSION = '1.99_01';

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
    my $phase = shift;

    my %all_plugins = $interhack->find_plugins($interhack->config_dir . "/plugins/$phase/");
    for (keys %all_plugins) {
        delete $all_plugins{$_} unless $all_plugins{$_} =~ /::${phase}::/;
    }
    my @plugins;

    if ($phase eq 'IO')
    {
        for (qw/NetHack User/)
        {
            my $io_plugin = $config->{plugins}{IO}{$_}
                or die "You must specify a $_ IO plugin in your config";
            die "Invalid IO plugin: $io_plugin"
                unless exists($all_plugins{"${phase}::$io_plugin"});
            push @plugins, $all_plugins{"${phase}::$io_plugin"};
        }
    }
    else
    {
        if (exists $config->{plugins}{$phase}{include})
        {
            for (@{$config->{plugins}{$phase}{include}})
            {
                if (!exists $all_plugins{"${phase}::$_"})
                {
                    warn "No plugin $_ found.";
                    next;
                }

                push @plugins, $all_plugins{"${phase}::$_"};
            }
        }
        elsif (exists $config->{plugins}{$phase}{exclude})
        {
            delete $all_plugins{"${phase}::$_"}
                for @{$config->{plugins}{$phase}{exclude}};
            @plugins = values %all_plugins;
        }
    }

    local @INC = ($interhack->config_dir . "/plugins/$phase/", @INC);
    my %deps;
    my @roles;
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
    my $children = sub { map {"Interhack::Plugin::${phase}::$_"} @{$deps{$_[0]} || []} };
    # XXX: does NOT handle circular dependencies well - goes into an infinite
    # loop. we'll want a new module for toposort, but it's good enough for now
    my @sorted = toposort($children, \@roles);

    for my $role (reverse @sorted)
    {
        $interhack->apply($role);
    }
}

1;

