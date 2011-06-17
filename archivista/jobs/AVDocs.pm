#!/usr/bin/perl

=head1 AVDocs.pm Archivista Class for manipulation Documents, Pages and Parameters.

(c) 2006 by Archivista GmbH, Urs Pfister
This class is inherited from the following classes: AVDB,AVBase,AVConfig

=cut

package AVDocs;

use strict;
use AVDB;
use AVUser;
use AVScan;
use Wrapper;

our @ISA = qw(AVDB);

# default database name
use constant DB_DEFAULT => 'archivista';

# tables in every archivista database (not all)
use constant TABLE_DOCS => 'archiv';
use constant TABLE_PAGES => 'archivseiten';
use constant TABLE_IMAGES => 'archivbilder';
use constant TABLE_PARAMETER => 'parameter';
use constant TABLE_USER => 'user';
use constant TABLE_FIELDLISTS => 'feldlisten';
use constant TABLE_ABREVIATIONS => 'abkuerzungen';

# table names for MAIN archivista database
use constant TABLE_JOBS => 'jobs';
use constant TABLE_JOBSDATA => 'jobs_data';
use constant TABLE_LOGS => 'logs';
use constant TABLE_MENUS => 'application_menu';
use constant TABLE_LANGUAGES => 'languages';
use constant TABLE_ARCHIVESLIST => 'archives';
use constant TABLE_SESSIONWEB => 'sessionweb';
use constant TABLE_SESSION => 'session';
use constant TABLE_SESSIONS => 'sessions';
use constant TABLE_SESSIONDATA => 'session_data';

# field names for archiv table
use constant FLD_DOC => 'Laufnummer';
use constant FLD_DOC2 => 'Akte';
use constant FLD_PAGES => 'Seiten';
use constant FLD_TYPE => 'ArchivArt';
use constant FLD_OWNER => 'Eigentuemer';
use constant FLD_TITLE => 'Titel';
use constant FLD_NOTE => 'Notiz';
use constant FLD_DATE => 'Datum';
use constant FLD_DATE_ADDED => 'ErfasstDatum';
use constant FLD_FOLDER => 'Ordner';
use constant FLD_ADDED => 'Erfasst';
use constant FLD_ARCHIVED => 'Archiviert';
use constant FLD_FILENAME => 'EDVName';
use constant FLD_LOCKED => 'Gesperrt';
use constant FLD_INPUT_ON => 'BildInput';
use constant FLD_INPUT_EXT => 'BildInputExt';	
use constant FLD_IMAGE_ON => 'BildIntern';
use constant FLD_IMAGE_EXT => 'BildAExt';
use constant FLD_SOURCE_ON => 'QuelleIntern';
use constant FLD_SOURCE_EXT => 'QuelleExt';
use constant FLD_USERADDED_NAME => 'UserNeuName';
use constant FLD_USERADDED_TIME => 'UserNeuDatum';
use constant FLD_USERMOD_NAME => 'UserModName';
use constant FLD_USERMOD_TIME => 'UserModDatum';

# key field for secondary Archivista tables
use constant FLD_RECORD => 'Laufnummer';

# field names from archivbilder
use constant FLD_IMG_INPUT => 'BildInput';
use constant FLD_IMG_IMAGE => 'Bild';
use constant FLD_IMG_HIGH => 'BildA';
use constant FLD_IMG_SOURCE => 'Quelle';
use constant FLD_IMG_PAGE => 'Seite';
use constant FLD_IMG_X => 'BildX';
use constant FLD_IMG_Y => 'BildY';
use constant FLD_IMG_AX => 'BildAX';
use constant FLD_IMG_AY => 'BildAY';

# field names from archivseiten tabel (not all)
use constant FLD_PAGE => 'Seite';
use constant FLD_TEXT => 'Text';
use constant FLD_OCR => 'OCR';
use constant FLD_OCR_EXCLUDE => 'Ausschliessen';
use constant FLD_OCR_DONE => 'Erfasst';

# field names from parameter table (not all)
use constant FLD_PAR_VALUE => 'Inhalt';
use constant FLD_PAR_NAME => 'Name';
use constant FLD_PAR_TYPE => 'Art';

# field names from logs table
use constant FLD_LOGFILE => 'file';
use constant FLD_LOGPATH => 'path';
use constant FLD_LOGTYPE => 'type';
use constant FLD_LOGDATE => 'date';
use constant FLD_LOGHOST => 'host';
use constant FLD_LOGDB => 'db';
use constant FLD_LOGUSER => 'user';
use constant FLD_LOGPWD => 'pwd';
use constant FLD_LOGOWNER => 'owner';
use constant FLD_LOGPAPERSIZE => 'papersize';
use constant FLD_LOGPAGES => 'pages';
use constant FLD_LOGWIDTH => 'width';
use constant FLD_LOGHEIGHT => 'height';
use constant FLD_LOGRESX => 'resx';
use constant FLD_LOGRESY => 'resy';
use constant FLD_LOGBITS => 'bits';
use constant FLD_LOGFORMAT => 'format';
use constant FLD_LOGDOC => 'Laufnummer';
use constant FLD_LOGTIME => 'TIME';
use constant FLD_LOGDONE => 'DONE';
use constant FLD_LOGERROR => 'ERROR';
use constant FLD_LOGID => 'ID';

use constant FLD_JOBID => 'id';
use constant FLD_JOBTYPE => 'job';
use constant FLD_JOBHOST => 'host';
use constant FLD_JOBDB => 'db';
use constant FLD_JOBUSER => 'user';
use constant FLD_JOBPWD => 'pwd';
use constant FLD_JOBTIMEMOD => 'timemod';
use constant FLD_JOBTIMEADD => 'timeadd';
use constant FLD_JOBSTATUS => 'status';
use constant FLD_JOBERROR => 'error';
use constant FLD_JOBIDLINK => 'jid';
use constant FLD_JOBPARAM => 'param';
use constant FLD_JOBVALUE => 'value';

use constant FLD_SESSIONID => 'sid';
use constant FLD_SESSIONHOST => 'host';
use constant FLD_SESSIONDB => 'db';
use constant FLD_SESSIONUSER => 'user';
use constant FLD_SESSIONPW => 'pw';
use constant FLD_SESSIONVALS => 'vals';
use constant FLD_SESSIONDATE => 'date';

use constant PAR_JOBSCANDEF => 'SCAN_DEFINITION';
use constant PAR_JOBSCANDOC => 'SCAN_TO_DOCUMENT';
use constant PAR_JOBFILE => 'FILENAME';

# constants for archive table
use constant DOC_TYPE_BMP => 0;
use constant DOC_TYPE_TIF => 1;
use constant DOC_TYPE_PNG => 2;
use constant DOC_TYPE_JPG => 3;
use constant DOC_EXT_BMP => 'BMP';
use constant DOC_EXT_TIF => 'TIF';
use constant DOC_EXT_PNG => 'PNG';
use constant DOC_EXT_JPG => 'JPG';
use constant DOC_MAXPAGES => 640;

# constants for parameter table
use constant PAR_SCANDEFS => 'ScannenDefinitionen';
use constant PAR_AVVERSION => 'AVVersion';
use constant PAR_AVBOX => 'ArchivistaBox';
use constant PAR_PUBLISHFIELD => 'PublishField';
use constant PAR_PUBLISHALL => 'ALL';
use constant PAR_QUALITYJPG => 'JpegQuality';
use constant PAR_FOLDER => 'ArchivOrdner';

# constants for default users
use constant USER_SYSOP => 'SYSOP';
use constant USER_ROOT => 'root';
use constant USER_LOCALHOST => 'localhost';

