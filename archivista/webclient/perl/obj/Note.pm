package obj::Note;

use strict;
#use Data::Dumper ();
use ExactImage ();

# map 'columns' in db record to object members
our @dbfields = qw(
 type x1 y1 x2 y2 x3 y3 index unused1
 bColor bgColor bgOpacity bWidth
 fgColor fgSize fgBold fgItalic fgUnderline
 fgRotation iWidth iHeight iXRes iYRes
 fgFamily fgText unused2
);

# the members we read from javascript code
our @jsReadFields = qw(
 cWidth cHeight cRotate cZoom
 bColor bWidth
 bgTop bgLeft bgWidth bgHeight bgColor bgOpacity
 fgColor fgSize fgBold fgItalic fgUnderline fgRotation fgFamily fgText
);

# the members we write to javascript code
our @jsWriteFields = qw(
 index doc page url editable
 iWidth iHeight
 iXRes iYRes
 cWidth cHeight cRotate cZoom
 bColor bWidth
 bgTop bgLeft bgWidth bgHeight bgColor bgOpacity
 fgColor fgSize fgBold fgItalic fgUnderline fgRotation fgFamily fgText
);

sub new {

  my $class = shift;

  my $self = {
    'index' => 0,

    # not in db
    url => '',
    doc => 0,
    page => 0,
    editable => 0,

    # extracted from BildInput (large image), added to db
    iWidth => 0,
    iHeight => 0,
    iXRes => 0,
    iYRes => 0,

    # cage size, provided by client, not in db
    cWidth => 0,
    cHeight => 0,
    cRotate => 0,
    cZoom => 0,

    # changed by user via js drag/resize, not in db
    # scaled due to cWidth/cHeight vs iWidth/iHeight
    bgLeft => 0, bgTop => 0,
    bgWidth => 0, bgHeight => 0,

    # changed by user via js drag/resize, in db
    x1 => 10, y1 => 10, x2 => 100, y2 => 100,

    # changed by user via javascript menu, in db
    bgColor => 65535,
    bgOpacity => 2,

    bColor => 0,
    bWidth => 5,

    fgRotation => 0,
    fgColor => 0,
    fgSize => 12,
    fgBold => 0,
    fgItalic => 0,
    fgUnderline => 0,
    fgFamily => 'Arial',
    fgText => '',

    # unused, but in db
    type => 3,
    x3 => 0, y3 => 0,
    unused1 => 0,
    unused2 => '',

    @_
  };
  bless($self,$class);
  return $self;
}


sub fromString {
  my $self = shift;
  my $line = shift;

  my @fields = split(/;/,$line,scalar @dbfields);
  foreach my $idx (0 .. $#dbfields){
    if(length $fields[$idx]){
      $self->{$dbfields[$idx]} = $fields[$idx];
    }
  }

  # boxes made in richclient always have 'archivista' in text, blast it.
  if($self->{'type'} == 2){
    $self->{'type'} = 3;
    $self->{'fgText'} = '';
  }

  return;
}

# after loading x1-y2 from db or defaults,
# we must update bg dimensions used by js/image code
sub updateBgParams {
  my $self = shift;

  $self->{'bgLeft'} = int($self->scaleWidth($self->{'x1'}));
  $self->{'bgWidth'} = int($self->scaleWidth($self->{'x2'}))-$self->{'bgLeft'};

  $self->{'bgTop'} = int($self->scaleHeight($self->{'y1'}));
  $self->{'bgHeight'} = int($self->scaleHeight($self->{'y2'}))-$self->{'bgTop'};

  return;
}

