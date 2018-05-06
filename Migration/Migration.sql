�������:
	1. Detach/Attach 
		- ���������� ������� � 2000 �� 20008 (��� ����������� ������ ����� Attach, ������ �� backup)
	2. �������� ��������
		- ��������� ������ �������� � ������� ���� ����� � ��		

-- ��� ����� ��������� � ����� �������
	SELECT instance_name   AS [������ ����������]
		 , sum(cntr_value) AS [����� �������������]
	FROM   sys.dm_os_performance_counters
	WHERE  object_name = 'SQLServer:Deprecated Features'
	AND    cntr_value <> 0
	GROUP BY instance_name
	ORDER BY [����� �������������] DESC
	
-- SQL Server Data Migration Assistant
	- �������� ���������������� ����������� �������� � ������ ����
		https://msdn.microsoft.com/en-us/library/mt613434.aspx
	- �������� ����� ������ SQL Server
		https://www.microsoft.com/en-us/download/details.aspx?id=53595
		
-- Database Experimentation Assistant
	- �������� �������� � �������� � ����������� � �� ����� SQL Server
		
-- Microsoft Assessment and Planning (MAP) Toolkit for SQL Server
	- map tool
	- �������� excel
	- �������� ���. ���������� ��� ��������
	- https://www.google.ru/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&ved=0ahUKEwjnxdfMqM7RAhXJd5oKHTjkBPIQFggcMAA&url=https%3A%2F%2Ftechnet.microsoft.com%2Fen-us%2Fsolutionaccelerators%2Fdd537572.aspx&usg=AFQjCNFGFr9iEpwBD2hmkw0QiPS7Q9uwsQ&sig2=1YkKi46qOUZPWxxckHL8iA
		
-- �������� ����� �������� �� ������ ������ SQL Server/Microsoft� Database Experimentation Assistant Technical Preview
	https://www.microsoft.com/en-us/download/details.aspx?id=54090
	
-- ����������� ��������
	- ������� ������ �� ������������ ��� ������ ������������� � ����
	- �� Collation. ���� �� ��� �������� � ������ COllation, �� ������ ����� ��� ����� �������� � ����� ������
	- �� ��, ������� �� ����� ���� ���������� �� �������������� ������ SQl, ������������� �� ����������� �����
	- ���������� ���������� ����������� �������� 21, �� ���������� ���� � ���� ��������, ������� � 2014 ����� ������������ mount point ��� ����������� �����
		- SQL RPC: Completed � SQL: BatchCompleted � Duration > 0 + PerfMon (4 ����)
		- �������� �����������
		- ��� ������������� ���� � Tuning Advizor > SQL: BatchCompleted (4 ���� �� ����� 100 �� �� ���� ����� ����� ����������)
	
-- �������� ����� ��������
	1. �����, ������ ��� �� �������������� ����
	2. ����� ��������� ����� �������������� � windows
	3. �� ������ ����� FULL backup, ��� ��� ����� ����� ������� �����
	
-- ��� �����/�������� stand alone instance
	0. ��������� ������������� � Windows
	0.1. Backup Windows, �������� Snapshot
	0.2. ������� ������������
	1. ��������� ��� � ��������� ��
		- Upgrade Advizor (����� ������ �������� �������� ����� ������� ������ SQL:BatchCompleted) (SQL:StmtCompleted, SQL:BatchCompleted, SP:Completed, RPC:Completed, SP:StmtCompleted). ����� ��������� �� ������� �������
	1.1. ����� ������� �������� ����� ����� ���� ������� ����� �������� (SQL:BatchCompleted, RPC:Completed)
	1.2. ������������� ����������� ������������
		- Distributed replay (����������� ������ � ��������� ��������). � ������ ������� ������ ������� ����� > ���������� � ������� > ���������� > ���������� � ������� ��������
	1.3. SQL Server Data Migration Assistant
	2. ��������� ���������/Breaking Change
		https://technet.microsoft.com/en-us/library/ms143179%28v=sql.110%29.aspx?f=255&MSPPError=-2147217396
	3. ��������� ��� � ��� �� Express � Developer Edition
	4. ��������� �������� DBCC CHECKDB WITH DATA_PURITY; �� ������������� ����� ������
	5. ��������� ����������� ����������� ����������� ����������� ������������ DBCC UPDATEUSAGE(db_name);
	6. �������� ����������
	7. sp_refreshview	
	
