#!/usr/bin/perl

=head1 AVWebElements (c) 2008 by Archivista GmbH, Urs Pfister

Klass provides html elements for various ArchivistaBox products

=head2 Syntax

You can use the class either given an pointer to an hash or an array.

name value bold href default size maxlength readonly rows cols src
align css_class onChange checked elements labels onClick id linebreak

Examples: 

my %hash;
$hash{name} = 'The best Label ever';
$hash{bold} = 0;
$avwe->label(\%hash);

my @array;
$array[0] = 'name';
$array[1] = "The second best Label";
$array[2] = 'bold';
$array[3] = 0;
$avwe->label(@array);

=cut

package AVWebElements;

use strict;
use Wrapper;
use HTML::Table;

use constant UP_ARROW => '/avclient/pics/uarr.png'; # Path to the UP Arrow
use constant DWN_ARROW => '/avclient/pics/darr.png'; # Path to the DOWN Arrow

my @flds = qw(name value bold href default size maxlength readonly rows cols 
  src align css_class onChange checked elements labels onClick id linebreak);
							
sub cgi {wrap(@_)}
sub strings {wrap(@_)}
sub table {wrap(@_)}
sub name {wrap(@_)}
sub value {wrap(@_)} 
sub bold {wrap(@_)}   
sub href {wrap(@_)} 
sub default {wrap(@_)}
sub size {wrap(@_)} 
sub maxlength {wrap(@_)}
sub readonly {wrap(@_)} 
sub rows {wrap(@_)}
sub cols {wrap(@_)}
sub src {wrap(@_)}
sub align {wrap(@_)} 
sub css_class {wrap(@_)}
sub checked {wrap(@_)}
sub elements {wrap(@_)}
sub labels {wrap(@_)}
sub onClick {wrap(@_)}
sub onChange {wrap(@_)}
sub id {wrap(@_)}
sub linebreak {wrap(@_)}






=head1 new($strings)

Creating a new AVWebElements Object. Needs a AVStrings Object.

=cut

sub new {
  my $class = shift;
	my $strings = shift;
	my $self = {};
	bless $self,$class;
	$self->strings($strings) if $strings;
	return $self;
}






# _init_values([$phash|@array])
# initializes Object Attributes with the given elements.
#
sub _init_values {
  my $self = shift;
  foreach my $field (@flds) {
    $self->$field('');
  }
  my $phash;
  if (ref($_[0]) eq "HASH") {
	  $phash = $_[0];
  } else {
	  my %hash = @_;
		$phash = \%hash;
	}
  foreach my $key (keys %$phash) {
    my $keyname = $key;
    $keyname =~ s/^-//;
    $self->$keyname($phash->{$key});
  }
}






# _inputfield
# show inputfield tag (text/hidden,password...)
#
sub _inputfield {
  my $self = shift;
	my $typ = shift;
  $self->_init_values(@_);
	my $el="";
	if ($self->name) {
	  $el = qq|<input name="|.$self->name.qq|" type="$typ"|.$self->_opts.">";
	}
	return $el;
}






# _opts
# check for all options that have values
#
sub _opts {
  my $self = shift;
	my $html = "";
	foreach my $el (@flds) {
		if ($el ne "name" && $el ne "elements" && $el ne "labels" &&
		    $self->$el ne "") {
		  my $el1 = $el;
	    $el1 = "class" if $el1 eq "css_class";
	    $el1 = "value" if $el1 eq "default";
	    $html .= qq| $el1="|.$self->$el.qq|"|;
		}
	}
	return $html;
}






=head2 $html=label($name,$bold)

Print out a label, bold is optionally  

=cut

sub label {
  my ($self,$name,$bold) = @_;
	$name = "<strong>$name</strong>" if $bold;
	return $name;
}






=head2 $html=string($name,$bold)

Print out a translated label, bold is optionally 

=cut

sub string {
  my ($self,$name,$bold) = @_;
	$name = $self->strings->string($name);
	return $self->label($name,$bold);
}






