# Current revision $Revision: 1.10 $
# Latest change by $Author: upfister $ on $Date: 2010/03/04 11:08:25 $

# -----------------------------------------------

=head1 NAME


=head1 SYNOPSYS


=head1 DESCRIPTION


=cut

# -----------------------------------------------

package PL::HTML;

use PL::LoginForm;
use PL::UserAdministration;
use PL::FieldDefinition;
use PL::MaskDefinition;
use PL::Form;
use PL::DatabaseAdministration;
use PL::PublishAdministration;
use PL::ScanDefAdministration;
use PL::BarcodeSettings;
use PL::BarcodeProcessing;
use PL::OCRDefAdministration;
use PL::SQLDefinition;

use constant SPACE => "\r\n";
use strict;

# -----------------------------------------------
# PRIVATE METHODS

=head1 _borderTable($self)

	IN: object (self)
	OUT: string

	Create the HTML string for the small black border of 
	the login mask and call the method to display the 
	content of the login mask 

=cut

sub _borderTable
{
  my $self = shift;

  my $class = "TableBorder";
	my $cellpadding = 1;
	my $cgiO = $self->cgi;

  if ($cgiO->param("admdb") == 1) {
		$class = "TableAdminDbBorder";
		$cellpadding = 4;
	}
	my $html = $self->_headerTable();
	return $html;
}

# -----------------------------------------------

=head1 _headerTable($self)

	IN: object (self)
	OUT: string

	Define the content of the login mask. This method displays 
	the login mask header image and calls the method which
	creates the login table	

=cut

sub _headerTable
{
	my $self = shift;

	my $cgiO = $self->cgi;	
	my $www = $self->config->get("WWW_DIR");
	
	my $html = SPACE .
	  $cgiO->start_table({-border => 0,-cellpadding => 0,
		  -cellspacing => 0}) .
	  $cgiO->Tr($cgiO->td({-height => 53,-colspan => 2,
			-background => $www.'/img/login_header.png'})) .
	  $cgiO->Tr($cgiO->td($self->_loginTable())) .
	  $cgiO->end_table . SPACE;

	return $html;
}

# -----------------------------------------------

=head1 _loginTable($self)

	IN: object (self)
	OUT: string

	Define the main part of the login mask, the left side with the background
	image and the right side with the login input mask. The input mask is defined
	thru another method. This method simply calls the appropriate method.

=cut

sub _loginTable
{
  my $self = shift;

	my $cgiO = $self->cgi;
	my $www = $self->config->get("WWW_DIR");
	my $html = SPACE . 
	  $cgiO->start_table({-border => 0,-cellpadding => 0,
	    -cellspacing => 0}) .
    $cgiO->Tr($cgiO->td({-width => 248,-height => 334,
			-background => $www.'/img/login_left.png'}),
    $cgiO->td({-align => 'center', -valign => 'center',
			-class => 'LoginMask',-width=>500,-height=>334},
			  $self->_loginFormTable())) .
    $cgiO->end_table . SPACE;
	
  return $html;
}

# -----------------------------------------------

=head1 _loginFormTable($self)

	IN: object (self)
	OUT: string

	Define the login form, especially the header with the text inside (version,
	powered by, module description). This method calls finally the appropriate
	method to display the login form with the input fields and button.

=cut

sub _loginFormTable
{
	my $self = shift;

	my $cgiO = $self->cgi;
  my $configO	= $self->config;
	my $title = $configO->get("TITLE");
	my $version = "2011/IV";
	
	my $html = SPACE . $cgiO->start_table({-border => 0,
																 -cellspacing => 0,
																 -cellpadding => 0,
																 -width => '100%'}) .
  $cgiO->Tr($cgiO->td({-height => 30},'&nbsp;')) .
	$cgiO->Tr($cgiO->td({-align => 'right',
											 -class=>'Title'}, $title)) .
  $cgiO->Tr($cgiO->td({-align => 'right',
											 -class => 'Subtitle'},"Version $version - Powered by", 
											 $cgiO->a({-href => 'http://www.archivista.ch',
     														 -target => 'blank'},'Archivista GmbH'))) .
  $cgiO->Tr($cgiO->td({-height => '40', -colspan => 2},'&nbsp;')) .
 	$cgiO->Tr($cgiO->td({-align => 'center',
											 -class => 'LoginMask'},$self->_loginForm)) .
  $cgiO->end_table . SPACE;

  return $html;
}

# -----------------------------------------------

=head1 _loginForm($self)

	IN: object (self)
	OUT: string

	Define finally the login form with all input fields, labels and the login
	button. This mask is different whether the normal login mask or the mask to
	create / drop databases is required.

=cut

