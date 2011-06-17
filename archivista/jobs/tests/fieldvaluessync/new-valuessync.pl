#!/usr/bin/perl


=head1 valuesync.pl 

(c) 2006, Archivista GmbH, tb

Script looks for jobs of a special type and syncs specified 
syncing fields if they are empty and if matching fields 
match each other.

=cut

use lib "/home/cvs/archivista/jobs/";
use strict;
use AVDocs;

#What Database do you want to use?
my $database = "testumgebung";

#fields that need to match to sync fields
my @matchfields = ("Auftraggeber","Auftrag");

#fields that will be synced if matchfields matched
my @syncfields = ("syncthis1","syncthis2");


#name of the field which defines the type of a document
my $fldtypename = "type";

#type value of documents that will be archetypes for the others
my $archetype = "ftp";

#type value of documents that will copy from their archetypes
my $imitatortype = "sne";

#suffix that should be added to type values of finished documents
my $donesuffix = "*";
#######################################################

my $av = AVDocs->new();
$av->setDatabase($database) || die "Could not change to DB";

#We need an Array with only NULL queries
#because we need to check for them in the db
my @nullarray;
for (my $i = 0; $i <= length @syncfields;$i++) {
  push  @nullarray, undef;
}

unshift @syncfields, $fldtypename;
unshift @nullarray, $imitatortype;
my @archematchflds = @matchfields;
unshift @archematchflds, $fldtypename;

my @imitatorlist = $av->keys(\@syncfields,\@nullarray);

foreach (@imitatorlist) {
	my $key = $_;
	my @matchings = $av->select(\@matchfields,$av->FLD_DOC,$key);
	my @archematchvals = @matchings;
	unshift @archematchvals,$archetype;
	my $archekey = $av->search(\@archematchflds,\@archematchvals);
	my @syncs = $av->select(\@syncfields,$av->FLD_DOC,$archekey);
	$syncs[0] = $imitatortype.$donesuffix;
	$av->update(\@syncfields,\@syncs,$av->FLD_DOC,$key);
}



