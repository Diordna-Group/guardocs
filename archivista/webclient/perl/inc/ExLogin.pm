package inc::ExLogin;

BEGIN {
  use Exporter();
  use DynaLoader();
  @inc::ExLogin::ISA    = qw(Exporter DynaLoader);
  @inc::ExLogin::EXPORT = qw(exLogin);
}

use strict;
use Carp;
use Net::LDAP;
use LWP::UserAgent;
use HTTP::Request::Common;


use constant MODE_MYSQL => 0;
use constant MODE_LDAP => 1;
use constant MODE_HTTP => 2;
use constant LVL_SYSOP => 255;

# MODE_MYSQL => check only MySQL Connection.
# MODE_LDAP => if we have a MySQL Connection Error 
#               check also if there is a LDAP User and create it
# LVL_SYSOP => SYSOP Level


=head1 exLogin($host,$db,$uid,$pwd,$dbh,$id,$id_from)

Given the login parameters a client can test if he want's to login

=cut

sub exLogin {
  my $host = shift; # host to log in
  my $db = shift; # db to log in
  my $puid = shift; # pointer to user to log in with
  my $pwd = shift; # password to log in with
  my $dbh = shift; # session Handler
  my $id = shift; # $id: >0 if user logged in
  my $userok = 0; # no success
  if ($id==0) {
    # ID is 0 so we aren't loged in
    logit("Check external login");
    # Connection is Not OK
    my ($mode,$server,$port,$prg,$dom,$bdn,$lcuser) = getMode($dbh,$db);
		if ($lcuser == 1 ) {
		  # if User not SYSOP or Admin
		  unless ($$puid eq "SYSOP" || $$puid eq "Admin" ) {
				# Check if both are uppercase if not set everything to lowercase
			  my $tmp = uc($$puid);
				if ($$puid ne $tmp) {
				  # We have not uppercase so change it to lowercase
			    # Set UserName to Lowercase if the option is activated
			    $$puid = lc($$puid);
				}
			}
		}
    # Check if we're in LDAP Mode if so create the User from LDAP Infos
    if ($mode == MODE_LDAP) {
      $host = 'localhost' if $host eq '127.0.0.1';
      # LDAP is only possible on localhost
      if ($host eq "localhost" ) {
        # change to our user and to our password
        my $ldap = Net::LDAP->new($server,port=>$port);
        $userok = checkUserLDAP($ldap,$dom,$$puid,$pwd);
        if ($userok==1) {
				  logit('LDAP login ok');
          my ($pmysqlgroups,$pldapgroups,$gid,$mysqlok,@fields);
          $pmysqlgroups = getMySQLGroups($dbh,$db);
          $pldapgroups = getGroupsFromLDAP($ldap,$bdn,$$puid);
          $gid = getMySQLIDFromLDAP($dbh,$db,$$puid,$pldapgroups,$pmysqlgroups);
          my $infos = loadUserShape($dbh,$db,$host,$$puid,$gid);
					my $hfrom = $host;
          $infos->{'EMail'} = $dbh->quote(getMailFromLDAP($ldap,$bdn,$infos));
          $mysqlok = checkUserMySQL($dbh,$db,$$puid,$host);
          if ($mysqlok){
            # If the user exists we only change the group settings 
            # to be up to date
            changeGroupMySQL($dbh,$host,$db,$$puid,$pwd,$infos);
          } else {
            # No mysql user but LDAP-Login is ok so we have to create the user
            createUser($dbh,$host,$db,$$puid,$pwd,$infos);
          }
          # Allways change password because we don't know if it's right 
          changePasswordMySQL($dbh,$host,$$puid,$pwd);
        }
      }
    } elsif ($mode == MODE_HTTP) {
		  if ($$puid ne "Admin" && $$puid ne "SYSOP") {
			  my ($groups,$mail); 
        ($userok,$groups,$mail) = checkUserHTTP($server,$prg,$$puid,$pwd);
			  if ($userok==1) {
					logit('HTTP login ok');
					my ($gid,$grp,$host1) = checkUserHTTPGroup($dbh,$db,$groups);
					if ($gid>0) {
            my $infos = loadUserShape($dbh,$db,$host1,$$puid,$gid,$grp);
            $infos->{'EMail'} = $dbh->quote($mail);
            my $mysqlok = checkUserMySQL($dbh,$db,$$puid,$host1);
            if ($mysqlok) {
              # If the user exists we only change the group settings 
              # to be up to date
              changeGroupMySQL($dbh,$host1,$db,$$puid,$pwd,$infos);
            } else {
              # No mysql user but LDAP-Login is ok so we have to create the user
              createUser($dbh,$host1,$db,$$puid,$pwd,$infos);
            }
            # Allways change password because we don't know if it's right 
            changePasswordMySQL($dbh,$host1,$$puid,$pwd);
				  } else {
            $userok=0; # no group and not ALL, don't let him in
					}
				}
			} else {
			  $userok=1; # SYSOP or Admin
			}
    } else {
      $userok=1; # Mysql
    }
  }
  return $userok; 
}






