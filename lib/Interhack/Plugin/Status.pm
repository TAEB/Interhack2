#!/usr/bin/env perl
package Interhack::Plugin::Status;
use Calf::Role;

our $VERSION = '1.99_01';

# attributes {{{
has st => (
    isa => 'Int',
    per_load => 1,
    default => 0,
    trigger => \&update_stats,
);

has dx => (
    isa => 'Int',
    per_load => 1,
    default => 0,
    trigger => \&update_stats,
);

has co => (
    isa => 'Int',
    per_load => 1,
    default => 0,
    trigger => \&update_stats,
);

has in => (
    isa => 'Int',
    per_load => 1,
    default => 0,
    trigger => \&update_stats,
);

has wi => (
    isa => 'Int',
    per_load => 1,
    default => 0,
    trigger => \&update_stats,
);

has ch => (
    isa => 'Int',
    per_load => 1,
    default => 0,
    trigger => \&update_stats,
);

has name => (
    isa => 'Str',
    per_load => 1,
    default => '',
    trigger => \&update_char,
);

has align => (
    isa => 'Str',
    per_load => 1,
    default => '',
    trigger => \&update_char,
);

has sex => (
    isa => 'Str',
    default => '',
    trigger => \&update_char,
);

has role => (
    isa => 'Str',
    per_load => 1,
    default => '',
    trigger => \&update_char,
);

has race => (
    isa => 'Str',
    per_load => 1,
    default => '',
    trigger => \&update_char,
);

has dlvl => (
    isa => 'Str',
    per_load => 1,
    default => 'Dlvl:1',
    trigger => \&update_dlvl,
);

has au => (
    isa => 'Int',
    per_load => 1,
    default => 0,
    trigger => \&update_au,
);

has hp => (
    isa => 'Int',
    per_load => 1,
    default => 0,
    trigger => \&update_hp,
);

has maxhp => (
    isa => 'Int',
    per_load => 1,
    default => 0,
    trigger => \&update_hp,
);

has pw => (
    isa => 'Int',
    per_load => 1,
    default => 0,
    trigger => \&update_pw,
);

has maxpw => (
    isa => 'Int',
    per_load => 1,
    default => 0,
    trigger => \&update_pw,
);

has ac => (
    isa => 'Int',
    per_load => 1,
    default => 0,
    trigger => \&update_ac,
);

has xlvl => (
    isa => 'Int',
    per_load => 1,
    default => 0,
    trigger => \&update_xp,
);

has xp => (
    isa => 'Int',
    per_load => 1,
    default => 0,
    trigger => \&update_xp,
);

has turn => (
    isa => 'Int',
    per_load => 1,
    default => 0,
    trigger => \&update_turn,
);

has status => (
    isa => 'Str',
    per_load => 1,
    default => '',
    trigger => \&update_status,
);

has score => (
    isa => 'Int',
    per_load => 1,
    default => 0,
    trigger => \&update_score,
);

has show_sl => (
    isa => 'Bool',
    per_load => 1,
    default => 0,
);

has show_bl => (
    isa => 'Bool',
    per_load => 1,
    default => 0,
);

has botl_stats => (
    isa => 'HashRef',
    per_load => 1,
    default => sub { {} },
);
# }}}
# private variables {{{
my %aligns = (lawful  => 'Law',
              neutral => 'Neu',
              chaotic => 'Cha',
);

my %sexes = (male   => 'Mal',
             female => 'Fem',
);

my %races = ('dwarven' => 'Dwa',
             'elven'   => 'Elf',
             'human'   => 'Hum',
             'orcish'  => 'Orc',
             'gnomish' => 'Gno',
);

