# Current revision $Revision: 1.11 $
# Latest change by $Author: upfister $ on $Date: 2009/10/15 10:00:57 $

package PL::Form;

use strict;

use lib qw(/home/cvs/archivista/jobs);
use AVWebElements;
use HTML::Table;
use Wrapper;

sub html {wrap(@_)} # AVWebElement object
sub cgi {wrap(@_)} # CGI object
sub dbh {wrap(@_)} # database handler
sub parname {wrap(@_)} # form definition long name
sub shortname {wrap(@_)} # form definition short name
sub type {wrap(@_)} # type of elements
sub formnr {wrap(@_)} # formnr for hidden field
sub fields {@{wrap(@_)}} # fields for detail view
sub vals {@{wrap(@_)}} # values for fields 
sub lang {wrap(@_)} # string class
sub def_nrs {@{wrap(@_)}} # numbers from definitions
sub def_names {@{wrap(@_)}} # names from definitions
sub def_ocrs {@{wrap(@_)}} # ocr definition for form recognition
sub def_logos {@{wrap(@_)}} # values from definitions
sub def_vals {@{wrap(@_)}} # values from definitions
sub mode {wrap(@_)} # mode: 0=overview, 1=detailview
sub def_nr {wrap(@_)} # the activated definition
sub def_id {wrap(@_)} # the current entry in the activated definition

use constant SIMPLE => 0; # simple form (only one definition)    
use constant MULTI => 1; # more then one definition
use constant FLAT => 2; # only single entries
use constant FORM_RECOGNITION => "FormRecognition";
use constant LOGO_RECOGNITION => "LogoRecognition";
use constant USER_EXTERN => "UserExtern";
use constant USER_GROUPS => "UserGroups";
use constant EXPORT_DOCS => "ExportDocs";
use constant MAILS => 'MailArchiving';
use constant OCRLIMIT => 'OCRLIMIT';
use constant JOBADMIN => 'JOBADMIN';



=head1 new($cls,$archiveO,$cgiO)

Constructur
	
=cut

sub new {
  my $cls = shift;
	my $dbh = shift;
	my $lang = shift;
	my $cgi = shift;
	my $short = shift;
	my $pfields = shift;
	my ($parname,$type,$formnr);
	if ($short eq "fr") {
    $parname = FORM_RECOGNITION;
		$type = MULTI;
		$formnr = "006";
	} elsif ($short eq "lr") {
    $parname = LOGO_RECOGNITION;
		$type = SIMPLE;
		$formnr = "006.001";
	} elsif ($short eq "ue") {
    $parname = USER_EXTERN;
		$type = FLAT;
		$formnr = "001.002";
	} elsif ($short eq "ug") {
    $parname = USER_GROUPS;
		$type = SIMPLE;
	} elsif ($short eq "ed") {
    $parname = EXPORT_DOCS;
		$type = FLAT;
	} elsif ($short eq "ml") {
    $parname = MAILS;
		$type = SIMPLE;
	} elsif ($short eq "oc") {
	  $parname = OCRLIMIT;
		$type = FLAT;
	} elsif ($short eq "ja") {
	  $parname = JOBADMIN;
		$type = SIMPLE;
	}
	my $self = {};
	bless $self,$cls;
	$self->fields($pfields); # element fields for form recognition
	$self->cgi($cgi); # current cgi programm
	$self->html(AVWebElements->new($cgi)); # html object
	$self->dbh($dbh); # database connection
	$self->lang($lang); # languages strings
	$self->shortname($short); # short name for viewing form
	$self->parname($parname); # parameter to load
	$self->type($type);
	$self->formnr($formnr);
	$self->loadDefs; # get the current definitions
  return $self;
}






=head1 loadDefs

Load the current form recognition forms

=cut

