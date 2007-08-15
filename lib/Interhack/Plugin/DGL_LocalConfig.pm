#!/usr/bin/perl
package Interhack::Plugin::DGL_LocalConfig;
use Moose::Role;
use Term::ReadKey;
use LWP::Simple;
use File::Temp qw/tempfile/;

our $VERSION = '1.99_01';

# method modifiers {{{
# XXX: is it safe to be calling orig() more than once? strikes me as no in
# general... it's not harmful here, since all it's doing is writing to the
# socket, but probably better to fix this.
around 'to_dgl' => sub
{
    my $orig = shift;
    my ($self, $text) = @_;

    if ($text eq "\t" && $self->logged_in)
    {
        $self->debug("Downloading rc file");
        $self->dgl_to_user("\e[1;30mPlease wait while I download the existing rcfile.\e[0m");
        my $nethackrc = get($self->rc_dir . "/" . $self->nick . ".nethackrc");
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
            $orig->($self, ' ');
            return;
        }

        $nethackrc = do { local (@ARGV, $/) = $name; <> };
        if ($nethackrc eq '')
        {
            $self->warn("Ignoring empty rc file");
            $self->dgl_to_user("\e[24H\e[1;30mYour nethackrc came out empty, so I'm bailing.--More--\e[0m");
            ReadKey 0;
        }
        else
        {
            $self->debug("Updating rc file");
            $self->dgl_to_user("\e[24H\e[1;30mPlease wait while I update the serverside rcfile.\e[0m");
            chomp $nethackrc;
            $orig->($self, "o:0,\$d\ni");
            $orig->($self, "$nethackrc\eg");
            my $last_buf = '';
            my $buf = '';
            while (1) {
                next unless defined($self->telnet_read($buf, 1024));
                $_ = $last_buf . $buf;
                last if /\e\[.*?'g' is not implemented/;
                $last_buf = $buf;
            }
            $orig->($self, ":wq\n");
        }
    }
    else
    {
        return $orig->($self, $text);
    }
};

around 'dgl_to_user' => sub
{
    my $orig = shift;
    my ($self, $text) = @_;

    if ($self->logged_in)
    {
        $text =~ s/(o\) Edit option file)/$1  \e[1;30mTab) edit options locally\e[0m/g;
    }

    return $orig->($self, $text);
};
# }}}

1;
