# Global values for Archivista WebClient

package inc::Global;

BEGIN {
  use Exporter();
  use DynaLoader();
  @inc::Global::ISA    = qw(Exporter DynaLoader);
  @inc::Global::EXPORT = qw(loginStringNoHost loginStringHost 
                            defaultLoginHost defaultLoginDb defaultLoginUser
                            onlyLocalhost ExitButton OnlyArchiviert 
		            onlyDefaultDb ViewDatabase ViewHelp ViewAkte 
                            WebLinkFieldName WebLinkFieldTo 
	                    avdb_uid avdb_pwd avdb_host avdb_db);
}

use strict;

sub defaultLoginHost {
	return "localhost";
}

sub defaultLoginDb {
  return "archivista";
}

sub defaultLoginUser {
  return "Admin";
}

sub loginStringNoHost {
    return "";
}

sub loginStringHost {
    return "";
}

sub onlyLocalhost {
    return 0;
}

sub onlyDefaultDb {
	return 0;
}

sub WebLinkFieldName {
    return "";
}

sub WebLinkFieldTo {
    return "";
}

sub ExitButton {
    return 1;
}

sub ViewDatabase {
    return 1;
}

sub ViewHelp {
	return 1;	
}

sub ViewAkte {
    return 1;
}

sub OnlyArchiviert {
	return 0;	
}

sub avdb_host {
    return "localhost";
}

sub avdb_uid {
    return "root";
}

sub avdb_pwd {
    return "archivista";
}

sub avdb_db {
    return "archivista";
}

1;