=head ($gid,$groups,$host)=checkUserHTTPGroup($dbh,$db,$groups)

Find out which user profile we need to use

=cut

sub checkUserHTTPGroup {
  my $dbh = shift;
	my $db = shift;
	my $groups = shift;
  my $pmysqlgroups = getMySQLGroups($dbh,$db);
	my @groups = split(/,/,$groups);
	my $groupextern = $groups[0];
	$groupextern="ALL" if $groupextern eq "";
	my $groupintern="";
	my $host1 = "localhost";
  my $gid=0;
	my $grp=$groups; # groups after check in profiles
	foreach(@$pmysqlgroups) { # have a look in profiles
		my $line = $_;
		chomp $line;
		my ($ex,$in,$note,$off) = split(";",$_);
		if ($ex eq $groupextern && $off==0) {
			$groupintern=$in; # we have a profile (incl. test for host)
			last;
		}
	}
	if ($groupintern ne "") { # check internal user id
    $groupintern = $dbh->quote($groupintern);
    my $sql = "SELECT Laufnummer,Alias,Host from $db.user " .
              "where User=$groupintern";
    my @res = $dbh->selectrow_array($sql);
		if ($res[0]>0) {
	    $gid=$res[0];
		  $grp=$res[1] if $res[1] ne ""; # if there are groups in profile use them
			$host1=$res[2];
		}
	}
  return ($gid,$grp,$host1); # take groups from groups entry
}






=head1 ($userok,$groups,$mail)=checkUserHTTP($server,$prg,$uid,$pwd)

Check if the user does exist and give back status,first group,groups,mail

=cut

sub checkUserHTTP {
  my $server = shift;
	my $prg = shift;
	my $uid = shift;
	my $pwd = shift;
  my $success = 0;
	my $groups = "";
	my $mail = "";
  my $where = $ENV{'REMOTE_ADDR'};
  my $ua = LWP::UserAgent->new;
	$ua->timeout(30);
  my $res = $ua->request(POST $server,[user=>$uid, pass=>$pwd, host=>$where]);
  if($res->is_success) {
    if ($res->content =~ /^1 /) {
		  my $users = `curl -s $prg | grep -i '$uid'`;
			chomp $users;
			my @fields = split(/\t/,$users);
			$groups = $fields[2];
			$mail = $fields[1];
		  $success=1;
		}
	} else {
	  my $errmsg = $res->status_line;
		logit("HTTP failure: $errmsg");

	}
	return ($success,$groups,$mail);
}






=head1 getMailFromLDAP

=cut

