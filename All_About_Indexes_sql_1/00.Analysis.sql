/**********************************************************************
SQL Server Internals from the Practical Angle

Dmitri Korotkevitch
http://aboutsqlserver.com
dmitri@aboutsqlserver.com

Practical Troubleshooting: Analysis scripts
**********************************************************************/

/*
Glenn Berry: SQL Server Diagnostic Queries is the good starting point
http://sqlserverperformance.wordpress.com/tag/dmv-queries/
*/

/*
-- Clearing Proc Cache - be careful in production
dbcc freeproccache
go

-- Clearing buffer pool - do not run in production
dbcc dropcleanbuffers
go

-- Clearing wait Statistics
DBCC SQLPERF ('sys.dm_os_wait_stats', CLEAR)
go

-- Clearing latch statistics
DBCC SQLPERF ('sys.dm_os_latch_stats', CLEAR)
go

*/

-- Get top waits in the system
SELECT 
	wait_type, wait_time_ms, waiting_tasks_count, 
	case when waiting_tasks_count = 0 then 0 else wait_time_ms / waiting_tasks_count end as [Avg Wait Time (ms)],
	convert(decimal(7,4), 100.0 * wait_time_ms / SUM(wait_time_ms) OVER()) AS [Percent]
from 
	 sys.dm_os_wait_stats with (nolock)
where 
	wait_type NOT IN ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK'
	,'SLEEP_SYSTEMTASK','SQLTRACE_BUFFER_FLUSH','WAITFOR', 'LOGMGR_QUEUE','CHECKPOINT_QUEUE'
	,'REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TO_FLUSH','BROKER_TASK_STOP',
	'CLR_MANUAL_EVENT','CLR_AUTO_EVENT','DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT'
	,'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN','BROKER_EVENTHANDLER','SLEEP_DBSTARTUP', 'TRACEWRITE'
	,'HADR_FILESTREAM_IOMGR_IOCOMPLETION','DIRTY_PAGE_POLL','SQLTRACE_INCREMENTAL_FLUSH_SLEEP'
	-- Wait type below excluded because of the limitations of the demo environment. 
	-- You should analyze those waits in real time troubleshooting
	,'SOS_SCHEDULER_YIELD'
	)
	and wait_type NOT like 'PREEMPTIVE%'
order by 
	[Percent] desc
option (recompile)    
go

-- % of Signal Waits vs. Resource Waits. High percent of Signal Waits means CPU Bottleneck
select 
	sum(signal_wait_time_ms) as [Signal Wait Time (ms)]
	,convert(decimal(7,4), 100.0 * sum(signal_wait_time_ms) / sum (wait_time_ms)) as [% Signal waits]
	,sum(wait_time_ms - signal_wait_time_ms) as [Resource Wait Time (ms)]
	,convert(decimal(7,4), 100.0 * sum(wait_time_ms - signal_wait_time_ms) / sum (wait_time_ms)) as [% Resource waits]
from
	sys.dm_os_wait_stats with (nolock)
option (recompile)
go

-- Calculates average stalls per read, per write, and per total input/output for each database file 
select	db_name(fs.database_id) as [Database Name], mf.physical_name,
		io_stall_read_ms, num_of_reads,
		cast(io_stall_read_ms / (1.0 + num_of_reads) as numeric(10, 1)) as [avg_read_stall_ms],
		io_stall_write_ms, num_of_writes,
		cast(io_stall_write_ms / (1.0 + num_of_writes) as numeric(10, 1)) as [avg_write_stall_ms],
		io_stall_read_ms + io_stall_write_ms as [io_stalls],
		num_of_reads + num_of_writes as [total_io],
		cast((io_stall_read_ms + io_stall_write_ms) / (1.0 + num_of_reads
													   + num_of_writes) as numeric(10,
															  1)) as [avg_io_stall_ms]
from	sys.dm_io_virtual_file_stats(null, null) as fs
		inner join sys.master_files as mf with (nolock)
		on fs.database_id = mf.database_id
		   and fs.[file_id] = mf.[file_id]
