# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:23 $

package Archivista::Util::FS;

use strict;

use Archivista::Config;
use Archivista::Util::IO;

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

sub countFilesOnDir
{
  # Please note: FileMask is a string that must match the filename on the
	# directory (for example: scan-20-0003.tif matches the mask 'scan-20-')
	# If the FileMask is given, only files of the directory that matches the mask
	# will be counted
  my $self = shift;
	my $dir = shift;
	my $fileMask = shift;

  my $nrOfFiles = 0;
	my $io = Archivista::Util::IO->new;
	my $pafiles = $io->read($dir,"DIR");

	foreach my $file (@$pafiles) {
		if (defined $fileMask) {
			$nrOfFiles++ if ($file =~ /$fileMask/);	
		} else {
			$nrOfFiles++;
		}
	}

	return $nrOfFiles;
}

# -----------------------------------------------

sub createImageFoldersForArchive
{
  my $self = shift;
	my $archive = shift;
  
	my $config = Archivista::Config->new;
	my $dirSep = $config->get("DIR_SEP");
	my $baseImagePath = $config->get("BASE_IMAGE_PATH");
	my $baseImagePathForArchive = $baseImagePath.$dirSep.$archive.$dirSep;

	mkdir $baseImagePathForArchive;
	mkdir $baseImagePathForArchive."input";
	mkdir $baseImagePathForArchive."output";
	mkdir $baseImagePathForArchive."screen";
}

# -----------------------------------------------

sub unlinkImageFoldersForArchive
{
	my $self = shift;
  my $archive = shift;
	
	my $config = Archivista::Config->new;
	my $rm = $config->get("RM_RF");
	my $dirSep = $config->get("DIR_SEP");
	my $baseImagePath = $config->get("BASE_IMAGE_PATH");
  my $baseImagePathForArchive = $baseImagePath.$dirSep.$archive;
	
	system("$rm $baseImagePathForArchive");
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
# $Log: FS.pm,v $
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
# Revision 1.1  2005/06/02 18:29:53  ms
# Implementing update for mask definition
#
