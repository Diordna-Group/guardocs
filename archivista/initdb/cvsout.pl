#!/usr/bin/perl
use strict;

my $cvs ="cvs -d :ext:ms\@192.168.0.96:/home/CVS checkout ";
my $st="../";
my $back="back";
my $m1="webadmin";
my $m2="webclient";
my $m3="apcl";
my $m3="jobs";

my @modules=($m1,$m2,$m3);
my @vars=("cp $st$m1$back/perl/ASConfig.pm $st$m1/perl",
         "cp $st$m2$back/perl/inc/Global.pm $st$m2/perl/inc",
         "cp $st$m3$back/Archivista/Config.pm $st$m3/Archivista");
my $checkout;

foreach(@modules) {
  my $o=$_;
	my $b="$o$back";
  eval(system("rm -Rf $st$b"));
  eval(system("mv $st$o $st$b"));
	$checkout.="$o ";
}
eval(system("$cvs $checkout"));

foreach(@modules) {
  eval(system("mv ./$_ .."));
}

foreach(@vars) {
  system("$_");
}
