#!/usr/bin/perl

use strict;
my $options = shift;
open(FOUT,">>/home/data/archivista/av.log");
print FOUT "$0--$options\n";
close(FOUT);
my @opts = split(',',$options);
foreach my $id (@opts) {
  system("qm start $id");
}

