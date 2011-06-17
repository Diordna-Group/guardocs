
use strict;

package inc::Check;

sub hashes {
  my $f = shift;
  my $pcheck = shift;
	my @fparts = split(/::/,$f);
	$f = join("/",@fparts);
	$f .= ".pm";
	open(FIN,$f);
	my @r = <FIN>;
	close(FIN);

  my @errors=();
	my $errnr=0;
	my $linenr=0;
	foreach (@r) {
	  my $line = $_;
		chomp $line;
		last if $line eq "__DATA__";
		$linenr++;
	  foreach (keys %$pcheck) {
		  my $key = $_;
			my @keys = split(/(\$$key\{.*?\})/,$line);
			foreach (@keys) {
			  my $line1 = $_;
			  my $key2 = $line1;
		    $key2 =~ s/^(.*?)(\$)($key)(\{)(.*?)(\})(.*)$/$5/;
			  my $name = "";
			  if ($key2 ne $line1) {
				  foreach my $key1 (@{$$pcheck{$key}}) {
					  if ($key1 eq $key2) {
				      $name=$_;
					    last;
					  }
				  }
				  if ($name eq "") {
				    $errnr++;
					  push @errors,"line $linenr: $key2 in hash $key not allowed";
				  }
				}
		  }		
		}
	}
	if ($errnr>0) {
	  foreach (@errors) {
		  print STDERR "$_\n";
		}
	  die;
	}
}

1;

