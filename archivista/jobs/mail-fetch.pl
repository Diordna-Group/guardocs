#!/usr/bin/perl

=head1 mail-fetch.pl (c) 2011 by Archivista GmbH, Urs Pfister

Programm does either get one mail from command line ($db $name $file) or
it searches all databases on localhost if we have enable MailArchiving.
If so, it fetches the mails from an IMAP mail server and moves the mails
to the ftp folder, so axis2sane.pl can process them

=cut

# Note: IMAPClient 2.* is requires for proper IMAP + SSL handling.

use strict;
use lib qw(/home/cvs/archivista/jobs);
use DBI;
use AVJobs;
use IO::Socket;
use IO::Socket::SSL;
use Mail::IMAPClient;
use IO::File;
use File::Copy;
use File::Temp "tempfile";
use File::Basename "basename";
use Encode;
use Mail::Address;
use Mail::Message;
use Mail::Message::Field;
use Date::Calc qw(Delta_Days);
use Text::Wrap;

use constant TYPE_IMG => 'img'; # we check for an image
use constant TYPE_PDF => 'pdf'; # we check for an pdf file
use constant CHECK_PDF => 'pdfinfo '; # check for pdf file 
use constant CHECK_IMG => 'identify -ping '; # check for image 
use constant CHECK_HTML => 'identify -ping '; # check for image 
use constant HTMLDOC => 'htmldoc --size a4 --format pdf14 '.
                        '--continuous --no-embedfonts ';
use constant DECODE => 'mha-decode ';
use constant OK => 0; # sucess after file check (from system)
use constant CHECK_MAIL => "/tmp/mail-fetch.chk";
use constant OO => "/usr/bin/perl /home/cvs/archivista/jobs/mail-check.pl ";
use constant OOWAIT => 150; # twice the time in mail-check.pl (sleep 2)
use constant CONVERT => 'convert ';
use constant MAX_WRAP => 8388608;

my $db = shift;
my $def = shift;
my $file = shift;

if (! -e "/etc/mail-fetch-webconfig.conf") {
  logit("mail archiving not yet enabled. Please first enable it!");
	exit;
}
if (-e CHECK_MAIL) {
  logit("archiving process already started. If it hangs, restart service");
	exit;
}

writeFile(CHECK_MAIL,\"ok"); # say that we started

my $dbh=MySQLOpen(); # connect to a database
if ($dbh) {
  logit("connection for mail archiving ok");
  if (HostIsSlave($dbh)==0) { # we are not in slave mode
    logit("host is in master mode");
    # first, we need all Archivista databases
    my $pdb = getValidDatabases($dbh); # check all databases
    foreach my $db1 (@$pdb) {
			next if $db ne "" && $db ne $db1;
		  my $sql = "use $db1";
			$dbh->do($sql);
		  logit("checking database $db1");
		  my $val = "MailArchiving";
			my $val01 = $val."01";
			# get all mail entries from one database
      my $line = getParameterReadWithType($dbh,$db1,$val01,$val);
			if ($line ne "") {
		    logit("checking mail accounts from database $db1");
			  my @lines = split(/\r\n/,$line);
			  foreach my $line2 (@lines) { # check every mailbox in a database
			    fetchMails($dbh,$db1,$line2,$def,$file); # send mail to ftp folder
			  }
		  }
		}
	}
}

unlink CHECK_MAIL if -e CHECK_MAIL;







=head1 fetchMails($dbh,$db1,$line,$def,$file)

Fetch a mail and send it to ftp folder

=cut

