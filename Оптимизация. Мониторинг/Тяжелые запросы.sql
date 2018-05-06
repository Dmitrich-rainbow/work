
-- Тяжелые запросы по CPU и тд.
SELECT TOP 10 SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
	((CASE qs.statement_end_offset
	WHEN -1 THEN DATALENGTH(qt.TEXT)
	ELSE qs.statement_end_offset
	END - qs.statement_start_offset)/2)+1),
	qs.total_elapsed_time/1000 total_elapsed_time_ms,
	qs.last_elapsed_time/1000 last_elapsed_time_ms,
	qs.max_elapsed_time/1000 max_elapsed_time_ms,
	qs.min_elapsed_time/1000 max_elapsed_time_ms,
	qs.max_worker_time,
	qs.min_worker_time,
	qs.last_worker_time,
	qs.total_worker_time,
	qs.execution_count,
	qs.total_logical_reads, qs.last_logical_reads,
	qs.total_logical_writes, qs.last_logical_writes,
	qs.total_elapsed_time/1000000 total_elapsed_time_in_S,
	qs.last_elapsed_time/1000000 last_elapsed_time_in_S,
	qs.last_execution_time,
	CAST(qp.query_plan as XML),	
	qt.[objectid] -- по данному id можно вычислить что за объект SELECT name FROM sys.objects WHERE [object_id] = 238623893
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE (qs.execution_count > 1 OR last_execution_time > GETDATE() -1)
ORDER BY (qs.total_logical_reads + qs.total_logical_writes) / qs.execution_count DESC -- по-умолчанию
-- WHERE qs.last_ideal_grant_kb > total_grant_kb -- Найти запросы которым не хватило памяти
-- ORDER BY qs.total_logical_writes DESC -- logical writes
-- ORDER BY qs.total_worker_time DESC -- CPU time
-- ORDER BY total_elapsed_time_ms DESC -- Общее время выполнения
-- ORDER BY total_grant_kb DESC  -- по Memory
-- ORDER BY last_grant_kb * last_dop DESC -- Дорогие запросы учитывая параллелизм


-- Тяжелые запросы по CPU c пониманием объекта
	SELECT TOP 100
    query_hash, query_plan_hash,
    cached_plan_object_count,
    execution_count,
    total_cpu_time_ms, total_elapsed_time_ms,
    total_logical_reads, total_logical_writes, total_physical_reads,
    sample_database_name, sample_object_name,
    sample_statement_text
	FROM
	(
		SELECT
			query_hash, query_plan_hash,
			COUNT (*) AS cached_plan_object_count,
			MAX (plan_handle) AS sample_plan_handle,
			SUM (execution_count) AS execution_count,
			SUM (total_worker_time)/1000 AS total_cpu_time_ms,
			SUM (total_elapsed_time)/1000 AS total_elapsed_time_ms,
			SUM (total_logical_reads) AS total_logical_reads,
			SUM (total_logical_writes) AS total_logical_writes,
			SUM (total_physical_reads) AS total_physical_reads
		FROM sys.dm_exec_query_stats
		GROUP BY query_hash, query_plan_hash
	) AS plan_hash_stats
	CROSS APPLY
	(
		SELECT TOP 1
			qs.sql_handle AS sample_sql_handle,
			qs.statement_start_offset AS sample_statement_start_offset,
			qs.statement_end_offset AS sample_statement_end_offset,
			CASE
				WHEN [database_id].value = 32768 THEN 'ResourceDb'
				ELSE DB_NAME (CONVERT (int, [database_id].value))
			END AS sample_database_name,
			OBJECT_NAME (CONVERT (int, [object_id].value), CONVERT (int, [database_id].value)) AS sample_object_name,
			SUBSTRING (
				sql.[text],
				(qs.statement_start_offset/2) + 1,
				(
					(
						CASE qs.statement_end_offset
							WHEN -1 THEN DATALENGTH(sql.[text])
							WHEN 0 THEN DATALENGTH(sql.[text])
							ELSE qs.statement_end_offset
						END
						- qs.statement_start_offset
					)/2
				) + 1
			) AS sample_statement_text
		FROM sys.dm_exec_sql_text(plan_hash_stats.sample_plan_handle) AS sql 
		INNER JOIN sys.dm_exec_query_stats AS qs ON qs.plan_handle = plan_hash_stats.sample_plan_handle
		CROSS APPLY sys.dm_exec_plan_attributes (plan_hash_stats.sample_plan_handle) AS [object_id]
		CROSS APPLY sys.dm_exec_plan_attributes (plan_hash_stats.sample_plan_handle) AS [database_id]
		WHERE [object_id].attribute = 'objectid'
			AND [database_id].attribute = 'dbid'
	) AS sample_query_text
	ORDER BY total_cpu_time_ms DESC;