sub toString {
  my $self = shift;

  # replace ; with , to prevent ruining ; separated string
  $self->{'fgText'} =~ s/;/,/g;

  return join(';', map {$self->{$dbfields[$_]}} (0 .. $#dbfields));
}

sub fromCGI {
  my $self = shift;
  my $val = shift;

  foreach my $field (@jsReadFields){
    if(length $val->{"note_$field"}){
      $self->{$field} = $val->{"note_$field"};
    }
  }

  # if any of the bg dimensions have changed, update x1-y2 params
  if ( $self->{'iWidth'} && $self->{'iHeight'}
    && $self->{'cWidth'} && $self->{'cHeight'}
  ){
    #my $temp = int($self->{'x1'}*$self->{'cWidth'}/$self->{'iWidth'});
    #if($self->{'bgLeft'} != $temp){
      $self->{'x1'}
        = int($self->{'bgLeft'}*$self->{'iWidth'}/$self->{'cWidth'});
    #}

    #$temp = int($self->{'x2'}*$self->{'cWidth'}/$self->{'iWidth'}) 
    #  - $self->{'bgLeft'};
    #if($self->{'bgWidth'} != $temp){
      $self->{'x2'} = $self->{'x1'} 
        + int($self->{'bgWidth'}*$self->{'iWidth'}/$self->{'cWidth'});
    #}

    #$temp = int($self->{'y1'}*$self->{'cHeight'}/$self->{'iHeight'});
    #if($self->{'bgTop'} != $temp){
      $self->{'y1'} = int($self->{'bgTop'}*$self->{'iWidth'}/$self->{'cWidth'});
    #}

    #$temp = int($self->{'y2'}*$self->{'cHeight'}/$self->{'iHeight'})
    #  - $self->{'bgTop'};
    #if($self->{'bgHeight'} != $temp){
      $self->{'y2'} = $self->{'y1'}
        + int($self->{'bgHeight'}*$self->{'iWidth'}/$self->{'cWidth'});
    #}
  }
  else{
    warn 'not enough info2';
  }

  return;
}

sub toJSON {
  my $self = shift;

  my $json = "{\n";

  foreach my $field (@jsWriteFields){
    if($self->{$field} =~ m/^[0-9]+$/){
      $json .= qq( "note_$field" : $self->{$field},\n);
    }
    else{
      $json .= qq( "note_$field" : "$self->{$field}",\n);
    }
  }

  $json =~ s/,\n$//;

  $json .= "}\n";

  return $json;
}

# shift all the image and note dimensions based on 90/180/270 rotation
sub rotate {
  my $self = shift;
  my $degrees = shift;
  if (!length $degrees){
    $degrees = $self->{'cRotate'};
  }

  if(!$degrees){
    return;
  }

  if($degrees == 90 || $degrees == 270){
    my $temp = $self->{'iWidth'};
    $self->{'iWidth'} = $self->{'iHeight'};
    $self->{'iHeight'} = $temp;

    $temp = $self->{'iXRes'};
    $self->{'iXRes'} = $self->{'iYRes'};
    $self->{'iYRes'} = $temp;
  }

  $self->{'fgRotation'} = (($self->{'fgRotation'}/10 +$degrees) % 360)*10;

  # special case for triangles
  if($self->{'type'} == 1){
    if($degrees == 90){
      my ($x1,$x2,$x3) = ($self->{'x1'},$self->{'x2'},$self->{'x3'});
      $self->{'x1'} = $self->{'iWidth'} - $self->{'y1'};
      $self->{'x2'} = $self->{'iWidth'} - $self->{'y2'};
      $self->{'x3'} = $self->{'iWidth'} - $self->{'y3'};
      $self->{'y1'} = $x1;
      $self->{'y2'} = $x2;
      $self->{'y3'} = $x3;
    }
    elsif($degrees == 180){
      $self->{'x1'} = $self->{'iWidth'} - $self->{'x1'};
      $self->{'x2'} = $self->{'iWidth'} - $self->{'x2'};
      $self->{'x3'} = $self->{'iWidth'} - $self->{'x3'};
      $self->{'y1'} = $self->{'iHeight'} - $self->{'y1'};
      $self->{'y2'} = $self->{'iHeight'} - $self->{'y2'};
      $self->{'y3'} = $self->{'iHeight'} - $self->{'y3'};
    }
    elsif($degrees == 270){
      my ($y1,$y2,$y3) = ($self->{'y1'},$self->{'y2'},$self->{'y3'});
      $self->{'y1'} = $self->{'iHeight'} - $self->{'x1'};
      $self->{'y2'} = $self->{'iHeight'} - $self->{'x2'};
      $self->{'y3'} = $self->{'iHeight'} - $self->{'x3'};
      $self->{'x1'} = $y1;
      $self->{'x2'} = $y2;
      $self->{'x3'} = $y3;
    }
    return;
  }

  # all other types
  if($degrees == 90){
    my ($x1,$x2) = ($self->{'x1'},$self->{'x2'});
    $self->{'x1'} = $self->{'iWidth'} - $self->{'y2'};
    $self->{'x2'} = $self->{'iWidth'} - $self->{'y1'};
    $self->{'y1'} = $x1;
    $self->{'y2'} = $x2;
  }
  elsif($degrees == 180){
    my ($x1,$y1) = ($self->{'x1'},$self->{'y1'});
    $self->{'x1'} = $self->{'iWidth'} - $self->{'x2'};
    $self->{'x2'} = $self->{'iWidth'} - $x1;
    $self->{'y1'} = $self->{'iHeight'} - $self->{'y2'};
    $self->{'y2'} = $self->{'iHeight'} - $y1;
  }
  elsif($degrees == 270){
    my ($y1,$y2) = ($self->{'y1'},$self->{'y2'});
    $self->{'y1'} = $self->{'iHeight'} - $self->{'x2'};
    $self->{'y2'} = $self->{'iHeight'} - $self->{'x1'};
    $self->{'x1'} = $y1;
    $self->{'x2'} = $y2;
  }

  return;
}

# unshift all the image and note dimensions based on 90/180/270 rotation
# used before storing back to db
sub unrotate {
  my $self = shift;
  return $self->rotate((360-$self->{'cRotate'})%360);
}

# scale a number based on resolution of stored image
sub scaleXRes {
  my $self = shift;
  my $val = shift;
  my $res = shift;

  if($self->{'iXRes'} && $res){
    $val = $val*$self->{'iXRes'}/$res;
  }

  return $val;
}
sub scaleYRes {
  my $self = shift;
  my $val = shift;
  my $res = shift;

  if($self->{'iYRes'} && $res){
    $val = $val*$self->{'iYRes'}/$res;
  }

  return $val;
}

# scale a number based on size of client's page image
sub scaleWidth {
  my $self = shift;
  my $val = shift;

  if($self->{'cWidth'} && $self->{'iWidth'}){
    $val = int($val*$self->{'cWidth'}/$self->{'iWidth'});
  }

  return $val;
}
sub scaleHeight {
  my $self = shift;
  my $val = shift;

  if($self->{'cHeight'} && $self->{'iHeight'}){
    $val = int($val*$self->{'cHeight'}/$self->{'iHeight'});
  }

  return $val;
}

sub getImage {
  my $self = shift;

  # only support drawing boxes
  if($self->{'type'} != 3){
    return;
  }

  # assume we are drawing onto a larger image
  my $imgo = shift;
  my $top = $self->{'bgTop'};
  my $left = $self->{'bgLeft'};

  # setup margins of note
  my $bWidth = int($self->scaleWidth($self->scaleXRes($self->{'bWidth'},300)));
  if($self->{'bWidth'} && !$bWidth){
    $bWidth = 1;
  }
  my $bw2 = $bWidth/2;
  my $pad = $bWidth + int($self->scaleWidth($self->scaleXRes(5,300)));

  # setup size of note
  my $width = $self->{'bgWidth'};
  my $height = $self->{'bgHeight'};

  # setup colors of note
  my $alpha = $self->{'bgOpacity'};
  if($alpha > 1){
    $alpha = 0.7;
  }
  my $color = sprintf("%06x",$self->{'bgColor'});
  $color =~ m/^(..)(..)(..)$/;
  ExactImage::setBackgroundColor(hex($3)/255,hex($2)/255,hex($1)/255,$alpha);
  ExactImage::setForegroundColor(hex($3)/255,hex($2)/255,hex($1)/255,$alpha);

  # we are using a larger image, draw a rectangle
  if($imgo){

    # black and white images look weird- smash note to b&w
    #if(ExactImage::imageColorspace($imgo) eq 'gray1'){
      #ExactImage::setBackgroundColor(1,1,1,1);
      #ExactImage::setForegroundColor(1,1,1,1);
    #}
  
    my $path = ExactImage::newPath();
    ExactImage::pathMoveTo($path, $left, $top);
    ExactImage::pathLineTo($path, $left+$width, $top);
    ExactImage::pathLineTo($path, $left+$width, $top+$height);
    ExactImage::pathLineTo($path, $left, $top+$height);
    ExactImage::pathClose($path);
    ExactImage::pathFill($path, $imgo);
    ExactImage::deletePath ($path);
  }
  # we are NOT drawing onto a larger image, make new, small image
  else{
    $imgo = ExactImage::newImageWithTypeAndSize (4, 8, $width, $height, 1);
    $top = 0;
    $left = 0;
  }

  if(length $self->{'fgText'}){
 
    $color = sprintf("%06x",$self->{'fgColor'});
    $color =~ m/^(..)(..)(..)$/;
    ExactImage::setForegroundColor(hex($3)/255,hex($2)/255,hex($1)/255,1);

    # black and white images look weird- smash note to b&w
    #if(ExactImage::imageColorspace($imgo) eq 'gray1'){
      #ExactImage::setForegroundColor(0,0,0,1);
    #}
  
    # figure out font name
    my $fn = '/usr/X11/share/fonts/TTF/';
    if($self->{'fgFamily'} eq 'Arial'){
      $fn .= 'luxis';
    }
    elsif($self->{'fgFamily'} eq 'Courier'){
      $fn .= 'luxim';
    }
    else{
      $fn .= 'luxir';
    }
    if($self->{'fgBold'}){
      $fn .= 'b';
    }
    else{
      $fn .= 'r';
    }
    if($self->{'fgItalic'}){
      $fn .= 'i';
    }
    $fn .= '.ttf';

    # determine text properties
    my $fh = $self->scaleHeight($self->scaleYRes($self->{'fgSize'},72));

    # draw text on a rotated temporary image so we can determine wrapping
    my $tiw = $height;
    my $tih = $width;
    if($self->{'fgRotation'} == 900 || $self->{'fgRotation'} == 2700){
      my $temp = $tiw;
      $tiw = $tih;
      $tih = $temp;
    }

    my @lines = ();
    my @lengths = ();
    my $ln = 0;
    my $tpath = ExactImage::newPath();
    ExactImage::pathMoveTo($tpath, $tiw-$fh-$pad, $pad);
    ExactImage::pathLineTo($tpath, $tiw-$fh-$pad, $tih-$pad);

    foreach my $word (split(/ /,$self->{'fgText'})){
      my $timgo = ExactImage::newImageWithTypeAndSize (4, 8, $tiw, $tih, 1);
      ExactImage::imageDrawTextOnPath($timgo,$tpath,$lines[$ln].$word,$fh,$fn);
      ExactImage::imageFastAutoCrop($timgo);
      my $textLen = ExactImage::imageHeight($timgo);
      ExactImage::deleteImage($timgo);

      # space remains, go to next word
      if($textLen+$pad < $tih){
        $lines[$ln] .= $word . ' ';
        $lengths[$ln] = $textLen;
        next;
      }

      # this word put us over
      # bump to next line if this one is not empty
      if(length $lines[$ln]){
        $ln++;
      }

      # try again, splitting this word
      foreach my $letter (split(//,$word)){
        $timgo = ExactImage::newImageWithTypeAndSize (4, 8, $tiw, $tih, 1);
        ExactImage::imageDrawTextOnPath(
          $timgo,$tpath,$lines[$ln].$letter,$fh,$fn
        );
        ExactImage::imageFastAutoCrop($timgo);
        $textLen = ExactImage::imageHeight($timgo);
        ExactImage::deleteImage($timgo);
  
        # more space, or the line is empty, add char, move on
        if($textLen+$pad < $tih || !length $lines[$ln]){
          $lines[$ln] .= $letter;
          $lengths[$ln] = $textLen;
          next;
        }

        # this letter put us over, move a line
        $timgo = ExactImage::newImageWithTypeAndSize (4, 8, $tiw, $tih, 1);
        ExactImage::imageDrawTextOnPath($timgo,$tpath,$letter,$fh,$fn);
        ExactImage::imageFastAutoCrop($timgo);
        $textLen = ExactImage::imageHeight($timgo);
        ExactImage::deleteImage($timgo);
    
        $ln++;
        $lines[$ln] = $letter;
        $lengths[$ln] = $textLen;
      }
      $lines[$ln] .= ' ';
    }
    ExactImage::deletePath ($tpath);

    # draw final text for each line
    my $upad = $fh/8;
    foreach my $ln (0 .. $#lines){

      my $path = ExactImage::newPath(); # for text
      my $upath = ExactImage::newPath(); # for underline
  
      if($self->{'fgRotation'} == 900){
        # this line will be entirely off bottom of note
        last if(($fh+$upad)*$ln+$pad*2 > $width);
      
        ExactImage::pathMoveTo(
          $path, $left+$width-$pad-$fh*($ln+1)-$upad*$ln, $top+$pad);
        ExactImage::pathLineTo(
          $path, $left+$width-$pad-$fh*($ln+1)-$upad*$ln, $top+$height-$pad);
        ExactImage::pathMoveTo(
          $upath, $left+$width-$pad-$fh*($ln+1)-$upad*($ln+1), $top+$pad);
        ExactImage::pathLineTo(
          $upath, $left+$width-$pad-$fh*($ln+1)-$upad*($ln+1),
          $top+$lengths[$ln]);
      }
      elsif($self->{'fgRotation'} == 1800){
        # this line will be entirely off bottom of note
        last if(($fh+$upad)*$ln+$pad*2 > $height);

        ExactImage::pathMoveTo(
          $path, $left+$width-$pad, $top+$height-$pad-$fh*($ln+1)-$upad*$ln);
        ExactImage::pathLineTo(
          $path, $left+$pad, $top+$height-$pad-$fh*($ln+1)-$upad*$ln);
        ExactImage::pathMoveTo(
          $upath, $left+$width-$pad,
          $top+$height-$pad-$fh*($ln+1)-$upad*($ln+1));
        ExactImage::pathLineTo(
          $upath, $left+$width-$lengths[$ln],
          $top+$height-$pad-$fh*($ln+1)-$upad*($ln+1));
      }
      elsif($self->{'fgRotation'} == 2700){
        # this line will be entirely off bottom of note
        last if(($fh+$upad)*$ln+$pad*2 > $width);

        ExactImage::pathMoveTo(
          $path, $left+$pad+$fh*($ln+1)+$upad*$ln, $top+$height-$pad);
        ExactImage::pathLineTo(
          $path, $left+$pad+$fh*($ln+1)+$upad*$ln, $top+$pad);
        ExactImage::pathMoveTo(
          $upath, $left+$pad+$fh*($ln+1)+$upad*($ln+1), $top+$height-$pad);
        ExactImage::pathLineTo(
          $upath, $left+$pad+$fh*($ln+1)+$upad*($ln+1),
          $top+$height-$lengths[$ln]);
      }
      else{
        # this line will be entirely off bottom of note
        last if(($fh+$upad)*$ln+$pad*2 > $height);

        ExactImage::pathMoveTo(
          $path, $left+$pad, $top+$pad+$fh*($ln+1)+$upad*$ln);
        ExactImage::pathLineTo(
          $path, $left+$width-$pad, $top+$pad+$fh*($ln+1)+$upad*$ln);
        ExactImage::pathMoveTo(
          $upath, $left+$pad, $top+$pad+$fh*($ln+1)+$upad*($ln+1));
        ExactImage::pathLineTo(
          $upath, $left+$lengths[$ln], $top+$pad+$fh*($ln+1)+$upad*($ln+1));
      }
  
      ExactImage::imageDrawTextOnPath($imgo,$path,$lines[$ln],$fh,$fn);
      ExactImage::deletePath ($path);
  
      # draw underline
      if($self->{'fgUnderline'}){
        ExactImage::setLineWidth($fh/14);
        ExactImage::pathStroke($upath, $imgo);
      }
      ExactImage::deletePath ($upath);
    }

  }

  # draw border if enabled
  if($bWidth){
    $color = sprintf("%06x",$self->{'bColor'});
    $color =~ m/^(..)(..)(..)$/;
    ExactImage::setForegroundColor(hex($3)/255,hex($2)/255,hex($1)/255,1);

    # black and white images look weird- smash note to b&w
    #if(ExactImage::imageColorspace($imgo) eq 'gray1'){
      #ExactImage::setForegroundColor(0,0,0,1);
    #}
  
    ExactImage::setLineWidth($bWidth);

    my $path = ExactImage::newPath();
    ExactImage::pathMoveTo($path, $left+$bw2, $top+$bw2);
    ExactImage::pathLineTo($path, $left+$width-$bw2, $top+$bw2);
    ExactImage::pathLineTo($path, $left+$width-$bw2, $top+$height-$bw2);
    ExactImage::pathLineTo($path, $left+$bw2, $top+$height-$bw2);
    ExactImage::pathClose($path);
    ExactImage::pathStroke($path, $imgo);
    ExactImage::deletePath ($path);
  }

  return $imgo;
}

sub get {
  my $self = shift;
  my $key = shift;

  if (exists $self->{$key}){
    return $self->{$key};
  }

  return undef;
}

sub set {
  my $self = shift;

  while (scalar @_ > 1){
    my $key = shift;
    $self->{$key} = shift;
  }

  return;
}






=head $html=getNotes($tr)

Give back the notes html stuff (including the strings)

=cut

sub getNotes {
  #my $self = shift; # we call it as class method, not as an object method
  my $tr = shift; # get strings from web client
  if (!$tr) { # if there is a string variable, initalize hash
    my %th;
    $tr = \%th;
  }
  my $chk = $$tr{note_text};
  $chk =~ s/^\s+//g;
  $chk =~ s/\s+$//g;
  if ($chk eq "") { # no strings, set back to default
    $$tr{note_text} = "Text" ;
    $$tr{note_font} = "Font";
    $$tr{note_box} = "Box";
    $$tr{note_options} = "Options";
    $$tr{note_family} = "Family";
    $$tr{note_size} = "Size";
    $$tr{note_color} = "Color";
    $$tr{note_rotation} = "Rotation";
    $$tr{note_bold} = "Bold";
    $$tr{note_italic} = "Italic";
    $$tr{note_underline} = "Underline";
    $$tr{note_background} = "Background";
    $$tr{note_bordercolor} = "Border color";
    $$tr{note_color_white} = "White";
    $$tr{note_color_cyan} = "Cyan";
    $$tr{note_color_magenta} = "Magenta";
    $$tr{note_color_blue} = "Blue";
    $$tr{note_color_yellow} = "Yellow";
    $$tr{note_color_green} = "Green";
    $$tr{note_color_red} = "Red";
    $$tr{note_color_lightgray} = "Light Gray";
    $$tr{note_color_darkgray} = "Dark Gray";
    $$tr{note_color_darkcyan} = "Dark Cyan";
    $$tr{note_color_darkmagenta} = "Dark Magenta";
    $$tr{note_color_darkblue} = "Dark Blue";
    $$tr{note_color_darkgreen} = "Dark Green";
    $$tr{note_color_darkyellow} = "Dark Yellow";
    $$tr{note_color_darkred} = "Dark Red";
    $$tr{note_color_black} = "Black";
    $$tr{note_borderwidth} = "Border width";
    $$tr{note_opacity} = "Opacity";
    $$tr{note_opacity_transparent} = "Transparent";
    $$tr{note_opacity_translucent} = "Translucent";
    $$tr{note_opacity_opaque} = "Opaque";
    $$tr{note_note} = "Note";
    $$tr{note_duplicate} = "Duplicate";
    $$tr{note_delete} = "Delete";
  }

  my $noteMenu = <<EOF;
<div id="nm">
<a id="nm_tabText" class='noteMenuTabCurrent' href=''>$$tr{note_text}</a>
<a id="nm_tabFont" href=''>$$tr{note_font}</a>
<a id="nm_tabBox" href=''>$$tr{note_box}</a>
<a id="nm_tabOptions" href=''>$$tr{note_options}</a>
<div id="nm_content">
<div id="nm_bodyText">
<table>
<tr>
<td><input type="text" size="36" name="nm_fgText" id="nm_fgText"></td>
</tr>
</table>
</div>
<div id="nm_bodyFont">
<table>
<tr>
<td class="noteMenuLabel">$$tr{note_family}</td>
<td><select name="nm_fgFamily" id="nm_fgFamily">
  <option value='Arial'>Arial</option>
  <option value='Times'>Times</option>
  <option value='Courier'>Courier</option>
</select></td>
</tr>
<tr>
<td class="noteMenuLabel">$$tr{note_size}</td>
<td><select name="nm_fgSize" id="nm_fgSize">
  <option value='4'>4</option>
  <option value='5'>5</option>
  <option value='6'>6</option>
  <option value='7'>7</option>
  <option value='8'>8</option>
  <option value='9'>9</option>
  <option value='10'>10</option>
  <option value='11'>11</option>
  <option value='12'>12</option>
  <option value='13'>13</option>
  <option value='14'>14</option>
  <option value='15'>15</option>
  <option value='16'>16</option>
  <option value='17'>17</option>
  <option value='18'>18</option>
  <option value='19'>19</option>
  <option value='20'>20</option>
  <option value='21'>21</option>
  <option value='22'>22</option>
  <option value='23'>23</option>
  <option value='24'>24</option>
  <option value='25'>25</option>
  <option value='26'>26</option>
  <option value='27'>27</option>
  <option value='28'>28</option>
  <option value='29'>29</option>
  <option value='30'>30</option>
  <option value='31'>31</option>
  <option value='32'>32</option>
</select></td>
</tr>
<tr>
<td class="noteMenuLabel">$$tr{note_color}</td>
<td><select name="nm_fgColor" id="nm_fgColor">
  <option value="16777215">$$tr{note_color_white}</option>
  <option value="16776960">$$tr{note_color_cyan}</option>
  <option value="16711935">$$tr{note_color_magenta}</option>
  <option value="16711680">$$tr{note_color_blue}</option>
  <option value="65535">$$tr{note_color_yellow}</option>
  <option value="65280">$$tr{note_color_green}</option>
  <option value="255">$$tr{note_color_red}</option>
  <option value="12632256">$$tr{note_color_lightgray}</option>
  <option value="8421504">$$tr{note_color_darkgray}</option>
  <option value="8421376">$$tr{note_color_darkcyan}</option>
  <option value="8388736">$$tr{note_color_darkmagenta}</option>
  <option value="8388608">$$tr{note_color_darkblue}</option>
  <option value="32896">$$tr{note_color_darkyellow}</option>
  <option value="32768">$$tr{note_color_darkgreen}</option>
  <option value="128">$$tr{note_color_darkred}</option>
  <option value="0">$$tr{note_color_black}</option>
</select>
</td>
</tr>
<tr>
<td class="noteMenuLabel">$$tr{note_rotation}</td>
<td><select name="nm_fgRotation" id="nm_fgRotation">
  <option value='0'>0 degrees</option>
  <option value='900'>90 degrees</option>
  <option value='1800'>180 degrees</option>
  <option value='2700'>270 degrees</option>
</select></td>
</tr>
<tr>
<td class="noteMenuLabel">$$tr{note_bold}</td>
<td><input type="checkbox" name="nm_fgBold" id="nm_fgBold"></td>
</tr>
<tr>
<td class="noteMenuLabel">$$tr{note_italic}</td>
<td><input type="checkbox" name="nm_fgItalic" id="nm_fgItalic"></td>
</tr>
<tr>
<td class="noteMenuLabel">$$tr{note_underline}</td>
<td><input type="checkbox" name="nm_fgUnderline" id="nm_fgUnderline"></td>
</tr>
</table>
</div>
<div id="nm_bodyBox">
<table>
<tr>
<td class="noteMenuLabel">$$tr{note_background}</td>
<td><select name="nm_bgColor" id="nm_bgColor">
  <option value="16777215">$$tr{note_color_white}</option>
  <option value="16776960">$$tr{note_color_cyan}</option>
  <option value="16711935">$$tr{note_color_magenta}</option>
  <option value="16711680">$$tr{note_color_blue}</option>
  <option value="65535">$$tr{note_color_yellow}</option>
  <option value="65280">$$tr{note_color_green}</option>
  <option value="255">$$tr{note_color_red}</option>
  <option value="12632256">$$tr{note_color_lightgray}</option>
  <option value="8421504">$$tr{note_color_darkgray}</option>
  <option value="8421376">$$tr{note_color_darkcyan}</option>
  <option value="8388736">$$tr{note_color_darkmagenta}</option>
  <option value="8388608">$$tr{note_color_darkblue}</option>
  <option value="32896">$$tr{note_color_darkyellow}</option>
  <option value="32768">$$tr{note_color_darkgreen}</option>
  <option value="128">$$tr{note_color_darkred}</option>
  <option value="0">$$tr{note_color_black}</option>
</select></td>
</tr>
<tr>
<td class="noteMenuLabel">$$tr{note_bordercolor}</td>
<td><select name="nm_bColor" id="nm_bColor">
  <option value="16777215">$$tr{note_color_white}</option>
  <option value="16776960">$$tr{note_color_cyan}</option>
  <option value="16711935">$$tr{note_color_magenta}</option>
  <option value="16711680">$$tr{note_color_blue}</option>
  <option value="65535">$$tr{note_color_yellow}</option>
  <option value="65280">$$tr{note_color_green}</option>
  <option value="255">$$tr{note_color_red}</option>
  <option value="12632256">$$tr{note_color_lightgray}</option>
  <option value="8421504">$$tr{note_color_darkgray}</option>
  <option value="8421376">$$tr{note_color_darkcyan}</option>
  <option value="8388736">$$tr{note_color_darkmagenta}</option>
  <option value="8388608">$$tr{note_color_darkblue}</option>
  <option value="32896">$$tr{note_color_darkyellow}</option>
  <option value="32768">$$tr{note_color_darkgreen}</option>
  <option value="128">$$tr{note_color_darkred}</option>
  <option value="0">$$tr{note_color_black}</option>
</select></td>
</tr>
<tr>
<td class="noteMenuLabel">$$tr{note_borderwidth}</td>
<td><select name="nm_bWidth" id="nm_bWidth">
  <option value='0'>0</option>
  <option value='1'>1</option>
  <option value='2'>2</option>
  <option value='3'>3</option>
  <option value='4'>4</option>
  <option value='5'>5</option>
  <option value='6'>6</option>
  <option value='7'>7</option>
  <option value='8'>8</option>
  <option value='9'>9</option>
</select></td>
</tr>
<tr>
<td class="noteMenuLabel">$$tr{note_opacity}</td>
<td><select name="nm_bgOpacity" id="nm_bgOpacity">
  <option value='0'>$$tr{note_opacity_transparent}</option>
  <option value='2'>$$tr{note_opacity_translucent}</option>
  <option value='1'>$$tr{note_opacity_opaque}</option>
</select></td></tr>
</table>
</div>
<div id="nm_bodyOptions">
<table>
<tr>
<td class="noteMenuLabel">$$tr{note_note}</td>
<td><input type="button" name="nm_duplicate" 
     id="nm_duplicate" value="$$tr{note_duplicate}"></td>
<td><input type="button" name="nm_delete" 
     id="nm_delete" value="$$tr{note_delete}"></td>
</td></tr>
</tr>
</table>
</div>
</div>
<a id="nm_tabClose" href=''>x</a>
</div>
EOF

  return \$noteMenu;
}

1;
