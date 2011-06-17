#!/usr/bin/perl

use strict;
use DBI;

# get the pdf file as file name
my (@fin,$t,@pages,$page,$c,$cl,$p2t,$pdftk);
my $pathin = "/mnt/net/"; # Path where we find the cold files
my $backup = "/mnt/net/backup/"; # backup path (plase where we send 
                                 # the files after processing
my $ftxt = "/tmp/kistemp.txt";   # temp. text file (text extraction)
my $fout = "/tmp/kistemp-";      # temp. pdf files (image generation)
my $fext = ".pdf";               # pdf extenstion
my $tmpout = "/tmp/kistiff";     # temp. tif file
my $tmpext = ".tif";             # temp. file extension
my $pdftk1 = " output ";         # pdftk option
# ghostscript command
my $gs = "gs -dNOPAUSE -dNOPROMPT -dBATCH -q -sDEVICE=tiffg4 " .
          "-r300x300 -sOutputFile=$tmpout%d$tmpext ";
# database information
my $host="192.168.50.40";
my $db="archiv";
my $user="Admin";
my $pw="*****";
my $lockuser="coldkis";

if (-d "/mnt/net/backup") {
  print TimeStamp().": old job still running...\n";
	die;
}
print TimeStamp().": mounting device\n";
system("/home/data/archivista/kis/mount.sh");
# open the mysql connection
my $dbh=MySQLOpen($host,$db,$user,$pw);
if (-d $pathin && -d $backup && $dbh) {
  # pathes and mysql are ok, so read all files
  opendir(FIN,$pathin);
	@fin=readdir(FIN);
	closedir(FIN);
	foreach(@fin) {
	  # go through each file
    my $f=$_;
    my $f1="$pathin$f";
		if ($f ne "." && $f ne ".." && !-d $f) {
		  # no entries from directories
      my $ext=lc($f1);
			$ext=~/(\.pdf)$/;
			$ext=$1;
      if (-e $f1 && $ext eq '.pdf') {
			  # file must exist and have a pdf extension
        $p2t = "pdftotext -layout $f1 $ftxt";
        $pdftk = "pdftk $f1 cat ";
				# process a file
	      my ($m,$art,$nummer,$ext)=split(/\./,$f);
				getfile($f1,$m,$art,$f);
				# move the files to the backup folder
	  	  my $fb="$backup$f";
		    unlink $fb if (-e $fb);
		    eval(system("mv -f $f1 $fb")) if (-e $f1);
		    eval(system("rm -f $f1")) if (-e $f1);
			}
	  }
  }
} else {
  print "mount points $pathin or $backup are not available\n";
}
print TimeStamp().": unmount device\n";
system("umount /mnt/net");






