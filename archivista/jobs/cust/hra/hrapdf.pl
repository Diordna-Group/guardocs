#!/usr/bin/perl

# hrapdf -> create pdf out of a database 
# (c) 2008 by Archivista GmbH, Urs Pfister

use strict;
use LWP::UserAgent; # we work with UserAgent (our batch web browser)
use HTTP::Cookies; # we need to work with cookies

my $host = shift;
my $db = shift;
my $user = shift;
my $pwd = shift;
my $from = shift;
my $to = shift;
my $ip = shift;
my $pfad = shift;
my $https = shift;

my $conf = 'hrapdf.conf';
my $log = 'hrapdf.log';

print "Programm ArchivistaBOX -> HRAPDF (c) 2010 v1.0 Archivista GmbH\n\n";
saveConfFile($conf,$host,$db,$user,$pwd,$from,$to,$ip,$pfad,$https,$log);
if ($from eq "" || $to eq "") {
  ($host,$db,$user,$pwd,$from,$to,$ip,$pfad,$https) = readConfFile($conf,$log);
	if ($host eq "" || $db eq "" || $user eq "") {
	  logit($log,"Bitte Programm konfigurieren, dazu Parameter übergeben:");
		logit($log,"$0 host db user pwd from to ip pfad https");
		exit;
	}
	print "Konfigurationsdatei $conf wurde gelesen:\n";
	print "IP:$ip - Host:$host - Datenbank:$host - User:$user\n";
	print "Ausgabepfad:$pfad, Verschlüsselung:$https\n\n";
	print "Bitte Startposition eingeben (Enter-Taste für $from):";
	my $from1 = <>;
	$from1 = int $from1;
	$from=$from1 if $from1>0;
	print "Bitte Endposition eingeben (Enter-Taste für $to):";
	my $to1 = <>;
	$to1 = int $to1;
	$to=$to1 if $to1>0;
	print "Verarbeitung mit Bereich $from bis $to starten (Abbruch Taste 'a'):";
	my $choose = <>;
	chomp $choose;
	exit if lc($choose) eq "a";
}

# server we use (link to webclient)
my $mode = "http";
$mode .= "s" if $https==1;
my $server = "$mode://$ip/perl/avclient/index.pl"; 
# connection string (host,db,user,password)
my $connect = "?host=$host&db=$db&uid=$user&pwd=$pwd";
my $login = "$server$connect";
my $flds = "&frm_Laufnummer=1&frm_Titel=1"; # faster connect
$pfad = "/home/data/archivista/tmp" if $pfad eq "";
my $www = LWP::UserAgent->new; # new www session 
# save the cookie for the corrent session
logit($log,"try to connect $ip - $host - $db - $user");
$www->cookie_jar(HTTP::Cookies->new('file'=>'/tmp/cookies.lwp','autosave'=>1));
logit($log,"get a cookie");
my $res = $www->get("$login$flds"); # connect to webclient 
logit($log,"got an answer");
if ($res->is_success) {
  logit($log,"connected");
  if ($res->content) { # we got login
	  my $from1 = $from;
		my $lastgood = 0;
    while ($from1>0 && $from1<=$to) {
	    ($from1,$lastgood) = processNextDocument($login,$flds,$www,
			                               $res,$from1,$to,$pfad,$log);
		}
		if ($lastgood>0) {
		  my $from2 = $lastgood+1;
		  $from2 = $to if $from2>$to ;
      saveConfFile($conf,$host,$db,$user,$pwd,$from2,$to,$ip,$pfad,$https,$log);
		}
	}
} else {
  logit($log,"no connection");
}




sub processNextDocument {
  my ($login,$flds,$www,$res,$from,$to,$outpfad,$log) = @_;
  my @docs = ();
  my @titles = ();
	my @files = ();
  selectNextDocument($login,$flds,$www,$res,$from,$to,\@docs,\@titles,$log);
	my $clast = checkSpecialCases($login,$flds,$www,$res,\@docs,\@titles,$log);
	my $doclist = "";
	for (my $c=0;$c<=$clast;$c++) {
	  $doclist .= "," if $doclist ne "";
		$doclist .= $docs[$c];
		if ($titles[$c] ne "") {
	    logit($log,"$docs[$c]--$titles[$c]");
		  my $cmd = "&go_pdf";
		  getPDFDocument($login,$flds,$www,$res,$docs[$c],
		                 $titles[$c].".pdf",$outpfad,$cmd,$log);
		}
	}
	if ($doclist ne $docs[0]) {
		if ($titles[0] ne "") {
	    logit($log,"combined pdf $doclist");
	    my $pdfname = $titles[0].".pdf";
	    my $cmd = "&go_pdfs&pdfdocs=$doclist&pdfname=$pdfname";
		  getPDFDocument($login,$flds,$www,$res,$docs[0],$pdfname,$outpfad,$cmd,$log);
		}
	}
	my $lastgood = $docs[$clast];
	$clast++;
	my $from2 = $docs[$clast];
	return ($from2,$lastgood);
}



