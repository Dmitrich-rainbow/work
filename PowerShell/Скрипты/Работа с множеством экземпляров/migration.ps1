


$server = "APP-SQL1,1433"
$FilePath = gc "F:\SQL Scripts\PowerShell\Скрипты\Работа с множеством экземпляров\sqcripts.sql"
$FilesLocationExport = "F:\SQL Scripts\PowerShell\Скрипты\Работа с множеством экземпляров\APP-SQL1.txt"

Remove-Item "F:\SQL Scripts\PowerShell\Скрипты\Работа с множеством экземпляров\APP-SQL1.txt"

for ($n=1;$n -le 6;$n++)
{

$SqlQuery = ''
$startSymbol = "<"+$n+">"
$endSymbol = "</"+$n+">" 
$FromHereStartingLine = $FilePath | Select-String $startSymbol | Select-Object LineNumber 
$UptoHereStartingLine = $FilePath| Select-String $endSymbol | Select-Object LineNumber 


foreach ($t in $FilePath)
{
    if (($t.ReadCount -gt $FromHereStartingLine.LineNumber-1)  -and ($t.ReadCount -le  $UptoHereStartingLine.LineNumber))
     {$SqlQuery  = $SqlQuery  + $t -replace $startSymbol,"" -replace $endSymbol,""}                
}


$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server = "+$server+"; Database = master; Integrated Security = True;"

$SqlCmd = New-Object System.Data.SqlClient.SqlCommand

$SqlCmd.CommandText = $SqlQuery
$SqlCmd.Connection = $SqlConnection
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
switch($n){
    1 {echo $DataSet.Tables | Out-File $FilesLocationExport -Append}
    2 {echo $DataSet.Tables | Out-File $FilesLocationExport -Append}
    3 {echo $DataSet.Tables | Format-Table | Out-File ($FilesLocationExport + "configurations.txt") }
    4 {echo $DataSet.Tables | Format-Table | Out-File ($FilesLocationExport + "messages.txt") }
    5 {echo $DataSet.Tables | Out-File $FilesLocationExport -Append} 
    6 {echo $DataSet.Tables | Format-Table | Out-File $FilesLocationExport -Append }
}


}