use constant JOB_SANE => 'SANE';
use constant JOB_CUPS => 'CUPS';
use constant JOB_FTP => 'FTP';
use constant JOB_MAIL => 'MAIL';
use constant JOB_PDF => 'PDF';
use constant JOB_TIFF => 'TIFF';
use constant JOB_TOSCA => 'TOSCA';
use constant JOB_AXAPTA => 'AXAPTA';




sub parid {wrap(@_)}
sub publish_field {wrap(@_)}
sub archivistadb {wrap(@_)}
sub archivistamain {wrap(@_)}
sub scandef {wrap(@_)}
sub scanid {wrap(@_)}
sub scan {wrap(@_)}
sub user {wrap(@_)}
sub folder {wrap(@_)}

# parid: record number to update a found parameter value
# ublish_field: field for publishing documents to other users
# archivistadb: is it an archivista db
# archivistamain: is it the main archivista db
# scandef: the current scan definition
# scanid: the id for the current scan definition
# user: object that holds all user information






=head1 new([$host,$db,$user,$pwd]) 

We give back an object and connect to the database (given 
with host,db,user,pwd). If no parameters are given, the normal
database connection is made with the values from AVConfig.



=cut

sub new {
  my $class = shift;
	my ($host,$db,$user,$pwd) = @_;
  my $self = $class->SUPER::new($host,$db,$user,$pwd,TABLE_USER);
	$self->_initValuesArchivista;
	return $self;
}







# changes all values after a new database connection
#
sub _initValuesArchivista {
  my $self = shift;
  $self->scanid(0);
  $self->scandef('');
	$self->parid(0);
	$self->archivistadb(0);
	$self->archivistamain(0);
	$self->table ( $self->TABLE_DEFAULT);
	$self->keyfield ( $self->FLD_DEFAULT);
	$self->keyvalue ( 0);
	$self->avuser(0);
	if ($self->dbState) {
	  if ($self->isArchivistaDB) { # we have an archivista db
			$self->user(AVUser->new($self)); 
			$self->publish_field($self->getParameter($self->PAR_PUBLISHFIELD));
			$self->folder($self->getParameter($self->PAR_FOLDER));
		}
	}
}






=head1 @row=select($pfield,[$condField,$condValue,$table])

Selects field(s) from an archivista archive table and gives back 
ONE record OR one field (just as a scalar)

=cut

sub select {
  my $self = shift;
	my ($pfields,$condField,$condValue,$table) = @_;
  $self->_checkTableArchive($condField,$condValue,\$table);
	if ($table eq $self->TABLE_DOCS) {
	  if (!defined($condField) && $self->keyvalue>0) {
		  # if we don't have values, we select the current record
			# that was selected previously
			$$condField[0] = $self->keyfield;
			$$condValue[0] = $self->keyvalue;
		}
	}
	if ($self->sqllimit ne "") {
	  # give back a number of record, don't set keyvalue
		my @prow=$self->SUPER::_select($pfields,$condField,$condValue,$table);
    #my @prow=base->_select($pfields,$condField,$condValue,$table);
		return $prow[0];
	} else {
	  # give back one record/field, set keyvalue
		my @row=$self->SUPER::_select($pfields,$condField,$condValue,$table);
    #my @row=base->_select($pfields,$condField,$condValue,$table);
	  if ($#row>0) {
	    return @row;
	  } else {
	    return $row[0];
	  }
	}
}






=head1 $rec=search($pfields,$pvals,[$table])

Search a record in an archivista archive table and gives back the record

=cut

sub search  {
  my $self = shift;
	my ($pfields,$pvals,$table) = @_;
  $self->_checkTableArchive($pfields,$pvals,\$table);
	my @ret = $self->SUPER::search($pfields,$pvals,$table);
	return $ret[0];
}







# check if we are in an archivista db (and correct tables)
#
sub _checkTableArchive {
  my $self = shift;
	my ($pfields,$pvals,$ptable) = @_;
	$self->_checkTable($ptable);
	if ($$ptable eq $self->TABLE_DOCS && $self->archivistadb) {
    $self->_initAddOwnerPublish($pfields,$pvals);
	}
}






# add the selections for getting the right documents
#
sub _initAddOwnerPublish {
  my $self = shift;
	my ($condField,$condValue) = @_;
  if (!defined($condField) && !defined($condValue)) {
 	  ($condField,$condValue)=$self->_initFieldsVals($condField,$condValue);
	}
 	if ($self->user->level==0 or $self->user->level==1) {
    $self->_searchOwner($condField,$condValue,$self->FLD_OWNER);
	  if ($self->publish_field ne "") {
	    $self->_searchOwner($condField,$condValue,$self->publish_field);
	  }
  }
}






# add the SQL_AND fields for owner/publish_field
#
sub _searchOwner {
  my $self = shift;
	my ($pfields,$pvals,$fld) = @_;
  my (@pnfields,@pnvals);
	my $valall = $self->PAR_PUBLISHALL;
	$valall = '' if $fld eq $self->FLD_OWNER;
	if (ref($pfields) ne "ARRAY") {
	  push @pnfields,$fld;
		push @pnvals,$valall;
	  $pfields=\@pnfields;
		$pvals=\@pnvals;
	} else {
	  push @$pfields,$fld;
    push @$pvals,$valall;
	}
		
	my @own = split(',',$self->user->groups);
	push @own,$self->user->name;
	foreach (@own) {
	  push @$pfields,$self->SQL_OR;
		push @$pvals,$_;
	}
}






=head1 $rec=add($pfields,$pvals,[$table])

Add an archivista document to the archive table

=cut 

sub add {
  my $self = shift;
	my ($pfields,$pvals,$table) = @_;
	my ($pdat,$ptyp,$pown,$ppub,$rec);
	$self->_checkTable(\$table);
  return 0 if $self->isArchivistaInternalTable($table);
	if ($table eq $self->TABLE_DOCS && $self->archivistadb) {
    return 0 if $self->user->checkAddDeleteRecordRights==0; # check for rights
	  ($pfields,$pvals)=$self->_initFieldsVals($pfields,$pvals); #ARRAY/SCALAR?
    my $pdel = $self->_initFieldsDelete; # ARRAY with fields to check
	  $$ptyp = $self->DOC_TYPE_TIF; # default type is TIF images
	  $$pown = ''; # no default owner
	  $$pdat = $self->_quoteDateNow; # the current date in case there is none
    # check which fields we do accept, save the special fields
    $self->_addCheckFields($pfields,$pvals,$pdel,$ptyp,$pown,$ppub,$pdat);
    # add the document type to the document
    $self->_addDocTyp($pfields,$pvals,$ptyp);
    # check for owners
	  $self->_addUser($pfields,$pvals,$self->FLD_OWNER,$$pown);
		if ($self->publish_field ne "") {
	    $self->_addUser($pfields,$pvals,$self->publish_field,$$ppub);
		}
	  # add some special fields we want to have
	  push @$pfields,$self->FLD_DATE;
	  push @$pvals,$$pdat;
	  push @$pfields,$self->FLD_DATE_ADDED;
	  push @$pvals,$self->_quoteDateNow;
	  push @$pfields,$self->FLD_USERADDED_NAME;
	  push @$pvals,$self->user->name;
	  push @$pfields,$self->FLD_USERMOD_NAME;
	  push @$pvals,$self->user->name;
	  push @$pfields,$self->FLD_FOLDER;
	  push @$pvals,$self->folder;
	}
	# create the record in the db
  $rec = $self->_addDoIt($pfields,$pvals,$table);
	return $rec;
}






=head1 $done=update($pfields,$pvals,$condField,$condValue,[$table])

Update an archivista document to the archive table

=cut 