my %roles = (Archeologist => 'Arc',
             Barbarian    => 'Bar',
             Caveman      => 'Cav',
             Cavewoman    => 'Cav',
             Healer       => 'Hea',
             Knight       => 'Kni',
             Monk         => 'Mon',
             Priest       => 'Pri',
             Priestess    => 'Pri',
             Rogue        => 'Rog',
             Ranger       => 'Ran',
             Samurai      => 'Sam',
             Tourist      => 'Tou',
             Valkyrie     => 'Val',
             Wizard       => 'Wiz',
);
# }}}
# private methods {{{
sub handle_new_login # {{{
{
    my $self = shift;

    return unless $self->topline =~ /^\w+ (?:\w+ )?(\w+), welcome to NetHack!  You are a (\w+) (\w+) (\w+)(?: (\w+))?\./;

    if (!defined($5)) {
        $self->name($1);
        $self->align($aligns{$2});
        $self->race($races{$3});
        $self->role($roles{$4});
        $self->sex($4 =~ /(?:woman|ess)$/ ? "Fem" : "Mal");
    }
    else {
        $self->name($1);
        $self->align($aligns{$2});
        $self->race($races{$4});
        $self->role($roles{$5});
        $self->sex($sexes{$3});
    }
} # }}}
sub handle_returning_login # {{{
{
    my $self = shift;

    return unless $self->topline =~ /^\w+ (?:\w+ )?(\w+), the (\w+) (\w+), welcome back to NetHack!/;

    $self->name($1);
    $self->race($races{$2});
    $self->role($roles{$3});
    $self->sex("Fem") if $3 eq "Cavewoman" || $3 eq "Priestess";
    $self->sex("Mal") if $3 eq "Caveman"   || $3 eq "Priest";
} # }}}
sub parse_status_line # {{{
{
    my $self = shift;
    # XXX: show_sl and show_bl aren't working properly - look into this

    my @groups = $self->vt->row_plaintext(23) =~ /^(\w+)?.*?St:(\d+(?:\/(?:\*\*|\d+))?) Dx:(\d+) Co:(\d+) In:(\d+) Wi:(\d+) Ch:(\d+)\s*(\w+)(?:\s*S:(\d+))?/;
    $self->show_sl(@groups);
    return if @groups == 0;

    $self->st($groups[1]);
    $self->dx($groups[2]);
    $self->co($groups[3]);
    $self->in($groups[4]);
    $self->wi($groups[5]);
    $self->ch($groups[6]);
    $self->align($aligns{lc $groups[7]});
    $self->score($groups[8]) if $groups[8];
    $self->name($groups[0]) if $groups[0];
} # }}}
sub parse_bottom_line # {{{
{
    my $self = shift;

    my @groups = $self->vt->row_plaintext(24) =~ /^(Dlvl:\d+|Home \d+|Fort Ludios|End Game|Astral Plane)\s+(?:\$|\*):(\d+)\s+HP:(\d+)\((\d+)\)\s+Pw:(\d+)\((\d+)\)\s+AC:([0-9-]+)\s+(?:Exp|Xp|HD):(\d+)(?:\/(\d+))?(?:\s+T:(\d+))?\s+(.*?)\s*$/;
    $self->show_bl(@groups);
    return if @groups == 0;

    $self->dlvl($groups[0]);
    $self->au($groups[1]);
    $self->hp($groups[2]);
    $self->maxhp($groups[3]);
    $self->pw($groups[4]);
    $self->maxpw($groups[5]);
    $self->ac($groups[6]);
    $self->xlvl($groups[7]);
    $self->xp($groups[8]) if $groups[8];
    $self->turn($groups[9]);
    $self->status(join(' ', split(/\s+/, $groups[10])));
} # }}}
sub update_char # {{{
{
    my $self = shift;
    $self->botl_stats->{char} = sprintf "%s: %s%s%s%s",
                                        $self->name,
                                        $self->role  ? $self->role . " "  : "",
                                        $self->race  ? $self->race . " "  : "",
                                        $self->sex   ? $self->sex  . " "  : "",
                                        $self->align ? $self->align       : "";
} # }}}
sub update_stats # {{{
{
    my $self = shift;
    $self->botl_stats->{stats} = sprintf "St:%d Dx:%d Co:%d In:%d Wi:%d Ch:%d",
                                         $self->st, $self->dx, $self->co,
                                         $self->in, $self->wi, $self->ch;
} # }}}
sub update_score # {{{
{
    my $self = shift;
    $self->botl_stats->{score} = defined($self->score) ?
                                     sprintf "S:%d", $self->score : "";
} # }}}
sub update_dlvl # {{{
{
    my $self = shift;
    $self->botl_stats->{dlvl} = $self->dlvl;
} # }}}
sub update_au # {{{
{
    my $self = shift;
    $self->botl_stats->{au} = "\$:" . $self->au;
} # }}}
sub update_hp # {{{
{
    my $self = shift;
    $self->botl_stats->{hp} = "HP:" . $self->hp . "(" . $self->maxhp . ")";
} # }}}
sub update_pw # {{{
{
    my $self = shift;
    $self->botl_stats->{pw} = "Pw:" . $self->pw . "(" . $self->maxpw . ")";
} # }}}
sub update_ac # {{{
{
    my $self = shift;
    $self->botl_stats->{ac} = "AC:" . $self->ac;
} # }}}
sub update_xp # {{{
{
    my $self = shift;
    $self->botl_stats->{xp} = sprintf "Xp:%s%s",
                                $self->xlvl, $self->xp ? "/" . $self->xp : "";
} # }}}
sub update_turn # {{{
{
    my $self = shift;
    $self->botl_stats->{turn} = "T:" . $self->turn;
} # }}}
sub update_status # {{{
{
    my $self = shift;
    $self->botl_stats->{status} = $self->status;
} # }}}
# }}}
# method modifiers {{{
before 'mangle_output' => sub
{
    my ($self, $text) = @_;

    handle_new_login($self);
    handle_returning_login($self);
    parse_status_line($self);
    parse_bottom_line($self);
};
# }}}

1;
