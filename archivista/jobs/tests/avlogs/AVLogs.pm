use reform;
use strict;

use lib qw(/home/cvs/archivista/jobs);

package AVLogs < AVDocs;


fields logfields;

sub initialize ($host,$db,$user,$pw) {
  base->initialize($host,$db,$user,$pw);
  if (self->isArchivistaMain) {
	  my $table=self->setTable(self->TABLE_LOGS);
	  foreach(self->fieldnames) {
      my $fname = $_;
		  self->add_field($fname);
	  } 
	} else {
	  self->logMessage("$db is not main database!");
		return 0;
	}
}







sub _getlog {
	foreach (self->fieldnames(self->TABLE_LOGS)) {
	  my $f = $_;
	  my $entry = self->select($f,
	                           self->FLD_LOGID,
			  									   self->ID,
				  								   self->TABLE_LOGS);
		self->$f = $entry;
	}
}







=head1 

if there is no previously selected log entry use the first log
FIFO.

=cut

sub _checklog {
  if (self->ID eq "") {
	  self->ID = self->min(self->FLD_LOGID) || return 0;
	} else {
    return 1;
	}
}






=head1 @select = selectlog([$id])

gives back an array of the desired log entry and 
changes to this entry. Or selects the current 
log entry without $id.

=cut

sub selectlog ($id) {
  self->ID = $id;
  self->_checklog;
	self->_getlog;
  my @select;
	foreach (self->fieldnames(self->TABLE_LOGS)) {
		push @select,self->$_;
	}
	return @select;
}




sub newselectlog ($pfields,$pwfields,$pwvals) {
  my @select = self->select($pfields,$pwfields,$pwvals);
	self->ID = self->select(self->FLD_LOGID);
	return @select;
}





=head1 $ok = updatelog($pfields,$pvals,[$id])

Updates Fields, which are given in a pointer to an array,
to Values, which are given too in a pointer to an array.
Returns 1 if updating was a success. 

(Returns some strange value if update fails aug,19 2005)

=cut

sub updatelog ($pfields,$pvals,$id) {
  self->ID = $id;
  self->_checklog;
  $pfields = self->_checkfields($pfields);
	$pvals = self->_checkvals($pfields,$pvals);
	my $ok = self->update($pfields,$pvals);
  return $ok;
}






=head1 $ok = deletelog([$id])

deletes log with FLD_LOGID $id or without $id
deletes the current log entry. Returns success of the procedure.

=cut

sub deletelog ($id) {
  self->ID = $id;
	self->_checklog;
	my $ok = self->delete;
	return $ok
}






=head1 $record = addlog($pfields,$pvals)

add a log entry with $pvals in $pfields and return it

=cut

sub addlog ($pfields,$pvals) {
  self->setTable(self->TABLE_LOGS);
	my $record;
	if (self->_checkfields($pfields)) {
	  if (self->_checkvals($pfields,$pvals)) {
      $record = self->add($pfields,$pvals);
		}
	}
	return $record;
}





sub _checkfields ($pfields) {
  my $notfound=0;
  my @f2 = self->fieldnames;
  foreach (@$pfields) {
	  my $fn = $_;
		my $found=0;
		foreach (@f2) {
			if ($_ eq $fn) {
			  $found=1;
				last;
			}
		}
		if ($found==0) {
		  $notfound=1;
			last;
		}
	}
	if ($notfound!=0) {
	  self->logMessage("unknown log field: $_");
		$pfields = [];
		return 0;
	} else {
	  return 1;
	}
}






sub _checkvals ($pfields,$pvals) {
  my $c;
	foreach (@$pfields) {
	  my $errmsg = "$$pvals[$c] is not a correct value for $_!";

		# Done needs values between 1 to 6
		if ($_ eq self->FLD_LOGDONE) {
		  if (($$pvals[$c] < 1) && ($$pvals[$c] > 6)) {
			  self->logMessage($errmsg);
				$$pvals[$c]=5;
			} 
		} elsif ($_ eq self->FLD_LOGERROR) {
		  if (($$pvals[$c] < 0) && ($$pvals[$c] > 20)) {
  		  self->logMessage($errmsg);
				$$pvals[$c]=0;
		  }
		}
	  $c++;
	}
	return 1;
}



1;