sub update {
  my $self = shift;
	my ($pfields,$pvals,$condField,$condValue,$table) = @_;
	my ($pdat,$ptyp,$pown,$ppub);
	$self->_checkTable(\$table);
  return 0 if $self->isArchivistaInternalTable($table);
	if ($self->archivistadb && $table eq $self->TABLE_DOCS) {
    return 0 if $self->user->checkUpdateRecordRights==0; # check for rights
    $self->_initAddOwnerPublish($condField,$condValue);
	  my $val=$self->_initFields($condField,$condValue,\$table);
	  if ($val) {
	    # record was found, so we update it
	    ($pfields,$pvals)=$self->_initFieldsVals($pfields,$pvals); #ARRAY/SCALAR?
      my $pdel = $self->_initFieldsDelete; # ARRAY with fields to check
      my $pflds1=[$self->FLD_PAGES,$self->FLD_ARCHIVED,
			            $self->FLD_TYPE,$self->FLD_DATE,$self->FLD_OWNER];
		  push @$pflds1,$self->publish_field if $self->publish_field ne "";
		  my @vals1=$self->select($pflds1);
		  $$ptyp = $vals1[2];
	    $$pdat = $vals1[3];
		  $$pown = $vals1[4];
		  $$ppub = $vals1[5];

			# stop, if only READ rights
			return 0 if $self->user->checkUpdateRights($$pown)==0; 
			
      # check which fields we do accept, save the special fields
      $self->_addCheckFields($pfields,$pvals,$pdel,$ptyp,$pown,$ppub,$pdat);
		  if ($vals1[2] != $$ptyp && $vals1[0]==0 && $vals1[1]==0) { 
        # change the document type to the document
        $self->_addDocTyp($pfields,$pvals,$ptyp);
		  }
		
      # check for owners
		  if ($vals1[4] ne $$pown) {
	      $self->_addUser($pfields,$pvals,$self->FLD_OWNER,$$pown);
		  }
		  if ($vals1[5] ne $$ppub && $self->publish_field ne "") {
	      $self->_addUser($pfields,$pvals,$self->publish_field,$$ppub);
		  }
		
	  	if ($vals1[3] ne $$pdat) {
	      # add some special fields we want to have
	      push @$pfields,$self->FLD_DATE;
	      push @$pvals,$$pdat;
		  }
		
	    push @$pfields,$self->FLD_USERMOD_NAME;
	    push @$pvals,$self->user->name;
	    # create the record in the db
		}
	}
  my @done=$self->SUPER::update($pfields,$pvals,$condField,$condValue,$table);
	return $done[0];
}






# initiate the fields we need to care about
#
sub _initFieldsDelete {
  my $self = shift;
  # this fields we need to process in a special manner or it is forbidden
	# MOD: 15.1.2009 -> we can modify EDVName
  my @delete = ($self->FLD_DOC,$self->FLD_DOC2,$self->FLD_PAGES,
	              $self->FLD_DATE,$self->FLD_DATE_ADDED,$self->FLD_FOLDER,
								$self->FLD_ADDED,$self->FLD_ARCHIVED,
								$self->FLD_LOCKED,$self->FLD_INPUT_ON,$self->FLD_INPUT_EXT,
								$self->FLD_IMAGE_ON,$self->FLD_IMAGE_EXT,$self->FLD_SOURCE_ON,
								$self->FLD_SOURCE_EXT,$self->FLD_TYPE,$self->FLD_OWNER,
						    $self->FLD_USERADDED_NAME,$self->FLD_USERADDED_TIME,
								$self->FLD_USERMOD_NAME,$self->FLD_USERMOD_TIME);
	# add the publish field to the watch list if it is defined
	push @delete,$self->publish_field if $self->publish_field ne "";
	$self->errorfields([]);
	$self->errorfieldstate(1);
  return \@delete;
}






# does check if the owner/publish_field values are correct
#
sub _addUser {
  my $self = shift;
	my ($pfields,$pvals,$fld,$fowner) = @_;
  my ($fownerok);
  if ($fowner ne "") {
    my @owners = split(',',$self->user->groups);
    push @owners,$self->user->name;
		push @owners,$self->PAR_PUBLISHALL if $fld eq $self->publish_field;
    if ($self->user->level<3) {
      foreach (@owners) {
        if ($_ eq $fowner) {
				  # User has level 1,2 and desired owner is available
			    $fownerok=1;
				  last;
			  }
		  }
    } else {
		  # User has level 3 or 255 (anything is ok)
	    $fownerok=1;
	  }
  } else {
	  # empty user
		$fownerok=1;
	}	
	if ($fld eq $self->FLD_OWNER && $self->user->adduser ne "") {
	  $fowner=$self->user->adduser;
	  $fownerok=1;
	}
	if ($fownerok==1) {
	  push @$pfields,$fld;
		push @$pvals,$fowner;
	}
}






sub _addDocTyp {
  my $self = shift;
	my ($pfields,$pvals,$ptype) = @_;
  my ($fext,$fimg);
  # check for doctype and extension
	$$ptype = $self->DOC_TYPE_TIF if ($$ptype != $self->DOC_TYPE_BMP &&
			                      $$ptype != $self->DOC_TYPE_PNG &&
			                      $$ptype != $self->DOC_TYPE_JPG);
	push @$pfields,$self->FLD_TYPE;
	push @$pvals,$$ptype;
  if ($$ptype == $self->DOC_TYPE_BMP) {
	  $fext=$self->DOC_EXT_BMP;
		$fimg=$self->DOC_EXT_PNG;
	} elsif ($$ptype == $self->DOC_TYPE_TIF) {
	  $fext=$self->DOC_EXT_TIF;
		$fimg=$self->DOC_EXT_PNG;
	} elsif ($$ptype == $self->DOC_TYPE_PNG) {
	  $fext=$self->DOC_EXT_PNG;
		$fimg=$self->DOC_EXT_PNG;
	} else {
	  $fext=$self->DOC_EXT_JPG;
		$fimg=$self->DOC_EXT_JPG;
	}
	push @$pfields,$self->FLD_IMAGE_EXT;
	push @$pvals,$fimg;
	push @$pfields,$self->FLD_IMAGE_ON;
	push @$pvals,1;
	push @$pfields,$self->FLD_INPUT_EXT;
	push @$pvals,$fext;
	push @$pfields,$self->FLD_INPUT_ON;
	push @$pvals,1;
}






# does a check to all fields from @delete with @fields, if needed
# the field is kicked off then ARRAY
#
sub _addCheckFields {
  my $self = shift;
	my ($pfields,$pvals,$pdelete,$pft,$pfo,$pfp,$pfd) = @_;
  my ($c);
	foreach (@$pfields) {
	  # go through every field and check if it is ok
    my $f=$_;
	  $$pft = $$pvals[$c] if $f eq $self->FLD_TYPE; # save type
    $$pfo = $$pvals[$c] if $f eq $self->FLD_OWNER; # save owner
		$$pfp = $$pvals[$c] if $f eq $self->publish_field; # publish field
		$$pfd = $$pvals[$c] if $f eq $self->FLD_DATE; # save date
		foreach (@$pdelete) {
		  # check if we need to remove the field
		  my $d=$_;
			if ($d eq $f) {
			  # this is the case, so set the field value to ''
			  $$pfields[$c]="";
			  push @{$self->errorfields},$f;	
        last;
			}
		}
		$c++;
	}

	my $found=1;
	while ($found==1) {
	  # go through the fields until we don't find empty fields,
		# does mean fields we need to remove (internal fields)
	  $found=0;
		$c=0;
	  foreach (@$pfields) {
      if ($$pfields[$c] eq "") {
		    splice @$pfields,$c,1;
			  splice @$pvals,$c,1;
			  $found=1;
			  last;
		  }
			$c++;
		}
	}
}






