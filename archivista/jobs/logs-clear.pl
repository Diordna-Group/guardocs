#!/usr/bin/perl

=head1 Main

This Programm was designed to clean up the logs table.
It expects one parameter. This parameter can be rows or clear.

count -> returns count of rows in the logs table
clear -> delets all rows in the logs table

=cut

use strict;
use lib qw(/home/cvs/archivista/jobs);
use AVDocs;

my $action = shift;
my $table = shift;
my $res;

if ($table eq "") {
  $table = 'logs';
} else {
  if ($table ne 'jobs' && $table ne 'jobs_data') {
	  $table = 'logs';
	}
}

my $av = AVDocs->new();
$av->setTable($table);
my $fld = "ID";
if ($table eq 'jobs') {
  $fld = "id";
} elsif ($table eq 'jobs_data') {
  $fld = "jid";
}

if ($action eq 'count') {
  $res = get_logs_count($av,$fld);
} elsif ($action eq 'clear') {
  $res = clear_logs($av,$table);
	$res = 0 if $res>0;
}
$res = -1 if !defined $res;

$av->close();
print $res;






=head2 get_logs_count($av)

Get the count of Rows in the Logs Table.

=cut

sub get_logs_count {
  my $av = shift;
	my $fld = shift;
	my $rows = $av->count('>'.$fld,0);
	return $rows;
}






=head2 clear_logs($av)

Delets all rows in logs table. Returns how many rows have been deleten.

=cut

sub clear_logs {
  my $av = shift;
	my $table = shift;
	return $av->deleteAll($table);
}

