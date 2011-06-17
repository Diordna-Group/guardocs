#! /usr/bin/perl

=head1 coldplus for xal archiving process for Laepp AG

In the title comment we get the file name of the index information.
Then we open the index file and give back the fields to the normal
COLD process

=cut

use strict;
my $pdb = shift;
my $file = shift;

my $pathin = "/home/data/archivista/cust/laepp/cold";
my $ds = "/";
my $checkfile = "$pathin$ds"."bad";

if (-e $checkfile) {
  system("/home/data/archivista/cust/laepp/mount1.sh");
}

my $out = "";
my $filein = $pathin.$ds.$file;
if (-e $filein) {
	open(FIN,$filein);
	my @line = <FIN>;
	close(FIN);
	my $pfields = join("",@line);
	$pfields =~ s/\r\n//g;
  my %flds = ();
	my %flds0 = split(/\^/,$pfields);
  foreach (keys %flds0) {
    my $key = $_;
	  my $val = $flds0{$key};
		checkFieldsExtra($key,$val,\%flds);
  }
  foreach (keys %flds) {
  	$out = $out . ":" if $out ne "";
		my $key = $_;
		my $val = $flds{$key};
		$out = $out . "$key=$val";
	}
}
unlink $filein if -e $filein;
my $line = "$pdb;$out";
print $line;






sub checkFieldsExtra {
  my $key = shift;
	my $val = shift;
	my $pfld = shift;
  $val =~ s/:/ /g;
	$val =~ s/;/ /g;
  $val =~ s/=/ /g;
  if ($val ne "") {
		if ($key eq "Type") {
			if ($val eq "LS") {
				$$pfld{KategorieNr}="Bli";
				$$pfld{Kategorie}="Bewegungsdaten - Lieferscheine";
		  } elsif ($val eq "RE") {
				$$pfld{KategorieNr}="BFa";
				$$pfld{Kategorie}="Bewegungsdaten - Fakturen";
			} elsif ($val eq "BE" || $val eq "BA") {
				$$pfld{KategorieNr}="BBe";
				$$pfld{Kategorie}="Bewegungsdaten - Bestellungen";
			} elsif ($val eq "AB" || $val eq "RB") {
				$$pfld{KategorieNr}="BAb";
				$$pfld{Kategorie}="Bewegungsdaten - Auftragsbestätigungen";
			}
			$$pfld{Eigentuemer}="archiv";
		} elsif ($key eq "Firma") {
		  $val = uc($val);
			$$pfld{Firma}=$val;
		} else {
		  $$pfld{$key}=$val; 
		}
	}
}
		
		


