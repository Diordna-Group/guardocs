#!perl 

use DBI;
use File::Copy;
use strict;

# MySQL specific configuration
my $host = "localhost";
my $db = "archiv";
my $uid = "root";
my $pwd = "*****";

my $path = "d:\\avimp";
my $back = "d:\\avimp\\backeti";
my $mask1 = "ETIKETTE\.TXT";
my $mask2 = "AUFTRAG\.TXT";
my $ds = "\\";

my %vals;

my $dbh = DBI->connect("DBI:mysql:host=$host;database=$db",$uid,$pwd);
my $first = 1;
if ($dbh) {
  my $pa = getFilesFromMask($path,$ds,$mask1,$mask2);
  foreach(@$pa) {
    my $file = $_;
    print "$file in progress...\n";
    my $phash = getFileHash($path,$ds,$file);
    my $art = $file;
    $art =~ s/(.*?)(ETIKETTE)(\.TXT)$/$2/g;
    my $res;
    if ($art eq "ETIKETTE") {
       $res = processLabel($dbh,$phash);
    } else {
       $res = processLabelAuftrag($dbh,$phash);
    }
    if ($res) {
      my $file1 = "$path$ds$file";
      my $file2 = "$back$ds$res-$file";
      unlink $file2 if (-e $file2);
      move $file1,$file2;
    }
    sleep 2;
  }
}

$dbh->disconnect();






=head3 $res=processLabel($dbh,$phash) 

  Sends a barcode out to the printer (Kreditoren)

=cut

sub processLabel {
  my $dbh = shift;
  my $phash = shift;
  my $code;
  my $printer = processLabelPrinter($dbh,$$phash{USER});
  if ($printer ne "") {
    my $konto = $$phash{KONTO};
    my $firma = $$phash{FIRMA};
    my $art = $$phash{BELEGART};
    $art .= "1" if length($art)==2;
    my $beleg = $$phash{BELEGNR};
    my $text1 = $$phash{KTOBEZEICH};

    my $text2 = $$phash{ZAHLREF};
    my $langt2 = length($text2); 
    $text2 = "..".substr($text2,-13) if $langt2>13;
    $text2 =  $text2 . " " . $$phash{DATUM};
    $text2 .= "   ".$konto if $konto ne "" && $art eq "Z00";
    my $dat1 = $$phash{DATUM};
    if ($dat1 ne "") {
      my $y = substr($dat1,6,4);
      my $m = substr($dat1,3,2);
      my $d = substr($dat1,0,2);
      $dat1 = "'".$y."-".$m."-".$d." 00:00:00'";
    }
    my $wae = $$phash{WAE};
    $wae = "CHF" if $wae eq "";
    my $betrag = $$phash{BETRAG}; 
    $betrag =~ s/(^0*)//;
    $betrag = getCurrencyDeluxe($betrag);
    my $text3 = "$wae $betrag";
    my $typ = 1; # Kreditoren
    $code = processLabelPrintAddDoc($dbh,$typ,$firma,$art,$beleg,$dat1,"",$konto,$text1);
    my $lang = 26-length($text3)-length($code);
    $lang=3 if $lang<3;
    $text3 .= " " x $lang . $code;
    processLabelPrint($printer,$code,$text1,$text2,$text3) if $code>0;
  }
  return $code;
}






=head3 $res=processLabelAuftrag($dbh,$phash) 

  Sends a barcode out to the printer (Bestellungen)

=cut

sub processLabelAuftrag {
  my $dbh = shift;
  my $phash = shift;
  my $code;
  my $printer = processLabelPrinter($dbh,$$phash{USER});
  if ($printer ne "") {
    my $firma = $$phash{MANDANT};
    my $auftrag = $$phash{AUFTRAG};
    $auftrag =~ s/^(0*)(.*)/$2/;
    my $knr = $$phash{KUNDENNR};
    $knr =~ s/^(0*)(.*)/$2/;
    my $kna = $$phash{KUNDENAME};
    my $dat = $$phash{BESTELLDT};
    my $y = substr($dat,0,3);
    # Year starts with 99, so add 1900 to get 20xx
    $y += 1900;
    my $m = substr($dat,3,2);
    my $d = substr($dat,5,2);
    $dat = "'".$y."-".$m."-".$d." 00:00:00'";
    my $ref = $$phash{BESTELLRF};
    my $user = $$phash{USER};
    my $t = 2; # Bestellungen
    $code = processLabelPrintAddDoc($dbh,$t,$firma,$knr,$auftrag,$dat,$ref);
    my $text1 = $auftrag;
    my $text2 = $knr . " " . $kna;
    my $text3 = $user;
    my $lang = 26-length($text3)-length($code);
    $lang=3 if $lang<3;
    $text3 .= " " x $lang . $code;
    processLabelPrint($printer,$code,$text1,$text2,$text3) if $code>0;
  } else {
    print "User $$phash{USER} does not exist. Please add it in Archivista\n";
  }
  return $code;
}