sub getfile {
  my $fpdf = shift;
	my $m = shift;
	my $art = shift;
	my $fname = shift; # original file name
	my (@rnr,@d1,@anr,@knr,@d2,@files,@res,@ref,@wnr,@jnr,@code,@belnr);
	# get Mandant, Bereich/Unterbereich out of file name
  if (-e $fpdf) {
    # create a text file out of the pdf file
	  # first remove an old file
    unlink $ftxt if (-e $ftxt);
	  if (!-e $ftxt) {
	    # we don't have any more a txt file, create it again
      system($p2t);
	    if (-e $ftxt) {
		    # the text file is here, so we read it
			  open(FIN,$ftxt);
        my @a=<FIN>;
        close(FIN);
        $t=join("",@a);

        # split the pages into single pages
        @pages=split(/\014/s,$t);

        foreach (@pages) {
          # go through each page
          $page=$_;
			    # read the values from every page
					if ($art eq "RWEB2PP1" || $art eq "RWEB2PP") {
					  # Wareneingang is completely different
						# always in single files
            @res=getfieldswareneingang($page);
            push @knr,$res[0];
            push @d1,$res[1];
            push @wnr,$res[2];
            push @anr,$res[2];
	      	  push @rnr,$res[3];
            push @d2,$res[3];
						push @ref,$res[3];
						push @jnr,0;
						push @code,'';
						push @belnr,0;
					} elsif ($art eq "RFKJNPP") {
					  @res=getfieldsjournal($page);
            push @rnr,$res[0];
						push @d1,$res[1];
            push @anr,$res[0];
						push @knr,0;
	      	  push @rnr,0;
            push @d2,$res[2];
						push @ref,$res[2];
						push @jnr,$res[0];
						push @code,'';
						push @belnr,0;
					} elsif ($art eq "RLGK2PP2") {
						# Lagerbelege is completely different
						# always in single files
            @res=getfieldslagerbelege($page);
            push @knr,0;
            push @d1,$res[1];
            push @wnr,'';
            push @anr,$res[2];
	      	  push @rnr,$res[3];
            push @d2,$res[3];
						push @ref,$res[3];
						push @jnr,0;
						push @code,$res[0];
						push @belnr,$res[2];
			    } else {
  				  # the rest, normally more documents in one file
            @res=getfieldsnormal($page);
      	    push @rnr,$res[0];
            push @d1,$res[1];
            push @anr,$res[2];
            push @knr,$res[3];
            push @d2,$res[4];
						push @ref,$res[5];
						push @wnr,$res[6];
						push @jnr,0;
						push @code,'';
						push @belnr,0;
					}
				}
		  }
    }
  }
	print "file $fpdf is splitted\n";

  # after we processed every page, we store the pages to the database
  $c=0;
  $cl=0;
  foreach(@rnr) {
    # now we go through the values from generated from every page
	  # start only on the second page
	  if (($anr[$c] != $anr[$cl] && $anr[$c]>0) || $anr[$c]==0) {		  
      # we have a new document, so put it together
		  $files[$cl]="$fout$anr[$cl]$fext";
      print "$rnr[$cl]-$d1[$cl]-$anr[$cl]-" .
			      "$knr[$cl]-$d2[$cl]-$ref[$cl]-$wnr[$cl]-$jnr[$cl]-" .
						"$code[$cl]-$belnr[$cl]\n";
		  my $c1=$c;
		  my $cl1=$cl+1;
		  my $cmd = "$pdftk $cl1-$c1 $pdftk1 $files[$cl]";
			# get the pages from pdftk
		  system($cmd);
			# now create the pages
      $cmd="$gs $files[$cl]";
			system($cmd);
			# add the document to the database
			insertdocument($files[$cl],$c,$cl,$m,$art,$d1[$cl],
			               $anr[$cl],$knr[$cl],$d2[$cl],$rnr[$cl],
										 $ref[$cl],$wnr[$cl],$jnr[$cl],
										 \@pages,$tmpout,$tmpext,$fname,$code[$cl],$belnr[$cl]);
		  $cl=$c;
	  }
	  last if $anr[$c] == 0;
	  $c++;
  }
}






sub getfieldsnormal {
  my $t = shift;
  my ($t1,$rechnr,$datum,$auftrag,$kundennr,$datumauftrag,$ref);

  # first remove the adress (after it we need four empty lines
  $t=~/(.*?)(\n{3,6})(.*)/s;
  #print "$1--$2--$3--$4--$5--$6--$7--$8--$9\n";
  $t=$3;

	# get the RechnungsNr
	$t=~/(\s+)(No|No\.|Nr\.)(\s{1,1})([0-9]{6,7})(\s)/s;
	$rechnr=$4;
	
  # get the Datum
	$t=~/(\s+)(Date|Datum|Data)(\s+)(:)(\s+)([0-9]+\.[0-9]+\.[0-9]+)(\s+)/s;
	$datum=$6;
	
  # get the line that holds AuftragNr,KundenNr,DatumAuftrag
  $t=~/(\_+)(\n)(.*?)(\n)(.*?)(\n)(\s*?)(\_+)(\n)/s;
  $t=$5; # get this line to process it
  # we need the title, then the customer nr and at the end the order date
  $t=~/(\s+)([0-9]+)(\s+)([0-9]+)(\s+)([0-9]+\.[0-9]+\.[0-9]+)(\s+?)(.*)$/s;
	# we store the datumauftrag only if we got a number at starting point
	my $d=$6; # get the datumauftrag information
	$datumauftrag=$d;
	$d=int $d; # check if it starts with a number (what should be)
	$t1=$8; # later reference (if we got datumauftrag)
	if ($d==0) {
	  # store the auftrag,kundennr
	  print "no datumauftrag\n";
	  # we got no order date, so check for reduced information
    $t=~/(\s+)([0-9]+)(\s+)([0-9]+)(\s+?.*)/s;
		$datumauftrag="";
    $auftrag=$2;
    $kundennr=$4;
	} else {
    # store the auftrag,kundennr,reference
		print "get reference\n";
    $auftrag=$2;
    $kundennr=$4;
    $t1=~/(\s{2,40})(.*)$/s;
	  $ref=$2;
	}
	print "$rechnr--$datum--$auftrag--$kundennr--$datumauftrag--$ref\n";
  return ($rechnr,$datum,$auftrag,$kundennr,$datumauftrag,$ref);
}






