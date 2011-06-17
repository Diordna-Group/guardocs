use strict;

# -----------------------------------------------

=head1 main($global,$request)

	IN: object (inc::Global)
	    object (inc::Request)
	OUT: string

	Main entry point to the application

=cut

sub main
{
	my $global = shift;
	my $request = shift;
	
	if ($request->get('submit') eq "save") {
		main_save($global,$request);
	} elsif ($request->get('submit') eq "check") {
		main_check($global,$request);
	} elsif ($request->get('submit') eq "edit") {
		main_edit($global,$request);
	} elsif ($request->get('submit') eq "delete") {
		main_delete($global,$request);
	}
	
	my $return = main_header($global,$request);
	$return .= main_input($global,$request);
	$return .= main_footer();

	return $return;	
}

# -----------------------------------------------

=head1 convert_to_sql($global,$request)

	IN: object (inc::Global)
	    object (inc::Request)
	OUT: string

	Convert the form input values to an sql string

=cut

sub convert_to_sql
{
	my $global = shift;
	my $request = shift;
	my (%fields);
	my @fields = split /,/, $global->get('fields');
	my $max_comb = $global->get('number_comb');
	my $fulltext = $request->get('ft');
	my $start_comb_idx = 2;
	foreach (@fields) {
		my ($fieldlang,$field,$type) = split /:/, $_;
		$fields{$field}	= $type;
	}
	my $return = "SELECT Titel,Akte,Datum FROM archiv WHERE ";
	if (length($fulltext) > 0) {
		$start_comb_idx = 1;
	} 
	for (my $inc = 1; $inc <= $max_comb; $inc++) {
		my $comb = $request->get("comb_$inc");
		my $field = $request->get("field_$inc");
		my $value = $request->get("value_$inc");
		my $exact = $request->get("exact_$inc");
		next if length($value) == 0;
		if ($inc >= $start_comb_idx) {
			if ($comb eq "not") {
				$return .= "and ";	
			} else {
				$return .= "$comb ";
			}
		}
		$return .= " $field ";
		if ($fields{$field} eq "string" && $exact == 1) {
			if ($comb eq "not") {
				$return .= "!= '$value' ";	
			} else {
				$return .= "= '$value' ";
			}
		} elsif ($fields{$field} eq "string" && $exact != 1) {
			if ($comb eq "not") {
				$return .= "NOT LIKE '%$value%'";	
			} else {
				$return .= "LIKE '%$value%' ";
			}
		} elsif ($fields{$field} eq "number" && $exact == 1 && $value =~ /</) {
			$value =~ s/</<=/;
			$return .= " $value ";
		} elsif ($fields{$field} eq "number" && $exact == 1 && $value =~ />/) {
			$value =~ s/>/>=/;
			$return .= " $value ";
		} elsif ($fields{$field} eq "number" && $exact == 1) {
			$return .= "= $value ";
		} else {
			$return .= " $value ";	
		}
	}
	
	return $return;
}

# -----------------------------------------------

=head1 convert_to_form($global)

	IN: object (inc::Global)
	OUT: -

	Convert an SQL string to form input values

=cut

sub convert_to_form
{
	my $global = shift;
	my $sql = $global->get('sql');
	my $inc = 0;
	$sql =~ s/(SELECT.*?archiv\s)(.*?)(AND\sDatum.*)/$2/;
	my @comb = split /\sand\s|\sor\s/, $sql;
	
	foreach (@comb) {
		if ($sql =~ /($_\s)(and|or)/) {
			my $next = $inc+1;
			my $comb = $2;
			if ($sql =~ /NOT LIKE/ or $sql =~ /!=/) {
				$global->set("comb_$next","not");
			} else {
				$global->set("comb_$next",$comb);
			}
		}
		$global->set('sql',$_);
		$global->set('inc',$inc);
		parse_sql($global);
		$inc++;	
	}
}

# -----------------------------------------------

=head1 parse_sql($global)

	IN: object (inc::Global)
	OUT: -

	Parse an SQL string and save the required information to the object for
	displaying the values on the main form