-- Checklist
	1. ������
		- ������ ������ ������������� �� ��. ������ (Microsoft) - ��������.sql
	2. �������� ����� ���� x86 � �� ������� ��� ��������
	4. Collation
	5. ��������� ������������
		SELECT * FROM sys.configurations c1 INNER JOIN [MS-CLUSTER1-LNC\MSLYNC].master.sys.configurations c2 ON c1.configuration_id = c2.configuration_id
		WHERE c1.value_in_use <> c2.value_in_use
	6. ���������������� ��������� �� �������
		SELECT * FROM sys.messages ORDER BY message_id DESC
	7. Linked Server, ����� ��� ����� ���� �32, �� �64
		SELECT * FROM sys.servers
	8. ������� �������������
	9. Jobs
	10. Mirroring, Log Shipping, Replication, SSIS ������
		Select * from sysssispackages
	11. assembly
		-- ����� assembly/����� dll
			SELECT 
				assembly = a.name, 
				path     = f.name
			FROM sys.assemblies AS a
			INNER JOIN sys.assembly_files AS f
			ON a.assembly_id = f.assembly_id
			WHERE a.is_user_defined = 1;
	12. ��������� ������� ������
		-- ��� ���������� �����/Keys
			SELECT * FROM [sys].[openkeys]
	
		-- ��������� ���� �� ���������� � ��
			USE [master]
			GO
			SELECT db.[name]
			, db.[is_encrypted]
			, dm.[encryption_state]
			, dm.[percent_complete]
			, dm.[key_algorithm]
			, dm.[key_length]
			FROM [sys].[databases] db
			LEFT OUTER JOIN [sys].[dm_database_encryption_keys] dm
			ON db.[database_id] = dm.[database_id];
			GO	
	13. ��������� ��� ������ �� ���������� AWE, ��� ��� �� ������ � 2012 ������
		SELECT * FROM sys.configurations WHERE name like '%awe%'
	14. ������������ �� �������������� SQL ��� ���
	15. �� ���� �������� ���������� �������� ������������� ������������ �����, ��� �� ��������� �� ����� ����� ������ ��������
	16. �� ������ ����� FULL backup, ��� ��� ����� ����� ������� �����
	17. ����� ������� ������ SQL Server �� 'perform volume task' � 'lock page in memory'
	18. ������� ����� �����������
		-T1117 -- ��������� ������������ ���� ����� ���� ������ �� ������������, ����� ����������� ��� ������������ ����� ������ tempdb	
		-T1118 -- ���������� ������������ ��� Tempdb
		-T2371 -- �������� �������������� ���������� ����������, ����� ���� ����, � �� ��� 20% ���������
		-T3226 -- ���������� ������ � ��� ��������� ���������� �����������
		-T8048 -- ����������� �������� ���� 8 � ����� CPU �� �����
		-T4199 -- ������� ��� �������� ��� ������������, ������� ���� ������� 'on-demand'
	19. Replication/����������
	20. SELECT * FROM Sys.Plan_Guides
	21. ��������� ��������� �� ���� �� ����� ���������, ��� ��� ���� �� ������������� ��������� � �� �� �����, �� ��� ����� ������������

		
-- ������������� ��������
	1. �� �����1 ������ backup LOG ����� ��������
	2. �� �����2 ������ Restore LOG
	3. �� �����1 ��������� �� � SINGLE USER
	4. �� �����1 ������ backup LOG ����� ��������
	5. �� �����1 ��������� �� � offline
	6. �� �����2 ������ Restore LOG
	7. �� �����2 ��������� �� � MULTI USER
	
-- ���������� ���������
	- �� 2000 ����� ���� ������ ��������������� VIEW � top, ������ ��� �� ��������������
	
-- ��������� hostname	
	- ��� Stand-alone
		1. �� �������������� ��� SQL Server, ������� �������� � ����������
		2. ���� �� ������� �������� � Reporting Services, �� ����� ��������� ��� � https://msdn.microsoft.com/en-us/library/ms345235.aspx?f=255&MSPPError=-2147217396
		3. When you rename a computer that is configured to use database mirroring, you must turn off database mirroring before the renaming operation. Then, re-establish database mirroring with the new computer name. Metadata for database mirroring will not be updated automatically to reflect the new computer name. Use the following steps to update system metadata.
		4. �������� �� ������� ���������� hostname		
		5. ��� ������ �������� ��� �� ���������� ����� ��������� ��������� ��������� https://msdn.microsoft.com/en-us/library/ms190318.aspx?f=255&MSPPError=-2147217396
		
		- ��� SQL Server � default instance name
			sp_dropserver <old_name>;
			GO
			sp_addserver <new_name>, local;
			GO
			
