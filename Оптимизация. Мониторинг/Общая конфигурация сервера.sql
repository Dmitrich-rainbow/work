-- ���������� ������
	SELECT cpu_count AS [Logical CPU Count], hyperthread_ratio AS [Hyperthread Ratio],
	cpu_count/hyperthread_ratio AS [Physical CPU Count], 
	physical_memory_in_bytes/1048576 AS [Physical Memory (MB)], 
	sqlserver_start_time, affinity_type_desc -- (affinity_type_desc is only in 2008 R2)
	FROM sys.dm_os_sys_info WITH (NOLOCK) OPTION (RECOMPILE);
	GO

-- ���������
	EXEC xp_instance_regread 
	'HKEY_LOCAL_MACHINE', 'HARDWARE\DESCRIPTION\System\CentralProcessor\0',
	'ProcessorNameString';

-- ����� ������������ �������
	SELECT name, value, value_in_use, [description] 
	FROM sys.configurations WITH (NOLOCK)
	ORDER BY name OPTION (RECOMPILE);
	GO
	
-- ���������� �� �����
	sp_helpdb
	
-- ����� ������ ���� ��
	select SUM(size * 8.0 / 1024) as [������ ���� ��]
    from sys.master_files
	
-- ����� ������ ���� ����� ��
	select SUM(size * 8.0 / 1024) as [������ ���� ��]
    from sys.master_files
    WHERE type_desc = 'LOG'
	
-- ����� �� � �� ����������
	SELECT DB_NAME([database_id])AS [Database Name], 
		   [file_id], name, physical_name, type_desc, state_desc, 
		   CONVERT( bigint, size/128.0) AS [Total Size in MB],
		   CASE is_percent_growth WHEN 0 THEN CAST((CAST(growth as float)*8/1024) as nvarchar(10)) ELSE CAST(growth as nvarchar(10))+'%' END as [����������]
	FROM sys.master_files WITH (NOLOCK)
	WHERE [database_id] > 4 
	AND [database_id] <> 32767
	OR [database_id] = 2
	ORDER BY DB_NAME([database_id]) OPTION (RECOMPILE);
	GO
	
-- ����� ������ �� �� ������
	select SUBSTRING(physical_name,0,2), SUM(size * 8.0 / 1024) as [Size, Mb]
	from sys.master_files
	GROUP BY SUBSTRING(physical_name,0,2)	
	
-- Recovery Model � ������������� ����
	SELECT db.[name] AS [Database Name], db.recovery_model_desc AS [Recovery Model], 
	db.log_reuse_wait_desc AS [Log Reuse Wait Description], 
	ls.cntr_value AS [Log Size (KB)], lu.cntr_value AS [Log Used (KB)],
	CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT)AS DECIMAL(18,2)) * 100 AS [Log Used %], 
	db.[compatibility_level] AS [DB Compatibility Level], 
	db.page_verify_option_desc AS [Page Verify Option], db.is_auto_create_stats_on, db.is_auto_update_stats_on,
	db.is_auto_update_stats_async_on, db.is_parameterization_forced, 
	db.snapshot_isolation_state_desc, db.is_read_committed_snapshot_on,
	db.is_auto_close_on, db.is_auto_shrink_on, db.is_cdc_enabled
	FROM sys.databases AS db WITH (NOLOCK)
	INNER JOIN sys.dm_os_performance_counters AS lu WITH (NOLOCK)
	ON db.name = lu.instance_name
	INNER JOIN sys.dm_os_performance_counters AS ls WITH (NOLOCK) 
	ON db.name = ls.instance_name
	WHERE lu.counter_name LIKE N'Log File(s) Used Size (KB)%' 
	AND ls.counter_name LIKE N'Log File(s) Size (KB)%'
	AND ls.cntr_value > 0 OPTION (RECOMPILE);
	GO
	
-- �������� ������������� ������
	SELECT DB_NAME(fs.database_id) AS [Database Name], mf.physical_name, io_stall_read_ms, num_of_reads,
	CAST(io_stall_read_ms/(1.0 + num_of_reads) AS NUMERIC(10,1)) AS [avg_read_stall_ms],io_stall_write_ms, 
	num_of_writes,CAST(io_stall_write_ms/(1.0+num_of_writes) AS NUMERIC(10,1)) AS [avg_write_stall_ms],
	io_stall_read_ms + io_stall_write_ms AS [io_stalls], num_of_reads + num_of_writes AS [total_io],
	CAST((io_stall_read_ms + io_stall_write_ms)/(1.0 + num_of_reads + num_of_writes) AS NUMERIC(10,1)) 
	AS [avg_io_stall_ms]
	FROM sys.dm_io_virtual_file_stats(null,null) AS fs
	INNER JOIN sys.master_files AS mf WITH (NOLOCK)
	ON fs.database_id = mf.database_id
	AND fs.[file_id] = mf.[file_id]
	ORDER BY avg_io_stall_ms DESC OPTION (RECOMPILE);
	
