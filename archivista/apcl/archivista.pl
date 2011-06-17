#!/usr/bin/perl

my $mod_check = eval { require Archivista };

if ($mod_check) {
	print "Congratulations: the Archivista Perl Class Library is ready to use\n";
} else {
	print "I can't find the Perl Class Library, please check the installation\n";
  print "ERROR: $@\n";
}
