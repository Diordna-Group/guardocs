#!/usr/bin/perl

=head1 ocrfromnotes.pl -> extract a given page according notes

(c) v1.0 - 5.9.2010 by Archivista GmbH, Urs Pfister

=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
use DBI;
use AVJobs;

my $host = shift;
my $db = shift;
my $user = shift;
my $pw = shift;
my $doc = shift;
my $page = shift;

my $archivfolders = "";
my $ocrok = '/home/archivista/.wine/drive_c/Programs/Av5e';
my $ocrpath = '/home/archivista/.wine/drive_c/Programs/Av51';
my $ocrfr = checkOCR($ocrok,$ocrpath);
my $base = "ocrfromnotes";
my $dbh;
logit("program started with: $db");
if ($dbh=MySQLOpen($host,$db,$user,$pw)) { # open database and check for slave
  my $slave = HostIsSlaveSimple($dbh);
	die if $slave>0;
  my $sql = "select Akte,Archiviert,Ordner,Seiten,ArchivArt ".
	          "from $db.archiv where ".
            "Laufnummer = $doc";
	my ($lnr,$archiviert,$folder,$seiten,$art) = $dbh->selectrow_array($sql);
	my $table = "archivbilder";
	my $tablego = getBlobTable($dbh,$folder,$archiviert,$table,$archivfolders);
	my $nr = ($doc*1000)+$page;
	$sql = "select Notes,OCR from archivseiten where Seite=$nr";
	my @row = $dbh->selectrow_array($sql);
	my $notes = $row[0];
	my $ocr = $row[1];
	$sql = "select BildInput from $tablego where Seite=$nr";
	@row = $dbh->selectrow_array($sql);
	if ($row[0] ne "") {
	  my @images = ();
	  my @texts = ();
    my ($dopdf,$doocr,$pdfwholedoc,$limit,$start,$end)=getOCRVals($dbh,$db);
		$ocrpath = $ocrok if $doocr > 1;
	  ExtractImages(\$row[0],$ocrpath,$base,$art,$notes,\@images,\@texts);
		logit("images extracted from $nr");
		OCRPage($dbh,$db,$ocrpath,$base,\@images,\@texts,$ocrfr,$doocr,$ocr);
		logit("recognition done for $nr");
		UpdateText($dbh,$db,$ocrpath,$base,\@images,\@texts,$nr,$doocr);
		logit("text updated for $nr");
	}
	$dbh->disconnect();
}
logit("program ended with: $db");






=head1 $ocrfr=checkOCR($ocrok,$ocrpath)

Check if commercial ocr exists, if yes make a copy (no conflict
with createpdf.pl). If no, just create an empty directory for os ocr

=cut

sub checkOCR {
  my ($ocrok,$ocrpath) = @_;
  my $ocrfr = 0;
  if (-e $ocrok) {
    $ocrfr=1;
    if (!-e $ocrpath) {
      my $cmd = "cp -rp $ocrok $ocrpath";
	    system($cmd);
	  }
  } else {
    system("mkdir $ocrpath");
  }
	return $ocrfr;
}






=head1 ExtractImages($pimg,$ocrpath,$base,$art,$notes,$pimages,$ptexts)

Extract the image parts for the text recognition

=cut