sub _loginForm
{
  my $self = shift;

	my $frmFieldSize = 20;
	my $frmTdHeight = 22;
  open(FIN,'/etc/lang.conf');
	my @f = <FIN>;
	close(FIN);
	my $kb = join("",@f);
	if ($kb eq '') {
    open(FIN,'/home/archivista/.xkb-layout');
	  @f = <FIN>;
	  close(FIN);
	  $kb = join("",@f);
	}
	my $defLanguage = "en";
	$defLanguage = "de" if index($kb,"de")==0;
	$defLanguage = "fr" if index($kb,"fr")==0;
	$defLanguage = "it" if index($kb,"it")==0;

  use lib qw(/home/cvs/archivista/jobs);
  use AVStrings;
	my $str = AVStrings->new($defLanguage);
	my $pw1 = $str->string("web_pwd");
	my $host1 = $str->string("web_host");
	my $db1 = $str->string("web_db");
	my $user1 = $str->string("web_uid");
	my $login1 = $str->string("web_login");
	my $lang1 = $str->string("web_lang");
	my $err1 = $self->{'error'};
	$err1 = $str->string("web_error_login") if  $err1 eq "Error on login!";
	
	my $cgiO = $self->cgi;
	my $admdb = 0;
	my $loginFrm = PL::LoginForm->new;
	
  my ($adminDatabases,$submitButton,$chooseLanguage,%langs);
  # Pointer to array of all archivista archives (method called from APCL)
	my $parchives = $loginFrm->archives;
  # Add a null elment at the top
	unshift @$parchives, "";
	my $archives = $cgiO->popup_menu(-name => 'archive',
																	 -values => $parchives);
	# This are the configured languages
	$langs{'de'} = "Deutsch";
	$langs{'en'} = "English";
	$langs{'fr'} = "Français";
	$langs{'it'} = "Italiano";
	my @langs = keys %langs;
  my $langSelect = $cgiO->popup_menu(-name => 'lang',
																		 -values => \@langs,
																		 -default => $defLanguage,
																		 -labels => \%langs);
  
	if (defined $cgiO->param("admdb")) {
		$admdb = $cgiO->param("admdb");
	}

	my $displayHostField = $self->config->get("LOGIN_DISPLAY_HOST");
  my $host = $cgiO->param('host');
	my $db = $cgiO->param('db');
	my $uid = $cgiO->param('uid');
	
	# Display admin databases (create/from)
	if ($admdb == 1) {
	  $uid = "root";
		$adminDatabases =	
		  $cgiO->Tr(
			  $cgiO->td({-height => $frmTdHeight,
			    -align => 'left'},"Options"),
			  $cgiO->td({-align=>'right'},$cgiO->radio_group(-name => 'options',
					-values => ['create','drop'],
					-default => 'create',
					-override => 1,
					-class => 'NoBorder'))
				) . SPACE .
			$cgiO->Tr(
			  $cgiO->td({-height => $frmTdHeight,
					-align => 'left'},"Settings from"),
				$cgiO->td({-align=>'right'},$archives)) . SPACE;
		$submitButton =	
		  $cgiO->Tr(
		    $cgiO->td({-colspan =>'2',-align =>'right'},
				  $cgiO->submit(-name => 'submit',-value => "Execute"))
			) . SPACE;
	} else {
		$host = $self->config->get("DEFAULT_LOGIN_HOST") if (length($host) == 0);
	  $db = $self->config->get("DEFAULT_LOGIN_DB") if (length($db) == 0);
	  $uid = $self->config->get("DEFAULT_LOGIN_USER");
		$chooseLanguage = $cgiO->Tr(
			$cgiO->td({-height => $frmTdHeight,-align => 'left'},$lang1),
			$cgiO->td({-align=>'right'},$langSelect)
		);
		$submitButton =	$cgiO->Tr(
		  $cgiO->td({-colspan => 2,-align => 'right'},
			  $cgiO->submit(-name => 'submit',-value => $login1))
		) . SPACE;
	}
	
	my $html = SPACE . $cgiO->start_form() .
	$cgiO->hidden({-name => 'admdb',-value => 0,-override => 1}) .
  $cgiO->hidden({-name => 'ua', -value => 1}) .
	SPACE . $cgiO->start_table({-border => 0,-cellspacing => 0,-cellpadding => 0,
											-width => '350'});

	if ($displayHostField == 1) {
		$html .= $cgiO->Tr(
		  $cgiO->td({-height => $frmTdHeight,-align => 'left'},$host1),
      $cgiO->td({-align => 'right'},$cgiO->textfield(-size => $frmFieldSize,
				-name => 'host',-value => $host,-override => 1))
		) . SPACE;
	} else {
		$host = 'localhost' if (length($host) == 0);
		$html .= $cgiO->hidden({-name => 'host', -value => $host, -override => 1});
	}
	
	$html .= 
	  $cgiO->Tr(
	    $cgiO->td({-height => $frmTdHeight,-align => 'left'},$db1),
		  $cgiO->td({-align=>'right'},
			           $cgiO->textfield(-size => $frmFieldSize,-name => 'db',
			  -value => $db,-override => 1))
	    ) . SPACE .
			
 	  $cgiO->Tr(
		  $cgiO->td({-height => $frmTdHeight,-align => 'left'},$user1),
	  	$cgiO->td({-align=>'right'},$cgiO->textfield(-size => $frmFieldSize,-name => 'uid',
			  -value => $uid, -override => 1))) .													
	    $cgiO->Tr($cgiO->td({-height => $frmTdHeight,
			  -align => 'left'},$pw1),
			$cgiO->td({-align=>'right'},$cgiO->password_field(-size => $frmFieldSize,
				-name => 'pwd',-override => 1))
			) . SPACE .
			
	  $adminDatabases .		
    $chooseLanguage .
    $cgiO->Tr($cgiO->td('&nbsp;')) . SPACE .
    $submitButton .
    $cgiO->Tr($cgiO->td({-height => 30,-align => 'right',-colspan => 2,
			-class => 'Error'},'&nbsp;'.$err1)) . SPACE .
	  $cgiO->end_table . SPACE .
    $cgiO->end_form . SPACE;

  return $html;
}

# -----------------------------------------------

=head1 _menuItem($self,$menuItem)

	IN: object (self)
	    object (Archivista::Application::Menu::MenuItem)
	OUT: string

	Return the HTML string to display a menu item. Menu items are configured on
	application_menu table and called thru APCL. Menu and MenuItems are both
	objects.
	
=cut

sub _menuItem
{
  my $self = shift;
	my $menuItem = shift; # Object of Archivista::Application::Menu::MenuItem
	
	my $cgiO = $self->cgi;
  my $perl = $self->config->get("PERL_DIR");

  my $param = $menuItem->param;
	my $label = $menuItem->label;
	my $relativeLevel = $menuItem->relativeLevel;
	my $absoluteLevel = $menuItem->absoluteLevel;
  my $tdClass = "MenuItem";
	my $tdClassLabel = "MenuItem$relativeLevel";
  
  $param .= "&level=$absoluteLevel";
  
	return $cgiO->Tr(
	  $cgiO->td({-class => $tdClass},"&rsaquo;"),
		$cgiO->td({-class => $tdClassLabel},
		  $cgiO->a({-href => "$perl/index.pl?$param",-class => 'Menu'},$label)));
}

# -----------------------------------------------

=head1 _menuItems($self)

	IN: object (self)
	OUT: string

	Return the HTML string with all menu items (the whole menu)

=cut

sub _menuItems
{
  my $self = shift;
	my $cgiO = $self->cgi;
	my $archiveO = $self->archive;
	my $langO = $self->archive->lang;
	my $level = $cgiO->param("level");
	my $applicationId = $self->config->get("APPLICATION_ID");
	my $menuO = $archiveO->application($applicationId)->menu($level);
	my $db = $cgiO->param('db');
	
	my $menuItems = $cgiO->start_table;
  $menuItems .= $cgiO->Tr($cgiO->td({-height => 15},"&nbsp;"));

	while (my $menuItem = $menuO->nextItem) {
	  # $menuItem is on object of Archivista::Application::Menu::MenuItem!
		$menuItems .= $self->_menuItem($menuItem) . SPACE;
	}

  $menuItems .= $cgiO->end_table . SPACE;
	
  return $menuItems;
}

# -----------------------------------------------

=head1 _menu($self)

	IN: object (self)
	OUT: string

	Return the HTML string which creates the menu. Basically 
	this method calls the method which displays all MenuItems

=cut

sub _menu
{ 
  my $self = shift;
	my $cgiO = $self->cgi;
	my $www = $self->config->get("WWW_DIR");
  

  return SPACE . $cgiO->start_table({-border => 0,
											    	 -cellpadding => 0,
														 -cellspacing => 0}) .
				 $cgiO->Tr($cgiO->td({-valign => 'top',
				                      -width => 249,
				 											-height => 500,
				 											-background => $www.'/img/menu_main.png'},
															$self->_menuItems)) .
				 $cgiO->end_table . SPACE;
}

# -----------------------------------------------

=head1 _header($self)

	IN: object ($self)
	OUT: -

	Create the header for logged forms

=cut

sub _header 
{ 
  my $self = shift;
	my $cgiO = $self->cgi;
	my $www = $self->config->get("WWW_DIR");
  
  my $html = $cgiO->start_table({-border => 0,
											    			 -cellpadding => 0,
																 -cellspacing => 0,
												 				 -width => '100%'}) .
	$cgiO->Tr($cgiO->td({-height => 53,
											 -background => $www.'/img/header1.png',
											 -width => '249'},"&nbsp;") . 
					  $cgiO->td({-height => 53,
											 -background => $www.'/img/header2.png'},"&nbsp;")) .
	$cgiO->end_table;

	$self->{'html'} .= $html;
}

# -----------------------------------------------

=head1 _main($self)

	IN: object (self)
	OUT: object (PL::Main)

	Return the PL::Main object

=cut

sub _main
{
  my $self = shift;

	return $self->{'main'};
}

# -----------------------------------------------

=head1 _formTitle($self,$title)

	IN: object (self)
	    title string
	OUT: -

	Place a title for each form

=cut

sub _formTitle
{
  my $self = shift;
	my $title = shift;
	my $cgiO = $self->cgi;

	$title .= " @ ".$self->archive->session->db;	
	$self->{'main'} .= $cgiO->div({-class => 'FormTitle'},$title);
}

# -----------------------------------------------

