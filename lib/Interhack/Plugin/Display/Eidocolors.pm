#!/usr/bin/env perl
package Interhack::Plugin::Display::Eidocolors;
use Calf::Role;

our $VERSION = '1.99_01';

# deps {{{
sub depend { qw/Recolor/ }
# }}}
# methods {{{
sub BUILD # {{{
{
    my $self = shift;

    my $called = qr/called|of/;
    my $colors = qr/(?:\e\[[0-9;]*m)?/;

    my @eci = @{ $self->config->{plugin_options}{Eidocolors}{include} || [] };
    my @ece = @{ $self->config->{plugin_options}{Eidocolors}{exclude} || [] };

    my $eci = { map { $_ => 1 } @eci };
    my $ece = { map { $_ => 1 } @ece };
    my $ec  = $self->config->{plugin_options}{Eidocolors};

# BUC {{{
    if (!$ece->{buc})
    {
# !C !B !UC {{{
        if (!$ece->{shortbuc})
        {
            $self->recolor(qr/(?<=named )!C\b/ => $ec->{semiknown} || $ec->{notcursed} || "brown");
            $self->recolor(qr/(?<=named )!B\b/ => $ec->{semiknown} || $ec->{notblessed} || "brown");
            $self->recolor(qr/(?<=named )!UC\b/ => $ec->{semiknown} || $ec->{notuncursed} || "brown");
        }
# }}}
# blessed uncursed cursed {{{
        if (!$ece->{longbuc})
        {
            $self->recolor(qr/\buncursed\b|(?<=named )UC?\b/ => $ec->{uncursed} || "brown");
            $self->recolor(qr/\bblessed\b|(?<=named )B\b/ => $ec->{blessed} || "cyan");
            $self->recolor(qr/\bcursed\b|(?<=named )C\b/ => $ec->{cursed} || "red");
        }
# }}}
    }
# }}}
# erosion {{{
    $self->recolor(qr/(?:very|thoroughly)? ?(?:rusty|burnt|rotted|corroded)/ => $ec->{erosion} || "red") if $eci->{erosion};
# }}}
# water sports {{{
    if (!$ece->{water})
    {
# holy water {{{
        if (!$ece->{holywater})
        {
            $self->recolor(qr/\bholy water\b/ => $ec->{holywater} || "bcyan");
            $self->recolor(qr/\bblessed clear potions?\b/ => $ec->{holywater} || "bcyan");
            $self->recolor(qr/\bblessed potions? called water\b/ => $ec->{holywater} || "bcyan");
            $self->recolor(qr/\bclear potions? named \b(?:holy|blessed|B)\b/ => $ec->{holywater} || "bcyan");
            $self->recolor(qr/\bpotions? of water named \b(?:holy|blessed|B)\b/ => $ec->{holywater} || "bcyan");
            $self->recolor(qr/\bpotions? called water named \b(holy|blessed|B)\b/ => $ec->{holywater} || "bcyan");
        }
# }}}
# unholy water {{{
        if (!$ece->{unholywater})
        {
            $self->recolor(qr/\bunholy water\b/ => $ec->{unholywater} || "orange");
            $self->recolor(qr/\bcursed clear potions?\b/ => $ec->{unholywater} || "orange");
            $self->recolor(qr/\bcursed potions? called water\b/ => $ec->{unholywater} || "orange");
            $self->recolor(qr/\bclear potions? named \b(?:unholy|cursed|C)\b/ => $ec->{unholywater} || "orange");
            $self->recolor(qr/\bpotions? of water named \b(?:unholy|cursed|C)\b/ => $ec->{unholywater} || "orange");
            $self->recolor(qr/\bpotions? called water named (?:unholy|cursed|C)\b/ => $ec->{unholywater} || "orange");
        }
# }}}
# split water coloring {{{
        if ($eci->{splitwater})
        {
            $self->recolor(qr/\bclear potions?\b/ => $ec->{water} || "cyan");
            $self->recolor(qr/\b(?<= of )water\b/ => $ec->{water} || "cyan");
            $self->recolor(qr/\b(?<= of holy )water\b/ => $ec->{water} || "cyan");
            $self->recolor(qr/\b(?<= of unholy )water\b/ => $ec->{water} || "cyan");
            $self->recolor(qr/\b(?<= called )water\b/ => $ec->{water} || "cyan");
            $self->recolor(qr/\b(?<!un)holy(?= (?:\e\[[0-9;]*m)?water)\b/ => $ec->{holywater} || "bcyan");
            $self->recolor(qr/\bunholy(?= (?:\e\[[0-9;]*m)?water)\b/ => $ec->{unholywater} || "orange");
        }
# }}}
    }
# }}}
# food conducts {{{
    if (!$ece->{food})
    {
# vegan {{{
        if (!$ece->{vegan})
        {
            $self->recolor(qr/\b(?:food |cram |[KC]-)rations?\b/ => $ec->{vegan} || "bgreen");
            $self->recolor(qr/\btins? (?:called|named|of) spinach/ => $ec->{vegan} || "bgreen");
            $self->recolor(qr/(?<!soft |hard |lled )\boranges?(?! dragon| gem| potion| spellbook)\b/ => $ec->{vegan} || "bgreen");
            $self->recolor(qr/\bpears?\b/ => $ec->{vegan} || "bgreen");
            $self->recolor(qr/\b(?:gunyoki|lembas wafer|melon|carrot|pear|apple|banana|kelp frond|slime mold|brain)s?\b/ => $ec->{vegan} || "bgreen");
            $self->recolor(qr/\bsprigs? of wolfsbane\b/ => $ec->{vegan} || "bgreen");
            $self->recolor(qr/\beucalyptus lea(?:f|ves)\b/ => $ec->{vegan} || "bgreen");
            $self->recolor(qr/\bcloves? of garlic\b/ => $ec->{vegan} || "bgreen");
            $self->recolor(qr/\b(?:tin of )?(?:gelatinous cube|acid blob|quivering blob|lichen|shrieker|violet fungus|(?:blue|spotted|ochre) jelly|(?:brown|yellow|green) mold)(?: corpse)?\b/ => $ec->{vegan} || "bgreen");
        }
# }}}
# vegetarian {{{
        if (!$ece->{vegetarian})
        {
            $self->recolor(qr/\b(?:egg|pancake|fortune cookie|candy bar|cream pie)s?\b/ => $ec->{vegetarian} || "green");
            $self->recolor(qr/\blumps? of royal jelly\b/ => $ec->{vegetarian} || "green");
            $self->recolor(qr/\b(?:tin of )?(?:brown pudding|gray ooze)(?: corpse)?\b/ => $ec->{vegetarian} || "green");
        }
# }}}
    }
# }}}
# goodies {{{
    if (!$ece->{goodies})
    {
        $self->recolor(qr/(?<!cursed )\bbag $called holding\b/ => $ec->{boh} || $ec->{goody} || "magenta") unless $ece->{boh};
        $self->recolor(qr/(?<!cursed )\b(?:stone called )?luck(?:stone)?\b/ => $ec->{luckstone} || $ec->{goody} || "magenta") unless $ece->{luckstone};
        $self->recolor(qr/\bwand $called wishing\b/ => $ec->{wishing} || $ec->{goody} || "magenta") unless $ece->{wishing};
        $self->recolor(qr/\bmagic marker\b/ => $ec->{marker} || $ec->{goody} || "magenta") unless $ece->{marker};
        $self->recolor(qr/\bmagic lamp\b/ => $ec->{magiclamp} || $ec->{goody} || "magenta") unless $ece->{magiclamp};
        $self->recolor(qr/\blamp called magic\b/ => $ec->{magiclamp} || $ec->{goody} || "magenta") unless $ece->{magiclamp};
        $self->recolor(qr/(?<!cursed )\bunicorn horn\b(?!\s+\[)/ => $ec->{unihorn} || $ec->{goody} || "magenta") unless $ece->{unihorn};
        $self->recolor(qr/\btinning kit\b/ => $ec->{tinkit} || "magenta") unless $ece->{tinkit};
        $self->recolor(qr/\bring $called regen(?:eration)?\b/ => $ec->{regen} || $ec->{goody} || "magenta") unless $ece->{regen};
        $self->recolor(qr/\bring $called conflict\b/ => $ec->{conflict} || $ec->{goody} || "magenta") unless $ece->{conflict};
        $self->recolor(qr/\bring $called (?:FA|free action)\b/ => $ec->{freeaction} || $ec->{goody} || "magenta") unless $ece->{freeaction};
        $self->recolor(qr/\bring $called (?:TC|teleport control)\b/ => $ec->{tc} || $ec->{goody} || "magenta") unless $ece->{tc};
        $self->recolor(qr/\bring $called lev(?:itation)?\b/ => $ec->{lev} || $ec->{goody} || "magenta") unless $ece->{lev};
        $self->recolor(qr/\bamulet $called (?:LS|life ?saving)\b/ => $ec->{ls} || $ec->{goody} || "magenta") unless $ece->{ls};
        $self->recolor(qr/\bamulet $called ref(?:lection)?\b/ => $ec->{ref} || $ec->{goody} || "magenta") unless $ece->{ref};
        $self->recolor(qr/\bc(?:o|hi)ckatrice (?:corpse|egg)s?\b/ => $ec->{trice} || $ec->{goody} || "magenta") unless $ece->{trice};
        $self->recolor(qr/\beggs? named cockatrice\b/ => $ec->{trice} || $ec->{goody} || "magenta") unless $ece->{trice};
        $self->recolor(qr/\blizard corpses?\b/ => $ec->{lizard} || $ec->{goody} || "magenta") unless $ece->{lizard};
        $self->recolor(qr/\bstethoscope\b/ => $ec->{scope} || $ec->{goody} || "magenta") unless $ece->{scope};
        $self->recolor(qr/\bwraith corpses?\b/ => $ec->{wraith} || $ec->{goody} || "magenta") unless $ece->{wraith};
    }
# instruments {{{
    if (!$ece->{instrument})
    {
        $self->recolor(qr/\b(?:(?:tooled|fire|frost)? horn)\b/ => $ec->{instrument} || $ec->{goody} || "magenta");
        $self->recolor(qr/\bhorn $called (?:tooled|fire|frost)\b/ => $ec->{instrument} || $ec->{goody} || "magenta");
        $self->recolor(qr/\b(?:magic|wooden) (?:harp|flute)\b/ => $ec->{instrument} || $ec->{goody} || "magenta");
        $self->recolor(qr/\b(?:harp|flute) $called (?:magic|wooden)\b/ => $ec->{instrument} || $ec->{goody} || "magenta");
        $self->recolor(qr/\bbugle\b/ => $ec->{instrument} || $ec->{goody} || "magenta");
    }
# }}}
# }}}
# artifacts {{{
    if (!$ece->{artifact})
    {
# unaligned {{{
        $self->recolor(qr/\b(?:Dragonbane|Fire Brand|Frost Brand|Ogresmasher|Trollsbane|Werebane)\b/ => $ec->{uartifact} || $ec->{artifact} || "bgreen");
# }}}
#lawful {{{
        $self->recolor(qr/\b(?:Demonbane|Excalibur|Grayswandir|Snickersnee|Sunsword)\b/ => $ec->{lartifact} || $ec->{artifact} || "bgreen");
        $self->recolor(qr/(?:[Tt]he )?\b(?:Orb of Detection|Sceptre of Might|Magic Mirror of Merlin|Mitre of Holiness|Tsurugi of Muramasa)\b/ => $ec->{qlartifact} || $ec->{qartifact} || $ec->{lartifact} || $ec->{artifact} || "bgreen");
# }}}
#neutral {{{
        $self->recolor(qr/\b(?:Cleaver|Giantslayer|Magicbane|Mjollnir|Vorpal Blade)\b/ => $ec->{nartifact} || $ec->{artifact} || "bgreen");
        $self->recolor(qr/(?:[Tt]he )?\b(?:Heart of Ahriman|Staff of Aesculapius|Eyes of the Overworld|Platinum Yendorian Express Card|Orb of Fate|Eye of the Aethiopica)\b/ => $ec->{qnartifact} || $ec->{qartifact} || $ec->{nartifact} || $ec->{artifact} || "bgreen");
# }}}
#chaotic {{{
        $self->recolor(qr/\b(?:Grimtooth|Orcrist|Sting|Stormbringer)\b/ => $ec->{cartifact} || $ec->{artifact} || "bgreen");
        $self->recolor(qr/(?:[Tt]he )?\b(?:Longbow of Diana|Master Key of Thievery)\b/ => $ec->{qcartifact} || $ec->{qartifact} || $ec->{cartifact} || $ec->{artifact} || "bgreen");
    }
# }}}
#invocation items {{{
        $self->recolor(qr/(?:[Tt]he )?(?<!cursed )\b(?:Bell of Opening|silver bell|Candelabrum of Invocation|candelabrum|Book of the Dead|papyrus spellbook)\b/ => $ec->{invocation} || "bmagenta") unless $ece->{invocation};
# }}}
#raison d'etre {{{
        $self->recolor(qr/(?:[Tt]he )?\bAmulet of Yendor(?= named\b)/ => $ec->{yendor} || "bmagenta") unless $ece->{yendor};
# }}}
# }}}
# cursed goodies {{{
    if (!$ece->{goodies})
    {
        $self->recolor(qr/\bcursed bag $called holding\b/ => $ec->{cboh} || "bred") unless $ece->{cboh};
        $self->recolor(qr/\bcursed (?:stone called )?luck(?:stone)?\b/ => $ec->{cluck} || "bred") unless $ece->{cluck};
        $self->recolor(qr/\bcursed unicorn horn\b(?!\s+\[)/ => $ec->{chunihorn} || "bred") unless $ece->{chunihorn};
        $self->recolor(qr/\bcursed (?:Bell of Opening|silver bell|Candelabrum of Invocation|candelabrum|Book of the Dead|papyrus spellbook)\b/ => $ec->{cinvocation} || "bred") unless $ece->{cinvocation};
    }
# }}}
# bad stuff! {{{
    $self->recolor(qr/\b(?:stone called )?(?<!your )load(?:stone)?\b/ => $ec->{loadstone} || "bred") unless $ece->{loadstone};
# }}}
# watch out bag of holding {{{
    if (!$ece->{bohboom})
    {
        $self->recolor(qr/\bbag $called tricks\b/ => $ec->{bot} || $ec->{bohboom} || "blue");
        $self->recolor(qr/\bwand $called [^\e]*?(?<!!)canc(?:ellation)?\b(?! named ${colors}e(?:mpty)?\b| (?:named .*?)?\($colors\d+$colors:${colors}(?:0|-1)$colors\))/ => $ec->{canc} || $ec->{bohboom} || "blue");
        $self->recolor(qr/\bwand $called (?:\w+ )?vanish(?:e[rs])?\b/ => $ec->{vanish} || $ec->{canc} || $ec->{bohboom} || "blue");
    }
# }}}
# shinies {{{
    $self->recolor(qr/\d+ (?:gold piece|[Zz]orkmid)s?\b/ => $ec->{gold} || "yellow") unless $ece->{gold};
    $self->recolor(qr/\bgems? $called valuable(?: \w+| yellowish brown)?\b/ => $ec->{goodsoft} || $ec->{goodgem} || "brown") unless $ece->{gem};
    $self->recolor(qr/\bgems? $called hard(?: \w+| yellowish brown)?\b/ => $ec->{goodhard} || $ec->{goodgem} || "yellow") unless $ece->{gem};
# too tired to do this now {{{
#soft gems
#MENUCOLOR=" \([0-9]+\|an?\|gems? .*\) \(uncursed \|cursed \|blessed \)?\(dilithium\|opal\|garnet\|jasper\|agate\|jet\|obsidian\|jade\|citrine\|chrysoberyl\|amber\|amethyst\|fluorite\|turquoise\)\(e?s\)?\( stones?\| gems?\| crystals?\)?\( named .*\)?$"=brown
##hard gems
#MENUCOLOR=" \([0-9]+\|an?\|gems?.*\) \(uncursed \|cursed \|blessed \)?\(diamond\|rub\(y\|ies\)\|jacinth\|sapphire\|black opal\|emerald\|topaz\|aquamarine\)\(e?s\)?\( stones?\| gems?\)?\( named .*\)?$"=yellow
# }}}
# }}}
# interhack-specific stuff {{{
# charges (originally from doy) {{{
    if (!$ece->{charges_individual})
    {
        $self->recolor(qr/(?<=\()0(?=:)/        => $ec->{zero_recharges} || "cyan");  # 0 recharge
        $self->recolor(qr/(?<=:)(?:0|-1)(?=\))/ => $ec->{zero_charges} || "red");   # no charges
        $self->recolor(qr/(?<=:)\d+(?=\))/      => $ec->{recharges} || "cyan");  # many charges
        $self->recolor(qr/(?<=\()\d+(?=:)/      => $ec->{charges} || "green"); # many recharges
    }
    elsif (!$ece->{charges})
    {
        $self->recolor(qr/\([\d-]+:\d+\)/         => $ec->{charged} || "cyan");
        $self->recolor(qr/\([\d-]+:0\)/           => $ec->{zero_charges} || $ec->{empty} || "darkgray");
    }
# }}}
# enchantment (originally from doy) {{{
    if (!$ece->{enchantment})
    {
        $self->recolor(qr/\s\+0/               => $ec->{plus0} || "brown");
        $self->recolor(qr/\s\+[1-3]/           => $ec->{plus13} || $ec->{plus} || "green");
        $self->recolor(qr/\s\+[4-9]\d*/        => $ec->{plus4} || $ec->{plus} || "bgreen");
        $self->recolor(qr/(?<!AC)\s\-[1-9]\d*/ => $ec->{minus} || "red");
    }
# }}}
# empty wands and tools {{{
    $self->recolor(qr/(?<=named )e(?:mpty)?\b/ => $ec->{empty} || "darkgray") unless $ece->{empty};
# }}}
# item in use {{{
    $self->recolor(qr/(?<=\()(?:\d candles, )?lit(?=\))/ => $ec->{lit} || "yellow") unless $ece->{lit};
# equipment (originally by Stabwound) {{{
    if (!$ece->{wielded})
    {
        $self->recolor(qr/ \(weapon in [^)]+\)/ => $ec->{primary} || $ec->{weapon} || $ec->{eq} || "brown");
        $self->recolor(qr/ \(wielded[^)]*\)/ => $ec->{secondary} || $ec->{weapon} || $ec->{eq} || "brown");
        $self->recolor(qr/ \(alternate weapon[^)]*\)/ => $ec->{alternate} || $ec->{weapon} || $ec->{eq} || "brown");
    }

    $self->recolor(qr/ \(in quiver\)/ => $ec->{quiver} || $ec->{eq} || "brown") unless $ece->{quiver};

    if (!$ece->{worn})
    {
        $self->recolor(qr/ \(being worn\)/ => $ec->{worn} || $ec->{eq} || "brown");
        $self->recolor(qr/ \(embedded in your skin\)/ => $ec->{worn} || $ec->{eq} || "brown");
        $self->recolor(qr/ \(on left [^)]+\)/ => $ec->{worn} || $ec->{eq} || "brown");
        $self->recolor(qr/ \(on right [^)]+\)/ => $ec->{worn} || $ec->{eq} || "brown");
        $self->recolor(qr/ \(in use\)/ => $ec->{worn} || $ec->{eq} || "brown");
    }
# }}}
# }}}
# pretty useless items {{{
    if (!$ece->{useless})
    {
# things explicitly named "crap" {{{
        $self->recolor(qr/\w+ called (?:crap|junk|worthless)\b/ => $ec->{useless_crap} || $ec->{useless} || "darkgray") unless $ece->{useless_crap};
# }}}
# scrolls {{{
        $self->recolor(qr/scrolls? (?:called|of) (?:light|confuse monster|stinking cloud|punishment|fire|destroy armor|amnesia|create monster|food detection)\b/ => $ec->{useless_scrolls} || $ec->{useless} || "darkgray") unless $ece->{useless_scrolls};
        $self->recolor(qr/scrolls? called (?:\w+\s+)+50(?!\/)/ => $ec->{useless_scrolls} || $ec->{useless} || "darkgray") unless $ece->{useless_scrolls};
# }}}
# potions {{{
        $self->recolor(qr/(?!smoky )potions? (?:called|of) (?!smoky\b)(?:[\w-]+ )?(?:booze|sake|fruit juice|see invisible|sickness|deli|confusion|hallucination|restore ability|sleeping|blindness|invisibility|monster detection|obj(?:ect)? ?det(?:ection)?|(?:(?!1x)\d+x)?OD|levitation|polymorph|acid|oil|paralysis)\b/ => $ec->{useless_potions} || $ec->{useless} || "darkgray") unless $ece->{useless_potions};

        # only 150 potion of note is gain energy, so we can color all 150 crap
        # three regex for '150' or 'NxOD' or both, for sanity reasons :)
        $self->recolor(qr/(?!smoky )potions? called (?!smoky\b)(?:[\w-]+\s+)+1?50(?!\/)(?: (?:(?!1x)\d+x)?OD)?/ => $ec->{useless_potions} || $ec->{useless} || "darkgray") unless $ece->{useless_potions};
        $self->recolor(qr/(?!smoky )potions? called (?!smoky\b)(?:[\w-]+\s+)+ (?:(?!1x)\d+x)?OD/ => $ec->{useless_potions} || $ec->{useless} || "darkgray") unless $ece->{useless_potions};
        $self->recolor(qr/(?!smoky )potions? called (?!smoky\b)(?:[\w-]+\s+)+1?50(?!\/)/ => $ec->{useless_potions} || $ec->{useless} || "darkgray") unless $ece->{useless_potions};
# }}}
# rings {{{
        $self->recolor(qr/ring (?:of|called) (?:adornment|hunger|protection(?: from shape changers)?|stealth|sustain ability|warning|aggravate monster|\w+ resistance|gain \w+|increase \w+|see invisible|searching|polymorph(?: control)?)\b/ => $ec->{useless_rings} || $ec->{useless} || "darkgray") unless $ece->{useless_rings};
        $self->recolor(qr/ring called (?:[\w-]+\s+)+1(?:0|5)0(?!\/)/ => $ec->{useless_rings} || $ec->{useless} || "darkgray") unless $ece->{useless_rings}; # only exception is =invis, which is borderline anyway
# }}}
# wands {{{
        $self->recolor(qr/wand (?:called|of) (?:light|nothing|locking|make invisible|opening|probing|secret door detection|(?:speed|slow)(?: monster)?|undead turning|create monster)\b/ => $ec->{useless_wands} || $ec->{useless} || "darkgray") unless $ece->{useless_wands};
        $self->recolor(qr/wand called (?:\w+\s+)+(?:100|nomsg)(?!\/)/ => $ec->{useless_wands} || $ec->{useless} || "darkgray") unless $ece->{useless_wands};
# }}}
# amulets {{{
        $self->recolor(qr/amulet (?:called|of) (?:versus poison|change|ESP|magical breathing|restful sleep|strangulation|unchanging)\b/ => $ec->{useless_amulets} || $ec->{useless} || "darkgray") unless $ece->{useless_amulets};
        $self->recolor(qr/amulet versus poison\b/ => $ec->{useless_amulets} || $ec->{useless} || "darkgray") unless $ece->{useless_amulets};
# }}}
    }
# }}}
# unidentified magical armor {{{
    if (!$ece->{unid_armor})
    {
        $self->recolor(qr/(?:mud|buckled|riding|snow|hiking|combat|jungle) boots/ => $ec->{unid_boots} || $ec->{unid_armor} || "green");
        $self->recolor(qr/piece of cloth|opera cloak|ornamental cope|tattered cape/ => $ec->{unid_cloak} || $ec->{unid_armor} || "green");
        $self->recolor(qr/(?:plumed|etched|crested|visored) helmet/ => $ec->{unid_helmet} || $ec->{unid_armor} || "green");
        $self->recolor(qr/(?:old|riding|padded|fencing) gloves/ => $ec->{unid_gloves} || $ec->{unid_armor} || "green");
    }
# }}}
# goodies (other) {{{
    if (!$ece->{goodies_other})
    {
# scrolls {{{
        $self->recolor(qr/scrolls? (?:called|of) (?:charging|genocide)\b/ => $ec->{good_scrolls} || $ec->{goodies_other} || "magenta") unless $ece->{good_scrolls};
# }}}
# potions {{{
        $self->recolor(qr/potions? (?:called|of) (?:gain level|(?:full |extra )?healing)\b/ => $ec->{good_potions} || $ec->{goodies_other} || "magenta") unless $ece->{good_potions};
# }}}
# wands {{{
        $self->recolor(qr/wand (?:called|of) (?:death|tele(?:portation)?)\b/ => $ec->{good_wands} || $ec->{goodies_other} || "magenta") unless $ece->{good_wands};
# }}}
    }
# }}}
# }}}
} # }}}
# }}}

1;

