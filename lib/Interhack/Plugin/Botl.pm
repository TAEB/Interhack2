#!/usr/bin/env perl
package Interhack::Plugin::Botl;
use Calf::Role;

our $VERSION = '1.99_01';

# attributes {{{
has statusline => (
    isa => 'Str',
    default => '{char} {stats} {score}',
);

has botl => (
    isa => 'Str',
    default => '{dlvl} {au} {hp} {pw} {ac} {xp} {turn} {status}',
);
# }}}
# private variables {{{
my $blocking = 0;
# }}}
# private methods {{{
sub block_botl # {{{
{
    my $self = shift;
    my ($text) = @_;

    # strip escape chars here (properly this time...)
    # XXX: this is broken - nethack does weird things if your character is near
    # the bottom of the screen that this interferes with
    return $text unless $self->show_sl or $self->show_bl;
    my $replacement = '';
    my @real_text = split $text =~ /(\e\[[0-9;]*H)/;
    while (1) {
        last unless @real_text;
        my $substr = shift @real_text;
        $replacement .= $substr unless $blocking;

        last unless @real_text;
        my $esc_code = shift;
        $esc_code =~ /\e\[(?:([0-9]+);)?[0-9;]*H/;
        my $row = $1 || 1;
        $blocking = ($row >= 23);
        $replacement .= $esc_code;
    }

    return $replacement;
} # }}}
sub parse_botl # {{{
{
    my $self = shift;
    my ($text) = @_;

    $text =~ s/{([^}]+)}/parse_chunk($self, $1)/ge;

    return $text;
} # }}}
sub show_botl # {{{
{
    my $self = shift;

    my $output .= "\e[s";
    my $sl = parse_botl($self, $self->statusline);
    my $bl = parse_botl($self, $self->botl);
    $output .= "\e[23;1H\e[K\e[0m$sl" if $self->show_sl;
    $output .= "\e[24;1H\e[K\e[0m$bl" if $self->show_bl;
    $output .= "\e[u";
} # }}}
sub parse_chunk # {{{
{
    my ($self, $chunk) = @_;

    # method call
    if ($chunk =~ s/^_//)
    {
        my @arguments;

        # {foo:bar, baz} resolves to $self->foo('bar', 'baz')
        $chunk =~ s/:(.+)// and do
        {
            @arguments = split /[\s,]+/, $1;
        };

        $self->can($chunk) or return "{$_[1]}";
        return $self->$chunk(@arguments);
    }

    return defined $self->botl_stats->{$chunk}
                 ? $self->botl_stats->{$chunk}
                 : "{$_[1]}";
} # }}}
# }}}
# method modifiers {{{
around 'mangle_output' => sub
{
    my $orig = shift;
    my $self = shift;
    my ($text) = @_;

    # XXX: this is completely broken... needs to be debugged
    #$text = block_botl($self, $text);
    $text = $text . show_botl($self);

    $orig->($self, $text);
};
# }}}

1;