sub loadDefs {
  my $self = shift;
  my $sql = "select Art,Name,Inhalt from parameter where ".
	          "Art LIKE '".$self->parname."__' and Tabelle='archiv' order by Art";
	my $prows = $self->dbh->selectall_arrayref($sql);
	my (@nrs,@names,@vals,@ocrs,@logos);
	foreach my $prow (@$prows) {
	  push @nrs, $$prow[0];
		my ($name,$ocr,$logo) = split(/;/,$$prow[1]);
	  push @names, $name;
		push @ocrs,$ocr;
		push @logos,$logo;
	  push @vals, $$prow[2];
	}
	$self->def_nrs(\@nrs);
	$self->def_names(\@names);
	$self->def_ocrs(\@ocrs);
	$self->def_logos(\@logos);
	$self->def_vals(\@vals);
}






=head1 updateDef($defname,$field,$value)

Update a definition 

=cut

sub updateDef {
  my $self = shift;
	my $nr = shift;
	my $field = shift;
	my $value = shift;
  my $sql = "update parameter set $field=".$self->dbh->quote($value)." ".
	          "where Art='$nr' and Tabelle='archiv'";
	$self->dbh->do($sql);
	$self->loadDefs;
}






=head1 addDef($name)

Add a new definition with a given name

=cut

sub addDef {
  my $self = shift;
	my $name = shift;
	my $nr = ($self->def_nrs)[-1];
	my $parname = $self->parname;
	$nr =~ s/($parname)([0-9]+)/$2/;
	$nr++;
	my $nr1 = $parname.sprintf("%02d",$nr);
  my $sql = "insert into parameter set Tabelle='archiv',Art='$nr1',".
	          "Name=".$self->dbh->quote($name).",Inhalt=''";
	$self->dbh->do($sql);
	$self->loadDefs;
}






=head1 deleteDef($defnr)

Delete the desired definition from the database

=cut

sub deleteDef {
  my $self = shift;
	my $nr = shift;
	my $sql = "delete from parameter where Art='$nr' and Tabelle='archiv'";
	$self->dbh->do($sql);
	$self->loadDefs;
	$self->def_nr(0);
}






=head1 process

Process the input (modifies the definitions according the actions)

=cut

sub process {
  my $self = shift;
	# according the current definition activate it
	# ATTENTION: Activation is done by name, not by id (Art field),
	# this means that the names must be unique
	$self->process_activate;
	if ($self->cgi->param("go_seldef")) {
	  # nothing to do, we always check for the current definition
	} elsif ($self->cgi->param("go_deldef")) {
	  $self->deleteDef(($self->def_nrs)[$self->def_nr]); # delete a definition
	} elsif ($self->cgi->param("go_create")) {
	  my $name = $self->cgi->param("create");
		$self->addDef($name) if $name ne ""; # create a definition
	} elsif ($self->cgi->param("go_rename")) { 
	  my $obj = ($self->def_nrs)[$self->def_nr];
		my $ocr = $self->cgi->param("ocr");
		my $logo = $self->cgi->param("logo");
		my $name = $self->cgi->param("rename");
		$name =~ s/;/ /g;
		$name = $name.";".$ocr.";".$logo;
	  $self->updateDef($obj,"Name",$name); # rename a definition
	} elsif ($self->cgi->param("go_add")) {
	  $self->mode(1); # switch to single element mode
	} elsif ($self->cgi->param("go_save")) {
	  $self->process_save; # save a single elment
	} else {
	  foreach ($self->cgi->param()) {
		  # check for edit/delete of single elements
		  my $cmd = $_;
			my $id = $cmd;
			$id =~ s/(go\_edit)(\_)([0-9]+)(.*)$/$3/;
			if ($id>0) {
			  # edit an element
	      $self->mode(1);
				$self->def_id($id);
			} else {
			  # delete an element
			  $id = $cmd;
			  $id =~ s/(go\_del)(\_)([0-9]+)(.*)$/$3/;
				if ($id>0) {
				  # do it only if we got back an element id
	        my $val = ($self->def_vals)[$self->def_nr];
					my @lines = split(/\r\n/,$val);
					$id--;
					splice @lines,$id,1;
					$val = join("\r\n",@lines);
	        my $obj = ($self->def_nrs)[$self->def_nr];
	        my $field = "Inhalt";
	        $self->updateDef($obj,$field,$val);
				}
			}
		}
	}
}