sub getCurrencyDeluxe {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1'/g;
    return scalar reverse $text;
}






sub processLabelPrintAddDoc {
  my $dbh = shift;
  my $typ = shift;
  my $firma = shift;
  my $feld1 = shift; # typ=1 -> Belegart, type=2 -> KundenNr
  my $feld2 = shift; # typ=1 -> Belegnr, typ=2-> Auftrag
  my $feld3 = shift; # typ=2 -> Datum
  my $feld4 = shift; # typ=2 -> Bestellreferenz
  my $konto = shift; # Lieferantennummer (HHWLieferNr, KISLiefer)
  my $bezeich = shift; # typ=4 -> Bezeichnung

  my $spez1="";
  my $spez2="";
  if ($typ==1) {
    my $bz = $feld1;
    if ($bz eq "Z00") {
        $spez1="Rechnungswesen";
        $spez2="Investitionen";
	$typ=4;
    } elsif ($konto eq "150000") {
      if ($bz eq "DZK" || $bz eq "BK0" || $bz eq "DZ0" || $bz eq "KZ0" || $bz eq "SB0") {
        $spez1="Rechnungswesen";
        $spez2="Kass H CHF";
        $typ=3;
      }
    } elsif ($konto eq "151120") {
      if ($bz eq "DZW" || $bz eq "BK0" || $bz eq "DZ0" || $bz eq "KZ0" || $bz eq "SB0") {
        $spez1="Rechnungswesen";
        $spez2="Kass W CHF";
        $typ=3;
      }
    } elsif ($konto eq "155000") {
       if ($bz eq "DZP" || $bz eq "BK0" || $bz eq "DZ0" || $bz eq "KZ0" || $bz eq "SB0") {
         $spez1="Rechnungswesen";
         $spez2="Post CHF";
         $typ=3;
      }
    } elsif ($konto eq "470015") {
      if ($bz eq "DZ1" || $bz eq "BK0" || $bz eq "DZ0" || $bz eq "KZ0" || $bz eq "SB0" || $bz eq "VES") {
        $spez1="Rechnungswesen";
        $spez2="Bank CHF";
        $typ=3;
      }
    } elsif ($konto eq "445000") {
      if ($bz eq "DZ4" || $bz eq "BK0" || $bz eq "DZ0" || $bz eq "KZ0" || $bz eq "SB0") {
        $spez1="Rechnungswesen";
        $spez2="W¸Fi CHF";
        $typ=3;
      }
    } elsif ($konto eq "445002") {
      if ($bz eq "DZ5" || $bz eq "BK0" || $bz eq "DZ0" || $bz eq "KZ0" || $bz eq "SB0") {
        $spez1="Rechnungswesen";
        $spez2="W¸Fi EUR";
        $typ=3;
      }
    } elsif ($konto eq "445005") {
      if ($bz eq "DZ6" || $bz eq "BK0" || $bz eq "DZ0" || $bz eq "KZ0" || $bz eq "SB0") {
        $spez1="Rechnungswesen";
        $spez2="W¸Fi USD";
        $typ=3;
      }
    }
  }

  my ($code,$kname,$datum);
  if ($feld3 ne "") {
    $datum = $feld3;
  } else {
    $datum="'".SQLStamp()."'";
  }
  my $sql = "insert into archiv set ArchivArt=1,BildInput=1," .
            "Datum=$datum,ErfasstDatum=$datum,";

  if ($typ == 1) {
    # Kreditoren
    $sql .= processLabelPrintAddDocAddress($dbh,$firma,0,$konto,$typ);
    $feld1 = $dbh->quote($feld1);
    $sql .= "Belegart=$feld1,Belegnr=$feld2,";
    $sql .= "Bereich='Lieferanten',Unterbereich='Rechnungen'";
  } elsif ($typ == 3) {
    $sql .= processLabelPrintAddDocAddress($dbh,$firma,0,$konto,$typ);
    $feld1 = $dbh->quote($feld1);
    $sql .= "Belegart=$feld1,Belegnr=$feld2,";
    $spez1=$dbh->quote($spez1);
    $spez2=$dbh->quote($spez2);
    $sql .= "Bereich=$spez1,Unterbereich=$spez2";
  } elsif ($typ == 4) {
    $sql .= processLabelPrintAddDocAddress($dbh,$firma,0,$konto,$typ);
    $feld1 = $dbh->quote($feld1);
    $sql .= "Belegart=$feld1,Belegnr=$feld2,";
    $spez1=$dbh->quote($spez1);
    $spez2=$dbh->quote($spez2);
    $sql .= "Bereich=$spez1,Unterbereich=$spez2,";
    $sql .= "Bezeichnung=".$dbh->quote($bezeich);
  } else {
    # Bestellungen (typ 2)
    $sql .= processLabelPrintAddDocAddress($dbh,$firma,$feld1,0,$typ);
    $feld4 = $dbh->quote($feld4);
    $sql .= "AuftragNr=$feld2,DatumBestellung=$feld3,Referenz=$feld4,";
    $sql .= "Bereich='Kunden',Unterbereich='Bestellungen'";
  }
  my $res=$dbh->do($sql);

  if ($res==1) {
    # Document is ok, we need the number
    $sql="select Laufnummer from archiv " .
	 "where Laufnummer=LAST_INSERT_ID()";
    my @a=$dbh->selectrow_array($sql);
    $code=$a[0];
    $sql = "update archiv set Akte=$code where Laufnummer=$code";
    $dbh->do($sql);
  }
  return $code;
}






