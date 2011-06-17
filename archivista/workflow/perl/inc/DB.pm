use strict;

# -----------------------------------------------

=head1 dbhOpen($global)

	IN: object (inc::Global)
	OUT: database handler

	Return a database handler for the logged user

=cut

sub dbhOpen {
	my $global = shift;
    my $host = $global->get('host');
    my $db = $global->get('db');
    my $uid = $global->get('uid');
    my $pwd = $global->get('pwd');
    my $port = $global->get('port');
   	return DBI->connect("DBI:mysql:host=$host;database=$db;port=$port",$uid,$pwd);
}

# -----------------------------------------------

=head1 exec_query($global)

	IN: object (inc::Global)
	OUT: statement handler

	Execute a query and return the active statement handler to handle the data 

=cut

sub exec_query {
    my $global = shift;
    my $dbh = $global->get('dbh');
    my $query = $global->get('query');
    my $sth = $dbh->prepare($query);
    $sth->execute();
    return $sth;
}

# -----------------------------------------------

=head1 sthFinish($sth)

	IN: statement handler
	OUT: -

	Finish a statement handler

=cut

sub sthFinish {
    my $sth = shift;
    $sth->finish();
}

# -----------------------------------------------

=head1 dbhClose($dbh)

	IN: database handler
	OUT: -

	Close a connection to the database

=cut

sub dbhClose {
    my $dbh = shift;
    $dbh->disconnect();
}


1;
