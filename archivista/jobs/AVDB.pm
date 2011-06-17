#!/usr/bin/perl

package AVDB;

use strict;
use AVBase;
use AVField;
use DBI;
use Wrapper;

our @ISA = qw(AVBase);



use constant CHAR => 'varchar';
use constant CHARFIX => 'char';
use constant TIMESTAMP => 'timestamp';
use constant YESNO => 'tinyint';
use constant INT => 'int';
use constant BLOB => 'blob';
use constant TEXT => 'text';
use constant MEDIUMTEXT => 'mediumtext';
use constant MEDIUMBLOB => 'mediumblob';
use constant LONGTEXT => 'longtext';
use constant LONGBLOB => 'longblob';
use constant DATE => 'datetime';
use constant KEY => 'PRI';
use constant SQL_DESCRIBE => 'describe ';
use constant SQL_SHOWTABLES => 'show tables';
use constant SQL_SHOWDATABASES => 'show databases';
use constant SQL_SLAVE => 'show slave status';
use constant SQL_SLAVE2 => "show variables like 'server%'";
use constant SQL_SHOWPROCESSLIST => 'show processlist';
use constant SQL_TEST => 'select version()';

use constant SQL_EMPTY => ' ';
use constant SQL_SELECT=> 'select ';
use constant SQL_ALL => '*';
use constant SQL_FROM => ' from ';
use constant SQL_WHERE => ' where ';
use constant SQL_ORDER => ' order by ';
use constant SQL_ASC => ' asc';
use constant SQL_DESC => ' desc';
use constant SQL_SET => ' set ';
use constant SQL_DELETE => 'delete from ';
use constant SQL_UPDATE => 'update ';
use constant SQL_INSERT => 'insert into ';
use constant SQL_INSERT_EMPTY => ' () values ()';
use constant SQL_INSERT_LAST => 'select last_insert_id()';

use constant SQL_LIKE => ' like ';
use constant SQL_BETWEEN => ' between ';
use constant SQL_AND => ' and ';
use constant SQL_OR => ' or ';
use constant SQL_NOT => ' not ';
use constant SQL_ISNULL => ' is null '; 
use constant SQL_LIMIT => ' limit ';
use constant SQL_LIMIT1 => ' limit 1';

use constant SQL_MAX_FIELDS => 200; # max. number of fields we can retrieve
use constant SQL_DEF_ROWS => 16; # number of records for limit method

use constant TABLE_DEFAULT => 'archiv';
use constant FLD_DEFAULT => 'Laufnummer';

use constant SEARCH_REC => '';
use constant SEARCH_COUNT => 'count';
use constant SEARCH_MIN => 'min';
use constant SEARCH_MAX => 'max';
use constant SEARCH_SUM => 'sum';

use constant LANGUAGE_SQL => 'undef';
use constant LANGUAGE_GERMAN => 'de';
use constant LANGUAGE_ENGLISH => 'en';

sub dbh {wrap(@_)}
sub dbHost {wrap(@_)}
sub dbDatabase {wrap(@_)}
sub dbUser {wrap(@_)}
sub dbPassword {wrap(@_)}
sub dbState {wrap(@_)}
sub loglevel {wrap(@_)}
sub table {wrap(@_)}
sub keyvalue {wrap(@_)}
sub keyfield {wrap(@_)}
sub keyquote {wrap(@_)}
sub searchmode {wrap(@_)}
sub searchfield {wrap(@_)}
sub waitsleep {wrap(@_)}
sub rec {wrap(@_)}
sub sqllimit {wrap(@_)}
sub langcode {wrap(@_)}
sub lockuser {wrap(@_)}
sub errornr {wrap(@_)}
sub errorfields {wrap(@_)}
sub errorfieldstate {wrap(@_)}

# dbh: database handler
# dbHost: host of current connection
# dbDatabase: database name "
# dbUser: user name "
# dbPassword: password "
# dbState: 0=connection not ok, 1=connection ok
# loglevel: 0=no additional logs, >0=all sql commands
# table: all table names (only already used one)
# keyvalue: current (default) record number for primary key
# keyfield: current (default) fieldname for primary key
# searchmode: 0=we want the first record, 1=we want the number of records
# waitsleep: x=number of seconds to wait if the db connection is not ok
# sqllimit: give keys function a way to retrieve some keys (limit 'x,y')
# rec: variable to store the current table definitions (only already used one)
# langcode: '' (undef), de, en (see constants)
# errornr: latest error code from an sql command


my $count=-1; # number of tables stored in memory
my @tables; # the list array for the tables
my @keyfield; # the lastkey array
my @rec; # the field definitions for the current table






=head1 new([$host,$database,$user,$password],$table) 

We give back an object and connect to the database (given 
with host,db,user,pwd). Without parameters the default
database connection is made with the values from AVConfig.

=cut

sub new {
  my $class = shift;
  my ($host,$db,$user,$pw,$table) = @_;
	my $self = $class->SUPER::new();
  $self->_connect($host,$db,$user,$pw);
  $self->loglevel(0); # if loglevel=1, every SQL command will be logged
  $self->waitsleep(5); # seconds to wait in case Database is not alive
  $self->langcode($self->LANGUAGE_SQL); # no date formating while select
  $table=$self->TABLE_DEFAULT if $table eq "";
  $self->_checkTable(\$table); # initialize the default table
	return $self;
}






=head1 close

Close the database handler (disconnect if connected)

=cut

sub close {
  my $self = shift;
  eval($self->dbh->disconnect()) if $self->dbh;
  $self->dbh(undef);
}






