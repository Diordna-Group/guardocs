use strict;

# -----------------------------------------------

=head1 AVConnect($global)

	IN: object (inc::Global)
	OUT: database handler

	Return a database handler to the session database

=cut

sub AVConnect {
	my $global = shift;
	my $host = $global->get('host');
  my $db = $global->get('avdb');
  my $uid = $global->get('avuid');
  my $pwd = $global->get('avpwd');
  my $port = $global->get('port');
  my $dbh = DBI->connect("DBI:mysql:host=$host;database=$db;port=$port",$uid,$pwd);

	return $dbh;
}

# -----------------------------------------------

=head1 AVGetUserParam($global)

	IN: object (inc::Global)
	OUT: -

	Retrieve user session parameter like username and password

=cut

sub AVGetUserParam {
    my $global = shift;
    my $sid = $global->get('sid');
    my $table = $global->get('avtable');
    my $dbh = $global->get('avdbh');
    my $query = "SELECT uid,pwd FROM $table WHERE sid='$sid'";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my @row = $sth->fetchrow();
    $global->set('uid',$row[0]);
    $global->set('pwd',$row[1]);
    sthFinish($sth);
}

# -----------------------------------------------

=head1 AVCheckSID($global)

	IN: object (inc::Global)
	OUT: boolean value (0/1)

	Return 1 if the session id is value, 0 else

=cut

sub AVCheckSID {
    my $global = shift;
    my $sid = $global->get('sid');
    my $table = $global->get('avtable');
    my $dbh = $global->get('avdbh');
    my $check_sid = 0;
    my $sth = $dbh->prepare("SELECT sid FROM $table WHERE sid='$sid'");
		$sth->execute();
    if ($sth->rows()) { $check_sid = 1; }
    sthFinish($sth);
    return $check_sid;
}

# -----------------------------------------------

=head1 AVExecInsert($global)

	IN: object (inc::Global)
	OUT: -

	Open a new session, by inserting a new row on the session table

=cut

sub AVExecInsert {
		my $global = shift;
    my $dbh = shift;
    my $query = shift;
    my $table = $global->get('avtable');
    my $query = "INSERT INTO $table (sid,host,db,uid,pwd) $query";
   	$dbh->do($query);
}

# -----------------------------------------------

=head1 AVExecDelete($global)

	IN: object (inc::Global)
	OUT: -

	Remove an existing session, by deleting the corresponding row from the session
	table

=cut

sub AVExecDelete {
		my $global = shift;
    my $sid = $global->get('sid');
    my $table = $global->get('avtable');
    my $dbh = $global->get('avdbh');
    $dbh->do("DELETE FROM $table WHERE sid='$sid'");
}

1;
