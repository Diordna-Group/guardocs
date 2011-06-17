#!/usr/bin/perl

# winupload.pl -> script for uploading a document via web client
# (c) 2008 by Archivista GmbH, Urs Pfister

use strict;
use LWP::UserAgent; # we work with UserAgent (our batch web browser)
use HTTP::Request::Common qw(POST); # the post method must be imported

my $ho = shift;
my $db = shift;
my $us = shift;
my $pw = shift;
my $def = shift;
my $https = shift;
my $fout = shift;
my $meta = shift;
if ($us ne "") {
  setConf($ho,$db,$us,$pw,$def,$https) if !-e $fout;
} else {
  if ($ho ne "") {
    $fout = $ho if $ho ne "";
	  $meta = $db if $db ne "";
    ($ho,$db,$us,$pw,$def,$https)=getConf(); # get configuration
    die "no valid input file $fout" if !-e $fout;
	} else {
	  print "$0 v1.0 (c) 2010 by Archivista GmbH, upload files to WebClient\n";
		print "This program has three modes, a) single, b) config and c) upload\n";
		print "a) single mode: $0 host db user password def https file [meta]\n";
		print "b) config mode: $0 host db user password [def=0..x https=0/1]\n";
		print "c) upload mode: $0 file [fieldname1=value1:fieldname2=value2..]\n";
		print "\n";
	}
}
my $mode = "http://";
$mode = "https://" if $https==1;
my $server = "$mode$ho/perl/avclient/index.pl"; 
my $www = LWP::UserAgent->new; # new www session 
# now upload a file, we use request method with POST
my $res = $www->request(POST "$server",
  Content_Type => 'form-data', # multipart/form-data
  Content => [ # structure for our file
  MAX_FILE_SIZE => 134217728, # max. size (WebClient won't accept more)
  upload => [ $fout, $fout ], # file to upload, file name to use 
  go => 'go_action', # we need to call the go_action command
  action => 'upload', # inside of go_action we need to use upload
  uploaddef => $def, # scan def
  host => 'localhost',
  db => $db,
  uid => $us,
  pwd => $pw,
	frm_Laufnummer => 1,
	meta => $meta,
]);
if ($res->is_success) { # if we got a succes, file is uploaded
  print "file $fout sent to $ho, check if it is uploaded!\n";
}



sub getConf {
  open(FIN,"winupload.dat");
  my @lines = <FIN>;
	my $crypt = join("",@lines);
  my $pad = "Y" x length $crypt;
  my $string = $crypt ^ $pad;
	@lines = split("\n",$string);
  chomp @lines;
  my $host = $lines[0];
  my $db = $lines[1];
  my $user = $lines[2];
  my $pw = $lines[3];
  my $def = $lines[4];
  my $https = $lines[5];
  return ($host,$db,$user,$pw,$def,$https);
}



sub setConf {
  my ($host,$db,$user,$pw,$def,$https) = @_;
  $def = 0 if $def eq "";
  $https = 0 if $https != 1;
	my $string = "$host\n$db\n$user\n$pw\n$def\n$https\n";
  my $pad = "Y" x length $string;
  my $crypt = $string ^ $pad;
	open(FOUT,">winupload.dat");
	binmode(FOUT);
	print FOUT $crypt;
	close(FOUT);
	print "configuration file winupload.dat saved\n";
	exit;
}


