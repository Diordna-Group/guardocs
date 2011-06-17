# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:25 $

package Gewa::lib::DB;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT);

use DBI;
use Gewa::lib::Config;

BEGIN {
  use Exporter();
  use DynaLoader();

  @ISA    = qw(Exporter DynaLoader);
  @EXPORT = qw(new connect query do disconnect);
}

# -----------------------------------------------
# PRIVATE METHODS

# -----------------------------------------------
# PUBLIC METHODS

=head1 $db = new DB($host,$db,$uid,$pwd)

  Init a new db object
  Initilize the database handler

  PRE: PackageName
       String(host)
       String(db)
       String(uid)
       String(pwd)
  POST: Object(lib::DB)

=cut

sub new
{
  my $cls = shift;
  my $host = shift;
  my $db = shift;
  my $uid = shift;
  my $pwd = shift;

  my $self = {};
  
  bless $self, $cls;
  
  my $dbh = DBI->connect("DBI:mysql:host=$host;database=$db",$uid,$pwd);
  
  if (defined $dbh) {
    $self->{'dbh'} = $dbh;
  } else {
    undef $self;
  }

  return $self;
}

# -----------------------------------------------

=head1 $db->query($sql)

  Return a statement handler for an sql query

  PRE: Object(lib::DB), String(sqlQuery)
  POST: Pointer(statementHandler)

=cut

sub query
{
  my $self = shift;
  my $query = shift;

  return $self->{'dbh'}->prepare($query);
}

# -----------------------------------------------

=head1 $db->do($sql)

  Execute an sql query

  PRE: Object(lib::DB), String(sqlQuery)
  POST: -

=cut

sub do
{
  my $self = shift;
  my $query = shift;

  $self->{'dbh'}->do($query);
}

# -----------------------------------------------

=head1 $db->quote($sql)

  Return a quoted sql query

  PRE: Object(lib::DB), String(sqlQuery)
  POST: String(sqlQuery)

=cut

sub quote
{
  my $self = shift;
  my $string = shift;

  return $self->{'dbh'}->quote($string);
}

# -----------------------------------------------

=head1 $db->disconnect()

  Disconnect db connection

  PRE: Object(lib::DB)
  POST: -

=cut

sub disconnect
{
  my $self = shift;

  $self->{'dbh'}->disconnect();
}

1;

__END__

# Log record
# $Log: DB.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:25  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:23  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.1  2005/11/21 10:40:43  ms
# Added to project
#
# Revision 1.1  2005/01/21 15:58:07  ms
# Added files, new namespace Gewa
#
# Revision 1.1  2005/01/07 18:10:03  ms
# Entwicklung
#