# add the fields with the values to the archive table
#
sub _addDoIt {
  my $self = shift;
	my ($pfields,$pvals,$table) = @_;
	# finally add the record through the internal OBER class
  my @row=$self->SUPER::add($pfields,$pvals,$table);
	my $rec = $row[0];
	if ($rec>0 && $table eq $self->TABLE_DOCS && $self->archivistadb) {
	  # record was added, now change field Akte (FLD_DOC2),Timestampd Added

		# first get back the TimeStamp
    my $sql=$self->SQL_SELECT.$self->FLD_USERMOD_TIME.$self->SQL_FROM.$table.
						$self->SQL_WHERE.$self->FLD_DOC.'='.$rec;
	  my @time=$self->SUPER::_getRow($sql);
		
		# now update TimeStamp and FLD_DOC2 (Akte)
    $sql=$self->SQL_UPDATE.$table.$self->SQL_SET.
		        $self->FLD_DOC2.'='.$rec.",".
						$self->FLD_USERADDED_TIME."='".$time[0]."' ".
						$self->SQL_WHERE.$self->FLD_DOC.'='.$rec;
		my @done = $self->SUPER::_setRows($sql);
		
		if ($done[0]==0) {
		  # update was not sucessfully, so remove the record
		  $sql=$self->SQL_DELETE.$table.$self->SQL_WHERE.$self->FLD_DOC.'='.$rec;
		  my @done = $self->SUPER::_setRows($sql);
			$rec=0;
		}
	}
	return $rec; # give back the record number (otherwiese 0)
}






=head1 $deleted=delete($condField,$condValue,[$table])

Delete ONE record from an archivista archive table

=cut

sub delete {
  my $self = shift;
	my ($condField,$condValue,$table) = @_;
	my ($doc,$arch,$lock,$own,$pages,$delok,@row,@flds);
  $self->_checkTable(\$table);
  return 0 if $self->isArchivistaInternalTable($table);
	if ($table eq $self->TABLE_DOCS && $self->archivistadb) {
    return 0 if $self->user->checkAddDeleteRecordRights==0; # check for rights
  	$self->_initAddOwnerPublish($condField,$condValue);
		my $ptest = [$self->FLD_DOC,$self->FLD_PAGES,
		             $self->FLD_ARCHIVED,$self->FLD_LOCKED,$self->FLD_OWNER];
		my @flds=$self->select($ptest,$condField,$condValue,$table);
		$doc=$flds[0];
		$pages=$flds[1];
		$arch=$flds[2];
		$lock=$flds[3];
		$own=$flds[4];
		$delok=1;
		if ($doc>0 && $arch==0 && ($lock eq "" || $lock eq $self->lockuser)) {
		  $delok=1;
		}
		if ($delok==1) {
		  # can we delete this record?
		  $delok=$self->user->checkUpdateRights($own);
			if ($delok==1) {
			  # is this record locked?
				my $user=$self->_isLocked($doc);
				if ($user eq "") {
		      $delok=$self->_lock($doc,$self->lockuser);
				} elsif ($user eq $self->lockuser) {
				  $delok=1;
				}
				if ($delok==1) {
		      my $from=0;
		      $from=1 if $pages>0;
		      #delete images acording to document (changes table)
		      $delok=$self->_pagesDeleteFromTo($doc,$from,$pages);
				}
			}
		}
	} else {
	  $delok=1; # not in table TABLE_DOCS
	}
	if ($delok) {
    @row=$self->SUPER::delete($condField,$condValue,$table);
	} else {
	  $self->setTable($table);
	}
	return $row[0];
}






# internal archivista tables
#
sub isArchivistaInternalTable {
  my $self = shift;
	my ($table) = @_;
  my $ret;
  if ($self->archivistadb) {
	  $ret=1 if ($table eq $self->TABLE_IMAGES ||
		           $table eq $self->TABLE_PAGES ||
				       $table eq $self->TABLE_PARAMETER ||
				       $table eq $self->TABLE_USER);
	}
}






=head1 $rec=key([$key,$table])

Activate record with $key in $table or gives back just key (without key)

=cut

sub key {
  my $self = shift;
	my ($key,$table) = @_;
  my @record;
  return $self->keyvalue if !defined $key; # give back the current key (getter method)
  $self->_checkTable(\$table);
	if ($self->archivistadb && $table eq $self->TABLE_DOCS) {
	  $key=$self->select($self->FLD_DOC,$self->FLD_DOC,$key,$table);
	} else {
	  @record=$self->SUPER::key($key,$table);
		$key=$record[0];
	}
	return $key;
}






=head1 @keys=keys($pfields,$pvals,[$table])

Gives back all keys in an array  from a range of records. Please
have a look at search about the format to use.

=cut

sub keys {
  my $self = shift;
	my ($pfields,$pvals,$table) = @_;
  $self->_checkTableArchive($pfields,$pvals,\$table);
	my @keys=$self->SUPER::keys($pfields,$pvals,$table);
	return @keys;
}






=head1 $ok=isArchivistaDB([$dbname,$log])

Does a check if it is an archivista database (and logs it if wished)

=cut

sub isArchivistaDB {
  my $self = shift;
	my ($dbname,$log) = @_;
  $dbname=$self->dbDatabase if $dbname eq '';
  my $val=$self->PAR_AVVERSION;
	my $ver=$self->getParameter($val,$self->TABLE_PARAMETER,$dbname);
  my $message = "Sorry, no archivista database";
	if ($ver>=$self->avversion) {
    $message = "Archivista database found";
		if ($self->dbDatabase eq $dbname) {
		  $self->archivistadb(1);
			if ($self->dbDatabase eq $self->DB_DEFAULT) {
			  $self->archivistamain(1);
				$message .= "-- main";
			} else {
			  $self->archivistamain(0);
			}
		}
	} else {
	  if ($self->dbDatabase eq $dbname) {
		  $self->archivistadb(0);
			$self->archivistamain(0);
		}
  }
  $self->logMessage($message) if $log>0;
	if ($ver>=$self->avversion) {
	  $ver=1;
	} else {
	  $ver=0;
	}
  return $ver;
}






=head1 $ok=isArchivistaMain

Give back if the current db is the main Archivista database

=cut

sub isArchivistaMain {
  my $self = shift;
  return $self->archivistamain;
}






=head1 $ok=isArchivista 

Give back if the current db is an Archivista database

=cut

sub isArchivista {
  my $self = shift;
  return $self->archivistadb;
}






=head1 $pav=getDatabasesArchivista

Gives back an array with all archivista databases

=cut

sub getDatabasesArchivista {
  my $self = shift;
  my @av=$self->SUPER::getDatabases();
	my @out=();
	my $c=0;
	foreach (@av) {
	  my $db = $_;
		if ($self->isArchivistaDB($db)) {
		  push @out,$db;
		  $c++;
		}
	}
	return @out;
}






=head1 $countrec=count($pfields,$pvals,[$table])

Gives back the number of records from a range of records.

=cut

sub count {
  my $self = shift;
	my ($pfields,$pvals,$table) = @_;
  $self->_checkTableArchive($pfields,$pvals,\$table);
	return $self->_searchOne($self->SEARCH_COUNT,"",$pfields,$pvals,$table);
}







=head1 $minvalue=min($testsearch,$pfields,$pvals,[$table])

Gives back the minimal value from a range of records.

=cut

sub min {
  my $self = shift;
	my ($search,$pfields,$pvals,$table) = @_;
  $self->_checkTableArchive($pfields,$pvals,\$table);
	return $self->_searchOne($self->SEARCH_MIN,$search,$pfields,$pvals,$table);
}







=head1 $maxvalue=max($testfield,$pfields,$pvals,[$table])

Gives back the maximal value from a range of records.

=cut

sub max {
  my $self = shift;
	my ($search,$pfields,$pvals,$table) = @_;
  $self->_checkTableArchive($pfields,$pvals,\$table);
	return $self->_searchOne($self->SEARCH_MAX,$search,$pfields,$pvals,$table);
}






=head1 $sumvalue=sum($testfield,$pfields,$pvals,[$table])

Gives back the sum value from a range of records.

