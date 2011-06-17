# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:23 $

package Archivista::Util::IO;

use strict;

use vars qw ( $VERSION );

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PUBLIC METHODS

sub new
{
  my $cls = shift;
	my $self = {};

  bless $self, $cls;
	
  return $self;
}

# -----------------------------------------------

sub read
{
  my $self = shift;
  my $resource = shift;
  my $type = shift; # Can be 'DIR' or 'FILE'

	$type = "FILE" if (! defined $type);

	if (uc($type) eq "FILE") {
		open FIN, "$resource" or die "Can't open file $resource\n";
  	my @fin = <FIN>;
		my $fin = join "", @fin;
		close FIN;
		return \$fin;
	} elsif (uc($type) eq "DIR") {
	  my @files;
		opendir DIR, "$resource" or die "Can't open directory $resource\n";
		while (my $file = readdir DIR) {
			next if $file eq "." or $file eq "..";
			push @files, $file;
		}
		closedir DIR;
		return \@files;
	}
}

# -----------------------------------------------

sub append
{
  my $self = shift;
	my $file = shift;
	my $data = shift;

	open FOUT, ">>$file" or die "Can't open $file\n";
  print FOUT $data;
	close FOUT;
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
# $Log: IO.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:23  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.2  2005/06/17 22:08:08  ms
# Implementing scan over webclient
#
# Revision 1.1  2005/03/21 18:36:57  ms
# Files added to project
#
