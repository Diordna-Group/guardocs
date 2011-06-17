# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:21:01 $

package PL::FormRecognition;

use strict;

use lib qw(/home/cvs/archivista/jobs);
use AVWebElements;
use HTML::Table;
use Wrapper;

sub html {wrap(@_)} # AVWebElement object
sub cgi {wrap(@_)} # CGI object
sub dbh {wrap(@_)} # database handler
sub fields {@{wrap(@_)}} # fields for detail view
sub vals {@{wrap(@_)}} # values for fields 
sub lang {wrap(@_)} # string class
sub def_nrs {@{wrap(@_)}} # numbers from definitions
sub def_names {@{wrap(@_)}} # names from definitions
sub def_ocrs {@{wrap(@_)}} # ocr definition for form recognition
sub def_vals {@{wrap(@_)}} # values from definitions
sub mode {wrap(@_)} # mode: 0=overview, 1=detailview
sub def_nr {wrap(@_)} # the activated definition
sub def_id {wrap(@_)} # the current entry in the activated definition



=head1 new($cls,$archiveO,$cgiO)

Constructur
	
=cut

sub new {
  my $cls = shift;
  my $archiveO = shift; # Object of Archivista::BL::Archive (APCL)
	my $cgiO = shift;
	my $self = {};
	bless $self,$cls;
	my @fields = qw(fr_object fr_left fr_top fr_width fr_height fr_type
	                fr_from fr_to fr_field fr_start fr_end fr_script);
	$self->fields(\@fields); # element fields for form recognition
	$self->cgi($cgiO); # current cgi programm
	$self->html(AVWebElements->new($cgiO)); # html object
	$self->dbh($archiveO->db->dbh); # database connection
	$self->lang($archiveO->lang); # languages strings
	$self->loadDefs; # get the current definitions
  return $self;
}






=head1 loadDefs

Load the current form recognition forms

=cut

sub loadDefs {
  my $self = shift;
  my $sql = "select Art,Name,Inhalt from parameter where ".
	          "Art LIKE 'FormRecognition__' and Tabelle='archiv' order by Art";
	my $prows = $self->dbh->selectall_arrayref($sql);
	my (@nrs,@names,@vals,@ocrs);
	foreach my $prow (@$prows) {
	  push @nrs, $$prow[0];
		my ($name,$ocr) = split(/;/,$$prow[1]);
	  push @names, $name;
		push @ocrs,$ocr;
	  push @vals, $$prow[2];
	}
	$self->def_nrs(\@nrs);
	$self->def_names(\@names);
	$self->def_ocrs(\@ocrs);
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
	$nr =~ s/(FormRecognition)([0-9])/$2/;
	$nr++;
	my $nr1 = "FormRecognition".sprintf("%02d",$nr);
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
		my $name = $self->cgi->param("rename");
		$name =~ s/;/ /g;
		$name = $name.";".$ocr;
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
			$id =~ s/(go\_edit)(\_)([0-9])(.*)$/$3/;
			if ($id>0) {
			  # edit an element
	      $self->mode(1);
				$self->def_id($id);
			} else {
			  # delete an element
			  $id = $cmd;
			  $id =~ s/(go\_del)(\_)([0-9])(.*)$/$3/;
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
	my $obj = ($self->def_nrs)[$self->def_nr];
	my $field = "Inhalt";
	my $vals = ($self->def_vals)[$self->def_nr];
	my $c=0;
  foreach ($self->fields) {
	  my $val = $self->cgi->param($_);
 	  if ($c>=1 and $c<=4) {
      $val = $self->_parseToTwain($val);
		}
		$val =~ s/;/ /g;
	  $out.=$val.";";
		$c++;
	}
	my $id = $self->cgi->param("id");
	if ($id==0) { # we have a new element
	  $outall=$vals;
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
	$html .= $self->html->hidden(name=>'fr',value=>'1');
	$html .= $self->html->hidden(name=>'level',value=>'006');
	my $tbl = HTML::Table->new(-padding=>0,-spacing=>1);
  if ($self->mode==0) {
	  $self->display_overview($tbl); # choose, rename, delete and create defs
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
	                  elements=>\@defs,default=>$def,style=>'width: 100%'));
	$tbl->setCell(1,3,$self->html->submitbutton(value=>$lblseldef, 
	                  name=>'go_seldef',css_class=>'ButtonDefs'));
	$tbl->setCell(1,4,$self->html->submitbutton(value=>$lbldeldef, 
	                  name=>'go_deldef',css_class=>'ButtonDefs'));
	$tbl->setCell(2,2,$self->html->textfield(name=>"rename",default=>"$def"));
	$tbl->setCell(2,3,$self->html->submitbutton(value=>$lblchange, 
	                  name=>'go_rename',css_class=>'ButtonDefs'));

	$tbl->setCell(3,2,$self->html->textfield(name=>"create",default=>''));
	$tbl->setCell(3,3,$self->html->submitbutton(value=>$lblcreate, 
	                  name=>'go_create',css_class=>'ButtonDefs'));
										
	$tbl->setCell(4,1,"&nbsp;");
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
                    default=>$ocrname,style=>'width: 100%'));
	$tbl->setCell(5,3,$self->html->submitbutton(value=>$lblsave, 
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
  my $akt = 6;
	if (($self->def_names)[0] ne "") {
	  $tbl->setCell($akt,1," ");
	  $tbl->setCell($akt,2," ");
	  $tbl->setCellClass($akt,1,'ElementWhite');
	  $tbl->setCellClass($akt,2,'ElementWhite');
	  $akt++;
	  my $add =	$self->html->submitbutton(value=>$lblnew,
	                   name=>"go_add",css_class=>"New");
	  $tbl->setCell($akt,1,$add);
	  $tbl->setCell($akt,2," ");
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
	  my $mod = $self->html->submitbutton(value=>$lbledit,
		          name=>"go_edit_$id",css_class=>"Edit") . "  " .
	            $self->html->submitbutton(value=>$lbldel,
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
 	  if ($el>=1 and $el<=4) {
      $val = $self->_parseToMM($val);
		}
	  my $lbl = $self->lang->string(uc($obj));
    $tbl->setCell($rakt,1,$self->html->label(name=>$lbl,bold=>0));
		$tbl->setCellWidth($rakt,1,"250px");
		if ($obj eq 'fr_field') {
		  my @arr = @{$self->dbfields("archiv")};
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
		} else {
	    $tbl->setCell($rakt,2,$self->html->textfield(name=>$obj,
			                      default=>"$val"));
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
	my $butt = $self->html->submitbutton(value=>$lblback,name=>'go_back').
	           "  ".$self->html->submitbutton(value=>$lblsave,name=>'go_save');
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
	return \@dbflds;
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

Read twain to mm

=cut

sub _parseToMM {
  my $self = shift;
  my $value = shift;
  return int (($value / 56.692) + 0.499);
}





1;

