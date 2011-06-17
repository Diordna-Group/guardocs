#!/usr/bin/perl

# getnumber.pl -> (c) 2006-05-17 by Urs Pfister
# tool for printing out the filename for a document

use lib '/home/cvs/archivista/jobs';
use AVJobs;

my $akte = shift;
my $seite = shift;

my $name= AVJobs::getFileNameNr($akte,$seite,"A");
print "$name\n";
