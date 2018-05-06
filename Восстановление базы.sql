-- Restoring pages/�������������� �������
	- Damaged pages can be detected when activities such as the following take place.
		- A query needs to read a page.
		- DBCC CHECKDB or DBCC CHECKTABLE is being run.
		- BACKUP or RESTORE is being run.
		- You are trying to repair a database with DBCC DBREPAIR.
	- ���� �������� � ��������, �� �� ����� ������ �����������
	- ���� ���������� ����� �������, �� ����� �������������� �� backup
	- ������� ����� ������� ����� ���� ������������� � �������. Online �������� ������ � Enterprise
	- Start a page restore with a full, file, or filegroup backup that contains the page or pages to be restored. In the RESTORE DATABASE statement, use the PAGE clause to list the page IDs of all pages to be restored. The maximum number of pages that can be restored in a single file is 1,000.

-- ������ �����
NB! ������ ����� �������� ������ ��� ������ SQL2000
1. ������� ����� ���� � ����� �� ������ � �������� �� ������ � ������������ .mdf � .ldf ������� 
2. ������������� ������, ��������� ���� .mdf 
3. �������� ������, �� �������� �������� �� ������ ���� 
4. �� QA ��������� ������ 
	Use master 
	go 
	sp_configure 'allow updates', 1 
	reconfigure with override 
	go 

4. ��� �� ��������� 
select status from sysdatabases where name = '<db_name>' 
� ����������/���������� �������� �� ������ ������� ������� ���� 

5.��� �� ��������� 
update sysdatabases set status= 32768 where name = '<db_name>' 

6. ������������� SQL Server 

7. � �������� ���� ������ ���� ����� (� emergency mode). �����, ��������, ������������� ��� ������� 

8. �� QA ��������� 
DBCC REBUILD_LOG('<db_name>', '<��� ������ ���� � ��������� ������� ����>')
SQL Server ������ - Warning: The log for database '<db_name>' has been rebuilt. 

9. ���� ��� ���������, �� ��� �� ��������� 
Use master 
go 
sp_dboption '<db_name>', 'single user', 'true' 
go 
USE <db_name> 
GO 
DBCC CHECKDB('<db_name>', REPAIR_ALLOW_DATA_LOSS) 
go 

9a.
���� ��� �� ������� ��������� ���� � single user mode, �� ��� �������� ����������� ������ ����� ����������� dbo only mode
sp_dboption '<db_name>', 'dbo use only', 'true' 

10. ���� ��� � �������, �� 
sp_dboption '<db_name>', 'single user', 'false' 
go 
Use master 
go 
sp_configure 'allow updates', 0 
go

alter database DataBaseName set ONLINE, MULTI_USER

-- ������(���-�� �� ����������)
DBCC CHECKDB (uyar)
DBCC CHECKDB (uyar) WITH NO_INFOMSGS, ALL_ERRORMSGS
DBCC CHECKDB (uyar, REPAIR_FAST)
DBCC CHECKDB (uyar, REPAIR_REBUILD)

-- ��� �������
EXEC sp_resetstatus uyar; 
ALTER DATABASE uyar SET EMERGENCY
DBCC checkdb(uyar) 
ALTER DATABASE uyar SET SINGLE_USER WITH ROLLBACK IMMEDIATE 
DBCC CheckDB (uyar, REPAIR_ALLOW_DATA_LOSS) 
ALTER DATABASE uyar SET MULTI_USER

-- ��� �������
Use master 
go 
sp_configure 'allow updates', 1 
reconfigure with override 
go 
Use master 
go
alter database WWWBRON set emergency
go 
use master 
go 
sp_dboption 'WWWBRON', 'single_user', 'true' 
go 
USE WWWBRON
GO 
DBCC CHECKDB('WWWBRON', REPAIR_ALLOW_DATA_LOSS) 
go 
sp_dboption 'WWWBRON', 'single_user', 'false' 
Use master 
go 
sp_configure 'allow updates', 0 
go

-- One more
	ALTER DATABASE abs_V1 SET EMERGENCY;
	ALTER DATABASE abs_V1 SET SINGLE_USER;
	DBCC CHECKDB (abs_V1, REPAIR_ALLOW_DATA_LOSS) WITH NO_INFOMSGS, ALL_ERRORMSGS;