sub getPDFDocument {
  my ($login,$flds,$www,$res,$docnr,$fname,$outpfad,$cmd1,$log) = @_;
	$fname = "$outpfad/$fname";
  my $cmd = "&go_query&fld_Laufnummer=$docnr";
  $res = $www->get("$login$flds$cmd");
	if ($res->is_success) {
    $res = $www->get("$login$flds$cmd1");
		if ($res->is_success) {
			unlink $fname if -e $fname;
			if (!-e $fname) {
			  my $pdf = $res->content;
			  open(FOUT,">$fname");
				binmode(FOUT);
				print FOUT $pdf;
				close(FOUT);
				logit($log,"wrote $fname to disk");
			} else {
			  logit("$fname already does exist");
			}
		}
	}
}



sub checkSpecialCases {
  my ($login,$flds,$www,$res,$pdocs,$ptitles,$log) = @_;
	my $from1 = $$pdocs[0];
	my $to1 = $$pdocs[0];
	my $basenr = $$ptitles[0];
  my $c=0;
	my $clast = 0;
  foreach (@$pdocs) {
	  my $nextnr = $$ptitles[$c];
		my $docnr = $$pdocs[$c];
		next if $nextnr eq "";
		if ($nextnr eq "PERSONEN" || $nextnr eq "STATUTEN") {
		  logit($log,"special case at $docnr with base $basenr");
      my $cmd1 = "&go_query&fld_Laufnummer=$docnr";
      $res = $www->get("$login$flds$cmd1");
	    if ($res->is_success) {
			  my $plus = "STA";
				$plus = "PER" if $nextnr eq "PERSONEN";
				$cmd1 = "&go_update&fld_Titel=$basenr$plus";
				$$ptitles[$c] = "$basenr$plus";
        $res = $www->get("$login$flds$cmd1");
	      if ($res->is_success) {
          $cmd1 = "&go_action&action=deletepage&docpage=1";
          $res = $www->get("$login$flds$cmd1");
	        if ($res->is_success) {
				    logit($log,"remove page 1 from $basenr$plus");
					}
			  }
			}
		} else {
		  # not special case PERSONEN/STATUTEN, check for current basenr
		  if (index($nextnr,$basenr)!=0) {
			  # it is not current basenr, so go to next document
				last;
			}
		}
		$clast = $c;
		$c++;
	}
	return $clast;
}



sub selectNextDocument {
  my ($login,$flds,$www,$res,$from,$to,$pdocs,$ptitles,$log) = @_;
  my $cmd1 = "&go_query&fld_Laufnummer=$from-$to";
  $res = $www->get("$login$flds$cmd1");
	if ($res->is_success) {
    $cmd1 = "&go_order_asc&orderfield=Laufnummer";
    $res = $www->get("$login$flds$cmd1");
		if ($res->is_success) {
	    logit($log,"query for documents from $from to $to");
		  my $html = $res->content;
		  for (my $doc=1;$doc<16;$doc++) {
		    $html =~ /(Laufnummer_$doc\" value=\")([0-9]+)/;
		    if ($1 eq "Laufnummer_$doc\" value=\"" && $2 >0) {
			    push @$pdocs,$2;
		      $html =~ /(Titel_$doc\" value=\")(.*?)(\")/;
		      if ($1 eq "Titel_$doc\" value=\"" && $2 ne "") {
				    push @$ptitles,$2;
				  } else {
				    push @$ptitles,"";
				  }
			  } else {
			    last;
			  }
		  }
		}
	}
}



sub saveConfFile {
  my ($conf,$host,$db,$user,$pwd,$from,$to,$server,$pfad,$https,$log) = @_;
  if ($host ne "" && $pfad ne "") {
    open(FOUT,">$conf");
	  print FOUT "$host\n";
	  print FOUT "$db\n";
	  print FOUT "$user\n";
	  print FOUT "$pwd\n";
	  print FOUT "$from\n";
	  print FOUT "$to\n";
	  print FOUT "$server\n";
	  print FOUT "$pfad\n";
    close(FOUT);
		logit($log,"configuration file $conf created!");
		exit;
	}
}



sub readConfFile {
  my ($conf,$log) = @_;
  open(FIN,$conf);
  my @lines = <FIN>;
  my $host = readConfFileLine($lines[0]);
  my $db = readConfFileLine($lines[1]);
  my $user = readConfFileLine($lines[2]);
  my $pwd = readConfFileLine($lines[3]);
  my $from = readConfFileLine($lines[4]);
  my $to = readConfFileLine($lines[5]);
  my $server = readConfFileLine($lines[6]);
  my $pfad = readConfFileLine($lines[7]);
  my $https = readConfFileLine($lines[8]);
	logit($log,"configuration file $conf loaded");
  return ($host,$db,$user,$pwd,$from,$to,$server,$pfad,$https);
}



sub readConfFileLine {
  my ($line) = @_;
	chomp $line;
	return $line;
}



sub logit {
  my ($log,$message) = @_;
	my $stamp = TimeStamp();
	print "$message\n";
	open(FOUT,">>$log");
	print FOUT "$stamp => $message\n";
	close(FOUT);
}



sub TimeStamp {
  my @t = localtime( time() );
  my ( $stamp, $y, $m, $d, $h, $mi, $s );
  $y     = $t[5] + 1900;
  $m     = $t[4] + 1;
  $m     = sprintf( "%02d", $m );
  $d     = sprintf( "%02d", $t[3] );
  $h     = sprintf( "%02d", $t[2] );
  $mi    = sprintf( "%02d", $t[1] );
  $s     = sprintf( "%02d", $t[0] );
  $stamp = $y . $m . $d . $h . $mi . $s;
  return $stamp;
}


	
