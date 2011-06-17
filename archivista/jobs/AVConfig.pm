#!/usr/bin/perl

=head1 AVConfig

AVConfig holds all global variables that we use with Archivista

=cut

package AVConfig;

use strict;
use lib qw(/home/cvs/archivista/apcl /home/cvs/archivista/jobs);
use Archivista::Config;    # only needed for connection
use Wrapper;

sub logfile {wrap(@_)}
sub avversion {wrap(@_)}
sub identify {wrap(@_)}
sub jobpath {wrap(@_)}
sub jobwork {wrap(@_)}
sub jobstop {wrap(@_)}
sub jobend {wrap(@_)}
sub def_host {wrap(@_)}
sub def_db {wrap(@_)}
sub def_user {wrap(@_)}
sub def_pw {wrap(@_)}
sub avuser {wrap(@_)}
sub avgroup {wrap(@_)}
sub dirsep {wrap(@_)}
sub tmpdir {wrap(@_)}
sub gotif {wrap(@_)}
sub gojpg1 {wrap(@_)}
sub gojpg2 {wrap(@_)}
sub go1bit {wrap(@_)}
sub empty {wrap(@_)}
sub bcrec {wrap(@_)}
sub got2pnm {wrap(@_)}
sub gop2pnm {wrap(@_)}
sub gop2png {wrap(@_)}
sub pnmdepth {wrap(@_)}
sub convert {wrap(@_)}
sub gopnmflip {wrap(@_)}
sub gopnmr270 {wrap(@_)}
sub jpegrot {wrap(@_)}
sub tiffrot {wrap(@_)}
sub eimi {wrap(@_)}
sub eimr {wrap(@_)}
sub eimo {wrap(@_)}
sub eimc1 {wrap(@_)}
sub eimc2 {wrap(@_)}
sub eims {wrap(@_)}
sub bctypes {wrap(@_)}
sub thumbjpg {wrap(@_)}
sub thumbjpgqual {wrap(@_)}
sub thumbtif1 {wrap(@_)}
sub thumbtif1opt {wrap(@_)}
sub thumbtif1log {wrap(@_)}
sub thumbtif2 {wrap(@_)}
sub ftpin {wrap(@_)}
sub ftpgs {wrap(@_)}
sub ftpsane {wrap(@_)}
sub cupsin {wrap(@_)}
sub cupsps {wrap(@_)}
sub pdfinfo {wrap(@_)}
sub pdftk {wrap(@_)}
sub pdf2txt {wrap(@_)}
sub cupsinfo {wrap(@_)}
sub coldplus {wrap(@_)}
sub sanepost {wrap(@_)}
sub avfoldermax {wrap(@_)}
sub unzip {wrap(@_)}
sub bmptif {wrap(@_)}
sub tifpng {wrap(@_)}
sub dirimg {wrap(@_)}
sub lockarch {wrap(@_)}
sub lockavdb {wrap(@_)}
sub rmdirall {wrap(@_)}
sub archinput {wrap(@_)}
sub archoutput {wrap(@_)}
sub archscreen {wrap(@_)}
sub archtemp {wrap(@_)}
sub usbstick {wrap(@_)}
sub exportimages {wrap(@_)}
sub exportpdf {wrap(@_)}
sub exportfile {wrap(@_)}
sub ocrdo {wrap(@_)}
sub ocrhost {wrap(@_)}
sub ocrdb {wrap(@_)}
sub ocruser {wrap(@_)}
sub ocrpw {wrap(@_)}
sub ocrdoc {wrap(@_)}
sub ocrpdf {wrap(@_)}
sub ocrall {wrap(@_)}
sub ocrsingle {wrap(@_)}
sub ocrend {wrap(@_)}






=head1 BEGIN

Send all fatal errors to the log file


BEGIN {
  use CGI::Carp qw(carpout);
  open(LOG,">>/home/data/archivista/av.log") or die "unable to open log";
  carpout(LOG);
}

=cut






=head1 new

Initialize all needed variables

=cut