# $dbh=_connect($host,$db,$user,$pw)
# Open a database connection (is ALWAYS CALLED from new method!)
#
sub _connect {
  my $self = shift;
  my ($host,$db,$user,$pw) = @_;
  $self->dbHost("");
  $self->dbDatabase("");
  $self->dbUser("");
  $self->dbPassword("");
  $self->dbState(0);
  $self->dbh(undef);
  if ($host eq "" && $user eq "" && $db eq "") {
    # if we don't have any connection values, just use the session ones
    $host=$self->def_host;
    $db=$self->def_db;
    $user=$self->def_user;
    $pw=$self->def_pw;
  }
  $self->dbh($self->_connectDB($host,$db,$user,$pw));
  if ($self->dbh) {
    # connection is ok
    $self->dbHost($host);
    $self->dbDatabase($db);
    $self->dbUser($user);
    $self->dbPassword($pw);
    $self->dbState(1);
    $self->lockuser($self->lockavdb."$$");
  }
  return $self->dbState;
}






# internal method to open the database handler
#
sub _connectDB {
  my $self = shift;
  my ($host,$db,$user,$pw) = @_;
  my ($ds,$dbh);
  $ds = "DBI:mysql:host=$host;database=$db";
  $dbh = DBI->connect($ds,$user,$pw,{PrintError=>0,RaiseError=>0});
  return $dbh;
}






=head1 $val=select([$pFields,$pSearchFields,$pSearchVals,$table])

Give back the record values that are in pFields given the pSearchFields
and the pSearchValues in $table. If the parameters are not available,
we use the default values (the current key in the current table).
If pFields has no values, we get back all fields. Some Examples:

$cl->select -> all fields from current record

$cl->select(9) -> the first ten fields (0 counts) from the current record

$cl->select($cl->FLD_DOC) -> give back the FLD_DOC from the current reocrd

$cl->select($cl->FLD_DOC,['>'.$cl->FLD_DOC.'+',$c->FLD_TITLE],[100,'x'])

does mean get back the FLD_DOC number where FLD_DOC is > 100 (asc sorting)
AND FLD_TITLE has the value 'x'.

HINT: If the select (or any other command) is not ok, $c->isError 
gives back an error code.

=cut

sub select {
  my $self = shift;
  my ($pfields,$condField,$condValue,$table) = @_;
  return $self->_select($pfields,$condField,$condValue,$table);
}






# compose sql and give back record(s) information
#
sub _select {
  my $self = shift;
  my ($pfields,$condField,$condValue,$table) = @_;
  my ($prows,@row,@dates,@yes,$single,$sql,$val,$whereorder);
  if ($self->sqllimit ne "") {
    # give back a number of records in a pointer of a list
    $self->_checkTable(\$table);
    if (defined($condField) && defined($condValue)) {
      # give back a pointer to a number of records ($prows)
      $whereorder=$self->_composeSQL($condField,$condValue,\$table);
    }
    if ($whereorder) {
      my ($select,$keypos)=$self->_selectComposeSelect($pfields,$table,
                                            \@dates,\@yes,\$single);
      $sql = $select.$self->SQL_WHERE.$whereorder;
      $sql.=$self->SQL_LIMIT.$self->sqllimit;
      $prows = $self->_getRows($sql);
      $self->keyvalue($$prows[0]->[$keypos]); # set it to 1st rec.
      $self->keyvalue(0) if $self->keyvalue eq "";
      my $cp=0;
      foreach(@$prows) {
        # correct format of Dates/Yes/No-Fields for every record
        $self->_selectCheckForValues($$prows[$cp],\@dates,\@yes);
        $cp++;
      }
    }
    $self->sqllimit("");
    return $prows;
  } else {
    # give back one record/field AND sets keyvalue/keyfield
    $val=$self->_initFields($condField,$condValue,\$table);
    if ($val) {
      my $keypos;
      ($sql,$keypos) = $self->_selectComposeSelect($pfields,$table,
                                       \@dates,\@yes,\$single);
      $sql.=$self->SQL_WHERE.$val;
      $sql.=$self->SQL_LIMIT1;
      @row = $self->_getRow($sql);
      $self->_selectCheckForValues(\@row,\@dates,\@yes); # check dates/yes/no
    }
    if ($single==1) {
      return $row[0];
    } else {
      return @row;
    }
  }
}






# compose the where part of the select
#
sub _selectComposeSelect {
  my $self = shift;
  my ($pfields,$table,$pdates,$pyes,$psingle) = @_;
  # compose field names (''/*,int = alls or x fields, name=1 field)
  my $keypos;
  ($pfields,$keypos) = $self->_selectComposeFields($pfields,$table);
  my $c=0;
  my $field="";
  foreach (@$pfields) {
    # compose SQL field list AND check for DATE fields
    my $field1 = $_;
    $$psingle=0 if $c>0;
    my ($name,$type,$size) = $self->_field($field1,$table);
    $$pdates[$c]=$name if ($name eq $field1 && $type eq $self->DATE);
    $$pyes[$c]=$name if ($name eq $field1 && $type eq $self->YESNO);
    $field.="," if $field ne "";
    $field.=$field1;
    $c++;
  }
  # put SQL part together
  my $sql=$self->SQL_SELECT.$field.
          $self->SQL_FROM.$table;
  return ($sql,$keypos);
}






