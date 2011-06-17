#!/usr/bin/perl

=head1 fieldimport.pl $importfile

(c) 2006, Archivista GmbH, tb

imports Fieldnames and Codes from an import file.

=cut

use lib "/home/cvs/archivista/jobs";

use strict;
use AVDocs;

my $importfile = shift;
my $database = "kunden";
my ($av,$rows,@fieldlist);

my $fld_flddef = "FeldDefinition";
my $fld_def = "Definition";
my $fld_fldcode = "FeldCode";
my $fld_code = "Code";
my $val_flddef = "KundenName";
my $val_fldcode = "KundenNr";

$av = AVDocs->new();
$av->setDatabase($database);
if ($av->setTable($av->TABLE_FIELDLISTS)) {
  $av->readFile($importfile,\$rows);
  if ($rows ne "") {
	  $av->deleteAll($av->TABLE_FIELDLISTS);
    $rows =~ s/\r//g;
	  my $pflds = [$fld_flddef,$fld_def,$fld_fldcode,$fld_code];
    @fieldlist = split "\n",$rows;
    foreach (@fieldlist) {
      my ($code,$def) = split "\t",$_;
		  $code = int $code;
		  my $pvals = [$val_flddef,$def,$val_fldcode,$code];
      $av->add($pflds,$pvals);
    }
	} else {
    $av->logMessage("table feldlisten does not exist!");
	}
} else {
  $av->logMessage("empty or non existing file: $importfile!");
}