sub fetchMails {
  my ($dbh,$db,$line,$def,$filecmd) = @_;
	my ($name,$server,$port,$user,$passwd,$ssl,$mailbox1,
	    $from,$cc,$to,$subject,$owner,$age,$delete,
			$move,$restore,$scandef,$noattach,$inactive) = split(";",$line);
	$noattach=0 if $noattach eq ""; # if nothing, we want the attachemnts
	if ($inactive==1) {
	  logit("mail archiving definition $name IS INACTIVE.................");
	  return;
	}
	return if $def ne "" && $def ne $name; # def/message from command line?
	my @mailboxes = split(",",$mailbox1);
	my @msg_list = ();
  my $bit64 = 0;
	$bit64=1 if check64bit()==64;
	foreach my $mailbox (@mailboxes) {
	  $restore = $mailbox if $restore eq ""; # send back default folder if none
	  $restore = "mail;$name;$restore"; # name for restore (mail;name;folder)
    logit("$db with $name-$server-$port-$user-$ssl-$mailbox-$from-$cc-$to-".
	        "$subject-$age-$delete-$scandef-$move-$restore-$noattach-$inactive");
    my $maildir = "/tmp/mail";
		mkdir $maildir if !-e $maildir;
		my $client = 0;
		if ($filecmd eq "") {
      my $socket = 0;
      if ($ssl==1) {
        logit("opening SSL socket ...");
        $socket = IO::Socket::SSL->new(PeerAddr => $server,PeerPort => $port)
                                   or die "SSL socket(): $@";
      } else {
        logit("opening INET socket ...$server-$port");
        $socket = IO::Socket::INET->new(PeerAddr => $server,PeerPort => $port)
                                    or die "INET socket(): $@";
      }
      my $greeting = <$socket>;
      my ($id, $answer) = split /\s+/, $greeting;
			if ($answer eq "OK") {
        logit("greeting OK: $greeting");
        # Build up the client attached to the socket and login
				my $passwd1 = pack("H*",$passwd);
		    if ($bit64==1) {
          $client = Mail::IMAPClient->new(User => $user,Password => $passwd1,
	       			            RawSocket => $socket) or die "IMAP new(): $@";
				} else {
          $client = Mail::IMAPClient->new(User => $user,Password => $passwd1,
	       			            Socket => $socket) or die "IMAP new(): $@";
				}
        $client->State(Mail::IMAPClient::Connected());
				my $res = $client->login();
				if ($res) {
          my $res2 = $client->select($mailbox); # like 'INBOX'
					if (!$res2) {
    			  my @list = $client->list();
		    	  foreach(@list) {
						  my $line = $_;
							chomp $line;
			        logit($line);
			      }
						logit("mailfolder $mailbox does not exist!!!");
					} else {
            @msg_list = $client->search('UNDELETED');
					}
				} else {
				  logit("no login: ".$client->LastError());
				}
			} else {
        logit("problems logging in: $greeting");
			}
		} else {
		  if (-e $filecmd) {
			  my $data = "";
				readFile2($filecmd,\$data);
				$msg_list[0] = $data;
			}
		}
    my $i = 0;
    foreach my $message (@msg_list) {
	    $i++; # count number of mails
			#next if $i<635;
			#last if $i>638;
			my $res = 0;
			my ($filename,$fh);
			if ($filecmd eq "") {
		    my $diff = 0;
		    my ($day1,$month1,$year1) = getNow();
	      my $date = $client->date($message);
		    my ($date2,$day2,$month2,$year2) = getDate($date);
        eval { $diff = Delta_Days($year2,$month2,$day2,$year1,$month1,$day1) };
			  if ($diff > $age || $age==0) {
	        ($fh, $filename)  = tempfile("$maildir/eml-XXXX")
	                            or die "failed to open message for writing\n";
	        $client->message_to_file($fh, $message)
	                 or die "could not write message: $@\n";
	        $fh->close();
		      logit("MAIL $i:$filename goes to $db");
					$res = 1; # process mail
				} else {
		      logit("MAIL AGE is $diff, minimum age $diff required ".
			          "==================================$i");
				}
			} else {
			  $res = 1; # process mail
				$filename = $filecmd;
			}
			if ($res==1) {
		    fetchProcess($db,$filename,$from,$cc,$to,$subject,$owner,
			               $scandef,$restore,$noattach,$i,$maildir);
		    #print "fetch next mail?\n";
		    #<>;
	      # delete message on server if configured to
			  $res = 0;
				if ($filecmd eq "") {
			    if ($move ne "") {
			      logit("MOVE MAIL to $move ==============================$i");
			      $res=$client->move($move,$message);
			    }
	        if ($delete==1 && $res==0) {
			      logit("DELETE MAIL ==============================$i");
	          #$client->delete_message($message);
	        }
				}
		  }
	  }
		if ($filecmd eq "") {
      $client->logout() 
		} else  {
		  last;
		};
	}
	logit("Mail fetched.......");
}