sub getMailFromLDAP {
  my $ldap = shift;
	my $bdn = shift;
	my $infos = shift;

  my ($filter,$res,$mail,$user);

	$user = $infos->{'User'};
	$user = unquote($user);
	$filter = "sAMAccountName=$user";

  $res = $ldap->search(base => $bdn, filter => $filter);
  foreach my $entry ($res->entries) {
    $mail = $entry->get_value('mail');
  }
	return $mail;
}





=head1 getMySQLIDFromLDAP

=cut

sub getMySQLIDFromLDAP {
  my $dbh = shift;
  my $db = shift;
  my $user = shift;
  my $pldapgroups = shift;
  my $pmysqlgroups = shift;

  my @ldapg = @$pldapgroups;
  my @mysqls = @$pmysqlgroups;

  my $group;

  foreach my $myset (reverse(@mysqls)) {
    my ($myldap ,$mygroup ,undef,undef) = split(';',$myset);

    foreach my $ldapgroup (@ldapg) {
      # have a look at LDAP Structure
      my @parts = split(',',$ldapgroup);
      $parts[0] =~ s/^CN=//g;
      # The Group in MySQL Matchs with the Group in LDAP
      $group = $mygroup if $parts[0] eq $myldap;
    }
  }
  $group = $dbh->quote($group);
  my $sql = "SELECT Laufnummer "
          . "from $db.user "
          . "where User=$group and Host='localhost'";
  my @res = $dbh->selectrow_array($sql);
  return $res[0];
}






=head1 $id=checkUserMySQL($dbh,$db,$uid,$host)

Check if a user does exist in the archivista user table

=cut

sub checkUserMySQL {
  my $dbh = shift;
  my $db = shift;
  my $uid = shift;
	my $host = shift;
  my $quser = $dbh->quote($uid);
	my $qhost = $dbh->quote($host);
  my $sql = "select Laufnummer from $db.user " .
            "where User=$quser and Host=$qhost";
  my @row = $dbh->selectrow_array($sql);
  return $row[0];
}
  






=head1 ($mode,$server,$port,$prg,$dom,$bdn,$lcuser)=getMode($dbh,$db)

Return the access parameters we are in (MYSQL, LDAP, HTTP)

=cut

sub getMode {
  my $dbh = shift;
  my $db = shift;
  my $sselect = 'Inhalt';
  my $sdb = "$db.parameter";
  my $scondition = "Art = 'UserExtern01'";
  my $sorder = 'order by Art';
  my $sql = "SELECT $sselect FROM $sdb WHERE $scondition $sorder";
  my ($mod,$serv,$port,$prg,$dom,$bdn,$lcuser,$defuser) = 
	    split(';',$dbh->selectrow_array($sql));
  $mod = MODE_MYSQL if ($mod != MODE_LDAP && $mod != MODE_HTTP);
  return ($mod,$serv,$port,$prg,$dom,$bdn,$lcuser);
}






=head1 checkUserLDAP($ldap_server,$ldap_port,$ldap_dom,$user,$pwd)

Try to login to the LDAP Server (-1=wrong pw,0=no user,1=user and pw ok)

=cut

sub checkUserLDAP {
  my $ldap= shift;
  my $ldapdom = shift;
  my $user = shift;
  my $pw = shift;
  my $res = 0; # no LDAP user
  my $code=49; # Set code to connection error.
  if($ldap) {
    # Connection to LDAP-Server ok!
    my $login = $ldap->bind("$user\@$ldapdom",password=>$pw);
    $code = $login->code();
  }
  $res=1 if $code==0;
  return $res;
}






=head1 changePassword($dbh,$host,$username,$password)

Change the password. The user can't login in MySQL but in the LDAP-Diercotry so the password has changed.

=cut

sub changePasswordMySQL {
  my $dbh = shift;
  my $host = shift;
  my $username = shift;
  my $password = shift;
  my $myuser = $dbh->quote($username).'@'.$dbh->quote($host);
  my $mypass = $dbh->quote($password);
  my $sql = "set password for $myuser=Password($mypass)";
  $dbh->do($sql);
}






