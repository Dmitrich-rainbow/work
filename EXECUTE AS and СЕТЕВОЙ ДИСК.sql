USE master
GO
EXEC sp_addumpdevice 'disk', 'AdvWorksData', 
'C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\BACKUP\AdvWorksData.bak';
GO
BACKUP DATABASE AdventureWorks2008R2 
 TO AdvWorksData
   WITH FORMAT;
GO

USE AdventureWorks2008R2;
GO
EXECUTE ('CREATE TABLE Sales.SalesTable (SalesID int, SalesName varchar(10));')
AS USER = 'User1';
GO

-- Посмотреть все сетевые диски
SELECT * FROM sys.backup_devices

-- Удалить устройство
sp_dropdevice