-- ���������� VLF ������ �� ���� �����
	CREATE TABLE #VLFInfo (FileID  int,
					   FileSize bigint, StartOffset bigint,
					   FSeqNo      bigint, [Status]    bigint,
					   Parity      bigint, CreateLSN   numeric(38));
					   
	CREATE TABLE #VLFCountResults(DatabaseName sysname, VLFCount int);	 
	EXEC sp_MSforeachdb N'Use [?]; 

					INSERT INTO #VLFInfo 
					EXEC sp_executesql N''DBCC LOGINFO([?])''; 
		 
					INSERT INTO #VLFCountResults 
					SELECT DB_NAME(), COUNT(*) 
					FROM #VLFInfo; 

					TRUNCATE TABLE #VLFInfo;'
		 
	SELECT DatabaseName, VLFCount  
	FROM #VLFCountResults
	ORDER BY VLFCount DESC;
		 
	DROP TABLE #VLFInfo;
	DROP TABLE #VLFCountResults;
	GO
	
-- ������������ ��������
	SELECT DB_NAME(database_id) AS [Indexes: Database Name], OBJECT_NAME(ps.OBJECT_ID) AS [Object Name], 
	i.name AS [Index Name], ps.index_id, index_type_desc,
	avg_fragmentation_in_percent, fragment_count, page_count
	FROM sys.dm_db_index_physical_stats(DB_ID(),NULL, NULL, NULL ,N'LIMITED') AS ps 
	INNER JOIN sys.indexes AS i WITH (NOLOCK)
	ON ps.[object_id] = i.[object_id] 
	AND ps.index_id = i.index_id
	WHERE --database_id = DB_ID() AND
	page_count > 1500
	ORDER BY avg_fragmentation_in_percent DESC OPTION (RECOMPILE);
	GO
	
-- ������ ����������
	SELECT DB_NAME(database_id) AS [Statistics: Database Name], OBJECT_NAME(ps.OBJECT_ID) AS [Object Name], 
	i.name AS [Index Name], ps.index_id, index_type_desc,
	avg_fragmentation_in_percent, fragment_count, page_count
	FROM sys.dm_db_index_physical_stats(DB_ID(),NULL, NULL, NULL ,N'LIMITED') AS ps 
	INNER JOIN sys.indexes AS i WITH (NOLOCK)
	ON ps.[object_id] = i.[object_id] 
	AND ps.index_id = i.index_id
	WHERE -- database_id = DB_ID() AND
	page_count > 1500
	ORDER BY avg_fragmentation_in_percent DESC OPTION (RECOMPILE);	
	GO
	
-- ��������� Backup
	select
	  database_name,
	  MAX(backup_finish_date) as Last_backup_start_date,
	  max(backup_finish_date) as Last_backup_finish_date,
			case when [type]= 'D' then '1_Full Backup'
				 when [type] = 'I' then '2_Diff Backup'
				 when [type] = 'L' then '3_Log Backup'
				 end as [Backup TYPE],
	  count (1) as 'Count of backups'
	from msdb..backupset
	group by database_name,[type]
	order by database_name,[Backup TYPE] --desc --, Last_backup_finish_date
	go 
	
-- ���������� �����
	DBCC TRACESTATUS


-- ��������������� ��������
select spid, blocked, datediff(ms, last_batch, getdate()) as duration, loginame, nt_username, hostname, lastwaittype, status, cmd, program_name
from sysprocesses where blocked>0

-- ����� SQL-������� �������� � ������ ������?
SELECT [Spid] = session_Id
-- , ecid
, duration = datediff(ms, start_time, getdate())
, reads
, sp.blocked
, [Database] = DB_NAME(sp.dbid)
, [User] = case nt_username when null then nt_username else loginame end
, [Status] = er.status
, [Wait] = wait_type
, [Individual Query] = SUBSTRING (qt.text, er.statement_start_offset/2,
(CASE WHEN er.statement_end_offset = -1
THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
ELSE er.statement_end_offset END - er.statement_start_offset)/2)
,[Parent Query] = qt.text
, Program = program_name
, Hostname
, nt_domain
, start_time
FROM sys.dm_exec_requests er
INNER JOIN sys.sysprocesses sp ON er.session_id = sp.spid
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) as qt
WHERE session_Id > 50 --and session_id<>75 -- ������������ ��������� ��������
AND session_Id NOT IN (@@SPID) -- ������������ ������� ����� �������
ORDER BY 1, 2	

-- ������� ����������
      SELECT LTRIM (st.text) AS 'Command Text',[host_name], der.session_id AS 'SPID',
      der.status, db_name(database_id) AS DatabaseName, ISNULL(der.wait_type, 'None')AS 'Wait Type', der.logical_reads 
      FROM sys.dm_exec_requests AS der
      INNER JOIN sys.dm_exec_connections AS dexc
      ON der.session_id = dexc.session_id
      INNER JOIN sys.dm_exec_sessions AS dexs
      ON dexs.session_id = der.session_id
      CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS st
      WHERE der.session_id >= 51
      AND der.session_id <> @@spid
      ORDER BY der.status

	