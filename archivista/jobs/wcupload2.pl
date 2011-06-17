#!/usr/bin/perl

# upload.pl -> demo script for uploading a document via web client 
# (c) 2008 by Archivista GmbH, Urs Pfister

use strict;
use LWP::UserAgent; # we work with UserAgent (our batch web browser)
use HTTP::Cookies; # we need to work with cookies
use HTTP::Request::Common qw(POST); # the post method must be imported

my $fin = "/home/archivista/documentation_de.pdf"; # demo doc (our manual)
my $pages = "1"; # pages to extract (so we don't wait too long)
my $fout = "/tmp/eins.pdf"; # the finally file we want to import
if (!-e $fout) { # create file with pdftk if it does not already exist
  system("pdftk $fin cat $pages output $fout");
}

# server we use (link to webclient)
my $server = "http://localhost/perl/avclient/index.pl"; 
# connection string (host,db,user,password)
my $connect = "?host=localhost&db=archivista&uid=Admin&pwd=archivista";
my $frm_mode = "&frm_Laufnummer=1"; # faster connect (give back only form mode)

my $www = LWP::UserAgent->new; # new www session 
# save the cookie for the corrent session
$www->cookie_jar(HTTP::Cookies->new('file'=>'/tmp/cookies.lwp','autosave'=>1));
my $res = $www->get("$server$connect$frm_mode"); # connect to webclient 
if ($res->is_success) {
  if ($res->content) { # we got login
	  # now upload a file, we use request method with POST
    my $res = $www->request(POST "$server",
		  Content_Type => 'form-data', # multipart/form-data
			Content => [ # structure for our file
			  MAX_FILE_SIZE => 134217728, # max. size (WebClient won't accept more)
				upload => [ $fout, $fout ], # file to upload, file name to use 
				go => 'go_action', # we need to call the go_action command
				action => 'upload', # inside of go_action we need to use upload
				uploaddef => 1, # desired scan definition (0,1,2...)
				meta => "Titel:450", # filling in  keys is no problem
			]
		);
		if ($res->is_success) { # if we got a succes, file is uploaded
		  print "file $fout uploaded\n";
		}
	}
}



	