=head1 changeGroupMySQL 

=cut

sub changeGroupMySQL {
  my $dbh = shift;
	my $host = shift;
  my $db = shift;
  my $username = shift;
  my $password = shift;
  my $infos = shift;

  my $sql = updateAvUserSQL($db,$infos);
	$dbh->do($sql);
	my $level = $infos->{'Level'};
	#createMySQLUser($dbh,$host,$db,$username,$password,$level);
	createMySQLUser($dbh,$host,$db,$username,$password,$level,'update');
}






=head1 createUser($dbh,$host,$db,$username,$password,$gid)

User can login in LDAP-Directory but not MySQL.
So we need to create user in MySQL.

=cut

sub createUser {
  my $dbh = shift;
  my $host = shift;
  my $db = shift;
  my $username = shift;
  my $password = shift;
  my $infos = shift;

  my $sql = createAvUserSQL($db,$infos);
  $dbh->do($sql);
  createMySQLUser($dbh,$host,$db,$username,$password,$infos->{'Level'});
}






=head1 \%infos = loadUserShape($dbh,$db,$host,$username,$usershape);

Load Data and save it into $pinfos;

=cut

sub loadUserShape {
  my $dbh = shift;
  my $db = shift;
  my $host = shift;
  my $username = shift;
  my $usershape = shift;
	my $groups = shift;
  my ($pinfos,@fields);
  my ($sselect,$suserid,$sql);

  @fields = qw(User Host Alias Anzahl Suchtreffer PWArt PWEncrypted Level 
               Masseinheit Korrektur ZugriffIntern ZugriffWeb AddOn AddNew 
               Workflow AVStart AVForm EMail Zusatz Bemerkungen);

  # Remove User and Host because it's diffrent in the shape
  my $fuser = shift(@fields);
  my $fhost = shift(@fields);

  $sselect = join(',',@fields);
  $suserid = $usershape;
  
  my $pgroups = getMySQLGroups($dbh,$db);
  $suserid = getDefaultUID($dbh,$db,$pgroups) if ($suserid == 0);

  $sql = "select $sselect from $db.user where Laufnummer=$suserid";
  $pinfos = $dbh->selectrow_hashref($sql);

  # Add User and Host to the sql string
  unshift(@fields,$fhost);
  $pinfos->{$fhost} = $host;
  unshift(@fields,$fuser);
  $pinfos->{$fuser} = $username;

  # Create Value List for join
  foreach my $field (@fields) {
	  if ($field eq "Alias" && $groups ne "") {
      $pinfos->{$field} = $dbh->quote($groups);
	  } elsif ($field eq "PWArt") {
      $pinfos->{$field} = $dbh->quote("1");
		} else {
      $pinfos->{$field} = $dbh->quote($pinfos->{$field});
		}
  }
  return $pinfos;
}






sub getDefaultUID {
  my $dbh = shift;
  my $db = shift;
  my $pgroup = shift;

  my $lastentry = $pgroup->[@$pgroup-1];
  my (undef,$username,undef,undef) = split(';',$lastentry);

  my $susername = $dbh->quote($username);
  my $sql = "SELECT Laufnummer from $db.user where User=$susername limit 1";
  my @id = $dbh->selectrow_array($sql);

  # Retrun first ID
  return $id[0];
}






=head1 createAvUserSQL($db,$infos)

Generate SQL-String with Field and Values given.

=cut

sub createAvUserSQL {
  my $db = shift;
  my $pinfos = shift;
  # SQL Variables
  my (@fields,@values);
  my ($sfields,$svalues,$sql);

  foreach my $key (keys %$pinfos) {
    push(@fields,$key);
    push(@values,$pinfos->{$key});
  }

  # Prepare for SQL-String
  $sfields = join(',',@fields);
  $svalues = join(',',@values);

  # Compose SQL for Archivista User and do it.
  $sql = "insert into $db.user($sfields) values($svalues)";
  return $sql;
}