=cut

sub sum {
  my $self = shift;
	my ($search,$pfields,$pvals,$table) = @_;
  $self->_checkTableArchive($pfields,$pvals,\$table);
	return $self->_searchOne($self->SEARCH_SUM,$search,$pfields,$pvals,$table);
}






=head1 $pages=selectPage($page,$pfields)

Gives back fields from a given page

=cut

sub selectPage {
  my $self = shift;
	my ($page,$pfields) = @_;
  return $self->_selectPage($page,$pfields);
}






=head1 $ok=addPage($pfields,$pvals)

Add a page to a selected (NOT ARCHIVED) document

=cut

sub addPage {
  my $self = shift;
	my ($pfields,$pval) = @_;
  return $self->_addPage($pfields,$pval);
}






=head1 $ok=updatePage($page,$pfields,$pvals)

Update a page in a selected document. Some of the fields can be
updated only as long as the document is NOT YET archived, other
fields can updated (changed) all the time.

=cut

sub updatePage {
  my $self = shift;
	my ($page,$pfields,$pvals) = @_;
  return $self->_updatePage($page,$pfields,$pvals);
}






=head1 $ok=deletePage

Delete the last page of an archivista document

=cut

sub deletePage {
  my $self = shift;
  return $self->_deletePage;
}







=head1 $ok=lock([$doc],$lockuser)

Locks a document to a given user (only for archive table)

=cut

sub lock {
  my $self = shift;
	my ($doc,$lockuser) = @_;
  return $self->_lock($doc,$lockuser);
}






=head1 $ok=unlock([$doc])

Unlocks a document (only for archive table)

=cut

sub unlock {
  my $self = shift;
  my ($doc) = @_;
  return $self->_lock($doc,'');
}






# LOCK/UNLOCK a document
#
sub _lock {
  my $self = shift;
  my ($doc,$user) = @_;
  $doc=$self->keyvalue if !defined($doc);
  $user=$self->_quote($user);
  my $sql = $self->SQL_UPDATE.$self->TABLE_DOCS.
	          $self->SQL_SET.$self->FLD_LOCKED.'='.$user.
	          $self->SQL_WHERE.$self->FLD_DOC.'='.$doc;
	return $self->_setRows($sql);
}






=head1 $ok=isNotLocked([$doc])

Checks if a document is NOT locked and gives back 1 (success)

=cut

sub isNotLocked {
  my $self = shift;
  my ($doc) = @_;
  my $res;
  my $user=$self->_isLocked($doc);
	$res=1 if $user eq "";
	return $res;
}






=head1 $user=isLocked([$doc])

Checks if a doc is locked

=cut

sub isLocked {
  my $self = shift;
  my ($doc) = @_;
  my $user=$self->_isLocked($doc);
	return $user;
}






# give back the lock user of a document
#
sub _isLocked {
  my $self = shift;
  my ($doc) = @_;
  $doc=$self->keyvalue if !defined($doc);
  my $user;
  my $sql = $self->SQL_SELECT.$self->FLD_LOCKED.','.$self->FLD_DOC.
	          $self->SQL_FROM.$self->TABLE_DOCS.$self->SQL_WHERE.
						$self->FLD_DOC.'='.$doc;
	my @row=$self->_getRow($sql);
	$user=$row[0] if $row[1]==$doc;
	return $user;
}






=head1 $def=getScanDefByNumber($scanid)

Read a scan definition by its number and gives back the string

=cut

sub getScanDefByNumber {
  my $self = shift;
  my ($scanid) = @_;
  my ($scandef,@scannen);
  # read the scan definitions from the database
  $scandef = $self->getParameter($self->PAR_SCANDEFS);
  @scannen = split( "\r\n", $scandef );
  $scanid = $scannen[0] if $scannen[$scanid] eq "";
	$self->scanid($scanid);
	$self->scandef($scannen[$self->scanid]);
	$self->scan(AVScan->new($scannen[$self->scanid]));
  return $scannen[$scanid];
}






=head1 $scandef=getScanDefByName($scanname)

Read scan definition from the database and gives back scandef

=cut

sub getScanDefByName {
  my $self = shift;
  my ($scanname) = @_;
  my ($scandef,@scannen,@scanval,$scanid,$c);
  # read the scan definitions from the database
  $scandef = $self->getParameter($self->PAR_SCANDEFS);
  @scannen = split( "\r\n", $scandef );
  # give back the first definition in case we don't find it
  $scanid = 0;
  $c = 0;
  foreach (@scannen) {
    # go through all definitions
    @scanval = split( ";", $_ );
    if ( $scanval[0] eq $scanname ) {
      $scanid = $c;
    }
    $c++;
  }
	$self->scanid($scanid);
	$self->scandef($scannen[$self->scanid]);
	$self->scan(AVScan->new($scannen[$self->scanid]));
  return $scannen[$scanid];
}






=head1 $scandef=getScanDef

Give back the current select scan definitions 

=cut

sub getScanDef {
  my $self = shift;
  return $self->scandef;
}







=head1 $id=getScanId 

Give back current ScanId number (line number in scan definitions)

=cut

sub getScanId {
  my $self = shift;
  return $self->scanid;
}






=head1 $value=getScanParameter($nr)

Give back the value $nr from the current scan definitions

=cut

sub getScanParameter {
  my $self = shift;
  my ($nr) = @_;
  $self->getScanDefByNumber(0) if $self->scandef eq "";
  my @scan = split(";",$self->scandef);
	my $val = $scan[$nr];
	if ($nr == $self->SCAN_DPI) { 
	  if ($val<72 || $val>9600) {
		  $val=300;
		  $val=150 if ($self->SCAN_TYPE<1 || $self->SCAN_TYPE>2);
		}
	}
	return $val;
}






=head1 $res=getParameterBox($val,$min,$max,$def)

Read a BOX value form the parameter table and give it back as string

=cut

sub getParameterBox {
  my $self = shift;
  my ($val,$min,$max,$def) = @_;
	my $res = $self->getParameter($val,$self->PAR_AVBOX);
	$res=$def if ($res<$min || $res>$max);
	return $res;
}






=head1 $res=getParameter($val,[$type,$db])

Reads a value from the parameter table and gives it back as a string

=cut

sub getParameter {
  my $self = shift;
  my ($val,$type,$db) = @_;
	$type=$self->TABLE_PARAMETER if $type eq "";
	$db=$self->dbDatabase if $db eq "";
  my $sql = $self->SQL_SELECT.$self->FLD_PAR_VALUE.','.$self->FLD_RECORD.
	          $self->SQL_FROM.$db.'.'.$self->TABLE_PARAMETER.
						$self->SQL_WHERE.$self->FLD_PAR_TYPE.
						$self->SQL_LIKE.$self->_quote($type).
						$self->SQL_AND.$self->FLD_PAR_NAME.
						$self->SQL_LIKE.$self->_quote($val);
  my @row = $self->_getRow($sql);
	if ($row[1]>0) { # there was a record found, so set parid value
	  $self->parid($row[1]);
	} else {
	  $self->parid(0);
	}
	return $row[0];
}






=head1 $record=getParameterId

Gives back the last returned record from getParameter 
ATTENTION: return value points to the db that was used with getParameter

=cut

sub getParameterId {
  my $self = shift;
  return $self->parid;
}






=head1 $res=setParameter($id,$val,[$type,$db])

Update the $val in the parameter table according the $id

=cut

sub setParameter {
  my $self = shift;
  my ($id,$val,$type,$db) = @_;
  my $res;
	$type=$self->TABLE_PARAMETER if $type eq "";
	$db=$self->dbDatabase if $db eq "";
	if ($id>0) {
    my $sql = $self->SQL_UPDATE.$db.'.'.$self->TABLE_PARAMETER.
	            $self->SQL_SET.$self->FLD_PAR_VALUE.'='.$self->_quote($val).
	            $self->SQL_WHERE.$self->FLD_RECORD=$id;
		$res=$self->_setRow($sql);
	}
	return $res;
}






