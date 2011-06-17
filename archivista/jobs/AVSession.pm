
package AVSession;

use strict;
use lib qw(/home/cvs/archivista/jobs);
use AVDocs;
use Net::Ping;
use Wrapper;

my $count;

use Digest::MD5 qw(md5_hex);

sub cookie {wrap(@_)} # cookie = cookie string
sub host {wrap(@_)} # host = host for user connection
sub db {wrap(@_)} # db = database for user connection
sub user {wrap(@_)} # user = user name for user connection
sub pw {wrap(@_)} # pw = password for user connection
sub vals {wrap(@_)} # vals = values for session information
sub ses {wrap(@_)} # ses = session object (AVDocs)
sub av {wrap(@_)} # av = user object (AVDocs)
sub message {wrap(@_)} # message = Error Message for the Login Form
sub sid {wrap(@_)} # session id
sub cgivals {wrap(@_)} # store parameters
sub header {wrap(@_)} # store header with cookies
sub logging {wrap(@_)} # if it is set <>0, then we got log messages

use constant SID => 'sid'; # Cookie Names
use constant EXIT_PARAM => 'go_exit.x'; # exit button






=head1 new()

1. Checks for a cookie 
2. Set a cookie if it is not defined
3. Checks for a entry in the sessions table
4. Loads the values from the session table
5. Checks if we need to update connection infos

=cut

sub new {
  my $class = shift;
  my $table = shift;
  my $self = {};
	bless $self,$class;
  $self->sid($table);
  $self->cookie($self->getCookie($self->sid)); # get back cookies
	$self->logging(0); # set logs (0/1)
	$self->DataRequest(); # store cgi vars in cgivals
  # Check if we are exiting the Programm.
  if ($self->param($self->EXIT_PARAM)) {
    $self->ses(AVDocs->new()); # open the archivista session handler
    $self->close();
    $self->cookie("");
  }
  my $print .= "Content-type: text/html\n"; # set the cookie
  if (!$self->cookie) { # we don't have a cookie, so create one
    my $session = md5_hex(localtime().$count++); # $count++=unique id
		$self->cookie($session);
	  $print .= "Set-Cookie: ".$self->sid."=".$self->cookie."; path=/;\n";
  }
  $print .= "\n";
	$self->header($print);

  if ($self->param($self->EXIT_PARAM)>0) {
    $self->cookie("");
  } else {
    $self->getCookie($self->sid); # get it back (setting is ok)
    if ($self->cookie) {
      $self->ses(AVDocs->new()); # open archivista session handler
      if ($self->ses->isArchivistaMain) {
        # get back the values for the session (or create empty values)
        my $pf=[$self->ses->FLD_SESSIONID,$self->ses->FLD_SESSIONHOST,
                $self->ses->FLD_SESSIONDB,$self->ses->FLD_SESSIONUSER,
                $self->ses->FLD_SESSIONPW,$self->ses->FLD_SESSIONVALS];
        my @rec=$self->ses->select($pf,$self->ses->FLD_SESSIONID,
                                  $self->cookie,$self->ses->TABLE_SESSIONS);
        if ($rec[0] ne $self->cookie) {
          $self->ses->add($self->ses->FLD_SESSIONID,$self->cookie,
                         $self->ses->TABLE_SESSIONS);
          @rec = $self->ses->select($pf,$self->ses->FLD_SESSIONID,$self->cookie);
        }
        if ($rec[0] eq $self->cookie) { # session entry ok, so load values
          $self->host($rec[1]);
          $self->db($rec[2]);
          $self->user($rec[3]);
          $self->pw($rec[4]);
          $self->vals($rec[5]); # get current vals
        } else {
          $self->cookie(""); # error storing/retrieving cookie
          $self->ses->close();
          $self->ses(''); # close session object
        }
      }
    }
    $self->updateLogin($table); # check if login was already done
  }
	return $self;
}






=head1 param($key)

Give back a value of a cgi field

=cut

sub param {
  my $self = shift;
	my $key = shift;
	return ${$self->cgivals()}{$key};
}






=head1 param_set($key,$value)

Set a value of a cgi field

=cut

sub param_set {
  my ($self,$key,$value) = @_;
	${$self->cgivals()}{$key} = $value;
}






=head1 $av=updateLogin 

Check if we got user information (host,db,user,pw), if yes, update
user information in db and open the av (user object) session

=cut