=head2 $html=link

Give back a href ling (href,value)

=cut

sub link {
  my $self = shift;
  $self->_init_values(@_);
  my $el="";
  if($self->href ne '' and $self->value ne '') {
	  $el = qq|<a href="|.$self->href.qq|">|.$self->value."</a>\n";
		$el = "<strong>$el</strong>" if $self->bold;
	}
	return $el;
}






=head2 $html=textfield

Give back a textfield (name,default,size,maxlength,css_class)

=cut

sub textfield {
  my $self = shift;
	return $self->_inputfield("text",@_);
}






=head2 $html=textarea

Give back textarea field (name,default,rows,columns,readonly)

=cut

sub textarea {
  my $self = shift;
  $self->_init_values(@_);
  my $el="";
  if($self->name ne '') {
	  $el = qq|<textarea cols="95" name="|.$self->name.qq|"|.$self->_opts.">";
	  $el .= $self->default."</textarea>\n";
	}
  return $el;
}






=head2 $html=password

Give back a password field (default,size,maxlength,css_class)

=cut

sub password {
  my $self = shift;
	return $self->_inputfield("password",@_);
}








=head2 $html=imagebutton

Values: name,src, [align ['TOP','MIDDLE','BOTTOM'],css_class]

=cut

sub imagebutton {
  my $self = shift;
  $self->_init_values(@_);
  my $el="";
  if($self->name ne '' and $self->src ne '') {
    if($self->align){
      my $align = 'MIDDLE';
      $align = 'TOP' if $self->align eq 'TOP';
      $align = 'BOTTOM' if $self->align eq 'BOTTOM';
      $self->align($align);
		}
    $el = qq|<input name="|.$self->name.qq|" type="image"|.$self->_opts.">";
  }
  return $el;
}







=head2 $html=submit

Give back a sumbit button (name,value,css_class,onClick)

=cut

sub submit {
  my $self = shift;
	$self->_inputfield("submit",@_);
}






=head2 $html=reset

Give back a reset button (name,value,css_class,onClick)

=cut

sub reset {
  my $self = shift;
	return $self->_inputfield("reset",@_);
}






=head2 $html=hidden

Give back a hidden field (name,value)

=cut

sub hidden {
  my $self = shift;
	return $self->_inputfield("hidden",@_);
}






=head2 $html=buttonarrows

Give back a sorting button with up/down (name,css_class)

=cut

sub buttonarrows {
  my $self = shift;
  $self->_init_values(@_);
	my $class = $self->css_class; # we have to save the elements because 
	my $name = $self->name;       # calling other methods (will be killed)
  my @elements = ("");
  if($self->name ne ''){
    $elements[0] = $self->imagebutton(name=>'order_'.$name."_up",
                  src=>$self->UP_ARROW, css_class=>$class);
    $elements[1] = $self->imagebutton(name=>'order_'.$name."_down",
                  src=>$self->DWN_ARROW, css_class => $class);
    $elements[2] =$self->label(ucfirst(lc($name)));
  }
  return \@elements;
}






=head2 $html=dropdown 