sub ExtractImages {
  my ($prow,$ocrpath,$base,$art,$notes,$pimages,$ptexts) = @_;
  my $ext = "png";
	$ext = "png" if $art == 2;
	$ext = "jpg" if $art == 3;
	my $img = $base.'.'.$ext;
	my $txt = $base.'.'.$ext;
	unlink "$ocrpath/$img" if -e "$ocrpath/$img";
	my $lang2 = length($$prow);
  writeFile("$ocrpath/$img",$prow);
  my @notes = split("\r\n",$notes);
	my $c = 0;
  foreach my $note (@notes) {
	  my @vals = split(';',$note);
		my $x1 = $vals[1];
		my $y1 = $vals[2];
		my $x2 = $vals[3]-$x1;
		my $y2 = $vals[4]-$y1;
		my $img2 = $base.$c.'.'.$ext;
		my $txt2 = $base.$c.'.txt';
		unlink "$ocrpath/$img2" if -e "$ocrpath/$img2";
		my $cmd = "econvert -i $ocrpath/$img ".
		          "--crop $x1,$y1,$x2,$y2 ".
							"-o $ocrpath/$img2";
		system($cmd);
    archivingDocSetOwner("$ocrpath/$img2");    
		push @$pimages, $img2;
		push @$ptexts, $txt2;
		$c++;
	}
	if ($notes eq "") {
		my $img2 = $base.$c.'.'.$ext;
		my $txt2 = $base.$c.'.txt';
		unlink "$ocrpath/$img2" if -e "$ocrpath/$img2";
		my $cmd = "econvert -i $ocrpath/$img ".
							"-o $ocrpath/$img2";
		system($cmd);
    archivingDocSetOwner("$ocrpath/$img2");   
		push @$pimages, $img2;
		push @$ptexts, $txt2;
	}
	unlink "$ocrpath/$img" if -e "$ocrpath/$img";
}






=head1 OCRPage($dbh,$db,$ocrpath,$base,$pimages,$ptexts,$ocrfr,$ocr)

Do the recognition part of the images and save parts in text files

=cut

sub OCRPage {
  my ($dbh,$db,$ocrpath,$base,$pimages,$ptexts,$ocrfr,$doocr,$ocr) = @_;
	my $lang = OCRDoOpenSourceLang($dbh,$db,$dbh,"",$ocr);
	$doocr=3 if $doocr==1 && $ocrfr==0;
	if ($doocr>1 ) {
	  my $fin1 = join(',',@$pimages);
	  my $fout1 = join(',',@$ptexts);
    OCRDoOpenSource($fin1,$fout1,$lang,$doocr,0);
  } else {
	  my $profile_cmd='. /etc/profile'; # import default settingdx = 0; $idx <
	  my $display_cmd = 'export DISPLAY=:0'; # export display to default
	  my $cd_cmd = "cd ".$ocrpath; # ocr folder
	  my $xrandr = getXRandr($profile_cmd,$display_cmd);
	  my $fins = join(',',@$pimages);
		my $fouts = join(',',@$ptexts);
	  my $ocr_cmd = "wine avformrc.exe -i $fins -o $fouts";
	  $ocr_cmd .= " -l $lang" if $lang ne "";
	  my $ocrdo = qq(/bin/su - archivista -c "$profile_cmd; $display_cmd;).
	              qq($xrandr $cd_cmd; $ocr_cmd");
    logit($ocrdo);
    system($ocrdo);
	}
}






=head1 UpdateText($dbh,$db,$ocrpath,$base,$pimages,$ptexts,$nr)

Update the rerecognised page with the extracted text

=cut

sub UpdateText {
	my ($dbh,$db,$ocrpath,$base,$pimages,$ptexts,$nr,$doocr) = @_;
	my $output = "";
	foreach my $file (@$ptexts) {
    my $output1 = "";
  	my $file2 = $ocrpath.'/'.$file;
	  readFile2($file2,\$output1);
	  my $lang1 = length($output1);
	  if ($lang1>2) {
	    my $last = substr($output1,-1,1);
	    my $prelast = substr($output1,-2,1);
	    if ($last eq "-" && $prelast ne " ") {
		    $output1 = substr($output1,0,$lang1-1);
			}
		}
		if ($doocr==3) {
		  # Cuneiform fix
			$output1 =~ s/\x84/"/g;
		}
		$output1 =~ s/\n\n/\n/g;
		unlink $file2 if -e $file2;
		$output .= $output1;
	}
	my $sql = "update archivseiten set Erfasst=1,Text=".$dbh->quote($output).
	          "where Seite=$nr";
	$dbh->do($sql);
	foreach my $file (@$pimages) {
		my $file2 = $ocrpath.'/'.$file;
		unlink $file2 if -e $file2;
	}
}