# get all field names in an pointer to an array
#
sub _selectComposeFields {
  my $self = shift;
  my ($pfields,$table) = @_;
  my (@fields);
  if (ref($pfields) ne "ARRAY") { # no array, check for all/some fields
    my $field=$pfields;
    my $max = -1; # does mean, we want to have all fields
    my $f1 = int $field; 
    # comp int with text, if it is the same, we have a number (x fields)
    $max = $f1 if ($f1 eq $field && $f1>=0);
    # get all fields with '*' or if we give nothing (empty string)
    $max = $self->SQL_MAX_FIELDS if $field eq $self->SQL_ALL || $field eq '';
    $pfields = []; # remove the old values
    if ($max>=0) {
      # we have unnamed fields or want to get ALL fields
      my $c=0;
      foreach ($self->_fields($table)) {
        # extract the desired field name and store it
        push @fields,$_->name;
        last if $c>=$max;
        $c++;
      }
    } else {
      @fields = ($field); # we have only ONE NAMED field
    }
  } else {
    @fields = @$pfields; # we already have an array, give it back
  }
  my $keypos; # the postion of the keyfield in the field list
  if ($self->sqllimit ne "") {
    # if we ask for more then one record, check if the keyfield is included
    # if the keyfield is not included, add the field at the end (gives back one
    # row more)
    $keypos=-1;
    my $c;
    for($c=0;$c<@fields;$c++) {
      $keypos=$c if $fields[$c] eq $self->keyfield;
    }
    if ($keypos==-1) { # if not founded, add the row
      $keypos=$c;
      push @fields,$self->keyfield;
    }
  }
  return (\@fields,$keypos);
}






# check for date fields in a row and give back the date string
# according the language given by the class
#
sub _selectCheckForValues {
  my $self = shift;
  my ($prow,$pdates,$pyes) = @_;
  return if $self->langcode eq $self->LANGUAGE_SQL;
  my $c1=0;
  foreach (@$prow) {
    if ($$pdates[$c1] ne '') {
      my ($date,$rest) = split(" ", $$prow[$c1]);
      my ($y,$m,$d) = split("-",$date);
      if ($y>=0 && $m>=0 && $d>=0) {
        if ($self->langcode eq $self->LANGUAGE_ENGLISH) {
          $$prow[$c1]=$m.'/'.$d.'/'.$y;
        } elsif ($self->langcode eq $self->LANGUAGE_GERMAN) {
          $$prow[$c1]=$d.'.'.$m.'.'.$y;
        }
      }
    }
    if ($$pyes[$c1] ne '') {
      my $val = $$prow[$c1];
      my $yes;
      $yes=1 if $val==1;
      if ($self->langcode eq $self->LANGUAGE_ENGLISH) {
        if ($val==1) {
          $$prow[$c1]='Yes';
        } else {
          $$prow[$c1]='No';
        }
      } elsif ($self->langcode eq $self->LANGUAGE_GERMAN) {
        if ($val==1) {
          $$prow[$c1]='Ja';
        } else {
          $$prow[$c1]='Nein';
        }
      }
    }
    $c1++;
  }
}






=head1 @vals=search($pFields,$pVals,[$table])

Activate a record in the $table. If there is no $table,
we just use the default table.

$pFields and $pVals can be SCALAR or ARRAY typed (one or more fields)

=head2 Format for activation of a record (with two SCALARS): 

$cl->search('!'.$cl->FLD_PAGES,30) gives first record with NOT 30 pages

=head2 Format for activation of a record (with two ARRAYS):

$cl->search('*',[$c->FLD_PAGES.'+',$cl->FLD_TYPE.'-',SQL_OR],[30,1,2]) 
gives back the first record where we have 30 pages and type is 1 or 2, the
sorting order is done by FLD_PAGES (ascending) and FLD_TYPE (descending)

=head2 Format with OR values

$c->search($c->FLD_DOC,[$c->FLD_DOC,$c->SQL_OR,$c->SQL_OR],[1,40,20]) 
gives back the FLD_DOC number if 1 or 40 or 20 is available.

=head2 Some special notes for accessing fields:

Every pFields condition has from ONE to THREE parts. You can use:

first part: !,<,>,=,~ (LIKE) condition to search (default: nothing=equal)

second part: field name

thired part: sorting order +/- (ascending, descending or none)

=head2 Some notes about the values you pass to the class:

You don't need to quote strings (vals) and can use normal
DATEs (i.e. 20040821) as language specific (English,German) ones 
(i.e. 13.2.2006). If you pass an ' ' empty char, the current date
will be added.

=cut

sub search {
  my $self = shift;
  my ($pfields,$pvals,$table) = @_;
  return $self->_search($pfields,$pvals,$table);
}






# internal function (also needed from add record)
#
sub _search {
  my $self = shift;
  my ($pfields,$pvals,$table) = @_;
  my $sql=$self->_composeSQL($pfields,$pvals,\$table);
  if ($sql) {
    $sql.=$self->SQL_LIMIT1;
    my @row=$self->_getRow($sql); # retrieve the record
    if (defined $row[0]) {
      # we could find a record, so activate the record
      $self->keyvalue($row[0]);
    } else {
      $self->keyvalue(0); # nothing found
    }
  }
  return $self->keyvalue;
}






=head1 $record=add($pfields,$pvals,[$table]) 

Add a record with $pfields and $pvals, gives back record number

=cut

sub add {
  my $self = shift;
  my ($pfields,$pvals,$table) = @_;
  my ($done,$sql,$sql1,$ret);
  $self->_checkTable(\$table);
  $sql1=$self->_updateSQL($pfields,$pvals,$table);
  if ($sql1) {
    $sql=$self->SQL_INSERT.$table.$self->SQL_SET.$sql1;
  } else {
    $sql=$self->SQL_INSERT.$table.$self->SQL_INSERT_EMPTY;
  }
  $done = $self->_setRows($sql);
  if ($done) {
    $sql=$self->SQL_INSERT_LAST;
    my @row=$self->_getRow($sql);
    $ret=$row[0];
    $self->keyvalue($row[0]);
  }
  return $ret;
}






=head1 $anz=update($pfields,$pvals,$condField,$condValue,[$table]) 

Set $pvals to $pfields in $table accroding $condField and $condValue

=cut

sub update {
  my $self = shift;
  my ($pfields,$pvals,$condField,$condValue,$table) = @_;
  my ($done,$sql1,@fields,@vals);

  my $val=$self->_initFields($condField,$condValue,\$table);
  if ($val) {
    $sql1=$self->_updateSQL($pfields,$pvals,$table);
    my $sql=$self->SQL_UPDATE.$table.$self->SQL_SET.$sql1.$self->SQL_WHERE.$val;
    $done = $self->_setRows($sql);
  }
  return $done;
}






