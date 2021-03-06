USE MASTER
GO

-- От кого запущен экземпляр
	sp_MSGetServerProperties
	
GO

SELECT @@VERSION

GO
xp_readerrorlog 0, 1, N'Server is listening on'
GO

-- Backup
select
	  database_name,MAX(backup_finish_date)
from msdb..backupset bs
	group by database_name
	order by database_name --desc --, Last_backup_finish_date

GO

sp_helpdb

-- Disk
SELECT DB_NAME(dm_io_virtual_file_stats.database_id) AS [Database Name], dm_io_virtual_file_stats.file_id,f.name,f.physical_name, io_stall_read_ms, num_of_reads,
	CAST(io_stall_read_ms/(1.0 + num_of_reads) AS NUMERIC(10,1)) AS [avg_read_stall_ms],io_stall_write_ms, 
	num_of_writes,CAST(io_stall_write_ms/(1.0+num_of_writes) AS NUMERIC(10,1)) AS [avg_write_stall_ms],
	io_stall_read_ms + io_stall_write_ms AS [io_stalls], num_of_reads + num_of_writes AS [total_io],
	CAST((io_stall_read_ms + io_stall_write_ms)/(1.0 + num_of_reads + num_of_writes) AS NUMERIC(10,1)) 
	AS [avg_io_stall_ms]
	--INTO virtual_file_stats
	FROM sys.dm_io_virtual_file_stats(null,null) INNER JOIN sys.master_files as f ON dm_io_virtual_file_stats.database_id = f.database_id AND dm_io_virtual_file_stats.file_id = f.file_id
	ORDER BY io_stalls DESC,avg_io_stall_ms DESC;


-- memory
		WITH    RingBuffer
          AS (SELECT    CAST(dorb.record AS XML) AS xRecord,
                        dorb.TIMESTAMP
              FROM      sys.dm_os_ring_buffers AS dorb
              WHERE     dorb.ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR'
             )
    SELECT  xr.value('(ResourceMonitor/Notification)[1]', 'varchar(75)') AS RmNotification,
            xr.value('(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint') AS IndicatorsProcess,
            xr.value('(ResourceMonitor/IndicatorsSystem)[1]', 'tinyint') AS IndicatorsSystem,
            DATEADD(ss,
                    (-1 * ((dosi.cpu_ticks / CONVERT (FLOAT, (dosi.cpu_ticks / dosi.ms_ticks)))
                           - rb.TIMESTAMP) / 1000), GETDATE()) AS RmDateTime,
            xr.value('(MemoryNode/TargetMemory)[1]', 'bigint') AS TargetMemory,
            xr.value('(MemoryNode/ReserveMemory)[1]', 'bigint') AS ReserveMemory,
            xr.value('(MemoryNode/CommittedMemory)[1]', 'bigint')/1024 AS CommitedMemory,
            xr.value('(MemoryNode/SharedMemory)[1]', 'bigint') AS SharedMemory,
            xr.value('(MemoryNode/PagesMemory)[1]', 'bigint') AS PagesMemory,
            xr.value('(MemoryRecord/MemoryUtilization)[1]', 'bigint') AS MemoryUtilization,
            xr.value('(MemoryRecord/TotalPhysicalMemory)[1]', 'bigint') AS TotalPhysicalMemory,
            xr.value('(MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint') AS AvailablePhysicalMemory,
            xr.value('(MemoryRecord/TotalPageFile)[1]', 'bigint') AS TotalPageFile,
            xr.value('(MemoryRecord/AvailablePageFile)[1]', 'bigint') AS AvailablePageFile,
            xr.value('(MemoryRecord/TotalVirtualAddressSpace)[1]', 'bigint') AS TotalVirtualAddressSpace,
            xr.value('(MemoryRecord/AvailableVirtualAddressSpace)[1]',
                     'bigint') AS AvailableVirtualAddressSpace,
            xr.value('(MemoryRecord/AvailableExtendedVirtualAddressSpace)[1]',
                     'bigint') AS AvailableExtendedVirtualAddressSpace
    FROM    RingBuffer AS rb
            CROSS APPLY rb.xRecord.nodes('Record') record (xr)
            CROSS JOIN sys.dm_os_sys_info AS dosi
    ORDER BY RmDateTime DESC;

-- Использование в данный момент памяти
	SELECT  
		(physical_memory_in_use_kb/1024) AS Memory_usedby_Sqlserver_MB,  
		(locked_page_allocations_kb/1024) AS Locked_pages_used_Sqlserver_MB,  
		(total_virtual_address_space_kb/1024) AS Total_VAS_in_MB,  
		process_physical_memory_low,  
		process_virtual_memory_low  
	FROM sys.dm_os_process_memory;  