order by avg_io_stall_ms desc 
option	(recompile);

-- select top 50 most expensive queries. This is the version that
-- works in SQL 2005+. There are a few other useful columns in the higher versions
-- of SQL Server. 
SELECT TOP 50 
	SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
		((
			CASE qs.statement_end_offset
				WHEN -1 THEN DATALENGTH(qt.TEXT)
				ELSE qs.statement_end_offset
			END - qs.statement_start_offset)/2)+1) as SQL,
	qs.execution_count,
	(qs.total_logical_reads + qs.total_logical_writes) / qs.execution_count as [Avg IO],
	qp.query_plan,
	qs.total_logical_reads, qs.last_logical_reads,
	qs.total_logical_writes, qs.last_logical_writes,
	qs.total_worker_time,
	qs.last_worker_time,
	qs.total_elapsed_time/1000 total_elapsed_time_in_ms,
	qs.last_elapsed_time/1000 last_elapsed_time_in_ms,
	qs.last_execution_time
FROM 
	sys.dm_exec_query_stats qs with (nolock)
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
		OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY -- change order by to sort by different criteria than IO
	[Avg IO] desc
 option (recompile)  
go



/* Set blocked process threashold to 5 seconds. Required for Blocked Process event in SQL Profiler */
use master
go

sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
sp_configure 'blocked process threshold', 5
GO
RECONFIGURE
GO


use SqlServerInternals
go

select
	TL1.resource_type
	,DB_NAME(TL1.resource_database_id) as [DB Name]
	,CASE TL1.resource_type
		WHEN 'OBJECT' THEN OBJECT_NAME(TL1.resource_associated_entity_id, TL1.resource_database_id)
		WHEN 'DATABASE' THEN 'DB'
		ELSE
			CASE 
				WHEN TL1.resource_database_id = DB_ID() 
				THEN
					(
						select OBJECT_NAME(object_id, TL1.resource_database_id)
						from sys.partitions
						where hobt_id = TL1.resource_associated_entity_id
					)
				ELSE
					'(Run under DB context)'
			END
	END as ObjectName
	,TL1.resource_description
	,TL1.request_session_id
	,TL1.request_mode
	,TL1.request_status
	,WT.wait_duration_ms as [Wait Duration (ms)]
	,(
		select
			SUBSTRING(
				S.Text, 
				(ER.statement_start_offset / 2) + 1,
				((
					CASE 
						ER.statement_end_offset
					WHEN -1 
						THEN DATALENGTH(S.text)
						ELSE ER.statement_end_offset
					END - ER.statement_start_offset) / 2) + 1)		
		from 
			sys.dm_exec_requests ER with (nolock)
				cross apply sys.dm_exec_sql_text(ER.sql_handle) S
		where
			TL1.request_session_id = ER.session_id
	 ) as [Query]
from
	sys.dm_tran_locks TL1 with (nolock) join sys.dm_tran_locks TL2 with (nolock) on
		TL1.resource_associated_entity_id = TL2.resource_associated_entity_id
	left outer join sys.dm_os_waiting_tasks WT with (nolock) on
		TL1.lock_owner_address = WT.resource_address and TL1.request_status = 'WAIT'

where
	TL1.request_status <> TL2.request_status and
	(
		TL1.resource_description = TL2.resource_description OR
		(TL1.resource_description is null and TL2.resource_description is null)
	)
option (recompile)
go

/*
Shows current locks. Even if it works across all database, ObjectName 
populates for current database only. Could be modified with dynamic SQL if needed

Be careful with Query text for LOCKS with GRANT status. This represents currently active
request for this specific session id which could be different than query which produced locks
It also could be NULL if there are no active requests for this session
*/

