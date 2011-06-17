use strict;

# -----------------------------------------------

=head1 header($global)

	IN: object (inc::Global)
	OUT: string

	Return the HTML header for the document

=cut

sub header {
    my $global = shift;
    my $cookie = $global->get('cookie');
    my $www_dir = $global->get('www_dir');
    
    my $print = "Content-type: text/html\n";
   	$print .= $cookie if (length($cookie) > 0);
    $print .= "\n";
    $print .= qq{<html>\n};
    $print .= qq{<head>\n};
    $print .= qq{<title>Archivista Workflow Module</title>\n};
    $print .= qq{<meta content="no-cache" http-equiv="Cache-Control">\n};
    $print .= qq{<meta content="0" http-equiv="Expires">\n};
    $print .= qq{<meta content="no-cache" http-equiv="Pragma">\n};
    $print .= qq{<style type="text/css">\@import url("$www_dir/css/dmt.css")\;</style>};
    $print .= qq{</head>\n};
    $print .= qq{<body bgcolor="#ffffff">\n};
    
		return $print;
}

# -----------------------------------------------

=head1 footer()

	IN: -
	OUT: string

	Return the HTML footer for the document

=cut

sub footer {
    return qq{</body>\n</html>\n};
}

# -----------------------------------------------

=head1 login_form($global,$request)

	IN: object (inc::Global)
			object (inc::Request)
	OUT: string

	Return the HTML string for the login form

=cut

sub login_form {
	my $global = shift;
	my $request = shift;
	
	my ($onlyDefaultHost,$host,$onlyDefaultDb,$db);
	my $www_dir = $global->get('www_dir');
  my $cgi_dir = $global->get('cgi_dir');	
	my $error = $global->get('error');
  my $uid = $request->get('uid');
  my $login_title = $global->get('login_title');
  
	my $print = loginMaskHeader($www_dir,$cgi_dir);

  # LOGIN MASK
  $print .= qq{<table border="0" cellpadding="0" cellspacing="0">\n};
  if (! $onlyDefaultHost) {
    $print .= qq{<tr><td width="100" height="20">Host</td>};
    $print .= qq{<td><input type="text" name="host" value="$host">};
    $print .= qq{</td></tr>\n};
  } else {
		$print .= qq{<input type="hidden" name="host" value="$host">};
	}
	if (! $onlyDefaultDb) {
  	$print .= qq{<tr><td width="100" height="20">Database};
  	$print .= qq{</td><td><input type="text" name="db" value="$db">};
  	$print .= qq{</td></tr>\n};
  } else {
		$print .= qq{<input type="hidden" name="db" value="$db">};
	}
	$print .= qq{<tr><td width="100" height="20">Username</td><td>};
  $print .= qq{<input type="text" name="uid"></td></tr>\n};
  $print .= qq{<tr><td height="20">Password</td><td>};
  $print .= qq{<input type="password" name="pwd"></td></tr>\n};
  $print .= qq{<tr><td colspan="2" height="35" align="right" };
  $print .= qq{valign="center" class="Error">$error</td></tr>\n};
  $print .= qq{<tr><td colspan="2" align="right"><input type="submit" value="};
  $print .= "Login";
  $print .= qq{"></td></tr>\n};
  $print .= qq{<tr><td colspan="2" align="right">&nbsp;</td></tr>\n};
  $print .= qq{</table>\n};
  # END LOGIN MASK
 
  $print .= loginMaskFooter();
	
	return $print;
}

# -----------------------------------------------

=head1 loginMaskHeader()

	IN: www dir
	    cgi dir
	OUT: string
	
	Displays the HTML header of the login mask

=cut

sub loginMaskHeader
{
	my $www_dir = shift;
	my $cgi_dir = shift;
	
	my $print = BodyOpen();
 	$print .= qq{<form action="$cgi_dir/index.pl" };
  $print .= qq{method="post" name="login">\n};
  $print .= qq{<table border="0" cellpadding="0" cellspacing="0" width="100%" height="95%">\n};
	$print .= qq{<tr><td width="10%">&nbsp;</td>};
 	$print .= qq{<td align="center" valign="center">\n};
 	     
	$print .= qq{<table border="0" cellpadding="1" cellspacing="0" width="100%">\n};
	$print .= qq{<tr><td class="TableBorder">};

  $print .= qq{<table border="0" cellpadding="0" cellspacing="0" width="100%">\n};
	$print .= qq{<tr>\n};
	$print .= qq{<td height="53" background="$www_dir/img/login_header.png" colspan="2"></td>};
	$print .= qq{</tr>\n}; 
	$print .= qq{<tr><td>\n};
      
	$print .= qq{<table border="0" cellpadding="0" cellspacing="0" width="100%">\n};
  $print .= qq{<tr>};
  $print .= qq{<td width="248" height="307" background="$www_dir/img/login_left.png">&nbsp;</td>};
  $print .= qq{<td align="center" valign="center" class="LoginMask">\n};
      
  $print .= qq{<table border="0" cellpadding="0" cellspacing="0" width="100%">\n};
  $print .= qq{<tr>\n};
  $print .= qq{<td colspan="2" align="right" class="Title">Archivista Workflow Module<br>\n};
  $print .= qq{<font class="powered">Powered by };
  $print .= qq{<a href="http://www.archivista.ch">Archivista GmbH</a></font>};
  $print .= qq{</td></tr>\n};
  $print .= qq{<tr><td height="40">&nbsp;</td></tr>\n};
  $print .= qq{<tr>\n};
  $print .= qq{<td width="20">&nbsp;</td>\n};
  $print .= qq{<td>\n};
  
  return $print;
}

# -----------------------------------------------

=head1 loginMaskFooter()

	IN: -
	OUT: string
	
	Displays the HTML login mask footer

=cut

sub loginMaskFooter
{
  my $print = qq{</td></tr>\n};
  $print .= qq{</table>\n};
      
  $print .= qq{</td></tr>\n};
  $print .= qq{</table>\n};

  $print .= qq{</td></tr>\n};
  $print .= qq{</table>\n};

  $print .= qq{</td><td width="10%">&nbsp;</td></tr>\n};
  $print .= qq{</table>\n};
  $print .= qq{</form>\n};

  $print .= BodyClose();
  
	return $print;
}

# -----------------------------------------------

=head1 BodyOpen($setFocus,$styles)

	IN: String(focus on element of document)
			String(style class)
	OUT: String(HTML body tag)

	Return the HTML body tag

=cut

sub BodyOpen {
    return qq{<body>};
}

# -----------------------------------------------

=head1 BodyClose()

	IN: -
	OUT: String(HTML body tag)

	Return the HTML closing body tag

=cut

sub BodyClose {
    return qq{</body>};
}

1;