=head1 _fieldTypeToHtml($self,$fieldNAme,$fieldType,
												$fieldValue,$pafieldValues,$phfieldValues)

	IN: object (self)
	    field name string
			field type string
			field value string
			pointer to array of field values
			pointer to hash of field values
	OUT: string

	Create the HTML code to display depending on FieldType. Supported types are:
	textfield, password, select, checkbox, textarea

=cut

sub _fieldTypeToHtml
{
  my $self = shift;
	my $fieldName = shift;
	my $fieldType = shift;
	my $fieldValue = shift;
	my $pafieldValues = shift;
	my $phfieldValues = shift;
	my $cgiO = $self->cgi;

  my $field;

	if ($fieldType eq "textfield") {
		$field = $cgiO->textfield(-name => $fieldName,
															-value => $fieldValue,
															-override => 1,
															-style => 'width: 400px');
	} elsif ($fieldType eq "password") {
    $field = $cgiO->password_field(-name => $fieldName,
																	 -override => 1);
	} elsif ($fieldType eq "select") {
		$field = $cgiO->popup_menu(-name => $fieldName,
															 -values => $pafieldValues,
															 -default => $fieldValue,
															 -labels => $phfieldValues,
															 -override => 1);
	} elsif ($fieldType eq "checkbox") {
		$field = $cgiO->checkbox(-name => $fieldName,
														 -checked => $fieldValue,
														 -value => 1,
														 -label => '',
														 -override => 1,
														 -class => 'NoBorder');
	} elsif ($fieldType eq "textarea") {
		$field = $cgiO->textarea(-name => $fieldName,
														 -value => $fieldValue,
														 -override => 1);
	}

	return $field;
}

# -----------------------------------------------

=head1 _displaySelectionForm($self,$pselection,$admin)

	IN: object (self)
	    pointer to hash of selection items
			admin flag
	OUT: -

	Create a definitions selection box. This feature is needed for forms who has
	more then one definition which has different items to display (for example for
	mask definitions)

=cut

sub _displaySelectionForm
{
  my $self = shift;
  my $pselection = shift;	
  my $admin = shift;
	my $tdWidth = 150;
	my $tdHeight = 20;
  my $cgiO = $self->cgi;
	my $langO = $self->archive->lang;
  my $langCode = $langO->code;
  my $level = $cgiO->param("level");

	my $label = $$pselection{'label'};
  my $fieldName = $$pselection{'field_name'};
	my $pafieldValues = $$pselection{'array_values'};
	my $phfieldValues = $$pselection{'hash_values'};
	my $fieldValue = $$pselection{'value'};
	my $selected = $$phfieldValues{$fieldValue};
	my $newSelectionValue = $$pselection{'new_selection_value'};

  my $deleteButton;

	if ($$pselection{'display_delete'} == 1) {
		$deleteButton =	$cgiO->submit(-name => 'submit',
			-value => $langO->string("DELETE"),
			-onClick => "return askForDeletion('$langCode')",
			-style => 'width: 100%');
	}
	
	my $select = 
	  $cgiO->popup_menu(-name => $fieldName,
	    -values => $pafieldValues,
	    -default => $fieldValue,
	    -labels => $phfieldValues,
	    -override => 1,
	    -style => 'width: 100%');
	
	my $h = $cgiO->start_table({-border => 0});
	
	# Select element
	$h .= SPACE.SPACE.$cgiO->start_form.SPACE;
	$h .= $cgiO->hidden({-name => $admin,-value => 1,-override => 1});
	$h .= $cgiO->hidden({-name=>'level',-value=>$level,-override => 1});
	$h .= $cgiO->
	  Tr(
	    $cgiO->td({-width => $tdWidth,-height => $tdHeight},$label).SPACE,
		  $cgiO->td({-valign => 'top', -width => '130'},$select).SPACE,
	    $cgiO->td({-width => '100'},$cgiO->submit(-name => 'submit',
			  -value => $langO->string("SELECT"),-style => 'width: 100%')).SPACE,
		  $cgiO->td({-valign => 'bottom', -width => '100'},$deleteButton).SPACE
		).SPACE;														 
	$h .= $cgiO->end_form.SPACE.SPACE;
	
	# Edit element
	if ($$pselection{'display_rename'} == 1) {
		$h .= $cgiO->start_form;
		$h .= $cgiO->hidden({-name => $admin,-value => 1,-override => 1});
		$h .= $cgiO->hidden({-name => 'level',-value => $level,-override => 1});
		$h .= $cgiO->hidden({-name => 'edit_selection',-value => '1'});
		$h .= $cgiO->hidden({-name => 'edit_selection_value',
		  -value => $fieldValue,-override => 1});
		$h .= $cgiO->
		  Tr(
			  $cgiO->td({},'&nbsp;'),
				$cgiO->td({-valign => 'top',-width => $tdWidth},
				  $cgiO->textfield({-name => 'edit_selection_name',-value => $selected,
						-override => 1,-style => 'width: 97%'})),
				$cgiO->td({-width => '100'},
				  $cgiO->submit(-name => 'submit',-value => $langO->string("CHANGE"),
						-style => 'width: 100%'))
			);
		$h .= $cgiO->end_form;
	}

	#	 New element
	if ($$pselection{'display_create'} == 1) {
		$h .= $cgiO->start_form;
		$h .= $cgiO->hidden({-name => $admin,-value => 1,-override => 1});
		$h .= $cgiO->hidden({-name => 'level',-value => $level,-override => 1});
		$h .= $cgiO->hidden({-name => 'adm',-value => 'edit',-override => 1});
		$h .= $cgiO->hidden({-name => 'new_selection',-value => '1'});
		$h .= $cgiO->hidden({-name => 'new_selection_value',
		  -value => $newSelectionValue,-override => 1});
 		$h .= $cgiO->Tr(
		  $cgiO->td({},'&nbsp;'),
			$cgiO->td({-valign => 'top',-width => $tdWidth},
			  $cgiO->textfield({-name => 'new_selection_name',-override => 1,
				  -style => 'width: 97%'})),
				$cgiO->td({-width => '100'},
				  $cgiO->submit(-name => 'submit',-value => $langO->string("CREATE"),
					 -style => 'width: 100%'))
		);
		$h .= $cgiO->end_form;
	}

	if ($$pselection{'message'} ne "") {
	  $h .= $cgiO->Tr(
		  $cgiO->td({-colspan=>4,-align=>'right',
			  -width=>$tdWidth,-height=>$tdHeight},$$pselection{'message'}));
	}
	$h .= $cgiO->end_table;
	
	$self->{'main'} .= $h.$cgiO->br;
}






# -----------------------------------------------

=head1 _displayInputForm($self,$pfields,$admin)

	IN: object (self)
	    pointer to hash of fields
			admin flag
	OUT: -

	This method displays for all forms the input fields to add new items or edit
	existing items. This method is used from each form. The definition of pfields
	is done inside of the PL::XYZ modules which describes the content and
	configuration of each form.

	PLEASE NOTE: this means that there is no need to create specific HTML forms
	for new administration/configuration forms. Use this method to generate the
	HTML code!!
	
=cut

