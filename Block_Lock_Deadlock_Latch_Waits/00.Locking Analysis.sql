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


/*
Shows blocked and blocking processes. Even if it works across all database, ObjectName 
populates for current database only. Could be modified with dynamic SQL if needed

Be careful with Query text for BLOCKING session. This represents currently active
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

-- Get the statement by handle
declare
	@H varbinary(max) = 0x03000b000a37e129e3e2260172a1000001000000000000000000000000000000000000000000000000000000
	,@S int = 438
	,@E int = 564

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
where
	qs.sql_handle = @H and qs.statement_start_offset = @S and qs.statement_end_offset = @E
option (recompile)  


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