sub getfieldswareneingang {
  my $t = shift;
	my ($wnr,$datum,$liefernr);
  $t=~/(Lieferantennummer:)(\s+)([0-9]+)(\s+)/s;
	$liefernr=$3;
	
  $t=~/(Wareneingangnummer)(\s+)([0-9]+)(\s+)/s;
	$wnr=$3;
	
	$t=~/(\s+)([0-9]{1,2})(\/)([0-9]{1,2})(\/)([0-9]{1,2})/s;
	#print "1: $1--2: $2--3: $3--4: $4--5: $5--6: $6--7: $7\n";
	$datum="$2\.$4\.$6";
	print "$liefernr--$datum--$wnr\n";
  return ($liefernr,$datum,$wnr);
}





sub getfieldslagerbelege {
  my $t = shift;
	my ($code,$datum,$belegnr);
  $t=~/(\s{2,99})(\()(.*?)(\s*?)(\))/s;
	$code=$3;
  $t=~/(Belegnummer)(\s+)([0-9]+)(\s+)/s;
	$belegnr=$3;
	$t=~/(\s+)([0-9]{1,2})(\.)([0-9]{1,2})(\.)([0-9]{1,2})/s;
	#print "1: $1--2: $2--3: $3--4: $4--5: $5--6: $6--7: $7\n";
	$datum="$2\.$4\.$6";
	print "$code--$datum--$belegnr\n";
  return ($code,$datum,$belegnr);
}






sub getfieldsjournal {
  my $t = shift;
	my ($journal,$datum);
  $t=~/(Nr\.)(\s+)([0-9]+)(\s+)/s;
	$journal=$3;
	$t=~/(\s+)([0-9]{1,2})(\/)([0-9]{1,2})(\/)([0-9]{1,2})/s;
	$datum="$2\.$4\.$6";
	print "$journal--$datum\n";
  return ($journal,$datum);
}








