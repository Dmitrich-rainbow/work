-- Информация о всех подключениях
	sys.dm_exec_connections

-- Анализирование статистики (подробнее - Статистика.sql)
	sys.system_internals_partition_columns 
	sys.dm_db_index_operational_stats
	sys.dm_db_stats_properties

-- *****DMV/DMF*****

-- Clear Wait Stats 
	DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);

-- Возвращает по строке на каждый счетчик производительности с собранной статистикой
	SELECT * FROM sys.dm_os_performance_counters

-- Статистика использования планов
	sys.dm_exec_cached_plans
	sys.dm_exec_cached_plan_dependent_objects 

-- Статистика по выполненным запросам
	sys.dm_exec_procedure_stats 
	sys.dm_exec_query_stats - суммарная статистика производительности для кэшированного плана запроса

-- Активные запросы/запущенные запрос
	sys.dm_exec_requests - информация о каждом запросе

-- Запросы требуют многого, а потом этим не пользуются (только настоящий момент)
	sys.dm_exec_query_memory_grants 

-- Определение полезности индексов (текущая активность IO, блокировки и кратковременные блокировки
-- по секции индекса или таблицы)
	SELECT * FROM sys.dm_db_index_operational_stats(NULL, NULL, NULL, NULL);

-- Статистика
	sys.dm_os_wait_stats - данные обо всех случаях ожидания
	sys.dm_os_waiting_tasks - сведения об очереди задач, ожидающих освобождение определённого ресурса
	
-- sys.dm_exec_sessions . Текущие подключения/пользователи
	- Returns one row per authenticated session on SQL Server. sys.dm_exec_sessions is a server-scope view that shows information about all active user connections and internal tasks. This information includes client version, client program name, client login time, login user, current session setting, and more.

-- sys.dm_os_loaded_modules 	
	- Показывает подключенные к серверу dll	
	
-- sys.dm_os_volume_stats
	- sys.dm_os_volume_stats (database_id, file_id)
	- Возвращает сведения о томе (каталоге) операционной системы, в котором хранятся указанные базы данных и файлы SQL Server. Используйте эту функцию динамического управления для проверки атрибутов физического диска или для получения сведений об объеме свободного пространства в каталоге.
	- Смотреть автоувеличение файла

-- sys.ysprocesses
	- Содержит сведения о процессах, которые выполняются в экземпляре SQL Server. Эти процессы могут быть клиентскими или системными
		SELECT * FROM sys.sysprocesses
	
	-- Как много пользователей сидит под опеределённым логином
		SELECT login_name, COUNT(session_id) AS [session_count] 
		FROM sys.dm_exec_sessions 
		GROUP BY login_name
		ORDER BY COUNT(session_id) DESC;
	
-- sys.dm_os_sys_info
	- This query tells you how many physical and logical CPUs you have on your SQL Server instance. It also gives you the hyperthread_ratio and the amount of physical RAM, along with the last SQL Server Start time
	
	-- Общая информация о сервере
		SELECT cpu_count AS [Logical CPU Count], hyperthread_ratio AS [Hyperthread Ratio],
		cpu_count/hyperthread_ratio AS [Physical CPU Count], 
		physical_memory_in_bytes/1048576 AS [Physical Memory (MB)], sqlserver_start_time
		FROM sys.dm_os_sys_info;
		
-- sys.dm_os_sys_memory
	- Returns memory information from the operating system. SQL Server is bounded by, and responds to, external memory conditions at the operating system level and the physical limits of the underlying hardware. Determining the overall system state is an important part of evaluating SQL Server memory usage.
	
	-- Состояние памяти (не очень помогает)
		SELECT total_physical_memory_kb, available_physical_memory_kb, 
			   total_page_file_kb, available_page_file_kb, 
			   system_memory_state_desc
		FROM sys.dm_os_sys_memory;
		
-- sys.dm_db_mirroring_auto_page_repair
	- Returns a row for every automatic page-repair attempt on any mirrored database on the server instance. This view contains rows for the latest automatic page-repair attempts on a given mirrored database, with a maximum of 100 rows per database. As soon as a database reaches the maximum, the row for its next automatic page-repair attempt replaces one of the existing entries.
	
	-- Общая информация
		SELECT DB_NAME(database_id) AS [database_name], 
		database_id, file_id, page_id, error_type, page_status, modification_time
		FROM sys.dm_db_mirroring_auto_page_repair; 

-- sys.dm_db_index_usage_stats
	- Returns counts of different types of index operations and the time each type of operation was last performed. Every individual seek, scan, lookup, or update on the specified index by one query execution is counted as a use of that index and increments the corresponding counter in this view. Information is reported both for operations caused by user-submitted queries, and for operations caused by internally generated queries, such as scans for gathering statistics.
	
	-- Информация об индексах в текущей базе
		SELECT OBJECT_NAME(s.[object_id]) AS [Table Name], i.name AS [Index Name], i.index_id,
		user_updates AS [Total Writes], user_seeks + user_scans + user_lookups AS [Total Reads],
		user_updates - (user_seeks + user_scans + user_lookups) AS [Difference]
		FROM sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
		INNER JOIN sys.indexes AS i WITH (NOLOCK)
		ON s.[object_id] = i.[object_id]
		AND i.index_id = s.index_id
		WHERE OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
		AND s.database_id = DB_ID()
		AND user_updates > (user_seeks + user_scans + user_lookups)
		AND i.index_id > 1
		ORDER BY [Difference] DESC, [Total Writes] DESC, [Total Reads] ASC;
		