=head1 updateAvUserSQL($db,$infos)

=cut

sub updateAvUserSQL {
  my $db = shift;
  my $pinfos = shift;

  my (@alter);

  foreach my $key (keys %$pinfos) {
    next if ( $key eq 'User' );
    my $alter = "$key = ".$pinfos->{$key};
    push(@alter,$alter);
  }

  my $salter = join(',',@alter);
  my $condition = "User=".$pinfos->{'User'};

  my $sql = "update $db.user set $salter where $condition";

  return $sql;
}






=head1 createMySQLUser($dbh,$host,$db,$username,$password,$level)

Create the MySQL User and grant all rights to the important tabels.

=cut

sub createMySQLUser {
  my $dbh = shift;
  my $host = shift;
  my $db = shift;
  my $username = shift;
  my $password = shift;
  my $level = shift;
	my $mode = shift;

  my ($user);
	$mode = 'create' if $mode ne 'update';

  my @tables = qw(user parameter workflow archiv abkuerzungen archivseiten
                  archivbilder feldlisten adressen adressenplz literatur
                  literaturrubrik notizen);
  
	# Remove ' at the beginning and the end
	$level = unquote($level);
  $level = 0 if (! defined $level);

  $user = $dbh->quote($username).'@'.$dbh->quote($host);

	if($mode eq 'update') {
    # Remove All Privileges from User in thes database
		my @revokes = (
		               "REVOKE ALL PRIVILEGES ON $db.* FROM $user",
	                 "REVOKE GRANT OPTION ON $db.* FROM $user",
				  				 "REVOKE ALL PRIVILEGES ON archivista.access FROM $user",
  			  				);
	  foreach my $sql (@revokes) {
  	   $dbh->do($sql);
		}
	}

  foreach my $table (@tables) {
    my $rights = getRights($level,$table);
    my $sql = "GRANT $rights ON $db.$table TO $user";
    $sql .= " WITH GRANT OPTION" if ($level == LVL_SYSOP);
    $dbh->do($sql);
  }

  fixSpezialTables($dbh,$db,$user);

  my $sql = "flush privileges";
  $dbh->do($sql);
}






=head1 getRights($level,$table)

Return the rights for the given level with the the table.

=cut

sub getRights {
  my $level = shift;
  my $table = shift;
  my $rights;

  $rights = "Select";
  if ($level == LVL_SYSOP) {
    $rights = "All";
  } elsif($level > 0) {
    if ( ! isInternTable($table) ) {
      $rights = "Select,Insert,Update,Delete";
    }
  }
  return $rights;
}






=head1 isInternTable($table)

Checks if it is an internal table. intTables = (parameter,workflow or user)

=cut

sub isInternTable {
  my $table = shift;
  my @intTables = qw(parameter workflow user);

  my $intern;
  $intern = 0;

  foreach my $intTable (@intTables) {
    if ($intTable eq $table) {
      $intern = 1;
    }
  }
  return $intern;
}






=head1 fixSpezialTables($dbh,$db,$user)

Update/Grant user rights for some spezial tables.

=cut

sub fixSpezialTables {
  my $dbh = shift;
  my $db = shift;
  my $user = shift;
  my $level = shift;

  my ($sql,$query,@querys);

  $sql = "GRANT Select,Insert,Update ON archivista.access TO $user";
  unshift(@querys,$sql);

  if ($level != LVL_SYSOP) {
    $sql = "GRANT Update(PWArt) ON $db.user TO $user";
    unshift(@querys,$sql);
  }

  foreach my $query (@querys) {
    $dbh->do($query) if ($query ne "");
  }
}






=head1 getGroupsFromLDAP

Returns all groups or subgroups wich the given user is in.

=cut