=head1 process_activate

Activate the current definition

=cut

sub process_activate {
  my $self = shift;
  if ($self->cgi->param("defs") ne "") {
	  my $name = $self->cgi->param("defs");
		my $c = 0;
		my $akt = 0;
		foreach ($self->def_names) {
		  if ($_ eq $name) {
		    $akt=$c;
				last;
			}
			$c++;
		}
		$self->def_nr($akt);
	}
}






=head1 process_save  

Save the current element to the definition

=cut

sub process_save {
  my $self = shift;
  my $out="";
	my $outall="";
	my $obj=$self->parname."01";
	if ($self->type != FLAT) {
	  # get the current object name
	  $obj = ($self->def_nrs)[$self->def_nr]; 
	} else {
	  # in FLAT mode we always have only 1 entry AND it must EXIST
	  my $dbh = $self->dbh;
	  my $sql="select Laufnummer from parameter where Name=".$dbh->quote($obj);
		my @row=$dbh->selectrow_array($sql);
		$self->addDef($obj) if $row[0]==0;
	}
	my $field = "Inhalt";
	my $vals = ($self->def_vals)[$self->def_nr];
	my $c=0;
  foreach ($self->fields) {
	  my $val = $self->cgi->param($_);
 	  if ($c>=1 and $c<=4 && $self->parname eq FORM_RECOGNITION) {
      $val = $self->_parseToTwain($val);
		}
		if ($c>=2 and $c<=3 && $self->parname eq LOGO_RECOGNITION) {
      $val = $self->_parseToTwain($val);
		}
		if ($c>=4 and $c<=4 && $self->parname eq MAILS) {
		  $val = unpack("H*",$val);
		}
		if ($c>=7 and $c<=7 && $self->parname eq JOBADMIN) { 
		  $val = unpack("H*",$val);
		}
		if ($c>=3 and $c<=3 && $self->parname eq JOBADMIN) {
		  $val = escape($val);
		}
		$val =~ s/;/ /g;
	  $out.=$val.";";
		$c++;
	}
	my $id = $self->cgi->param("id");
	if ($id==0) { # we have a new element
		# hold the old elements if we are NOT in FLAT mode 
	  $outall=$vals if $self->type != FLAT; 
		$outall.="\r\n" if $outall ne "";
	  $outall.=$out;
	} else { # replace an existing element
	  $self->def_id($id);
		my @lines = split(/\r\n/,$vals);
		$id--;
		$lines[$id]=$out;
		$outall = join("\r\n",@lines);
	}
	$self->updateDef($obj,$field,$outall);
}






=head1 display

Print out the table with all the form information

=cut

sub display {
  my $self = shift;
	my $html = $self->cgi->start_form;
	my $ft = $self->shortname;
	$html .= $self->html->hidden(name=>$ft,value=>'1');
	$html .= $self->html->hidden(name=>'level',value=>$self->formnr);
	my $tbl = HTML::Table->new(-padding=>0,-spacing=>1);
	if ($self->type == FLAT) {
	  $self->display_detail($tbl,\$html); # edit the current selected element
  } elsif ($self->mode==0) {
	  if ($self->type == MULTI) {
	    $self->display_overview($tbl); # choose, rename, delete and create defs
		}
		$self->display_elements($tbl); # show elements from current form
	} else {
	  $self->display_detail($tbl,\$html); # edit the current selected element
	}
  $html .= $tbl->getTable(); # compose the table
	$html .= $self->cgi->end_form;
	return $html;
}






=head1 display_overview($tbl)

Create the overview table part

=cut

