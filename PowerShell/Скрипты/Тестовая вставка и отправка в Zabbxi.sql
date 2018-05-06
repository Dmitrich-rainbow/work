[int]$errors_old = 0
[int]$errors_new = 0
$time = get-date

do
{

$errors_new = 0

$myvar  = 'digispot-sql1.msk.rian\DJIN digispot-sql2.msk.rian\DJIN AX2009-SQL-STD AX2009MIA-SQL AXA-SQL Fabnews-db2 AXA14-APP1 CRM2011-APP1-DV mscl4-node1 mscl3-node3\djinmsk LYNC-AM1\RTCLOCAL mscl3-node3\dpcrm mscl4-node2 mscl3-node4\sp13 LYNC-FRONT2\RTCLOCAL mscl3-node3\sp13 mscl3-node4\djinmsk mscl5-node1.msk.rian\fab mscl3-node4\dpcrm mscl5-node2.msk.rian\fab omni-uat-db1\omni_uat OMNI-UAT-APP1\OT Pr13-app1 sed-db1\prod_sed sed-uat-db\uat_sed sepm-db1\sepm shared-db1\mssqlshared1 Vsphere-develvi\sqlexp_vim VISCTRL-DB1\VISCTRL ms-cluster1-lnc\mslync VSPHERE-DEVELVI\VIM_SQLEXP'
$myvar1 = $myvar.split(" ")
for($i = 0;$myvar1.Count -gt $i; $i++)
{

    if($errors_new -gt 3) {break}

    try
    {

    invoke-sqlcmd -ServerInstance $myvar1[$i] -query "if object_id('master.dbo.test_insert') is null
    BEGIN
	    CREATE TABLE master.dbo.test_insert ([date] datetime DEFAULT GETDATE())
    END

    INSERT INTO master.dbo.test_insert
    VALUES (DEFAULT)" -ConnectionTimeout 5    

    }

    CATCH
    {          
        $errors_new = $errors_new + 1      
    }
}

If ($errors_old -ne $errors_new -or $time.AddSeconds(60) -lt (get-date) )
{   

    $errors_old = $errors_new
    $time = get-date

    C:\Zabbix-agent\zabbix_sender -z observer1-0.rian.off -s "network_core_work_mssql" -k network_core_work_mssql -o $errors_new.ToString()
}

Start-Sleep -s 5

}
while ((Get-Date -Format t) -lt '9:00')