=head1 fetchProcess($db,$file,$from,$cc,$to,$subject,$ow,$sc,$rest,$att,$i)

Process one single mail and send it to ftp folder

=cut

sub fetchProcess {
  my ($db,$file,$from,$cc,$to,$subject,$owner,
	    $scandef,$restore,$noattach,$i,$maildir) = @_;
  # we use a pseudo hash, html/pdf/tmp parts ara arrays storing temp. files
  my $val = {part=>'',pdftk=>'',html=>[],pdf=>[],tmp=>[],
	                        utf8header=>0,utf8=>0};
  $val->{pdftk} = "pdftk";
  open (MAIL, $file) or die "No mail filename";
  $val->{part} = Mail::Message->read(\*MAIL);
  close (MAIL);
  # parse the mail and gives back all parts in the f... arrays
	my $fields = "";
  parse_mail($val,\$fields,$from,$cc,$to,$subject,$noattach,$file,$i,$maildir);
	if ($owner ne "") {
	  $fields .= ":" if $fields ne "";
		$fields .= "Eigentuemer=".escape($owner);
	}
  # compose it and send it to the next job (CUPS)
  compose_pdf($file,$val,$db,$scandef,$fields,$restore,$i,$maildir);
}






=head1 compose_pdf($file,$val,$db,$from,$cc,$to,$subject,$owner,$scandef,$i)

Create from the pdf and html parts a single pdf and sends it to cups

=cut

sub compose_pdf {
  my ($file,$val,$db,$scandef,$fields,$restore,$i,$maildir) = @_;
  my $zipit = "zip";
	my $found = 0;
	my $body = "body.pdf";
	while ($found==0) {
    # create the html part
		unlink $body if -e $body;
    my $cmd = HTMLDOC . " @{$val->{html}} --outfile $body";
    my $res = system($cmd);
	  logit("$res=$cmd");
	  if ($res==0 || -e $body) {
      # create the pdf part
		  my $files = "";
		  foreach (@{$val->{pdf}}) {
		    $files .= " " if $files ne "";
		    $files .= "'$_'";
		  }
      $cmd =  $val->{pdftk} . " $body $files cat output mail.pdf";
	    logit("$res=$cmd");
      $res = system($cmd);
		  if ($res==0) {
        # create the zip part
        my $ziptemp = "parts.zip"; 
        unlink($ziptemp) if (-e $ziptemp); # make sure we never append
        $cmd = $zipit . " -j $ziptemp $file";
			  $res = system($cmd);
	      logit("$res=$cmd");
			  if ($res==0) {
          foreach my $file(($body),@{$val->{html}},
				                 @{$val->{pdf}},@{$val->{tmp}}){
            # cleanup - later maybe work in some temp-dir
            logit("del: $file");
            unlink ($file) if -e $file;
          }
          # now move final files and create the axis text file
	        my ($filebase,$filetxt,$filepdf,$filezip) = compose_file($i,0);
	        my $c=0;
	        while ($filebase eq "") {
	          ($filebase,$filetxt,$filepdf,$filezip) = compose_file($i,1);
		        $c++;
		        last if $c>10;
	        }
          move ("mail.pdf", "$filebase$filepdf");
          move ($ziptemp, "$filebase$filezip");
				  $fields .= ":" if $fields ne ""; # add restore folder name
				  $fields .= "EDVName=".escape($restore); 
          # parse the file to axis
          CUPSparseFile($filepdf,"",$db,$scandef,$fields,"$filebase$filezip");
          unlink "$file" if -e "$file";
			  } else {
		      logit("ZIP ERROR ==================================$i");
			  }
		  } else {
		    logit("PDFtk ERROR ==================================$i");
		  }
			$found=1;
	  } else {
      logit("HTMLDOC ERROR ==================================$i");
		  my $el = pop @{$val->{html}};
			my $fpart = writefile("");
      my $cmd = HTMLDOC . "$el --outfile $fpart";
      $res = system($cmd);
		  if ($res==0 && -e $fpart) {
			  logit("this part is ok, now adding to pdfs: $fpart");
		    push @{$val->{pdf}},$fpart;
			} else {
			  logit("this part is not ok, now removing: $fpart");
			  unlink $fpart if -e $fpart;
			}
			unlink $el if -e $el; # remove old html part file
		  $el = @{$val->{html}};
			$found=1 if $el==0;
		}
	}
	my $folder = "$maildir/$i";
	system("rm -Rf $folder");
}