Give back a dropdown list (name,elements,css_class,default,labels [ext. vers.]

=cut

sub dropdown {
  my $self = shift;
  $self->_init_values(@_);
	my $element = qq|<select name="|.$self->name.qq|"|.$self->_opts.qq|>\n|;
	if ($self->labels) {
	  foreach my $key (@{$self->elements}) {
	    $element .= qq|<option value="$key"|;
		  $element .= " selected" if $key eq $self->default;
		  $element .= qq|>|.${$self->labels}{$key}."\n";
		}
	} else {
	  foreach my $key (@{$self->elements}) {
	    $element .= qq|<option|;
		  $element .= " selected" if $key eq $self->default;
		  $element .= qq|>|.$key."\n";
		}
	}
	$element .= "</select>\n";
  return $element;
}






=head2 $html=radio

Give back a multiple (radio) selection (name,elements,css_class,linebreak)

=cut

sub radiobutton {
  my $self = shift;
	$self->_init_values(@_);
	my $el="";
	if ($self->name) {
	  foreach my $key (@{$self->elements}) {
	    $el .= qq|<input name="|.$self->name.qq|" type="radio"|.
		         qq|value="|.$key.qq|"|;
		  $el .= qq| class="|.$self->css_class.qq|"| if $self->css_class;
			$el .= qq| checked| if $self->default eq $key;
		  $el .= qq|">|.${$self->labels}{$key};
		  $el .= "<br>" if $self->linebreak;
	  }
	}
	return $el;
}






=head2 $html=checkbox

Give back a checkbox element (name,checked,value,class,onClick,id)

=cut

sub checkbox {
  my $self = shift;
	return $self->_inputfield("checkbox",@_);
}






=head2 $html=ipfield($name,$chkcidr,$default)

Give back an ip entry field based on combo boxes (optional with cidr-notation)

=cut

sub ipfield {
  my ($self,$name,$chkcidr,$default) = @_;
	my ($html,$def,$cidr,@defels);
	if ($name ne '') {
	  if ($default eq "") {
		  if ($chkcidr != 0) {
	      $default = "192.168.0.100/24";
			} else {
				$default = "192.168.0.1";
			}
		}
		if ($default) {
		  ($def,$cidr)=split('/',$default);
			@defels=split('\.',$def);
		}  
	  foreach my $id (0..3) {
		  my @els = (0..255);
			$html .= "\n." if $html ne "";
			$html .= $self->dropdown(name=>$name."_ip_oct_".$id,
		               elements=>\@els,default=>$defels[$id]);
	  }
		if ($chkcidr) {
		  my @els = (1..32);
	    $html .= "/".$self->dropdown(name=>$name."_ip_cidr", 
                          elements=>\@els,default=>$cidr);
		}
	}
	return $html;
}






=head2 $html=keyboard

Keyboard selection field

=cut

sub keyboard {
  my ($self,$name) = @_;
	my $element="";
	if ($name ne '') {
	  my %lab;
		my @elements = ('us','fr','de','it','es','de_CH','fr_CH','it_CH');
		my @labels = ("US","French","German","Italian","Spanish","Swiss German",
		              "Swiss French","Swiss Italian");
		my $c=0;
		my $layout = `cat /home/archivista/.xkb-layout`;
		chomp($layout);
		foreach my $element (@elements) {
		  $lab{$element} = $labels[$c];
			$c++;
		}
	  $element = $self->dropdown({name => $name,elements => \@elements,
		                            labels => \%lab, default=> $layout});
	}
	return $element;
}






=head2 $html=language

Keyboard selection field

=cut

sub language {
  my ($self,$name) = @_;
	my $element="";
	if ($name ne '') {
	  my %lab;
		my @elements = ('en','fr','de');
		my @labels = ("English","Français","Deutsch");
		my $c=0;
		my $layout = `cat /etc/lang.conf`;
		chomp($layout);
		foreach my $element (@elements) {
		  $lab{$element} = $labels[$c];
			$c++;
		}
	  $element = $self->dropdown({name => $name,elements => \@elements,
		                            labels => \%lab, default=> $layout});
	}
	return $element;
}







=head2 $html=timeareas

Give back a field for timezone selection

=cut

sub timeareas {
  my ($self,$name) = @_;
	my $element="";
	if ($name ne '') {
	  my $pareas = $self->_getAreas();
		my $area = $self->_getSelectedArea();
		my @elements = sort((keys %{$pareas}));
		$element=$self->dropdown({name=>$name,elements=>\@elements,default=>$area,
		                                     id=>'areas',onChange=>'TimeZone()'});
	}
	return $element;
}






# \%areas=$self->_getAreas();
# Gets all Areas and Zones from /usr/share/zoneinfo/zone.tab
#
sub _getAreas {
  my $self = shift;
	open(FIN,"<","/usr/share/zoneinfo/zone.tab");
	binmode(FIN);
	my @data = <FIN>;
	close(FIN);
	my %areas;
	foreach my $line (@data) {
	  if ( $line =~ /\s(\w*)\/(\w*?)\s/ ) {
		  if ($areas{$1}) {
			  push(@{$areas{$1}},$2);
			} else {
				$areas{$1} = [$2];
			}
		}
	}
	return \%areas;
}







# _getSelectedArea {
# Return the selected Area
#
sub _getSelectedArea {
  my $self = shift;
  # Get selected Area
  my $ls = "ls -lah /etc/localtime";
  my $cut1 = "cut -d '>' -f 2";
  my $cut2 = "cut -d '/' -f 5";
  my $area=`$ls | $cut1 | $cut2`;
  chomp($area);
	return $area;
}






=head2 $html=timezones

Values: name

=cut

sub timezones {
  my ($self,$name) = @_;
	my $element="";
	if ($name ne '') {
	  my $pareas = $self->_getAreas();
		foreach my $k (keys %{$pareas}) {
		  my @zones=sort(@{$pareas->{$k}});
			my $area = $self->_getSelectedArea();
      my $ls = "ls -lah /etc/localtime";
      my $cut1 = "cut -d '>' -f 2";
      my $cut2 = "cut -d '/' -f 6";
      my $zone=`$ls | $cut1 | $cut2`;
      chomp $zone;
			my $class="";
			$class = "hidden_zone" if $area ne $k;
			$element .=$self->dropdown(name =>"zone_$k",id=>"zone_$k",
			     elements=>\@zones, css_class=>$class,default=>$zone);
		}
	}
	return $element;
}






=head2 $html=datetime

Give back datetime information 
=cut

sub datetime {
  my ($self,$name) = @_;
	my $element;
	if ($name ne '') {
	  my ($min,$hour,$day,$month,$year) = (localtime())[1,2,3,4,5];
		$min = sprintf("%02d",$min);
		$hour = sprintf("%02d",$hour);
		$day = sprintf("%02d",$day);
		$month = sprintf("%02d",$month+1);
		$year = sprintf("%02d",$year+1900);
	  $element = $self->textfield(name=>$name.'_day',id=>'date_time_D',
		                             default=>$day,size=>2,maxlength=>2);
	  $element .= ".".$self->textfield(name=>$name.'_month',id=>'date_time_M',
		                                 default=>$month, size=>2,maxlength=>2);
	  $element .= ".".$self->textfield(name=>$name.'_year',id=>'date_time_Y',
		                                  default=>$year,size=>4,maxlength=>4);
	  $element .= " ".$self->textfield(name=>$name.'_hour',id=>'date_time_h',
		                                  default=>$hour,size=>2,maxlength=>2);
	  $element .= ":".$self->textfield(name=>$name.'_min',id=>'date_time_m',
		                                  default=>$min,size=>2,maxlength=>2);
	}
	return $element;
}






=head2 div

=cut

sub div {
  my ($self,$name,$css,$id) = @_;
	my $el = "<div";
	$el .= qq| class="$css"| if $css;
	$el .= qq| id="$id"| if $id;
	$el .= ">$name</div>";
	return $el;
}






=head2 $html=menu($pmenu,$actin)

Give back a menu structure based on an array (+ at end = submenu)

=cut

sub menu {
  my ($self,$pmenu,$actin) = @_;
  my $style = "";
  if ($ENV{HTTP_USER_AGENT} =~ /IE/) {
    $style .= "<style>.Menu{width:0;overflow:visible;}</style>\n";
    $style .= "<style>.MenuActive{width:0;overflow:visible;}</style>\n";
	}
	my $table = HTML::Table->new(-border=>0,-width=>'240px');
	my (@lbl,@val,@cs,@lev,@vis,@act,$cmax);
	$cmax=$self->_getMenuInit($pmenu,\@lbl,\@val,\@cs,\@lev,\@act,$actin);
	$self->_getMenuVisible($cmax,\@lev,\@vis,\@act);
	for (my $c=0;$c<=$cmax;$c++) {
	  if ($vis[$c]==1) {
		  my $b=$self->submit({name=>$val[$c],value=>$lbl[$c],css_class=>$cs[$c]});
		  if ($lev[$c] == 0) {
		    $table->addRow("&rsaquo;",$b);
		    $table->setCellColSpan(-1,2,2);
		    $table->setCellClass(-1,1,"MenuItem");
		    $table->setCellClass(-1,2,"MenuItem2");
		  } else {
		    $table->addRow("&rsaquo;","&nbsp",$b);
		    $table->setCellClass(-1,1,"MenuItem");
		    $table->setCellClass(-1,2,"MenuItem1");
		    $table->setCellClass(-1,3,"MenuItem2");
		  }
		}
	}
	my $out = $style.$table->getTable();
	return $out;
}






=head _getMenuInit($pmenu,$plabel,$pval,$pcss,$plevel,$pactive,$act)

Does fill in the variabels to show the structure later

=cut

sub _getMenuInit {
  my ($self,$pmenu,$plabel,$pval,$pcss,$plevel,$pactive,$act) = @_;
	my $c = 0;
	my $cmax = 0;
	foreach (@$pmenu) {
	  my $el = $_;
		my $left = substr($el,0,length($el)-1);
		my $right = substr($el,-1,1);
		$$plevel[$c] = 0;
		if ($right eq "+") {
		  $$plevel[$c] = 1;
		  $el = $left;
		}
		my $lbl = $self->strings->string($el);
		$$plabel[$c] = $lbl;
	  $$pval[$c] =  "go_menu_".$el;
	  $$pcss[$c] = "Menu";
		if ($el eq $act) {
		  $$pcss[$c] = "MenuActive";
			$$pactive[$c] = 1;
		}
		$cmax=$c;
		$c++;
	}
	return $cmax;
}






=head1 _getMenuVisible($cmax,$plevel,$pvisible,$pactive)

Does test which menu elements we want to show

=cut

sub _getMenuVisible {
  my ($self,$cmax,$plevel,$pvisible,$pactive) = @_;
	for (my $c=0;$c<=$cmax;$c++) {
		$$pvisible[$c]=1 if $$plevel[$c]==0;
		if ($$pactive[$c]==1) {
		  if ($$plevel[$c]>0) {
		    for (my $c1=$c;$c1>=0;$c1--) { # show elements above active entry
		      if ($$plevel[$c1]==1) {
			      $$pvisible[$c1]=1;
			    } else {
			      $c1=0;
			    }
				}
			}
			my $c2=$c+1;
			for (my $c1=$c2;$c1<=$cmax;$c1++) { # show elements after active entry
			  if ($$plevel[$c1]>0) {
			    $$pvisible[$c1]=1;
				} else {
				  $c1=$cmax;
				}
			}
		}
	}
}






=head2 $html=row_textfield($stringid,$name,$default)

Give back a label and textfield in a table row

=cut

sub row_textfield {
  my $self = shift;
	my ($stringid,$name,$default) = @_;
	my $text=$self->strings->string($stringid);
	my $label = $self->label($text);
	my $element=$self->textfield(name=>$name,default=>$default);
	$self->table->addRow($label,$element);
}






=head2 $html=row_dropdown($stringid,$name,$el,$default)

Give back a dropdown list given the parameters

=cut

sub row_dropdown {
	my ($self,$stringid,$name,$el,$default) = @_;
  my $text = $self->strings->string($stringid);
	my $label = $self->label($text);
	$el=$self->dropdown({name=>$name,elements=>$el,default=>$default});
	$self->table->addRow($label,$el);
}






=head2 row_checkbox($string,$name,$value,$check,$js)

Give back a checkbox (with label)

=cut

sub row_checkbox {
	my ($self,$stringid,$name,$value,$checked,$js) = @_;
	my $text = $self->strings->string($stringid);
	my $label = $self->label($text);
	$checked="checked" if $checked eq '1';
	$checked="" if $checked eq '0';
	my $element = $self->checkbox(name=>$name,value=>$value,checked=>$checked,
	                               onClick=>$js,id=>$name);
  $self->table->addRow($label,$element)
}





=head2 $html=row_ip

=cut

sub row_ip {
  my ($self,$stringid,$name,$default,$cidr) = @_;
	$cidr = 0 if !$cidr;
	my $text=$self->strings->string($stringid);
	my $label = $self->label($text);
	my $element=$self->ipfield($name,$cidr,$default);
	$self->table->addRow($label,$element);
}






=head2 row_keyboard(stringid,$name)

Give back the keyboard settings

=cut

sub row_keyboard {
  my ($self,$stringid,$name) = @_;
	my $text=$self->strings->string($stringid);
	my $label=$self->label($text);
	my $element= $self->keyboard($name);
	$self->table->addRow($label,$element);
}






=head2 row_language(stringid,$name)

Give back the language settings

=cut

sub row_language {
  my ($self,$stringid,$name) = @_;
	my $text=$self->strings->string($stringid);
	my $label=$self->label($text);
	my $element= $self->language($name);
	$self->table->addRow($label,$element);
}


=head2 $html=row_timezones($stringid,$name)

Give back a timezone selection

=cut

sub row_timezones {
  my ($self,$stringid,$name) = @_;
	my $text=$self->strings->string($stringid);
	my $label=$self->label($text);
	my $element= $self->timezones($name);
	$self->table->addRow($label,$element);
}






=head2 $html=getConfigTimeArea($stringid,$name)

Give back timearea selection

=cut

sub row_timearea {
  my ($self,$stringid,$name) = @_;
	my $text=$self->strings->string($stringid);
	my $label=$self->label($text);
	my $element= $self->timeareas($name);
	$self->table->addRow($label,$element);
}






=head2 $html=row_datetime($stringid,$name)

Give back date and time

=cut

sub row_datetime {
  my ($self,$stringid,$name) = @_;
	my $text=$self->strings->string($stringid);
	my $label=$self->label($text);
	my $element= $self->datetime($name);
	$self->table->addRow($label,$element);
}






=head2 $html=row_password

Give back a pssowrd field

=cut

sub row_password {
	my ($self,$stringid,$name,$default) = @_;
	my $text=$self->strings->string($stringid);
	my $label = $self->label($text);
	my $element = $self->password(name=>$name,value=>$default);
	$self->table->addRow($label,$element);
}






=head2 $self->row_submit($title,$action,$message,$left,$msgcmd)

Show the appropriate submit button (incl. warning/javascript messages)

=cut

sub row_submit {
  my ($self,$action,$message,$left,$msgcmd) = @_;
	my ($msg,$js);
	if ($message) {
	  $msg = $self->strings->string($message);
	  $js = "return confirm('$msg');";
	}
	my $name = "go_action_".$action;
	my $lbl = 'WEBC_SUBMIT';
	$lbl = $msgcmd if $msgcmd ne "";
	my $txt = $self->strings->string($lbl);
	my $el = $self->submit(name=>$name, value=>$txt, onClick=>$js);
	if ($left eq '') {
	  $self->table->addRow('',$el);
	} else {
	  $self->table->addRow($el);
	}
}






=head2 $self->row_title($title)

Show a column title in a row of the detail form

=cut

sub row_title {
  my ($self,$title) = @_;
	my $title1 = $self->strings->string($title);
	$self->table->addRow($self->div($self->string($title),'FormTitle'));
}






=head2 $self->row_attribues($css,$id)

Helper method to show attributes of tab cell

=cut

sub row_attributes {
  my ($self,$css,$id) = @_;
	$self->table->setLastRowClass($css);
	$self->table->setLastRowAttr($id);
}



=head1 vers=check64bit 

Give back if we are under 32 or 64 bit

=cut

sub check64bit {
  my ($self) = @_;
  my $vers = 32;
	$vers=64 if -e "/usr/bin/soffice";
	return $vers;
}




1;