-- sys.dm_db_missing_index_group_stats, which is described by BOL as:
	- Returns summary information about groups of missing indexes, excluding spatial indexes. Information returned by sys.dm_db_missing_index_group_stats is updated by every query execution, not by every query compilation or recompilation. Usage statistics are not persisted and are kept only until SQL Server is restarted. Database administrators should periodically make backup copies of the missing index information if they want to keep the usage statistics after server recycling.

-- sys.dm_db_missing_index_groups, which BOL describes as:
	- Returns information about what missing indexes are contained in a specific missing index group, excluding spatial indexes.

-- sys.dm_db_missing_index_group_stats and sys.dm_db_missing_index_details. The third one is sys.dm_db_missing_index_details, which BOL describes like this:
	- Returns detailed information about missing indexes, excluding spatial indexes.
	- Подробности смотри в файле Индексы.sql
		
-- sys.dm_fts_active_catalogs, which is described by BOL as:
	- Returns information on the full-text catalogs that have some population activity in progress on the server.

-- sys.dm_fts_index_population which BOL describes as:
	- Returns information about the full-text index populations currently in progress.
	
	-- Что происходит с full-text в текущей БД
		SELECT c.name, c.[status], c.status_description, OBJECT_NAME(p.table_id) AS [table_name], 
		p.population_type_description, p.is_clustered_index_scan, p.status_description, 
		p.completion_type_description, p.queued_population_type_description, 
		p.start_time, p.range_count 
		FROM sys.dm_fts_active_catalogs AS c 
		INNER JOIN sys.dm_fts_index_population AS p 
		ON c.database_id = p.database_id 
		AND c.catalog_id = p.catalog_id 
		WHERE c.database_id = DB_ID()
		ORDER BY c.name;
		
-- sys.dm_os_schedulers, which is described by BOL as:
	- Returns one row per scheduler in SQL Server where each scheduler is mapped to an individual processor. Use this view to monitor the condition of a scheduler or to identify runaway tasks.
	
	-- Количество запущенных расписаний
		SELECT AVG(current_tasks_count) AS [Avg Task Count], 
		AVG(runnable_tasks_count) AS [Avg Runnable Task Count]
		FROM sys.dm_os_schedulers
		WHERE scheduler_id < 255
		AND [status] = 'VISIBLE ONLINE';

-- sys.dm_exec_procedure_stats, which was added in SQL Server 2008, is described by BOL as:
	- Returns aggregate performance statistics for cached stored procedures. The view contains one row per stored procedure, and the lifetime of the row is as long as the stored procedure remains cached. When a stored procedure is removed from the cache, the corresponding row is eliminated from this view. At that time, a Performance Statistics SQL trace event is raised similar to sys.dm_exec_query_stats.
	
	-- 25 наиболее дорогих процедур по физическим чтениям. Берёт данные из кэша
		SELECT TOP(25) p.name AS [SP Name],qs.total_physical_reads AS [TotalPhysicalReads], 
		qs.total_physical_reads/qs.execution_count AS [AvgPhysicalReads], qs.execution_count, 
		ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0) AS [Calls/Second],
		qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count 
		AS [avg_elapsed_time], qs.cached_time 
		FROM sys.procedures AS p
		INNER JOIN sys.dm_exec_procedure_stats AS qs
		ON p.[object_id] = qs.[object_id]
		WHERE qs.database_id = DB_ID()
		ORDER BY qs.total_physical_reads DESC;
		
-- sys.dm_db_index_usage_stats, which is described by BOL as:	
	- Returns counts of different types of index operations and the time each type of operation was last performed. Every individual seek, scan, lookup, or update on the specified index by one query execution is counted as a use of that index and increments the corresponding counter in this view. Information is reported both for operations caused by user-submitted queries, and for operations caused by internally generated queries, such as scans for gathering statistics.
	-- Показать неиспользуемые индексы к базе
		SELECT OBJECT_NAME(i.[object_id]) AS [Table Name], i.name 
		FROM sys.indexes AS i
		INNER JOIN sys.objects AS o
		ON i.[object_id] = o.[object_id]
		WHERE i.index_id 
		NOT IN (SELECT s.index_id 
				FROM sys.dm_db_index_usage_stats AS s 
				WHERE s.[object_id] = i.[object_id] 
				AND i.index_id = s.index_id 
				AND database_id = DB_ID())
		AND o.[type] = 'U'
		ORDER BY OBJECT_NAME(i.[object_id]) ASC;
		
-- sys.dm_db_partition_stats, which is described by BOL as:
	- Returns page and row-count information for every partition in the current database.
	-- В каких таблицах сколько строк
		SELECT OBJECT_NAME(ps.[object_id]) AS [TableName], 
		i.name AS [IndexName], SUM(ps.row_count) AS [RowCount]
		FROM sys.dm_db_partition_stats AS ps
		INNER JOIN sys.indexes AS i 
		ON i.[object_id] = ps.[object_id] 
		AND i.index_id = ps.index_id 
		WHERE i.type_desc IN ('CLUSTERED','HEAP')
		AND i.[object_id] > 100
		AND OBJECT_SCHEMA_NAME(ps.[object_id]) <> 'sys'
		GROUP BY ps.[object_id], i.name
		ORDER BY SUM(ps.row_count) DESC;
		
