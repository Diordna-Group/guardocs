#!/usr/bin/perl

=head1 exportpdf.pl (c) 2009 by Archivista GmbH

Export pdf files from archivista database

=cut

use strict;
use lib qw (/home/cvs/archivista/jobs);
use AVJobs;
use lib qw (/home/cvs/archivista/webclient/perl); 
use obj::Note;

my $db1 = shift;
my $dir = shift;
my $range = shift;
my $out = "/mnt/usbdisk/pdf";
$out=$dir if $dir ne "";
my $user = "expopdf413";
my $extprg = "/home/data/archivista/cust/export/exportpdf.pl";
my $tmp = "/home/data/archivista/tmp/";

my $dbh=MySQLOpen();
if ($dbh) {
  if (-e $out && HostIsSlave($dbh)==0) {
    logit("connection and directory $out ok");
    eval(system("rm $out/*"));
    my $sql="update $db1.archiv set Gesperrt='$user' " .
           "where (Gesperrt='' or Gesperrt is null) ";
    $sql.=sqlrange($range) if $range ne "";
    my $doit=$dbh->do($sql);
    while ($doit > 0) {
      $sql = "select Laufnummer from $db1.archiv where " .
		         "Gesperrt='$user' limit 1";
      my @res = $dbh->selectrow_array($sql);
			if ($res[0]>0) {
		    MainPDF($dbh,$db1,$out,$res[0],$extprg,$tmp);
				$sql = "update $db1.archiv set Gesperrt='' where Laufnummer=$res[0]";
				$dbh->do($sql);
		  } else {
			  $doit = 0;
			}
			sleep 2;
		}
  } else {
    logit("No dir $out or in slave mode");
  }
  $dbh->disconnect();
} else {
  logit("No connection!");
}






=head1 MainPDF($dbh,$db1,$out,$doc,$extprg,$tmp)

Send source file to client

=cut

sub MainPDF {
  my ($dbh,$db1,$out,$doc,$extprg,$tmp) = @_;
  my $sql = "SELECT Seiten,ArchivArt,Ordner,Archiviert " .
            "FROM $db1.archiv WHERE Laufnummer=$doc";
  my ($pages,$art,$folder,$arch) = $dbh->selectrow_array($sql);
	if ($pages>0) {
    my $firstPage = ($doc*1000)+1;
    my $lastPage = ($doc*1000)+$pages;
	  my $whole = 0;
    my $prow = getBlobFile($dbh,"Quelle",$firstPage,$folder,$arch);
    if (length($$prow)>0) {
      my $prow2 = getBlobFile($dbh,"Quelle",$lastPage,$folder,$arch);
      if (length($$prow2)==0) {
        writeFile(getFileName($db1,$doc,"$out/$doc.pdf",$extprg),$prow,1);
			  $whole=1;
		  } 
 	  }
	  if ($whole==0) {
		  logit("now creating pdf file $doc");
			my $file = getFileName($db1,$doc,"$out/$doc.pdf",$extprg)."\n";
      MainPDFCreate($dbh,$db1,$out,$doc,$pages,$art,$folder,$arch,$file,$tmp);
	  }
	}
}
		
	




=head1 MainPDFCreate($dbh,$db1,$out,$lnr,$seiten,$art,$fo,$arch,file,$tmp)

Create the pdf file and save it

=cut

sub MainPDFCreate {
  my ($dbh,$db1,$out,$lnr,$seiten,$archivart,$folder,$arch,$file,$tmp) = @_;
  my @files = ();
  for(my $c=1;$c<=$seiten;$c++) {
	  my $found = 0; 
    my $nr1=($lnr*1000)+$c;
    my $bild = 'Quelle';
    my $prow = getBlobFile($dbh,$bild,$nr1,$folder,$arch);
		$found=1 if length($$prow)>0;
		my $file1 = "$tmp$nr1.pdf";
		if ($found==0) {
      $bild = 'BildInput';
      $prow = getBlobFile($dbh,$bild,$nr1,$folder,$arch);
      if (length($$prow)==0) {
        $bild = 'Bild';
        $prow = getBlobFile($dbh,$bild,$nr1,$folder,$arch);
			}
      my $imgo = ExactImage::newImage();
      ExactImage::decodeImage($imgo,$$prow);
      # load the common note params
      my $params = {
        doc=>$lnr,
        page=>$c,
        cWidth => ExactImage::imageWidth($imgo),
        cHeight => ExactImage::imageHeight($imgo)
      };
      # extract notes from db, but dont rotate them or update params
      # pass in image to increase speed. Should always be BildInput?
      my $dbnotes = MainNoteHash($dbh,$db1,$params,$imgo);
      # loop thru notes and add to image
      foreach my $note (values %{$dbnotes}){
        $note->getImage($imgo);
      }
			logit("save $file1");
      if ($archivart==3) {
        #ExactImage::encodeImageFile($imgo,$file1,5,"jpeg,recompress");
        ExactImage::encodeImageFile($imgo,$file1);
      } else {
        ExactImage::encodeImageFile($imgo,$file1);
      }
      ExactImage::deleteImage($imgo);
		} else {
		  writeFile($file1,$prow,1);
		}
    push @files,$file1;
	}
  my $dopdf="pdftk ".join(" ",@files)." output $file";
  system("$dopdf");
  foreach (@files) {
    unlink $_ if -e $_;
  }
}






