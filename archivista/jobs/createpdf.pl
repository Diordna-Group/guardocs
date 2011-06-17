#!usr/bin/perl

################################################# What it is

=head1 createpdf.pl --- (c) by Archivista GmbH, 2.5.2007
       
Create pdf files and/or ocr recognition in archivista archives
and do a form recognition if it is enabled

=cut

use strict;
use lib qw(/home/cvs/archivista/jobs/);
use DBI;
use AVJobs;
use File::Copy;
use Math::Trig;
use Archivista::Config;

my %val;
$val{log} = '/home/data/archivista/av.log';
$val{sleepmax} = 30; # max. number of seconds we wait for document to be ready
$val{frrec} = '/home/data/archivista/cust/formrec/';
$val{frtemp} = $val{frrec}.'temptxt.txt';
$val{frpath} = '/home/archivista/.wine/drive_c/Programs/Av5e/';

# where we get the Archivista connection
my $config = Archivista::Config->new;
my $host = $config->get("MYSQL_HOST");
my $db = $config->get("MYSQL_DB");
my $user = $config->get("MYSQL_UID");
my $pw = $config->get("MYSQL_PWD");
undef $config;






=head2 Functionality

This script is responsible for barcode and ocr recognitions.

=cut

jobCheckInit("ocr init"); 
# open a database handler
my $pdfwholedoc1=1;
my $lastgs = "";
my $lasttime = 0;
my $limited = 0;
my $lastdoc = 0;
my $lastcount = 0;
for ( my $count = 0; $count <= 3600; $count++ ) { # restart somewhere later
	logit("start ocr") if $count==0;
	my $doocr1=1;
	my $found1=0;
	($lastgs,$lasttime)=checkGhostscript($lastgs,$lasttime);
  my $dbh=MySQLOpen();
  if ($dbh) {
    if (HostIsSlave($dbh)==0) { # we are not slave 
      my ($sql,$res,$seiten,$extinput,$extquelle);
      my $err = 0;
      $sql = "select ID,Laufnummer,host,db,user,pwd,DONE,formrec from logs " .
             "where (TYPE='sne' or TYPE='imp') AND " .
						 "(DONE=0 or DONE=3) and Laufnummer>0 " .
             "and ERROR=0 order by DONE desc limit 1";
      my @felder=$dbh->selectrow_array($sql);
      my $id=$felder[0];
      my $lnr=$felder[1];
      my $host1=$felder[2];
			my $db1=$felder[3];
			my $user1=$felder[4];
      my $pw1=$felder[5];
			my $done=$felder[6];
			my $formrec=$felder[7];
			if ($host1 eq "localhost") {
			  $user1=$user;
				$pw1=$pw;
			}
			if ($id>0) {
			  $doocr1=0; # say that we not yet got an ocr job
			  logit("new doc found under $id");
			  my $dbh2=MySQLOpen($host1,$db1,$user1,$pw1);
			  if ($dbh2) {
          if (HostIsSlaveSimple($dbh2)==0) {
				    $found1=1;
			      if ($done==0) {	
						  logit("doc with id $id not yet processed");
				      my ($dopdf,$doocr,$pdfwholedoc,
									$limit,$start,$end) = getOCRVals($dbh2,$db1);
						  if ($formrec>0) {
                # create pdf files without ocr
                $sql = "update logs set DONE=1 where ID=$id";
                $dbh->do($sql);
				        $found1=1;
                my $test = processLogoRec($dbh,$db1,$dbh2,$lnr,
								                          $id,$formrec,$host1,$doocr);
                processFormRec($dbh,$db1,$dbh2,$lnr,$id,$formrec,
							                 $host1,$user1,$pw1,$test);
							} else {
							  my $doit=1;
							  if ($limit==1) {
                  my @t = localtime( time() );
                  my $h = $t[2];
									if ($h>=$start && $h<$end && $start != $end) {
									  $doit=1;
									} else {
									  $doit=0;
									}
								}
								if ($doit==1) {
								  $limited=0;
						      processJob($dbh,$db1,$dbh2,$lnr,$dopdf,$doocr,
								             $pdfwholedoc,$id);

						      $doocr1=$doocr;
						      $pdfwholedoc1=$pdfwholedoc;
								} else {
								  if ($limited==0) {
								    logit("no ocr for some hours (see WebAdmin in $db1)!");
										$limited=1;
									}
								  sleep 60;
								}
							}
					  }
		        checkForTempFiles($dbh,$user,$pw,$pdfwholedoc1);
						checkForSplittedTables($dbh,$db1,$dbh2,$id,$host1,$user1);
				  }
			    $dbh2->disconnect();
			  }
			}
			if ($lastdoc == $lnr && $lnr>0) {
			  $lastcount++;
				sleep 30;
				sleep $lastcount;
				logit("$lnr was already used for last call, now wait a bit");
				if ($lastcount>50) {
          $lastcount=0;
					if ($id>0) {
            my $sql = "update logs set DONE=1 where ID=$id";
            $dbh->do($sql);
					}
				}
			}
			$lastdoc = $lnr;
    }
		sleep 5 if $doocr1>0 || $found1==0; # wait a moment (no docs/after ocr)
    $dbh->disconnect();
	}
	sleep 2;
}






=head1 checkForSplittedTables($dbh,$db1,$dbh2,$id1,$host1,$user1,$pw1)

Check if we got an ocr in extended tables

=cut

sub checkForSplittedTables {
  my ($dbh,$db1,$dbh2,$id1,$host1,$user1) = @_;
	my $sql = "";
	my $idlast = 0;
	while($id1>0) {
	  $sql = "select ID,DONE,host,db,user,Laufnummer from logs where ID>=$id1 ".
	         "and host=".$dbh->quote($host)." and db=".$dbh->quote($db1).
			  	 " order by ID limit 1";
	  my ($id,$done,$host,$db,$user,$lnr) = $dbh->selectrow_array($sql);
	  if ($host1 eq $host && $db1 eq $db && $done==4 && $idlast != $id) {
	    $sql = "select Akte,Archiviert,Ordner,Seiten from $db1.archiv ".
		         "where Laufnummer=$lnr";
	    my ($lnr2,$archiviert,$folder,$seiten) = $dbh2->selectrow_array($sql);
		  if ($lnr2==$lnr) {
		    my $tbarch = "archivbilder";
	      my $tbgo = getBlobTable($dbh2,$folder,$archiviert,$tbarch);
			  if ($tbgo ne $tbarch) {
		      logit("after ocr:$id--$done--$host--$db--$user--$lnr");
			    for (my $c=1;$c<=$seiten;$c++) {
				    my $seite = ($lnr*1000)+$c;
					  $sql = "select length(BildInput) from $db1.$tbgo ".
					         "where Seite=$seite";
					  my ($lang) = $dbh2->selectrow_array($sql);
					  if ($lang>0) {
					    $sql = "select length(Quelle) from $db1.archivbilder ".
							       "where Seite=$seite";
						  my ($lang1) = $dbh2->selectrow_array($sql);
							if ($lang1>0) {
							  $sql = "select Quelle from $db1.archivbilder ".
								       "where Seite=$seite";
						    my ($pdf) = $dbh2->seletrow_array($sql);
					      $sql = "update $db1.$tbgo set Quelle=".$dbh2->quote($pdf)." ".
						           "where Seite=$seite";
						    $dbh2->do($sql);
							} else {
					      $sql = "update $db1.$tbgo set Quelle=^' where Seite=$seite";
						    $dbh2->do($sql);
							}
						  $sql = "delete from $db1.archivbilder where Seite=$seite";
						  $dbh2->do($sql);
					  }
				  }
        }
				$idlast = $id;
			  $id1 = $id++;
		  } else {
			  $id1 = 0;
			}
		} else {
		  $id1 = 0;
		}
	}
}