-- sys.dm_io_virtual_file_stats, which is described by BOL as:
	- Задержки чтения для файла лога менее важны чем задержки записи
	- Returns I/O statistics for data and log files. This dynamic management view replaces the fn_virtualfilestats function.
	-- Статистика использования каждого файла базы данных (общая)/использование файлов (Идеально 0-8 мс чтение/запись файлов данных и 0-4 мс файлов журналов, но на практивке нормально когда 10-20. Общая опасна тем, что регламентные задания сильно увеличивают это число)/файлов по базам
		SELECT DB_NAME(dm_io_virtual_file_stats.database_id) AS [Database Name], dm_io_virtual_file_stats.file_id,f.name,f.physical_name, io_stall_read_ms, num_of_reads,
		CAST(io_stall_read_ms/(1.0 + num_of_reads) AS NUMERIC(10,1)) AS [avg_read_stall_ms],io_stall_write_ms, 
		num_of_writes,CAST(io_stall_write_ms/(1.0+num_of_writes) AS NUMERIC(10,1)) AS [avg_write_stall_ms],
		io_stall_read_ms + io_stall_write_ms AS [io_stalls], num_of_reads + num_of_writes AS [total_io],
		CAST((io_stall_read_ms + io_stall_write_ms)/(1.0 + num_of_reads + num_of_writes) AS NUMERIC(10,1)) 
		AS [avg_io_stall_ms]
		FROM sys.dm_io_virtual_file_stats(null,null) INNER JOIN sys.master_files as f ON dm_io_virtual_file_stats.database_id = f.database_id AND dm_io_virtual_file_stats.file_id = f.file_id
		ORDER BY io_stalls DESC,avg_io_stall_ms DESC;
		
		-- или (смотреть на IO Read и на IO Write Stal)
		SELECT DB_NAME(vfs.DbId) DatabaseName, mf.name,
		mf.physical_name, vfs.BytesRead, vfs.BytesWritten,
		vfs.IoStallMS, vfs.IoStallReadMS, vfs.IoStallWriteMS,
		vfs.NumberReads, vfs.NumberWrites,
		(Size*8)/1024 Size_MB
		FROM ::fn_virtualfilestats(NULL,NULL) vfs
		INNER JOIN sys.master_files mf ON mf.database_id = vfs.DbId
		AND mf.FILE_ID = vfs.FileId
		ORDER BY IoStallMS DESC;
		
	-- Лимиты задержек по мнению Paul Randal
		Excellent: < 1ms
		Very good: < 5ms
		Good: 5 – 10ms
		Poor: 10 – 20ms
		Bad: 20 – 100ms
		Shockingly bad: 100 – 500ms
		WOW!: > 500ms
			
	-- Способы решения проблемы если это касается tempdb
		1. Переместите на быстрые SSD Диски в RAID-1
		2. Проверьте каналы соединения с SAN, а лучше увеличить их и убрать инородную нагрузку
		3. Неправильные настройки SAN, такие как не включение кэширования на запись, неправильная глубина очереди
		4. Объединение LUN для tempdb с другими пользователями
		
	-- Тревожные сигналы
		1. Spill в tempdb
		2. Чрезмерное использование tempdb. Создание лишних столбцов, создание неиспользуемых индексов
		3. Перестроение индексов, использующее sort in tempdb
		4. Использование snapshot isolation level и долгих запросов
		
	-- Текущая статистика использований файлов базы данных/сбор статистики за 30 сек
		DECLARE @Reset bit = 0;
        
		IF NOT EXISTS (SELECT NULL FROM tempdb.sys.objects 
		WHERE name LIKE '%#fileStats%')  
				SET @Reset = 1;  -- force a reset

		IF @Reset = 1 BEGIN 
				IF EXISTS (SELECT NULL FROM tempdb.sys.objects 
				WHERE name LIKE '%#fileStats%')  
						DROP TABLE #fileStats;

				SELECT 
						database_id, 
						file_id, 
						num_of_reads, 
						num_of_bytes_read, 
						io_stall_read_ms, 
						num_of_writes, 
						num_of_bytes_written, 
						io_stall_write_ms, io_stall
				INTO #fileStats 
				FROM sys.dm_io_virtual_file_stats(NULL, NULL);
		END
		
		WAITFOR DELAY '00:00:30'
	
		SELECT  
				DB_NAME(vfs.database_id) AS database_name, 
				--vfs.database_id , 
				vfs.FILE_ID , 
				 NULLIF((vfs.num_of_reads - history.num_of_reads), 0) AS num_of_reads ,
				 NULLIF((vfs.num_of_writes - history.num_of_writes), 0) AS num_of_writes,
				(vfs.io_stall_read_ms - history.io_stall_read_ms)
				 / NULLIF((vfs.num_of_reads - history.num_of_reads), 0) AS  avg_read_latency, 
				(vfs.io_stall_write_ms - history.io_stall_write_ms)
				 / NULLIF((vfs.num_of_writes - history.num_of_writes), 0) AS avg_write_latency , 
				mf.physical_name 
		FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs 
						JOIN sys.master_files AS mf 
								ON vfs.database_id = mf.database_id AND vfs.FILE_ID = mf.FILE_ID 
						RIGHT OUTER JOIN #fileStats history 
								ON history.database_id = vfs.database_id AND history.file_id = vfs.file_id
		ORDER BY avg_write_latency DESC;
		
--  sys.dm_os_wait_stats, which is described by BOL as:
	- Returns information about all the waits encountered by threads that executed. You can use this aggregated view to diagnose performance issues with SQL Server and also with specific queries and batches.
	-- Общее время ожидания по ресурсам (процессор и всё остальное)
		SELECT CAST(100.0 * SUM(signal_wait_time_ms)/ SUM (wait_time_ms)AS NUMERIC(20,2)) 
		AS [%signal (cpu) waits],
		CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) 
		AS [%resource waits]
		FROM sys.dm_os_wait_stats; 
		