=head1 ($sql,$start,$ende)=getSQLrange($range)

Gives back an sql fragment either 'and Laufnummer=x' or
'and Laufnummer between x and y' and start/end document

=cut

sub getSQLrange {
  my $self = shift;
  my ($self1) = @_;
  my ($sql,$x,$y,$start,$ende);

  # check if we only have one document or several documents
  $self1=~/^(\d+)(-*)(\d*)/;
  $x=$1;
  $y=$3;
 
  if ($y != ''){
    $sql = $self->SQL_AND.$self->FLD_DOC.$self->SQL_BETWEEN.$x.$self->SQL_AND.$y.
		       $self->SQL_EMPTY if ($y>0 && $y>$x);
  } else {
    $sql = $self->SQL_AND.$self->FLD_DOC.'='.$x.$self->SQL_EMPTY if ($x>0);
  }
	$start=$x if $x>0;
	$ende=$x if $x>0;
	$ende=$y if $y>0;
  return ($sql,$start,$ende); 
}






=head1 ($doc,$pag,$folder,$typ)=getNextFreeDocument($aktnr,$desc,$sql)

Gives back the next free document we can process

=cut

sub getNextFreeDocument {
  my $self = shift;
  my ($aktnr,$desc,$sqladd) = @_;
  # compose base framgent
  my $sql=$self->SQL_SELECT.$self->FLD_DOC.','.
	        $self->FLD_PAGES.','.$self->FLD_FOLDER.','.
					$self->FLD_TYPE.$self->SQL_FROM.$self->TABLE_DOCS.
					$self->SQL_WHERE.$self->FLD_LOCKED."=''".$self->SQL_EMPTY;
	# add an additional part (if available)
	$sql .= $sqladd if ($sqladd ne "");
  if ($desc) {
	  # calcluate last document
		$sql.=$self->SQL_AND.$self->FLD_DOC."<=$aktnr".
		      $self->SQL_ORDER.$self->FLD_DOC.$self->SQL_DESC.$self->SQL_EMPTY;
	} else {
	  # calculate first document
		$sql.=$self->SQL_AND.$self->FLD_DOC.">=$aktnr".
		      $self->SQL_ORDER.$self->FLD_DOC.$self->SQL_EMPTY;
	}
	# we only want 1 document
	$sql.=$self->SQL_LIMIT1;
	# do the sql command
  my ($akte,$seiten,$ordner,$art) = $self->_getRow($sql);
	return ($akte,$seiten,$ordner,$art);
}






=head1 $newdb=setDatabase($db)

Sets a new database (resets parameter, here parid)

=cut

sub setDatabase {
  my $self = shift;
  my ($db) = @_;
  my @res=$self->SUPER::setDatabase($db);
	$self->_initValuesArchivista;
	return $res[0];
}






# internal function to get fields back from a document
#
sub _selectPage {
  my $self = shift;
  my ($page,$pfields) = @_;
  my ($res,$pagekey,@row,@row1,@row2,@fimg,@fold);
  my ($update,$pages,$arch,$doc)=$self->_initPageUpdate;
	if ($pages>=$page) {
    if (ref($pfields) ne "ARRAY") {
		  my @flds = $pfields;
			$pfields = \@flds;
	  }
		$pagekey=($doc*1000)+$page;
    @fold = @$pfields; # hold the old fields
    my $c=0;
	  foreach (@$pfields) {
	    # we check for fields we accept
	    my $fld=$_;
		  # this fields are for archivseiten table TABLE_PAGES
		
	   	if ($fld eq $self->FLD_TEXT || $fld eq $self->FLD_OCR || 
 		      $fld eq $self->FLD_OCR_EXCLUDE || $fld eq $self->FLD_OCR_DONE) {
        push @fimg,$fld;
		    $$pfields[$c]='';
	    } elsif ($fld ne $self->FLD_IMG_INPUT && $fld ne $self->FLD_IMG_IMAGE &&
               $fld ne $self->FLD_IMG_HIGH && $fld ne $self->FLD_IMG_SOURCE &&
               $fld ne $self->FLD_IMG_X && $fld ne $self->FLD_IMG_Y && 
		   		     $fld ne $self->FLD_IMG_AX && $fld ne $self->FLD_IMG_AY) {
			  # if the fields are not for archivbilder, kill them
			  $$pfields[$c]='';
			}
		  $c++;
	  }
		
	  my $found=1;
	  while ($found==1) {
	    # kill the fields as long as we can find some
	    $found=0;
		  my $c=0;
	    foreach (@$pfields) {
		    if ($_ eq '') {
		      splice @$pfields,$c,1;
			    $found=1;
			    last;
		    }
		    $c++;
			}
	  }

	  my $res=-1;
	  if ($fimg[0] ne "") {
	    # select TABLE_PAGES
	    @row1=$self->SUPER::select(\@fimg,$self->FLD_PAGE,
			                           $pagekey,$self->TABLE_PAGES);
	  }
	  if ($$pfields[0] ne "" && $res!=0) {
	    # update TABLE_IMAGES
	    @row2=$self->SUPER::select($pfields,$self->FLD_PAGE,
			                           $pagekey,$self->TABLE_IMAGES);
	  }

    $c=0;
		foreach (@fold) {
		  # copy the fields to the final row
		  my $fld=$_;
			my $c1=0;
			foreach (@fimg) {
			  if ($_ eq $fld) {
				  $row[$c]=$row1[$c1];
					last;
				}
				$c1++;
			}
			$c1=0;
			foreach (@$pfields) {
			  if ($_ eq $fld) {
				  $row[$c]=$row2[$c1];
					last;
				}
				$c1++;
			}
			$c++;
		}
    $self->_updateBackToArchiv($doc);
		my $single=1;
		$single=0 if $c>1;
		
		if ($single==1) {
		  return $row[0];
		} else {
		  return @row;
		}
	}
	return 0;
}






# set back the pointer to table TABLE_DOC
#
sub _updateBackToArchiv {
  my $self = shift;
  my ($doc) = @_;
  $self->table($self->TABLE_DOCS);
	$self->keyfield($self->FLD_DOC);
	$self->keyvalue($doc);
}






# internal function to delete a page
#
sub _deletePage {
  my $self = shift;
  my ($res);
  my ($update,$pages,$arch,$oldkey)=$self->_initPageUpdate;
  if ($update) {
	  if ($pages>0) {
      my $user=$self->_isLocked($self->keyvalue);
		  $res=$self->_pagesDeleteFromTo($oldkey,$pages,$pages);
		}
	}
	return $res;
}






# internal function to update values in TABLE_PAGES and/or TABLE_IMAGES
#
sub _updatePage {
  my $self = shift;
  my ($page,$pfields,$pvals) = @_;
  my ($res);
  my ($update,$pages,$arch,$oldkey)=$self->_initPageUpdate;
  if ($update) {
	  if ($page>=0 && $page<=$self->DOC_MAXPAGES) {
      my $user=$self->_isLocked($self->keyvalue);
	    if ($user eq $self->lockuser) {
	      $self->_lock($self->keyvalue,$self->lockuser);
				$res=$self->_updatePageDoIt($oldkey,$page,$arch,$pfields,$pvals);
			}
		}
	}
	return $res;
}







