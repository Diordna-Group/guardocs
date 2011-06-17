# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:21:03 $

# -----------------------------------------------

=head1 NAME


=head1 SYNOPSYS


=head1 DESCRIPTION


=cut

# -----------------------------------------------

package PL::PublishAdministration;

use strict;

# -----------------------------------------------
# PRIVATE METHODS

# -----------------------------------------------
# PUBLIC METHODS

=head1 new($cls,$archiveO)

	IN: class name
	    object (Archivista::BL::Archive APCL)
	OUT: object

	Constructor

=cut

sub new
{
  my $cls = shift;
  my $archiveO = shift; # Object of Archivista::BL::Archive (APCL)
	my $self = {};

  bless $self, $cls;

  my @fields = ("web_on","web_size_max","web_bw","web_bw_factor",
								"web_b_on","web_b_factor","web_b_jpeg",
							  "web_a_on","web_a_factor","web_a_jpeg");
	
  $self->{'archiveO'} = $archiveO;
	$self->{'field_list'} = \@fields;
	
  return $self;
}

# -----------------------------------------------

=head1 fields($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: pointer to hash

	Return a pointer to hash of all required fields

=cut

sub fields
{
  my $self = shift;
  my $cgiO = shift;
	my $archiveO = $self->archive;
  my $langO = $self->archive->lang;
  	
	my (%fields);	
  $fields{'list'} = $self->{'field_list'};
	$fields{'web_on'}{'label'} = $langO->string("WEB_COPY_ARCHIVING");
	$fields{'web_on'}{'name'} = "web_on";
	$fields{'web_on'}{'type'} = "checkbox";
  $fields{'web_on'}{'update'} = 1;
	$fields{'web_size_max'}{'label'} = $langO->string("MAX_SIZE_KB");
	$fields{'web_size_max'}{'name'} = "web_size_max";
	$fields{'web_size_max'}{'type'} = "textfield";
	$fields{'web_size_max'}{'update'} = 1;
	$fields{'web_bw'}{'label'} = $langO->string("BW_OPTIMISATION");
	$fields{'web_bw'}{'name'} = "web_bw";
	$fields{'web_bw'}{'type'} = "checkbox";
	$fields{'web_bw'}{'update'} = 1;
	$fields{'web_bw_factor'}{'label'} = $langO->string("ADDITIONAL_SCALING_PERCENT");
	$fields{'web_bw_factor'}{'name'} = "web_bw_factor";
	$fields{'web_bw_factor'}{'type'} = "textfield";
	$fields{'web_bw_factor'}{'update'} = 1;
	$fields{'web_b_on'}{'label'} = $langO->string("CREATE_FROM_B_COPY");
	$fields{'web_b_on'}{'name'} = "web_b_on";
	$fields{'web_b_on'}{'type'} = "checkbox";
	$fields{'web_b_on'}{'update'} = 1;
	$fields{'web_b_factor'}{'label'} = $langO->string("SIZE")." (10-100%)";
	$fields{'web_b_factor'}{'name'} = "web_b_factor";
	$fields{'web_b_factor'}{'type'} = "textfield";
	$fields{'web_b_factor'}{'update'} = 1;
	$fields{'web_b_jpeg'}{'label'} = $langO->string("JPEG_FACTOR");
	$fields{'web_b_jpeg'}{'name'} = "web_b_jpeg";
	$fields{'web_b_jpeg'}{'type'} = "textfield";
	$fields{'web_b_jpeg'}{'update'} = 1;
	$fields{'web_a_on'}{'label'} = $langO->string("CREATE_FROM_A_COPY");
	$fields{'web_a_on'}{'name'} = "web_a_on";
	$fields{'web_a_on'}{'type'} = "checkbox";
	$fields{'web_a_on'}{'update'} = 1;
	$fields{'web_a_factor'}{'label'} = $langO->string("SIZE")." (10-100%)";
	$fields{'web_a_factor'}{'name'} = "web_a_factor";
	$fields{'web_a_factor'}{'type'} = "textfield";
	$fields{'web_a_factor'}{'update'} = 1;
	$fields{'web_a_jpeg'}{'label'} = $langO->string("JPEG_FACTOR");
	$fields{'web_a_jpeg'}{'name'} = "web_a_jpeg";
	$fields{'web_a_jpeg'}{'type'} = "textfield";
	$fields{'web_a_jpeg'}{'update'} = 1;
	# In this form we won't the back button
  $fields{'displayBackFormButton'} = 0;

	my $webOn = $archiveO->parameter("ArchivWebArchivOn")
					             ->attribute("Inhalt")->value;
  my $webSizeMax = $archiveO->parameter("ArchivWebSizeMax")
														->attribute("Inhalt")->value;
	my $webBW = $archiveO->parameter("ArchivWebSchwarzWeiss")
											 ->attribute("Inhalt")->value;
	my $webBWFactor = $archiveO->parameter("ArchivWebSWFaktor")
														 ->attribute("Inhalt")->value;
  my $webBOn = $archiveO->parameter("ArchivWebBOn")
												->attribute("Inhalt")->value;
  my $webBFactor = $archiveO->parameter("ArchivWebBFaktor")
														->attribute("Inhalt")->value;
  my $webBJpeg = $archiveO->parameter("ArchivWebBJPEG")
													->attribute("Inhalt")->value;
	my $webAOn = $archiveO->parameter("ArchivWebAOn")
												->attribute("Inhalt")->value;
  my $webAFactor = $archiveO->parameter("ArchivWebAFaktor")
														->attribute("Inhalt")->value;
  my $webAJpeg = $archiveO->parameter("ArchivWebAJPEG")
													->attribute("Inhalt")->value;
													
	if (defined $webOn) {
		$fields{'web_on'}{'value'} = $webOn;
	} else {
		$fields{'web_on'}{'value'} = 1;
  }
	if (defined $webSizeMax) {
		$fields{'web_size_max'}{'value'} = $webSizeMax;
	} else {
		$fields{'web_size_max'}{'value'} = 100;
	}
	if (defined $webBW) {
		$fields{'web_bw'}{'value'} = $webBW;
	} else {
		$fields{'web_bw'}{'value'} = 1;
	}
	if (defined $webBWFactor) {
		$fields{'web_bw_factor'}{'value'} = $webBWFactor;
	} else {
		$fields{'web_bw_factor'}{'value'} = 50;
	}
	if (defined $webBOn) {
		$fields{'web_b_on'}{'value'} = $webBOn;
	} else {
		$fields{'web_b_on'}{'value'} = 0;
	}
	if (defined $webBFactor) {
		$fields{'web_b_factor'}{'value'} = $webBFactor;
	} else {
		$fields{'web_b_factor'}{'value'} = 100;
	}
	if (defined $webBJpeg) {
		$fields{'web_b_jpeg'}{'value'} = $webBJpeg;
	} else {
		$fields{'web_b_jpeg'}{'value'} = 16;
	}
	if (defined $webAOn) {
		$fields{'web_a_on'}{'value'} = $webAOn;
	} else {
		$fields{'web_a_on'}{'value'} = 0;
	}
	if (defined $webAFactor) {
		$fields{'web_a_factor'}{'value'} = $webAFactor;
	} else {
		$fields{'web_a_factor'}{'value'} = 50;
	}
	if (defined $webAJpeg) {
		$fields{'web_a_jpeg'}{'value'} = $webAJpeg;
	} else {
		$fields{'web_a_jpeg'}{'value'} = 16;
	}
	
	return \%fields;
}

# -----------------------------------------------

=head1 save($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: -

	Save all information of a definition to the database. This method performs an
	insert and an update as well, depending if the definition is new or you are
	updating one.

=cut

sub save 
{
  my $self = shift;
	my $cgiO = shift; # Object of CGI.pm
	my $archiveO = $self->archive;

	my $webOn = $cgiO->param("web_on");
	my $webSizeMax = $cgiO->param("web_size_max");
	my $webBW = $cgiO->param("web_bw");
	my $webBWFactor = $cgiO->param("web_bw_factor");
	my $webBOn = $cgiO->param("web_b_on");
	my $webBFactor = $cgiO->param("web_b_factor");
	my $webBJpeg = $cgiO->param("web_b_jpeg");
	my $webAOn = $cgiO->param("web_a_on");
	my $webAFactor = $cgiO->param("web_a_factor");
	my $webAJpeg = $cgiO->param("web_a_jpeg");
	$webOn = 0 if (! defined $webOn);
	$webBW = 0 if (! defined $webBW);
	$webBOn = 0 if (! defined $webBOn);
	$webAOn = 0 if (! defined $webAOn);
	
	$archiveO->parameter("ArchivWebArchivOn")->attribute("Inhalt")->value($webOn);
	$archiveO->parameter->update;	
	$archiveO->parameter("ArchivWebSizeMax")->attribute("Inhalt")->value($webSizeMax);
	$archiveO->parameter->update;
	$archiveO->parameter("ArchivWebSchwarzWeiss")->attribute("Inhalt")->value($webBW);
	$archiveO->parameter->update;
	$archiveO->parameter("ArchivWebSWFaktor")->attribute("Inhalt")->value($webBWFactor);
	$archiveO->parameter->update;
	$archiveO->parameter("ArchivWebBOn")->attribute("Inhalt")->value($webBOn);
	$archiveO->parameter->update;
	$archiveO->parameter("ArchivWebBFaktor")->attribute("Inhalt")->value($webBFactor);
	$archiveO->parameter->update;
	$archiveO->parameter("ArchivWebBJPEG")->attribute("Inhalt")->value($webBJpeg);
	$archiveO->parameter->update;
	$archiveO->parameter("ArchivWebAOn")->attribute("Inhalt")->value($webAOn);
	$archiveO->parameter->update;
	$archiveO->parameter("ArchivWebAFaktor")->attribute("Inhalt")->value($webAFactor);
	$archiveO->parameter->update;
	$archiveO->parameter("ArchivWebAJPEG")->attribute("Inhalt")->value($webAJpeg);
	$archiveO->parameter->update;
}

# -----------------------------------------------

=head1 archive($self)

	IN: object (self)
	OUT: object (Archivista::BL::Archive APCL)

=cut

sub archive
{
  my $self = shift;

	return $self->{'archiveO'};
}

1;

__END__

=head1 EXAMPLE


=head1 TODO


=head1 AUTHOR


=cut

# Log record
# $Log: PublishAdministration.pm,v $
# Revision 1.1.1.1  2008/11/09 09:21:03  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:24  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.2  2005/11/29 18:24:07  ms
# Added POD
#
# Revision 1.1  2005/07/19 09:14:22  ms
# Initial import for new CVS structure
#
# Revision 1.1  2005/06/08 16:57:22  ms
# File added to project
#
# Revision 1.2  2005/05/27 15:43:38  ms
# Entwicklung an database administration
#
# Revision 1.1  2005/04/21 16:40:47  ms
# Files added to project
#