-- ���������� �����
	- ��������� Upgrade Edition
	- ������������� SQL
	- ���� ��� ���������� ������������, �� ���������� ��������� ���� �� ������ ����, ����� ����� ���� ���������� � ���
			
		- ��� ������������� ����������
			sp_dropserver <old_name\instancename>;
			GO
			sp_addserver <new_name\instancename>, local;
			GO
			
		- ����� ������������� ��������� ���� ������������� �� �������, ����� ��������� ��������� sp_dropserver
			sp_dropremotelogin old_name;
			sp_dropremotelogin old_name\instancename;
			
-- �������� �� ������ �������
	1. Build the new cluster with the new OS and SQL Server versions with SQL as a clustered instance with the same instance name (the OS name will be different, but well deal with that later).
	2. Copy all the logins, SSIS packages and jobs to the new clustered instance. (����� ������������ ��������� ��)
	3. On the night of the upgrade take the old clustered instance offline.
	4. Take a SAN snapshot of the LUN (this will be your rollback)
	5. Move the LUNs from the old cluster to the new cluster and bring the LUNs online and add them as clustered resources.
	6. Put the new clustered disks into the SQL Server resource group.
	7. Make the SQL Server service dependent on the clustered disks within the failover cluster manager.
	8. Attach the databases to the new clustered instance.
	9. Add a new network name resource to the cluster based on the old clustered instances network name (this will probably require that you delete the network name from Active Directory first).
	10. Add a new network IP resource to the cluster based on the old clustered instances IP address (optional)
	11. Test
	12. Once testing is complete delete the SAN snapshot.
	13. Done
	14. ��������� ������� assembly
	15. ��������� ������� ������
	16. Upgrade Advizor
	
-- �������� � ������
	- Migration from SQL Server to Azure SQL Database Using Transactional Replication (https://blogs.msdn.microsoft.com/sqlcat/2017/02/03/migration-from-sql-server-to-azure-sql-database-using-transactional-replication/)	
		
-- ��� �����:
	1. �����
		������� ����� ��������: 
			- SQL Server Managment Studio 2008 �������� ������� ���������� � � ������� � ���������� ����� �� ������ �� ������ SQL Server, �� ���������� ������� �������, ������ � Managment Studio 2008 �� ������� ������������ � Integration Services 10.

			-  ��� �� ������ ����� ���������. ��� ������ ��������� ��� �������� ������������� � ��� ������ ������ ������� � ����� �������. ��� ��� ��������� �������� � ��������� �� msdb. � ������ �������� ��� ������ Integration Services �� SQL Server 2012.

			- NT Service\MsDtsServer120 ��� ��������� �������, ������� ������������� �������������� ������� � ������ ���������. ���� �� ����� ��������� ������������� ��������, �� ������� ����� �������� �������, ���� ����� �������� � �������� �� NT Service\MsDtsServer120, �� ����� �������� �� Network Service.
			
	2. ��������� (���� �������� SQL Server 2012 �� ������ �������)
		1. ��������� ������ �������� 
		2. ��������� ����������� ���������� SQL Server � ��� �� Instance Name, �� � ������ Cluster Resource Name � IP �� ���������� ����/LUN 15 ��. ��� ����� ������ ���� P:\ (������ �������� ���� ���������)
		3. ��������� ������������ ������� � ������ ����������� SQL Server
		4. �������� backup ��
		5. ��������� ������� ���������� SQL Server
		6. ����������� ��������� �� �� ��������� �����
		7. �������������� ������� SQL Server � ������� IP ��� ���������� ��������� ������
		8. ��������� ������ ���������� SQL Server
		9. ������� ������ �� ������� �������� �� �����, ����������� �� � ��������� ������ SQL Server, ��������� ������������
		10. ������� ��������� �� �� ������� ���������� SQL Server �� ����� (�� ��������� �����). ��� ������������� ������� ����� ����������� �������� Restore ��������� �� ������ �������
		11. ������ ������ ���������� SQL Server
		12. �������� ������ ������ ���������� SQL Server
		13. ����������� ���������������� �� (Attach Database)
		14. �������� ������ ������ ���������� SQL Server
		15. �������������� ������ SQL Server � ������� IP
		16. ���������� DNS
		
	3. Volkswagen (2005-2012)
		- ���� ����� ���������, � ������ �������
		
-- Upgrade Advizor
	- ������� � ���������� SQLDOM ��� ������ ������ SQL � �������. ������ ������ ��������� ��� ������������
	- ����� ��������� �� ������� �������
	
-- Oracle, Sybase ASE, DB2, MySQL and Access
	- ������� https://blogs.msdn.microsoft.com/ssma/2016/03/09/preview-release-of-sql-server-migration-assistant-ssma-for-sql-server-2016-rc0/
	- ��� ������������ https://msdn.microsoft.com/en-us/library/hh313041(v=sql.110).aspx