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
my $mask1 = "UPDATE\.TXT";
my $ds = "\\";

my $res;

my $dbh = DBI->connect("DBI:mysql:host=$host;database=$db",$uid,$pwd);
my $first = 1;
if ($dbh) {
  my $pa = getFilesFromMask($path,$ds,$mask1);
  foreach(@$pa) {
    sleep 180;
    my $file = $_;
    print "$file in progress...\n";
    my $plines = getFileHash($path,$ds,$file);
    foreach (@$plines) {
      my ($mand,$gjahr,$bart,$bnr,$anr,$zahlref,
          $weingnr,$weingnr1,$weingnr2,$weingnr3,
          $bdatum,$buchper,$wae,$betrag) = 
          # alt unpack("A3A4A10A10A8A8A20A10A6A3A16",$_);
          unpack("A3A4A10A10A8A30A10A10A10A10A10A6A3A16",$_);
      $bnr =~ s/^(0+)([0-9]*$)/$2/;
      $bart = $dbh->quote($bart);
      $buchper = $dbh->quote($buchper);
      my ($d1, $m1, $y1) = split('\.',$bdatum);
      $bdatum = "'$y1-$m1-$d1 00:00:00'";
      $wae = $dbh->quote($wae);
      $weingnr =~ s/^(0+)([0-9]+)(\s*)$/$2/;
      $weingnr = $dbh->quote($weingnr);
      $weingnr1 =~ s/^(0+)([0-9]+)(\s*)$/$2/;
      $weingnr1 = $dbh->quote($weingnr1);
      $weingnr2 =~ s/^(0+)([0-9]+)(\s*)$/$2/;
      $weingnr2 = $dbh->quote($weingnr2);
      $weingnr3 =~ s/^(0+)([0-9]+)(\s*)$/$2/;
      $weingnr3 = $dbh->quote($weingnr3);
      $zahlref = $dbh->quote($zahlref);
      $betrag =~ s/^(0+)([0-9\.]*$)/$2/;

      my $feld;
      if ($mand == 100) {
        $feld = "KISLieferNr";
       } else {
        $feld = "HHWLieferNr";
       }

      my $sql="select Laufnummer from archiv " .
	 "where Belegart=$bart and Belegnr=$bnr AND $feld = $anr order by Laufnummer desc limit 1";
      my @a=$dbh->selectrow_array($sql);
      my $code=$a[0];
      if ($code>0) {
	print "found: $bart - $bnr -> $code\n";
        $sql = "update archiv set ";        
 	$sql .= processLabelPrintAddDocAddress($dbh,$mand,$anr);
        $sql .= "Geschaeftsjahr=$gjahr,Buchungsperiode=$buchper,";
        $sql .= "Betrag=$betrag,Waehrung=$wae,WareneingangNr=$weingnr,";
        $sql .= "WareneingangNr1=$weingnr1,";
        $sql .= "WareneingangNr2=$weingnr2,";
        $sql .= "WareneingangNr3=$weingnr3,";
        $sql .= "Datum=$bdatum,Zahlreferenz=$zahlref ";
        $sql .= "where Laufnummer=$code";
        #print "$sql\n";
        #<>;
        $dbh->do($sql);

        # search for Wareneingang and update all records
        my @wnr;
        $wnr[0]=$weingnr;
	$wnr[1]=$weingnr1;
	$wnr[2]=$weingnr2;
	$wnr[3]=$weingnr3;
        foreach (@wnr) {
          my $wnrakt = $_;
          if ($wnrakt ne "''") {
            my $sql="select Laufnummer from archiv " .
	            "where WareneingangNr=$wnrakt and MandantNr=$mand and $feld=$anr";
            my @a=$dbh->selectrow_array($sql);
	    my $code=$a[0];
            if ($code>0) {
              $sql = "update archiv set ";        
              $sql .= "Geschaeftsjahr=$gjahr,Buchungsperiode=$buchper,";
              $sql .= "Betrag=$betrag,Waehrung=$wae,Zahlreferenz=$zahlref, ";
              $sql .= "Belegart=$bart,Belegnr=$bnr ";
              $sql .= "where Laufnummer=$code";
              #print "$sql\n";
              $dbh->do($sql);
            }
          }
        }
      } else {
        print "not found: $bart - $bnr\n";
      }
    }
    my $file1 = "$path$ds$file";
    my $file2 = "$back$ds$file";
    unlink $file2 if (-e $file2);
    move $file1,$file2;
    sleep 2;
  }
}

$dbh->disconnect();










sub processLabelPrintAddDocAddress {
  my $dbh = shift;
  my $mand = shift;
  my $knr = shift;

  # store mandant information
  my ($mandtext,$sql);
  if ($mand==100) {
    $mandtext="Kisling";
  } elsif ($mand==200) {
    $mandtext="Metabo";
  } else {
    $mandtext="HHW";
  }

  if ($mandtext ne "") {
    $mand = int $mand;
  }

  if ($knr>0) {
    my ($feld1,$feld2);
    $feld1="LieferName";
    $feld2="LieferNr";
	
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

    $sql .= "$feld2=$knr,";
    if ($feld1 ne "") {
      # Document is ok, we need the address number
      # and the other fields -> the fields come from archmaster db
      my $sql2="select $feld1,Zusatzbezeichnung,Postfach,Strasse,Land,PLZ,Ort " .
               "from archmaster.archiv where $feld2=$knr";
      my @a=$dbh->selectrow_array($sql2);
      my $kname=$dbh->quote($a[0]);
      my $zus=$dbh->quote($a[1]);
      my $pf=$dbh->quote($a[2]);
      my $str=$dbh->quote($a[3]);
      my $land=$dbh->quote($a[4]);
      my $plz=$dbh->quote($a[5]);
      my $ort=$dbh->quote($a[6]);
      $sql.="$feld1=$kname,Zusatzbezeichnung=$zus,Postfach=$pf,";
      $sql.="Strasse=$str,Land=$land,PLZ=$plz,Ort=$ort,";
    }
  }
  return $sql;
}






=head3 \@l=getFileHash($path,$ds,$file)

  Reads a hash from the label definition file (Kisling)

=cut

sub getFileHash {
  my $pfadin = shift;
  my $dirsep = shift;
  my $file = shift;
  my $f = "$pfadin$dirsep$file";
  my @l;
  if (-e $f) {
    open(FIN,$f);
    @l = <FIN>;
    close(FIN);
  }
  return \@l;
}






=head3 \@a=getFilesFromMask($path,$ds,$mask)

  gives back some files from a mask

=cut

sub getFilesFromMask {
  my $pfadin = shift;
  my $dirsep = shift;
  my $mask1 = shift;
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


