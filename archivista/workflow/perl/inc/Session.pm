use strict;
use Carp;

use Digest::MD5 qw(md5_hex);

# -----------------------------------------------

=head1 getUserParam($global)

	IN: object (inc::Global)
	OUT: -

	Read all user session params into the global object

=cut

sub getUserParam {
	my $global = shift;
    AVGetUserParam($global);
    my $key = reverse($global->get('uid'));
    my $pwd = $global->get('pwd');
    $global->set('pwd',Decipher($pwd,$key));
}

# -----------------------------------------------

=head1 openSession($global)

	IN: object (inc::Global)
	OUT: -

	Open a new session for a logged user

=cut

sub openSession {
	my $global = shift;
	my $dbh = $global->get('avdbh');
    my $host = $dbh->quote($global->get('host'));
    my $db = $dbh->quote($global->get('db'));
    my $uid = $global->get('uid');;
    my $pwd = $global->get('pwd');
    my $session = localtime();
    my $key = reverse($uid);
    $session = md5_hex "$session$uid$db";
    $pwd = Cipher($pwd,$key);
    $pwd = $dbh->quote($pwd);   
    $uid = $dbh->quote($uid);
    my $values = "'$session',$host,$db,$uid,$pwd";
    my $sql="values ($values)";
    AVExecInsert($global,$dbh,$sql);
    $global->set('sid',$session);
}

# -----------------------------------------------

=head1 closeSession($global)

	IN: object (inc::Global)
	OUT: -

	Remove an active session

=cut

sub closeSession {
	my $global = shift;
    AVExecDelete($global);
}

# -----------------------------------------------

=head1 setCookie($key,$value)

	IN: cookie key
	    cookie value
	OUT: cookie string

	Return the cookie string to send to the browser to set a cookie

=cut

sub setCookie {
    my $key = shift;
    my $value = shift;
    return "Set-Cookie: $key=$value; path=/;\n";
}

# -----------------------------------------------

=head1 getCookie($get_key)

	IN: cookie key
	OUT: cookie value

	Retrieve a cookie
	
=cut

sub getCookie {
    my $get_key = shift;
    if (defined $ENV{'HTTP_COOKIE'}) {
			my @key_value_pairs = split /;\s/, $ENV{'HTTP_COOKIE'};
			foreach (@key_value_pairs) {
	   		my ($key,$value) = split /=/, $_;
	    	return $value if ($key eq $get_key);
			}
    } else {
			return 0;
    }
}

# -----------------------------------------------

=head1 checkSID($global)
	
	IN: object (inc::Global)
	OUT: boolean value (0/1)

	Return 1 if the session id is valid, 0 else

=cut

sub checkSID {
    my $global = shift;
    return AVCheckSID($global);
}

1;

__END__
