-- Расширение диска Windows Server 2003
	cmd > diskpart > list volume > select volume %Volume Number% > extend
	
-- Добавить к кластеру template роли SQL Server и SQL Server Agent	
	1. Запускаем PowerShell
	Import-Module FailoverClusters -- подключение модуля
	Add-ClusterResourceType "SQL Server Agent" C:\Windows\system32\SQAGTRES.DLL
	Add-ClusterResourceType "SQL Server" C:\Windows\system32\SQSRVRES.DLL