# add values to TABLE_IMAGES and/or TABLE_PAGES
#
sub _addPage {
  my $self = shift;
  my ($pfields,$pvals) = @_;
  my ($res,$page);
  my ($update,$pages,$arch,$doc)=$self->_initPageUpdate;
  if ($update) {
	  $page=$pages+1;
		if ($page<=$self->DOC_MAXPAGES) {
      my $user=$self->_isLocked($self->keyvalue);
	    if ($user eq $self->lockuser || $user eq "") {
		    $self->_lock($self->keyvalue,$self->lockuser);
	      my $pagekey = ($doc*1000)+$page;
			  my $sql=$self->SQL_INSERT.$self->TABLE_IMAGES.
				        $self->SQL_SET.$self->FLD_PAGE.'='.$pagekey;
			  $res=$self->_setRows($sql);
			  if ($res) {
			    $sql=$self->SQL_INSERT.$self->TABLE_PAGES.
					     $self->SQL_SET.$self->FLD_PAGE.'='.$pagekey;
				  $res=$self->_setRows($sql);
				} else {
				  my $sql=$self->SQL_DELETE.$self->TABLE_IMAGES.
					        $self->SQL_WHERE.$self->FLD_PAGE.'='.$pagekey;
					$self->_setRow($sql,$self->TABLE_IMAGES);
				}
				if ($res) {
				  $res=$self->_updatePagesAdjustNumber($doc,$page);
					if ($res) {
				    $res=$self->_updatePageDoIt($doc,$page,$arch,$pfields,$pvals);
					}
				}
	      #$self->SUPER::key($doc,TABLE_DOCS) if $res==0; # select old key in TABLE_DOC
			}
		}
	}
	return $res;
}






# adjust the number of pages of a document
#
sub _updatePagesAdjustNumber {
  my $self = shift;
  my ($doc,$pages) = @_;
	my $pfld=[$self->FLD_PAGES,$self->FLD_ADDED];
	my $added=0;
	$added=1 if $pages>0;
	my $pval=[$pages,$added];
	my $res=$self->SUPER::update($pfld,$pval,$self->FLD_DOC,
	                             $doc,$self->TABLE_DOCS);
	return $res;
}
	





# update fields in TABLE_IMAGES and TABLE_PAGES according $doc and $page
#
sub _updatePageDoIt {
  my $self = shift;
  my ($doc,$page,$arch,$pfields,$pvals) = @_;
	my (@fimg,@vimg,$c,$pagekey,$res);
	($pfields,$pvals)=$self->_initFieldsVals($pfields,$pvals);
	$pagekey=($doc*1000)+$page;

  $c=0;
	foreach (@$pfields) {
	  # we check for fields we accept
	  my $fld=$_;
		# this fields are for archivseiten table TABLE_PAGES
		
		if ($fld eq $self->FLD_TEXT || $fld eq $self->FLD_OCR || 
 		    $fld eq $self->FLD_OCR_EXCLUDE || $fld eq $self->FLD_OCR_DONE) {
      push @fimg,$fld;
      push @vimg,$$pvals[$c];
			$$pfields[$c]='';
	  } elsif ($fld ne $self->FLD_IMG_INPUT && $fld ne $self->FLD_IMG_IMAGE &&
            $fld ne $self->FLD_IMG_HIGH && $fld ne $self->FLD_IMG_SOURCE &&
            $fld ne $self->FLD_IMG_X && $fld ne $self->FLD_IMG_Y && 
						$fld ne $self->FLD_IMG_AX && $fld ne $self->FLD_IMG_AY) {
			# if the fields are not for archivbilder, kill them
			$$pfields[$c]="";
		} elsif ($arch==1 && $fld eq $self->FLD_IMG_INPUT) {
		  $$pfields[$c]="";
		}
		$c++;
  }

	my $found=1;
	while ($found==1) {
	  # kill the fields as long as we can find some
	  $found=0;
		my $c=0;
	  foreach (@$pfields) {
		  if ($_ eq '') {
			  splice @$pfields,$c,1;
				$found=1;
				last;
			}
		  $c++;
		}
	}

	$res=-1;
	if ($fimg[0] ne "") {
	  # update TABLE_PAGES
	  $res=$self->SUPER::update(\@fimg,\@vimg,$self->FLD_PAGE,
		                  $pagekey,$self->TABLE_PAGES);
	}
	if ($$pfields[0] ne "" && $res!=0) {
	  # update TABLE_IMAGES
	  $res=$self->SUPER::update($pfields,$pvals,$self->FLD_PAGE,
		                  $pagekey,$self->TABLE_IMAGES);
	}
  $self->_updateBackToArchiv($doc);
	return $res;
}






# check if we can update a certain page, gives back the page or 0
#
sub _initPageUpdate {
  my $self = shift;
  my ($table) = @_;
	my ($doc,$arch,$lock,$own,$pages,$update,$oldkey);
	if ($self->keyvalue>0) {
	  $oldkey=$self->keyvalue; # hold the old document number
		$table=$self->TABLE_DOCS if $self->table eq $self->TABLE_DOCS;
	}
  #$self->_checkTable(\$table);
	if ($table eq $self->TABLE_DOCS && $self->archivistadb && $self->keyvalue>0) {
    return 0 if $self->user->checkAddDeleteRecordRights==0; # check for rights
		my $ptest = [$self->FLD_DOC,$self->FLD_PAGES,$self->FLD_ARCHIVED,
		             $self->FLD_LOCKED,$self->FLD_OWNER];
		my @flds=$self->SUPER::select($ptest,$self->FLD_DOC,$oldkey);
		$doc=$flds[0];
		$pages=$flds[1];
		$arch=$flds[2];
		$lock=$flds[3];
		$own=$flds[4];
		if ($doc>0 && $arch==0 && ($lock eq $self->lockuser || $lock eq '')) {
		  # can we delete this record?
		  $update=$self->user->checkUpdateRights($own);
		}
	}
	return ($update,$pages,$arch,$oldkey);
}






# delete all pages from archivbilder,archivseiten, given a doc/page
#
sub _pagesDeleteFromTo {
  my $self = shift;
  my ($doc,$from,$pages) = @_;
  my ($res);
  return 0 if $from<0 or $from>$self->DOC_MAXPAGES; # outside range, don't do it
	return 0 if $pages<0 or $pages>$self->DOC_MAXPAGES; # " don't do it
	return 0 if $from>$pages; # not possible, don't do it
	$pages=$from if $pages==0; # adjust pages (if there is nothing
  my ($done);
	if ($pages>0) {
    my $user=_isLocked($doc);
		if ($user eq "") {
	    $res=$self->_lock($doc,$self->lockuser);
		} elsif ($user eq $self->lockuser) {
      $res=1;
		}
		if ($res) {
      my $start = ($doc*1000)+$from;
	    my $end = ($doc*1000)+$pages;
	    $done=$self->SUPER::delete('~'.$self->FLD_PAGE,$start.'-'.$end,
			                   $self->TABLE_PAGES);
	    if ($done==1) {
	      $done=$self->SUPER::delete('~'.$self->FLD_PAGE,$start.'-'.$end,
				                   $self->TABLE_IMAGES);
			}
		}
    $self->_updateBackToArchiv($doc);
		if ($done) {
	    my $newpages=$pages-$from;
		  if ($newpages>=0) {
	      $done=$self->_updatePagesAdjustNumber($doc,$newpages);
		  } else {
		    $done=0;
		  }
	  }
	} else {
	  $done=1;
	}
  return $done;
}






=head1 $id=addJob($user,$type,$val,[$val2])

Add a jobs to the jobs table with 1 or (optional) 2 parameters 
given by an $user object and a type

=cut

