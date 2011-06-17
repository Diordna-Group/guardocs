# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:23 $

package Archivista::DL::Jobs;

use strict;

use vars qw ( $VERSION @ISA );

use Archivista::DL::DB;

@ISA = qw ( Archivista::DL::DB );

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PRIVATE METHODS

# -----------------------------------------------
# PUBLIC METHODS

sub new 
{
	my $cls = shift;
  my $params = shift; # Object of Job Paramas Hash
	my $db = shift; # Object of Archivista::DL::DB
	my $self = {};

	bless $self, $cls;

  $self->{'db'} = $db;
	$self->{'job_params'} = $params;
	
  return $self;
}

# -----------------------------------------------

sub get
{
  my $self = shift;

  my ($query,$sth);
	my $dbh = $self->db->sudbh;
	my $params = $self->{'job_params'};
	my $jobA = $params->{'job'};
  
  $query = "SELECT id,host,user,db ";
	$query .= "FROM jobs ";
	$query .= "WHERE job = ".$dbh->quote($jobA)." AND ";
	$query .= "status = 100 ";
	$query .= "LIMIT 1";
	$sth = $dbh->prepare($query);
	$sth->execute;

  while (my @row = $sth->fetchrow_array()) {
		$params->{'id'} = $row[0];
		$params->{'host'} = $row[1];
		$params->{'user'} = $row[2];
		$params->{'db'} = $row[3];
	}

	$sth->finish;

  if (defined $params->{'id'}) {
		$query = "SELECT param,value FROM jobs_data WHERE jid = ".$params->{'id'};
		$sth = $dbh->prepare($query);
		$sth->execute;

  	while (my @row = $sth->fetchrow_array()) {
			$params->{$row[0]} = $row[1];
		}
	
		$sth->finish;
	}
}

# ------------------------------------------------

sub done
{
  my $self = shift;

	my $dbh = $self->db->sudbh;
	my $params = $self->{'job_params'};
	my $jobId = $params->{'id'};

  if (defined $jobId) {
		my $query = "UPDATE jobs SET status = 120 WHERE id = $jobId";
		$dbh->do($query);
	}
}

# -----------------------------------------------

sub process
{
  my $self = shift;

	my $dbh = $self->db->sudbh;
	my $params = $self->{'job_params'};
	my $jobId = $params->{'id'};

  if (defined $jobId) {
		my $query = "UPDATE jobs SET status = 110 WHERE id = $jobId";
		$dbh->do($query);
	}
}

1;

__END__

=head1 NAME


=head1 SYNOPSYS


=head1 DESCRIPTION

	Job status
		- 100 to do
		- 110 process 
		- 120 done

=head1 DEPENDENCIES


=head1 EXAMPLE


=head1 TODO


=head1 AUTHOR


=cut

# Log record
# $Log: Jobs.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:23  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.2  2005/10/18 21:31:23  up
# Changes for ArchivistaBox
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.1  2005/06/17 18:23:21  ms
# File added to project
#
