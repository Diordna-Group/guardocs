#!/usr/bin/perl

# upload.pl -> demo script for uploading a document via web client 
# (c) 2008 by Archivista GmbH, Urs Pfister

use strict;
use LWP::UserAgent; # we work with UserAgent (our batch web browser)
use HTTP::Cookies; # we need to work with cookies

# server we use (link to webclient)
my $server = "http://localhost/perl/avclient/index.pl"; 
# connection string (host,db,user,password)
my $connect = "?host=localhost&db=archivista&uid=Admin&pwd=archivista";
my $frm_mode = "&frm_Laufnummer=1"; # faster connect (give back only form mode)

my $www = LWP::UserAgent->new; # new www session 
# save the cookie for the corrent session
print "try to connect $server$connect$frm_mode\n";
$www->cookie_jar(HTTP::Cookies->new('file'=>'/tmp/cookies.lwp','autosave'=>1));
print "get a cookie\n";
my $res = $www->get("$server$connect"); # connect to webclient 
print "got an answer\n";
if ($res->is_success) {
  print "connected\n";
  if ($res->content) { # we got login
	  my $cmd1 = "?go_query&fld_Seiten=1&frm_Laufnummer=1";
	  # now upload a file, we use request method with POST
    my $res = $www->get("$server$cmd1");
		if ($res->is_success) { # if we got a succes, file is uploaded
		  print "query ok\n";
			my $html = $res->content;
			$html =~ /(Laufnummer_1\" value=\")([0-9]+)/;
			if ($1 eq "Laufnummer_1\" value=\"" && $2 >0) {
			  my $doc = $2;
			  print "found doc $doc, now getting pdf\n";
	      my $cmd1 = "?go_pdf";
	      # now upload a file, we use request method with POST
        my $res = $www->get("$server$cmd1");
			  if ($res->is_success) {
			    print "pdf ok\n";
			  }
				my $fname = "$doc.pdf";
				if (!-e $fname) {
				  my $pdf = $res->content;
				  open(FOUT,">$fname");
					binmode(FOUT);
					print FOUT $pdf;
					close(FOUT);
					print "wrote $fname to disk\n";
				} else {
				  print "$fname already does exist\n";
				}
			} else {
			  print "no document found\n";
			}
		}
	}
} else {
  print "no connection\n";
}



	