# calculate sql part that does update/insert
#
sub _updateSQL {
  my $self = shift;
  my ($pfields,$pvals,$table) = @_;
  my ($c,$sql1,@fields,@vals);
  $self->errorfields([]) if $self->errorfieldstate==0;
  ($pfields,$pvals)=$self->_initFieldsVals($pfields,$pvals);
  @fields=@$pfields;
  @vals=@$pvals;
  foreach (@fields) {
    my $field=$_;
    my $value=$vals[$c];
    my ($name,$type,$lang,$quote)=$self->_field($field,$table);
    if ($name eq $field) {
      if ($quote) { # we have a string field
        $value = $self->_quote($value);  
      } elsif ($type eq $self->DATE) { # we have a date field
        $value = $self->_quoteDate($value);
      } elsif ($type eq $self->YESNO) {
        $value = $self->_quoteYesNo($value);
      }
      $sql1.="," if $sql1 ne "";
      $sql1.=$field."=".$value;
    } else {
      push @{$self->errorfields},$field;  
    }
    $c++;
  }
  return $sql1;
}






=head1 $deleted=delete($condField,$condValue,[$table])

Delete ONE record from $table matching $condField with $condValue. If
$table is not available, we use the current values.

=cut

sub delete {
  my $self = shift;
  my ($condField,$condValue,$table) = @_;
  my ($done);
  my $val=$self->_initFields($condField,$condValue,\$table);
  if ($val) {
    my $sql=$self->SQL_DELETE.$table.$self->SQL_WHERE.$val.$self->SQL_LIMIT1;
    $done = $self->_setRows($sql);
  }
  return $done;
}





=head1 $deleted=deleteAll($table)

Delete ALL records of a table, but keep the table structure.

=cut

sub deleteAll {
  my $self = shift;
  my ($table) = @_;
  my ($done);
  my $sql=$self->SQL_DELETE.$table;
  $done = $self->_setRows($sql);
  return $done
}






=head1 $rec=key([$key,$table])

Activate record with $key in $table or gives back just key (without key)

=cut

sub key {
  my $self = shift;
  my ($key,$table) = @_;
  return $self->keyvalue if !defined $key;
  my ($sql,$field,$record);
  $self->_checkTable(\$table); # initiate the table/db/field
  $field=$self->keyfield;
  if ($field) {
    my ($name,$type,$lang,$quote) = $self->_field($field);
    if ($name eq $field) { # field is available
      if ($quote) { # we have a string field
        $key = $self->_quote($key);         # there is NO between
      } elsif ($type eq self->DATE) { # we have a date field
        $key = $self->_quoteDate($key);
      }
      $sql=$field."=".$key;
    }
  }
  if ($sql) {
    $sql=$self->SQL_SELECT.$field.$self->SQL_FROM.$table.$self->SQL_WHERE.$sql;
    my @row=$self->_getRow($sql);
    if (defined $row[0]) {
      $record = $row[0];
      $self->keyvalue($record);
    }
  }
  return $record;
}






=head1 @keys=keys($pfields,$pvals,[$table])

Gives back all keys in an array  from a range of records. Please
have a look at search about the format to use.

=cut

sub keys {
  my $self = shift;
  my ($pfields,$pvals,$table) = @_;
  my (@keys);
  my $sql=$self->_composeSQL($pfields,$pvals,\$table);
  if ($sql) {
    if ($self->sqllimit ne "") {
      $sql.=$self->SQL_LIMIT.$self->sqllimit;
      $self->sqllimit="";
    }
    my $prows = $self->_getRows($sql);
    foreach (@$prows) {
      my @row = @$_;
      push @keys,$row[0];
    }
  }
  return @keys;
}






# internal function for getKeys and getReocrd, does compose
# the needed sql string WITHOUT limit factor
# 
sub _composeSQL {
  my $self = shift;
  my ($pfields,$pvals,$ptable) = @_;
  my (@fields,@vals,@sql,@order,@ors,$c,$oron,$sql,$comp,$order);
  ($pfields,$pvals)=$self->_initFieldsVals($pfields,$pvals);
  @fields=@$pfields;
  @vals=@$pvals;
  $self->_checkTable($ptable); # initiate the table/field
  foreach (@fields) { # process all fields
    my $field = $_;
    $ors[$c]=0;
    if ($field eq $self->SQL_OR && $c>0) { # check if we have OR instead of AND
      $field = $fields[$c-1];
      $fields[$c]=$field;
      $ors[$c]=1;
    }
    # ('>Titel+','Titel+','=Titel','~Titel+','!Titel-') 
    # split into select part (>,<,=,~,!), field (Titel) and order (+,-)
    my ($comp0,$field1,$order0) = $field=~/^([\>|\<|=|~|!]*)(.*?)([\+|-]*)$/;
    $field=$field1 if $field1 ne "";
    my $value = $vals[$c];
    if ($field eq "") {
      # in case we don't have a field, we just use the pointers
      $field=$self->keyfield;
      $value=$self->keyvalue;
    }
    $c++;
    
    if ($order0 eq "+" || $order0 eq "-") {
      $order = $field;
      $order .= $self->SQL_DESC if ($order0 eq "-");
      push @order,$order;
    }
    
    my $value1=$value;
    $value1 =~ s/^(-)/=/;
    $value1 =~ s/-{2,2}/=/;
    my ($val1,$val2) = split('-',$value1);
    $val1 =~ s/=/-/;
    $val2 =~ s/=/-/;
    
    if ($comp0 eq "=") {
      $comp = "=";
    } elsif ($comp0 eq "!") {
      $comp = '!=';
    } elsif ($comp0 eq "<") {
      $comp = "<";
    } elsif ($comp0 eq ">") {
      $comp = ">";
    } elsif ($comp0 eq "~") {
      $comp = $self->SQL_LIKE;
    } else {
      $comp0="";
    }
    $comp="=" if $comp0 eq "";
    
    my ($name,$type,$lang,$quote) = $self->_field($field,$$ptable);
    if ($name eq $field) { # field is available
      if (not defined($value)) {
        $sql=$field.$self->SQL_ISNULL;
      } else {
        if ($quote) { # we have a string field
          $val1 = $self->_quote($value);         # there is NO between
          $val2 = "";
        } elsif ($type eq $self->YESNO) { # we have a yesno field
          $val1 = $self->_quoteYesNo($value);
          $val2 = "";
        } elsif ($type eq $self->DATE) { # we have a date field
          $val1 = $self->_quoteDate($val1);
          $val2 = $self->_quoteDate($val2);
        }
    
        $sql=""; # handle the SQL_BETWEEN CASE
        if ($val2 ne "") {
          $sql=$field.$self->SQL_BETWEEN.$val1.$self->SQL_AND.$val2;
        } else {
          $sql=$field.$comp.$val1;
        }
      }
      push @sql,$sql;
    }
  }
  return $self->_composeSQLString(\@sql,\@ors,\@order,$ptable);
}