sub _displayInputForm
{
  my $self = shift;
	my $pfields = shift;
	my $admin = shift;
	my $tdWidth = 250;
  my $tdHeight = 20;
	my $cgiO = $self->cgi;
  my $langO = $self->archive->lang;
  my $id = $cgiO->param("id");
	my $level = $cgiO->param("level");
  my $valign = "center";
	my ($back);

  $self->{'main'} .= $cgiO->start_form;
  $self->{'main'} .= $cgiO->start_table;
	$self->{'main'} .= $cgiO->hidden({-name => $admin,
																		-value => 1,
																		-override => 1});
	$self->{'main'} .= $cgiO->hidden({-name => 'adm',
																		-value => 'save',
																		-override => 1});
	$self->{'main'} .= $cgiO->hidden({-name => 'level',
																		-value => $level,
																		-override => 1});
	
	if ($cgiO->param("adm") eq "edit") {
  	$self->{'main'}	.= $cgiO->hidden('id',$id);
	}
	
  foreach my $key (@{$$pfields{'list'}}) {
	  my $field;
		my $fieldName = $$pfields{$key}{'name'};
		my $fieldType = $$pfields{$key}{'type'};
		my $fieldValue = $$pfields{$key}{'value'};
		my $fieldHiddenValue = $$pfields{$key}{'hidden_value'};
		my $pafieldValues = $$pfields{$key}{'array_values'};
		my $phfieldValues = $$pfields{$key}{'hash_values'};
	  my $fieldUpdate = $$pfields{$key}{'update'};
		if ($fieldUpdate == 1 || 
		    length($id) == 0 || 
				$cgiO->param("adm") ne "edit") {
			# Field is editable (for example host and username in user administration
			# are not editable!
			$field = $self->_fieldTypeToHtml($fieldName,$fieldType,$fieldValue,
			                                 $pafieldValues,$phfieldValues);
	  } else {
			$field = $fieldValue;
			# Set non editable values as hidden fields
			$self->{'main'} .= $cgiO->hidden({-name => $fieldName,
																				-value => $fieldHiddenValue,
																				-override => 1});
		}
		if ($fieldType eq "hidden") {
			$self->{'main'} .= $cgiO->hidden({-name => $fieldName,
																				-value => $fieldValue,
																				-override => 1});
		} else {
			$valign = "top" if ($fieldType eq "textarea");
			$self->{'main'} .= $cgiO->
			  Tr(
				  $cgiO->td({-class => 'NoWrap',
				    -valign => $valign,-width => $tdWidth,
				    -height => $tdHeight},$$pfields{$key}{'label'}),
			    $cgiO->td({-valign => 'top'},$field)
				);
		}
	}

  if ($$pfields{'displayBackFormButton'} == 1) {
  	$back = $cgiO->submit(-name => 'submit',-style => 'width: 80px',
	  										  -value => $langO->string("BACK"));
  }
	
  my $submit = $cgiO->submit(-name => 'submit',-style => 'width: 80px',
											 			 -value => $langO->string("SAVE"));
														 
  $self->{'main'} .= $cgiO->Tr($cgiO->td({-colspan => 2,-align => 'right',
	  -height => 40,-valign => 'bottom'},$back."&nbsp;".$submit));
	
	$self->{'main'} .= $cgiO->end_table;
	$self->{'main'} .= $cgiO->end_form;
}

# -----------------------------------------------

=head1 _displayExistingElements($self,$pelements,$admin)

	IN: object (self)
	    pointer to hash of elements
			admin flag
	OUT: -

	This method creates based on the hash of elements a HTML table with all items
	and the 'new', 'update', 'delete' features.

=cut

sub _displayExistingElements {
  my $self = shift;
	my $pelements = shift;
	my $admin = shift;
	my $perl = $self->config->get("PERL_DIR");
  my $langO = $self->archive->lang;
	my $cgiO = $self->cgi;
	my $level = $cgiO->param("level");
	my $nrOfElements = $#{$$pelements{'list'}};
	my $mid = $$pelements{'mask_definition'};
	my $url = "$perl/index.pl?$admin=1&mid=$mid&level=$level";
  my $langCode = $langO->code;
  my ($newLink);
	
	if ($$pelements{'new'} == 0) {
		$newLink = "&nbsp;";
	} else {
		$newLink = $cgiO->a({-href => $url."&adm=new",
	  	-class => 'New'},"&rsaquo;".$langO->string("NEW"));
  }

	if ($$pelements{'paste'} == 0) {
	  $newLink .= "&nbsp;";
	} else {
	  $newLink .= '&nbsp;&nbsp;'.$cgiO->a({-href => $url."&adm=paste",
		             -class => 'New'},"&rsaquo;".$langO->string("PASTE"));
	}

	$self->{'main'} .= SPACE . $cgiO->start_table({-border => 0,
																				 -cellpadding => 0,
																				 -cellspacing => 1,
																				 -width => '80%'});
 
  my $elementTh = $cgiO->th({-class => 'Element',
														 -width => 140},$newLink);


	if ($nrOfElements >= 0) {
  	foreach my $attribute (@{$$pelements{'attributes'}}) {
			$elementTh .= $cgiO->th({-class => 'Element'},
      $langO->string(uc($attribute)));
		}

		$self->{'main'} .= $cgiO->Tr($elementTh);
			
		foreach my $id (@{$$pelements{'list'}}) {
			my ($edit,$copy,$delete);
			my $urlParams = $$pelements{$id}{'url_params'};
			my $paramId = $cgiO->escape($id);
			if ($$pelements{$id}{'update'} == 1) {
				$edit = $cgiO->a({-href => "$url&adm=edit&id=$paramId&$urlParams",
		   									  -class => 'Edit'},"&rsaquo;".$langO->string("EDIT"));
				$edit .= "&nbsp;&nbsp;&nbsp;&nbsp;";
			}
			if ($$pelements{$id}{'copy'} == 1) {
			  $copy = $cgiO->a({-href => "$url&adm=copy&id=$paramId&$urlParams",
				               -class => 'Edit'},"&rsaquo;".$langO->string("COPY"));
				$copy .= "&nbsp;&nbsp;&nbsp;&nbsp;";
			}
			if ($$pelements{$id}{'delete'} == 1) {
				$delete = $cgiO->a({-href => "$url&adm=delete&id=$paramId&$urlParams",
			  	-class => 'Delete',-onClick => "return askForDeletion('$langCode')"},
					"&rsaquo;".$langO->string("DELETE"));
				$delete .= "&nbsp;&nbsp;&nbsp;&nbsp;";
			}
			my $elementTr = $cgiO->td({-class => 'Element'},$edit.$copy.$delete);
			foreach my $attribute (@{$$pelements{'attributes'}}) {
				$elementTr .= $cgiO->td({-class => 'Element'},
				                        $$pelements{$id}{$attribute});
			}
			$self->{'main'} .= $cgiO->Tr($elementTr) . SPACE;
		}	
	} else {
		$self->{'main'} .= $cgiO->Tr($elementTh);
		$self->{'main'} .= $cgiO->Tr(
			$cgiO->td({-class => 'Element',-colspan => 2},
			          $langO->string("NO_ELEMENTS_FOUND"))
																);
	}

	$self->{'main'} .= $cgiO->end_table . SPACE;
}

# -----------------------------------------------

=head1 _userAdministration($self)

	IN: object (self)
	OUT: -

	This is the main method which handles the user administration form. The
	appropiate module is loaded and depending on the user action the right method
	is selected.

=cut

sub _userAdministration
{
  my $self = shift;
  my $langO = $self->archive->lang;
	my $cgiO = $self->cgi;
  my $archiveO = $self->archive;
	my $adm = $self->cgi->param("adm");
	
	my $ua = PL::UserAdministration->new($archiveO);
	
  if ($cgiO->param("adm") eq "save" && 
			$cgiO->param("submit") ne $langO->string("BACK")) {
		$ua->save($self->cgi);
	} elsif ($self->cgi->param("adm") eq "delete") {
		$ua->delete($self->cgi);
	}
	
  my $pfields = $ua->fields($self->cgi);
  my $pelements = $ua->elements($self->cgi);
	$self->_formTitle($langO->string("USER_ADMINISTRATION"));
	if ($adm eq "new" or $adm eq "edit") {
		$self->_displayInputForm($pfields,"ua");
  } else {
		$self->_displayExistingElements($pelements,"ua");
	}
}

