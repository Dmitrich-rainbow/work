$chechs = Get-Content \\msk.rian\mssqlbackup\SCRIPTS\jobs_register.sql 

[string]$results = "";
[string]$subject = "";
[string]$query = "";
[int]$result_symbols = 0;


$check = $chechs.split("`n")
for($i = 0;$check.Count -gt $i; $i++)
{

$param = $check[$i].split(";");

for($s = 0;$param.Count -gt $s; $s++)
{

if($s -eq 0)
{$server = $param[$s];}
if($s -eq 1)
{$job = $param[$s];}
if($s -eq 2)
{$threshold = $param[$s];}
if($s -eq 3)
{$skip_secondary = $param[$s];}

}

$query = "
DECLARE @skip bit
SET @skip = "+$skip_secondary.ToString()+"

IF (SELECT DATEDIFF(mi,ISNULL(MAX(last_executed_step_date),GETDATE()-100),getdate()) as name FROM msdb.dbo.sysjobs as t1 INNER JOIN msdb.dbo.sysjobactivity  as t2 ON t1.job_id = t2.job_id WHERE [enabled] = 1 AND t1.name = N'"+$job.ToString()+"')  > "+$threshold.ToString()+"
BEGIN
    IF (@skip = 1) and (SELECT Count(*) FROM sys.databases WHERE name NOT IN ('tempdb') and state_desc <> 'ONLINE') > 0
		SELECT NULL as name
	ELSE
		SELECT N'"+$job.ToString()+"' as name
END
"

Try
{
$results +=   (invoke-sqlcmd -ServerInstance $server -Database master -query $query -ErrorAction Stop | select -expand name);

}
Catch
{
$results += "Ошибка подключения к";
}


if($result_symbols+1 -le $results.Length)
{
    $results += " ("+$server+")" + "`n";
}


$result_symbols = $results.Length;


}


if ($results.TrimEnd().TrimStart() -eq "")
{
    $results = "Все задания отработали штатно";
    $subject = "Отчёт о проблемных заданиях SQL Server Agent (не обнаружено)";
}
else
{
    $results = $results.Insert(0,"Проверить задания:" + "`n" + "`n");    
    $subject = "Отчёт о проблемных заданиях SQL Server Agent (обнаружено)";
}

$results += "`n"+"`n" +
"Инструкция - http://kb.rian.off:3000/wiki/2/SQL_Server_Agent_checker"

echo $results

$encoding = [System.Text.Encoding]::UTF8;

Send-MailMessage -From "SQL Server Jobs <noreplay@rian.ru>" -To "mssql-alerts@rian.ru" -Subject $subject -Body $results -SmtpServer "mr0.rian.off" -Port 25 -Encoding $encoding;

C:\Zabbix-agent\zabbix_sender -z observer1-0.rian.off -s "service-jobs1.msk.rian" -k service_jobs1_sql_server_jobs_checker -o "1"