sub updateLogin {
  my $self = shift;
  my ($table) = @_;
  if (
      ($self->param('host') ne "" &&
       $self->param('db') ne "" &&
       $self->param('user') ne ""
      )
      ||
      (
       $self->host ne "" &&
       $self->db ne "" &&
       $self->user ne ""
      )
     ) {
    my $host=$self->param('host')?$self->param('host'):$self->host;
    my $db=$self->param('db')?$self->param('db'):$self->db;
    my $user=$self->param('user')?$self->param('user'):$self->user;
    my $pw=$self->param('pw')?$self->param('pw'):$self->pw;
    my $vals=$self->param('vals')?$self->param('vals'):$self->vals;
    if ($self->cookie) {
      my $pf=[$self->ses->FLD_SESSIONHOST,$self->ses->FLD_SESSIONDB,
              $self->ses->FLD_SESSIONUSER,$self->ses->FLD_SESSIONPW,
              $self->ses->FLD_SESSIONVALS];
      if ($self->ses->update($pf,[$host,$db,$user,$pw,$vals],
                            $self->ses->FLD_SESSIONID,
                            $self->cookie,$self->ses->TABLE_SESSIONS)) {
				if ($user ne "") {
          unless($self->av) {
            $self->av(AVDocs->new($host,$db,$user,$pw));
          }
          if ($self->av->isArchivistaDB) {
				    $self->av->setTable($table) if $table ne "";
            $self->host($host);
            $self->db($db);
            $self->user($user);
            $self->pw($pw);
            $self->vals($vals);
          } else {
            $self->av->close();
            $self->av('');
          }
				}
      }
    }
  }
}






=head1 close 

Close the whole session (incl. db handlers)

=cut

sub close {
  my $self = shift;
  $self->ses->delete($self->ses->FLD_SESSIONID,
                    $self->cookie,
                    $self->ses->TABLE_SESSIONS);

  $self->closeHandler();
  $self->cookie('') if $self->cookie;
}




=head1 closeHandler

Close the db connections

=cut

sub closeHandler {
  my $self = shift;
  if($self->av) {
    $self->av->close();
    $self->av('');
  }
  if ($self->ses) {
    $self->ses->close() if $self->ses;
    $self->ses('');
  }
}






=head1 DataRequest()
  
Retrieve all POST/GET key=value pairs

=cut

sub DataRequest {
  my $self = shift;
  my $request_method = $ENV{'REQUEST_METHOD'};
  my ($form_input,@pairs,$key,$value,%request,$pairs,$multipart);
  if ($ENV{'REQUEST_METHOD'} eq "GET") {
    $form_input = "$ENV{'QUERY_STRING'}";
  } else {
	  $multipart = DataRequestMultipart(\%request);
    read STDIN, $form_input, $ENV{'CONTENT_LENGTH'} if $multipart==0;
	}
	if ($multipart==0) {
    @pairs = split /&/, "$form_input";
    foreach $pairs (@pairs) {
      ($key,$value) = split /=/, $pairs;
      $key =~ tr/+/ /; 
      $key =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex($1))/eg;
      $value =~ tr/+/ /; 
      $value =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex($1))/eg;
      if (exists $request{$key}) {
        $request{$key} .= ",$value";
      } else {
        $request{$key} = $value;
      }
    }
	}
  if ($self->logging) {
	  foreach my $key (keys %request) {
	    print STDERR "$key => $request{$key}"."----------------------\n";
	  }
	}
	$self->cgivals(\%request);
}






=head1 $multipart=DataRequestMultipart(\%request)
  
Check if we have a multipart POST request and if so store values

=cut

sub DataRequestMultipart {
  my $self = shift;
  my $prequest = shift;
  my $len  = $ENV {'CONTENT_LENGTH'}; # length of the content (not used)    
  my $cttype = $ENV {'CONTENT_TYPE'}; # get back content type
	my $multipart = 0; # no multi part
  if ($cttype =~ /multipart\/form-data/) { # check for form-data (multipart)
	  $multipart = 1;
	  my (@blocks,$boundary,$index,$last);
	  my $crlf = "\r\n"; # separator in blocks (headers and bodies)
	  ($boundary) = $ENV {'CONTENT_TYPE'} =~ /boundary=\"?([^\";,]+)\"?/;
		my $boundary_last = "$boundary--$crlf"; # last one has two -- more
		$boundary .= $crlf; # after a boundary we always find a crlf
		my $boundary_length = length($boundary); # length of the boundary
		my $pos = -1; # starting point is that we did not find anything
		my $start = $boundary_length; # we don't want a match a the beginning
    my $max = (128 * 1024 * 1024)+2048; # max. size of block we get (128 MByte)
	  my $input_length = read(STDIN,$$prequest{post},$max); # read the block
		if ($input_length>0) { # we got content
		  # somethimes we have some chars before a boundary amd also crlf after it
		  my $relativ = index($$prequest{post},$boundary)+length($crlf); 
		  while ($index>=0) { # as long as there ar blocks
			  $index = index($$prequest{post},$boundary,$start); # next position
				my $till = $index; 
				$till = index($$prequest{post},$boundary_last) if $index<0; # last?
				if ($till>0) { # we got a new block
	        $pos++; # adjust position 
		      $blocks[$pos]{start} = $start; # start position 
		      $blocks[$pos]{length} = $till-$start-$relativ; # length of block
					DataRequestMultipartBlock($prequest,$pos,\@blocks,$crlf);
				}
		    $start=$index+$boundary_length; # adjust starting pos for next block
		  }
		}
	}
	return $multipart; # (0=no multipart, 1=multipart)
}