# -----------------------------------------------

=head1 _fieldDefinition($self)

	IN: object (self)
	OUT: -

	This is the main method which handles the field definition form. The
	appropiate module is loaded and depending on the user action the right method
	is selected.

=cut

sub _fieldDefinition
{
  my $self = shift;
  my $langO = $self->archive->lang;
	my $cgiO = $self->cgi;
  my $archiveO = $self->archive;
	my $adm = $self->cgi->param("adm");
	
  my $fd = PL::FieldDefinition->new($archiveO);

	if ($cgiO->param("adm") eq "save" &&
	    $cgiO->param("submit") ne $langO->string("BACK")) {
		$fd->save($self->cgi);
	} elsif ($self->cgi->param("adm") eq "delete") {
		$fd->delete($self->cgi);
	}

  my $pfields = $fd->fields($self->cgi);
	my $pelements = $fd->elements($self->cgi);
	$self->_formTitle($langO->string("FIELD_DEFINITION"));
  if ($adm eq "new" or $adm eq "edit") {
		$self->_displayInputForm($pfields,"fd");
	} else {
		$self->_displayExistingElements($pelements,"fd");
	}
}






# -----------------------------------------------

=head1 _userExternal($self)

External user administration

=cut

sub _userExternal {
  my $self = shift;
	$self->_formTitle($self->archive->lang->string("USER_EXTERN"));
  my $dbh = $self->archive->db->dbh; # database connection
	my $lang = $self->archive->lang; # languages strings
	my $cgi = $self->cgi;
	my $name = "ue";
	my @fields = qw(ue_mode ue_server ue_port ue_application
	                ue_dom ue_bdn ue_lcuser ue_defuser ue_upload);
	my $pfields = \@fields;
  my $fr = PL::Form->new($dbh,$lang,$cgi,$name,$pfields);
	$fr->process();
	$self->{'main'} .= $fr->display();
}






# -----------------------------------------------

=head1 _userGroups($self)

External group administration

=cut

sub _userGroups {
  my $self = shift;
	$self->_formTitle($self->archive->lang->string("USER_GROUPS"));
  my $dbh = $self->archive->db->dbh; # database connection
	my $lang = $self->archive->lang; # languages strings
	my $cgi = $self->cgi;
	my $name = "ug";
	my @fields = qw(ug_group ug_intern ug_note ug_active);
	my $pfields = \@fields;
  my $fr = PL::Form->new($dbh,$lang,$cgi,$name,$pfields);
	$fr->process();
	$self->{'main'} .= $fr->display();
}






# -----------------------------------------------

=head1 _exportDocs($self)

Settings for export of documents

=cut

sub _exportDocs {
  my $self = shift;
	$self->_formTitle($self->archive->lang->string("EXPORT_DOCS"));
  my $dbh = $self->archive->db->dbh; # database connection
	my $lang = $self->archive->lang; # languages strings
	my $cgi = $self->cgi;
	my $name = "ed";
	my @fields = qw(ed_allowed ed_user ed_maxrecords ed_deactivate);
	my $pfields = \@fields;
  my $fr = PL::Form->new($dbh,$lang,$cgi,$name,$pfields);
	$fr->process();
	$self->{'main'} .= $fr->display();
}







# -----------------------------------------------

=head1 _mailArchiving($self)

Settings for mail archiving

=cut

sub _mailArchiving {
  my $self = shift;
	$self->_formTitle($self->archive->lang->string("MAILS"));
  my $dbh = $self->archive->db->dbh; # database connection
	my $lang = $self->archive->lang; # languages strings
	my $cgi = $self->cgi;
	my $name = "ml";
	my @fields = qw(ml_name ml_host ml_port ml_user ml_pw ml_ssl ml_folder 
	  ml_from ml_cc ml_to ml_subject ml_owner ml_age ml_delete 
		ml_move ml_restore ml_processing ml_attach ml_inactive);
	my $pfields = \@fields;
  my $fr = PL::Form->new($dbh,$lang,$cgi,$name,$pfields);
	$fr->process();
	$self->{'main'} .= $fr->display();
}






# -----------------------------------------------

=head1 _ocrLimit($self)

Settings for ocr limitation

=cut

sub _ocrLimit {
  my $self = shift;
	$self->_formTitle($self->archive->lang->string("OCRLIMIT"));
  my $dbh = $self->archive->db->dbh; # database connection
	my $lang = $self->archive->lang; # languages strings
	my $cgi = $self->cgi;
	my $name = "oc";
	my @fields = qw(oc_limit oc_start oc_stop);
	my $pfields = \@fields;
  my $oc = PL::Form->new($dbh,$lang,$cgi,$name,$pfields);
	$oc->process();
	$self->{'main'} .= $oc->display();
}






# -----------------------------------------------

=head1 _jobAdmin($self)

Administrate jobs

=cut

sub _jobAdmin {
  my $self = shift;
	$self->_formTitle($self->archive->lang->string("JOBADMIN"));
  my $dbh = $self->archive->db->dbh; # database connection
	my $lang = $self->archive->lang; # languages strings
	my $cgi = $self->cgi;
	my $name = "ja";
	my @fields = qw(ja_name ja_script ja_boxes ja_code ja_update 
	                ja_actualized ja_user ja_pw);
	my $pfields = \@fields;
  my $oc = PL::Form->new($dbh,$lang,$cgi,$name,$pfields);
	$oc->process();
	$self->{'main'} .= $oc->display();
}






# -----------------------------------------------

=head1 _formRecognition($self)

	IN: object (self)
	OUT: -

	This is the main method which handles the form definition form. The
	appropiate module is loaded and depending on the user action the right method
	is selected.

=cut

sub _formRecognition {
  my $self = shift;
	$self->_formTitle($self->archive->lang->string("FORM_RECOGNITION"));
  my $dbh = $self->archive->db->dbh; # database connection
	my $lang = $self->archive->lang; # languages strings
	my $cgi = $self->cgi;
	my $name = "fr";
	my @fields = qw(fr_object fr_left fr_top fr_width fr_height fr_type
	                fr_from fr_to fr_field fr_start fr_end fr_script fr_test);
	my $pfields = \@fields;
  my $fr = PL::Form->new($dbh,$lang,$cgi,$name,$pfields);
	$fr->process();
	$self->{'main'} .= $fr->display();
}






# -----------------------------------------------

=head1 _logoRecognition($self)

	IN: object (self)
	OUT: -

	This is the main method which handles the logo recognition form. The
	appropiate module is loaded and depending on the user action the right method
	is selected.

=cut

sub _logoRecognition {
  my $self = shift;
	$self->_formTitle($self->archive->lang->string("LOGO_RECOGNITION"));
  my $dbh = $self->archive->db->dbh; # database connection
	my $lang = $self->archive->lang; # languages strings
	my $cgi = $self->cgi;
	my $name = "lr";
	my @fields = qw(lr_name lr_logo lr_logox lr_logoy lr_radius 
	                lr_contours lr_tolerance 
	                lr_reduction lr_anglemax lr_anglestep lr_score);
	my $pfields = \@fields;
  my $fr = PL::Form->new($dbh,$lang,$cgi,$name,$pfields);
	$fr->process();
	$self->{'main'} .= $fr->display();
}