=cut

sub parse_sql
{
	my $global = shift;
	my $sql = $global->get('sql');
	my $inc = $global->get('inc');
	if ($sql =~ /(.*?)(\sLIKE.*?%)(.*?)(%)/) { # Title LIKE '%string%'
		$global->set("field_$inc",$1);
		$global->set("value_$inc",$3);
		$global->set("exact_$inc",0);
	} elsif ($sql =~ /(.*?)(\s=\s')(.*?)(')/) { # Title = 'string'
		$global->set("field_$inc",$1);
		$global->set("value_$inc",$3);
		$global->set("exact_$inc",1);	
	} elsif ($sql =~ /(.*?)(\s)(.*?)(\s)/) { # Number =124, Number <=124, Number >=124
		my $value = $3;
		$global->set("field_$inc",$1);
		$global->set("exact_$inc",1) if ($value =~ /=/);
		$value =~ s/=//;
		$global->set("value_$inc",$value);
	}
}

# -----------------------------------------------

=head1 main_input($global,$request)

	IN: object (inc::Global)
	    object (inc::Request)
	OUT: string

	Create and return the main form HTML code

=cut

sub main_input
{
	my $global = shift;
	my $request = shift;
	my ($jobname,$ft);
	my $cgi_dir = $global->get('cgi_dir');
	my $max_comb = $global->get('number_comb');
	my $joberror = $global->get('joberror');
	if ($request->get('submit') eq "check") {
		$jobname = $request->get('jobname');
		$ft = $request->get('ft');
	} else {
		$jobname = $global->get('jobname');
		$ft = $global->get('ft');
	}
	my $sqlmsg = $global->get('sqlmsg');
	my $jobid = $global->get('jobid');
	my @fields = split /,/, $global->get('fields');
	my $return = qq{<form action="$cgi_dir/index.pl" method="post">\n};
	$return .= qq{<table border="0" cellpadding="0" cellspacing="0" width="100%">\n};
	$return .= qq{<tr><td align="center">\n};
	$return .= qq{<table border="0" cellpadding="0" cellspacing="0" width="100%">\n};
	$return .= qq{<tr><td width="100" height="30">Job name</td>};
	$return .= qq{<td colspan="4"><input type="text" name="jobname" value="$jobname" style="width: 200px;">&nbsp;};
	$return .= qq{<font class="Error">$joberror</font>} if (length($joberror) > 0);
	$return .= qq{</td><td>&nbsp;</td></tr>\n};
	$return .= qq{<tr><td height="30">Fulltext</td>};
	$return .= qq{<td colspan="4"><input type="text" name="ft" value="$ft" style="width: 200px;">&nbsp;};
	$return .= qq{</td><td>&nbsp;</td></tr>\n};
	$return .= qq{<tr><td colspan="2">&nbsp;</td></tr>\n};
	for (my $inc = 1; $inc <= $max_comb; $inc++) {
		my ($comb,$field,$value,$exact);
		if ($request->get('submit') eq "check") {
			$comb = $request->get("comb_$inc") if (length($request->get("comb_$inc")) > 0);
			$field = $request->get("field_$inc") if (length($request->get("field_$inc")) > 0);
			$value = $request->get("value_$inc") if (length($request->get("value_$inc")) > 0);
			$exact = $request->get("exact_$inc") if (length($request->get("exact_$inc")) > 0);
		} else {
			$comb = $global->get("comb_$inc") if (length($global->get("comb_$inc")) > 0);
			$field = $global->get("field_$inc") if (length($global->get("field_$inc")) > 0);
			$value = $global->get("value_$inc") if (length($global->get("value_$inc")) > 0);
			$exact = $global->get("exact_$inc") if (length($global->get("exact_$inc")) > 0);
		}
		$return .= qq{<tr height="30">\n};
		$return .= qq{<td width="120">\n};
		$return .= qq{<select name="comb_$inc">\n};
		$return .= qq{<option value="and"};
		$return .= " selected" if ($comb eq "and");
		$return .= qq{>AND</option>\n};
		$return .= qq{<option value="or"};
		$return .= " selected" if ($comb eq "or");
		$return .= qq{>OR</option>\n};
		$return .= qq{<option value="not"};			
		$return .= " selected" if ($comb eq "not");
		$return .= qq{>AND NOT</option>\n};
		$return .= qq{</select>\n};
		$return .= qq{&nbsp;&nbsp;&nbsp;</td>\n};
		$return .= qq{<td width="150">\n};
		$return .= qq{<select name="field_$inc">\n};
		foreach (@fields) {
				my ($fieldlang,$myfield,$type) = split /:/, $_;
				$return .= qq{<option value="$myfield"};
				$return .= " selected" if ($field eq $myfield);
				$return .= qq{>$fieldlang</option>\n};
		}
		$return .= qq{</select>\n};
		$return .= qq{&nbsp;&nbsp;&nbsp;</td>\n};
		$return .= qq{<td width="320">&nbsp;&nbsp;&nbsp;};
		$return .= qq{<input type="text" name="value_$inc" value="$value" style="width: 300px;">};
		$return .= qq{</td>\n};
		$return .= qq{<td width="100">&nbsp;&nbsp;&nbsp;<input type="checkbox" name="exact_$inc" value="1"};
		$return .= " checked" if ($exact == 1);
		$return .= qq{>&nbsp;Exact</td>\n};
		$return .= qq{</tr>\n};
	}
	$return .= qq{<tr><td>&nbsp;</td></tr>\n};
	if ($jobid > 0) {
		$return .= qq{<input type="hidden" name="editjobid" value="$jobid">\n};	
	}
	$return .= qq{<tr><td colspan="5" align="right"><input type="submit" name="submit" value="check"></td></tr>\n};
	$return .= qq{</form>\n};
	$return .= qq{<tr><td>&nbsp;</td></tr>\n};
	$return .= qq{</table>\n};
	$return .= qq{</td></tr>\n};
	$return .= qq{</table>\n};
	$return .= qq{<table border="0" cellpadding="0" cellspacing="0" width="100%">\n};
	$return .= qq{<tr><td colspan="6" align="left">$sqlmsg</td></tr>\n};
	$return .= qq{</table>\n};
	
	return $return;
}

