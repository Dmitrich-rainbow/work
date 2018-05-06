How to connect to MS SQL Server database

	


Below is the code for connecting to a MSSQL Server database.

<?php
$myServer = "localhost";
$myUser = "your_name";
$myPass = "your_password";
$myDB = "examples"; 

//connection to the database
$dbhandle = mssql_connect($myServer, $myUser, $myPass)
  or die("Couldn't connect to SQL Server on $myServer"); 

//select a database to work with
$selected = mssql_select_db($myDB, $dbhandle)
  or die("Couldn't open database $myDB"); 

//declare the SQL statement that will query the database
$query = "SELECT id, name, year ";
$query .= "FROM cars ";
$query .= "WHERE name='BMW'"; 

//execute the SQL query and return records
$result = mssql_query($query);

$numRows = mssql_num_rows($result); 
echo "<h1>" . $numRows . " Row" . ($numRows == 1 ? "" : "s") . " Returned </h1>"; 

//display the results 
while($row = mssql_fetch_array($result))
{
  echo "<li>" . $row["id"] . $row["name"] . $row["year"] . "</li>";
}
//close the connection
mssql_close($dbhandle);
?>







Connect with a DSN

DSN stands for 'Data Source Name'. It is an easy way to assign useful and easily rememberable names to data sources which may not be limited to databases alone. If you do not know how to set up a system DSN read our tutorial How to set up a system DSN.

In the example below we will show you how to connect with a DSN to a MSSQL Server database called 'examples.mdb'  and retrieve all the records from the table 'cars'.

<?php 

//connect to a DSN "myDSN" 
$conn = odbc_connect('myDSN','',''); 

if ($conn) 
{ 
  //the SQL statement that will query the database 
  $query = "select * from cars"; 
  //perform the query 
  $result=odbc_exec($conn, $query); 

  echo "<table border=\"1\"><tr>"; 

  //print field name 
  $colName = odbc_num_fields($result); 
  for ($j=1; $j<= $colName; $j++) 
  {  
    echo "<th>"; 
    echo odbc_field_name ($result, $j ); 
    echo "</th>"; 
  } 

  //fetch tha data from the database 
  while(odbc_fetch_row($result)) 
  { 
    echo "<tr>"; 
    for($i=1;$i<=odbc_num_fields($result);$i++) 
    { 
      echo "<td>"; 
      echo odbc_result($result,$i); 
      echo "</td>"; 
    } 
    echo "</tr>"; 
  } 

  echo "</td> </tr>"; 
  echo "</table >"; 

  //close the connection 
  odbc_close ($conn); 
} 
else echo "odbc not connected"; 
?>







Connect without a DSN (using a connection string)

Let see a sample script to see how ADODB is used in PHP:

<?php
$myServer = "localhost";
$myUser = "your_name";
$myPass = "your_password";
$myDB = "examples"; 

//create an instance of the  ADO connection object
$conn = new COM ("ADODB.Connection")
  or die("Cannot start ADO");

//define connection string, specify database driver
$connStr = "PROVIDER=SQLOLEDB;SERVER=".$myServer.";UID=".$myUser.";PWD=".$myPass.";DATABASE=".$myDB; 
  $conn->open($connStr); //Open the connection to the database

//declare the SQL statement that will query the database
$query = "SELECT * FROM cars";

//execute the SQL statement and return records
$rs = $conn->execute($query);

$num_columns = $rs->Fields->Count();
echo $num_columns . "<br>";  

for ($i=0; $i < $num_columns; $i++) {
    $fld[$i] = $rs->Fields($i);
}

echo "<table>";
while (!$rs->EOF)  //carry on looping through while there are records
{
    echo "<tr>";
    for ($i=0; $i < $num_columns; $i++) {
        echo "<td>" . $fld[$i]->value . "</td>";
    }
    echo "</tr>";
    $rs->MoveNext(); //move on to the next record
}


echo "</table>";

//close the connection and recordset objects freeing up resources 
$rs->Close();
$conn->Close();

$rs = null;
$conn = null;
?>





To create 'examples' database on your MSSQL Server you should run the following script:

CREATE DATABASE examples;
USE examples;
CREATE TABLE cars(
   id int UNIQUE NOT NULL,
   name varchar(40),
   year varchar(50),
   PRIMARY KEY(id)
);

INSERT INTO cars VALUES(1,'Mercedes','2000');
INSERT INTO cars VALUES(2,'BMW','2004');
INSERT INTO cars VALUES(3,'Audi','2001');