# -----------------------------------------------

=head1 _maskDefinition($self)

	IN: object (self)
	OUT: -

	This is the main method which handles the mask definition form. The
	appropiate module is loaded and depending on the user action the right method
	is selected.

=cut

sub _maskDefinition
{
  my $self = shift;
	my $langO = $self->archive->lang;
	my $cgiO = $self->cgi;
	my $archiveO = $self->archive;
  my $adm = $self->cgi->param("adm");
  my $md = PL::MaskDefinition->new($archiveO);
  if ($cgiO->param("adm") eq "save" &&
	    $cgiO->param("submit") ne $langO->string("BACK")) {
		$md->save($self->cgi);		
	} elsif ($self->cgi->param("adm") eq "delete") {
		$md->delete($self->cgi);
	}
  my $pfields = $md->fields($self->cgi);
  my $pelements = $md->elements($self->cgi);
	my $pselection = $md->selection($self->cgi);
	$self->_formTitle($langO->string("MASK_DEFINITION"));
 	$self->_displaySelectionForm($pselection,"md");
  if ($adm eq "new" or $adm eq "edit") {
	 	$self->_displayInputForm($pfields,"md");
  } else {
	 	$self->_displayExistingElements($pelements,"md");
  }
}


# -----------------------------------------------

=head1 _databaseAdministration($self)

	IN: object (self)
	OUT: -

	This is the main method which handles the database administration form. The
	appropiate module is loaded and depending on the user action the right method
	is selected.

=cut

sub _databaseAdministration
{
  my $self = shift;
  my $langO = $self->archive->lang;
	my $cgiO = $self->cgi;
  my $archiveO = $self->archive;
	
  my $da = PL::DatabaseAdministration->new($archiveO);
	
  if ($cgiO->param("adm") eq "save" &&
	    $cgiO->param("submit") ne $langO->string("BACK")) {
		$da->save($self->cgi);
	}
	
	my $pfields = $da->fields($self->cgi);
	$self->_formTitle($langO->string("DATABASE_ADMINISTRATION"));
	$self->_displayInputForm($pfields,"da");
}

# -----------------------------------------------

=head1 _scanDefinitionAdministration($self)

	IN: object (self)
	OUT: -

	This is the main method which handles the scan definition
	administration form. The appropiate module is loaded and
	depending on the user action the right method is selected.

=cut

sub _scanDefinitionAdministration
{
  my $self = shift;
	my $langO = $self->archive->lang;
	my $cgiO = $self->cgi;
  my $archiveO = $self->archive;
	my $adm = $self->cgi->param("adm");
	
	my $sa = PL::ScanDefAdministration->new($archiveO);

  if ($cgiO->param("adm") eq "save" &&
	    $cgiO->param("submit") ne $langO->string("BACK")) {
		$sa->save($self->cgi);
	} elsif ($self->cgi->param("adm") eq "delete") {
		$sa->delete($self->cgi);
	} elsif ( $self->cgi->param("adm") eq "copy") {
	  $sa->copy($self->cgi);
	} elsif ( $self->cgi->param("adm") eq "paste") {
	  $sa->paste($self->cgi);
	}
	
  my $pfields = $sa->fields($self->cgi);
  my $pelements = $sa->elements($self->cgi);
	
	$self->_formTitle($langO->string("SCAN_DEFINITIONS"));
	if ($adm eq "new" or $adm eq "edit") {
		$self->_displayInputForm($pfields,"sa");
  } else {
		$self->_displayExistingElements($pelements,"sa");
	}
}

# -----------------------------------------------

=head1 _ocrDefinitionAdministration($self)

	IN: object (self)
	OUT: -

	This is the main method which handles the OCR definition administration
	form. The appropiate module is loaded and depending on the user action
	the right method is selected.

=cut

sub _ocrDefinitionAdministration
{
  my $self = shift;
  my $langO = $self->archive->lang;
  my $cgiO = $self->cgi;
  my $archiveO = $self->archive;
  my $adm = $self->cgi->param("adm");
	
  my $sa = PL::OCRDefAdministration->new($archiveO);

  if ($cgiO->param("adm") eq "save" &&
			$cgiO->param("submit") ne $langO->string("BACK")) {
  	$sa->save($self->cgi);
  } elsif ($self->cgi->param("adm") eq "delete") {
  	$sa->delete($self->cgi);
	} elsif ( $self->cgi->param("adm") eq "copy") {
	  $sa->copy($self->cgi);
	} elsif ( $self->cgi->param("adm") eq "paste") {
	  $sa->paste($self->cgi);
  }
	
  my $pfields = $sa->fields($self->cgi);
  my $pelements = $sa->elements($self->cgi);
  $self->_formTitle($langO->string("OCRDEFINITIONS"));
  if ($adm eq "new" or $adm eq "edit") {
    $self->_displayInputForm($pfields,"ld");
  } else {
    $self->_displayExistingElements($pelements,"ld");
  }
}





# -----------------------------------------------

=head1 _sqlDefinition($self)

	IN: object (self)
	OUT: -

	This is the main method which handles the SQL definition form. The
	appropiate module is loaded and depending on the user action the 
	right method is selected.

=cut

sub _sqlDefinition
{
  my $self = shift;
  my $langO = $self->archive->lang;
  my $cgiO = $self->cgi;
  my $archiveO = $self->archive;
  my $adm = $self->cgi->param("adm");
	
  my $sq = PL::SQLDefinition->new($archiveO);

  if ($cgiO->param("adm") eq "save" &&
			$cgiO->param("submit") ne $langO->string("BACK")) {
  	$sq->save($self->cgi);
  } elsif ($self->cgi->param("adm") eq "delete") {
  	$sq->delete($self->cgi);
	} elsif ( $self->cgi->param("adm") eq "copy") {
	  $sq->copy($self->cgi);
	} elsif ( $self->cgi->param("adm") eq "paste") {
	  $sq->paste($self->cgi);
  }
	
  my $pfields = $sq->fields($self->cgi);
  my $pelements = $sq->elements($self->cgi);
  $self->_formTitle($langO->string("SQLDEFINITIONS"));
  if ($adm eq "new" or $adm eq "edit") {
    $self->_displayInputForm($pfields,"sq");
  } else {
    $self->_displayExistingElements($pelements,"sq");
  }
}




# -----------------------------------------------

=head1 _barcodeSettiongs($self)

	IN: object (self)
	OUT: -

	This is the main method which handles the barcode settings form.
	The appropiate module is loaded and depending on the user action
	the right method is selected.

=cut

sub _barcodeSettings
{
  my $self = shift;
	my $langO = $self->archive->lang;
	my $cgiO = $self->cgi;
	my $archiveO = $self->archive;
	my $adm = $self->cgi->param("adm");

	my $bs = PL::BarcodeSettings->new($archiveO);

	if ($cgiO->param("adm") eq "save" &&
	    $cgiO->param("submit") ne $langO->string("BACK")) {
		$bs->save($self->cgi);
	} elsif ($self->cgi->param("adm") eq "delete") {
		$bs->delete($self->cgi);
	}

	my $pfields = $bs->fields($self->cgi);
	my $pelements = $bs->elements($self->cgi);
	$self->_formTitle($langO->string("BARCODE_RECOGNITION"));
	if ($adm eq "new" or $adm eq "edit") {
		$self->_displayInputForm($pfields,"bs");
	} else {
		$self->_displayExistingElements($pelements,"bs");
	}
}

# -----------------------------------------------

=head1 _barcodeProcessing($self)

	IN: object (self)
	OUT: -

	This is the main method which handles the barcode processing form.
	The appropiate module is loaded and depending on the user action
	the right method is selected.

