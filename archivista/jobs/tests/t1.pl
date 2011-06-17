#!/usr/bin/perl

=head1 sane-client.pl --- (c) by Archivista GmbH, v1.2 18.9.2005

Add images coming from scanadf to Archivista
        
=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
use AVDocs;

for (my $c1=0;$c1<1;$c1++) {
  my $c=AVDocs->new("localhost","archivista","Admin","archivista");
	print "userlevel: ".$c->user->level."\n";
	print $c->getTable."\n";
	$c->_getRow("asdfasdfasdfasdfasfas");
	my $x=$c->isError;
	if ($x) {
	  print "error: $x\n";
	}
	
  $c->setTable('languages');
	my $key = $c->search('id','USERNAME','languages');
	print $c->keyfield."\n";
	print "key: $key\n";
	$c->update('de',"Benutzername",'id','USERNAME');
	my $n=$c->select('de');
	print "$n\n";

  my @rows = $c->keys('!id','');
	foreach (@rows) {
    my $key = $_;
		my $key1=$c->key($key);
		print "key: $key1\n";
		my @row = $c->select();
		foreach (@row) {
		  print "$_\n";
		}
		last;
	}

  $c->setTable('archiv');
	my $state=$c->isAlive;

	if ($state) {
	  my $key = $c->search($c->FLD_DOC,111);
		print "$key\n";
	  my $pfields = [$c->FLD_TITLE."-",$c->SQL_OR,$c->SQL_OR,$c->FLD_DOC."+"];
		my $pvals = ["hallo","GUT","",'4-500'];
    my $count=$c->count($pfields,$pvals);
    my $min=$c->min($c->FLD_DOC,$pfields,$pvals);
    my $max=$c->max($c->FLD_DOC,$pfields,$pvals);
    my $sum=$c->sum($c->FLD_PAGES,$pfields,$pvals);
    my $rec=$c->search($pfields,$pvals);
    
		my @fields=$c->fieldnames;
		print "fields: ";
		foreach (@fields) {
      print "$_--";
		}
		print "\n";
		
	  my $l=$c->language($c->LANGUAGE_GERMAN);
		my @rec = $c->select;
		print "nothing: ";
		foreach (@rec) {
      print "$_---";
		}
		print "\n";

	  my $l=$c->language($c->LANGUAGE_ENGLISH);
    print "$l all: ";
    my @rec = $c->select($c->SQL_ALL);
		foreach (@rec) {
      print "$_---";
		}
		print "\n";
		
	  my $l=$c->language($c->LANGUAGE_SQL);
		print "only: ";
    my @rec = $c->select(15);
		foreach (@rec) {
      print "$_---";
		}
		print "\n";
		my @keys=$c->keys(['>'.$c->FLD_DOC],[1]);
		print "keys:\n";
		foreach (@keys) {
      print "$_---";
		}
		print "\n";
    print "stat: $count--$min--$max--$sum\n";
		print "level: ".$c->user->level."--".$c->user->id."\n";
    print "user password: ".$c->user->password."\n";
		
		my @dbs=$c->getDatabases;
		foreach(@dbs) {
		  print "$_\n";
		}
		print "--ended\n";
		print "$dbs[$c1]\n";
		print "..".$c->setDatabase($dbs[$c1])."\n";
	}
	#my $rec=$c->add($c->FLD_TITLE,"hier");
	my $rec=$c->add([$c->FLD_DOC,"eier",$c->FLD_TITLE],[1,"HIER","hier"]);
	my @wrong = $c->getErrorFields;
	foreach(@wrong) {
    print "wrong: $_\n";
	}
	my $done=$c->update($c->FLD_TITLE,"DDDDDDDDDD");
	print "updated: $done\n";
	my $r1=$c->select($c->FLD_TITLE);
	my $pos=$c->fieldpos($c->FLD_DOC);
	print "position: $pos\n";
	print "updated value: $r1\n";
	
	print "mysql ok: $rec--$state\n";
	if ($rec) {
	  print "add page\n";
	  my $done=$c->addPage($c->FLD_IMG_INPUT,"EINS");
		print "added\n";
		my $done=$c->updatePage(1,$c->FLD_IMG_SOURCE,"ZWEI");
		print "updated\n";
		my $done=$c->updatePage(1,$c->FLD_OCR,10);
		print "updated\n";

		my $d=$c->unlock($rec);
		print "unlocked $d\n";

		my $pages=$c->select($c->FLD_PAGES);

    my $pfld = [$c->FLD_IMG_INPUT,$c->FLD_IMG_SOURCE,$c->FLD_OCR];
		my ($img,$source,$ocr) = $c->selectPage($pages,$pfld);
		print "$img===$source-===$ocr+===$pages========\n";

		print "bevor removing: $pages\n";
		$done=$c->deletePage();
    print "delete page: $done\n";
		$pages=$c->select($c->FLD_PAGES);
		print "after: $pages\n";
	}
  my $done=$c->delete($c->FLD_DOC,$rec) if $rec>0;
	print "$rec deleted\n";
  my $p=$c->_quoteDate("13.2.2006");
	print "$p\n";
	print "-------------".$c->lockuser."\n";

	my $key=$c->key(10);
	print "key: $key\n";
	
	print "..".$c->setDatabase('archivista')."\n";
	my $id=$c->addJob($c->user,'SANE',$c->getScanDefByNumber(0));
	print $c->getScanDef."\n";
	print "id: $id\n";
	print $c->scan->get_name."\n";
	print $c->scan->get_dpi."\n";
	$c->scan->set_dpi(300);
	my $scandef=$c->scan->save;
	print "$scandef\n";
  $c->close;
}