=head1 DataRequestMultipartBlock($preq,$pos,$pin,$pbl,$crlf)
  
Save a block in the final plaes (request), if file (fileval/filename)

=cut

sub DataRequestMultipartBlock {
  my $self = shift;
  my ($preq,$pos,$pbl,$crlf) = @_;
	my $header_start = $$pbl[$pos]{start};
	my $header_sep = "$crlf$crlf";
	my $total_length = $$pbl[$pos]{length};
	my $header_end = index($$preq{post},$header_sep,$header_start);
	if ($header_end > 0) {
	  my $header = substr($$preq{post},$header_start,$header_end-$header_start);
    my @parts = split($crlf,$header);
		my $vals = $parts[0];
		$vals =~ s/(Content-Disposition:\sform-data;\s)(.*)$/$2/; 
		my @vals = split("; ",$vals);
		my %headervals;
		foreach (@vals) {
		  my $line = $_;
			my ($name,$val) = split("=",$line);
			$val =~ s/^(\")(.*?)(\")$/$2/;
			$headervals{$name} = $val;
		}
		my $body_start = $header_end + length($header_sep);
		my $body_length = $total_length - length($header) - length($header_sep);
		if (exists($headervals{filename})) {
      $$preq{filename} = $headervals{filename};		  
			$$preq{filestart} = $body_start;
			$$preq{filelength} = $body_length;
		} else {
      $$preq{$headervals{name}} = substr($$preq{post},$body_start,$body_length);
		}
	}
}






=head1 getCookie($key)

Parse the COOKIE ENV variable and return the value of the cookie

=cut

sub getCookie {
  my $self = shift;
  my $get_key = shift;
  if (defined $ENV{'HTTP_COOKIE'}) {
    my @key_value_pairs = split /;\s/, $ENV{'HTTP_COOKIE'};
    foreach (@key_value_pairs) {
      my ($key,$value) = split /=/, $_;
      return $value if ($key eq $get_key);
    }
  } else {
    return 0;
  }
}






=head2 checkParam($var,$def,\@checkvals) 

Check if a given var has some values, if not, set it to default value

=cut

sub checkParam {
  my ($self,$var,$def,$pvals) = @_;
	my $found=0;
	foreach (@$pvals) {
	  $found=1 if $self->param($var) eq $_;
	}
	$self->param_set($var,$def) if $found==0;
}






=head2 checkIP($name,$cidr)

Check if given ip octets name_ip_oct_0..3 are a valid ip or ip/cidr address

=cut

sub checkIP {
  my ($self,$name,$cidr) = @_;
	my @ip = (0..3);
	my $ok = 1;
	foreach (@ip) { # get octets from web form
    $ip[$_] = $self->param("$name$_");
		$ok = 0 if $ip[$_]<0 || $ip[$_]>255;
	}
	my $ip = join(".",@ip); # compose a single ip address
  my $ipcheck = ((`/sbin/ifconfig eth0`)[1] =~ /inet addr:(\S+)/);
	if ($ipcheck ne "") {
	  my $ping = Net::Ping->new(); # check the ip address
	  my $res=$ping->ping($ip);
	  $ok = 0 if $cidr ne "" && $res!=0; # error, we got ip, not allowed (ip/cups)
	  $ok = 0 if $cidr eq "" && $res==0; # error, no ip, must be there (gw/ns)
	}
	if ($ok==1 && $cidr ne "") {
		$ok=0 if $cidr<0 && $cidr>32; # wrong cidr notation
	}
  foreach my $restrictedip ("^0\..*","^127\..*","^255(\.255){3}") {
		if ($ip =~ /$restrictedip/) { # 0.0.0.0/8 127.0.0.0/8 255.255.255.255
		  $ok=0;
		}
	}
	$ip .= "/$cidr" if $cidr ne ""; # check for cidr
	$ip = "" if $ok==0; # if there was an error, reset ip to ''
	$self->message('ERR_IP_FORBIDDEN') if $ok==0 && $self->message eq '';
  return $ip;
}






sub DESTROY {
  my $self = shift;
  $self->closeHandler();
}






1;