sub display_overview {
  my $self = shift;
	my $tbl = shift;
  my $lblseldef = $self->lang->string("SELECT");
  my $lbldeldef = $self->lang->string("DELETE");
  my $lblchange = $self->lang->string("CHANGE");
	my $lblcreate = $self->lang->string("CREATE");
  my $lblsave = $self->lang->string("SAVE");
	$tbl->setCell(1,1,$self->lang->string("MASK"));
	$tbl->setCellWidth(1,1,"180px");
	my @defs = $self->def_names;
	my $def = ($self->def_names)[$self->def_nr];
	$tbl->setCell(1,2,$self->html->dropdown(name=>"defs",
#	                  elements=>\@defs,default=>$def,style=>'width: 100%'));
	                  elements=>\@defs,default=>$def,));
	$tbl->setCell(1,3,$self->html->submit(value=>$lblseldef, 
	                  name=>'go_seldef',css_class=>'ButtonDefs'));
	$tbl->setCell(1,4,$self->html->submit(value=>$lbldeldef, 
	                  name=>'go_deldef',css_class=>'ButtonDefs'));
	$tbl->setCell(2,2,$self->html->textfield(name=>"rename",default=>"$def"));
	$tbl->setCell(2,3,$self->html->submit(value=>$lblchange, 
	                  name=>'go_rename',css_class=>'ButtonDefs'));

	$tbl->setCell(3,2,$self->html->textfield(name=>"create",default=>''));
	$tbl->setCell(3,3,$self->html->submit(value=>$lblcreate, 
	                  name=>'go_create',css_class=>'ButtonDefs'));
										
	$tbl->setCell(4,1,"&nbsp;");
	if ($self->parname eq FORM_RECOGNITION) {
	  $self->showOCRSets($tbl,$lblsave);
		$self->showLogoSets($tbl,$lblsave);
  }
}






=head1 showOCRSets($tbl)

Show ocr sets in form recognition

=cut

sub showOCRSets {
  my $self = shift;
	my $tbl = shift;
	my $lblsave = shift;
	$tbl->setCell(5,1,$self->lang->string("BOX_OCRDEF"));
  my $sql = "select Inhalt from parameter where Name = 'OCRSets'";
  my @ocr1 = $self->dbh->selectrow_array($sql);
	my @ocr = split(/\r\n/,$ocr1[0]);
	my $c=0;
	foreach (@ocr) {
	  my @el = split(/;/,$_);
		$ocr[$c]=$el[0];
		$c++;
	}
	my $ocrname = ($self->def_ocrs)[$self->def_nr];
	$tbl->setCell(5,2,$self->html->dropdown(name=>"ocr",elements=>\@ocr,
#                    default=>$ocrname,style=>'width: 100%'));
                    default=>$ocrname,));
	$tbl->setCell(5,3,$self->html->submit(value=>$lblsave, 
	                  name=>'go_rename',css_class=>'ButtonDefs'));
}






=head1 showLogoSets($tbl)

Show logo recognition definitions

=cut

sub showLogoSets {
  my $self = shift;
	my $tbl = shift;
	my $lblsave = shift;
	$tbl->setCell(6,1,$self->lang->string("BOX_LOGODEF"));
  my $sql = "select Inhalt from parameter where Art like '" .
	          LOGO_RECOGNITION . "__'";
  my @logos = $self->dbh->selectrow_array($sql);
	my @logos1 = split(/\r\n/,$logos[0]);
	my $c=0;
	foreach (@logos1) {
	  my @el = split(/;/,$_);
		$logos1[$c]=$el[0];
		$c++;
	}
	unshift @logos1,"";
	my $logoname = ($self->def_logos)[$self->def_nr];
	$tbl->setCell(6,2,$self->html->dropdown(name=>"logo",elements=>\@logos1,
#                    default=>$logoname,style=>'width: 100%'));
                    default=>$logoname,));
	$tbl->setCell(6,3,$self->html->submit(value=>$lblsave, 
	                  name=>'go_rename',css_class=>'ButtonDefs'));

}






