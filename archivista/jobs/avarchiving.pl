#!/usr/bin/perl

use lib '/home/cvs/archivista/jobs';
use AVJobs;

my @args=split "/",shift;

my $database=$args[0];
my $user=$args[1];
my $password=$args[2];

archive_database(host => 'localhost', 
                 database => $database,
                 user => $user,
                 password => $password);