-- sys.dm_os_performance_counters, which is described by BOL as:
	- Returns a row per performance counter maintained by the server. For information about each performance counter, see Using SQL Server Objects.
	-- Общая информация по базам
		SELECT db.[name] AS [Database Name], db.recovery_model_desc AS [Recovery Model], 
		db.log_reuse_wait_desc AS [Log Reuse Wait Description], 
		ls.cntr_value AS [Log Size (KB)], lu.cntr_value AS [Log Used (KB)],
		CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT)AS DECIMAL(18,2)) * 100 AS [Log Used %], 
		db.[compatibility_level] AS [DB Compatibility Level], db.page_verify_option_desc AS [Page Verify Option]
		FROM sys.databases AS db
		INNER JOIN sys.dm_os_performance_counters AS lu 
		ON db.name = lu.instance_name
		INNER JOIN sys.dm_os_performance_counters AS ls 
		ON db.name = ls.instance_name
		WHERE lu.counter_name LIKE 'Log File(s) Used Size (KB)%' 
		AND ls.counter_name LIKE 'Log File(s) Size (KB)%';
		
	-- log_reuse_wait_desc (Paul Randal)/совет по использованию лога
		NOTHING: Just as it looks, this value means that SQL Server thinks there is no problem with log truncation. In our case though, the log is clearly growing, so how could we see NOTHING? Well, for this we have to understand how the log_reuse_wait_desc reporting works. The value is reporting what stopped log truncation last time it was attempted. If the value is NOTHING, it means that at least one VLF was marked inactive the last time log truncation occurred. We could have a situation where the log has a huge number of VLFs, and there are a large number of active transactions, with each one having its LOP_BEGIN_XACT log record in successive VLFs. If each time log truncation happens, a single transaction has committed, and it only manages to clear one VLF, it could be that the speed of log truncation is just waaaay slower than the speed of log record generation, and so the log is having to grow to accommodate it. I’d use my script here to see how many active transactions there are, monitor VLFs with DBCC LOGINFO, and also track the Log Truncations and Log Growths counters for the database in the Databases perfmon object. I need to see if I can engineer this case and repeatably see NOTHING.
		CHECKPOINT: This value means that a checkpoint hasn’t occurred since the last time log truncation occurred. In the simple recovery model, log truncation only happens when a checkpoint completes, so you wouldn’t normally see this value. When it can happen is if a checkpoint is taking a long time to complete and the log has to grow while the checkpoint is still running. I’ve seen this on one client system with a very poorly performing I/O subsystem and a very large buffer pool with a lot of dirty pages that needed to be flushed when the checkpoint occurred.
		LOG_BACKUP: This is one of the most common values to see, and says that you’re in the full or bulk_logged recovery model and a log backup hasn’t occurred. In those recovery models, it’s a log backup that performs log truncation. Simple stuff. I’d check to see why log backups are not being performed (disabled Agent job or changed Agent job schedule? backup failure messages in the error log?)
		ACTIVE_BACKUP_OR_RESTORE: This means that there’s a data backup running or any kind of restore running. The log can’t be truncated during a restore, and is required for data backups so can’t be truncated there either.
		ACTIVE_TRANSACTION: This means that there is a long-running transaction that is holding all the VLFs active. The way log truncation works is that it goes to the next VLF (#Y) from the last one (#X) made inactive last time log truncation works, and looks at that. If VLF #Y can’t be made inactive, then log truncation fails and the log_reuse_wait_desc value is recorded. If a long-running transaction has its LOP_BEGIN_XACT log record in VLF #Y, then no other VLFs can be made inactive either. Even if all other VLFs after VLF #Y have nothing to do with our long-running transaction – there’s no selective active vs. inactive. You can use this script to see all the active transactions.
		DATABASE_MIRRORING: This means that the database mirroring partnership has some latency in it and there are log records on the mirroring principal that haven’t yet been sent to the mirroring mirror (called the send queue). This can happen if the mirror is configured for asynchronous operation, where transactions can commit on the principal before their log records have been sent to the mirror. It can also happen in synchronous mode, if the mirror becomes disconnected or the mirroring session is suspended. The amount of log in the send queue can be equated to the expected amount of data (or work) loss in the event of a crash of the principal.
		REPLICATION: This value shows up when there are committed transactions that haven’t yet been scanned by the transaction replication Log Reader Agent job for the purpose of sending them to the replication distributor or harvesting them for Change Data Capture (which uses the same Agent job as transaction replication). The job could have been disabled, could be broken, or could have had its SQL Agent schedule changed.
		DATABASE_SNAPSHOT_CREATION: When a database snapshot is created (either manually or automatically by DBCC CHECKDB and other commands), the database snapshot is made transactionally consistent by using the database’s log to perform crash recovery into the database snapshot. The log obviously can’t be truncated while this is happening and this value will be the result. See this blog post for a bit more info.
		LOG_SCAN: This value shows up if a long-running call to fn_dblog (see here) is under way when the log truncation is attempted, or when the log is being scanned during a checkpoint.
		AVAILABILITY_REPLICA: This is the same thing as DATABASE_MIRRORING, but for an availability group (2012 onward) instead of database mirroring.
	
	-- Худшие сценарии для каждого параметра		
		NOTHING: It could be the scenario I described in the list above, but that would entail a workload change having happened for me to be surprised by it. Otherwise it could be a SQL Server bug, which is unlikely.
		CHECKPOINT: For a critical, 24×7 database, I’m likely using the full recovery model, so it’s unlikely to be this one unless someone’s switched to simple without me knowing…
		LOG_BACKUP: This would mean something had happened to the log backup job so it either isn’t running or it’s failing. Worst case here would be data loss if a catastrophic failure occurred, plus the next successful log backup is likely to be very large.
		ACTIVE_BACKUP_OR_RESTORE: As the log is growing, if this value shows up then it must be a long-running data backup. Log backups can run concurrently so I’m not worried about data loss of a problem occurs.
		ACTIVE_TRANSACTION: Worst case here is that the transaction needs to be killed and then will take a long time to roll back, producing a lot more transaction log before the log stops growing.
		DATABASE_MIRRORING: Worst case here is that a crash occurs and data/work loss occurs because of the log send queue on the principal, but only if I don’t have log backups that I can restore from. So maybe we’re looking at a trade off between some potential data loss or some potential down time (to restore from backups).
		REPLICATION: The worst case here is that replication’s got itself badly messed up for some reason and has to be fully removed from the database with sp_removedbreplication, and then reconfigured again.
		DATABASE_SNAPSHOT_CREATION: The worst case here is that there are some very long running transactions that are still being crash recovered into the database snapshot and that won’t finish for a while. It’s not possible to interrupt database snapshot creation, but it won’t affect anything in the source database apart from log truncation.
		LOG_SCAN: This is very unlikely to be a problem.
		AVAILABILITY_REPLICA: Same as for database mirroring, but we may have another replica that’s up-to-date (the availability group send queue could be for one of the asynchronous replicas that is running slowly, and we have a synchronous replica that’s up-to-date.
			
--  sys.dm_exec_cached_plans, which is described by BOL as:
	- Returns a row for each query plan that is cached by SQL Server for faster query execution. You can use this dynamic management view to find cached query plans, cached query text, the amount of memory taken by cached plans, and the reuse count of the cached plans.

--  sys.dm_exec_sql_text, which is actually a dynamic management function (DMF), that is described by BOL as:
	- Returns the text of the SQL batch that is identified by the specified sql_handle. This table-valued function replaces the system function fn_get_sql.
	-- Find single-use, ad-hoc queries that are bloating the plan cache
		SELECT TOP(100) [text], cp.size_in_bytes
		FROM sys.dm_exec_cached_plans AS cp
		CROSS APPLY sys.dm_exec_sql_text(plan_handle) 
		WHERE cp.cacheobjtype = 'Compiled Plan' 
		AND cp.objtype = 'Adhoc' 
		AND cp.usecounts = 1
		ORDER BY cp.size_in_bytes DESC;

--  sys.dm_db_index_usage_stats, which is described by BOL as:
	- Returns counts of different types of index operations and the time each type of operation was last performed.
	-- Статистика по индексам в текущей базе
		SELECT OBJECT_NAME(s.[object_id]) AS [ObjectName], i.name AS [IndexName], i.index_id,
			   user_seeks + user_scans + user_lookups AS [Reads], user_updates AS [Writes],
			   i.type_desc AS [IndexType], i.fill_factor AS [FillFactor]
		FROM sys.dm_db_index_usage_stats AS s
		INNER JOIN sys.indexes AS i
		ON s.[object_id] = i.[object_id]
		WHERE OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
		AND i.index_id = s.index_id
		AND s.database_id = DB_ID()
		ORDER BY OBJECT_NAME(s.[object_id]), writes DESC, reads DESC;
		
-- sys.dm_clr_tasks, which is described by BOL as:
	- Returns a row for all common language runtime (CLR) tasks that are currently running. A Transact-SQL batch that contains a reference to a CLR routine creates a separate task for execution of all the managed code in that batch. Multiple statements in the batch that require managed code execution use the same CLR task. The CLR task is responsible for maintaining objects and state pertaining to managed code execution, as well as the transitions between the instance of SQL Server and the common language runtime.
	-- Find long running SQL/CLR tasks (Найти долго выполняющиеся CLR)
		SELECT os.task_address, os.[state], os.last_wait_type, 
			   clr.[state], clr.forced_yield_count 
		FROM sys.dm_os_workers AS os 
		INNER JOIN sys.dm_clr_tasks AS clr 
		ON (os.task_address = clr.sos_task_address) 
		WHERE clr.[type] = 'E_TYPE_USER';
	
-- sys.dm_os_wait_stats, which is described by BOL as:/ожидания/waitings
	- Returns information about all the waits encountered by threads that executed. You can use this aggregated view to diagnose performance issues with SQL Server and also with specific queries and batches.
	-- Isolate top waits for server instance since last restart or statistics clear(Самые большие ожидания с последнего рестарта сервера)
		WITH Waits AS
		(SELECT wait_type, wait_time_ms / 1000. AS wait_time_s,
		100. * wait_time_ms / SUM(wait_time_ms) OVER() AS pct,
		ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS rn
		FROM sys.dm_os_wait_stats
		WHERE wait_type NOT IN ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK'
		,'SLEEP_SYSTEMTASK','SQLTRACE_BUFFER_FLUSH','WAITFOR', 'LOGMGR_QUEUE','CHECKPOINT_QUEUE'
		,'REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TO_FLUSH','BROKER_TASK_STOP','CLR_MANUAL_EVENT'
		,'CLR_AUTO_EVENT','DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT'
		,'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN'))
		SELECT W1.wait_type, 
		CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s,
		CAST(W1.pct AS DECIMAL(12, 2)) AS pct,
		CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct
		FROM Waits AS W1
		INNER JOIN Waits AS W2
		ON W2.rn <= W1.rn
		GROUP BY W1.rn, W1.wait_type, W1.wait_time_s, W1.pct
		HAVING SUM(W2.pct) - W1.pct < 95; -- percentage threshold

--  sys.dm_exec_cached_plans which is described by BOL as:
	- Returns a row for each query plan that is cached by SQL Server for faster query execution. You can use this dynamic management view to find cached query plans, cached query text, the amount of memory taken by cached plans, and the reuse count of the cached plans.
	
	-- Сгруппированное количество планов по количеству выполнений
		SELECT objtype, usecounts, COUNT(*) AS [no_of_plans] 
		FROM sys.dm_exec_cached_plans 
		WHERE cacheobjtype = 'Compiled Plan' 
		GROUP BY objtype, usecounts
		ORDER BY objtype, usecounts;
		
--  sys.dm_os_ring_buffers, which is helpfully NOT described by BOL as:
	- The following SQL Server Operating System–related dynamic management views are Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.
		
	-- История использования процессора (снимок раз в 30 минут)
		-- This version works with SQL Server 2008 and SQL Server 2008 R2 only
		DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks)FROM sys.dm_os_sys_info); 

		SELECT TOP(30) SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
					   SystemIdle AS [System Idle Process], 
					   100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
					   DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] 
		FROM ( 
			  SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
					record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
					AS [SystemIdle], 
					record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 
					'int') 
					AS [SQLProcessUtilization], [timestamp] 
			  FROM ( 
					SELECT [timestamp], CONVERT(xml, record) AS [record] 
					FROM sys.dm_os_ring_buffers 
					WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
					AND record LIKE '%<SystemHealth>%') AS x 
			  ) AS y 
		ORDER BY record_id DESC;
		
