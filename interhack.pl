#!/usr/bin/perl
use strict;
use warnings;
use lib 'lib';
use Interhack;
use Term::ReadKey;

$| = 1;
ReadMode 3;
END { ReadMode 0 }
$SIG{INT} = sub {};

Interhack->new->run;

