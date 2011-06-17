# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:23 $

package Archivista::DL::MyUser;

use strict;
use constant GRANT => "GRANT";
use constant REVOKE => "REVOKE";
use constant SYSOP => 255;

use Archivista::Config;

use vars qw ( $VERSION );

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PRIVATE METHODS






sub _privileges
{
  my $self = shift;
  my $type = shift;
  my $host = shift;
  my $uid = shift;
  my $pwd = shift;
  my $level = shift;
  $type = uc($type);
  my $dbh = $self->db->dbh;
	my $dbh1 = $dbh;
  my $dbh2 = $self->db->sudbh;	
  my $database = $self->db->database;
  my $grantTo = $dbh->quote($uid)."@".$dbh->quote($host);
  my $isSYSOP = $self->_isSysop($dbh,$database,$grantTo);
  my @tables = (
                  "user",
                  "parameter",
                  "workflow",
                  "archiv",
                  "abkuerzungen",
                  "archivseiten",
                  "archivbilder",
                  "feldlisten",
                  "adressen",
                  "adressenplz",
                  "literatur",
                  "literaturrubrik",
                  "notizen",
                );

  $level = 0 if (! defined $level);
  # Table grants for archivista database
	if($isSYSOP) {;
	  $level=255; 
	  # we have the first user (SYSOP), so set back Level 255
	  my $sql = "update $database.user set Level=255 "
		        . "where User='$uid' and Host='$host'";
		$dbh->do($sql);
  }	

  # check first if we already have grant rights (so wee neet to revoke them)
	my $revokefirst = $self->checkGrant($grantTo,$dbh2,$database);

	# only change user rights if we don't have the FIRST user (SYSOP)
  foreach my $table (@tables) {
    # NOTE : Set it to "select" as default
    my $priv="select";
    my $opt="";
    my $sql = "";
    if ($level == SYSOP) {
	    # Level 255
      $priv="All";
      $opt=" with grant option";
    } elsif ($table ne "parameter" && 
             $table ne "workflow" &&
             $table ne  "user" && 
             $level > 0) {
		  # not level 0 and not internal tables
      $priv = "Select,Insert,Update,Delete";
    }
    if ($type eq GRANT) {
      $sql = "TO $grantTo $opt";
    } elsif ($type eq REVOKE) {
      # We don't need $opt becaus it's only for grant
      $sql = "FROM $grantTo";
    }
    if ($sql ne "" && (($type eq REVOKE && $revokefirst==1) ||
		                    $type eq GRANT)) {
      $sql="$type $priv ON $database.$table $sql";
			my $sql1 = "select version()";
			my @row = $dbh->selectrow_array($sql1);
			my $vers = $row[0];
			my $vers1 = int $vers;
			if ($vers1>=5) {
			  if ($table eq "user") {
			    # mysql5 does not open user when sending a grant, so
				  # we need to do this manually (only once when granting user table)
				  $sql1 = "create user '$uid'\@$host";
				  $dbh2->do($sql1);
				  if ($level==255) {
				    $sql1 = "update mysql.user set Create_user_priv='Y' ".
					          "where user=".$dbh->quote($uid)." and ".
							  		"host=".$dbh->quote($host);
				    $dbh2->do($sql1);
				  }
				  $dbh2->do("flush privileges");
				}
				$dbh1 = $dbh2;
			}
      $dbh1->do($sql);
    }
  }
 
  my $sql="";
  if ($level!=SYSOP) {
    if ($type eq GRANT) {
	    # give the right to update flag field PWArt after login
      $sql = "$type Update(PWArt) ON $database.user TO $grantTo";
    } elsif ($type eq REVOKE ) {
      # remove the grant option from users
      $sql = "$type Update(PWArt) ON $database.user FROM $grantTo";
		}
    $dbh1->do($sql);
  }
 	$self->AccessLog($type,$host,$uid,$dbh2);

  my $cmd = "perl /home/cvs/archivista/jobs/adjustRights.pl";
	my $cmd2 = lc($type);
	system("$cmd $database $cmd2 $uid $host");
}






=head1 $revokefirst=checkGrant($grant,$dbh,$database)

Check if existing rights are available (we need to revoke rights)

=cut

sub checkGrant {
  my $self = shift;
  my $grant = shift;
	my $dbh = shift;
	my $database = shift;
	my $sql = "show grants for $grant";
	my $prow = $dbh->selectall_arrayref($sql);
	my $found = 0;
	foreach (@$prow) {
	  my $row = $$_[0];
		if (index($row,$database)>0) {
			$found = 1;
			last;
		}
  }
	return $found;
}






sub AccessLog {
  my $self = shift;
  my $type = shift;
	my $host = shift;
	my $uid = shift;
	my $dbh = shift;
	return if $host eq "localhost";
  my $config = Archivista::Config->new;
  my $host1 = $config->get("MYSQL_HOST");
  my $db1 = $config->get("MYSQL_DB");
  my $user1 = $config->get("MYSQL_UID");
  my $pw1 = $config->get("MYSQL_PWD");
	if ($dbh) {
    if ($type eq GRANT) {
      my $sql = "grant select,insert,update on archivista.access to ".
	              $dbh->quote($uid)."@".$dbh->quote($host);
	    $dbh->do($sql);
	  } elsif ($type eq REVOKE) { 
	    my $sql = "revoke all on archivista.access from ".
	              $dbh->quote($uid)."@".$dbh->quote($host);
	    $dbh->do($sql);
	  }
	}
}