=cut

sub _barcodeProcessing
{
  my $self = shift;
	my $langO = $self->archive->lang;
	my $cgiO = $self->cgi;
	my $archiveO = $self->archive;
	my $adm = $self->cgi->param("adm");

	my $bp = PL::BarcodeProcessing->new($archiveO);

	if ($cgiO->param("adm") eq "save" &&
			$cgiO->param("submit") ne $langO->string("BACK")) {
		$bp->save($self->cgi);
	} elsif ($cgiO->param("adm") eq "delete") {
		$bp->delete($self->cgi);
	}

  my $pselection = $bp->selection($self->cgi);
  my $pfields = $bp->fields($self->cgi);
	my $pelements = $bp->elements($self->cgi);
	$self->_formTitle($langO->string("BARCODE_PROCESSING"));
 	$self->_displaySelectionForm($pselection,"bp");
	if ($adm eq "new" or $adm eq "edit") {
		$self->_displayInputForm($pfields,"bp");
	} else {
		$self->_displayExistingElements($pelements,"bp");
	}
}






# -----------------------------------------------
# PUBLIC METHODS

=head1 new($cls,$mainO)

	IN: class name
	    object (PL::Main)
	OUT: object

	Constructor

=cut

sub new
{
  my $cls = shift;
  my $mainO = shift; # Object of PL::Main
	my $self = {};

  bless $self, $cls;

	$self->{'cgiO'} = $mainO->cgi;
  $self->{'archiveO'} = $mainO->archive;
  $self->{'configO'} = $mainO->config;
  $self->{'error'} = $mainO->error;

	return $self;
}

# -----------------------------------------------

=head1 main($self)

	IN: object (self)
	OUT: string

	Depending on which administration form the user is requesting, this method
	calls the appropriate method to display the requested form.

	The return value is the whole HTML code returned to the browser 

=cut

sub main
{
  my $self = shift;
  my $cgiO = $self->cgi;

  if ($self->cgi->param("ua") == 1) {
		$self->_userAdministration;
	} elsif ($self->cgi->param("ue") == 1) {
		$self->_userExternal;
	} elsif ($self->cgi->param("ug") == 1) {
		$self->_userGroups;
	} elsif ($self->cgi->param("fd") == 1) {
		$self->_fieldDefinition;
	} elsif ($self->cgi->param("md") == 1) {
		$self->_maskDefinition;
	} elsif ($self->cgi->param("fr") == 1) {
		$self->_formRecognition;
	} elsif ($self->cgi->param("lr") == 1) {
		$self->_logoRecognition;
	} elsif ($self->cgi->param("da") == 1) {
		$self->_databaseAdministration;
	} elsif ($self->cgi->param("sa") == 1) {
		$self->_scanDefinitionAdministration;
  } elsif ($self->cgi->param("ld") == 1) {
      $self->_ocrDefinitionAdministration;
	} elsif ($self->cgi->param("bs") == 1) {
		$self->_barcodeSettings;
	} elsif ($self->cgi->param("bp") == 1) {
		$self->_barcodeProcessing;
	} elsif ($self->cgi->param("sq") == 1) {
		$self->_sqlDefinition;
	} elsif ($self->cgi->param("ed") == 1) {
		$self->_exportDocs;
	} elsif ($self->cgi->param("ml") == 1) {
		$self->_mailArchiving;
	} elsif ($self->cgi->param("ja") == 1) {
		$self->_jobAdmin;
	} elsif ($self->cgi->param("oc") == 1) {
		$self->_ocrLimit;
	}

  $self->_header;
  $self->{'html'} .= $cgiO->start_table({-border => 0,
	                                       -cellspacing => 0,
																				 -cellpadding => 0,
																				 -width => '100%'});
	$self->{'html'} .= $cgiO->Tr($cgiO->td({-valign => 'top',
																					-width => 249},$self->_menu),
															 $cgiO->td({-width => 30},"&nbsp;"),
															 $cgiO->td({-valign => 'top'},$self->_main));
 
  $self->{'html'} .= $cgiO->end_table;
	
	return $self->{'html'};
}

# -----------------------------------------------

=head1 header($self,$cookie)

	IN: object (self)
	    cookie string
	OUT: string

	Return the HTML header (all tags until <BODY>)

=cut

sub header
{
  my $self = shift;
  my $cookie = shift;

  my ($html);
	my $www = $self->config->get("WWW_DIR");
	my $styles = $www . $self->config->get("STYLES");
	my $fr = qq|<style type="text/css">#centered { position:absolute; |.
	         qq|top:50%; left:50%; width:64em; height:36.2em; |.
					 qq|margin-left:-32em; margin-top:-18.1em; border:1px |.
           qq|solid #888; padding:0em; }</style>|;
	my $javascript = $www . "/js/functions.js";

  if (defined $cookie) {
		$html = $self->cgi->header(-cookie => $cookie);
	} else {
		$html = $self->cgi->header;
	}
	$html .= $self->cgi->start_html(-title => 'Archivista WebAdmin',
		-author => 'Urs Pfister upfister@archivista.ch',
		-style => {-src => $styles},
		-head => $fr,
		-script => {-src => $javascript});

  return $html;
}

# -----------------------------------------------

=head1 login($self)

	IN: object (self)
	OUT: string

	This method is used to call the login form thru PL::Main

=cut

sub login
{
  my $self = shift;
	
	my $cgiO = $self->cgi;
	
	my $print = "";
	if (!-e '/etc/nologinext.conf') {
	  $print .= "<p>";
	  $print .= qq|<a href="/perl/avclient/index.pl">WebClient</a>\n|;
	  $print .= " - ";
		if (-e '/etc/erp.conf') {
	    $print .= qq|<a href="/erp">WebERP</a>\n|;
	    $print .= " - ";
		}
	  $print .= qq|<a href="/cgi-bin/webadmin/index.pl">WebAdmin</a>\n|;
	  $print .= " - ";
	  $print .= qq|<a href="/perl/webconfig/index.pl">WebConfig</a>\n|;
	  $print .= " - ";
	  $print .= qq|<a href="/manual.pdf">Manual</a>\n|;
	  $print .= " - ";
	  $print .= qq|<a href="/handbuch.pdf">Handbuch</a>\n|;
	  $print .= "<p>\n\n";
	}
  my $html = $print.qq|<div id="centered">|.$self->_borderTable().qq|</div>|;
  return $html;
}

# -----------------------------------------------

=head1 footer($self)

	IN: object (self)
	OUT: string

	Close the HTML document

=cut

sub footer
{
  my $self = shift;

  return $self->cgi->end_html;
}

# -----------------------------------------------

=head1 cgi($self)

	IN: object (self)
	OUT: object (CGI.pm)

	Return the CGI.pm object

=cut

sub cgi
{
  my $self = shift;

	return $self->{'cgiO'};
}

# -----------------------------------------------

=head1 archive($self)

	IN: object (self)
	OUT: object (Archivista::BL::Archive)

	Return the archive object (link to APCL)

=cut

sub archive
{
  my $self = shift;

	return $self->{'archiveO'};
}

# -----------------------------------------------

=head1 config($self)

	IN: object (self)
	OUT: object (ASConfig.pm)

	Return the webadmin config object

=cut

sub config
{
  my $self = shift;

	return $self->{'configO'};
}

1;

__END__

=head1 EXAMPLE


=head1 TODO


=head1 AUTHOR


=cut