-- Запросы, страдающие от блокировки
	SELECT TOP 10
		   [Average Time Blocked] = (total_elapsed_time - total_worker_time) / qs.execution_count,
		   [Total Time Blocked] = total_elapsed_time - total_worker_time,
		   [Execution count] = qs.execution_count,
		   [Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
			 (CASE
				WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
				ELSE qs.statement_end_offset
			  END - qs.statement_start_offset)/2),
		   [Parent Query] = qt.text,
		   [DatabaseName] = DB_NAME(qt.dbid)
	  FROM sys.dm_exec_query_stats qs
	  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
	  ORDER BY [Average Time Blocked] DESC;

-- Одиночные тяжелые запросы по памяти
	select top (50)
		[text] as [QueryText], cp.objtype, cp.size_in_bytes
	from	sys.dm_exec_cached_plans as cp with (nolock)
			cross apply sys.dm_exec_sql_text(plan_handle)
	where	cp.cacheobjtype = N'Compiled Plan'
			and cp.objtype in (N'Adhoc', N'Prepared')
			and cp.usecounts = 1
	order by cp.size_in_bytes desc 
	option	(recompile);

-- Now lets try it based on aggregated time and
-- look for several executes
SELECT TOP 5
        [qs].[query_hash],
        SUM([qs].[total_worker_time]) AS [total_worker_time],
        SUM([qs].[execution_count]) AS [total_execution_count]
FROM    [sys].[dm_exec_query_stats] AS [qs]
CROSS APPLY [sys].[dm_exec_sql_text]([qs].[sql_handle]) AS [qt]
GROUP BY [query_hash]
HAVING  SUM([qs].[execution_count]) > 100
ORDER BY SUM([qs].[total_worker_time]) DESC;

-- Plug in query hash for an example
SELECT  SUBSTRING([qt].[text], [qs].[statement_start_offset] / 2,
                  (CASE WHEN [qs].[statement_end_offset] = -1
                        THEN LEN(CONVERT(NVARCHAR(MAX), [qt].[text])) * 2
                        ELSE [qs].[statement_end_offset]
                   END - [qs].[statement_start_offset]) / 2) AS [statement],
        [qs].[total_worker_time],
        [qs].[execution_count],
        [qs].[query_hash],
        [qs].[query_plan_hash]
FROM    [sys].[dm_exec_query_stats] AS qs
CROSS APPLY [sys].[dm_exec_sql_text]([qs].[sql_handle]) AS qt
WHERE   [query_hash] = 0x4B8B513764CB9F4C;

-- Потребление памяти
	-- Посмотреть кто съедает память
	SELECT * FROM sys.dm_exec_query_memory_grants

	-- Посмотреть запрос того, кто съедает память
	SELECT * FROM sys.dm_exec_sql_text(sql_handle)

	-- Посмотреть счётчики недостаточности памяти
	SELECT OBJECT_NAME,cntr_value AS [Memory Grants Pending]
	FROM sys.dm_os_performance_counters
	WHERE OBJECT_NAME = 'MSSQL$ABS1P:Memory Manager'
	AND counter_name = 'Memory Grants Pending'