=head1 compose_file($i,$nr)

Give back a file name for ftp folder according $i mail and $nr part

=cut

sub compose_file {
  my ($nr,$wait) = @_;
  my $base = "/home/data/archivista/ftp/";
	my $time = TimeStamp();
	my $fpdf = "mail-$nr-$time.pdf";
	my $ftxt = "mail-$nr-$time.txt";
	my $fzip = "mail-$nr-$time.zip";
	$base="" if (-e "$base$ftxt" || -e "$base$fpdf" || -e "$base$fzip");
	sleep $wait if $wait>0;
	return ($base,$ftxt,$fpdf,$fzip);
}






=head1 $txt=htmlify($txt)

Replace </> chars in html part

=cut

sub htmlify {
  my $txt = shift;
  $txt =~ s/</&lt;/g;
  $txt =~ s/>/&gt;/g;
  return $txt;
}






=head1 $fname=writefile($val,$filename)

Get a scalar $val or an object Mail::Message. If it is a scalar,
save the content ($val) to a temp file and give back the name as $fname.
If it is an object, first decode it and write it to $fname.

$filename (opt): create the temp file name with this template

=cut

sub writefile {
  my $val = shift;
  my $filename = shift;
  my ($fh,$fname);
  if ($filename ne "" && !-e $filename) {
    # if we got a filename and the file does not exist,
    # just use this filename in the current directory
    $fname=$filename;
    open($fh,">$fname");
  } else {
    ($fh,$fname) = tempfile(DIR=>"/tmp/mail");
  }
  if (ref($val)) { # if it is a mail object, decode it
    $val->decoded->print($fh);
  } else { # otherwise just print it to the file
    print $fh $val;
  }
  close($fh);
  return $fname;
}






=head1 htmlHeader($msg)

Create a html header and give it back as html part

=cut

sub htmlHeader {
  my $val = shift;
  my $html = "<html><body>\n";
	my $subject1 = checkMessageElement($val->{part},"subject",1);
	$html .= "<b>Subject:</b> $subject1<br>\n";
	my $from1 = checkMessageElement($val->{part},"from",1);
  htmlHeaderFormat(\$from1);	
	$html .= "<b>From:</b> $from1<br>\n";
	my $to1 = checkMessageElement($val->{part},"to",1);
  htmlHeaderFormat(\$to1);	
	$html .= "<b>To:</b> $to1<br>\n";
	my $cc1 = checkMessageElement($val->{part},"cc",1);
  htmlHeaderFormat(\$cc1);	
	$html .= "<b>CC:</b> $cc1<br>\n" if $cc1 ne "";
	my $date1 = checkMessageElement($val->{part},"date",1);
  $html .=  "<b>Date:</b> $date1<br>\n<br></body></html>\n";
	$html = Encode::decode('utf8',$html) if $val->{utf8header}==1;
  return $html;
}






=head htmlHeaderFormat($ptext)

Remove "/' chars from from/cc/to field

=cut

sub htmlHeaderFormat {
  my ($ptext) = @_;
	$$ptext =~ s/\"//g;
	$$ptext =~ s/\'//g;
}






=head1 htmlPDF($part,$val)

Create a pdf file and add it to the array

=cut

sub htmlPDF {
  my $part = shift;
  my $val = shift;
  logit("recognized PDF part");
  # we can not use the filename for PDFs since pdftk appears to
  # dislike UTF-8
  my $fname = writefile($part);
  # test if it is readable (e.g. encrypted)
  my $cmd = $val->{pdftk} . " '$fname' cat 1 output /tmp/test.pdf";
  system ($cmd);
  if ($? == 0) {
    push @{$val->{pdf}}, $fname;
  }
}






=head htmlOfficePDF($filename,$filename1,$val)

Create a pdf file from somewhat like an office file