=head $fname=getFileName($db1,$doc,$file,$extprg)

Check if there is an external program to compose the file name

=cut

sub getFileName {
  my ($db1,$doc,$file,$extprg) = @_;
	if (-e $extprg) {
	  my ($host,$db,$user,$pw) = getConnectionValues();
		$db1 = $db if $db1 eq "";
	  $file = `$extprg '$host' '$db1' ^$user' '$pw' $doc`;
	}
	return $file;
}






=head1 MainNoteHash

Returns a hash of all notes for a page, keyed on the note index
Also updates the params argument with image size info if any of the
notes contain it, or gets it from image if all of them need it.

=cut
sub MainNoteHash {
  my $dbh = shift;
	my $db1 = shift;
  my $params = shift; # contains: doc, page, cWidth, cHeight, and more
  my $imgo = shift; # only send BildInput!
  my $pn = ($params->{doc}*1000)+$params->{page};
  
  ##############################################################
  # pull existing notes from db and cache them in @dbnotes
  # also determine the maximum note index
  my @dbnotes = ();
  my $maxIdx = 0;

  my $sql = "select Notes from $db1.archivseiten where Seite=$pn";
	my @res = $dbh->selectrow_array($sql);
  foreach my $line (split(/\r\n/,$res[0])) {
    my $note = obj::Note->new();
    $note->fromString($line);

    # if the caller gave us incomplete data, use _ALL_ data from note
    if ( !$params->{'iWidth'} || !$params->{'iHeight'}
      || !$params->{'iXRes'} || !$params->{'iYRes'}
    ){
      $params->{'iWidth'} = $note->get('iWidth');
      $params->{'iHeight'} = $note->get('iHeight');
      $params->{'iXRes'} = $note->get('iXRes');
      $params->{'iYRes'} = $note->get('iYRes');
    }

    if($maxIdx < $note->get('index')){
      $maxIdx = $note->get('index');
    }

    push (@dbnotes, $note);
  }

  # if the caller AND all the notes gave us incomplete data,
  # get the correct data from image
  if ( (!$params->{'iWidth'} || !$params->{'iHeight'}
    || !$params->{'iXRes'} || !$params->{'iYRes'})
    && (scalar @dbnotes)
  ){
    my $deleteImgo = 0;
    ##############################################################
    # extract size and resolution
    $params->{'iWidth'} = ExactImage::imageWidth($imgo);
    $params->{'iHeight'} = ExactImage::imageHeight($imgo);
    $params->{'iXRes'} = ExactImage::imageXres($imgo);
    $params->{'iYRes'} = ExactImage::imageYres($imgo);
  
    # some images dont have resolution encoded. we make a guess
    if(!$params->{'iXRes'}){
      $params->{'iXRes'} = 300;
    }
    if(!$params->{'iYRes'}){
      $params->{'iYRes'} = 300;
    }
  }

  ##############################################################
  # add missing params and index to notes made by RichClient
  # rotate note params if page view is rotated (not for pdfs)
  # convert array @dbnotes to hash %dbnotes
  my %dbnotes;
  foreach my $note (@dbnotes){
    $note->set(%{$params});
    $note->updateBgParams();
    if($note->get('index') < 1){
      $maxIdx++;
      $note->set('index'=>$maxIdx);
    }
    $dbnotes{$note->get('index')} = $note;
  }
  return \%dbnotes;
}