-- sys.dm_exec_query_memory_grants, which is described by BOL as:
	- Returns information about the queries that have acquired a memory grant or that still require a memory grant to execute. Queries that do not have to wait on a memory grant will not appear in this view.
	-- Посмотреть ожидание запросами памяти
		-- SQL Server 2008 version
		SELECT DB_NAME(st.dbid) AS [DatabaseName], mg.requested_memory_kb, mg.ideal_memory_kb,
		mg.request_time, mg.grant_time, mg.query_cost, mg.dop, st.[text]
		FROM sys.dm_exec_query_memory_grants AS mg
		CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
		WHERE mg.request_time < COALESCE(grant_time, '99991231')
		ORDER BY mg.requested_memory_kb DESC;
		-- SQL Server 2005 version
		SELECT DB_NAME(st.dbid) AS [DatabaseName], mg.requested_memory_kb,
		mg.request_time, mg.grant_time, mg.query_cost, mg.dop, st.[text]
		FROM sys.dm_exec_query_memory_grants AS mg
		CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
		WHERE mg.request_time < COALESCE(grant_time, '99991231')
		ORDER BY mg.requested_memory_kb DESC;
		
-- sys.dm_os_process_memory, which is described by BOL as:
	- Most memory allocations that are attributed to the SQL Server process space are controlled through interfaces that allow for tracking and accounting of those allocations. However, memory allocations might be performed in the SQL Server address space that bypasses internal memory management routines. Values are obtained through calls to the base operating system. They are not manipulated by methods internal to SQL Server, except when it adjusts for locked or large page allocations. All returned values that indicate memory sizes are shown in kilobytes (KB). The column total_virtual_address_space_reserved_kb is a duplicate of virtual_memory_in_bytes from sys.dm_os_sys_info.
	
	-- SQL Server Process Address space info (SQL 2008 and 2008 R2 only)
		--(shows whether locked pages is enabled, among other things)
		SELECT physical_memory_in_use_kb,locked_page_allocations_kb, 
			   page_fault_count, memory_utilization_percentage, 
			   available_commit_limit_kb, process_physical_memory_low, 
			   process_virtual_memory_low
		FROM sys.dm_os_process_memory;

