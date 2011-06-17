#!/usr/bin/perl

use reform;
use strict;

package T4;

fields name,vorname;

sub initialize($vorname,$name) {
  self->name=$name;
	self->vorname=$vorname;
}


sub print {
  return self->vorname." ".self->name;
}


1;