# put the sql string together and give it back as a string
sub _composeSQLString {
  my $self = shift;
  my ($psql,$pors,$porder,$ptable) = @_;
  my $sql=""; # put the SQL string together
  my $c=0;
  my $orstarted=0;
  foreach(@$psql) {
    my $sqlpart = $_;
    if ($$pors[$c+1]==1 && $$pors[$c]==0 && $orstarted==0) {
      $sql.=$self->SQL_AND if $c>0;
      $sql.='(';
      $orstarted=1;
    }
    if ($c>0 && $$pors[$c]==1) {
      $sql.=$self->SQL_OR;
    } else {
      $sql.=$self->SQL_AND if $sql ne "" && $orstarted==0;
    }
    $sql.=$sqlpart;
    $c++;
    if ($$pors[$c]==0 && $orstarted==1) {
      $orstarted=0;
      $sql.=')';
    }
  }

  if ($self->searchmode ne $self->SEARCH_REC) {
    my $k=$self->searchfield;
    $k=$self->keyfield if $k eq "";
    $sql = $self->SQL_SELECT.$self->searchmode."($k)".
           $self->SQL_FROM.$$ptable.$self->SQL_WHERE.$sql;
  } else {
    if ($self->sqllimit eq "") { 
      # we want the full sql query (not only the where part)
      my $k=$self->keyfield;
      $sql = $self->SQL_SELECT.$k.$self->SQL_FROM.$$ptable.$self->SQL_WHERE.$sql;
    }
    my $sql1; # add the order by part
    for (my $c=0;$c<@$porder;$c++) {
      $sql1.= "," if $sql1 ne "";
      $sql1.= $self->SQL_ORDER if $sql1 eq "";
      my $order2=$$porder[$c];
      $sql1.= $$porder[$c];
      while ($$porder[$c] eq $$porder[$c+1]) {
        $c++;
      }
    }
    $sql.=$sql1;
  }
  return $sql;
}






=head1 limit([$records,[$start]])

Set a limit factor for NEXT keys/select method call

=cut

sub limit {
  my $self = shift;
  my ($records,$start) = @_;
  $records = int $records;
  $start = int $start;
  my ($sqlrecords,$sqlstart);
  $sqlrecords=16;
  $sqlstart=0;
  $sqlrecords=$records if $records>0;
  $sqlstart=$start if $start>0;
  $self->sqllimit("$sqlstart,$sqlrecords");
  return $sqlrecords;
}






# does the check if we got an ARRAY or just a SCALAR
#
sub _initFieldsVals {
  my $self = shift;
  my ($pfields,$pvals) = @_;
  my ($pfieldsnew,$pvalsnew);
  if (ref($pfields) eq "ARRAY") {
    $pfieldsnew=$pfields;
    $pvalsnew=$pvals;
  } else {
    $$pfieldsnew[0] = $pfields;
    $$pvalsnew[0] = $pvals;
  }
  return ($pfieldsnew,$pvalsnew);
}






=head1 @flds=getErrorFields

Give back an array with all fields that were not processed

=cut

sub getErrorFields {
  my $self = shift;
  return @{$self->errorfields};
}






=head1 $countrec=count($pfields,$pvals,[$table])

Gives back the number of records from a range of records.

=cut

sub count {
  my $self = shift;
  my ($pfields,$pvals,$table) = @_;
  return $self->_searchOne($self->SEARCH_COUNT,"",$pfields,$pvals,$table);
}







=head1 $minvalue=min($testfield,$pfields,$pvals,[$table])

Gives back the minimal value from a range of records.

=cut

sub min {
  my $self = shift;
  my ($search,$pfields,$pvals,$table) = @_;
  return $self->_searchOne($self->SEARCH_MIN,$search,$pfields,$pvals,$table);
}







=head1 $maxvalue=max($testfield,$pfields,$pvals,[$table])

Gives back the maximal value from a range of records.

=cut

sub max {
  my $self = shift;
  my ($search,$pfields,$pvals,$table) = @_;
  return $self->_searchOne(SEARCH_MAX,$search,$pfields,$pvals,$table);
}






=head1 $sumvalue=sum($testfield,$pfields,$pvals,[$table])

Gives back the sum value from a range of records.

=cut

sub sum {
  my $self = shift;
  my ($search,$pfields,$pvals,$table) = @_;
  return $self->_searchOne($self->SEARCH_SUM,$search,$pfields,$pvals,$table);
}