-- sys.dm_tran_database_transactions
	- Returns information about transactions at the database level.
	
-- sys.dm_tran_session_transactions
	- Returns correlation information for associated transactions and sessions.

-- sys.dm_tran_active_transactions
	- Returns information about transactions for the instance of SQL Server.

-- sys.dm_exec_requests, which is described by BOL as/активные запросы:
	- Returns information about each request that is executing within SQL Server.		
	- Показывает не все выполняемые в данный момент транзакции
	-- Запросы выполняемые в данный момент на сервере. (Look at currently executing requests, status and wait type)
		SELECT r.session_id, r.[status], r.wait_type, r.scheduler_id, 
		SUBSTRING(qt.[text],r.statement_start_offset/2, 
					(CASE WHEN r.statement_end_offset = -1 
						THEN LEN(CONVERT(nvarchar(max), qt.[text])) * 2 
						ELSE r.statement_end_offset 
					 END - r.statement_start_offset)/2) AS [statement_executing],
			DB_NAME(qt.[dbid]) AS [DatabaseName],
			OBJECT_NAME(qt.objectid) AS [ObjectName],
			r.cpu_time, r.total_elapsed_time/1000 as total_elapsed_time_s, r.reads, r.writes, 
			r.logical_reads, qp.query_plan
		FROM sys.dm_exec_requests AS r
		CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS qt
		CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) qp
		WHERE r.session_id > 50
		-- AND DB_NAME(qt.[dbid]) IN ('RU_Utils','RU_OutData') -- Отфильтровать по БД
		ORDER BY r.scheduler_id, r.[status], r.session_id;
		
