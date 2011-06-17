#!/usr/bin/perl

=head1 mail2axis.pl $file

(c) 2006 by René Rebe <rene@exactcode.de>, 
Urs Pfister, Mail to PDF parsing in Perl for Archivista

=cut

use strict;
use lib qw(/home/cvs/archivista/jobs);
use AVJobs;
use File::Basename "basename";
use File::Copy;
use File::Temp "tempfile";
use Encode;
use Mail::Address;
use Mail::Message;
use Mail::Message::Field;
use fields; 
#use User::Identity::Collection::Emails;
#use User::Identity::Collection;

use constant TYPE_IMG => 'img'; # we check for an image
use constant TYPE_PDF => 'pdf'; # we check for an pdf file
use constant CHECK_PDF => 'pdfinfo '; # check for pdf file 
use constant CHECK_IMG => 'identify -ping '; # check for image 
use constant OK => 0; # sucess after file check (from system)

my $file = shift; # get the file from enotify
my $notkill = shift; # don't kill the input file (test case)
# we use a pseudo hash, html/pdf/zip/tmp parts ara arrays storing temp. files
my $val = fields::phash(part=>'',pdftk=>'',html=>[],pdf=>[],zip=>[],tmp=>[]);
$val->{pdftk} = "pdftk";
open (MAIL, $file) or die "No mail filename";
$val->{part} = Mail::Message->read(\*MAIL);
close (MAIL);
# parse the mail and gives back all parts in the f... arrays
parse_mail($val);
# compose it and send it to the next job (CUPS)
compose_pdf($file,$val,$notkill);






=head1 compose_pdf($file,$val,$notkill)

Create from the pdf/zip and html parts a single pdf and sends it to cups

=cut

sub compose_pdf {
  my $file = shift;
  my $val = shift;
  my $notkill = shift;

  my $htmldoc = "htmldoc --size a4 --format pdf14 --continuous --no-embedfonts";
  my $zipit = "zip";
  
  # create the html part
  my $cmd = $htmldoc . " @{$val->{html}} --outfile body.pdf";
  system($cmd);
  
  # create the pdf part
  $cmd =  $val->{pdftk} . " body.pdf @{$val->{pdf}} cat output mail.pdf";
  
  system($cmd);
  
  # create the zip part
  my $zipfile = "parts.zip"; 
  unlink($zipfile) if (-e $zipfile); # make sure we never append
  if (scalar($val->{zip}) > 0){
    system ($zipit . " -r $zipfile @{$val->{zip}}");
  }
  foreach my $file(("body.pdf"),@{$val->{html}},
                  @{$val->{pdf}},@{$val->{zip}},@{$val->{tmp}}){
    # cleanup - later maybe work in some temp-dir
    print "del: $file\n";
    unlink ($file) if -e $file;
  }
  # now move final files and create the axis text file
  move ("mail.pdf", "/home/data/archivista/ftp/mail-$$.pdf");
  move ($zipfile, "/home/data/archivista/ftp/parts-$$.zip") if -e $zipfile;
  # parse the file to axis
  CUPSparseFile("mail-$$.pdf");
  unlink "$file" if $notkill==0;
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
    ($fh,$fname) = tempfile;
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
  my $msg = shift;
  my $html =
    "<html><body>\n" .
    "<b>Subject:</b> " . $msg->head->get('subject')->study . "<br>\n" .
    "<b>From:</b> ". htmlify ($msg->head->get('from')->study) . "<br>\n" .
    "<b>To:</b> " . htmlify ($msg->head->get('to')->study) . "<br>\n" .
    "<b>Date:</b> " . htmlify ($msg->head->get('date')->study) . "<br>\n" .
    "<br></body></html>\n";
  return $html;
}






=head1 htmlInline($part,$val)

Create form a inline html message different files (calls parse_mail)

=cut