# -----------------------------------------------

=head1 main_header($global,$request)

	IN: object (inc::Global)
	    object (inc::Request)
	OUT: string

	Return the header HTML code

=cut

sub main_header
{
	my $global = shift;
	my $request = shift;
	my $www_dir = $global->get('www_dir');
	my $cgi_dir = $global->get('cgi_dir');
	my $dbh = $global->get('dbh');
	my $uid = $global->get('uid');
	my $job = $request->get('jobs');
	
	my $return = qq{<form action="$cgi_dir/index.pl" method="post">\n};
	$return .= qq{<table border="0" cellpadding="0" cellspacing="0" width="100%">\n};
	$return .= qq{<tr>};
	$return .= qq{<td height="53" width="249" background="$www_dir/img/header1.png">};
	$return .= qq{&nbsp;};
	$return .= qq{</td>};
	$return .= qq{<td height="53" background="$www_dir/img/header2.png">};
	$return .= qq{&nbsp;};
	$return .= qq{</td>};
	$return .= qq{</tr>};
	$return .= qq{<tr>};
	$return .= qq{<td valign="top" width="249" height="500" background="$www_dir/img/menu_main.png">};
	$return .= qq{&nbsp;};
	$return .= qq{</td>};
	$return .= qq{<td valign="top">};
	$return .= qq{<table border="0" cellpadding="10" cellspacing="0">\n};
	$return .= qq{<tr><td>\n};
	$return .= qq{<table border="0" cellpadding="0" cellspacing="0" width="100%">\n};
	$return .= qq{<tr><td align="left" width="50">\n};
	$return .= qq{<a href="$cgi_dir/index.pl?mode=logout">};
	$return .= qq{<img src="$www_dir/img/pma07.gif" border="0">\n};
	$return .= qq{</a></td>\n};
	$return .= qq{<td align="right">\n};
	$return .= qq{<select name="jobs">\n};
	
	my $query = "SELECT Laufnummer,Name FROM workflow ";
	$query .= "WHERE Art='Workflow' AND User='$uid' AND Tabelle='archiv' ORDER BY Name";
	$global->set('query',$query);
	my $sth = exec_query($global);
	if ($sth->rows()) {
		while (my @row = $sth->fetchrow()) {
			$return .= qq{<option value="$row[0]"};
			$return .= " selected" if ($job == $row[0]);
			$return .= qq{>$row[1]</option>\n};
		} 
	} else {
		$return .= qq{<option value="-1">No jobs defined</option>\n};
	}
	sthFinish($sth);
	
	$return .= qq{</select>\n};
	$return .= qq{<input type="submit" name="submit" value="edit">&nbsp;};
	$return .= qq{<input type="submit" name="submit" value="delete">};
	$return .= qq{</td>\n};
	$return .= qq{</tr>\n};
	$return .= qq{</table>\n};
	$return .= qq{</form>\n};
	$return .= qq{<br><br>\n};
	
	return $return;
}