-- Тяжелые сеансы/тяжелые активные сеансы/тяжелые запросы (активные) (более приоритетный запрос выше. Этот запрос может помочь определить нагрузку ещё и на Analysis Services)
	SELECT es.session_id
		,es.program_name
		,DB_NAME(st.dbid)
		,es.login_name
		,es.nt_user_name
		,es.login_time
		,es.host_name
		,es.cpu_time
		,es.total_scheduled_time
		,es.total_elapsed_time
		,es.memory_usage
		,es.logical_reads
		,es.reads
		,es.writes
		,st.text
	FROM sys.dm_exec_sessions es
		LEFT JOIN sys.dm_exec_connections ec 
			ON es.session_id = ec.session_id
		LEFT JOIN sys.dm_exec_requests er
			ON es.session_id = er.session_id
		OUTER APPLY sys.dm_exec_sql_text (er.sql_handle) st
	WHERE es.session_id > 50    -- < 50 system sessions
	ORDER BY es.cpu_time DESC
		
-- sys.dm_os_memory_cache_counters, which is described by BOL as:
	- Returns a snapshot of the health of a cache. sys.dm_os_memory_cache_counters provides run-time information about the cache entries allocated, their use, and the source of memory for the cache entries.		
	-- Look at the number of items in different parts of the cache
		SELECT name, [type], entries_count, single_pages_kb, 
		single_pages_in_use_kb, multi_pages_kb, multi_pages_in_use_kb
		FROM sys.dm_os_memory_cache_counters
		WHERE [type] = 'CACHESTORE_SQLCP' 
		OR [type] = 'CACHESTORE_OBJCP'
		ORDER BY multi_pages_kb DESC;
		
-- sys.dm_tran_locks, which is described by BOL as (более подробно в файле Blocking.sql):
	- Returns information about currently active lock manager resources. Each row represents a currently active request to the lock manager for a lock that has been granted or is waiting to be granted. The columns in the result set are divided into two main groups: resource and request. The resource group describes the resource on which the lock request is being made, and the request group describes the lock request.
		
-- sys.dm_io_pending_io_requests, which is described by BOL as:
	- Returns a row for each pending I/O request in SQL Server.
	
	-- Показывает надвигающийся ввод/вывод. Показывает обращения к файлам данных в данный момент. Если часто видим одни и те же файлы, значит необходимо усивилить систему ввода-вывода. Look at pending I/O requests by file
		SELECT DB_NAME(mf.database_id) AS [Database], mf.physical_name, 
		r.io_pending, r.io_pending_ms_ticks, r.io_type, fs.num_of_reads, fs.num_of_writes
		FROM sys.dm_io_pending_io_requests AS r
		INNER JOIN sys.dm_io_virtual_file_stats(null,null) AS fs
		ON r.io_handle = fs.file_handle 
		INNER JOIN sys.master_files AS mf
		ON fs.database_id = mf.database_id
		AND fs.file_id = mf.file_id
		ORDER BY r.io_pending, r.io_pending_ms_ticks DESC; 
		
-- sys.dm_exec_connections, which is described by BOL as:
	- Returns information about the connections established to this instance of SQL Server and the details of each connection.
	
	-- Показывает количество подключений с каждого источника. Get a count of SQL connections by IP address
		SELECT ec.client_net_address, es.[program_name], 
		es.[host_name], es.login_name, 
		COUNT(ec.session_id) AS [connection count] 
		FROM sys.dm_exec_sessions AS es  
		INNER JOIN sys.dm_exec_connections AS ec  
		ON es.session_id = ec.session_id   
		GROUP BY ec.client_net_address, es.[program_name], es.[host_name], es.login_name  
		ORDER BY ec.client_net_address, es.[program_name];
		
-- sys.dm_os_buffer_descriptors, which is described by BOL as (см. данные в кэше):
	- Returns information about all the data pages that are currently in the SQL Server buffer pool. The output of this view can be used to determine the distribution of database pages in the buffer pool according to database, object, or type. When a data page is read from disk, the page is copied into the SQL Server buffer pool and cached for reuse. Each cached data page has one buffer descriptor. Buffer descriptors uniquely identify each data page that is currently cached in an instance of SQL Server. sys.dm_os_buffer_descriptors returns cached pages for all user and system databases. This includes pages that are associated with the Resource database.
	
	-- Отображает информацию о объёме использования оперативной памяти по данным по БД.   -- Get total buffer usage by database
		SELECT DB_NAME(database_id) AS [Database Name],
		COUNT(*) * 8/1024.0 AS [Cached Size (MB)]
		FROM sys.dm_os_buffer_descriptors
		WHERE database_id > 4 -- exclude system databases
		AND database_id <> 32767 -- exclude ResourceDB
		GROUP BY DB_NAME(database_id)
		ORDER BY [Cached Size (MB)] DESC;  
			
	-- Другой вид того же запроса
		SELECT
			(CASE WHEN ([database_id] = 32767)
				THEN N'Resource Database'
				ELSE DB_NAME ([database_id]) END) AS [DatabaseName],
			COUNT (*) * 8 / 1024 AS [MBUsed],
			SUM (CAST ([free_space_in_bytes] AS BIGINT)) / (1024 * 1024) AS [MBEmpty]
		FROM sys.dm_os_buffer_descriptors
		GROUP BY [database_id];
    
    -- Отображает использование памяти объектами текущей БД (таблицы, индексы).Breaks down buffers used by current database by 
		SELECT OBJECT_NAME(p.[object_id]) AS [ObjectName],  
		p.index_id, COUNT(*)/128 AS [buffer size(MB)],  
		COUNT(*) AS [buffer_count] 
		FROM sys.allocation_units AS a
		INNER JOIN sys.dm_os_buffer_descriptors AS b
		ON a.allocation_unit_id = b.allocation_unit_id
		INNER JOIN sys.partitions AS p
		ON a.container_id = p.hobt_id
		WHERE b.database_id = DB_ID()
		AND p.[object_id] > 100
		GROUP BY p.[object_id], p.index_id
		ORDER BY buffer_count DESC;
		
 -- Статистика о памяти/работа с памятью/распределение памяти/использование памяти
	- 75% выделенной памяти идёт на кэши планов (if we set max server memory to 14GB the plan cache could use at most 9GB  [(8GB*.75)+(6GB*.5)=(6+3)=9GB], leaving 5GB for the buffer cache. )
	DBCC MEMORYSTATUS
	SELECT * FROM sys.dm_os_memory_cache_counters
	SELECT * FROM sys.dm_os_memory_cache_entries
	SELECT * FROM sys.dm_os_memory_nodes
	-- Освобождение неиспользуемых записей кэша из кэша пула регулятора ресурсов
		DBCC FREESYSTEMCACHE ('ALL', default)
	-- Посмотреть количество планов с одним вызовом
		SELECT * FROM sys.dm_exec_cached_plans where usecounts = 1	
	-- Отображает распределение памяти/Сколько памяти выдано под запросы
		SELECT * FROM sys.dm_os_memory_clerks 
		SELECT * FROM sys.dm_os_memory_clerks where type IN ('CACHESTORE_SQLCP', 'CACHESTORE_OBJCP') -- Память на запросы. 75% на кэш планов и 25% на данные
	-- Распределение памяти
		- SQL Server 2005 RTM & SP1
			75% of server memory from 0-8GB + 50% of server memory from 8Gb-64GB + 25%  of server memory > 64GB
		- SQL Server 2005 SP2   
			75% of server memory from 0-4GB + 10% of server memory from 4Gb-64GB + 5% of server memory > 64GB
		- SQL Server 2000
			SQL Server 2000 4GB upper cap on the plan cache
		
