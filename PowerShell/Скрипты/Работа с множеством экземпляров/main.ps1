$myvar  = Get-Content C:\distr\ps\other.txt
$myvar1 = $myvar.split(" ")
for($i = 0;$myvar1.Count -gt $i; $i++)
{
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$SqlConnection.ConnectionString = "Server = "+$myvar1[$i]+"; Database = master; Integrated Security = True;"
	$SqlQuery = "SELECT @@VERSION"
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand

	$SqlCmd.CommandText = $SqlQuery
	$SqlCmd.Connection = $SqlConnection
	$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
	$SqlAdapter.SelectCommand = $SqlCmd
	$DataSet = New-Object System.Data.DataSet
	$SqlAdapter.Fill($DataSet)
	echo $DataSet.Tables | Format-Table name,db_size
}

sleep 360