sub getGroupsFromLDAP {
  my $ldap = shift;
  my $bdn = shift;
  my $username = shift;
  my $filter = "sAMAccountName=$username";
  my @groups;
  my $pgroups = \@groups;

  getLDAPGroupsFromUser($ldap,$bdn,$filter,$pgroups);

  return $pgroups;
}






=head1 getLDAPGroupsFromUser

Returns Groups that the User is a member of.

=cut

sub getLDAPGroupsFromUser {
  my $ldap = shift;
  my $bdn = shift;
  my $filter = shift;
  my $pgroups = shift;

  my @array;
  my $pnewgroups=\@array;

  $filter = "(&($filter)(objectClass=user))";
  my $entries = getLDAPGroups($ldap,$bdn,$filter,$pnewgroups);

  if ($entries) {
    my $anz_groups = @$pnewgroups;
    my $start = $anz_groups-$entries-1;
    add_to_array($pgroups,$pnewgroups);
    while ($entries > 0) {
      $filter = (split(',',($pgroups->[$start])))[0];
      getLDAPGroupsFromGroup($ldap,$bdn,$filter,$pgroups);
      $entries--;
      $start++;
    }
  }
}






=head1 getLDAPGroupsFromGroup

Returns Groups of the given group is member of.

=cut

sub getLDAPGroupsFromGroup {
  my $ldap = shift;
  my $bdn = shift;
  my $filter = shift;
  my $pgroups = shift;

  my @array;
  my $pnewgroups = \@array;

  $filter = "(&($filter)(objectClass=group))";
  my $entries = getLDAPGroups($ldap,$bdn,$filter,$pnewgroups);

  if ($entries) {
    # We have a sub group
    # check sub group for subsubgroups
    # Save actuel Number of Groups
    my $anz_groups = @$pnewgroups;
    my $start = ($anz_groups-$entries)-1;
    add_to_array($pgroups,$pnewgroups);
    while($entries > 0) {
      # We only Take the First Element of the Group DN
      # DN have a look at LDAP and DN
      $filter = (split(',',($pgroups->[$start])))[0];
      getLDAPGroupsFromGroup($ldap,$bdn,$filter,$pgroups);
      $entries--;
      $start++;
    }
  }
}



=head1 getLDAPGroups

Return 'memberOf' with the given Filter.

=cut

sub getLDAPGroups {
  my $ldap = shift;
  my $bdn = shift;
  my $filter = shift;
  my $pgroups = shift;
  my $res;

  $res = $ldap->search(base => $bdn, filter => $filter);

  my $anz=0;

  if($res->entries) {
    foreach my $entry ($res->entries) {
      my @groups = $entry->get_value('memberOf');

      $anz=@groups;
      add_to_array($pgroups,\@groups);
    }
  }
  return $anz;
}






=head1 getMySQLGroups

=cut

sub getMySQLGroups {
  my $dbh = shift;
  my $db = shift;

  my $sselect = 'Inhalt';
  my $sdb = "$db.parameter";
  my $scondition = "Art = 'UserGroups01'";
  my $sorder = 'order by Art';
  my $sql = "SELECT $sselect FROM $sdb WHERE $scondition $sorder";

  my $inhalt = $dbh->selectrow_array($sql);
  my @shapes = split("\r\n",$inhalt);
  return \@shapes;
}






=head1 add_to_array

Add Second Array(Pointer) to the First Array(Pointer).

=cut

sub add_to_array {
  my $pfirst = shift;
  my $psecond = shift;
  foreach my $element (@$psecond) {
    $pfirst->[@$pfirst] = $element;
  }
}






=head1 $unqutoted = unquote($text)

Remove Quotes at the beginning and the End

=cut

sub unquote {
  my $text = shift;
	$text =~ s/^'//;
	$text =~ s/'$//;
	return $text;
}







=head1 logit

=cut

sub logit {
  my $txt = shift;
  print STDERR "ExLogin: $txt\n";
}






1;
