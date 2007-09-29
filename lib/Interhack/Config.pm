#!/usr/bin/env perl
package Interhack::Config;
use Sort::Topological 'toposort';
use YAML 'LoadFile';

our $VERSION = '1.99_01';

my $hostname = `hostname`;
chomp $hostname;
my %servers = (
    $hostname  => { type   => 'pty',
                    phase  => 'InGame',
                    binary => "nethack",
                    args   => '',
                    rcfile => '~/.nethackrc',
                  },
    nao        => { type   => 'telnet',
                    phase  => 'PreGame',
                    server => 'nethack.alt.org',
                    port   => 23,
                    rc_dir => 'http://alt.org/nethack/rcfiles',
                    line1  => ' dgamelaunch - network console game launcher',
                    line2  => ' version 1.4.6',
                  },
    sporkhack  => { type   => 'telnet',
                    phase  => 'PreGame',
                    server => 'sporkhack.nineball.org',
                    port   => 23,
                    rc_dir => 'http://nethack.nineball.org/rcfiles',
                    line1  => ' ** Games on this server are recorded for in-progress viewing and playback!',
                    line2  => '',
                  },
);

sub load_all_config
{
    my $interhack = shift;

    # XXX: once we start thinking about the plugin pack idea, move %servers
    # into config files in the plugin packs that we load here too
    while (($k, $v) = each %servers) {
        $interhack->add_connection($k, $v);
    }

    my $config = LoadFile($interhack->config_dir . "/config.yaml");
    $interhack->config($config);
    if (defined $interhack->config->{servers}) {
        while (($k, $v) = each %{$interhack->config->{servers}}) {
            $interhack->add_connection($k, $v);
        }
    }

    if (defined $interhack->config->{servername}) {
        $interhack->set_connection($interhack->config->{servername})
    }
    else {
        die "You must specify a servername option in your config file.";
    }
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
        elsif ($phase eq 'Util')
        {
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
        $deps{$plugin} = [ $plugin->can("depend") ? $plugin->depend : () ];
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

