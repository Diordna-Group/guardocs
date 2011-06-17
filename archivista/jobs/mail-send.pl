#!/usr/bin/perl

# Requries Perl Mail::IMAPClient
# For the currently shipping Archivista Box ISO, some
# more dependencies have to be added, all in all:
# Perl Mail-IMAPClient 3.* does not yet handle an supplied socket
# e.g. for SSL correctly.
# Until a significantly fixed IMAPClient 3.x is released, the
# IMAPClient 2.* is requires for proper IMAP + SSL handling.

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
use fields; 

use constant TYPE_IMG => 'img'; # we check for an image
use constant TYPE_PDF => 'pdf'; # we check for an pdf file
use constant CHECK_PDF => 'pdfinfo '; # check for pdf file 
use constant CHECK_IMG => 'identify -ping '; # check for image 
use constant OK => 0; # sucess after file check (from system)

my $db0 = shift;
my $nr = shift;

my $dbh=MySQLOpen(); # connect to a database
if ($dbh) {
  logit("connection for mail archiving ok");
  if (HostIsSlave($dbh)==0) { # we are not in slave mode
    logit("host is in master mode");
    # first, we need all Archivista databases
    my $pdb = getValidDatabases($dbh); # check all databases
    foreach my $db1 (@$pdb) {
		  if ($db0 eq $db1) {
		    my $sql = "use $db1";
			  $dbh->do($sql);
		    logit("checking database $db1");
			  restoreMail($dbh,$db1,$nr); # restore a mail
		  }
		}
	}
}






=head1 fetchMails($dbh,$db1,$line)

Fetch a mail and send it to ftp folder

=cut

sub restoreMail {
  my ($dbh,$db,$nr) = @_;

  my @docs;
	my ($nr1,$nr2) = split("-",$nr);
	if ($nr1 ne $nr) {
	  if ($nr1>0 && $nr2>0 && $nr1<$nr2) {
		  for (my $c=$nr1;$c<=$nr2;$c++) {
		     push @docs,$c;	
			}
		}
	} else {
	  @docs = split(",",$nr);
	}
	foreach my $docnr (@docs) {
	  my $sql = "select EDVName from archiv where Laufnummer=$docnr";
	  my @row = $dbh->selectrow_array($sql);
	  my ($type1,$name1,$restore1) = split(";",$row[0]);
	  if ($type1 ne "mail") {
	    logit("Document $nr in $db is not a mail...");
	    return;
	  }
    my $val = "MailArchiving";
    my $val01 = $val."01";
    # get all mail entries from one database
    my $line = getParameterReadWithType($dbh,$db,$val01,$val);
    if ($line ne "") {
	    logit("checking mail accounts from database $db");
		  my @lines = split(/\r\n/,$line);
		  my $pos = 0;
		  my $c = 0;
		  foreach my $line2 (@lines) { # check every mailbox in a database
		    my @elements = split(";",$line2);
			  if ($elements[0] eq $name1) {
			    $pos=$c;
				  last;
			  }
			  $c++;
		  }
		  my $line2 = $lines[$pos];
		  if ($line2 ne "") {
	      my ($name,$server,$port,$user,$passwd,$ssl,$mailbox1,
	          $from,$cc,$to,$subject,$owner,$age,$delete,
			      $move,$restore,$scandef,$noattach,$inactive) = split(";",$line2);
	      if ($inactive==1) {
	        logit("mail archiving definition $name IS INACTIVE..............");
		      next;
	      }
				$restore1 = $restore if $restore1 eq ""; # no restore folder in table?
				my @mailboxes = split(",",$mailbox1);
				my $mailbox = $mailboxes[0];
				$restore1 = $mailbox if $restore1 eq ""; # no restore folder in def?
        my $maildir = "/tmp";
        my $socket = 0;
        if ($ssl==1) {
          logit("opening SSL socket ...");
          $socket = IO::Socket::SSL->new(PeerAddr => $server,
					          PeerPort => $port) or die "SSL socket(): $@";
        } else {
          logit("opening INET socket ...$server-$port");
          $socket = IO::Socket::INET->new(PeerAddr => $server,
					          PeerPort => $port) or die "INET socket(): $@";
        }
        my $greeting = <$socket>;
        my ($id, $answer) = split /\s+/, $greeting;
        die "problems logging in: $greeting" if $answer ne 'OK';
        logit("greeting OK: $greeting");
        # Build up the client attached to the socket and login
        my $client = 0;
				my $passwd1 = pack("H*",$passwd);
        $client = Mail::IMAPClient->new(User => $user,Password => $passwd1,
	    	  		    Socket => $socket) or die "IMAP new(): $@";
        $client->State(Mail::IMAPClient::Connected());
        $client->login() or die 'login(): ' . $client->LastError();
				my $sql = "select Seiten,Archiviert,Ordner from archiv ".
				          "where Laufnummer=$docnr";
				my ($seiten,$archiviert,$folder) = $dbh->selectrow_array($sql);
				if ($seiten>0) {
          my $nr1 = ($docnr*1000)+1;
				  my $prow = getBlobFile($dbh,"BildA",$nr1,$folder,$archiviert);
					if ($$prow ne "") {
	          my ($fh, $filename)  = tempfile("$maildir/eml-XXXX");
		        logit("mail from $db at $nr restored under $filename");
		        binmode($fh);
		        print $fh $$prow;
		        close($fh);
		        my ($fh2, $filename2)  = tempfile("$maildir/eml-XXXX");
		        close($fh2);
		        my $cmd = "unzip -p $filename >$filename2";
		        logit($cmd);
		        my $res=system($cmd);
		        logit("mail restored under $filename2, state:$res");
		        my $content;
		        readFile($filename2,\$content);
		        unlink $filename if -e $filename;
		        unlink $filename2 if -e $filename2;
		        my $uid = $client->append($restore1,$content);
		        logit("mail restored under $uid");
					}
		    }
        $client->logout();
			}
		}
	}
	logit("end of program...");
}