# -----------------------------------------------

=head1 main_footer()

	IN: -
	OUT: string

	Return the footer of the document

=cut

sub main_footer
{
	my $return = qq{</td></tr></table>};

	return $return;
}

# -----------------------------------------------

=head1 main_check($global,$request)

	IN: object (inc::Global)
	    object (inc::Request)
	OUT: -
	
	Perform the check if the values inserted by the user are ok or not. This
	function checks whether the created SQL string is ok and performs the query to
	check if between a time laps the query gives some results or not

=cut

sub main_check
{
	my $global = shift;
	my $request = shift;
	my $dbh = $global->get('dbh');
	my $cgi_dir = $global->get('cgi_dir');
	my $dmt_time = $global->get('dmt_time');
	my $test_time = $global->get('test_time');
	my $jobname = $request->get('jobname');
	my $jobid = $request->get('editjobid');
	my $fulltext = $request->get('ft');
	if (length($jobname) > 0) {
		my ($sqlmsg);
		my $sql = convert_to_sql($global,$request);
		my $dmt_sql = "$sql AND Datum >= '$dmt_time'";
		my $test_sql = "$sql AND Datum >= '$test_time'";
		if (length($fulltext) > 0) {
			$test_sql =~ s/(SELECT.*?FROM archiv)(.*)/$1,archivseiten$2/;
			$test_sql =~ s/(SELECT.*?WHERE\s)(.*)/$1MATCH archivseiten.Text AGAINST ('$fulltext' IN BOOLEAN MODE) $2 GROUP by Akte/;
		}
		my $sth = $dbh->prepare($test_sql);
		$sth->execute();
		if ($sth->err) {
			$sqlmsg = qq{$test_sql<br><br><font class="Error">This is an invalid SQL query</font>};
		} elsif ($sth->rows) {
			my $count = 0;
			my $matches = qq{<table border="0" cellpadding="0" cellspacing="0">\n};
			while (my @row = $sth->fetchrow()) {
				$count++;
				$row[2] =~ s/00:00:00//;
				$matches .= qq{<tr><td width="50">$row[1]</td><td width="100">$row[2]</td><td>$row[0]</td></tr>\n};
			}
			$matches .= qq{</table>\n};
			$sqlmsg = "$test_sql<br><br>Your query is ok.<br><br>Matches on this database:<br><br>$matches<br>";
			$sqlmsg .= qq{<br><br>Really save this job?<br><br>\n};
			$sqlmsg .= qq{<form action="$cgi_dir/index.pl" method="post">\n};
			$sqlmsg .= qq{<input type="hidden" name="editjobid" value="$jobid">\n};
			$sqlmsg .= qq{<input type="hidden" name="jobname" value="$jobname">\n};
			$sqlmsg .= qq{<input type="hidden" name="dmtsql" value="$dmt_sql">\n};
			$sqlmsg .= qq{<input type="hidden" name="ft" value="$fulltext">\n};
			$sqlmsg .= qq{<input type="submit" name="submit" value="save">\n};
			$sqlmsg .= qq{</form>};
		} else {
			$sqlmsg = "$test_sql<br><br>Your query is ok.<br><br>0 matches on this database";
			$sqlmsg .= qq{<br><br>Really save this job?<br><br>\n};
			$sqlmsg .= qq{<form action="$cgi_dir/index.pl" method="post">\n};
			$sqlmsg .= qq{<input type="hidden" name="editjobid" value="$jobid">\n};
			$sqlmsg .= qq{<input type="hidden" name="jobname" value="$jobname">\n};
			$sqlmsg .= qq{<input type="hidden" name="dmtsql" value="$dmt_sql">\n};
			$sqlmsg .= qq{<input type="hidden" name="ft" value="$fulltext">\n};
			$sqlmsg .= qq{<input type="submit" name="submit" value="save">\n};
			$sqlmsg .= qq{</form>};
		}
		$global->set('sqlmsg',$sqlmsg);
	} else {
		$global->set('joberror','Please enter a job name');	
	}	
}

