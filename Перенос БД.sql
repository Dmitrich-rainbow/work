http://msdn.microsoft.com/en-us/library/ms345408.aspx - ������� ��� ������

-- ����� ����� ����������� � ������ ���� �� ��������
	1. ��������� ������� �����������
		ALTER DATABASE msdb
		MODIFY FILE (name = 'MSDBDATA', filename = 'D:\System\MSDBDATA.mdf')

		ALTER DATABASE msdb
		MODIFY FILE (name = 'MSDBLOG', filename = 'E:\System\MSDBLOG.ldf')

		ALTER DATABASE model
		MODIFY FILE (name = 'modeldev', filename = 'D:\System\model.mdf')

		ALTER DATABASE model
		MODIFY FILE (name = 'modellog', filename = 'E:\System\modellog.ldf')

		ALTER DATABASE tempdb
		MODIFY FILE (name = 'tempdev', filename = 'D:\System\tempdb.mdf')

		ALTER DATABASE tempdb
		MODIFY FILE (name = 'templog', filename = 'E:\System\templog.ldf')
	2. ��������� �������
	3. ������ ����� Configuration Tools ��������� �������
		dD:\System\master.mdf;-eC:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\ERRORLOG;-lE:\System\mastlog.ldf
		
	4. ��������� � ��������� ������
	5. Resource �� �� �����������

-- MSDB/Restore msdb
	- ��� �������� ������ msdb ���������� �������� ����� � ������ ����� ����� �� ������������, �� ���� � ����� �� �� �������� ���������� � ������������ ������, ������ � master
	1. ������ ��������� �����
	2. �� ������� ���������� ����������� SQL Agent(��������� ����������� � msdb)
	3. ������� ���������� �������� � msdb ������
	4. ��������������� ����
	
-- �������������� master/Restore master
	1. Start the server instance in single-user mode
		net start mssqlserver /m
	2. Connect to SQL Server
		sqlcmd -e
	3. restore the master database. (this will bring up all the user info and database info)
		RESTORE DATABASE master FROM DISK = 'Z:\SQLServerBackups\AdventureWorks2012.bak' WITH REPLACE
	4. switch back to multi user mode and restart service.
		net start mssqlserver

-- ������� ������� ���
	- Detach/Attach
	- ���� ������ ������, �� ���� ��� ������������� �����������

-- ������� tempdb
	use master
	alter database tempdb
	modify file(
	name = tempdev,
	filename = N'C:\�����_�����\tempdb.mdf')
	go

	alter database tempdb
	modify file(
	name = templog,
	filename = N'C:\�����_�����\templog.ldf')
	go
	
-- ������� �� � AlwaysOn
	- �� Secondary ��������� �� �� AlwaysON (�� ������� � ��������� Recovery)
	- ���������� ����� ����������������� ��� ������ ALTER DATABASE [RSNewsDb] MODIFY FILE (NAME = RSNewsDb_log2 ,FILENAME ='L:\LOGS\RSNewsDb_log2.ldf')
	- ���������� SQL Server
	- ��������� ��������� �����
	- ����������� SQL Server
	- ���������� �� � AlwaysON

-- ����������� ��������� ��
	Setup /QUIET /ACTION=REBUILDDATABASE /INSTANCENAME=ABS4V /SQLSYSADMINACCOUNTS=dkx6kpqadm /SAPWD= [*****]
	
-- Flags/�����	
	-T3607	-- Recovers no database. Skips automatic recovery (at startup) for all databases.
	-T3608 -- �������������� ����������� msdb. Recovers master database only. Skips automatic recovery (at startup) for all databases except the master database.
	-T3609	-- Skips the creation of the tempdb database at startup. Use this trace flag if the tempdb database is problematic or problems exist in the model database.
	/f --parameter is to start SQL Server service with its minimal configuration and in single user mode
	/m"SQLCMD" -- ��������� ����������� ������ ����� SQLCMD

-- ���� �������� ������ �������� ������ � ������ �� ��������
	- � ��������� ������� ������� -T3608 � �������� ����������������� �����

--����� ���������� ����� � �������������� ���� ������, ������������ ����� ������, �������������� �������� ����������
	sp_helpfile;