# special search mode (count,min,max,sum) 
#
sub _searchOne {
  my $self = shift;
  my ($mode,$searchfield,$pfields,$pvals,$table) = @_;
  my (@row);
  $self->searchmode($mode);
  $self->searchfield($searchfield);
  my $sql=$self->_composeSQL($pfields,$pvals,\$table);
  $self->searchmode($self->SEARCH_REC);
  $self->searchfield("");
  if ($sql) {
    @row = $self->_getRow($sql);
  }
  return $row[0];
}






=head1 ($name,$type,$size)=field($field,[$table])

Give back the field structure of a $field in $table

=cut

sub field {
  my $self = shift;
  my ($field,$table) = @_;
  return $self->_field($field,$table);
}






# internal function to get one field information (name,type,size)
#
sub _field {
  my $self = shift;
  my ($field,$table) = @_;
  my ($name,$type,$lang,$quote);
  $table=$self->table if !$table;
  return [] if $table eq '';
  for (my $c=0;$c<=$count;$c++) {
    if ($tables[$c] eq $table) {
      foreach (@{$rec[$c]}) {
        if ($_->name eq $field) {
          $name = $_->name;
          $type = $_->type;
          $lang = $_->size;
          $quote = $_->quote;
          last;
        }
      }
      last;
    }
  }
  return ($name,$type,$lang,$quote);
}






=head1 $@fields=fields($table)

Gets back in a pointer of an array a hash 
containing all name, type und sizes of an mysql table

=cut

sub fields {
  my $self = shift;
  my ($table) = @_;
  return $self->_fields($table);
}






# internal function to get the fields
#
sub _fields {
  my $self = shift;
  my ($table) = @_;
  my (@flds,$ok);
  $table=$self->table if !$table;
  if ($table eq $self->table && $table ne "") {
    $ok=1;
    @flds = @{$self->rec};
  } else {
    for (my $c=0;$c<=$count;$c++) {
      if ($tables[$c] eq $table) {
        $ok=1;
        @flds = @{$rec[$c]};
        last;
      }
    }
  }
  if ($ok==0) {
    if ($self->setTable($table)) {
      @flds = @{$self->rec};
    }
  }
  return @flds;
}






=head1 $name=fieldname($pos,[$table])

Gives back the field name from a given position

=cut

sub fieldname {
  my $self = shift;
  my ($pos,$table) = @_;
  my @flds=$self->_fields($table);
  my $name;
  $name=$flds[$pos]->name if $pos<=#$flds;
  return $name;
}






=head1 @fieldnames=fieldnames([$table])

Gives back in an array all field names

=cut

sub fieldnames {
  my $self = shift;
  my ($table) = @_;
  my @flds = $self->_fields($table);
  my @fields;
  foreach(@flds) {
    push @fields,$_->name;
  }
  return @fields;
}






=head1 $pos=fieldpos($name,[$table])

Gives back the name of the field at position $pos (if not found -1)

=cut

sub fieldpos {
  my $self = shift;
  my ($field,$table) = @_;
  my @flds = $self->_fields($table);
  my $pos=0;
  my $found=-1;
  foreach(@flds) {
    if ($_->name eq $field) {
      $found=$pos;
      last;
    }
    $pos++;
  }
  return $found;
}






# we use this internal function to activate the current
# record in the keyfield in case we have the optional values
# to use (internally search method is used to do the job)
#
sub _initFields {
  my $self = shift;
  my ($condField,$condValue,$ptable) = @_;
  my $val;
  $self->_checkTable($ptable);
  if (defined($condField) && defined($condValue)) {
    $self->_search($condField,$condValue,$$ptable);
  }
  $condField=$self->keyfield;
  $condValue=$self->keyvalue;
  my ($name,$type,$lang,$quote)=$self->_field($condField,$$ptable);
  if ($name eq $condField) {
    $condValue=$self->_quote($condValue) if $quote;
    $val=$condField."=".$condValue;
  }
  return $val;
}






# check if we have a given table and dbh, if not use defaults
sub _checkTable {
  my $self = shift;
  my ($ptable) = @_;

  if (!$$ptable) {
    $$ptable=$self->getTable;
    $self->_initDBValues if !$$ptable;
    $$ptable=$self->table;
  } else {
    $self->setTable($$ptable);
  }
}






# internal method to set back default start values
sub _initDBValues {
  my $self = shift;
  $self->table($self->TABLE_DEFAULT);
  $self->keyfield($self->FLD_DEFAULT);
  $self->keyvalue(0);
}






# internal method to retrieve a record in a row
#
sub _getRow {
  my $self = shift;
  my ($sql) = @_;
  my @row;
  $self->errornr(0);
  if ($self->dbh) {
    @row=$self->dbh->selectrow_array($sql);
    $self->errornr($self->dbh->err) if $self->dbh->err;
  }
  $self->_checkRowLog($sql,\@row,$self->dbh);
  return @row;
}






# internal method to retrieve records
#
sub _getRows {
  my $self = shift;
  my ($sql) = @_;
  my $prows;
  $self->errornr(0);
  if ($self->dbh) {
    $prows = $self->dbh->selectall_arrayref($sql);
    $self->errornr($self->dbh->err) if $self->dbh->err;
  }
  $self->_checkRowLog($sql,$prows,$self->dbh);
  return $prows;
}






# interlal method to update records
#
sub _setRows {
  my $self = shift;
  my ($sql) = @_;
  my ($done);
  $self->errornr(0);
  $self->errorfieldstate(0);
  if ($self->isHostSlave==0) {
    if ($self->dbh) {
      $done = $self->dbh->do($sql);
      $self->errornr($self->dbh->err) if $self->dbh->err;
      $self->_checkRowLog(\$sql,$done,$self->dbh);
    }
  } else {
    $self->errornr(-9999);
  }
  return $done;
}