# -----------------------------------------------

=head1 main_save($global,$request)

	IN: object (inc::Global)
	    object (inc::Request)
	OUT: -

	Save the new created SQL string to the workflow table. The method performs an
	UPDATE and an INSERT as well.

=cut

sub main_save
{
	my $global = shift;
	my $request = shift;
	my $dbh = $global->get('dbh');
	my $dmt_sql = $request->get('dmtsql');
	my $jobid = $request->get('editjobid');
	my $uid = $global->get('uid');
	my $jobname = $request->get('jobname');
	my $dmt_sql = $dbh->quote($dmt_sql);
	my $fulltext = $request->get('ft');
	my $fulltext = $dbh->quote($fulltext);
	my ($query);
	if ($jobid > 0) {
		$query = "UPDATE workflow SET Inhalt=$dmt_sql WHERE Laufnummer=$jobid";
		$dbh->do($query);	
		$query = "UPDATE workflow SET Volltext=$fulltext WHERE Laufnummer=$jobid";
		$dbh->do($query);
	} else {
		$query = "INSERT INTO workflow (Art,Tabelle,Name,Inhalt,User,Volltext) ";
		$query .= "values ('Workflow','archiv','$jobname',$dmt_sql,'$uid',$fulltext)";
		$dbh->do($query);
	}	
}

# -----------------------------------------------

=head1 main_edit($global,$request)

	IN: object (inc::Global)
	    object (inc::Request)
	OUT: -

	Select a specific workflow definition from the workflow table to edit

=cut

sub main_edit
{
	my $global = shift;
	my $request = shift;
	my $dbh = $global->get('dbh');
	my $job = $request->get('jobs');
	my ($jobid,$sql,$jobname);
	my $query = "SELECT Laufnummer, Inhalt, Name, Volltext FROM workflow WHERE Laufnummer=$job";
	$global->set('query',$query);
	my $sth = exec_query($global);
	while (my @row = $sth->fetchrow()) {
		($jobid,$sql,$jobname) = ($row[0],$row[1],$row[2]);
		$global->set('ft',$row[3]);
	}
	$global->set('sql',$sql);
	convert_to_form($global);
	sthFinish($sth);
	$global->set('jobname',$jobname);
	$global->set('jobid',$jobid);
}

# -----------------------------------------------

=head1 main_delete($global,$request)

	IN: object (inc::Global)
	    object (inc::Request)
	OUT: -

	Delete a specific workflow definition from the workflow table

=cut

sub main_delete
{
	my $global = shift;
	my $request = shift;
	my $dbh = $global->get('dbh');
	my $job = $request->get('jobs');
	my $query = "DELETE FROM workflow WHERE Laufnummer=$job";
	$dbh->do($query);		
}
	
1;

__END__