=cut

sub htmlOfficePDF {
  my ($filename,$filename1,$val) = @_;
	my ($fin1,$path,$base1) = CheckFileNamePathBase($filename1);
  my $fin2 = "$path$base1\.pdf";
	if (!-e $fin1) {
    move($filename,$fin1);
    my $res=system("chown archivista.users '$fin1'");
		if ($res==0) {
		  my $cmdcheckoffice = OO.OOWAIT." '$fin1' '$fin2' &";
			system($cmdcheckoffice);
      ($res,$fin1,$fin2)=OpenOfficeConvert($fin1,$path,$base1,1);
			logit("oo conversion:$res--$fin1--$fin2");
			if (!-e $fin2) {
			  logit("first try, $fin2 not found");
	      my $fin1a = "$path$base1\.txt";
	      unlink $fin1a if -e $fin1a;
	      $res=move($fin1,$fin1a) if !-e $fin1a;
				$fin1 = $fin1a;
	      if ($res==1) {
				  logit("start second try for $fin1");
		      my $cmdcheckoffice = OO.OOWAIT." '$fin1' '$fin2' &";
			    system($cmdcheckoffice);
          ($res,$fin1,$fin2)=OpenOfficeConvert($fin1,$path,$base1,2);
			    logit("oo conversion2:$res--$fin1--$fin2");
				}
			}
      unlink $fin1 if -e $fin1;
			if ($res==0 && -e $fin2) {
			  logit("file $fin2 is ok");
        push @{$val->{pdf}}, $fin2;
			} else {
			  logit("output file $fin2 is not ok");
			  unlink $fin1 if -e $fin1;
			  unlink $fin2 if -e $fin2;
			}
		}
  }
}






=head1 $return=checkFile($filename,$type)

Checks the given file. It is an pdf or an image.

=cut

sub checkFile {
  my $filename = shift;
  my $type = shift;
	my $return = 0;
  return if (!-e $filename); # don't do anything if there is no file
  my $cmd = CHECK_IMG; # default check is image
	if ($type eq TYPE_PDF) {
    $cmd = CHECK_PDF; 
    $cmd .= $filename;
    $return = system($cmd);
    $return = $return == OK ? 1 : 0;
	} else {
    my $identify = $cmd.$filename;
    my $cmdinfo = `$identify`;
	  my @infos = split(" ",$cmdinfo);
	  my $format1 = $infos[1];
	  if ($format1 eq "PNM" || $format1 eq "PNG" || $format1 eq "TIF" ||
	      $format1 eq "JPEG" || $format1 eq "GIF" || $format1 eq "BMP" ||
			  $format1 eq "TIFF") {
		  $return = 1;
		}
	}
  return $return;
}






=head1 htmlMultiPartAlternative($part,$i,$html_mode,$pfhtml)

Get the main html body part and add it to the html array

=cut

sub htmlMultiPartAlternative {
  my $parts = shift;
  my $i = shift;
  my $html_mode = shift;
  my $pfhtml = shift;
  foreach my $part ($parts->parts) {
    my $type = $part->get('Content-Type');
    if (htmlValidMode($html_mode,$i,$type)) {
      # we should be on the main body html part here
      push @$pfhtml, writefile($part);
    }
  }
}






=head1 parse_mail($val);

Parse a mail (msg) to its parts and gives back all html,pdf and
temp parts. Everything is stored in the "pseudo" hash $val (using fields)

=cut

sub parse_mail {
  my ($val,$pfields,$from,$cc,$to,$subject,$noattach,$file,$i,$maildir) = @_;
	if ($$pfields eq "") {
	  my $from1 = checkMessageElement($val->{part},"from");
    htmlHeaderFormat(\$from1);	
	  parse_field($pfields,$from,$from1);
	  my $to1 = checkMessageElement($val->{part},"to");
    htmlHeaderFormat(\$to1);	
	  parse_field($pfields,$to,$to1);
	  my $cc1 = checkMessageElement($val->{part},"cc");
    htmlHeaderFormat(\$cc1);	
	  parse_field($pfields,$cc,$cc1);
	  my $titel1 = checkMessageElement($val->{part},"subject");
		$subject="Titel" if $subject eq "";
	  parse_field($pfields,$subject,$titel1);
	  my $date = checkMessageElement($val->{part},"date");
		my ($date2,$y2,$m2,$d2) = getDate($date);
	  parse_field($pfields,"Datum",$date2) if $date2 ne "";
	}
  parse_head_utf8($val);
  push @{$val->{html}}, writefile(htmlHeader($val));
	parse_parts($val,$file,$i,$maildir);
}






