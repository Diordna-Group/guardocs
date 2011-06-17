# Current revision $Revision: 1.1.1.1 $
# On branch $Name:  $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:21:18 $

use strict;
use Carp;
use Crypt::DES;

# -----------------------------------------------

=head1 Chipher($string)

	IN: String(cipher), String(cipher-key)
	OUT: Encrypted string

	This method makes an encryption of a given string
	
=cut

sub Cipher {
    ###
    # String to chipher
    my $string = shift;

    ###
    # Chipher key can be max 16 chars long
    my $key = shift;

    my (@key,@string,@ciphertext,$ciphertext);

    ###
    # Converting the given key and create a DES object with this key
		@key = DESString("16",$key,0);
    $key = join "", @key;
    $key = pack("H16",$key);
    my $cipher = new Crypt::DES $key;

    ###
		# Split the password string into 8-char blocks. DES can encrypt only 8 char
		# strings
    @string = DESString("8",$string,1);

    ###
    # Encrypt all 8-char strings
    foreach (@string) { push @ciphertext, $cipher->encrypt($_); }
    
    ###
    # Get the entire encrypted string
    $ciphertext = join "", @ciphertext;
    
    undef $cipher;

    return $ciphertext;
}

# -----------------------------------------------

=head1 Decipher($string,$key)

	IN: String(cipher), String(key)
	OUT: Decrypted string

	This method decrypts an encrypted string based on the given key

=cut

sub Decipher {
    my $string = shift;
    my $key = shift;
    
    my (@key,@string,@plaintext,$plaintext);

    @key = DESString("16",$key,0);
    $key = join "", @key;
    $key = pack("H16",$key);
    my $cipher = new Crypt::DES $key;
    
    @string = DESString("8",$string,1);

    ###
    # Encryption of all substrings
		foreach (@string) { push @plaintext, $cipher->decrypt($_); }

    ###
    # Get the entire encrypted string
    $plaintext = join "", @plaintext;

    return $plaintext;
}

# -----------------------------------------------

=head1 DESString($length,$string,$string_parts)

	IN: Integer(length), String(cipher), Integer(nr of substrings)
	OUT: Array(substrings)

	Check in how many substrings a string can be splitted
	Split the cipher string into substrings

=cut

sub DESString {
    my $length = shift;
    my $string = shift;
    my $string_parts = shift;
    my (@parts,$inc,$start,$end,$parts,$substr);
    
    if ($string_parts) {
			# Parts contains the nr of substrings of length $length, the string
			# $string can be splitted
			$parts = length($string) / $length;
			if ($parts =~ /(.*)(\.)(.*)/) {
	    	$parts = $1+1;    
			}
			# For the nr of substrings that can be made, create this substrings in
			# order that all substring has the same length
			for ($inc=0; $inc<$parts; $inc++) {
	    	$start = $inc*($length);
	    	$substr = substr($string,$start,$length);
	    	push @parts, $substr."\0" x ($length-length($substr));
			}
    } else {
			push @parts, substr($string,0,$length);
    }

    return @parts;
}

1;

# Log record
# $Log: DESModule.pm,v $
# Revision 1.1.1.1  2008/11/09 09:21:18  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:24  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.2  2005/11/28 11:39:09  ms
# Added POD
#