sub _isSysop{
  my $self = shift;
  my $dbh = shift;
  my $db = shift;
  my $grantTo = shift;

  my ($user,$host) = split('@',$grantTo);

  if($user =~ /SYSOP/){
    my $sql = "select Laufnummer from "
            . "$db.user where User=$user "
            . "and Host=$host";
    my $row = $dbh->selectrow_arrayref($sql);
    if($row->[0] == 1){
      return 1;
    } else {
      return 0;
    }
  } else {
    return 0;
  }
}







# -----------------------------------------------
# PUBLIC METHODS

sub myInsert
{
  my $self = shift;
  my $host = shift;
  my $uid = shift;
  my $pwd = shift;
  my $level = shift;
  $self->_privileges(GRANT,$host,$uid,$pwd,$level);
}

# -----------------------------------------------

sub myUpdate
{
  my $self = shift;
  my $attribute = shift; # Object of Archivista::BL::Attribute
  
  # NOTE: the syntax $attribute->id()->value can't be used; 
  # it's not the same as $user->attribute()->value !!
  $attribute->id("Host");
  my $host = $attribute->value;
  $attribute->id("User");
  my $uid = $attribute->value;
  $attribute->id("Password");
  my $pwd = $attribute->value;
  $attribute->id("Level");
  my $level = $attribute->value;
  $self->_privileges(REVOKE,$host,$uid,undef,255);
  $self->_privileges(GRANT,$host,$uid,$pwd,$level);
}

# -----------------------------------------------

sub myGrant
{
  my $self = shift;
  my $pausers = shift; # 2-dim array[n][2] host,user,level

  for (my $i = 0; $i <= $#$pausers; $i++) {
    my $host = $$pausers[$i][0];
    my $uid = $$pausers[$i][1];
    my $level = $$pausers[$i][2];
    
    $self->_privileges(REVOKE,$host,$uid,undef,255);
    $self->_privileges(GRANT,$host,$uid,undef,$level);
  }
}

# -----------------------------------------------

sub myRevoke
{
  my $self = shift;
  my $pausers = shift;

  for (my $i = 0; $i <= $#$pausers; $i++) {
    my $host = $$pausers[$i][0];
    my $uid = $$pausers[$i][1];
    my $level = $$pausers[$i][2];

    $self->_privileges(REVOKE,$host,$uid,undef,$level);
  }
}

# -----------------------------------------------

sub myDelete
{
  my $self = shift;
  my $user = shift;

  my $query;
  my $dbh = $self->db->dbh;
  my $host = $user->attribute("Host")->value;
  my $uid = $user->attribute("User")->value;
  my $level = $user->attribute("Level")->value;
  $self->_privileges(REVOKE,$host,$uid,undef,255);
}

1;

__END__

=head1 NAME


=head1 SYNOPSYS


=head1 DESCRIPTION


=head1 DEPENDENCIES


=head1 EXAMPLE


=head1 TODO


=head1 AUTHOR


=cut

# Log record
# $Log: MyUser.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:23  upfister
# Copy to sourceforge
#
# Revision 1.7  2008/07/28 18:05:40  up
# Adjusting extended tables
#
# Revision 1.6  2007/11/13 04:02:50  up
# Corrected version for last commit (only revoke if needed, but anyway grant it)
#
# Revision 1.5  2007/11/13 00:11:02  up
# Check first if rights exist and only then revokes rights so we can give new
# grants
#
# Revision 1.4  2007/09/27 06:24:28  up
# Don't open a second dbh handler when creating a user
#
# Revision 1.3  2007/02/19 10:59:10  up
# Give only rights to the access log table if not localhost
#
# Revision 1.2  2007/02/19 09:56:12  up
# Add/Remove rights for access table
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.4  2006/07/24 13:24:00  up
# SYSOP account in empty database is now working
#
# Revision 1.3  2006/06/29 14:20:04  up
# Corrected user rights (no access to internal tables, SYSOP NOT changeable
#
# Revision 1.2  2005/10/18 21:31:23  up
# Changes for ArchivistaBox
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.16  2005/06/08 16:56:01  ms
# Anpassungen an _exception
#
# Revision 1.15  2005/06/04 16:10:06  up
# correct updates for mysql-table (flush privileges)
#
# Revision 1.14  2005/06/02 18:29:53  ms
# Implementing update for mask definition
#
# Revision 1.13  2005/05/26 15:54:18  ms
# Anpassungen/Bugfixing für LinuxTag
#
# Revision 1.12  2005/05/12 13:01:43  ms
# Last changes for archive server (v.1.0)
#
# Revision 1.11  2005/04/28 14:20:09  ms
# *** empty log message ***
#
# Revision 1.10  2005/04/27 16:18:52  ms
# Anpassungen an GRANT/REVOKE
#
# Revision 1.9  2005/04/22 17:27:48  ms
# Anpassungen für Archivverwaltung
#
# Revision 1.8  2005/04/20 11:20:06  ms
# Bugfix: deleting multi user
#
# Revision 1.7  2005/03/31 18:18:14  ms
# Weiterentwicklung an formular elemente (hinzufügen neuer elemente)
#
# Revision 1.6  2005/03/23 12:01:44  ms
# Anpassungen an GRANT / REVOKE
#
# Revision 1.5  2005/03/22 18:35:21  ms
# Entwicklung an User mit GRANT auf Tabellen und Attribute
#
# Revision 1.4  2005/03/21 18:33:20  ms
# Erzeugung neuer archivista datenbanken
#
# Revision 1.3  2005/03/18 18:58:45  ms
# Enwicklung an der Benutzerfunktionalität
#
# Revision 1.2  2005/03/18 15:38:42  ms
# Stabile version um User hinzuzufügen
#
# Revision 1.1  2005/03/15 18:40:04  ms
# File added to project
#
