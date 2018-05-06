-- ��������
	- ���� ���� ����� tempdb ��� snapshot isolation level - version store
		-- ��� ����� �������� ����� ������ ������ 
			SELECT SUM(version_store_reserved_page_count) AS [version store pages used],
			(SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB]
			FROM sys.dm_db_file_space_usage;
		-- ���������� ���������� � ������ ������
			SELECT transaction_id
			FROM sys.dm_tran_active_snapshot_database_transactions 
			ORDER BY elapsed_time_seconds DESC;

-- ���������
	- ������ ��� ������������� ���� http://www.sqlskills.com/blogs/paul/correctly-adding-data-files-tempdb/
	- ���������� ������ ������:
		1 �������: 1 ���� = 1 ���� ������ (�� ������ �� ������� � ������� ��������)
		2 �������: 1/2 ��� 1/4 �� ���������� ����� ����
		3 �������: if you have less than 8 cores, use #files = #cores. If you have more than 8 cores, use 8 files and if you�re seeing in-memory contention, add 4 more files at a time
	- ��� ����� ������ ������ ���� ������ �������
	- ��� ������ ����������� ���������� ������ ����
	- ����������� �� ������� ������ ��� �� RAM DRIVE
	- ������������� ����� ������ �� ����������� ������ ���� �� ������ ������
	- ����� ����������� ����������� � tempdb ���� ��������� ��������� ������� � ������������ � ���� �� ����� �������� ����� ��������. ��� �������� ����� �����, �� ������� ���������� ������ tempdb �������� ��������
	- ������ �������� ����� ������ � tempdb - ������� ��������
	-- ����� ����� ������������ tempdb
		1. ��������� �������� (������� ������). �������� ������ ����, ����� ������ JOIN � ��������, ������� ���������� ��������� ��������, ����� ������� ��������� �������, �������� ���� ������ �� ���� ������� � ������� � ��� JOIN
		2. ���������� ����������, ���� ����� �������� � �������. ����� �� �������� �� ��� ����������, �� �� �������� �� ��������� ������� � ����� ���������� � ��������
	-- ��� �������� ������ tempdb
		1. ���������� �������� �� ��� ����, �� ����������� ��������� �������, ���� ��� �������������
		2. ���������� �� �������� ������� �����
		3. ���� 1118, 1117
		4. ��������� ������ ������
		5. ���� ����� 'Perform Volume task'
		6. 	USE [master]
			GO
			ALTER DATABASE [tempdb] SET PAGE_VERIFY NONE  WITH NO_WAIT
			GO
			ALTER DATABASE [tempdb] SET DELAYED_DURABILITY = ALLOWED WITH NO_WAIT
			GO
			ALTER DATABASE [tempdb] SET AUTO_UPDATE_STATISTICS OFF WITH NO_WAIT
			GO
			ALTER DATABASE [tempdb] SET AUTO_UPDATE_STATISTICS_ASYNC ON WITH NO_WAIT
			GO
		7. �� ����� ������� �� ��������� ������� �������� tablock
			
-- ������ ���� ��� ������ ������ tempdb
	- ���� >> ��������� >> cmd >> cd '����� ����� bin sql server' >> sqlservr.exe /f /c >> ��������� ���� � �����
	- ���� >> ��������� >> cmd >> sqlcmd - e >> ������ ������������ ����� tempdb
	- �������� �������� ������� -T3608
		alter database tempdb
		modify file(
		name = templog,
		filename = N'C:\templog.ldf')
		go
		alter database tempdb
		modify file(
		name = tempdev,
		filename = N'C:\tempdb.mdf')
		go	
	
-- �����������
	1. ������ ������� View
	2. ������ ������� Trigger
	
-- Trace Flag 1118
	- �� ������ ���� 2005 �� ��� ������� ������� (Paul Randal) � ���� �� �� ��� �������, �� �� ��������� ��������� ��������� ���������	 
	
-- CHECKPOINT
	- A checkpoint is only done for tempdb when the tempdb log file reaches 70% full � this is to prevent the tempdb log from growing if at all possible (note that a long-running transaction can still essentially hold the log hostage and prevent it from clearing, just like in a user database)
	- � ������� �� ���������������� ��� ������ � tempdb �� ������������ �� ����, ����� �������� ����� lazywriter process (part of the buffer pool) has to make space for pages from other databases � ����� �������� �������� ����� ������� CHECKPOINT
	- The other operation that occurs during a checkpoint of databases in the SIMPLE recovery model is that the VLFs in the log are examined to see if they can be made inactive 