=head1 parse_parts($val,$file,$i,$maildir)

Check the given parts for type (html/image/pdf/office)

=cut

sub parse_parts {
  my ($val,$file,$i,$maildir) = @_;
  my $folder = "$maildir/$i";
	my @outs = parse_parts_folders($folder,$file);
	my @attach = ();
	foreach (@outs) {
	  my $filename = $_;
    my $ext = lc(getFileExtension($filename));
		if ($ext eq "txt") {
			my $content = "";
			if ($val->{utf8}==1) {
			  $content = `cat $filename | iconv -c -f utf-8 - -t iso-8859-1`;
			} else {
			  readFile2($filename,\$content);
			}
			if (length($content)<=MAX_WRAP) {
        $Text::Wrap::columns=88;
	      $Text::Wrap::separator="\n";
		    $content =  wrap("","",$content);
			}
			$content = "<PRE>".$content."</PRE>";
			writeFile($filename,\$content,1);
		}
		if ($ext eq "html") {
		  if ($val->{utf8}==1) {
			  my $content = `cat $filename | iconv -c -f utf-8 - -t iso-8859-1`;
				writeFile($filename,\$content,1);
			}
		}
		if ($ext eq "html" || $ext eq "txt") {
		  logit("$filename is html part");
      push @{$val->{html}}, $filename;
		} else {
		  push @attach, $filename;
      if (checkFile($filename,TYPE_PDF)) {
        my $cmd = $val->{pdftk} . " '$filename' cat 1 output /tmp/test.pdf";
        system ($cmd);
        if ($? == 0) {
          push @{$val->{pdf}}, $filename;
				} else {
          push @{$val->{tmp}}, $filename;
				}
      } elsif (checkFile($filename,TYPE_IMG)) {
			  parse_parts_image($filename,$val,$folder,$i);
			} else {
        my $filename1 = basename $filename;
			  htmlOfficePDF($filename,$filename1,$val);
			}
		}
	}
	if ($attach[0] ne "") {
    my $html = "<B>Attachments:</B><br>\n";
    foreach (@attach) {
      my $filename = basename $_;
			$html .= "$filename<br>\n";
		}
    $html .= "<br><br>";
    push @{$val->{html}},writefile($html);
  }
}






=head1 parse_parts_image($filename,$val,$folder,$i)

Check an convert an given image to an pdf file (openoffice)

=cut

sub parse_parts_image {
  my ($filename,$val,$folder,$i) = @_;
 	my $filename2 = basename $filename;
	my @parts = split(/\./,$filename2);
  my $ext = pop @parts;
	my $base = join(".",@parts);
	for (my $c=0;$c<20;$c++) {
	  my $base1 = $base;
		$base .= "$c" if $c>0;
	  $base1 .= ".$ext" if $base eq "";
	  $base1 .= ".png";
	  $filename2 = "$folder/$base1";
		if (!-e $filename2) {
			$c=20;
		}
	}
	unlink $filename2 if -e $filename2;
	my $cmd = CONVERT . "$filename $filename2";
	my $res = system($cmd);
  logit("$res--$cmd");
	if ($res==0) {
    system("chmod 777 $filename2");
    system("chown -R archivista.users $filename2");
	  unlink $filename if -e $filename;
	  $filename = $filename2;
    my $filename1 = basename $filename;
	  htmlOfficePDF($filename,$filename1,$val);
	} else {
	  unlink $filename if -e $filename;
		unlink $filename2 if -e $filename2;
	}
}






=head @outs = parse_parts_folders($folder)

Give back the created filenames

=cut