# Log record
# $Log: HTML.pm,v $
# Revision 1.10  2010/03/04 11:08:25  upfister
# Update for flexible scan definitions
#
# Revision 1.9  2009/10/14 08:08:53  upfister
# Update for job administration
#
# Revision 1.8  2009/07/20 19:58:55  upfister
# Limit ocr recognition for a time period
#
# Revision 1.7  2009/03/13 12:50:34  upfister
# Updated version (italian)
#
# Revision 1.6  2008/12/21 11:02:29  upfister
# Mail archiving (no attachments)
#
# Revision 1.5  2008/12/19 20:20:30  upfister
# Add mail move / mail restore folder
#
# Revision 1.4  2008/12/15 22:43:13  upfister
# Mail archiving: add not activated
#
# Revision 1.3  2008/11/27 22:03:24  upfister
# Mail archiving form
#
# Revision 1.2  2008/11/21 00:14:53  upfister
# Update User setting while uploading
#
# Revision 1.1.1.1  2008/11/09 09:21:02  upfister
# Copy to sourceforge
#
# Revision 1.27  2008/08/16 01:45:49  up
# Error message when connecting
#
# Revision 1.26  2008/08/15 17:29:26  up
# Now strings in default language
#
# Revision 1.25  2008/08/15 17:07:24  up
# Layout change
#
# Revision 1.24  2008/08/15 07:56:06  up
# Explorer css correction
#
# Revision 1.23  2008/08/15 07:28:11  up
# Centered form for WebAdmin
#
# Revision 1.22  2008/05/28 08:08:47  up
# Get default language
#
# Revision 1.21  2008/05/19 23:13:26  up
# Ext login incl. ERP
#
# Revision 1.20  2008/05/19 19:35:55  up
# Extended login mask
#
# Revision 1.19  2008/05/12 06:48:01  up
# Added French language
#
# Revision 1.18  2008/01/18 20:19:55  up
# New field in ue -> ue_defuser
#
# Revision 1.17  2008/01/15 07:11:34  up
# Switch between not modified user names and lowercase ones (UPPERCASE groups)
#
# Revision 1.16  2007/11/23 01:22:23  up
# Changed default name for def (always parname)
#
# Revision 1.15  2007/11/22 22:01:30  up
# Connect from value
#
# Revision 1.14  2007/11/08 15:51:51  up
# Add new form for export documents
#
# Revision 1.13  2007/08/18 15:46:38  rn
# Add Domain and Base DN to User-Menu
#
# Revision 1.12  2007/07/29 21:46:51  up
# Added external acces via (LDAP/HTTP)
#
# Revision 1.11  2007/07/05 18:53:45  up
# Add test flag for form recognition
#
# Revision 1.10  2007/06/24 04:32:08  up
# Added choosing logo definition
#
# Revision 1.9  2007/06/23 05:25:13  up
# Add form for logo recognition
#
# Revision 1.8  2007/06/08 10:11:57  up
# One more space between New and Paste
#
# Revision 1.7  2007/05/31 14:44:42  rn
# Add copy&paste functionality to WebAdmin in
# ScanDefinition,OCRDefinition and SQLDefinition forms.
#
# Revision 1.6  2007/05/31 07:13:08  rn
# Cleaning Code
#
# Revision 1.5  2007/04/09 22:57:17  up
# Add 100px to labels for input form (explorer fix)
#
# Revision 1.4  2007/03/27 15:21:49  rn
# Add FormRecognition. (not finished)
# Add Display and Process to FormRecognition.
#
# Revision 1.3  2007/03/21 17:46:04  up
# Add form recognition (not yet finished)
#
# Revision 1.2  2007/02/14 03:31:15  up
# Button 'save' did not show full text
#
# Revision 1.1.1.1  2007/02/10 14:15:24  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.14  2006/11/07 17:08:38  up
# Changes for updating scan definitions
#
# Revision 1.13  2006/11/07 11:47:28  up
# SPACE between html elements for better debugging
#
# Revision 1.12  2006/03/06 09:35:55  up
# Archiving job and mask corrections (comp. RichClient)
#
# Revision 1.11  2006/02/24 09:50:10  up
# Changes for new form (SQL definitions)
#
# Revision 1.10  2005/12/01 13:12:54  ms
# Added POD
#
# Revision 1.9  2005/11/29 10:33:02  ms
# Adapt layout to Internet Explorer
#
# Revision 1.8  2005/11/15 13:20:30  ms
# Reimplementing escape for URL encoding
#
# Revision 1.7  2005/11/15 12:28:40  ms
# Updates Herr Wolff
#
# Revision 1.6  2005/11/07 12:24:16  ms
# Display localhost login input field based upon the configuration file
#
# Revision 1.5  2005/10/29 17:08:43  up
# Correct form layout on large screens
#
# Revision 1.4  2005/10/27 21:35:12  up
# Correction for middle centered form
#
# Revision 1.1  2005/07/19 09:14:22  ms
# Initial import for new CVS structure
#
# Revision 1.26  2005/07/12 17:13:01  ms
# Entwicklung an BarcodeProcess
#
# Revision 1.25  2005/07/11 16:45:02  ms
# Implementing Barcode-Recognition Module
#
# Revision 1.24  2005/07/08 17:26:10  ms
# Anpassungen menu
#
# Revision 1.23  2005/07/08 16:51:02  ms
# Neues Menu
#
# Revision 1.22  2005/06/18 21:46:38  ms
# Bugfix: display the table header if no elements found!
#
# Revision 1.21  2005/06/17 18:21:56  ms
# Implementation scan from webclient
#
# Revision 1.20  2005/06/15 15:47:32  ms
# Implementation ScanDefAdministration
#
# Revision 1.19  2005/06/10 17:37:14  ms
# Remove publish menu item
#
# Revision 1.18  2005/06/08 16:57:01  ms
# Fertigstellung Archiv verwalten und Publizieren
#
# Revision 1.17  2005/06/01 13:19:58  ms
# Implementierung der neuen passwort abfrage
#
# Revision 1.16  2005/05/27 16:41:23  ms
# Bugfix
#
# Revision 1.15  2005/05/27 15:43:38  ms
# Entwicklung an database administration
#
# Revision 1.14  2005/05/26 15:53:48  ms
# Anpassungen für LinuxTag
#
# Revision 1.13  2005/05/12 17:56:32  ms
# Anpassungen damit tabelle in user admin noch auf dem bildschirm sichtbar ist
#
# Revision 1.12  2005/05/12 13:02:28  ms
# Last changes vor v.1.0
#
# Revision 1.11  2005/05/11 18:23:49  ms
# Entwicklung masken definitionen
#
# Revision 1.10  2005/05/06 15:43:39  ms
# Edit mask name, sql definitions for user
#
# Revision 1.9  2005/05/04 16:59:29  ms
# Entwicklung an Masken Definition
#
# Revision 1.8  2005/04/29 16:23:42  ms
# Entwicklung an masken definition
#
# Revision 1.7  2005/04/28 16:40:45  ms
# Implementierung der felder definition (alter table)
#
# Revision 1.6  2005/04/27 17:02:43  ms
# *** empty log message ***
#
# Revision 1.5  2005/04/22 17:28:27  ms
# Entwicklung create/drop database
#
# Revision 1.4  2005/04/21 16:40:22  ms
# Entwicklung an Benutzerverwaltung
#
# Revision 1.3  2005/04/20 18:43:17  ms
# Weiterentwicklung: Integration der Sprachenstrings
#
# Revision 1.2  2005/04/15 18:19:31  ms
# Entwicklung login maske / session
#
# Revision 1.1.1.1  2005/04/14 17:44:19  ms
# Import project
#