=head1 processJob($dbh,$db1,$dbh2,$lnr,$dopdf,$doocr,$pdfwholedoc,$id)

Process the next job(s)

=cut

sub processJob {
  my $dbh = shift;
  my $db1 = shift;
	my $dbh2 = shift;
	my $lnr = shift;
	my $dopdf = shift;
	my $doocr = shift;
	my $pdfwholedoc = shift;
	my $id = shift;
	my $sleep=0;
  sleep 2 if ($dopdf==0 && $doocr==0); # no action, wait a bit
	while ($sleep<$val{sleepmax}) {
    if ($lnr>0) {
      my $sql="select Seiten,ArchivArt,BildInputExt from $db1.archiv " .
              "where Gesperrt='' and Laufnummer=$lnr";
      my @felder=$dbh2->selectrow_array($sql);
      my $seiten=$felder[0];
			my $archivart=$felder[1];
      my $extinput=$felder[2];
      if ($seiten>0 && ($archivart==1 || $archivart==3)) {
	      if ($extinput eq "") {
			    $extinput="TIF";
			    $extinput="JPG" if $archivart==3;
			    $dbh2->do("update $db1.archiv set BildInputExt='$extinput' ".
                    "where Laufnummer=$lnr");
        }
			  logit("start ocr job in $db1-$lnr-$seiten ($doocr/$dopdf)");
        if ($dopdf==1 && $doocr==0) {
          # create pdf files without ocr
          $sql = "update logs set DONE=1 where ID=$id";
          $dbh->do($sql);
          doJobPDFonly($dbh2,$lnr,$db1,$seiten,$extinput,$pdfwholedoc);
          $sql = "update logs set DONE=4 where ID=$id";
          $dbh->do($sql);
        } elsif ($doocr>0) {
          # say cronjob that we want for a document a ocr recognition
          doJobOCRandPDF($dbh,$db1,$dbh2,$lnr,$host,$db,$user,$pw,
					               $dopdf,$pdfwholedoc,$doocr);
					if ($doocr>1) {
            $sql = "update logs set DONE=4 where ID=$id";
            $dbh->do($sql);
					}
        } else {
          $sql = "update logs set DONE=4 where ID=$id";
					$dbh->do($sql);
				}
		    $sleep=$val{sleepmax};
      } else {
	      sleep 1;
	      $sleep++;
	      my $sql = "select Laufnummer from $db1.archiv where Laufnummer=$lnr";
        my @res = $dbh2->selectrow_array($sql);
	      if ($res[0]==0 || $sleep==$val{sleepmax}) {
	        my $sql = "update logs set DONE=4 where ID=$id";
	        $dbh->do($sql);
			    $sleep=$val{sleepmax};
				}
			}
		}
	}
}






=head1 checkForTempFiles($dbh,$user,$pw,$pdfwholedoc,$seiten)

Check if the generated pdf files are stored in temp files. If so, import them

=cut

sub checkForTempFiles {
  my $dbh = shift;
	my $user = shift;
	my $pw = shift;
	my $pdfwholedoc = shift;
  my $sql = "select ID,Laufnummer,host,db,user,pwd,pages from logs " .
         "where (TYPE='sne' or TYPE='imp') AND DONE=3 " .
	   		 "and Laufnummer>0 and ERROR=0 limit 1";
  my @felder=$dbh->selectrow_array($sql);
  my $id=$felder[0];
  my $lnr=$felder[1];
  my $host1=$felder[2];
	my $db1=$felder[3];
	my $user1=$felder[4];
  my $pw1=$felder[5];
	my $seiten=$felder[6];
	if ($host1 eq "localhost") {
	  $user1=$user;
		$pw1=$pw;
	}
	if ($id>0) {
 		my $dbh2=MySQLOpen($host1,$db1,$user1,$pw1);
 		if ($dbh2) {
      if (HostIsSlaveSimple($dbh2)==0) {
			  my $file=$val{frpath}.$id;
				if ($pdfwholedoc==1) {
				  $file .= '.pdf';
					checkForTempFiles1($dbh,$db1,$dbh2,$lnr,1,$file);
					for (my $c=2;$c<=$seiten;$c++) {
					  my $nr1 = ($lnr*1000)+$c;
            my $sql="update $db1.archivbilder set Quelle='' where Seite=$nr1";
						$dbh2->do($sql);
					}
				} else {
				  for (my $c=1;$c<=$seiten;$c++) {
					  my $file1 = $file.'_'.$c.'.pdf';
					  checkForTempFiles1($dbh,$db1,$dbh2,$lnr,$c,$file1);
					}
				}
			  $sql = "update logs set done=4 where ID=$id";
				$dbh->do($sql);
			}
		}
	  $dbh2->disconnect();
	}
}
	





=head1 checkForTempFiles($dbh,$db1,$dbh2,$file,$lnr,$seite)

check a single file and import it to the archivbilder table

=cut

sub checkForTempFiles1 {
	my $dbh = shift;
	my $db1 = shift;
  my $dbh2 = shift;
	my $lnr = shift;
	my $seite = shift;
	my $file = shift;
	
	if (-e $file) {
	  my $size = -s $file;
	  my $pf=getFile($file);
	  my $nr1 = ($lnr*1000)+$seite;
    my $sql="update $db1.archivbilder set Quelle=".$dbh->quote($$pf).
            "where Seite=$nr1";
    $dbh2->do($sql);
	  $$pf="";
	  unlink($file) if (-e $file);
		logit("$file deleted after loading into db $db1");
	}
}





=head3 getFile -> Read a file and give it back as text

=cut

sub getFile {
  my $datei = shift;
  my (@a,$inhalt);
  if (-f $datei) {
    open(FIN,$datei);
    binmode(FIN);
 		while (my $line = <FIN>) {
		  $inhalt .= $line;
		}
    close(FIN);
  }
  return \$inhalt;
}






=head1 doJobPDFOnly 

Just create pdf files, no ocr needed

=cut

sub doJobPDFonly {
  my $dbh = shift;
  my $lnr = shift;
  my $db1 = shift;
  my $seiten = shift;
  my $extinput = shift;
	my $pdfwholedoc = shift;
  my ($sql,$c,@felder);
  my ($ppdf,$pfile,$img);
  
  $sql="update $db1.archiv set Gesperrt='createpdf' where Laufnummer=$lnr";
  $dbh->do($sql);

  my @files = ();
  for(my $c=1;$c<=$seiten;$c++) {
    my $nr1=$lnr*1000+$c;
		for(my $c2=0;$c2<5;$c2++) {
      $sql="select BildInput from $db1.archivbilder where Seite=$nr1";
      @felder=$dbh->selectrow_array($sql);
      $img=$felder[0];
			if (length($img)>0) {
			  $c2=5;
			} else {
				sleep 1;
			}
		}
    my $c1=sprintf("%04d",$c);
    $ppdf="/tmp/seite$c1".".pdf";
		push @files,$ppdf;
    if ($extinput eq "JPG") {
      $pfile="/tmp/seite$c1".".jpg";
      open(FOUT,">$pfile");
      binmode(FOUT);
      print FOUT $img;
      close(FOUT);
      system("jpeg2ps $pfile | epstopdf --filter > $ppdf");
    } else {
      $pfile="/tmp/seite$c1".".tif";
      open(FOUT,">$pfile");
      binmode(FOUT);
      print FOUT $img;
      close(FOUT);
      system("tiff2pdf $pfile > $ppdf");
    }
		if ($pdfwholedoc==0) {
      my $nr1=($lnr*1000)+$c;
			my $pf = getFile($ppdf);
      $sql="update $db1.archivbilder set Quelle=".$dbh->quote($$pf).
           "where Seite=$nr1";
      $dbh->do($sql);
			$$pf="";
		}
		sleep 1;
  }
	if ($pdfwholedoc==1) {
    my $pdf1="/tmp/all.pdf";
    my $dopdf="pdftk ".join(" ",@files)." output $pdf1";
    system("$dopdf");
    my $nr1=($lnr*1000)+1;
		my $pf = getFile($pdf1);
    $sql="update $db1.archivbilder set Quelle=".$dbh->quote($$pf).
         "where Seite=$nr1";
    $dbh->do($sql);
		$$pf="";
	}
  $sql="update $db1.archiv set QuelleExt='PDF',QuelleIntern=1, ".
       "Gesperrt='' where Laufnummer=$lnr";
  $dbh->do($sql);
  eval(system("rm /tmp/all.pdf"));
  eval(system("rm /tmp/seite*.pdf"));
  eval(system("rm /tmp/seite*.jpg"));
  eval(system("rm /tmp/seite*.tif"));
}