WITH [Waits] AS
		(SELECT
			[wait_type],
			[wait_time_ms] / 1000.0 AS [WaitS],
			([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
			[signal_wait_time_ms] / 1000.0 AS [SignalS],
			[waiting_tasks_count] AS [WaitCount],
			100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
			ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
		FROM sys.dm_os_wait_stats
		WHERE [wait_type] NOT IN (
			N'BROKER_EVENTHANDLER',             N'BROKER_RECEIVE_WAITFOR',
			N'BROKER_TASK_STOP',                N'BROKER_TO_FLUSH',
			N'BROKER_TRANSMITTER',              N'CHECKPOINT_QUEUE',
			N'CHKPT',                           N'CLR_AUTO_EVENT',
			N'CLR_MANUAL_EVENT',                N'CLR_SEMAPHORE',
			N'DBMIRROR_DBM_EVENT',              N'DBMIRROR_EVENTS_QUEUE',
			N'DBMIRROR_WORKER_QUEUE',           N'DBMIRRORING_CMD',
			N'DIRTY_PAGE_POLL',                 N'DISPATCHER_QUEUE_SEMAPHORE',
			N'EXECSYNC',                        N'FSAGENT',
			N'FT_IFTS_SCHEDULER_IDLE_WAIT',     N'FT_IFTSHC_MUTEX',
			N'HADR_CLUSAPI_CALL',               N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
			N'HADR_LOGCAPTURE_WAIT',            N'HADR_NOTIFICATION_DEQUEUE',
			N'HADR_TIMER_TASK',                 N'HADR_WORK_QUEUE',
			N'KSOURCE_WAKEUP',                  N'LAZYWRITER_SLEEP',
			N'LOGMGR_QUEUE',                    N'ONDEMAND_TASK_QUEUE',
			N'PWAIT_ALL_COMPONENTS_INITIALIZED',
			N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
			N'QDS_SHUTDOWN_QUEUE',
			N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
			N'REQUEST_FOR_DEADLOCK_SEARCH',     N'RESOURCE_QUEUE',
			N'SERVER_IDLE_CHECK',               N'SLEEP_BPOOL_FLUSH',
			N'SLEEP_DBSTARTUP',                 N'SLEEP_DCOMSTARTUP',
			N'SLEEP_MASTERDBREADY',             N'SLEEP_MASTERMDREADY',
			N'SLEEP_MASTERUPGRADED',            N'SLEEP_MSDBSTARTUP',
			N'SLEEP_SYSTEMTASK',                N'SLEEP_TASK',
			N'SLEEP_TEMPDBSTARTUP',             N'SNI_HTTP_ACCEPT',
			N'SP_SERVER_DIAGNOSTICS_SLEEP',     N'SQLTRACE_BUFFER_FLUSH',
			N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
			N'SQLTRACE_WAIT_ENTRIES',           N'WAIT_FOR_RESULTS',
			N'WAITFOR',                         N'WAITFOR_TASKSHUTDOWN',
			N'WAIT_XTP_HOST_WAIT',              N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
			N'WAIT_XTP_CKPT_CLOSE',             N'XE_DISPATCHER_JOIN',
			N'XE_DISPATCHER_WAIT',              N'XE_TIMER_EVENT')
		AND [waiting_tasks_count] > 0
	 )
	SELECT
		MAX ([W1].[wait_type]) AS [WaitType],
		CAST (MAX ([W1].[WaitS]) AS DECIMAL (16,2)) AS [Wait_S],
		CAST (MAX ([W1].[ResourceS]) AS DECIMAL (16,2)) AS [Resource_S],
		CAST (MAX ([W1].[SignalS]) AS DECIMAL (16,2)) AS [Signal_S],
		MAX ([W1].[WaitCount]) AS [WaitCount],
		CAST (MAX ([W1].[Percentage]) AS DECIMAL (5,2)) AS [Percentage],
		CAST ((MAX ([W1].[WaitS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgWait_S],
		CAST ((MAX ([W1].[ResourceS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgRes_S],
		CAST ((MAX ([W1].[SignalS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgSig_S]
	FROM [Waits] AS [W1]
	INNER JOIN [Waits] AS [W2]
		ON [W2].[RowNum] <= [W1].[RowNum]
	GROUP BY [W1].[RowNum]
	HAVING SUM ([W2].[Percentage]) - MAX ([W1].[Percentage]) < 95; -- percentage threshold
	GO


WITH Latches AS
		(SELECT
			latch_class,
			wait_time_ms / 1000.0 AS WaitS,
			waiting_requests_count AS WaitCount,
			100.0 * wait_time_ms / SUM (wait_time_ms) OVER() AS Percentage,
			ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS RowNum
		FROM sys.dm_os_latch_stats
		WHERE latch_class NOT IN (
			'BUFFER')
		AND wait_time_ms > 0
		)
	SELECT
		W1.latch_class AS LatchClass, 
		CAST (W1.WaitS AS DECIMAL(14, 2)) AS Wait_S,
		W1.WaitCount AS WaitCount,
		CAST (W1.Percentage AS DECIMAL(14, 2)) AS Percentage,
		CAST ((W1.WaitS / W1.WaitCount) AS DECIMAL (14, 4)) AS AvgWait_S
	FROM Latches AS W1
	INNER JOIN Latches AS W2
		ON W2.RowNum <= W1.RowNum
	WHERE W1.WaitCount > 0
	GROUP BY W1.RowNum, W1.latch_class, W1.WaitS, W1.WaitCount, W1.Percentage
	HAVING SUM (W2.Percentage) - W1.Percentage < 95; -- percentage threshold
	GO

SELECT * FROM sys.master_files WHERE name like '%temp%'