-- ��������� �������/temporal table
	- ��������� ������� � ����������/temporal table in sp
		1. ���� ���� ��������� ������� ��������� � ���������, �� ����� ���� ��� �� ���������, � truncate + rename. ��� ��������� ���������� ��� �� ������� ������ � ����������� ������ ���� ��������� ��������������� ���������� ����������, ����������� �� ���������� ����� ��� ������� ���������� ��� ��������� �������������. ��� ���� ���� ��������� 10 �����, �� ����������� �������� � ������ ������� 10+500 ����� (���� ����� �����, �� ����� ������� ���������� 20% ������), �� ���� ������������� ����� ��������� ��-���� ��������� ���������� ����������, �� ��� ����� �� ��������� � �� ���������� ��� ������ �������. � ������ ������ TRUNCATE ��� �� ���������� ���������� �����.
		2. RECOMPILE �� ��������, ��� ��� �� ���������� ���������� ��� �� ������ �� ��������� ��������
		3. Update statistics �� ��������� �������� � ��������� ��� �� �� �������, �� ��� ������� ������ ����, ������� ������� ����� RECOMPILE + Update Stastics

	-- ����������� ������
		1. �� ������������ SELECT *
		2. ���������� �������, ����� �� �������� ��
	
-- ��������� �����
	-- �����
		SELECT SUM(unallocated_extent_page_count) AS [free pages], 
		(SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB]
		FROM sys.dm_db_file_space_usage;
	-- �� ������
		SELECT
			[name]
			,CONVERT(NUMERIC(10,2),ROUND([size]/128.,2))											AS [Size]
			,CONVERT(NUMERIC(10,2),ROUND(FILEPROPERTY([name],'SpaceUsed')/128.,2))				AS [Used]
			,CONVERT(NUMERIC(10,2),ROUND(([size]-FILEPROPERTY([name],'SpaceUsed'))/128.,2))		AS [Unused]
		FROM [sys].[database_files]
	
-- ����� ��� Internal ������
	SELECT SUM(internal_object_reserved_page_count) AS [internal object pages used],
	(SUM(internal_object_reserved_page_count)*1.0/128) AS [internal object space in MB]
	FROM sys.dm_db_file_space_usage;
	
-- ����� ������� ����������������� ��
	SELECT SUM(user_object_reserved_page_count) AS [user object pages used],
	(SUM(user_object_reserved_page_count)*1.0/128) AS [user object space in MB]
	FROM sys.dm_db_file_space_usage;
	
-- ������������� tempdb ��������/��� ����� � tempdb
	SELECT session_id, 
	  SUM(internal_objects_alloc_page_count) AS task_internal_objects_alloc_page_count,
	  SUM(internal_objects_alloc_page_count)*8/1024 as task_internal_objects_alloc_page_count_mb,
	  SUM(internal_objects_dealloc_page_count) AS task_internal_objects_dealloc_page_count 
	FROM sys.dm_db_task_space_usage 
	GROUP BY session_id
	ORDER BY task_internal_objects_alloc_page_count DESC;
	
-- ����� ������� ������� � tempdb
	select * from tempdb.sys.all_objects
	where is_ms_shipped = 0;
	
-- ������������� tempdb (������)
	SELECT SUM(user_object_reserved_page_count)*8 as usr_obj_kb, -- ������� ������ �� ��������� ���� ������ ������������ � ���������� ����
	SUM(internal_object_reserved_page_count)*8 as internal_obj_kb, -- ����������, ������� ������ ������������ ��� ��������� �����
	SUM(version_store_reserved_page_count)*8 as version_store_kb, -- ��������� ����� ������ ��� �������� ������ ����� ��� �������������
	SUM(unallocated_extent_page_count)*8 as freespace_kb,
	SUM(mixed_extent_page_count)*8 as mixedextent_kb
	FROM tempdb.sys.dm_db_file_space_usage
		
		-- ����� ��������
			SELECT es.session_id
			, ec.connection_id
			, es.login_name
			, es.host_name
			, st.text
			, su.user_objects_alloc_page_count
			, su.user_objects_dealloc_page_count
			, su.internal_objects_alloc_page_count
			, su.internal_objects_dealloc_page_count
			, ec.last_read
			, ec.last_write
			, es.program_name
			FROM tempdb.sys.dm_db_session_space_usage su
			INNER JOIN sys.dm_exec_sessions es ON su.session_id = es.session_id
			LEFT OUTER JOIN sys.dm_exec_connections ec ON su.session_id = ec.most_recent_session_id
			OUTER APPLY sys.dm_exec_sql_text(ec.most_recent_sql_handle) st
	

	