sub insertdocument {
  my $file = shift;
	my $c = shift;
	my $cl = shift;
	my $mand = shift;
	my $art = shift;
	my $datum = shift;
	my $anr = shift;
	my $knr = shift;
	my $datumbest = shift;
	my $rechnr = shift;
	my $ref = shift;
	my $wnr = shift;
	my $jnr = shift;
	my $ppages = shift;
	my $tmpout = shift;
	my $tmpext = shift;
	my $fname = shift;
	my $code = shift;
	my $belnr = shift;

	my ($mandtext,$bereich,$ubereich);

  if ($art eq "RFKJNPP") {
	  # Buchhaltungsjournal
		$bereich="Rechnungswesen";
		$ubereich="Fakturajournal";
	} elsif ($art eq "RBEB1PP1" || $art eq "RBEB1PP") {
    # Bestellung
  	$bereich="Lieferanten";
		$ubereich="Bestellungen";
	} elsif ($art eq "RREC1PP1" || $art eq "RREC1PP") {
	  # Rechnungen
	  $bereich="Kunden";
		$ubereich="Rechnungen";
	} elsif ($art eq "RWEB2PP" || $art eq "RWEB2PP1") {
    # Wareneingang
		$bereich="Lieferanten";
		$ubereich="Wareneingang";
	} elsif ($art eq "RLGK2PP2") {
    # Lagerbelege 
		$bereich="Logistik";
		$ubereich="Lagerbeleg";
	} elsif ($art eq "RAUB1PP" || $art eq "RAUB1PP1") {
    # Auftragsbestätigung
	  $bereich="Kunden";
		$ubereich="Auftragsbestätigung";
	} else { # RAUB2PP1/RAUB2PP = Offerte
    # Offerte
		$bereich="Kunden";
		$ubereich="Offerten";
	}

	my $s=1; # start page
	my $e=$c-$cl; # end page

	# calculate the field names for the address
	my ($feld1,$feld2,$eig1);
	if ($art eq "RLGK2PP2") {
	  $feld1="";
		$feld2="";
		$eig1="log";
	} elsif ($bereich eq "Kunden") {
	  $feld1="KundeName";
		$feld2="KundeNr";
		$eig1="kunde";
	} elsif ($bereich eq "Rechnungswesen") {
	  $eig1="buha";
	} else {
	  $feld1="LieferName";
		$feld2="LieferNr";
		$eig1="lief";
	}
	
	if ($feld1 ne "") {
	  if ($mand==100) {
	    $feld1="KIS".$feld1;
		  $feld2="KIS".$feld2;
	  } else {
      $feld1="HHw".$feld1;
		  $feld2="HHW".$feld2;
	  }
	}
	
	my $sql="insert into archiv set ArchivArt=1,BildInput=1,";
	if ($datum ne "") {
	  # we have a date
		$sql.="Datum=".datumadd($datum).",";
	}
  if ($datumbest ne "") {
   # we have a Bestelldatum
	 $sql.="DatumBestellung=".datumadd($datumbest).",";
	}
	# store mandant information
	if ($mand==100) {
    $mandtext="Kisling";
	#} elsif ($mand==200) {
  #  $mandtext="Metabo";
	} else {
		$mandtext="HHW";
	}
	if ($mandtext ne "") {
	  $mand = int $mand;
	  $sql.="MandantNr=$mand,MandantName=".$dbh->quote($mandtext).",";
		# add owner (depending on the lieferant/kunde)
		if ($mandtext eq "Kisling") {
		  $eig1 = "KIS".$eig1;
		} else {
    	$eig1 = $mandtext.$eig1;
		}
		$sql.="Eigentuemer=".$dbh->quote($eig1).",";
	}

  if ($jnr>0) {
	  # we got a Rechnungswesen (Journal) document
	  $anr=0;
		$rechnr=0;
    $sql.="JournalNr=$jnr,";
		my @date1 = split(/\./,$datum);
		my $jonly = $date1[2]+2000;
		$sql.="Geschaeftsjahr=$jonly,";
	}
	
  # check for Lagerbelege
  if ($code ne "") {
	  $anr=0;
	  my $sql2 = $dbh->quote($code);
	  my $sql1 = "select Definition from feldlisten where ".
		           "FeldDefinition='BewegungsartText' and ".
							 "FeldCode='BewegungsartCode' and ".
							 "Code=$sql2";
		my @row = $dbh->selectrow_array($sql1);
		if ($row[0] ne "") {
		  my $sql3 = $dbh->quote($row[0]);
			$sql.="BewegungsartText=$sql3,";
		}
		$sql.="BewegungsartCode=$sql2,";
	  $sql.="Belegnr=$belnr,";
	}

  # add custom fields if they are available
	if ($anr>0 && $wnr eq "") {
	  $sql.="AuftragNr=$anr,";
	}
	
  # check for WareneingangNr
	if ($wnr ne "") {
	  $wnr=$dbh->quote($wnr);
	  $sql.="WareneingangNr=$wnr,";
	}

	if ($knr>0) {
    # Document is ok, we need the address number
		# and the other fields -> the fields come from archmaster db
	  my $sql2="select $feld1,Zusatzbezeichnung,Postfach,Strasse,Land,PLZ,Ort " .
		         "from archmaster.archiv where $feld2=$knr";
	  my @a=$dbh->selectrow_array($sql2);
		if ($a[0] ne "") {
	    my $kname=$dbh->quote($a[0]);
	  	my $zus=$dbh->quote($a[1]);
		  my $pf=$dbh->quote($a[2]);
		  my $str=$dbh->quote($a[3]);
		  my $land=$dbh->quote($a[4]);
		  my $plz=$dbh->quote($a[5]);
		  my $ort=$dbh->quote($a[6]);
	    $sql.="$feld2=$knr,$feld1=$kname,Zusatzbezeichnung=$zus,Postfach=$pf,";
		  $sql.="Strasse=$str,Land=$land,PLZ=$plz,Ort=$ort,";
		}
	}

	if ($rechnr>0) {
	  $sql.="RechnungNr=$rechnr,";
	}

	if ($ref ne "") {
	  $sql.="Referenz=".$dbh->quote($ref).",";
	}
	
	if ($bereich ne "") {
	  $sql.="Bereich=".$dbh->quote($bereich).",";
	}

	if ($ubereich ne "") {
	  $sql.="Unterbereich=".$dbh->quote($ubereich).",";
	}
	
	# Add the file name
	if ($fname ne "") {
    my $fn=$dbh->quote($fname);
		$sql.="EDVName=$fn,";
	}
	
	$sql.="Gesperrt='$lockuser'";
	# send to new record to the database
	#print "$sql\n";
	#<>;
	$dbh->do($sql);
	
	# Document is ok, we need the number
	$sql="select Laufnummer from archiv " .
			 "where Laufnummer=LAST_INSERT_ID()";
	my @a=$dbh->selectrow_array($sql);
	my $lnr=$a[0];
	print "document $lnr added\n";
	$sql="update archiv set Akte=$lnr where Laufnummer=$lnr";
	$dbh->do($sql);
	
  for(my $c1=$s;$c1<=$e;$c1++) {
	  # here we add the pages
	  my $t=$$ppages[$cl-1+$c1];
		$t=~s/\n/\r\n/gs;
		$t=$dbh->quote($t);
		my $s=$lnr*1000+$c1;
		$sql="insert into archivseiten set " .
		     "Seite=$s,Text=$t,OCR=0,Indexiert=1,Erfasst=1";
		$dbh->do($sql);
		my $fn="$tmpout$c1$tmpext";
		if (-e $fn) {
      open(FIN,$fn);
			binmode(FIN);
			my @f=<FIN>;
			close(FIN);
			my $ft=join("",@f);
			$ft=$dbh->quote($ft);
			$sql="insert into archivbilder set " .
			     "Seite=$s,BildInput=$ft";
			$dbh->do($sql);
			unlink $fn if (-e $fn);
		}
	}
	if (-e $file) {
	  # add the pdf if we get it
    open(FIN,$file);
		binmode(FIN);
		my @f=<FIN>;
		close(FIN);
		my $ft=join("",@f);
		my $s=$lnr*1000+1;
		$ft=$dbh->quote($ft);
		$sql="update archivbilder set " .
			     "Quelle=$ft where Seite=$s";
		$dbh->do($sql);
		unlink $file if (-e $file);
	}

  my $datume=SQLStamp();
	# say to the document that we are ready
	$sql="update archiv set Gesperrt='',BildInputExt='TIF',Erfasst=1, " .
	     "ErfasstDatum='$datume', " .
	     "QuelleIntern=1,QuelleExt='PDF',Seiten=$e where Laufnummer=$lnr";
	$dbh->do($sql);
}






