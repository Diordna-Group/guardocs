#!/usr/bin/perl

=head1 ocrNow.pl

This script restart ocr job for some documents again

=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
use DBI;
use AVJobs;

my $db = shift;
my $range = shift;
my $host = shift;
my $user = shift;
my $pw = shift;

restartOCRbatch($db,$range,$host,$user,$pw);