-- ����� ���������� � tempdb ������
	WITH 
	XMLNAMESPACES (DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
	SELECT 
	Query_Plan.query('ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') TempDbSpillWarnings
	INTO #test
	FROM sys.dm_exec_cached_plans as s
	CROSS APPLY sys.dm_exec_query_plan(s.plan_handle) AS deqp

	SELECT * FROM #test WHERE CAST(TempDbSpillWarnings as varchar(MAX)) like  '%Spool%'
	DROP TABLE #test
	
-- ����� allocation page contention in tempDB. ����� ������� ���� ��� ��� �������, ������ ��� ������ ������ ���������� ������ ������ ���� tempdb
	Select session_id,
	wait_type,
	wait_duration_ms,
	blocking_session_id,
	resource_description,
		  ResourceType = Case
	When Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 1 % 8088 = 0 Then 'Is PFS Page'
				When Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 2 % 511232 = 0 Then 'Is GAM Page'
				When Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 3 % 511232 = 0 Then 'Is SGAM Page'
				Else 'Is Not PFS, GAM, or SGAM page'
				End
	From sys.dm_os_waiting_tasks
	Where wait_type Like 'PAGE%LATCH_%'
	And resource_description Like '2:%' -- 2 ��� id ��	
	
-- ��������� ����������� �� ���������� ������ tempdb
	- ��������� Performance Monitor �� SQLServer:Databases - Transaction/sec � tempdb � ���� tempdb ���� ���������� ������ ���������� ��� ��� �� ��������, ������ �� ���� � ������ �����������
	
-- �������� �� ������������� ���������� ������ tempdb (Paul Randal)
	SELECT
		[owt].[session_id],
		[owt].[exec_context_id],
		[owt].[wait_duration_ms],
		[owt].[wait_type],
		[owt].[blocking_session_id],
		[owt].[resource_description],
		CASE [owt].[wait_type]
			WHEN N'CXPACKET' THEN
				RIGHT ([owt].[resource_description],
				CHARINDEX (N'=', REVERSE ([owt].[resource_description])) - 1)
			ELSE NULL
		END AS [Node ID],
		[es].[program_name],
		[est].text,
		[er].[database_id],
		[eqp].[query_plan],
		[er].[cpu_time]
	FROM sys.dm_os_waiting_tasks [owt]
	INNER JOIN sys.dm_exec_sessions [es] ON
		[owt].[session_id] = [es].[session_id]
	INNER JOIN sys.dm_exec_requests [er] ON
		[es].[session_id] = [er].[session_id]
	OUTER APPLY sys.dm_exec_sql_text ([er].[sql_handle]) [est]
	OUTER APPLY sys.dm_exec_query_plan ([er].[plan_handle]) [eqp]
	WHERE
		[es].[is_user_process] = 1
	ORDER BY
		[owt].[session_id],
		[owt].[exec_context_id];
	GO
	
	-If you see a lot of lines of output where the wait_type is PAGELATCH_UP or PAGELATCH_EX, and the resource_description is 2:1:1 then that�s the PFS page (database ID 2 � tempdb, file ID 1, page ID 1), and if you see 2:1:3 then that�s another allocation page called an SGAM.

	There are three things you can do to alleviate this kind of contention and increase the throughput of the overall workload:
		Stop using temp tables
		Enable trace flag 1118 as a start-up trace flag
		Create multiple tempdb data files

-- ���������� ���������� � tempdb
	SELECT
	 SPID = s.session_id,
	 s.[host_name],
	 s.[program_name],
	 s.status,
	 s.memory_usage,
	 granted_memory = CONVERT(INT, r.granted_query_memory*8.00),
	 t.text, 
	 sourcedb = DB_NAME(r.database_id),
	 workdb = DB_NAME(dt.database_id), 
	 mg.*,
	 su.*
	FROM sys.dm_exec_sessions s
	INNER JOIN sys.dm_db_session_space_usage su
	   ON s.session_id = su.session_id
	   AND su.database_id = DB_ID('tempdb')
	INNER JOIN sys.dm_exec_connections c
	   ON s.session_id = c.most_recent_session_id
	LEFT OUTER JOIN sys.dm_exec_requests r
	   ON r.session_id = s.session_id
	LEFT OUTER JOIN (
	   SELECT
		session_id,
		database_id
	   FROM sys.dm_tran_session_transactions t
	   INNER JOIN sys.dm_tran_database_transactions dt
		  ON t.transaction_id = dt.transaction_id 
	   WHERE dt.database_id = DB_ID('tempdb')
	   GROUP BY  session_id,  database_id
	   ) dt
	   ON s.session_id = dt.session_id
	 CROSS APPLY sys.dm_exec_sql_text(COALESCE(r.sql_handle,
	 c.most_recent_sql_handle)) t
	 LEFT OUTER JOIN sys.dm_exec_query_memory_grants mg
	   ON s.session_id = mg.session_id
	 WHERE (r.database_id = DB_ID('tempdb')
	   OR dt.database_id = DB_ID('tempdb'))
	  AND s.status = 'running'
	 ORDER BY SPID;
	
-- ������� �������. tempdb
- �������:
	1. ����� ������������ ������
	2. ����� ����� ����� � �� � ����� �������
	3. ����� �������� �������� �����
	4. ������ � �������� � tempdb �� ������� �������, ��� � ��������, ������ ��� ��� �����
	   ������� ��������������
	   
- �������� �� ���� ������
	1. ����������� ���������� �� model � tempdb
	2. �������� �� model � tempdb
	3. ��������� tempdb
	...
- ���� �������� � tempdb
	1. ��������� sql � ���������� -f
	2. ������ 1 ���� �������� � ����� (ulimited,fixed auto grow)
	3. ������ ���� ������� 516096 bytes (unlimited,10% autogrow)
	4. ���������� �� � ����� ��������� ��� ��
	5. �������
- ������ ������� ����������� ��������
	1. ������� ����� ���� ������� �� ����� �����
	2. ��������� sql � ���������� -f
	3. �������� ��������� ���� ���� �� ������ ����
	4. �������
- ��� �������� � tempdb
	1. ��������� �������
	2. ��������� ����������, ��� �� ��, ��� ���������� ��������� ������� � ��������� ���������
	3. ��������� ��������� (# � ##)
	4. ������� �������, ��������� � tempdb
	5. ���������� (order by & index rebuild)
	6. ������� ������� (Worktable -����. ������� SQL SErver)
	7. ������� ����� (WOrkfile - Hash joins)
	8. Version store
	
- ���� ������ ���������
	1. ����� ������ ��������� �������, ������ ��� ���� ������ ������������ �� ���� ���������� �����

- ������ ���� �� ��������
	1. �������� PAGELATCH
	2. ������� �������� �� 2:<fileid>:<fixed page #>
	3. �������� ������, �� ����� (PAGELATCH �� PAGELATHIO)
- �������
	1. ����������� # �������
	2. Trace flag 1118
	3. ��������� ������
	4. �� ������� autogrow (Trace flag 1117)
	5. ������� ������������� ��������� ������
	6. ���������� ����������� ��������� ��������
- ������� ������ �����
	- ���� ������ 8 �����������, �� �� 1 ����� ������ �� CPU
	- ���� ������ - 8 ������ ������
	
--	������ ��������
	- �� ����������� ��������� �������, ����� ��� �� �����
	- ���������� �� ����� ������� ������
	- ���������� � RAMDrive
		- ���� Standard ��������, ��� ��� ���� ����������� �� ������
	- ����������� ���� 1118 (sql server �������� ������������ ��������� �������). �������� ������������������. ��� ��� ��������
	- ���������� ��������� ������ ������. ���� ���� ������ 8, �� 8, ���� ������ �� ������� � 8 � ����������� �� 4
	- tempdb ��� ��������� ���� ��� ������� ��������. ������� �������
	
-- �������� ������/�����
	USE [tempdb]
	GO
	CHECKPOINT
	GO
	DBCC DROPCLEANBUFFERS
	GO
	DBCC FREEPROCCACHE
	GO
	DBCC FREESESSIONCACHE
	GO
	DBCC FREESYSTEMCACHE ( 'ALL')
	GO
	DBCC SHRINKFILE (N'templog_default_ram' , EMPTYFILE)
	GO
	ALTER DATABASE [tempdb]  REMOVE FILE [templog_default_ram]
	GO