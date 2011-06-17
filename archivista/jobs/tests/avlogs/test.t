#!/usr/bin/perl

use strict;
use T4;
use Test::Simple qw(no_plan);

my @ar = ("Urs Pfister","Tobias Binz", "Otto");

foreach (@ar) {
  my ($vorname,$name) = split(/\s/,$_);
  my $cl=T4->new($vorname,$name);
	my $expected="$vorname $name";
	my $computed=$cl->print;
	ok($computed eq $expected, "$vorname $name -> $expected");

	my $expected="$name";
	$expected=" " if $name eq "";
	my $computed=$cl->get_name;
	ok($computed eq $expected, "$name -> $expected");
}

