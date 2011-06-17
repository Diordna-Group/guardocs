#!/usr/bin/perl

# Current revision $Revision: 1.1.1.1 $
# On branch $Name:  $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:21:13 $

use DBI;
use inc::Global;

my $db = avdb_db();
my $table = avdb_table();
my $uid = avdb_uid();
my $pwd = avdb_pwd();
my $host = avdb_host();
my $port = mysql_port();

my $con="DBI:mysql:host=$host;database=$db;port=$port";
my $dbh = DBI->connect($con,$uid,$pwd);
my $sth = $dbh->do("DELETE from avclient WHERE datum+6000<Now()+0");

# Log record
# $Log: avclient_kill.pl,v $
# Revision 1.1.1.1  2008/11/09 09:21:13  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:24  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.1  2005/07/19 09:26:04  ms
# Initial import for new CVS structure
#
# Revision 1.1.1.1  2005/04/14 09:23:46  ms
# Import projekt
#
# Revision 1.1.1.1  2005/03/01 16:43:44  ms
# Initial project import
#
# Revision 1.3  2005/02/24 15:31:13  ms
# Anpassungen an startup.pl. Nun gibt es keine use lib qw() Anweisungen in den
# *.pl Scripts mehr. Ueberpruefung von edit.pl
#
# Revision 1.2  2004/07/28 13:45:43  ms
# Added CVS branch information to the files
#
# Revision 1.1.1.1  2004/07/28 13:31:09  ms
# Initial import of archivista webclient
#
