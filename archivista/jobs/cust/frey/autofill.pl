#!perl

# ----------------------------
# Auto Beschlagwortung (c) 2008 by Archivista GmbH, Urs Pfister 
# ----------------------------

use strict;
use DBI;

# ----------------------------
# Configuration
my $my_host = "localhost";
my $my_db = "archiv";
my $my_uid = "Admin";
my $my_pwd = "archivista";

my $user_fields	= "RechnungNr,AuftragNr,KundenNr,Laufnummer";

# ----------------------------

my (@query1);
my @user_fields = split /,/, $user_fields;

my $dbh = DBI->connect("DBI:mysql:host=$my_host;database=$my_db",$my_uid,$my_pwd);

my $query = "SELECT $user_fields ";
$query .= "FROM archiv ";
$query .= "WHERE (ISNULL(RechnungNr) ";  
$query .= "OR RechnungNr = '') ";
$query .= "AND Gesperrt='' ";
$query .= "ORDER BY RechnungNr";

my $sth = $dbh->prepare($query);
$sth->execute();

while (my @row = $sth->fetchrow_array()) {
	my $auftrag = $row[1];
	my $akte = $row[3];
  print "$akte with $auftrag found\n";
  if ($auftrag>0) {
		my $query1 = "SELECT $user_fields ";
    # wir benötigen die letzte Tiff-Akte (gerastert), da es mehrere Rechnungen
    # pro Auftrag geben kann und immer die zuletzt gerasterte Rechnung dem zuletzt
    # gescannten Beleg zugeordnet werden soll
		$query1 .= "FROM archiv ";
		$query1 .= "WHERE RechnungNr<>'' AND RechnungNr is not null AND ";
		$query1 .= "ArchivArt=1 AND AuftragNr='$auftrag' ";
		$query1 .= "ORDER BY Laufnummer DESC LIMIT 1";
    print "$query1\n";
		my $sth_a = $dbh->prepare($query1);
		$sth_a->execute();
		my $inc = 0;
		undef @query1;
		while (my @row_a = $sth_a->fetchrow_array()) {
      print "update $row_a[3] with $row_a[0], $row[1], $row[2]\n";
			my $query1 = "UPDATE archiv SET ";
			foreach my $user_field (@user_fields) {
				push @query1, "$user_field = ".$dbh->quote($row_a[$inc]) if ($row_a[$inc]>0);
				$inc++;			
			}
     	pop @query1;
			$query1 .= join ",", @query1;
			$query1 .= " WHERE Akte=$akte";
    	print "$query1\n";
      $dbh->do($query1);
		}	
	}
} 
$sth->finish();
$dbh->disconnect();