sub htmlInline {
  my $part = shift;
  my $val = shift;
  print "mail part (fwd)\n";
  # I found no contructor taking the scalar :-(
  #my $fwd_msg_txt = $part->decoded;
  #my $fwd_msg = Mail::Message->read($part);
  #print $fwd_msg_txt;
  #my $fwd_msg = Mail::Message->read($fwd_msg_txt);
  # write out to file, inefficient but works
  open(FH, ">fwd.msg");
  $part->decoded->print(\*FH);
  close(FH);
  open(FH, "fwd.msg");
  $val->{part} = Mail::Message->read(\*FH);
  close(FH); 
  unlink("fwd.msg");
   
  push @{$val->{html}},writefile("<BR><B>Encapsulated message:</B><BR>");
  # recursive call of parsing a mail
  parse_mail($val);
  push @{$val->{html}},writefile("<p><B>... end of encapsulated message.</B>");
}






=head1 htmlOther($part,$filename)

Extracts a not HTML/PDF file, saves it and give it back

=cut

sub htmlOther {
  my $part = shift;
  my $filename = shift;
  print "other part\n";
  if ($filename eq "none") {
    $filename = "unnamed-part";
  } else {
    $filename =~ s/\s/_/g; # no spaces in the filename
  }
  return writefile($part,$filename);
}






=head1 htmlPDF($part,$val)

Create a pdf file and add it to the array

=cut

sub htmlPDF {
  my $part = shift;
  my $val = shift;
  
  print "recognized PDF part\n";
  # we can not use the filename for PDFs since pdftk appears to
  # dislike UTF-8
  my $fname = writefile($part);
  # test if it is readable (e.g. encrypted)

  my $cmd = $val->{pdftk} . " $fname cat 1 output /tmp/test.pdf";
  system ($cmd);

  if ($? == 0) {
    push @{$val->{pdf}}, $fname;
  } else {
    push @{$val->{zip}}, $fname;
  }
}






=head1 htmlImage($part,$filename,$val)

Add an image as a html part

=cut

sub htmlImage {
  my $part = shift;
  my $filename = shift;
  my $val = shift;

  print "recognized image part\n";
  push @{$val->{tmp}}, $filename; 
  my $html = "<HTML><BODY><IMG WIDTH=\"100%\"SRC=\"$filename\">" .
          "</BODY></HTML>";
  push @{$val->{html}}, writefile($html);
}






=head1 htmlAttach($pparts)

During first check, add all file names in a list

=cut

sub htmlAttach {
  my $pparts = shift;
  my $html = "<B>Attachments:</B>";
  foreach my $p (@$pparts) {
    my $filename = htmlGetFilename($p);
    next if $filename eq "none";
    $html = $html . " " . $filename;
  }
  $html = $html . "<br><br>";
  return $html;    
}






=head1 htmlFromText($part)

Add a text part to the html array

=cut

sub htmlFromText {
  my $part = shift;
  # we have a plain part and are not in HTML mode, use it
  my $html = htmlify ($part->decoded());
  # explicit HTML newlines
  $html =~ s/\n/<br>\n/g;
  return $html;
}






=head1 htmlSinglePart($val)

Add a single part mail to the html array

=cut

sub htmlSinglePart {
  my $val = shift;
  # ordenary message, only one text part
  print "ordenary, only one text part\n";
  my $html = htmlify ($val->{part}->decoded());
  # explicit HTML newlines
  $html =~ s/\n/<br>\n/g;
  push @{$val->{html}}, writefile($html);
}






=head1 htmlMultiPart($val)

Check a multipart html fragment to its parts and add all chunks to
the appropriate arrays

=cut