sub new {
  my $class = shift;
  my $self = {};
	bless $self,$class;

  $self->logfile("/home/data/archivista/av.log");
	$self->avversion(520);
  $self->identify("identify -ping ");
  $self->jobpath("/home/archivista/.wine/drive_c/Programs/Av5e/");
  $self->jobwork($self->jobpath."AV5AUTO.WRK");
  $self->jobstop($self->jobpath."AV5AUTO.STP");
  $self->jobend($self->jobpath."AV5AUTO.END");

  # where we get the Archivista connection
  #self->def_host="localhost";
  #self->def_db="archivista";
  #self->def_user="root";
  #self->def_pw="archivista";
  my $config = Archivista::Config->new;
  $self->def_host($config->get("MYSQL_HOST"));
  $self->def_db($config->get("MYSQL_DB"));
  $self->def_user($config->get("MYSQL_UID"));
  $self->def_pw($config->get("MYSQL_PWD"));
  undef $config;
  $self->avuser(500); # archivista user
  $self->avgroup(100); # group for archivista user
  $self->dirsep("/"); # seperate a directory ((windows/linux)
  $self->tmpdir("/tmp/"); # temp dir (in case we need a temporary file
  
  $self->usbstick("/mnt/usbdisk/"); # where we find the usb stick
  $self->exportimages("exchange/"); # default export folder for images
  $self->exportpdf("pdf/"); # default export folder for pdfs
  $self->exportfile("export.av5"); # default export file (Archivista values)
  
  $self->gotif("pnmtotiff -g4 >"); # program to convert from pipe to tif
  $self->gojpg1("pnmtojpeg --quality"); # program to convert from pipe to jpg
  $self->gojpg2(">"); # optin value
  $self->go1bit("/home/cvs/archivista/jobs/im/optimize2bw"); # optimize to 1 bit
  $self->empty("/home/cvs/archivista/jobs/im/empty-page"); # check empty pages
  $self->bcrec("/home/cvs/archivista/jobs/bc/bardecode -m"); # barcode rec
  $self->got2pnm("tifftopnm -respectfillorder"); # convert tif to a pnm file
  $self->gop2pnm("pngtopnm -respectillorder"); # convert png to a pnm file
  $self->gop2png("pnmtopng"); # convert pnm to png file
  $self->pnmdepth("pnmdepth"); # convert to x bits
  $self->convert("convert"); # ImageMagick convert
  $self->gopnmflip("pnmflip"); # use pnmflip for rotating
  $self->gopnmr270("-r270"); # rotate a pnm file
  $self->jpegrot("jpegtran -rotate"); # rotate a jpeg file
  $self->tiffrot("/home/cvs/archivista/jobs/im/rotate -r"); # tiff rotation
  $self->eimi("/home/cvs/archivista/jobs/im/econvert -i"); # econvert
  $self->eimr("--rotate"); # econvert rotate
  $self->eimo("-o"); # econvert output
  $self->eimc1("--colorspace GRAY"); # econvert colorspace (GRAY)
  $self->eimc2("--colorspace GRAY2"); # econvert colorspace (GRAY2)
  $self->eims("--box-scale"); # econvert box-scale (scaling down)

  # hash with types of barcode recognition
  $self->bctypes({
    0 => 'any',
    1 => 'code39',
    2 => 'code39',
    3 => 'code25',
    4 => 'code25',
    5 => 'ean13',
    6 => 'code128',
    7 => 'ean8'
  });

  $self->thumbjpg("epeg"); # program to generate a fast jpg thumbnail
  $self->thumbjpgqual("50"); # size in % of original image
  $self->thumbtif1("thumbnail -w"); # program to generate a fast tif thumbnail
  $self->thumbtif1opt("-h"); # option for generating tif thumbnail
  $self->thumbtif1log("2>/dev/null");
  $self->thumbtif2("tiff2png -force -destdir"); # program to convert it to png

  $self->ftpin("/home/data/archivista/ftp/"); # where we get the axis files
  $self->ftpgs("gs -dNOPAUSE -dNOPROMPT -dBATCH -q"); # gs with main attributes
  $self->ftpsane("/home/cvs/archivista/jobs/sane-client.pl");

  $self->cupsin("/var/spool/cups-pdf/ANONYMOUS/"); # in folder for cups files
  $self->cupsps("/var/spool/cups/"); # folder where we find the orig. ps file
  $self->pdfinfo("pdfinfo"); # program to extract pdf information
  $self->pdftk("pdftk"); # program to extract pdf pages
  $self->pdf2txt("pdftotext"); # program to extract text from pdf file
  $self->cupsinfo("lpstat_cups -W completed -o"); # check what job we got
  $self->coldplus("/home/data/archivista/cust/cold/coldplus.pl"); # coldplus
  $self->sanepost("/usr/bin/perl /home/cvs/archivista/jobs/sane-post.pl");    
  $self->dirimg("/home/data/archivista/images/"); # base path to images
  $self->avfoldermax(9999); # max. number of folders in archive
  $self->unzip("unzip"); # unzip a file
  $self->bmptif("bmp2tiff"); # convert a bmp file to a tiff file
  $self->tifpng("tiff2png"); # convert a tiff file to a png file

  $self->lockarch("avarch"); # user used for archiving process
  $self->lockavdb("avdb"); # user when working with AVDB class
  $self->archinput("input"); # normal archivista folders (for images)
  $self->archoutput("output");
  $self->archscreen("screen");
  $self->archtemp("temp");
  $self->rmdirall("rm -Rf ");

  $self->ocrdo(qq(/bin/su - archivista -c ". /etc/profile;export DISPLAY=:0;cd ) .
                qq(/home/archivista/.wine/drive_c/Programs/Av5e;) .
                qq(wine avocr.exe ));
  $self->ocrhost("  -h ");
  $self->ocrdb(" -d ");
  $self->ocruser(" -u ");
  $self->ocrpw(" -p ");
  $self->ocrdoc(" -f ");
  $self->ocrpdf(" -o ");
  $self->ocrall(" -a ");
  $self->ocrsingle(" -i ");
  $self->ocrend(qq("));

	return $self;
}

1;