sub addJob {
  my $self = shift;
  my ($user,$type,$val,$val2) = @_;
  my ($ok,$ok2,$ok3,$id,$name,$name2);
	return 0 if !$self->isArchivistaMain; # only main db
	return 0 if !$user->checkAddDeleteRecordRights; # have we rights?
  my $sql = $self->SQL_INSERT.$self->TABLE_JOBS.$self->SQL_SET.
	          $self->FLD_JOBHOST.'='.$self->_quote($user->host).','.
						$self->FLD_JOBDB.'='.$self->_quote($user->database).','.
						$self->FLD_JOBUSER.'='.$self->_quote($user->user).','.
						$self->FLD_JOBPWD.'='.$self->_quote($user->password).','.
						$self->FLD_JOBTYPE.'='.$self->_quote($type).','.
						$self->FLD_JOBSTATUS.'=100';
  $ok=$self->_setRows($sql);
	if ($ok) {
	  $sql=$self->SQL_INSERT_LAST;
    my @row=$self->_getRow($sql);
		$id=$row[0];
		if ($id) {
	    if ($type eq $self->JOB_SANE) {
			  $name=$self->PAR_JOBSCANDEF;
				$name2=$self->PAR_JOBSCANDOC;
		  } else {
			  $name=$self->PAR_JOBSCANFILE;
			}
		  $sql=$self->SQL_INSERT.$self->TABLE_JOBSDATA.$self->SQL_SET.
			$self->FLD_JOBIDLINK.'='.$id.','.$self->FLD_JOBPARAM.'='.
			$self->_quote($name).','.$self->FLD_JOBVALUE.'='.$self->_quote($val);
			$ok2=$self->_setRows($sql);
			if ($ok2 && $val2) {
		    $sql=$self->SQL_INSERT.$self->TABLE_JOBSDATA.$self->SQL_SET.
			  $self->FLD_JOBIDLINK=$id.','.$self->FLD_JOBPARAM.'='.
			  $self->_quote($name2).','.$self->FLD_JOBVALUE.'='.$self->_quote($val2);
				$ok3=$self->_setRows($sql);
			}
		}
	}
	return $id;
}





=head1 $jid=getJob

Gives back the next available job and marks it working in progress...

=cut

sub getJob {
  my $self = shift;
  my ($sql,$found,$ok,$rec);
	return 0 if !$self->isArchivistaMain; # only main db
	
	while ($found==0 && $rec==0) {
    $sql = $self->SQL_SELECT.$self->FLD_JOBID.$self->SQL_FROM.$self->TABLE_JOBS.
	         $self->SQL_WHERE.$self->FLD_JOBSTATUS.'=100'.
	         $self->FLD_ORDER.$self->FLD_JOBTYPE;
	  $rec=$self->_getRow($sql);
	
	  if ($rec>0) {
	    $sql=$self->SQL_UPDATE.$self->TABLE_JOBSDATA.
		       $self->SQL_SET.$self->FLD_JOBSTATUS.'=110'.$self->SQL_WHERE.
			     $self->FLD_JOBID.'='.$rec.$self->SQL_AND.$self->FLD_JOBSTATUS.'=100';
		  $ok=$self->_setRow($sql);
			$found=1 if $ok;
	  }
	}
	return $rec;
}







=head1 $ok=updateJob($pfields,$pvals)

Updates a job an gives back 0=not done, 1=done

=cut

sub updateJob {

}






=head1 $ok=deleteJob 

Delete a job

=cut

sub deleteJob {

}






=head1 $lid=addLog

Adds a log entry

=cut

sub addLog {

}






=head1 @row=selectLog 

Selects a log entry

=cut

sub selectLog {

}






=head1 $ok=updateLog

Updates a log entry

=cut

sub updateLog {

}






=head1 $ok=deleteLog

Deletes a log entry

=cut

sub deleteLog {

}






=head1 Class wide constants for AVDocs

DB_DEFAULT (default db name)

Tables in archivista dbs:
TABLE_DOCS
TABLE_PAGES
TABLE_IMAGES
TABLE_PARAMETER
TABLE_USER
TABLE_JOBS
TABLE_JOBSDATA
TABLE_LOGS
TABLE_MENUS
TABLE_LANGUAGES
TABLE_FIELDLISTS
TABLE_ARCHIVESLIST
TABLE_ABREVIATIONS
TABLE_SESSIONWEB
TABLE_SESSION
TABLE_SESSIONS
TABLE_SESSIONDATA

Field names in archive:
FLD_DOC
FLD_PAGES
FLD_TYPE
FLD_OWNER
FLD_TITLE
FLD_NOTE
FLD_DATE
FLD_DATE_ADDED
FLD_FOLDER
FLD_ADDED
FLD_ARCHIVED
FLD_FILENAME
FLD_LOCKED
FLD_INPUT_ON
FLD_INPUT_EXT
FLD_IMAGE_ON
FLD_IMAGE_EXT
FLD_SOURCE_ON
FLD_SOURCE_EXT
FLD_USERADDED_NAME
FLD_USERADDED_TIME
FLD_USERMOD_NAME
FLD_USERMOD_TIME

Normally used key field:
FLD_RECORD

Fields for ...Page functions
FLD_IMG_INPUT
FLD_IMG_IMAGE
FLD_IMG_HIGH
FLD_IMG_SOURCE
FLD_IMG_PAGE
FLD_IMG_X
FLD_IMG_Y
FLD_IMG_AX
FLD_IMG_AY

FLD_PAGE
FLD_TEXT
FLD_OCR
FLD_OCR_EXCLUDE
FLD_OCR_DONE

Fields for log table:
FLD_LOGFILE
FLD_LOGPATH
FLD_LOGTYPE
FLD_LOGDATE
FLD_LOGHOST
FLD_LOGDB
FLD_LOGUSER
FLD_LOGPWD
FLD_LOGOWNER
FLD_LOGPAPERSIZE
FLD_LOGPAGES
FLD_LOGWIDTH
FLD_LOGHEIGHT
FLD_LOGRESX
FLD_LOGRESY
FLD_LOGBITS
FLD_LOGFORMAT
FLD_LOGDOC
FLD_LOGTIME
FLD_LOGDONE
FLD_LOGERROR
FLD_LOGID

Fields for jobs/jobs_data table:
FLD_JOBID
FLD_JOBTYPE
FLD_JOBHOST
FLD_JOBDB
FLD_JOBUSER
FLD_JOBPWD
FLD_JOBTIMEMOD
FLD_JOBTIMEADD
FLD_JOBSTATUS
FLD_JOBERROR
FLD_JOBIDLINK
FLD_JOBPARAM
FLD_JOBVALUE

PAR_JOBSCANDEF
PAR_JOBSCANDOC
PAR_JOBFILE

Constants for archive table:
DOC_TYPE_BMP
DOC_TYPE_TIF
DOC_TYPE_PNG
DOC_TYPE_JPG
DOC_EXT_BMP

DOC_EXT_TIF
DOC_EXT_PNG
DOC_EXT_JPG
DOC_MAXPAGES

Parameter constants:
PAR_SCANDEFS
PAR_AVVERSION
PAR_AVBOX
PAR_PUBLISHFIELD
PAR_FOLDER
PAR_PUBLISHALL
PAR_QUALITYJPG

User constants:
USER_SYSOP
USER_ROOT
USER_LOCALHOST

Constants for scan definitions:
SCAN_NAME
SCAN_TYPE
SCAN_DPI
SCAN_WITH
SCAN_HEIGHT
SCAN_LEFT
SCAN_TOP
SCAN_ROTATION
SCAN_POSTPROCESSIONG
SCAN_SPLITPAGE
SCAN_OCR
SCAN_ADF
SCAN_WAIT
SCAN_PAGES
SCAN_BRIGHTNESS
SCAN_CONTRAST
SCAN_GAMMA
SCAN_NEWDOC
SCAN_DESKEW
SCAN_CLEAN
SCAN_BORDERREMOVE
SCAN_NOTDEFINED
SCAN_SLEEPBEFORE
SCAN_SCANNERADDRESS
SCAN_EMPTYPAGES
SCAN_BWOPTIMIZEON
SCAN_BWOPTIMIZERADIUS
SCAN_BWOUTPUTDPI
SCAN_BWAUTOFIELDS
SCAN_BARCODEDEF

=cut









# must be
1;



