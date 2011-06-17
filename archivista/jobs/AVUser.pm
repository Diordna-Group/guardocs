
package AVUser;
use strict;
use AVDB;
use Wrapper;


# field names from user table (not all)
use constant FLD_USER => 'User';
use constant FLD_HOST => 'Host';
use constant FLD_GROUPS => 'Alias';
use constant FLD_RECORDSLIMIT => 'Anzahl';
use constant FLD_LEVEL => 'Level';
use constant FLD_PWTYPE => 'PWArt';
use constant FLD_ADDON => 'AddOn';
use constant FLD_ADDUSER => 'AddNew';
use constant FLD_AVSTART => 'AVStart';
use constant FLD_AVFORM => 'AVForm';






sub id {wrap(@_)}
sub obj {wrap(@_)}
sub host {wrap(@_)}
sub database {wrap(@_)}
sub user {wrap(@_)}
sub password {wrap(@_)}
sub name {wrap(@_)}
sub host1 {wrap(@_)}
sub rights {wrap(@_)}
sub groups {wrap(@_)}
sub limit {wrap(@_)}
sub level {wrap(@_)}
sub pwtype {wrap(@_)}
sub addon {wrap(@_)}
sub adduser {wrap(@_)}
sub startsql {wrap(@_)}
sub form {wrap(@_)}

# id: unique user number in database
# obj: AVDocs object (is deleted after initializing
# host: host of the archive
# database: database of the connection
# user: user name
# password: password for the connection
# name: name of the connected user
# host1: rights that the connected user has
# groups: groups the user belongs to
# limit: number of records to show
# level: 0=read, 1=read/write own, 2=read all/write own, 3=all, 255=SYSOP
# pwtype: 0=without pw, 1=pw, 2=new password (inkl. empty), 3=new password
# addon: user can add/remove records
# adduser: when a user adds a record we use this owner
# startsql: sql start definition for the user
# form: form to use for the current user






=head1 new($bj) 

Opens an archivista user object depending on the avdocs $obj

=cut

sub new {
  my $class = shift;
	my $self = {};
	bless $self,$class;

  my ($obj)  = @_;
  $self->obj($obj); # get the AVDocs object
	my $user=$self->obj->dbUser;
  $user=$self->obj->USER_SYSOP if $user eq $self->obj->USER_ROOT;
	$self->id($self->_getUserId($self->obj->dbHost,$user));
	if ($self->id) {
	  # user was found, so set all values
    my @user = $self->obj->_select([$self->FLD_USER,$self->FLD_HOST,
		                         $self->FLD_GROUPS,$self->FLD_RECORDSLIMIT,
			  					  				 $self->FLD_LEVEL,$self->FLD_PWTYPE,
				  									 $self->FLD_ADDON,$self->FLD_ADDUSER,
					  								 $self->FLD_AVSTART,$self->FLD_AVFORM],
						  							 $self->obj->FLD_RECORD,$self->id,
														 $self->obj->TABLE_USER);
    $self->host($self->obj->dbHost);
	  $self->database($self->obj->dbDatabase);
	  $self->user($self->obj->dbUser);
	  $self->password($self->obj->dbPassword);
	  $self->name($user[0]);
	  $self->rights($user[1]);
	  $self->groups($user[2]);
	  $self->limit($user[3]);
	  $self->level($user[4]);
	  $self->pwtype($user[5]);
	  $self->addon($user[6]);
	  $self->adduser($user[7]);
	  $self->startsql($user[8]);
	  $self->form($user[9]);
	}
	$self->obj(0); # remove the given object
	return ($self,$self->id);
}






=head1 AVuser has the following PUBLIC getter methods

id
host
database
user
password
name
rights
groups
limit
level
pwtype
addon
adduser
startsql
form

=cut 






# $userId=_getUserId 
# Give back the current user id from the user table
#
sub _getUserId {
  my $self=shift;
  my ($host,$uid)  = @_;
	my $host1 = $host; # we keep the host in case we don't find it
  my @row = $self->obj->_getRow($self->obj->SQL_SHOWPROCESSLIST);
  if ( $row[2] ne "" ) {
	  $host = $row[2];
	  $host =~ s/(.*)(:[0-9]+)$/$1/;
	}
	$host1 = $host if $host ne "";
  my @p = split(/\./,$host);
	my $c1 = -1;
	my $found = 0;
	my $laufnummer = 0;

	while ($found==0) {
	  # as long we dont find a record, search again
    ($laufnummer,$found) = $self->_getUserIdCheck($host1,$uid);
		if ($found==0) {
		  # not found
		  if ($host1 eq $host) {
			  # first have look at global permissions
		    $host1='%';
		  } else {
			  # now have a look at ip/dns name parts
				if ($p[0] ne "") {
					if ($c1==-1) {
					  # ip (try first last part)
				    pop @p;
					  $host1 = join('.',@p) . '.%';
					} else {
					  # dns name (try first first part)
					  shift @p;
						$host1 = '%.' . join('.',@p);
					}
				} else {
				  # switch from ip to dns lookup
				  if ($c1==-1) {
            @p = split(/\./,$host);
					  @p = reverse @p;
					  $c1=0;
					} else {
					  # say at the end, that we don't search further on
					  $found=1;
					}
				}
			}
		}
	}
  return $laufnummer;
}






# $laufnummer=_getUserIdCheck($host,$uid)
# Tries to match one single host name and gives back laufnummer (if founded)
#
sub _getUserIdCheck {
  my $self=shift;
  my ($host,$uid)  = @_;
  my ($found,$laufnummer);
	my @row = $self->obj->_select($self->obj->FLD_RECORD,[$self->FLD_HOST,
	                             $self->FLD_USER],[$host,$uid],
					                     $self->obj->TABLE_USER);
	$laufnummer=$row[0];
	$found=1 if $laufnummer>0;
  return ($laufnummer,$found);
}






=head1 $ok=checkUpdateRecordRights

Give back if we can update fields (whole record, not a field)

=cut

sub checkUpdateRecordRights {
  my $self = shift;
	my $ret=1;
	if ($self->level==0 || 
	    ($self->addon==0 && $self->level<255)) {
	  $ret=0;
	}
	return $ret;
}






=head1 $ok=checkAddDeleteRecordRights

Give back if we can update fields (whole record, not a field)

=cut

sub checkAddDeleteRecordRights {
  my $self = shift;
	my $ret=0;
	if (($self->level>0 && $self->addon==1) || $self->level==255) {
	  $ret=1;
	}
	return $ret;
}






=head1 $ok=checkUpdateRights($owner)

Checks if a user can update/delete a record

=cut

sub checkUpdateRights {
  my $self=shift;
  my ($owner)  = @_;
  my $rights=0;
	if ($self->level==255 || $self->level==3) {
    $rights=1;
	} elsif ($self->level==1 || $self->level==2) {
	  my @owns = split(',',$self->groups);
		push @owns,'';
		push @owns,$self->name;
		foreach (@owns) {
		  if ($owner eq $_) {
			  $rights=1;
				last;
			}
		}
	}
  return $rights;
}







1;

