#!/usr/bin/perl

use strict;
use Archivista::Config;    # is needed for the passwords and other settings
use lib qw(/home/cvs/archivista/jobs);
my $config = Archivista::Config->new;
my $pw = $config->get("MYSQL_PWD");
undef $config;
print "$pw";