sub parse_parts_folders {
  my ($folder,$file) = @_;
	system("rm -Rf $folder") if -e $folder;
	mkdir $folder;
  system("chmod 777 $folder");
  system("chown -R archivista.users $folder");
	my @outs = (); 
  if (-d $folder) {
	  my $cmd = DECODE . "$file -outdir $folder";
	  my $res = system($cmd);
		logit("$res--$cmd");
	  if ($res==0) {
      opendir(DIR,$folder);
      my @files = readdir(DIR); 
      closedir(DIR);
	    foreach (@files) {
		    next if $_ eq ".";
		    next if $_ eq "..";
			  push @outs,"$folder/$_";
		  }
		}
	}
	return @outs;
}






=head1 ($d,$m,$y)=getNow()

Give back the current day in day,month,year format

=cut

sub getNow {
  my @t = localtime( time() );
  my $y = $t[5] + 1900;
  my $m = $t[4] + 1;
  $m = sprintf( "%02d", $m );
  my $d = sprintf( "%02d", $t[3] );
  return ($d,$m,$y);
}






=head1 $date2=getDate($date)

Give back a data string with dd.mm.yy

=cut

sub getDate {
  my ($date) = @_;
	my ($date2,$day,$month,$year);
  if ($date ne "") {
		my @dates = split(" ",$date);
		my $c=0;
		foreach (@dates) {
		  my $month1 = $_;
		  $month = getDateCheckMonth($month1);
			last if $month ne "";
			$c++;
		}
		if ($c>0) {
		  my $cd = $c-1;
			my $cy = $c+1;
		  $day = $dates[$cd];
		  $day = "0".$day if length($day)==1;
		  $year = $dates[$cy];
      $date2 = $day.".".$month.".".$year;
		}
	}
	return ($date2,$day,$month,$year);
}






=head1 $month=getDateCheckMonth($month1)

Check if a given mid long month value is given and gives back 01..02

=cut

sub getDateCheckMonth {
  my ($month1) = @_;
	my $month = "";
	$month1 = lc($month1);
	$month = "01" if $month1 eq "jan";
	$month = "02" if $month1 eq "feb";
	$month = "03" if $month1 eq "mar";
	$month = "04" if $month1 eq "apr";
	$month = "05" if $month1 eq "may";
	$month = "06" if $month1 eq "jun";
	$month = "07" if $month1 eq "jul";
	$month = "08" if $month1 eq "aug";
	$month = "09" if $month1 eq "sep";
	$month = "10" if $month1 eq "oct";
	$month = "11" if $month1 eq "nov";
	$month = "12" if $month1 eq "dec";
	return $month;
}






=head1 $line = checkMessageElement($msg,$name,$html)

Check if the element (subject,from,to,cc) is available, if yes, give it back

=cut 

sub checkMessageElement {
  my ($obj,$name,$html) = @_;
	my $line = "";
  eval { $line = $obj->head->get($name)->study };
	$line = htmlify($line) if $line ne "" && $html==1;
	return $line;
}






=head1 parse_field($pfields,$field,$val) 

Store one single field if there is one

=cut

sub parse_field {
  my ($pfields,$field,$val) = @_;
	if ($field ne "" && $val ne "") {
	  $$pfields .= ":" if $$pfields ne "";
		$val = escape($val);
		$$pfields .= "$field=$val";
	}
}






=head $utf8=parse_head_utf8($val)

Give back if we have an utf8 based mail

=cut

sub parse_head_utf8 {
  my ($val) = @_;
  $val->{part}->head =~ /(charset=)(.*?)(utf-8)/;
	$val->{utf8header} = 1 if $1 eq "charset=" && $3 eq "utf-8";
	if ($val->{utf8header}==0) {
    $val->{part}->head =~ /(charset=)(.*?)(UTF-8)/;
	  $val->{utf8header} = 1 if $1 eq "charset=" && $3 eq "UTF-8";
	}
  $val->{part}->body =~ /(charset=)(.*?)(utf-8|UTF-8)/;
	$val->{utf8} = 1 if $1 eq "charset=" && lc($3) eq "utf-8";
	if ($val->{utf8}==0) {
    $val->{part}->body =~ /(charset=)(.*?)(UTF-8)/;
	  $val->{utf8} = 1 if $1 eq "charset=" && $3 eq "UTF-8";
	}
}

										