select
	TL1.resource_type
	,DB_NAME(TL1.resource_database_id) as [DB Name]
	,CASE TL1.resource_type
		WHEN 'OBJECT' THEN OBJECT_NAME(TL1.resource_associated_entity_id, TL1.resource_database_id)
		WHEN 'DATABASE' THEN 'DB'
		ELSE
			CASE 
				WHEN TL1.resource_database_id = DB_ID() 
				THEN
					(
						select OBJECT_NAME(object_id, TL1.resource_database_id)
						from sys.partitions
						where hobt_id = TL1.resource_associated_entity_id
					)
				ELSE
					'(Run under DB context)'
			END
	END as ObjectName
	,TL1.resource_description
	,TL1.request_session_id
	,TL1.request_mode
	,TL1.request_status
	,WT.wait_duration_ms as [Wait Duration (ms)]
	,(
		select
			SUBSTRING(
				S.Text, 
				(ER.statement_start_offset / 2) + 1,
				((
					CASE 
						ER.statement_end_offset
					WHEN -1 
						THEN DATALENGTH(S.text)
						ELSE ER.statement_end_offset
					END - ER.statement_start_offset) / 2) + 1)		
		from 
			sys.dm_exec_requests ER with (nolock)
				cross apply sys.dm_exec_sql_text(ER.sql_handle) S
		where
			TL1.request_session_id = ER.session_id
	 ) as [Query]
from
	sys.dm_tran_locks TL1 with (nolock) left outer join sys.dm_os_waiting_tasks WT with (nolock) on
		TL1.lock_owner_address = WT.resource_address and TL1.request_status = 'WAIT'
where
	TL1.request_session_id <> @@SPID
order by
	TL1.request_session_id
option (recompile)
go

-- selects 50 most memory consuming single-use plans
select top (50)
		[text] as [QueryText], cp.objtype, cp.size_in_bytes
from	sys.dm_exec_cached_plans as cp with (nolock)
		cross apply sys.dm_exec_sql_text(plan_handle)
where	cp.cacheobjtype = N'Compiled Plan'
		and cp.objtype in (N'Adhoc', N'Prepared')
		and cp.usecounts = 1
order by cp.size_in_bytes desc 
option	(recompile);
  
-- get info about memory clerks
SELECT TOP(10) [type] AS [Memory Clerk Type], 
       SUM(pages_kb) AS [SPA Mem, Kb] 
FROM sys.dm_os_memory_clerks WITH (NOLOCK)
GROUP BY [type]  
ORDER BY SUM(pages_kb) DESC OPTION (RECOMPILE);

-- Get info about tables
;with TableInfo
as
(
	select 
		t.object_id as [ObjectId], i.index_id as [IndexId],
		t.NAME AS [TableName], i.name as [CIName], p.[Rows],
		i.is_unique as [CI unique], i.fill_factor,
		t.Lock_Escalation_Desc as [Lock Escalation],
		sum(a.total_pages) as TotalPages, 
		sum(a.used_pages) as UsedPages, 
		sum(a.data_pages) as DataPages,
		(sum(a.total_pages) * 8) / 1024 as TotalSpaceMB, 
		(sum(a.used_pages) * 8) / 1024 as UsedSpaceMB, 
		(sum(a.data_pages) * 8) / 1024 as DataSpaceMB
	from 
		sys.tables t join sys.indexes i on
			t.OBJECT_ID = i.object_id
		join sys.partitions p on 
			i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
		join sys.allocation_units a on 
			p.partition_id = a.container_id
	where
		t.NAME NOT LIKE 'dt%' and
		i.OBJECT_ID > 255 and 	
		i.index_id <= 1
	group by
		t.NAME, i.object_id, i.index_id, i.name, p.[Rows],
		i.is_unique, i.fill_factor, t.Lock_Escalation_Desc,
		t.object_id, i.index_id
)
select ic.GUIDThere, ti.*
from 
	TableInfo ti cross apply
	(
		select
			case
				when exists(
					select * 
					from 
						sys.index_columns ic join sys.columns c on	
							ic.object_id = c.object_id and
							ic.column_id = c.column_id  
					where 
						ic.object_id = ti.objectid and 
						ic.index_id = ti.indexid and 
						c.system_type_id = 36 --uniqueidentifier
				)
				then 'Yes'
				else 'No'
			end as [GuidThere]

	) ic  
order by 
	ti.TableName
go
