#!/usr/bin/env perl
package Interhack::Plugin::PreGame::DGL_LocalConfig;
use Calf::Role;
use Term::ReadKey;
use LWP::Simple;
use File::Temp qw/tempfile/;

our $VERSION = '1.99_01';

# deps {{{
sub depend { qw/Debug DGameLaunch/ }
# }}}
# method modifiers {{{
around 'to_nethack' => sub
{
    my $orig = shift;
    my ($self, $text) = @_;

    if ($text eq "\t" && $self->current_screen eq 'logged_in')
    {
        my $conn_info = $self->connection_info->{$self->connection};
        $self->debug("Downloading rc file");
        $self->to_user("\e[1;30mPlease wait while I download the existing rcfile.\e[0m");
        my $nethackrc = get($conn_info->{rc_dir} . "/" . $conn_info->{nick} . ".nethackrc");
        my ($fh, $name) = tempfile();
        print {$fh} $nethackrc;
        close $fh;
        my $t = (stat $name)[9];
        $ENV{EDITOR} = 'vi' unless exists $ENV{EDITOR};
        system("$ENV{EDITOR} $name");

        # file wasn't modified, so silently bail
        if ($t == (stat $name)[9])
        {
            $self->warn("Ignoring unmodified rc file");
            $self->to_nethack(' ');
            return;
        }

        $nethackrc = do { local (@ARGV, $/) = $name; <> };
        if ($nethackrc eq '')
        {
            $self->warn("Ignoring empty rc file");
            $self->to_user("\e[24H\e[1;30mYour nethackrc came out empty, so I'm bailing.--More--\e[0m");
            ReadKey 0;
        }
        else
        {
            $self->debug("Updating rc file");
            $self->to_user("\e[24H\e[1;30mPlease wait while I update the serverside rcfile.\e[0m");
            chomp $nethackrc;
            $self->to_nethack("o:0,\$d\ni");
            $self->to_nethack("$nethackrc\eg");
            my $last_buf = '';
            my $buf = '';
            while (1) {
                next unless defined($buf = $self->from_nethack);
                $_ = $last_buf . $buf;
                last if /\e\[.*?'g' is not implemented/;
                $last_buf = $buf;
            }
            $self->to_nethack(":wq\n");
        }
    }
    else
    {
        return $orig->($self, $text);
    }
};

around 'to_user' => sub
{
    my $orig = shift;
    my ($self, $text) = @_;

    if ($self->current_screen eq 'logged_in')
    {
        $text =~ s/(o\) Edit option file)/$1  \e[1;30mTab) edit options locally\e[0m/g;
    }

    return $orig->($self, $text);
};
# }}}

1;