=head1 display_elements($tbl)

Show the edit/delete possiblie of the elements of the current def

=cut

sub display_elements {
  my $self = shift;
	my $tbl = shift;
  my $char = "›"; # hack for &rsaquo;
	my $lblnew = $char.$self->lang->string("NEW");
  my $lbledit = $char.$self->lang->string("EDIT");
  my $lbldel = $char.$self->lang->string("DELETE");
  my $lblname = "<b>".$self->lang->string("NAME")."</b>";
	my $akt;
	if ($self->parname eq FORM_RECOGNITION) {
    $akt = 7;
	} else {
	  $akt = 1;
	  if (($self->def_names)[0] eq "") {
      $self->addDef($self->parname);
		}
	}
	if (($self->def_names)[0] ne "") {
	  $tbl->setCell($akt,1," ");
	  $tbl->setCell($akt,2," ");
	  $tbl->setCellClass($akt,1,'ElementWhite');
	  $tbl->setCellClass($akt,2,'ElementWhite');
	  $akt++;
	  my $add =	$self->html->submit(value=>$lblnew,
	                   name=>"go_add",css_class=>"New");
	  $tbl->setCell($akt,1,$add);
		$tbl->setCellWidth($akt,1,"160px");
	  $tbl->setCell($akt,2,$lblname);
		$tbl->setCellWidth($akt,2,"320px");
	  $tbl->setCellSpan($akt,2,1,3);
	  $tbl->setCellClass($akt,1,'ElementHead');
	  $tbl->setCellClass($akt,2,'ElementHead');
	  $akt++;
	}
	my $val = ($self->def_vals)[$self->def_nr];
	my @lines = split(/\r\n/,$val);
	my $id=0;
	foreach (@lines) {
	  $id++;
	  my @entries = split(";",$_);
	  my $mod = $self->html->submit(value=>$lbledit,
		          name=>"go_edit_$id",css_class=>"Edit") . "  " .
	            $self->html->submit(value=>$lbldel,
						  name=>"go_del_$id",css_class=>"Del");
	  $tbl->setCell($akt,1,$mod);
		$tbl->setCell($akt,2,$entries[0]);
		$tbl->setCellSpan($akt,2,1,3);
	  $tbl->setCellClass($akt,1,'ElementRow');
	  $tbl->setCellClass($akt,2,'ElementRow');
		$akt++;
	}
}






=head1 display_detail($tbl,$phtml)

Display the edit form to change element values

=cut