-- ����������� master
	From the Start menu, point to All Programs, point to Microsoft SQL Server, point to Configuration Tools, and then click SQL Server Configuration Manager.
	In the SQL Server Services node, right-click the instance of SQL Server (for example, SQL Server (MSSQLSERVER)) and choose Properties.
	In the SQL Server (instance_name) Properties dialog box, click the Startup Parameters tab.
	In the Existing parameters box, select the �d parameter to move the master data file. Click Update to save the change.
	In the Specify a startup parameter box, change the parameter to the new path of the master database.
	In the Existing parameters box, select the �l parameter to move the master log file. Click Update to save the change.
	In the Specify a startup parameter box, change the parameter to the new path of the master database.
	The parameter value for the data file must follow the -d parameter and the value for the log file must follow the -l parameter. The following example shows the parameter values for the default location of the master data file.
	-dC:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\master.mdf
	-lC:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\mastlog.ldf
	If the planned relocation for the master data file is E:\SQLData, the parameter values would be changed as follows:
	-dE:\SQLData\master.mdf
	-lE:\SQLData\mastlog.ldf
	Stop the instance of SQL Server by right-clicking the instance name and choosing Stop.
	Move the master.mdf and mastlog.ldf files to the new location.
	Restart the instance of SQL Server.
	Verify the file change for the master database by running the following query.
	
	SELECT name, physical_name AS CurrentLocation, state_desc
	FROM sys.master_files
	WHERE database_id = DB_ID('master');
	GO

-- ������� ��������������� ��/����������	
	1. Execute a series of alter database [foo] modify file (name = 'foo_1', filename = 'new location here') statements
	2. alter database [foo] set offline (youll have to kill any active spids in the db or wait for them to finish their business)
		ALTER DATABASE YourDatabaseName SET OFFLINE WITH ROLLBACK IMMEDIATE
	3. move your files
	4. alter database [foo] set online
		ALTER DATABASE YourDatabaseName SET ONLINE
		
-- Detach
	1. ��� detach ��� ���������� � �� ���������, ����� backup �����
	
	- ������� �� � ����� ����� FOR ATTACH_REBUILD_LOG.
		- ��� ���� �������� ������� backup
		- ����� ������������ ������ �������� ����� ���������� �� � ������� �����
		
	- master
		- system-wide configuration settings, endpoints, logins, databases on the current instance, database files and usage, and the definitions of linked servers
		- ������� ������ �� ������������� ����� sql server configuration mangment > ��������� �������
			-dE:\Data\master.mdf
			-lE:\Data\mastlog.ldf
			-eE:\Data\LOG\ERRORLOG
		
	- tempdb
		- ������������ ��� ��������, ����������, snapshot ��������
		- ������ � ���� ������ �������� UNDO
		- ���� ������
			1. ����������������
			2. ����������
				- work tables	
					- Spooling, to hold intermediate results during a large query
					- Working with XML or other large object (LOB) data type variables
					- Processing SQL Service Broker objects
					- Working with static or keyset cursors
				- work files
					- Work files are used when SQL Server is processing a query that uses a hash operator, either for joining or aggregating data.
				- sort units
			3. ������������ 
				- When an AFTER trigger is fired (versions aren�t generated by INSTEAD OF triggers)
				- When a Data Modification Language (DML) command is executed in a database that allows snapshot transactions, either snapshot isolation or read-committed snapshot isolation (RCSI)
				- When multiple active result sets (MARS) are invoked from a client application
				- During online index builds or rebuilds when the index has concurrent DML				
		
	- mssqlsystemresource
		- Executable system objects, such as system stored procedures and functions, are stored here
		- ����������� ��� ���������� �������
		- ���� �� ����� ���������� �� ��
			1. ���������� SQL > Copy files DB > Attach with another name
			2. ��������� ������ � single user � ����� ����� ����� ������� mssqlsystemresource
		- � SQL Server 2012 ������ �� �� ����� ���� ����
			
	- msdb
		- �������� ��� ���������� � ��������, ������ ������
		- jobs, alerts, log shipping, policies, database mail, and recovery of damaged pages
		
	- NET START MSSQLSERVER /f /T3608
		/f - min cpnfiguration
		/T3608 - master-only recovery mode