=head1 doJobOCRandPDF

Does an ocr recognition (and also pdf creation)

=cut

sub doJobOCRandPDF {
  my $dbh = shift;
  my $db2 = shift;
  my $dbh2 = shift;
  my $lnr = shift;
  my $host1 = shift;
  my $db1 = shift;
  my $user1 = shift;
  my $pw1 = shift;
  my $dopdf = shift;
	my $pdfwhole = shift;
	my $doocr = shift;

  my ($ocrdo,$opt);

	if ($doocr==1) {
    $opt = "ocr";
    $opt ="both" if $dopdf==1;
																													
	  my $profile_cmd = '. /etc/profile'; # import default settings
	  my $display_cmd = 'export DISPLAY=:0'; # export display to default
		my $xrandr = getXRandr($profile_cmd,$display_cmd);
	  my $cd_cmd = "cd ".$val{frpath}; # ocr folder
	  my $ocr_cmd = "wine avocr.exe -h $host1 -d $db1 -u $user1 -p $pw1";
	  $ocr_cmd .= " -l -b 20 -o $opt -a -t ";
	  $ocr_cmd .= " -i" if $pdfwhole==0;
	  $ocrdo = qq(/bin/su - archivista -c "$profile_cmd; $display_cmd;).
	           qq($xrandr $cd_cmd; $ocr_cmd");
		my $ocrlog = $ocrdo;
		$ocrlog =~ s/(-p)(\s)(.*?)(\s)(-l)/$1$2****$4$5/; 
    logit($ocrlog);
    system($ocrdo);
	} elsif ($doocr>1) {
	  logit("start open source ocr for document $lnr in db $db2");
    if (DocumentLock($dbh2,$db2,$lnr,'osocr')) {
		  my $sql = "select Laufnummer,ArchivArt,Seiten from $db2.archiv ".
			          "where Laufnummer=$lnr";
		  my @row = $dbh2->selectrow_array($sql);
			if ($row[0] == $lnr) {
			  my $art = $row[1];
				my $seiten = $row[2];
			  my $lang="";
				my @pdfs=();
				foreach (my $c=1;$c<=$seiten;$c++) {
				  my $file = "osocr$host$db2$lnr$c";
					my ($fin,$fout,$fin1,$fout1);
					if ($art == 1) {
					  $fin1 = $file.'.tif';
					} else {
					  $fin1 = $file.'.jpg';
					}
					$fin = $val{frpath}.$fin1;
					$fout1 = $file.'.txt';
					$pdfs[$c]="$val{frpath}$fout1";
					$fout = $val{frpath}.$fout1;
					my $seite = ($lnr*1000)+$c;
					if ($c==1) {
            $sql = "select OCR from $db2.archivseiten where Seite=$seite";
					  @row = $dbh2->selectrow_array($sql);
					  $lang = $row[0];
						$lang = OCRDoOpenSourceLang($dbh,$db2,$dbh2,"",$lang);
					}
					$sql = "select Seite,BildInput from $db2.archivbilder ".
					       "where Seite=$seite";
					@row = $dbh2->selectrow_array($sql);
					if ($row[0]==$seite && length($row[1])>0) {
					  open(FOUT,">$fin");
						binmode(FOUT);
						print FOUT $row[1];
						close(FOUT);
						if (-e $fin) {
	            logit("page $c in doc $lnr ready to recognise...");
              OCRDoOpenSource($fin1,$fout1,$lang,$doocr,$dopdf);
							if (-e $fout) {
								if ($doocr==3 && $dopdf==1) {
								  # catch the pdf file from cuneiform
									if ($pdfwhole==0) { 
									  my $pdf = "";
								    readFile($fout,\$pdf);
									  my $sql = "update $db2.archivbilder set Quelle=".
								            $dbh2->quote($pdf)." where Seite=$seite";
								    $dbh2->do($sql);
									}
									my $fout2 = $fout.'.txt';
									#unlink $fout2 if -e $fout2;
									#system("pdftotext $fout");
									$fout = $fout2;
								}
							  my $text="";
								readFile($fout,\$text);
								my $sql = "update $db2.archivseiten set Erfasst=1,Text=".
								          $dbh2->quote($text)." where Seite=$seite";
								$dbh2->do($sql);
								unlink $fout if -e $fout;
							}
							unlink($fin) if -e $fin;
						}
					}
				}
      	foreach (my $c=1;$c<=$seiten;$c++) {
				  if ($pdfwhole==1 && $c==1) {
						my $fout = "/tmp/cuneipdf.pdf";
						unlink $fout if -e $fout;
			      my $cmd = "pdftk ".join(" ",@pdfs)." output /tmp/cuneipdf.pdf";
						system($cmd);
						if (-e $fout) {
					    my $seite = ($lnr*1000)+1;
				      my $pdf = "";
			        readFile($fout,\$pdf);
			        my $sql = "update $db2.archivbilder set Quelle=".
					            $dbh2->quote($pdf)." where Seite=$seite";
							$dbh2->do($sql);
						  unlink $fout if -e $fout;
						}
					}
					my $file = $val{frpath}.$pdfs[$c];
					unlink $pdfs[$c] if -e $pdfs[$c];
				}
			}
	    logit("end open source ocr for document $lnr in db $db2");
      DocumentUnlock($dbh2,$db2,$lnr);
		} else {
		  logit("doc is locked");
		}
	}
} 






=head1 processLogoRec($dbh,$db1,$dbh2,$lnr,$id,$lr,$host,$doocr)

Start the logo recognition for an given document from logs table with id

=cut

sub processLogoRec {
  my $dbh = shift;
	my $db1 = shift;
	my $dbh2 = shift;
	my $lnr = shift;
	my $id = shift;
	my $lr = shift;
	my $host = shift;
	my $doocr = shift;
	return if $lr==0;
	my ($image,$match,$fins,$fouts,$logo,$logoContours,$logoRep,$test,$test1);
	my ($fins1,$fouts1,$first);
	logit("block recognition: start for doc $lnr"); 
  if (DocumentLock($dbh2,$db1,$lnr,'blockrec')) {
    my ($logofile,$x,$y,$match,$form,$ocr) = LogoRecLoad($dbh2,$db1,$lr);
		my $sql = "select Seiten,Archiviert,Gesperrt,Eigentuemer,ArchivArt " .
		       "from $db1.archiv where Laufnummer=$lnr";
	  my ($pages,$archived,$locked,$owner,$art) = $dbh2->selectrow_array($sql);
		if ($pages>0 and $archived==0 and $locked eq "blockrec") {
		  logit("start block recognition for document: $lnr in db: $db1");
			my $logook=LogoRecCheck($logo,$logofile,\$logoContours,\$logoRep);
			for (my $page=1;$page<=$pages;$page++) {
			  logit("start block recognition for page $page");
				my $seite = ($lnr*1000)+$page;
				$sql = "select BildInput from $db1.archivbilder where Seite=$seite";
				my @row = $dbh2->selectrow_array($sql);
				if ($row[0] ne "") {
          $image = ExactImage::newImage();
          if (ExactImage::decodeImage($image,$row[0])) {
            my $xres = ExactImage::imageXres($image);
            my $yres = ExactImage::imageXres($image);
            my ($found,$fin,$fout,$test)=LogoRecDo($dbh2,$db1,$lnr,$page,$art,
						     $id,\$logoRep,$x,$y,$image,$match,$form,$xres,$yres,$logook);
						if ($found>=$match) {
						  $test1 = 1 if $test == 1;
							$fins .= "," if $fins ne "";
							$fins .= $fin;
							$fouts .= "," if $fouts ne "";
							$fouts .= $fout;
							if (($page % 50)==0) {
                LogoRecGo($dbh,$dbh2,$db1,$fins,$fouts,$ocr,$doocr);
								$fins1.="," if $fins1 ne "";
								$fins1.=$fins;
								$fouts1.="," if $fouts1 ne "";
								$fouts1.=$fouts;
								$fins="";
								$fouts="";
							}
						}
            ExactImage::deleteImage($image); 
					}
				}
			}
			if ($logook==1) {
        ExactImage::deleteRepresentation($logoRep);
        ExactImage::deleteContours($logoContours);
			}
			$fins1.=$fins;
			$fouts1.=$fouts;
      LogoRecGo($dbh,$dbh2,$db1,$fins,$fouts,$ocr,$doocr);
			LogoRecDB($dbh2,$db1,$fins1,$fouts1,$lnr);
      ExactImage::deleteImage($logo);
		}
	}
	DocumentUnlock($dbh2,$db1,$lnr);
	logit("logo recognition: end for doc $lnr"); 
	return $test1;
}






=head1 $logook=LogoRecCheck($logo,$logofile,$logoContours,$logoRep)

Check if the logo is available

=cut

sub LogoRecCheck {
  my $logo = shift;
	my $logofile = shift;
	my $plogoContours = shift;
	my $plogoRep = shift;
  my $logook=0;
  $logo = ExactImage::newImage();
  if ($logofile ne "") {
    $logofile = $val{frrec}.$logofile;
    if (-e $logofile) {
      $logook=ExactImage::decodeImageFile($logo,$logofile);
			$logook=1 if $logook!=0; # fix to a unique return value
		  if ($logook==1) {
		    my $x1 = ExactImage::imageXres($logo);
	      logit("logo $logofile loaded, res: $x1");
   	    $$plogoContours = ExactImage::newContours($logo); # recognise pattern
        # $logoRep is needed to recognize logo, use it several times
        # Attention: Don't kill $logoRep as long as you use $logoContours
        $$plogoRep = ExactImage::newRepresentation($$plogoContours);
		  }
		}
	}
	return $logook;
}






=head1 LogoRecDB($dbh2,$db1,$fin,$fout,$lnr)

Read the recognized text parts from files and store them in database

=cut

sub LogoRecDB {
  my $dbh2 = shift;
	my $db1 = shift;
	my $fin = shift;
	my $fout = shift;
	my $lnr = shift;
	my @fins = split(",",$fin);
	my @fouts = split(",",$fout);
	my $c=0;
	foreach (@fouts) {
	  my $file = $_;
	  my $base = $file;
		$base =~ s/^(.*?)(\.txt)$/$1/;
	  my ($id,$page,$nr) = split('_',$base);
		for (my $c1=0;$c1<5;$c1++) {
		  my $file1 = $val{frpath}.$file;
		  if (-e $file1) {
			  logit("read file $file to store text in $lnr-$page");
			  my $text = "";
        readFile($file1,\$text);
				my $seite = ($lnr*1000)+$page;
				my $sql = "select Seite,Text from $db1.archivseiten ".
				          "where Seite=$seite";
				my @row = $dbh2->selectrow_array($sql); 
				if ($row[0]==$seite) {
				 	if ($nr==1) {
				    $text = "FormRec:$text\r\n";
					} else {
				    $text = $row[1]."FormRec:$text\r\n";
					}
				  $text = $dbh2->quote($text);
				  $sql = "update $db1.archivseiten set Text=$text where Seite=$seite";
				} else {
				  $text = "FormRec:$text\r\n";
				  $text = $dbh2->quote($text);
				  $sql = "insert into $db1.archivseiten " .
					       "(Seite,Text) values ($seite,$text)";
				}
				$dbh2->do($sql);
				unlink($file1) if -e $file1;
				$file1 = $val{frpath}.$fins[$c];
				unlink($file1) if -e $file1;
				$c1=5;
			} else {
			  sleep $c1;
			}
		}
		$c++;
  }		
}






=head1 LogoRecGo($dbh,$dbh2,$db1,$fins,$fouts,$ocr,$doocr)

Call form recognition programm to rettrieve extracted blocks

=cut

sub LogoRecGo {
  my $dbh = shift;
  my $dbh2 = shift;
	my $db1 = shift;
  my $fins = shift;
	my $fouts = shift;   
	my $ocr = shift;
	my $doocr = shift;
  my $langs = OCRDoOpenSourceLang($dbh,$db1,$dbh2,$ocr);
	if ($doocr>1) {
	  OCRDoOpenSource($fins,$fouts,$langs,$doocr);
	} else {
	  my $profile_cmd = '. /etc/profile'; # import default settingdx = 0; $idx <
	  my $display_cmd = 'export DISPLAY=:0'; # export display to default
	  my $cd_cmd = "cd ".$val{frpath}; # ocr folder
		my $xrandr = getXRandr($profile_cmd,$display_cmd);
	  my $ocr_cmd = "wine avformrc.exe -i $fins -o $fouts";
	  $ocr_cmd .= " -l $langs" if $langs ne "";
	  my $ocrdo = qq(/bin/su - archivista -c "$profile_cmd; $display_cmd;).
	              qq($xrandr $cd_cmd; $ocr_cmd");
    logit($ocrdo);
    system($ocrdo);
	}
	logit("form recognition ended");
}






=head LogoRecLoad($dbh2,$db,$logorec,$ptyp,$pfr,$pto,$pfld,$pst,$pend,$pscr)

Load the desired form recognition and store all values from it to arrays

=cut

sub LogoRecLoad {
  my $dbh2 = shift;
	my $db = shift;
	my $logorec = shift;
	my ($image,$x,$y,$match);
  my $fcname = "FormRecognition".sprintf("%02d",$logorec);
	my $sql = "select Name,Inhalt from $db.parameter where Art='$fcname' and ".
	          "Tabelle='archiv'";
	my @rows = $dbh2->selectrow_array($sql);
	my $form = $rows[1];
	my ($name,$ocr,$logo);
	if ($rows[0] ne "") {
	  ($name,$ocr,$logo) = split(";",$rows[0]);
		$sql = "select Inhalt from $db.parameter where Art='LogoRecognition01' ".
		       " and Tabelle='archiv'";
	  @rows = $dbh2->selectrow_array($sql);
	  if ($rows[0] ne "") {
	    my @flds = split(/\r\n/,$rows[0]);
	    my $c=0;
	    foreach (@flds) {
		    my @line = split(/;/,$_);
			  if ($line[0] eq $logo) {
			    $image = $line[1];
					$x = parseToMM($line[2]);
					$y = parseToMM($line[3]);
				  $match = $line[10];
			    last;
			  }
			}
		}
	}
	return ($image,$x,$y,$match,$form,$ocr);
}






=head1 $found=LogoRecDo($dbh2,$db1,$lnr,$page,$art,$id,$lRep,$x,$y,$img,$m,$f)

Check if a logo is in a page; if so give it back with found,fileins,fileouts

=cut

sub LogoRecDo {
  my $dbh2 = shift;
	my $db1 = shift;
	my $lnr = shift;
	my $page = shift;
	my $art = shift;
	my $id = shift;
	my $plogoRep = shift;
	my $x = shift;
	my $y = shift;
	my $image = shift;
	my $match = shift;
	my $form = shift;
	my $xres = shift;
	my $yres = shift;
	my $logook = shift;

  my ($fins,$fouts,$imgCont,$found,$test);
	$match = 0.5 if $match eq "";
  if ($logook==1) {
	  logit("logo recognition started");
    # Extract bit pattern, this step needs a lot of time because an
	  # optimize2bw call is needed (probable 1-3 secs)
    $imgCont = ExactImage::newContours($image);
	  # search for the log, matchingScore is between 0-1, where
	  # 0=no identification and 1=full identification, normal results
	  # are between 0.65 and 0.95, under 0.5 the logo anyway can't matched
    $found = ExactImage::matchingScore($$plogoRep,$imgCont);
	  logit("logo result: ".sprintf("%.2f",$found).">$match");
	}
	if (($logook==1 && $found>=$match) || $logook==0) {
	  my @forms = split(/\r\n/,$form);
		my $c=1;
		foreach (@forms) {
		  my $form = $_;
	    my @single = split(";",$form);
		  my $x1 = parseToMM($single[1]);
		  my $y1 = parseToMM($single[2]);
		  my $w = parseToMM($single[3]);
		  my $h = parseToMM($single[4]);
			my ($fin,$fout) = LogoRecGetBlock($id,$page,$c,$plogoRep,$image,
			                          $x,$y,$x1,$y1,$w,$h,$art,$xres,$yres,$logook);
			$fins .= "," if $fins ne "";
			$fins .= $fin;
			$fouts .= "," if $fouts ne "";
			$fouts .= $fout;
			if ($test==0 && $logook==1 && $single[12]==1) {
			  LogoRecDoTest($dbh2,$db1,$lnr,$page,$plogoRep,$image,
				              $x,$y,$x1,$y1,$w,$h,$art,$xres,$yres);
				$test=1;
			}
			$c++;
		}
	}
  ExactImage::deleteContours($imgCont) if $logook==1;
	return ($found,$fins,$fouts,$test);
}






=head2 LogoRecDoTest($dbh2,$db1,$lnr,$page,$lRep,$img,$x,$y,$x1,$y1,$w,$h,$a)

Check if we need to paint the founded form block (testing mode)

=cut

sub LogoRecDoTest {
  my $dbh2 = shift;
	my $db1 = shift;
	my $lnr = shift;
	my $page = shift;
	my $plogoRepresentation = shift;
	my $image = shift;
	my $logo_top_left_x = shift;
	my $logo_top_left_y = shift;
	my $field_x = shift;
	my $field_y = shift;
	my $field_w = shift;
	my $field_h = shift;
	my $art = shift;
	my $xres = shift;
	my $yres = shift;

	my $image_backup_copy = ExactImage::copyImage($image);

  #my $dpi_x = ExactImage::imageXres ($image_backup_copy);
  #my $dpi_y = ExactImage::imageXres ($image_backup_copy);
  my $dpi_x = $xres;
  my $dpi_y = $yres;
  my $dpm_x = $dpi_x / 25.4;
  my $dpm_y = $dpi_y / 25.4;

  my $logo_to_field_x = int( ($field_x - $logo_top_left_x) * $dpm_x);
  my $logo_to_field_y = int( ($field_y - $logo_top_left_y) * $dpm_y);

  my $logo_angle = ExactImage::logoAngle($$plogoRepresentation);
  my $logo_x = ExactImage::logoTranslationX($$plogoRepresentation);
  my $logo_y = ExactImage::logoTranslationY($$plogoRepresentation);
  draw_mark ($image_backup_copy, $logo_x, $logo_y); # Mark logo position
  # Paint contour
  ExactImage::drawMatchedContours($$plogoRepresentation,$image_backup_copy);
  
  my ($p1_x, $p1_y) = rotate_coord ($logo_x, $logo_y, -$logo_angle,
	                      			      $logo_x, $logo_y+$logo_to_field_y);
  
	ExactImage::setLineWidth(3);
  ExactImage::imageDrawLine ($image_backup_copy,$logo_x, $logo_y,
				                       int($p1_x), int($p1_y));

  my ($p2_x, $p2_y) = rotate_coord ($logo_x, $logo_y, -$logo_angle,
				                            $logo_x+$logo_to_field_x, 
																		$logo_y+$logo_to_field_y);
    
  ExactImage::imageDrawLine ($image_backup_copy,int($p1_x), int($p1_y),
				                       int($p2_x), int($p2_y));

  my ($p3_x, $p3_y) = rotate_coord ($p2_x, $p2_y, -$logo_angle,
				                            $p2_x+ $field_w * $dpm_x, $p2_y);

  my ($p4_x, $p4_y) = rotate_coord ($p2_x, $p2_y, -$logo_angle,
				                            $p2_x, $p2_y + $field_h * $dpm_y);
    
  my ($p5_x, $p5_y) = rotate_coord ($p2_x, $p2_y, -$logo_angle,
				                            $p2_x + $field_w * $dpm_x, 
																		$p2_y + $field_h * $dpm_y);
    
  ExactImage::imageDrawLine ($image_backup_copy,int($p2_x), int($p2_y),
				                       int($p3_x), int($p3_y));
															 
  ExactImage::imageDrawLine ($image_backup_copy,int($p2_x), int($p2_y),
				                       int($p4_x), int($p4_y));
															 
  ExactImage::imageDrawLine ($image_backup_copy,int($p5_x), int($p5_y),
				                       int($p4_x), int($p4_y));
															 
  ExactImage::imageDrawLine ($image_backup_copy,int($p5_x), int($p5_y),
				                       int($p3_x), int($p3_y));

	my $file = "/tmp/logotest-$lnr-$page";
	my $file1 = $file;
	my $file2 = $file.'.pdf';
	ExactImage::imageSetXres($image_backup_copy,$xres); # fix wrong resolution
	ExactImage::imageSetYres($image_backup_copy,$yres); # fix wrong resolution
  if ($art==1) {
		$file1 .= '.tif';
    ExactImage::encodeImageFile ($image_backup_copy, $file1);
    system("tiff2pdf $file1 > $file2");
	} else {
		$file1 .= '.jpg';
    ExactImage::encodeImageFile ($image_backup_copy, $file1);
    system("jpeg2ps $file1 | epstopdf --filter > $file2");
	}

	if (-e $file2) {
	  my $img;
    readFile($file2,\$img);
		my $seite = ($lnr*1000)+$page;
		$img = $dbh2->quote($img);
		my $sql = "update $db1.archivbilder set Quelle=$img where Seite=$seite";
		$dbh2->do($sql);
	}
	unlink($file1) if -e $file1;
	unlink($file2) if -e $file2;
	ExactImage::deleteImage($image_backup_copy);
}






=head1 LogoRecGetBlock($id,$page,$c,$lRep,$img2,$imgC,$x,$y,$x1,$y1,$w,$h,$art)

Save block to an image file according the definitions and give back file names 

=cut

sub LogoRecGetBlock {
  my $id = shift;
	my $page = shift;
	my $c = shift;
  my $plogoRepresentation =shift;
  my $image_backup_copy = shift;
	my $logo_top_left_x = shift;
	my $logo_top_left_y = shift;
	my $field_x = shift;
	my $field_y = shift;
	my $field_w = shift;
	my $field_h = shift;
	my $art = shift;
	my $xres = shift;
	my $yres = shift;
	my $logook = shift;
	my ($p_field_x,$p_field_y,$logo_angle);
	 
  #my $dpi_x = ExactImage::imageXres ($image_backup_copy); ExactImage bug?
  #my $dpi_y = ExactImage::imageXres ($image_backup_copy); ExactImage bug?
  my $dpi_x = $xres;
  my $dpi_y = $yres;
  my $dpm_x = $dpi_x / 25.4;
  my $dpm_y = $dpi_y / 25.4;
	
  if ($logook==1) {	
    $logo_angle = ExactImage::logoAngle($$plogoRepresentation);
    my $logo_x = ExactImage::logoTranslationX($$plogoRepresentation);
    my $logo_y = ExactImage::logoTranslationY($$plogoRepresentation);
    my $logo_to_field_x = int( ($field_x - $logo_top_left_x) * $dpm_x);
    my $logo_to_field_y = int( ($field_y - $logo_top_left_y) * $dpm_y);
    logit("block: logo rotation: $logo_angle, position: $logo_x, $logo_y");
    # copy, crop, rotate the wanted Field
    ($p_field_x, $p_field_y) = rotate_coord ($logo_x, $logo_y, -$logo_angle,
		                   	$logo_x+$logo_to_field_x, $logo_y+$logo_to_field_y);
	} else {
	  $logo_angle = 0;
	  $p_field_x = int($field_x * $dpm_x);
		$p_field_y = int($field_y * $dpm_y);
	}
	$p_field_x=0 if $p_field_x<0;
	$p_field_y=0 if $p_field_y<0;
	
  my $field_image = ExactImage::copyImageCropRotate ($image_backup_copy,
      					    int($p_field_x), int($p_field_y),int($field_w * $dpm_x), 
										int($field_h * $dpm_y),-$logo_angle);
  my $file = $id.'_'.$page.'_'.$c;
	my $fout = $file.'.txt';
	if ($art==1) {
	  $file .= '.tif';
	} else {
	  $file .= '.png';
	}
	logit("block object $file saving");
	my $file1 = $val{frpath}.$file;
	ExactImage::imageConvertColorspace($field_image,'bilevel') if $art==1;
	ExactImage::imageSetXres($field_image,$xres); # fix wrong resolution
	ExactImage::imageSetYres($field_image,$yres); # fix wrong resolution
  ExactImage::encodeImageFile($field_image,$file1);
  ExactImage::deleteImage($field_image);
	return ($file,$fout);
}






=head1 processFormRec($dbh,$db1,$dbh2,$lnr,$id,$fr,$host1,$user1,$pw1)

Start the form recognition for an given document from logs table with id

=cut

sub processFormRec {
  my $dbh = shift;
	my $db1 = shift;
	my $dbh2 = shift;
	my $lnr = shift;
	my $id = shift;
	my $fr = shift;
	my $host1 = shift;
	my $user1 = shift;
	my $pw1 = shift;
	my $test = shift;
	return if $fr==0;
	logit("forn recognition: start for doc $lnr"); 
	my (@typ,@from,@to,@fld,@start,@end,@script,@last,$newdoc,$newpage);
	my (@docs,$ldoc);
	push @docs,$lnr;
	$ldoc=$lnr;
	my $sql = "update $db1.archiv set Gesperrt='formrec' where " .
	          "Laufnummer=$lnr and (Gesperrt='' or Gesperrt is null)";
	my $done = $dbh2->do($sql);
	if ($done) {
    FormRecLoad($dbh2,$db1,$fr,\@typ,\@from,\@to,\@fld,\@start,\@end,\@script);
		$sql = "select Seiten,Archiviert,Gesperrt,Eigentuemer " .
		       "from $db1.archiv where Laufnummer=$lnr";
	  my ($pages,$archived,$locked,$owner) = $dbh2->selectrow_array($sql);
		if ($pages>0 and $archived==0 and $locked eq "formrec") {
		  logit("start form recognition for document: $lnr in db: $db1");
			for (my $page=1;$page<=$pages;$page++) {
			  logit("start form recognition for page $page");
			  FormRecPage($dbh,$db1,$dbh2,$lnr,$page,$pages,$owner,$id,
				            \$newdoc,\$newpage,\@typ,\@fld,\@script,\@last,
										\@from,\@to,\@start,\@end,$user1);
				if ($ldoc != $newdoc && $newdoc>0) {
			    push @docs,$newdoc;
					$ldoc = $newdoc;
				}
			}
			if ($newdoc==0) {
			  $newdoc=$lnr;
				$newpage=$pages;
			}
			FormRecUnlock($db1,$dbh2,$newdoc,$newpage,$user1);
		}
	}
	my $found=FormRecAddNewLogs($dbh,$db1,$dbh2,$host1,$user1,$pw1,
	                            \@docs,$fr,$test);
	FormRecLogAdjust($dbh,$id,$found,$fr,$test);
	logit("forn recognition: end for doc $lnr"); 
}






=head1 FormRecAddNewLogs($dbh,$db1,$dbh2,$host1,$user1,$pw1,$pdocs

Add new log entries, so we can process the ocr again

=cut

sub FormRecAddNewLogs {
  my $dbh = shift;
	my $db1 = shift;
	my $dbh2 = shift;
	my $host1 = shift;
	my $user1 = shift;
	my $pw1 = shift;
	my $pdocs = shift;
	my $fr = shift;
	my $test = shift;
	my $found = 0;
	my $done = "0";
	$done = "4" if $test==1;
	$fr = $fr-(2*$fr); # say to log table, that we processed form rec

	foreach (@$pdocs) {
	  my $lnr = $_;
		my $sql = "select Seiten,Gesperrt,ArchivArt,Eigentuemer " .
		          "from $db1.archiv where Laufnummer=$lnr";
		my @row = $dbh2->selectrow_array($sql);
		if ($row[0]>0 && $row[1] eq '') {
		  my $seiten = $row[0];
			my $art = $row[2];
			my $bits = 1;
			$bits=24 if $art==3;
			my $own = $dbh->quote($row[3]);
			my $host1a = $dbh->quote($host1);
		  my $db1a = $dbh->quote($db1);
			my $user1a = $dbh->quote($user1);
			my $pw1a = $dbh->quote($pw1);
		  $sql = "insert into logs set " .
			       "host=$host1a,db=$db1a,user=$user1a,pwd=$pw1a,".
			       "pages=$seiten,owner=$own,Laufnummer=$lnr,".
						 "type='sne',bits=$bits,format=$art,DONE=$done,".
						 "formrec=$fr";
			$dbh->do($sql);
	    $found = 1;
		}
	}
	return $found;
}






=head1 FormRecPage($dbh,$db1,$dbh2,$lnr,$page,$pages,$pnewdoc,$pnewpage,@fc)

Does the form recognition for each page given the current values from form rec

@fc is ptyp,pfld,pscript,plast,pfrom,pto,pstart,pend (arrays with values)

=cut

sub FormRecPage {
  my $dbh = shift;
	my $db1 = shift;
	my $dbh2 = shift;
	my $lnr = shift;
	my $page = shift;
	my $pages = shift;
	my $own = shift;
	my $id = shift;
	my $pnewdoc = shift;
	my $pnewpage = shift;
	my $ptyp = shift;
	my $pfld = shift;
	my $pscript = shift;
	my $plast = shift;
	my $pfrom = shift;
	my $pto = shift;
	my $pstart = shift;
	my $pend = shift;
	my $user1 = shift;
	my (@res,@txt);

  my $pagenr = ($lnr*1000)+$page;
	my $sql = "select Text from $db1.archivseiten where Seite=$pagenr";
	my @row = $dbh2->selectrow_array($sql);
	if ($row[0] ne "") {
	  @txt = split(/FormRec:/,$row[0]);
		shift @txt; # remnove the first (zero entry)
		my $split=FormRecScript($db1,$lnr,$page,$pscript,\@txt,\@res,
		                        $ptyp,$pfrom,$pto,$pstart,$pend);
		logit("after form check in $lnr, split it: $split");
  	if ($split==1) {
		  my $split2=0;
		  if ($$plast[0] ne "") {
			  logit("we already have last values");
			  my $c2=0;
			  foreach (@res) {
				  if ($res[$c2] ne $$plast[$c2]) {
					  $split2=1;
						last;
					}
					$c2++;
				}
				if ($split2==1) {
				  logit("we need to split the doc $lnr at page $page");
					FormRecDocAdd($dbh,$db1,$dbh2,$lnr,$page,$pages,$own,
					              $pnewdoc,$pnewpage,$user1);
					$c2=0;
					foreach (@res) {
					  $$plast[$c2] = $res[$c2];
						$c2++;
					}
				  FormRecUpdate($db1,$dbh2,$$pnewdoc,$pfld,$plast,$lnr,$user1);
				} else {
				  $split=0;
				}
			} else {
			  logit("hold current settings for next page");
			  my $c2=0;
			  foreach (@res) {
				  $$plast[$c2] = $res[$c2];
					$c2++;
				}
				FormRecUpdate($db1,$dbh2,$lnr,$pfld,$plast,$user1) if $page==1;
			}
		}
	  $$pnewpage++;
		if ($split==0 && $$pnewdoc>0) {
		  FormRecPageMove($db1,$dbh2,$lnr,$page,$$pnewdoc,$$pnewpage);
		}
	} else {
	  $$pnewpage++;
	  # there was no page text, so save page
	  my $pnr = ($lnr*1000)+$page;
		$sql = "select Seite from $db1.archivseiten where Seite=$pnr";
		my @row1 = $dbh2->selectrow_array($sql);
		if ($row1[0]>0) {
      $sql = "update $db1.archivseiten set Text='' where Seite=$pnr";
		} else {
	    $sql = "insert $db1.archivseiten set Seite=$pnr,Text=''";
		}
	  $dbh2->do($sql);
		if ($$pnewdoc>0) {
		  FormRecPageMove($db1,$dbh2,$lnr,$page,$$pnewdoc,$$pnewpage);
		}
	}
}






=head FormRecPageMove($db1,$dbh2,$lnr,$page,$newdoc,$newpage)

Move an old page from lnr to the desired new document and page

=cut

sub FormRecPageMove {
  my $db1 = shift;
	my $dbh2 = shift;
	my $lnr = shift;
	my $page = shift;
	my $newdoc = shift;
	my $newpage = shift;
	my $pnr = ($lnr*1000)+$page;
	my $pnew = ($newdoc*1000)+$newpage;
	if ($pnr != $pnew) {
	  logit("move page in $db1 from $pnr to $pnew");
	  my $sql = "update $db1.archivbilder set Seite=$pnew where Seite=$pnr";
	  $dbh2->do($sql);
	  $sql = "update $db1.archivseiten set Seite=$pnew where Seite=$pnr";
	  $dbh2->do($sql);
	}
}






=head1 FormRecDocAdd($dbh,$db1,$dbh2,$lnr,$page,$pages,$own,$pnewdoc,$pnewpage)

Add a new doc, so we can add pages and values from form recognition

=cut

sub FormRecDocAdd {
  my $dbh = shift;
	my $db1 = shift;
	my $dbh2 = shift;
	my $lnr = shift;
	my $page = shift;
	my $pages = shift;
	my $own = shift;
	my $pnewdoc = shift;
	my $pnewpage = shift;
	my $user1 = shift;
	my $sql = "";
	if ($$pnewdoc==0) {
	  $$pnewdoc = $lnr;
		$$pnewpage = $page-1;
	  logit("form recognition: first doc in $db1 ends at page $$pnewpage");
	}
	FormRecUnlock($db1,$dbh2,$$pnewdoc,$$pnewpage,$user1);
	if ($page<=$pages) {
	  logit("form recognition: now add new document");
	  $$pnewdoc=0;
		$$pnewpage=1;
		my $lock = "formrec";
    recordAddOrUpdate($dbh2,$db1,$pnewdoc,$pnewpage,\$lock,$user1);
		if ($own ne "") {
		  my $own1 = $dbh2->quote($own);
		  $sql = "update $db1.archiv set Eigentuemer=$own1 " .
			       "where Laufnummer=$$pnewdoc";
			$dbh2->do($sql);
		}
		logit("form recognition: new document added under $$pnewdoc");
		FormRecPageMove($db1,$dbh2,$lnr,$page,$$pnewdoc,1);
	}
}






=head1 $slit=FormRecScript($db1,$lnr,$page,$pscript,$ptxt,$pres,@fc)

Check the values and gives a 1 if we need to split the document at this page

@fc is ptyp,pfrom,pto,pstart,pend (arrays with values)

=cut

sub FormRecScript {
	my $db1 = shift;
	my $lnr = shift;
	my $page = shift;
  my $pscript = shift;
	my $ptxt = shift;
	my $pres = shift;
	my $ptyp = shift;
	my $pfrom = shift;
	my $pto = shift;
	my $pstart = shift;
	my $pend = shift;
	my $split = 1;
	my $c1=0;
	foreach (@$pscript) {
	  my $scname = $_;
    my $script = "$val{frrec}".$scname;
	 	if ($scname ne "" && -e $script) {
	    unlink $val{frtemp} if -e $val{frtemp};
		  open(FOUT,">$val{frtemp}");
		  binmode(FOUT);
			print FOUT $$ptxt[$c1];
			close(FOUT);
			$script = "$script $val{frtemp}";
			my $result = `$script`;
			$$pres[$c1] = $result;
			unlink $val{frtemp} if -e $val{frtemp};
		} else {
		  $$pres[$c1] = FormRecPrepare($$ptxt[$c1]);
		}
		if ($$ptyp[$c1]>0) {
		  #$$pres[$c1] =~ s/\s//g; # remove all spaces if number/date
			if ($$ptyp[$c1]==1) {
			  $$pres[$c1]=FormRecCheckNumber($$pres[$c1],$$pfrom[$c1],$$pto[$c1]);
			} elsif ($$ptyp[$c1]==2 || $$ptyp[$c1]==3) {
			  $$pres[$c1]=FormRecCheckDate($$pres[$c1],$$ptyp[$c1]);
			}
		}
		logit("FormRec in $db1 at $lnr on $page: $$pres[$c1]");
		$$pres[$c1]="" if length($$pres[$c1])<$$pfrom[$c1] && $$pfrom[$c1]>0;
		$$pres[$c1]="" if length($$pres[$c1])>$$pto[$c1] && $$pto[$c1]>0;
		if ($$pres[$c1] ne "" && $$pstart[$c1]>0) {
      my $start = $$pstart[$c1]-1;
			my $end = $$pend[$c1];
			$end = $start if $end<$start;
			my $lang = $end-$start;
			$$pres[$c1] = substr($$pres[$c1],$start,$lang) if $lang>0;
		}
		$split=0 if $$pres[$c1] eq "";
		$c1++;
	}
  return $split;	
}





=head $val=FormRecPrepare($val)

Preformat the text for the form recognition (remove all tabs/r/n)

=cut

sub FormRecPrepare {
  my $val = shift;
  $val =~ s/\t/ /g;
	$val =~	s/\n/ /g;
	$val =~ s/\r/ /g;
	$val =~ s/\s\s/ /g;
	$val =~ s/^\s//;
	$val =~	s/\s$//;
	return $val;
}







=head1 $val=FormRecCheckNumber($val,$from,$to)

Check if the number fits to the requirements (length from-to)

=cut

sub FormRecCheckNumber {
  my $val = shift;
	my $from = shift;
	my $to = shift;
	$to = $from if $from>0 and $to<$from;
	if ($from>0) {
		$val =~ /([0-9]{$from,$to})/;
		$val = $1;
	} else {
		$val =~ /([0-9]+)/;
		$val = $1;
	}
	return $val;
}






=head1 $val=FormRecCheckDate($val,$type)

Check for a date (german/english format)

=cut

sub FormRecCheckDate {
  my $val = shift;
  my $type = shift;
  my ($da,$mo,$ja);
	if ($type==2) {
		$val =~ s/\.\s/./g;
		$val =~ s/\s\././g;
    $val =~ /([0-9]{1,2})\.([0-9]{1,2})\.([0-9]{1,4})/;
		$da = $1;
		$mo = $2;
		$ja = $3;
	} elsif ($type==3) {
		$val =~ s/\/\s/\//g;
		$val =~ s/\s\//\//g;
    $val =~ /([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{1,4})/;
		$mo = $1;
		$da = $2;
		$ja = $3;
	}
	if ($da>0 && $mo>0 && $ja>0) {
	  if ($ja<35) {
		  $ja = 2000+$ja;
		} elsif ($ja>70 && $ja<=100) {
		  $ja = 1900+$ja;
		}
		$ja = sprintf("%04d",$ja);
		$mo = sprintf("%02d",$mo);
		$da = sprintf("%02d",$da);
		$val = "$ja-$mo-$da";
	} else {
	  $val = "";
	}
	return $val;
}






=head1 FormRecLogAdjust($dbh,$id)

Delete the old log entry (no longer needed)

=cut

sub FormRecLogAdjust {
  my $dbh = shift;
	my $id = shift;
	my $found = shift;
	my $fr = shift;
	my $test = shift;
	my $sql;
	my $done=",DONE=0";
	$done=",DONE=4" if $test==1;
	if ($found==1) {
	  $sql = "delete from logs where id=$id";
	} else {
	  $fr = $fr - (2*$fr);
		$fr.=$done;
    $sql = "update logs set formrec=$fr where id=$id";
	}
	$dbh->do($sql);  
}






=head1 FormRecUnlock($db1,$dbh2,$lnr,$pages)

Unlock a document and save the current pages to the document

=cut

sub FormRecUnlock {
  my $db1 = shift;
	my $dbh2 = shift;
	my $lnr = shift;
	my $pages = shift;
	my $user1 = shift;
	my $sql = "update $db1.archiv set Seiten=$pages,Gesperrt=''";
	$sql.= ",UserNeuName=".$dbh2->quote($user1) if $user1 ne "";
	$sql.= " where Laufnummer=$lnr";
	$dbh2->do($sql);
}






=head FormRecLoad($dbh2,$db,$formrec,$ptyp,$pfr,$pto,$pfld,$pst,$pend,$pscr)

Load the desired form recognition and store all values from it to arrays

=cut

sub FormRecLoad {
  my $dbh2 = shift;
	my $db = shift;
	my $formrec = shift;
	my $ptyp = shift;
	my $pfrom = shift;
	my $pto = shift;
	my $pfield = shift;
	my $pstart = shift;
	my $pend = shift;
	my $pscript = shift;
  my $fcname = "FormRecognition".sprintf("%02d",$formrec);
	my $sql = "select Inhalt from $db.parameter where Art='$fcname' and ".
	          "Tabelle='archiv'";
	my @rows = $dbh2->selectrow_array($sql);
	if ($rows[0] ne "") {
	  my @flds = split(/\r\n/,$rows[0]);
	  my $c=0;
	  foreach (@flds) {
		  my @line = split(/;/,$_);
			$$ptyp[$c]=$line[5];
			$$pfrom[$c]=$line[6];
			$$pto[$c]=$line[7];
			$$pfield[$c]=$line[8];
			$$pstart[$c]=$line[9];
			$$pend[$c]=$line[10];
			$$pscript[$c]=$line[11];
		  $c++;
		}
	}
}





=head1 FormRecUpdate($db1,$dbh2,$lnr,$pfld,$pres)

Update the current document with the results from the form recognition

=cut

sub FormRecUpdate {
  my $db1 = shift;
  my $dbh2 = shift;
	my $lnr = shift;
	my $pfld = shift;
	my $pres = shift;
	my $lold = shift;
	my $user1 = shift;
	my (%hash,$sql);
  my $pfields = getFields($dbh2,"archiv");
	copyValues($dbh2,$db1,$pfields,$lold,$lnr);
  foreach(@$pfields) {
    my $f1 = $_->{name};
    last if $f1 eq "Laufnummer"; # stop for field Notes
    my $t1 = $_->{type};
    # don't update Document, Datum and Pages
    if ($f1 ne "Akte" && $f1 ne "Seiten") {
		  $hash{$f1}=$t1;
    }
	}
	my $c=0;
  foreach(@$pres) {
    my $v = $_;
		my $v1 = $v;
    my $dont = 0;
    if ($hash{$$pfld[$c]} eq "varchar" or $hash{$$pfld[$c]} eq "datetime") {
		  $v .= " 00:00:00" if $hash{$$pfld[$c]} eq "datetime";
      $v = $dbh2->quote($v);
    } else {
      $dont=1 if $v eq "";
    }
    if ($dont==0) {
      $sql .= "," if $sql ne "";
      $sql .= $$pfld[$c]."=".$v;
    }
		checkLinkFields($dbh2,\$sql,$$pfld[$c],$hash{$$pfld[$c]},$v1);
    $c++;
	}
	if ($sql ne "") {
	  $sql .= ",UserNeuName=".$dbh2->quote($user1);
	  $sql = "update $db1.archiv set $sql where Laufnummer=$lnr";
		logit($sql);
		$dbh2->do($sql);
	}
}






=head1 parseToMM

Read twain to mm (rounded to 0.x)

=cut

sub parseToMM {
  my $value = shift;
  my $value1 = ($value / 56.692);
	$value = sprintf("%0.1f",$value1);
}






=head2 rotate_coord($xcent,$ycent,$angle)

Calculate the image block for form recognition part

=cut

sub rotate_coord {
  my $xcent = shift;
  my $ycent = shift;
  my $angle = shift;
  my $x = shift;
  my $y = shift;
  $angle = $angle * pi / 180;
  my $tx = ($x - $xcent) * cos($angle) + ($y - $ycent) * sin($angle);
  my $ty = - ($x - $xcent) * sin($angle) + ($y - $ycent) * cos($angle);
  return ($tx + $xcent, $ty + $ycent);
}






=head2 dark_mark($image,$x,$y)

Paint a dark mark in an image

=cut

sub draw_mark {
  my $image = shift;
  my $x = shift;
  my $y = shift;
  ExactImage::imageDrawLine ($image, $x-10, $y-10, $x+10, $y+10);
  ExactImage::imageDrawLine ($image, $x-10, $y+10, $x+10, $y-10);
}






=head2 (lastgs,lasttime)=checkGhostscript(lastgs,lasttime)

Check if Ghostscript hangs with the first single document (same file)

=cut

sub checkGhostscript {
  my ($lastgs,$lasttime) = @_;
	my $current = `ps ax | grep 'gs'`;
	my @lines = split(/\n/,$current);
	my $line = $lines[0];
	my @lines2 = split(/\//,$line);
	my $file = pop @lines2;
	if ($lastgs ne $file) {
	  $lasttime = time();
		$lastgs = $file;
	} else {
	  my $nowtime = time();
		my $endtime = $lasttime+300;
		if ($nowtime > $endtime) {
		  logit("now killing gs while file $file seems to hang");
		  system("killall gs");
			$lastgs = "";
			$lasttime = 0;
		}
	}
	return ($lastgs,$lasttime);
}