sub display_detail {
  my $self = shift;
	my $tbl = shift;
	my $phtml = shift;
  my $lblback = $self->lang->string("BACK");
  my $lblsave = $self->lang->string("SAVE");
	my $val = ($self->def_vals)[$self->def_nr];
	my @lines = split(/\r\n/,$val);
	my $def = ($self->def_names)[$self->def_nr];
  $$phtml .= $self->html->hidden(name=>'defs',value=>"$def");
	my $id = $self->def_id;
  $$phtml .= $self->html->hidden(name=>'id',value=>"$id") if $id>0;
	$id--;
	my $line = $lines[$id];
	my @vals = split(/;/,$line);
	my $rakt = 2;
	my $el = 0;
	foreach ($self->fields) {
	  my $obj = $_;
		$val = "";
		$val = $vals[$el] if $vals[$el] ne "";
 	  if ($el>=1 and $el<=4 && $self->parname eq FORM_RECOGNITION) {
      $val = $self->_parseToMM($val);
		}
 	  if ($el>=2 and $el<=3 && $self->parname eq LOGO_RECOGNITION) {
      $val = $self->_parseToMM($val);
		}
		if ($el>=4 and $el<=4 && $self->parname eq MAILS) {
      $val = pack("H*",$val);
		}
		if ($el>=7 and $el<=7 && $self->parname eq JOBADMIN) { 
		  $val = pack("H*",$val);
		}
		if ($el>=3 and $el<=3 && $self->parname eq JOBADMIN) {
		  $val = unescape2($val);
		}
	  my $lbl = $self->lang->string(uc($obj));
    $tbl->setCell($rakt,1,$self->html->label($lbl));
		$tbl->setCellWidth($rakt,1,"150px");
		if ($obj eq 'fr_field' || $obj eq 'ml_from' ||
		    $obj eq 'ml_cc' || $obj eq 'ml_to' || $obj eq 'ml_subject') {
		  my @arr = @{$self->dbfields("archiv")};
			if ($obj eq 'ml_cc' || $obj eq 'ml_to' || 
			    $obj eq 'ml_from' || $obj eq 'ml_subject') {
				pop @arr;
        unshift @arr,"";
			}
      $tbl->setCell($rakt,2,$self->html->dropdown(name=>$obj,
			                      default=>"$val",elements=>\@arr));
		} elsif ($obj eq 'fr_type') {
		  my @arr = (0,1,2,3);
			my %hash;
			$hash{0} = $self->lang->string('FR_TYPE_CHAR');
			$hash{1} = $self->lang->string('FR_TYPE_NUMBER');
			$hash{2} = $self->lang->string('FR_TYPE_DATE')." (.)";
			$hash{3} = $self->lang->string('FR_TYPE_DATE')." (/)";
      $tbl->setCell($rakt,2,$self->html->dropdown(name=>$obj,
			                      default=>"$val",elements=>\@arr,labels=>\%hash));
		} elsif ($obj eq 'fr_test' || $obj eq 'ug_active' ||
		         $obj eq 'ed_deactivate' || $obj eq 'ue_lcuser' ||
						 $obj eq 'ue_upload' || $obj eq 'ml_ssl' || 
						 $obj eq 'ml_delete' || $obj eq 'ml_inactive' ||
						 $obj eq 'ml_attach' || $obj eq 'oc_limit' ||
						 $obj eq 'ja_update') {
      $tbl->setCell($rakt,2,$self->html->checkbox(name=>$obj,
			                      checked=>"$val",value=>"1"));
		} elsif ($obj eq 'ja_code') {
      $tbl->setCell($rakt,2,$self->html->textarea({name=>$obj,
			                      default=>"$val",rows=>"20"}));
		} elsif ($obj eq 'ue_mode') {
		  my @arr = (0,1,2);
			my %hash;
			$hash{0} = $self->lang->string('UE_MODE_MYSQL');
			$hash{1} = $self->lang->string('UE_MODE_LDAP');
			$hash{2} = $self->lang->string('UE_MODE_HTTP');
      $tbl->setCell($rakt,2,$self->html->dropdown(name=>$obj,
			                      default=>"$val",elements=>\@arr,labels=>\%hash));
		} elsif ($obj eq 'ug_intern' || $obj eq 'ml_owner') {
		  my @arr = @{$self->dbusers()};
			unshift @arr,"" if $obj eq 'ml_owner';
      $tbl->setCell($rakt,2,$self->html->dropdown(name=>$obj,
			                      default=>"$val",elements=>\@arr));
		} elsif ($obj eq 'ed_user') {
		  my @arr = @{$self->dbusers()};
			my $first = $self->lang->string('ED_USER_ONLINE');
			unshift @arr,$first;
      $tbl->setCell($rakt,2,$self->html->dropdown(name=>$obj,
			                      default=>"$val",elements=>\@arr));
	  } elsif ($obj eq 'ml_pw' || $obj eq 'ja_pw') {
	    $tbl->setCell($rakt,2,$self->html->password(name=>$obj,
			                      default=>"$val"));
		} elsif ($obj eq "ml_processing") {
		  my @arr = @{$self->scandefs()};
	    $tbl->setCell($rakt,2,$self->html->dropdown(name=>$obj,
	                  default=>"$val",elements=>\@arr));
		} else {
	    $tbl->setCell($rakt,2,$self->html->textfield(name=>$obj,
			                      default=>"$val",size=>"53"));
		}
	  $rakt++;
		$el++;
	}
	$rakt++;
  $tbl->setCell($rakt,1," ");
	$tbl->setCellSpan($rakt,1,1);
	$tbl->setCellClass($rakt,1,'ElementWhite');
	$tbl->setCellClass($rakt,2,'ElementWhite');
	$rakt++;
	my $butt = $self->html->submit(value=>$lblback,name=>'go_back').
	           "  ".$self->html->submit(value=>$lblsave,name=>'go_save');
	$tbl->setCell($rakt,2,$butt);
	$tbl->setCellAlign($rakt,2,'RIGHT');
}