sub htmlMultiPart {
  my $val = shift;
  
  # check if the message or the first multipart is an alternative
  my $html_mode = 0;
  my @parts = $val->{part}->parts;
  my $type = $val->{part}->get('Content-Type');
  my $typep = $parts[0]->get('Content-Type');
  if ($type eq "multipart/alternative" || $typep eq "multipart/alternative") {
    $html_mode = 1; # does mean, we have both text/plain AND text/html 
  }
  
  my $i = 0;
  my $attach_list = 0; # do we have attachments
  foreach my Mail::Message::Part $part (@parts) {
    my $type = $part->get('Content-Type');
    $i += 1;
    # decide what to use as main body from alternative multiparts :-(
    if ($type eq "multipart/alternative") {
      htmlMultiPartAlternative($part,$i,$html_mode,\@{$val->{html}});
    } else {
      my $filename = htmlGetFilename($part);
      if (htmlValidMode($html_mode,$i,$type)) {
        if ($type eq "text/plain") {
          push @{$val->{html}}, writefile(htmlFromText($part));
        } elsif ($type =~ "text/html") {
          push @{$val->{html}}, writefile($part);
        } else {
          $attach_list = 1; # we have attachments, so add later the list
          if ( $type =~ ".*/rfc822" ) {
            # An Inline Mail
            htmlInline($part,$val);
          } else {
            # Somthing else (pdf,img,...)
            # Write it out to the disk
            # Then Check with pdfinfo if it is an PDF
            # and check with identify if it is an image
            $filename = writefile($part);

            if (checkFile($filename,TYPE_PDF)) {
              htmlPDF($part,$val);
            } elsif (checkFile($filename,TYPE_IMG)) {
              htmlImage($part,$filename,$val);
            } else {
               push @{$val->{zip}}, htmlOther($part,$filename);
            }
          }
        }
      }
    }
  }
  # add the attachment list as a html file
  push @{$val->{html}}, writefile(htmlAttach(\@parts)) if $attach_list==1;
}




=head1 $return=checkFile($filename,$type)

Checks the given file. It is an pdf or an image.

=cut

sub checkFile {
  my $filename = shift;
  my $type = shift;
  return if (!-e $filename); # don't do anything if there is no file
  my $cmd = CHECK_IMG; # default check is image
  $cmd = CHECK_PDF if $type eq TYPE_PDF;
  $cmd .= $filename;
  my $return = system($cmd);
  $return = $return == OK ? 1 : 0;
  return $return;
}








=head1 $ret=htmlValidMode($html_mode,$i,$type) 

If we have a html mail and the second part is a text/plain part,
we don't process it (it would be a second (unformatted) copy

=cut

sub htmlValidMode {
  my $html_mode = shift;
  my $i = shift;
  my $type = shift;
  my $ret = 0;
  print "type=$type";
  if ($html_mode == 1 && $i <= 2 && $type eq "text/plain") {
    print ": due HTML mode plain part skipped";
  } else {
    $ret=1; # we need to process the part
  }
  print "\n";
  return $ret;
}






=head1 $filename=htmlGetFilename($part)

Gives back the filename from a html part

=cut

sub htmlGetFilename {
  my $part = shift;
  #my $filename = $part->body->decoded->dispositionFilename;
  my $filename = $part->body->disposition->study;
  $filename =~ s/.*filename=//; $filename =~ s/"//g;
  $filename = basename $filename;
  return $filename;
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

Parse a mail (msg) to its parts and gives back all html,pdf,zip and
temp parts. Everything is stored in the "pseudo" hash $val (using fields)

=cut

sub parse_mail {
  my $val = shift;

=later
  my $from = $msg->head->study('From');  # not yet done
  my @addr = $from->addresses;
  my @from = $msg->from;
  my @to = $msg->to;
  #my $field    = $msg->head->get('Content-Disposition');
  #my $full     = $field->study();   # full understanding in unicode
  #my $filename = $full->attribute('filename');
=cut

  push @{$val->{html}}, writefile(htmlHeader($val->{part}));
  if ($val->{part}->isMultipart) {
    htmlMultiPart($val);
  } else {
    htmlSinglePart($val);
  }
}