sub processLabelPrintAddDocAddress {
  my $dbh = shift;
  my $mand = shift;
  my $knr = shift;
  my $lnr = shift;
  my $typ = shift;

  # store mandant information
  my ($mandtext,$sql);
  if ($mand==100) {
    $mandtext="KIS";
  } elsif ($mand==200) {
    $mandtext="Metabo";
  } else {
    $mandtext="HHW";
  }

  if ($mandtext ne "") {
    $mand = int $mand;
    my $mandtext1=$mandtext;
    $mandtext1="Kisling" if $mandtext eq "KIS";
    $sql.="MandantNr=$mand,MandantName=".$dbh->quote($mandtext1).",";
    # add owner
    my $eig1=$mandtext;
    if ($mandtext ne "Metabo") {
      $eig1=$mandtext."lief";
      $eig1=$mandtext."kunde" if ($knr>0);
      $eig1=$mandtext."RW" if ($typ==3 || $typ==4);
      $sql.="Eigentuemer=".$dbh->quote($eig1).",";
    }
  }

  if ($knr>0 || $lnr>0) {
    my ($feld1,$feld2);
    if ($knr>0) {
      $feld1="KundeName";
      $feld2="KundeNr";
    } else {
       if ($typ==4) {
         $feld1="";
         $feld2="Invest";
       } else {
         $feld1="LieferName";
         $feld2="LieferNr";
       }
    }

    if ($typ !=4) {	
      if ($mand==100) {
        # Kisling
        $feld1="KIS".$feld1;
        $feld2="KIS".$feld2;
      } elsif ($mand==300) {
        # HHW
        $feld1="HHw".$feld1;
        $feld2="HHW".$feld2;
      } else {
        # Metabo
        $feld2="Met".$feld2;
        $feld1="";
      }
    }
    
    if ($knr>0) {
      $sql .= "$feld2=$knr,"; 
    } elsif ($lnr>0) {
      if ($typ !=4) {
        $sql .= "$feld2=$lnr,"; 
      } else {
        $sql .= "$feld2=".$dbh->quote($lnr).","; 
      }
    }
    if ($feld1 ne "") {
      # Document is ok, we need the address number
      # and the other fields -> the fields come from archmaster db
      my $sql2="select $feld1,Zusatzbezeichnung,Postfach,Strasse,Land,PLZ,Ort " .
            "from archmaster.archiv where $feld2=";
      if ($knr>0) {
        $sql2 .= "$knr";
      } else {
        $sql2 .= "$lnr";
      }
      my @a=$dbh->selectrow_array($sql2);
      my $kname=$dbh->quote($a[0]);
      my $zus=$dbh->quote($a[1]);
      my $pf=$dbh->quote($a[2]);
      my $str=$dbh->quote($a[3]);
      my $land=$dbh->quote($a[4]);
      my $plz=$dbh->quote($a[5]);
      my $ort=$dbh->quote($a[6]);
      if ($kname ne "NULL") {
        $sql.="$feld1=$kname,Zusatzbezeichnung=$zus,Postfach=$pf,";
        $sql.="Strasse=$str,Land=$land,PLZ=$plz,Ort=$ort,";
      }
    }
  }
  return $sql;
}