# Gives back a quoted $value
#
sub _quote {
  my $self = shift;
  my ($value) = @_;
  if ($self->dbh) {
    return $self->dbh->quote($value);
  } else {
    return $value;
  }
}






# $val=_quoteYesNo($val) 
# Formats a yes/no field
#
sub _quoteYesNo {
  my $self = shift;
  my ($val) = @_;
  my $v = lc($val);
  $val=0;
  $val=1 if ($v eq 'yes' || $v eq 'y' || $v eq 'ja' || $v eq 'j' || $v eq '1');
  return $val;
}






# $dateSQL=_quoteDate($value) 
# Formats an unformated date string in an SQL date string
#
sub _quoteDate {
  my $self = shift;
  my ($value) = @_;
  return $self->_quote($value) if length($value)==19; # Date already formated
  if ($value eq " ") {
    # date from today
    $value = $self->_quoteDateNow;
  } else {
    my ($d,$m,$y) = split(/\./,$value); # german notation
    if ($m eq "") {
      ($m,$d,$y) = split(/\//,$value); # english notation
      if ($d eq "") {
        if (length($value)==6) { # simple 060124 notation
          $y = substr($value,0,2);
          $m = substr($value,2,2);
          $d = substr($value,4,2);
        } elsif (length($value)==8) { # simple 20060124 notation
          $y = substr($value,0,4);
          $m = substr($value,4,2);
          $d = substr($value,6,2);
        } else { # incorrect date
          $d="";
          $m="";
        }
      }
    }
    if ($d ne "" && $m ne "" && $y eq "") {
      my @t = localtime( time() ); # year is not available
      my ( $stamp, $y, $m, $d, $h, $mi, $s );
      $y = $t[5] + 1900;
    }

    if (length($y)==2) { # we nead a four digit year
      if ($y<70) { 
        $y=$y+2000;
      } else {
        $y=$y+1900;
      }
    }
    
    $d = sprintf("%02d",$d); # reformat for correct length
    $m = sprintf("%02d",$m);
    $y = sprintf("%04d",$y);

    if (length($d)==2 && length($m)==2 && length($y)==4) {
      $value = "'$y-$m-$d 00:00:00'";
    } else {
      $value=""; # kill date because format is not ok
    }
  }
  return $value;
}






# $stamp=_quoteDateNow
# Actual date as SQL string (2004-03-23 00:00:00)
#
sub _quoteDateNow {
  my $self = shift;
  my @t = localtime( time() );
  my ( $stamp, $y, $m, $d, $h, $mi, $s );
  $y = $t[5] + 1900;
  $m = $t[4] + 1;
  $m = sprintf( "%02d", $m );
  $d = sprintf( "%02d", $t[3] );
  $stamp = $y . "-" . $m . "-" . $d . " 00:00:00";
  return $stamp;
}









# _checkQuoted($type)
# Give back a 1 if we need to quote the field
#
sub _checkQuoted {
  my $self = shift;
  my ($type) = @_;
  my $quote=0;
  if ($type eq $self->CHAR || $type eq $self->BLOB || $type eq $self->TEXT ||
      $type eq $self->MEDIUMBLOB || $type eq $self->LONGBLOB || 
      $type eq $self->MEDIUMTEXT || $type eq $self->LONGTEXT || 
      $type eq $self->CHARFIX) {
    $quote=1;
  }
  return $quote;
}






# check if we want to print out a sql log message
#
sub _checkRowLog {
  my $self = shift;
  my ($sql,$prow,$dbh) = @_;
  my $out;
  if ($self->loglevel>0) {
    my $prow1 = $prow;
    $self->_checkRowLogOne(\$out,$prow1);
    $out="SQL: $dbh--$sql--$out";
    $self->logMessage($out);
  }
}






# check if a single string has more then 200 chars, if yes only
# store first and last 100 chars to the log file
#
sub _checkRowLogOne {
  my $self = shift;
  my ($pout,$part) = @_;
  my $r=ref($part);
  if ($r eq "REF") {
    if (ref($$part) eq "ARRAY") {
      my @a = @{$$part};
      $self->_checkRowLogOne($pout,\@a);
    } else {
      $$pout.=$$part;
    }
  } elsif ($r eq "ARRAY") {
    foreach (@{$part}) {
      $self->_checkRowLogOne($pout,\$_);
    }
  } elsif ($r eq "SCALAR") {
     $self->_checkRowLogOne($pout,$$part);
  } else {
    $$pout.="--" if $$pout ne "";
    if (length($part)>200) {
      $$pout.=substr($part,0,100)."..".substr($part,-1,100);
    } else {
      $$pout.=$part;
    }  
  }
}






=head1 setTable($table)

Activate $table and gives back the table name

=cut

sub setTable {
  my $self = shift;
  my ($table) = @_;
  return if $table eq $self->getTable;
  my ($ok);
  my @tablesdb=$self->getTables;
  foreach (@tablesdb) {
    if ($table eq $_) {
      $self->table($table);
      for (my $c=0;$c<=$count;$c++) {
        if ($tables[$c] eq $table) {
          $ok=1;
          $self->rec($rec[$c]);
           $self->table($tables[$c]);
          $self->keyfield($keyfield[$c]);
          $self->keyvalue(0);
          last;
        }
      }
      if ($ok==0) {
        my $sql = $self->SQL_DESCRIBE.$table;
        my $prows = $self->_getRows($sql);
        my $pos=0;
        my @flds;
				my $first="";
        foreach (@$prows) {
          my @row = @$_;
          my $name = $row[0];
					$first=$name if $first eq "";
          my ($type,$lang) = $row[1] =~ /(.*)\((.*)\)/; # extract type(lang)
					$lang = 0 if $type ne CHAR && $type ne CHARFIX;
          $type=$row[1] if ($type eq ""); # some fields only have type
          my $quote=$self->_checkQuoted($type);
          $type=$self->KEY if ($row[3] eq $self->KEY);
          if ($name ne '') {
            $flds[$pos]=AVField->new($name,$type,$lang,$quote);
            $pos++;
          }
        }
        $self->rec(\@flds);
        $self->keyfield("");
        $self->keyvalue(0);
        foreach (@{$self->rec}) {
          if ($_->type eq $self->KEY) {
            $self->keyfield($_->name);
            $self->keyvalue(0);
            $ok=1;
            last;
          }
        }
				if ($self->keyfield eq "" && $first ne "") {
				  $self->keyfield($first);
					$ok=1;
				}
        $count++;
        $rec[$count]=$self->rec;
        $tables[$count]=$self->table;
        $keyfield[$count]=$self->keyfield;
      }
      last;
    }
  }
  $table="" if $ok==0;
  return $table;
}






=head1 $table=getTable

Gives back the current table

=cut

sub getTable {
  my $self = shift;
  return $self->table;
}






=head1 @tables=getTables

Gives back an array with all table names

=cut

sub getTables {
  my $self = shift;
  my @tables;
  my $prows=$self->_getRows($self->SQL_SHOWTABLES);
  foreach (@$prows) {
    my @row = @$_;
    push @tables,$row[0];
  }
  return @tables;
}






=head1 $anz=setDatabase($db)

Select another database as the default db

=cut

sub setDatabase {
  my $self = shift;
  my ($db) = @_;
  my $dbok;
  my @db=$self->getDatabases;
  foreach (@db) {
    if ($db eq $_) { # the database does exist
      $self->dbh->disconnect;
      $self->table(''); # unset all old values
			my $table=$self->TABLE_DEFAULT;
      $self->_checkTable(\$table);
      $self->dbDatabase("");
      $self->dbh($self->_connectDB($self->dbHost,$db,
                                 $self->dbUser,$self->dbPassword));
      if ($self->dbh) {
        $dbok=$db;
        $self->dbDatabase($db);
        $self->_initDBValues;
      }
      last;
    }
  }
  return $dbok;
}






=head1 $db=getDatabase

Gives back the current database name

=cut

sub getDatabase {
  my $self = shift;
  return $self->dbDatabase;
}






=head1 $pav=getDatabases

Gives back an array with all databases

=cut

sub getDatabases {
  my $self = shift;
  my (@av,$pdbs);
  $pdbs = $self->_getRows($self->SQL_SHOWDATABASES);
  foreach (@$pdbs) {
    my $db = $$_[0];
    push @av,$db;
  }
  return @av;
}






=head1 $host=getHost

Gives back the current host

=cut

sub getHost {
  my $self = shift;
  return $self->dbHost;
}






=head1 $user=getUser

Gives back the current user

=cut

sub getUser {
  my $self = shift;
  return $self->dbUser;
}






=head1 $pw=getPassword

Gives back the current password

=cut

sub getPassword {
  my $self = shift;
  return $self->dbPassword;
}






=head1 $ok=isHostSlave

Gives back a 1 if we are in slave mode

=cut

sub isHostSlave {
  my $self = shift;
  my $hostIsSlave = 0;
  my @row=$self->_getRow($self->SQL_SLAVE);
  $hostIsSlave = 1 if ($row[9] eq 'Yes');
	if ($hostIsSlave==0) {
    @row=$self->_getRow($self->SQL_SLAVE2);
		$hostIsSlave=1 if $row[1]>1;
	}
  return $hostIsSlave;
}






=head1 $ok=isAlive

Check if the dbh connection is alive (1=yes,0=no)

=cut

sub isAlive {
  my $self = shift;
  my ($error);
  $self->errornr=0;
  if ($self->dbh) {
    my @row=$self->_getRow($self->SQL_TEST);
    $error=$self->dbh->err;
    if ($error) {
      $self->logMessage("no db connection: $error");
      $error=0;
      sleep $self->waitsleep;
      $self->dbh=_connectDB($self->dbHost,$self->dbDatabase,
                           $self->dbUser,$self->dbPassword);
      $error=-20 if !$self->dbh;
    }
  } else {
    $self->logMessage("db connection not ok");
    sleep $self->waitsleep;
    $self->dbh=_connectDB($self->dbHost,$self->dbDatabase,
                         $self->dbUser,$self->dbPassword);
    $error=-10 if !$self->dbh;
  }
  if ($error) {
    $self->errornr=$error;
     $self->dbState=0;
  } else {
    $self->dbState=1;
  }
  return $self->dbState;
}






=head1 $errnr=isError

Give back the last reported error from the class (mainly errors from database)

=cut

sub isError {
  my $self = shift;
  return $self->errornr;
}






=head1 $lang=language([$lang]) 

Tries to set a language code, possible values are: 
LANGUAGE_SQL,LANGUAGE_ENGLISH,LANGUAGE_GERMAN. 
Finally (without or with $lang) it gives back the
current enable language code

=cut

sub language {
  my $self = shift;
  my ($lang) = @_;
  if ($lang eq $self->LANGUAGE_GERMAN) {
    $self->langcode($self->LANGUAGE_GERMAN);
  } elsif ($lang eq $self->LANGUAGE_ENGLISH) {
    $self->langcode($self->LANGUAGE_ENGLISH);
  } elsif ($lang eq $self->LANGUAGE_SQL) {
    $self->langcode($self->LANGUAGE_SQL);
  }
  return $self->langcode;
}







=head1 Class wide constants for AVDB.pm

CHAR
TIMESTAMP
YESNO
INT
BLOB
TEXT
MEDIUMBLOB
LONGBLOB
DATE
KEY
SQL_OR

LANGUAGE_SQL (default)
LANGUAGE_GERMAN
LANGUAGE_ENGLISH

=cut










#
# has to be
1;



