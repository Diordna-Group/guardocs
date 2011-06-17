#!/usr/bin/perl

=head1 fieldimport.pl $importfile

(c) 2006, Archivista GmbH, tb

imports Fieldnames and Codes from an import file.

=cut

use lib "/home/cvs/archivista/jobs";

use strict;
use AVDocs;

my $importfile = shift;
my $database = "archivlt";
my ($av,$rows,@fieldlist);

my $fld_flddef = "FeldDefinition";
my $fld_def = "Definition";
my $fld_fldcode = "FeldCode";
my $fld_code = "Code";
my $val_flddef = "Mandant";
my $val_fldcode = "MandantNr";

$av = AVDocs->new();
$av->setDatabase($database);
if ($av->setTable($av->TABLE_FIELDLISTS)) {
  $av->readFile($importfile,\$rows);
  if ($rows ne "") {
    $rows =~ s/\r//g;
	  my $pflds = [$fld_flddef,$fld_def,$fld_fldcode,$fld_code];
    @fieldlist = split "\n",$rows;
		shift @fieldlist;
    foreach (@fieldlist) {
      my ($code,$vorname,$name) = split "\t",$_;
			$name .= ", $vorname" if $vorname ne "";
			print "$name--$code\n";
		  $code = int $code;
		  my $pvals = [$val_flddef,$name,$val_fldcode,$code];
      $av->add($pflds,$pvals);
    }
	} else {
    $av->logMessage("table feldlisten does not exist!");
	}
} else {
  $av->logMessage("empty or non existing file: $importfile!");
}