=head1 dbfields($table,$all)

Give back the fields of table. If all=0, then only give back archivista fields

=cut

sub dbfields {
  my $self = shift;
	my $table = shift;
	my $all = shift;
	my $dbh = $self->dbh;
	my $sql = "describe $table";
	my $prows = $self->dbh->selectall_arrayref($sql);
	my (@dbflds);
	foreach my $prow (@$prows) {
		last if $$prow[0] eq "Notiz" && $all==0;
	  next if ($$prow[0] eq "Akte" || $$prow[0] eq "Seiten") && $all==0;
	  push @dbflds,$$prow[0];
	}
	push @dbflds,"Eigentuemer";
	return \@dbflds;
}






=head1 dbusers($table,$all)

Give back the users of a database

=cut

sub dbusers {
  my $self = shift;
	my $dbh = $self->dbh;
	my $sql = "select User from user group by user";
	my $prows = $self->dbh->selectall_arrayref($sql);
	my (@dbflds);
	foreach my $prow (@$prows) {
	  push @dbflds,$$prow[0];
	}
	return \@dbflds;
}






=head1 scandefs($self)

Give back the users of a database

=cut

sub scandefs {
  my $self = shift;
	my @res;
	my $dbh = $self->dbh;
	my $sql = "select Inhalt from parameter where Name='ScannenDefinitionen' ".
	          "and Art='parameter' and Tabelle='parameter' limit 1";
	my @def = $self->dbh->selectrow_array($sql);
	if ($def[0] ne "") {
	  my @names = split("\r\n",$def[0]);
		foreach my $line (@names) {
		  my @lbl = split(";",$line);
			push @res,$lbl[0] if $lbl[0] ne "";
		}
	}
  return \@res;	
}







=head1 logit

Write a message to the web log

=cut

sub logit {
  my $mess = shift;
  print STDERR "$0 =====> $mess\n";
}






=head1 _parseToTwain

Save mm to twain

=cut

sub _parseToTwain {
  my $self = shift;
  my $value = shift;
  return int (($value * 56.692) + 0.499);
}






=head1 _parseToMM

Read twain to mm (rounded to 0.x)

=cut

sub _parseToMM {
  my $self = shift;
  my $value = shift;
  my $value1 = ($value / 56.692);
	$value = sprintf("%0.1f",$value1);
}






=head1 $val=escape($val)

Quote special chars in value parts (axis/xerox/autofields)

=cut

sub escape {
  my $str = shift;
  $str =~ s/([^a-zA-Z0-9_.-])/sprintf("%%%02x", ord($1))/ge;
	return $str;
}






=head1 $val=unescape2($val)

Unquote special chars in value parts (axis/xerox/autofields)

=cut

sub unescape2 {
  my $str = shift;
  $str =~ tr/+/ /;
	$str =~ s/\\$//;
  $str =~ s/%([0-9a-fA-Z]{2})/pack("c",hex($1))/eg;
  $str =~ s/\r?\n/\n/g;
  $str =~ s/\&/&amp;/g;
  $str =~ s/\"/&quot;/g; 
  $str =~ s/\</&lt;/g;
  $str =~ s/\>/&gt;/g;
	return $str;
}



1;

