<?php

/*Connection Information for the database
- $def_coy is the default company that is pre-selected on login

- host is the computer ip address or name where the database is the default is localhost assuming that the web server is also the sql server

- user is the user name under which the database should be accessed - need to change to the mysql (or other DB) user set up for purpose
  NB it is not secure to use root as the user with no password - a user with appropriate privileges must be set up

- password is the password the user of the database requires to be sent to authorise the above database user

- DatabaseName is the name of the database as defined in the RDMS being used. Typically RDMS allow many databases to be maintained under the same server.
  The scripts for MySQL provided use the name logicworks */


$fh = fopen("/home/cvs/archivista/apcl/Archivista/Config.pm","r");
$text = fread($fh,1024);
fclose($fh);
$search = "/(self->{\'MYSQL_PWD\'} = \")(.*?)(\")/";
preg_match($search,$text,$res);

$def_coy = 3;

$db_connections = array (
	0 => array ('name' => 'Archivista GmbH',
		'host' => 'localhost',
		'dbuser' => 'root',
		'dbpassword' => $res[2],
		'dbname' => 'archivistaerp')
,

	array ('name' => 'Archivista GmbH',
		'host' => 'localhost',
		'dbuser' => 'root',
		'dbpassword' => $res[2],
		'dbname' => 'archivistaerp1')
,

	array ('name' => 'Archivista GmbH',
		'host' => 'localhost',
		'dbuser' => 'root',
		'dbpassword' => $res[2],
		'dbname' => 'archivistaerp2')
,

	array ('name' => 'Archivista GmbH',
		'host' => 'localhost',
		'dbuser' => 'root',
		'dbpassword' => $res[2],
		'dbname' => 'archivistaerp3')

);

?>