sub processLabelPrinter {
  my $dbh = shift;
  my $user = shift;
  my $sql = "select Zusatz from user where user like '%$user' limit 1";
  my @row = $dbh->selectrow_array($sql);
  return $row[0];
}






sub processLabelPrint {
  my ($port,$code,$text1,$text2,$text3) = @_;
  $code=UmlauteWeg($code);
  $text1=UmlauteWeg($text1);
  $text2=UmlauteWeg($text2);
  $text3=UmlauteWeg($text3);
  $code = uc $code;

  print "Druck auf Port: $port, Code: $code\n";
  print "Text: $text1--$text2--$text3\n";
  open FOUT, ">>$port" or die "$port not available\n";
  print FOUT "\r\n";
  print FOUT "N\r\n";
  #print FOUT "B30,15,0,3,3,5,100,N,\"$code\"\r\n";
  $code = "0$code" if length($code)==7;
  print FOUT "B20,15,0,2,5,12,100,N,\"$code\"\r\n";
  print FOUT "A20,125,0,3,1,1,N,\"$text1\"\r\n";
  print FOUT "A20,150,0,3,1,1,N,\"$text2\"\r\n";
  print FOUT "A20,175,0,3,1,1,N,\"$text3\"\r\n";
  print FOUT "j200\r\n";
  print FOUT "P1\r\n";
  close FOUT;
}






sub UmlauteWeg {
   my $text = shift;
   $text =~ s/\x84/ae/g; #Ñ
   $text =~ s/\xe4/ae/g;
   $text =~ s/\x94/oe/g; #î
   $text =~ s/\xf6/oe/g;
   $text =~ s/\x81/ue/g; #Å
   $text =~ s/\xfc/ue/g;
   $text =~ s/\x8e/Ae/g; #é
   $text =~ s/\xc4/Ae/g;
   $text =~ s/\x99/Oe/g; #ô
   $text =~ s/\xd6/Oe/g;
   $text =~ s/\x9a/Ue/g; #ö
   $text =~ s/\xdc/Ue/g;
   return $text;
}







=head3 \%h=getFileHash($path,$ds,$file)

  Reads a hash from the label definition file (Kisling)

=cut

sub getFileHash {
  my $pfadin = shift;
  my $dirsep = shift;
  my $file = shift;
  my $f = "$pfadin$dirsep$file";
  my %hash;
  if (-e $f) {
    open(FIN,$f);
    my @l = <FIN>;
    close(FIN);
    foreach(@l) {
      my $l1 = $_;
      chomp $l1;
      $l1 =~ s/\r//g;
      $l1 =~ s/\n//g;
      $l1 =~ s/(\s*)$//g;
      my @l2 = split("=",$l1);
      my $key = shift @l2;
      $key =~ s/\s//g;
      my $val = join("=",@l2);
      $val =~ s/^(\s*)//g;
      $hash{$key}=$val;
    }
  }
  return \%hash;
}






=head3 \@a=getFilesFromMask($path,$ds,$mask)

  gives back some files from a mask

=cut

sub getFilesFromMask {
  my $pfadin = shift;
  my $dirsep = shift;
  my $mask1 = shift;
  my $mask2 = shift;
  my (@files,@tiffs,$file);

  opendir(FIN,$pfadin);
  @files=readdir(FIN);
  closedir(FIN);
  foreach (@files) {
    $file=$_;
    chomp $file;
    if ($file ne "." && $file ne "..") {
      if ($file=~/(.*)($mask1)$/) {
        push @tiffs,$file;
      } elsif ($file=~/(.*)($mask2)$/) {
        push @tiffs,$file;
      }
    }
  }
  return \@tiffs;
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