=head3 DocumentAddDatForm -> Format a date ('yyyy-mm-dd')

=cut

sub datumadd {
  my $d=shift;
	my ($t,$m,$y)=split(/\./,$d);
	$t=sprintf("%02d",$t);
	$m=sprintf("%02d",$m);
	if ($y<70) {
	  $y=$y+2000;
	} else {
    $y=$y+1900;
	}
	$y=sprintf("%04d",$y);
	$d= "'".$y."-".$m."-".$t." 00:00:00'";
	return $d;
}


			



=head3 MySQLOpen -> Open a MySQL handler and gives back a db handler

=cut

sub MySQLOpen {
    my $host = shift;
    my $db = shift;
    my $user = shift;
    my $pw = shift;
    my ($dbh,$ds);
    $ds = "DBI:mysql:host=$host;database=$db";
    $dbh=DBI->connect($ds,$user,$pw);
    return $dbh;
}






=head3 TimeStamp -> Actual date/time stamp (20040323130556)

=cut

sub TimeStamp
{
  my @t=localtime(time());
  my ($stamp,$y,$m,$d,$h,$mi,$s);
  $y=$t[5]+1900;
  $m=$t[4]+1;
  $m=sprintf("%02d",$m);
  $d=sprintf("%02d",$t[3]);
  $h=sprintf("%02d",$t[2]);
  $mi=sprintf("%02d",$t[1]);
  $s=sprintf("%02d",$t[0]);
  $stamp=$y.$m.$d.$h.$mi.$s;
  return $stamp;
}






=head3 SQLStamp -> Actual date as SQL string (2004-03-23 00:00:00)

=cut

sub SQLStamp
{
  my @t=localtime(time());
  my ($stamp,$y,$m,$d,$h,$mi,$s);
  $y=$t[5]+1900;
  $m=$t[4]+1;
  $m=sprintf("%02d",$m);
  $d=sprintf("%02d",$t[3]);
  $stamp=$y."-".$m."-".$d." 00:00:00";
  return $stamp;
}



