#!/usr/bin/perl

=head1 fieldimport.pl $importfile

(c) 2006, Archivista GmbH, tb

imports Fieldnames and Codes from an import file.

=cut


use strict;
use AVDocs;

my $database = "gutenberg";
my $fld_flddef = "FeldDefinition";
my $fld_def = "Definition";
my @fields = ("Creator","Language","Subject");
my $av = AVDocs->new();
$av->setDatabase($database);
if ($av->setTable($av->TABLE_FIELDLISTS)) {
	$av->deleteAll($av->TABLE_FIELDLISTS);
  foreach (@fields) {
	  my $field = $_;
	  my $file = "/tmp/".lc($field).".txt";
		my $rows = "";
    $av->readFile($file,\$rows);
    $rows =~ s/\r//g;
		my @vals = split(/\n/,$rows);
		foreach (@vals) {
		  my $val = $_;
      $av->add(["Definition","FeldDefinition"],[$val,$field]);
    }
	}
}




