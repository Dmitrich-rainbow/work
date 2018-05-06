
for($i = 0 ; $i -le 10000; $i++)
{
Get-Date | Add-Content "C:\distr\sql-cluster-dev.txt"
try
{
Measure-Command {invoke-sqlcmd -ServerInstance "sql-cluster-dev" -query "select @@version" -ErrorAction Continue} | Select days,hours,minutes,seconds, milliseconds | Add-Content "C:\distr\sql-cluster-dev.txt" 
}
CATCH
{
Add-Content "C:\distr\sql-cluster-dev.txt" "Error"
}
Start-Sleep -s 1
}