-- Запросы, которые потребляют много CPU (те, что сейчас в кэше) (осторожно, может сильно съесть место в tempdb)
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
		WITH XMLNAMESPACES 
		(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
		SELECT --TOP 10		
		qs.creation_time,
		CompileTime_ms,
		CompileCPU_ms,
		CompileMemory_KB,
		qs.execution_count,
		qs.total_elapsed_time/1000 AS duration_ms,
		qs.total_worker_time/1000 as cputime_ms,
		(qs.total_elapsed_time/qs.execution_count)/1000 AS avg_duration_ms,
		(qs.total_worker_time/qs.execution_count)/1000 AS avg_cputime_ms,
		qs.max_elapsed_time/1000 AS max_duration_ms,
		qs.max_worker_time/1000 AS max_cputime_ms,
		qs.min_logical_reads,
		qs.max_logical_reads,
		qs.total_logical_reads,
		SUBSTRING(st.text, (qs.statement_start_offset / 2) + 1,
		(CASE qs.statement_end_offset
		WHEN -1 THEN DATALENGTH(st.text)
		ELSE qs.statement_end_offset
		END - qs.statement_start_offset) / 2 + 1) AS StmtText,
		query_hash,
		query_plan_hash,
		CAST (tab.query_plan as XML) as query_plan
		FROM
		(
		SELECT 
		c.value('xs:hexBinary(substring((@QueryHash)[1],3))', 'varbinary(max)') AS QueryHash,
		c.value('xs:hexBinary(substring((@QueryPlanHash)[1],3))', 'varbinary(max)') AS QueryPlanHash,
		c.value('(QueryPlan/@CompileTime)[1]', 'int') AS CompileTime_ms,
		c.value('(QueryPlan/@CompileCPU)[1]', 'int') AS CompileCPU_ms,
		c.value('(QueryPlan/@CompileMemory)[1]', 'int') AS CompileMemory_KB,
		qp.query_plan
		FROM sys.dm_exec_cached_plans AS cp
		CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
		CROSS APPLY qp.query_plan.nodes('ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS n(c)
		) AS tab
		JOIN sys.dm_exec_query_stats AS qs
		ON tab.QueryHash = qs.query_hash
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
		ORDER BY qs.total_worker_time/1000 DESC--CompileTime_ms*qs.execution_count DESC
		OPTION(RECOMPILE, MAXDOP 1);		

				
			-- Количество компиляций и перекомпиляций	
				SELECT counter_name, cntr_value
				  FROM sys.dm_os_performance_counters
				  WHERE counter_name IN 
				  (
					'SQL Compilations/sec',
					'SQL Re-Compilations/sec'
				  );
				  
			-- Тяжелые запросы, выполняемые в данный момент
				SELECT resource_semaphore_id, -- 0 = regular, 1 = "small query"
				  pool_id,
				  available_memory_kb,
				  total_memory_kb,
				  target_memory_kb
				FROM sys.dm_exec_query_resource_semaphores;

				SELECT StmtText = SUBSTRING(st.[text], (qs.statement_start_offset / 2) + 1,
						(CASE qs.statement_end_offset
						  WHEN -1 THEN DATALENGTH(st.text) ELSE qs.statement_end_offset
						 END - qs.statement_start_offset) / 2 + 1),
				  r.start_time, r.[status], DB_NAME(r.database_id), r.wait_type, 
				  r.last_wait_type, r.total_elapsed_time, r.granted_query_memory,
				  m.requested_memory_kb, m.granted_memory_kb, m.required_memory_kb,
				  m.used_memory_kb
				FROM sys.dm_exec_requests AS r
				INNER JOIN sys.dm_exec_query_stats AS qs
				ON r.plan_handle = qs.plan_handle
				INNER JOIN sys.dm_exec_query_memory_grants AS m
				ON r.request_id = m.request_id
				AND r.plan_handle = m.plan_handle
				CROSS APPLY sys.dm_exec_sql_text(r.plan_handle) AS st;
				
			-- Тяжелые запросы, выполняемые в данный момент (кэш)
				SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

				;WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
				SELECT TOP (10) CompileTime_ms, CompileCPU_ms, CompileMemory_KB,
				  qs.execution_count,
				  qs.total_elapsed_time/1000.0 AS duration_ms,
				  qs.total_worker_time/1000.0 as cputime_ms,
				  (qs.total_elapsed_time/qs.execution_count)/1000.0 AS avg_duration_ms,
				  (qs.total_worker_time/qs.execution_count)/1000.0 AS avg_cputime_ms,
				  qs.max_elapsed_time/1000.0 AS max_duration_ms,
				  qs.max_worker_time/1000.0 AS max_cputime_ms,
				  SUBSTRING(st.text, (qs.statement_start_offset / 2) + 1,
					(CASE qs.statement_end_offset
					  WHEN -1 THEN DATALENGTH(st.text) ELSE qs.statement_end_offset
					 END - qs.statement_start_offset) / 2 + 1) AS StmtText,
				  query_hash, query_plan_hash
				FROM
				(
				  SELECT 
					c.value('xs:hexBinary(substring((@QueryHash)[1],3))', 'varbinary(max)') AS QueryHash,
					c.value('xs:hexBinary(substring((@QueryPlanHash)[1],3))', 'varbinary(max)') AS QueryPlanHash,
					c.value('(QueryPlan/@CompileTime)[1]', 'int') AS CompileTime_ms,
					c.value('(QueryPlan/@CompileCPU)[1]', 'int') AS CompileCPU_ms,
					c.value('(QueryPlan/@CompileMemory)[1]', 'int') AS CompileMemory_KB,
					qp.query_plan
				FROM sys.dm_exec_cached_plans AS cp
				CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
				CROSS APPLY qp.query_plan.nodes('ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS n(c)
				) AS tab
				JOIN sys.dm_exec_query_stats AS qs ON tab.QueryHash = qs.query_hash
				CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
				ORDER BY CompileMemory_KB DESC
				OPTION (RECOMPILE, MAXDOP 1);
				
-- Поиск запросов, которые достигли timeout по времени оптимизации
	SELECT  DB_NAME(detqp.dbid), 
			SUBSTRING(dest.text, (deqs.statement_start_offset / 2) + 1, 
					  (CASE deqs.statement_end_offset 
						 WHEN -1 THEN DATALENGTH(dest.text) 
						 ELSE deqs.statement_end_offset 
					   END - deqs.statement_start_offset) / 2 + 1) AS StatementText, 
			CAST(detqp.query_plan AS XML), 
			deqs.execution_count, 
			deqs.total_elapsed_time, 
			deqs.total_logical_reads, 
			deqs.total_logical_writes 
	FROM    sys.dm_exec_query_stats AS deqs 
			CROSS APPLY sys.dm_exec_text_query_plan(deqs.plan_handle, 
													deqs.statement_start_offset, 
													deqs.statement_end_offset) AS detqp 
			CROSS APPLY sys.dm_exec_sql_text(deqs.sql_handle) AS dest 
	WHERE   detqp.query_plan LIKE '%StatementOptmEarlyAbortReason="TimeOut"%';