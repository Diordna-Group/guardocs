#!/usr/bin/perl

=head1 Keywording after batch import of office files (c) 2009, Archivista GmbH

Needs processed.txt from putfiles.pl

=cut

use strict;
use lib "/home/cvs/archivista/jobs";
use AVDocs;

my $database = shift;
my $field = shift;
my $logfile = shift;
if ($database eq "" || $field eq "" || $logfile eq "") {
  print "Correct imported file names and put old path to a field.\n".
	      "Usage:: $0 databasename oldpathdbfield processed.txt\n".
				"Example: $0 archivista Titel processed.txt\n\n";
				exit;
}

my ($av,$rows,@files);
$av = AVDocs->new(); # get object
$av->setDatabase($database); # set database
if ($av->setTable($av->TABLE_DOCS)) {
  $av->readFile($logfile,\$rows);
  if ($rows ne "") {
    $rows =~ s/\r//g;
    @files = split "\n",$rows;
    foreach (@files) { # go through every filename
		  my $file = $_;
			chomp $file;
		  my @parts = split("--",$file);
			my $check = shift @parts;
			my $nr = shift @parts;
			my $laufnr = shift @parts;
			my $pathfile = join("--",@parts);
			my @parts1 = split(/\//,$pathfile);
			my $filename = pop @parts1;
			my $search = "office;$nr\.\%"; # like only works if we add quoting (at end)
			if ($check eq "import") {
			  my ($key) = $av->search(["~".$av->FLD_FILENAME,">".$av->FLD_DOC."-"],
				                        ["$search","0"]);
				my ($edvname) = $av->select($av->FLD_FILENAME);
				my $newfn = "office;$filename";
				$av->update([$av->FLD_FILENAME,$field],[$newfn,$pathfile]);
				print "key:$key-----$edvname-----\n";
			  print "$check--$nr--$pathfile--$filename\n";
			}
    }
	}
}