-- Посмотреть 20 самых тяжёлых запросов, находящихся в кэше/Поиск запроса к кэше/найти запрос/дорогие запросы/Top 10 (для поиска)/Top 25 (для поиска). Берёт данные из кэша
	SELECT TOP 20
	DB_NAME(qt.dbid), last_physical_reads,last_logical_writes,
	max_physical_reads, max_logical_reads,max_worker_time, SUBSTRING(qt.text, (qs.statement_start_offset/2)+1, 
			((CASE qs.statement_end_offset
			  WHEN -1 THEN DATALENGTH(qt.text)
			 ELSE qs.statement_end_offset
			 END - qs.statement_start_offset)/2)+1), 
	qs.execution_count, 
	qs.total_logical_reads, qs.last_logical_reads,
	qs.min_logical_reads, qs.max_logical_reads,
	qs.total_elapsed_time, qs.last_elapsed_time,
	qs.min_elapsed_time, qs.max_elapsed_time,
	qs.last_execution_time,
	qp.query_plan
	FROM sys.dm_exec_query_stats qs
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
	CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
	WHERE qt.encrypted=0
	--WHERE qt.encrypted=0 AND qt.text LIKE 'Select%max%cat.spog%'
    ORDER BY qs.total_logical_reads DESC
	
-- Количество чтений каждым запросом
	SELECT 
       qs.max_elapsed_time / 1000 max_duration_msec,
       qs.max_logical_reads,
       qs.max_logical_writes,
       d.name dbname,
       s.[text],
       p.query_plan,
       SUBSTRING(s.text, (qs.statement_start_offset/2) + 1,
        ((CASE statement_end_offset WHEN -1 THEN DATALENGTH(s.text)
        ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) + 1) statement_text
	FROM   sys.dm_exec_query_stats qs
		   CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) s
		   CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) p
		   LEFT JOIN sys.databases d ON d.database_id = s.dbid 
	ORDER BY
		   qs.max_logical_reads DESC
		   
-- Информация по индексам/фрагментация индексов/обновление индексов
	SELECT 
		dm.database_id, 
		'['+tbl.name+']', 
		dm.index_id, 
		idx.name, 
		dm.avg_fragmentation_in_percent,   
		idx.fill_factor,*
	FROM sys.dm_db_index_physical_stats(DB_ID(), null, null, null, 'LIMITED') dm -- Вместо LIMITED можно указать DETAILED, но тогда нужно будет ограничить index_level = 0, иначе будет замножение, так как у индекса есть разные уровни (0 - Leaf Level, 1 - intermedia, 2 - Root)
		INNER JOIN sys.tables tbl ON dm.object_id = tbl.object_id
		INNER JOIN sys.indexes idx ON dm.object_id = idx.object_id AND dm.index_id = idx.index_id 
	WHERE page_count > 8
		AND avg_fragmentation_in_percent > 15
		AND dm.index_id > 0 
		AND tbl.name not like '%$%'
    
-- Посмотрет количество нод/количество рейдов/количество дисков
	select * from sys.dm_os_nodes
	SELECT node_id, node_state_desc, memory_node_id, processor_group, online_scheduler_count, 
       active_worker_count, avg_load_balance, resource_monitor_state
	FROM sys.dm_os_nodes WITH (NOLOCK) 
	WHERE node_state_desc <> N'ONLINE DAC' OPTION (RECOMPILE);
	
-- Посмотреть активность процессоров/включённость процессоров/сопоставление процессоров
	select scheduler_address,parent_node_id,scheduler_id,cpu_id,[status],is_online from sys.dm_os_schedulers