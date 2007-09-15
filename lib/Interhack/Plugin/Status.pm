#!/usr/bin/env perl
package Interhack::Plugin::Status;
use Calf::Role;

our $VERSION = '1.99_01';

# attributes {{{
has st => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);

has dx => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);

has co => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);

has in => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);

has wi => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);

has ch => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);

has name => (
    isa => 'Str',
    is => 'rw',
    default => '',
);

has align => (
    isa => 'Str',
    is => 'rw',
    default => '',
);

has sex => (
    isa => 'Str',
    is => 'rw',
    default => '',
);

has role => (
    isa => 'Str',
    is => 'rw',
    default => '',
);

has race => (
    isa => 'Str',
    is => 'rw',
    default => '',
);

has dlvl => (
    isa => 'Str',
    is => 'rw',
    default => 'Dlvl:1',
);

has au => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);

has hp => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);

has maxhp => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);

has pw => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);

has maxpw => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);

has ac => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);

has xlvl => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);

has xp => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);

has turn => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);

has status => (
    isa => 'Str',
    is => 'rw',
    default => '',
);

has score => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);

has show_sl => (
    isa => 'Bool',
    is => 'rw',
    default => 0,
);

has show_bl => (
    isa => 'Bool',
    is => 'rw',
    default => 0,
);

has botl_stats => (
    isa => 'HashRef',
    is => 'rw',
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

# whether or not we are currently allowing text to pass through to the screen
my $blocking = 0;
# }}}
# private methods {{{
sub handle_new_login
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
}

sub handle_returning_login
{
    my $self = shift;

    return unless $self->topline =~ /^\w+ (?:\w+ )?(\w+), the (\w+) (\w+), welcome back to NetHack!/;

    $self->name($1);
    $self->race($races{$2});
    $self->role($roles{$3});
    $self->sex("Fem") if $3 eq "Cavewoman" || $3 eq "Priestess";
    $self->sex("Mal") if $3 eq "Caveman"   || $3 eq "Priest";
}

sub parse_status_line
{
    my $self = shift;

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
}

sub parse_bottom_line
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
}

sub update_botl_hash
{
    my $self = shift;

    $self->botl_stats->{char} = sprintf "%s: %s%s%s%s",
                                        $self->name,
                                        $self->role  ? $self->role . " "  : "",
                                        $self->race  ? $self->race . " "  : "",
                                        $self->sex   ? $self->sex  . " "  : "",
                                        $self->align ? $self->align       : "";
    $self->botl_stats->{stats} = sprintf "St:%d Dx:%d Co:%d In:%d Wi:%d Ch:%d",
                                         $self->st, $self->dx, $self->co,
                                         $self->in, $self->wi, $self->ch;
    $self->botl_stats->{score} = defined($self->score) ?
                                     sprintf "S:%d", $self->score : "";
    $self->botl_stats->{dlvl} = $self->dlvl;
    $self->botl_stats->{au} = "\$:" . $self->au;
    $self->botl_stats->{hp} = "HP:" . $self->hp . "(" . $self->maxhp . ")";
    $self->botl_stats->{pw} = "Pw:" . $self->pw . "(" . $self->maxpw . ")";
    $self->botl_stats->{ac} = "AC:" . $self->ac;
    $self->botl_stats->{xp} = sprintf "Xp:%s%s",
                                $self->xlvl, $self->xp ? "/" . $self->xp : "";
    $self->botl_stats->{turn} = "T:" . $self->turn;
    $self->botl_stats->{status} = $self->status;
}
# }}}
# method modifiers {{{
before 'mangle_output' => sub
{
    my ($self, $text) = @_;

    handle_new_login($self);
    handle_returning_login($self);
    parse_status_line($self);
    parse_bottom_line($self);
    update_botl_hash($self);
};
# }}}

1;
