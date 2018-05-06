-- Основное
	- Память расходуется динамически
	
	-- Какие запросы требуют много памяти, но не использует её
		SELECT * FROM sys.dm_exec_query_memory_grants er
		outer apply sys.dm_exec_sql_text((er.sql_handle)) st
		outer apply sys.dm_exec_query_plan((er.plan_handle)) qp
	
	-- Типы памяти
		- Buffer Cache: This is the pool of memory pages into which data pages are read. An important indicator of the performance of the buffer cache is the Buffer Cache Hit Ratio performance counter. It indicates the percentage of data pages found in the buffer cache as opposed to disk. A value of 95% indicates that pages were found in memory 95% of the time. The other 5% required physical disk access. A consistent value below 90% indicates that more physical memory is needed on the server.
		
		- Procedure Cache: This is the pool of memory pages containing the execution plans for all Transact-SQL statements currently executing in the instance. An important indicator of the performance of the procedure cache is the Procedure Cache Hit Ratio performance counter. It indicates the percentage of execution plan pages found in memory as opposed to disk.
		
		- Log Caches: This is the pool of memory used to read and write log pages. Each log has a set of cache pages. The log caches are managed separately from the buffer cache to reduce the synchronization between log and data buffers.
		
		- Connection Context: Each connection has a set of data structures that record the current state of the connection. These data structures hold items such as parameter values for stored procedures, cursor positioning information, and tables currently being referenced.
		System-level Data Structures: These are data structures that hold data global to the instance, such as database descriptors and the lock table.
		
		- Сортировка		
		- Сервис брокер
		- Блокировки
	
	- Если Windows Server не хватает памяти (32 Мб на каждые 4 Гб), то он начинает "просить" её у SQL Server, чем создаёт memory pressure. Происходит это когда в Windows активируется LowMemoryResourceNotification. Как только в Windows активируется флаг HighMemoryResourceNotification, SQL Server может взять память себе. Это происходит когда объём свободной памяти в Windows в 3 раза превосходит минимальный порог.
		- Если включён AWE, то понять сколько именно использует SQL Server памяти можно только специальные счётчики или DMV. В SQl Server 2012 AWE отсутствует
		- На 32 битной системе, Windows может отдать другим приложениям только 2 Гб оперативки. Это поведение можно изменить редактируя boot.ini, таким образом можно отдать 3 Гб оперативной памяти.
		- sys.dm_os_memory_cache_clock_hands
			- Если большое число в поле removed_last_round_count, то мы наблюдаем memory pressure
		
		- sys.dm_os_memory_cache_hash_tables
			- This view returns a row for each active cache in the SQL Server instance. This view can be joined to sys.dm_os_memory_cache_counters on the cache_address column. Interesting columns include the following. 
			- Покажет на сколько сильно заполнены кэши планов/объём кэшей планов
		
		-- The Memory Broker
			- You can think of the Memory Broker as a control mechanism with a feedback loop
				SELECT *
				FROM sys.dm_os_ring_buffers
				WHERE ring_buffer_type=N'RING_BUFFER_MEMORY_BROKER';
				
		
		-- Куда расходуется память
		
			-- До SQL Server 2012
			SELECT type,
				(sum(multi_pages_kb) + sum(single_pages_kb))/1024 as sum_pages_mb
			FROM sys.dm_os_memory_clerks
			WHERE multi_pages_kb != 0			
			GROUP BY type
			ORDER BY sum(multi_pages_kb) + sum(single_pages_kb) DESC;
			
			
			SELECT TOP 10 LEFT([name], 20) as [name],
				LEFT([type], 20) as [type],
				([single_pages_kb] + [multi_pages_kb])/1024 as [Использование памяти Мб],
				[entries_count] as [Количество вхождений]
			FROM sys.dm_os_memory_cache_counters order by single_pages_kb + multi_pages_kb DESC 
			
			-- SQL Server 2012+
			SELECT type,
				sum(pages_kb)/1024 as sum_pages_mb
			FROM sys.dm_os_memory_clerks
			WHERE pages_kb != 0			
			GROUP BY type
			ORDER BY sum(pages_kb)DESC;
			
			-- Описание разных клерков
				1. CACHESTORE_SQLCP - is storing cache plans for SQL statement or batches that arent in stored procedure, functions and triggers, which are less to be reused than stored procedure (Many of them are only used once). In your scenario, CACHESTORE_SQLCP is ued up to 11GB of physical memory, which indicates that there are a lot of ad-hoc queries running on the server. Please run the following query to have a overview of the size of the plan cache used by object type:
					SELECT 
						objtype AS 'Cached Object Type',
						COUNT(*) AS 'Number of Plans',
						SUM(CAST(size_in_bytes AS BIGINT))/1024/1024 AS 'Plan Cache Size (MB)',
						AVG(usecounts) AS 'Avg Use Count'
					FROM sys.dm_exec_cached_plans
					GROUP BY objtype
					ORDER BY 'Plan Cache Size (MB)' DESC
					To work around this issue, please try the fol
					
					-- DBCC FREESYSTEMCACHE('SQL Plans');						
			
				
			-- Использование памяти по базам (общий список)/по БД
				- Если это около 30%, то всё хорошо
				- Причиной большего числа может быть:
					1. Фрагментация индексов или
					2. Больше объекты, которые нельзя поместить вместе (например 5 кб, когда страница всегда 8 кб)
					3. Tables with lots of random insert operations can be problematic as well. 
					
				SELECT
					(CASE WHEN ([database_id] = 32767)
						THEN N'Resource Database'
						ELSE DB_NAME ([database_id]) END) AS [DatabaseName],
					COUNT (*) * 8 / 1024 AS [MBUsed],
					SUM (CAST ([free_space_in_bytes] AS BIGINT)) / (1024 * 1024) AS [MBEmpty]
				FROM sys.dm_os_buffer_descriptors
				GROUP BY [database_id]
				ORDER BY COUNT (*) * 8 / 1024 DESC;				
				
				-- Занятое место внутри таблиц в конкретной БД
					SELECT
						objects.name AS object_name,
						objects.type_desc AS object_type_description,
						COUNT(*) AS buffer_cache_pages,
						CAST(COUNT(*) * 8 AS DECIMAL) / 1024  AS buffer_cache_total_MB,
						CAST(SUM(CAST(dm_os_buffer_descriptors.free_space_in_bytes AS BIGINT)) AS DECIMAL) / 1024 / 1024 AS buffer_cache_free_space_in_MB,
						CAST((CAST(SUM(CAST(dm_os_buffer_descriptors.free_space_in_bytes AS BIGINT)) AS DECIMAL) / 1024 / 1024) / (CAST(COUNT(*) * 8 AS DECIMAL) / 1024) * 100 AS DECIMAL(5,2)) AS buffer_cache_percent_free_space
					FROM sys.dm_os_buffer_descriptors
					INNER JOIN sys.allocation_units
					ON allocation_units.allocation_unit_id = dm_os_buffer_descriptors.allocation_unit_id
					INNER JOIN sys.partitions
					ON ((allocation_units.container_id = partitions.hobt_id AND type IN (1,3))
					OR (allocation_units.container_id = partitions.partition_id AND type IN (2)))
					INNER JOIN sys.objects
					ON partitions.object_id = objects.object_id
					WHERE allocation_units.type IN (1,2,3)
					AND objects.is_ms_shipped = 0
					AND dm_os_buffer_descriptors.database_id = DB_ID()
					GROUP BY objects.name,
								objects.type_desc,
								objects.object_id
					HAVING COUNT(*) > 0
					ORDER BY COUNT(*) DESC;
					
				-- dirty page per server
					SELECT
						databases.name AS database_name,
						COUNT(*) AS buffer_cache_total_pages,
						SUM(CASE WHEN dm_os_buffer_descriptors.is_modified = 1
									THEN 1
									ELSE 0
							END) AS buffer_cache_dirty_pages,
						SUM(CASE WHEN dm_os_buffer_descriptors.is_modified = 1
									THEN 0
									ELSE 1
							END) AS buffer_cache_clean_pages,
						SUM(CASE WHEN dm_os_buffer_descriptors.is_modified = 1
									THEN 1
									ELSE 0
							END) * 8 / 1024 AS buffer_cache_dirty_page_MB,
						SUM(CASE WHEN dm_os_buffer_descriptors.is_modified = 1
									THEN 0
									ELSE 1
							END) * 8 / 1024 AS buffer_cache_clean_page_MB
					FROM sys.dm_os_buffer_descriptors
					INNER JOIN sys.databases
					ON dm_os_buffer_descriptors.database_id = databases.database_id
					GROUP BY databases.name;
					
				-- dirty page per DB
					SELECT
						indexes.name AS index_name,
						objects.name AS object_name,
						objects.type_desc AS object_type_description,
						COUNT(*) AS buffer_cache_total_pages,
						SUM(CASE WHEN dm_os_buffer_descriptors.is_modified = 1
									THEN 1
									ELSE 0
							END) AS buffer_cache_dirty_pages,
						SUM(CASE WHEN dm_os_buffer_descriptors.is_modified = 1
									THEN 0
									ELSE 1
							END) AS buffer_cache_clean_pages,
						SUM(CASE WHEN dm_os_buffer_descriptors.is_modified = 1
									THEN 1
									ELSE 0
							END) * 8 / 1024 AS buffer_cache_dirty_page_MB,
						SUM(CASE WHEN dm_os_buffer_descriptors.is_modified = 1
									THEN 0
									ELSE 1
							END) * 8 / 1024 AS buffer_cache_clean_page_MB
					FROM sys.dm_os_buffer_descriptors
					INNER JOIN sys.allocation_units
					ON allocation_units.allocation_unit_id = dm_os_buffer_descriptors.allocation_unit_id
					INNER JOIN sys.partitions
					ON ((allocation_units.container_id = partitions.hobt_id AND type IN (1,3))
					OR (allocation_units.container_id = partitions.partition_id AND type IN (2)))
					INNER JOIN sys.objects
					ON partitions.object_id = objects.object_id
					INNER JOIN sys.indexes
					ON objects.object_id = indexes.object_id
					AND partitions.index_id = indexes.index_id
					WHERE allocation_units.type IN (1,2,3)
					AND objects.is_ms_shipped = 0
					AND dm_os_buffer_descriptors.database_id = DB_ID()
					GROUP BY indexes.name,
							 objects.name,
							 objects.type_desc
					ORDER BY COUNT(*) DESC;
				
			- CACHESTORE_OBJCP. These are compiled plans for stored procedures, functions and triggers.
			- CACHESTORE_SQLCP.  These are cached SQL statements or batches that arent in stored procedures, functions and triggers.  This includes any dynamic SQL or raw SELECT statements sent to the server.
			- CACHESTORE_PHDR.  These are algebrizer trees for views, constraints and defaults.  An algebrizer tree is the parsed SQL text that resolves the table and column names.
		
			-- Свободная память
				SELECT * FROM sys.dm_os_performance_counters WHERE counter_name = 'Free Memory (KB)'		
		
					
		-- NUMA
			- The principal reason for using soft-NUMA is to segregate workloads to specific CPUs through the use of the separate I/O completion port assigned to each logical thread, for connectivity. Configuring four soft-NUMA nodes provides four I/O completion ports and managing threads, which allows separation of workloads by connecting to the port of a specific soft-NUMA node.
			- Configuring soft-NUMA doesn’t provide additional lazywriter threads in SQL Server. Separate lazywriter threads are created only for physical hardware NUMA memory nodes.
			- Желательно раскидывать память в каждую NUMA Равномерно, чтобы SQL Server не обращался к другим NUMA
				
		-- Read-ahead/упреждающее чтение
			- comes in two types: one for table scans on heaps and one for index ranges.
			- SQL Server Enterprise использует упреждающую выборку в большей степени, чем другие выпуски SQL Server, выполняя упреждающее чтение большего числа страниц
			
		-- Кольцевой просмотр (SQL Server Enterprise)
			- Если несколько запросов ссылаются на одну таблицу и уже идёт выборка из неё, то SQL Server подключит все новые запросы к этому процессу считывания, а оставшиеся строки доберёт вторым запросом

			
-- Куда расходуется память
	1. Поключения 
		- 28 Кб на подключение
		- один пользователь может создать множество подключений
	2. Блокировки
	3. Данные
	4. Планы
		
	-- Куда расходуется память в плане запроса/query plan
		Some common tactics for preventing these problems include using a higher sample rate for statistics updates and updating statistics more frequently. For the last case where data is widely skewed, the problem may persist even with the best possible statistics. Statistics are limited to 200 entries to try to describe the entire dataset in the index or columns. The greater the number of distinct values that must be represented, the harder it is to represent them accurately. Sometimes you can help the optimizer by adding statistics for a column that is not indexed. A known instance of data skew can be worked around by applying a filter to statistics. If you created a filtered index, the optimizer may or may not be able to use the filtered index. However, it would be able to take advantage of the statistics created to support the filtered index. Statistics are much lighter weight than indexes and if you only need the statistics for the optimizer to get accurate counts, then it makes sense to only create the statistics. If spills are currently occurring, you can use the DMV sys.dm_exec_query_memory_grants to see how much memory the optimizer thought the query needed. While the query is still running, the ideal_memory_kb column will show how much physical memory the optimizer thought the query would need.
		
		Memory and spilling Before a hash join begins execution, SQL Server tries to estimate how much memory it will need to build its hash table. It uses the cardinality estimate for the size of the build input along with the expected average row size to estimate the memory requirement. To minimize the memory required by the hash join, the optimizer chooses the smaller of the two tables as the build table. SQL Server then tries to reserve sufficient memory to ensure that the hash join can successfully store the entire build table in memory.

		When we talk about memory-consuming iterators, the first that should come to mind are:
			- Sort
			- Hash join
			- Hash aggregation
		
		Если запрос на физ. уровне использует Merge, то чтобы контролировать память, надо заставить делать его SORT или любой другой итератор, который запросит память, для HASH JOIN память всегда запрашивается. 
		Вот моё решение:

		MemoryGrant - 9352

		SELECT CAST(name as varchar(512)) FROM partner p INNER JOIN claim c ON CAST(p.inc as bigint) = CAST(c .partner as bigint)
		OPTION (HASH JOIN)

		MemoryGrant - 23240

		SELECT CAST(name as varchar(2000)) FROM partner p INNER JOIN claim c ON CAST(p.inc as bigint) = CAST(c .partner as bigint)
		OPTION (HASH JOIN)

		-- Так же помогает неверное количество строк в таблице
			UPDATE STATISTICS dbo.partner(PK_partner)
			WITH ROWCOUNT = 50000

			DBCC UPDATEUSAGE (Arttour,partner,PK_partner) WITH COUNT_ROWS
		
		-- Хинт для выделения памяти запросу
			https://support.microsoft.com/en-us/help/3107401/new-query-memory-grant-options-are-available-min-grant-percent-and-max-grant-percent-in-sql-server-2012
		

	
-- Распределение памяти по типам
	select type,SUM(single_pages_kb +multi_pages_kb + virtual_memory_committed_kb+shared_memory_committed_kb+awe_allocated_kb) as Summ_KB,
		sum(virtual_memory_reserved_kb) as [VM Reserved],
		sum(virtual_memory_committed_kb) as [VM Committed],
		sum(awe_allocated_kb) as [AWE Allocated],
		sum(shared_memory_reserved_kb) as [SM Reserved], 
		sum(shared_memory_committed_kb) as [SM Committed],
		sum(multi_pages_kb) as [MultiPage Allocator],
		sum(single_pages_kb) as [SinlgePage Allocator],  convert(varchar,getdate(),120) as EventTime	  
	from sys.dm_os_memory_clerks group by type order by Summ_KB desc
	
-- Минусы большого объёма памяти:
	1. Shutting down the instance. This will checkpoint all the databases, which could take quite a long time (minutes to hours) if suddenly all databases have lots of dirty pages that all need to be flushed out to disk. This can eat into your maintenance window, if you’re shutting down to install an SP or a CU.
	2. Starting up the instance. If the server’s POST checks memory, the more memory you have, the longer that will take. This can eat into your allowable downtime if a crash occurs.
	3. Allocating the buffer pool. We’ve worked with clients with terabyte+ buffer pools where they hit a bug on 2008 R2 (also in 2008 and 2012) around NUMA memory allocations that would cause SQL Server to take many minutes to start up. That bug has been fixed in all affected versions and you can read about in KB 2819662.
	4. Warming up the buffer pool. Assuming you don’t hit the memory allocation problem above, how do you warm up such a large buffer pool so that you’re not waiting a long time for your ‘working set’ of data file pages to be memory resident? One solution is to analyze your buffer pool when it’s warm, to figure out which tables and indexes are in memory, and then write some scripts that will read much of that data into memory quickly as part of starting up the instance. For one of the same customers that hit the allocation bug above, doing this produced a big boost in getting to the steady-state workload performance compared to waiting for the buffer pool to warm up naturally.
	5. Complacency. With a large amount of memory available, there might be a tendency to slacken off proactively looking for unused and missing index tuning opportunities or plan cache bloat or wasted buffer pool space (I mentioned above), thinking that having all that memory will be more forgiving. Don’t fall into this trap. If one of these things becomes such a problem that it’s noticeable on your server with lots of memory, it’s a *big* problem that may be harder to get under control quickly.
	6. Disaster recovery. If you’ve got lots of memory, it probably means your databases are getting larger. You need to start considering the need for multiple filegroups to allow small, targeted restores for fast disaster recovery. This may also mean you need to think about breaking up large tables, using partitioning for instance, or archiving old, unused data so that tables don’t become unwieldy.
	
 -- Статистика о памяти/работа с памятью/распределение памяти/использование памяти
	- (до 2008) 75% выделенной памяти идёт на кэши планов (if we set max server memory to 14GB the plan cache could use at most 9GB  [(8GB*.75)+(6GB*.5)=(6+3)=9GB], leaving 5GB for the buffer cache. )
	DBCC MEMORYSTATUS
	- Суть в следующуем. Если памяти менее 4 Гб, то на кэш планов идёт до 75%, если с 4 до 64, то к тем 75% от 4 Гб (3 Гб) прибавляется ещё 10% от (общая память минус 4 Гб), если больше 64 Гб, то ещё +5 % (2008+)
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
	-- Распределение памяти/memory pressure/когда начинается давление памяти
		- SQL Server 2005 SP2+, SQL Server 2008/2008R2, SQL Server 2012 - 2016 
			75% of visible target memory from 0-4 GB + 10% of visible target memory from 8 GB-64 GB + 5% of visible target memory > 64 GB
		- SQL Server 2005 RTM & SP1
			75% of server memory from 0-8GB + 50% of server memory from 8Gb-64GB + 25%  of server memory > 64GB
		- SQL Server 2005 SP2   
			75% of server memory from 0-4GB + 10% of server memory from 4Gb-64GB + 5% of server memory > 64GB
		- SQL Server 2000
			SQL Server 2000 4GB upper cap on the plan cache
			
			
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
		
-- data in cache/данные в кэше/данные в кеше
	SELECT * FROM sys.dm_os_buffer_descriptors
	- Low data density pages are caused by: (свободное место в страницах памяти, чем его больше, тем хуже плотность данных)
		- Very wide data rows (e.g. a table with a 5000-byte fixed-size row will only ever fit one row per page, wasting roughly 3000 bytes per page).
		- Page splits, from random inserts into full pages or updates to rows on full pages. These kind of page splits result in logical fragmentation that affects range scan performance, low data density in data/index pages, and increased transaction log overhead (see How expensive are page splits in terms of transaction log?).
		- Row deletions where the space freed up by the deleted row will not be reused because of the insert pattern into the table/index.
		
	- Low data density pages can be detrimental to SQL Server performance, because the lower the density of records on the pages in a table:
		- The higher the amount of disk space necessary to store the data (and back it up).
		- The more I/Os are needed to read the data into memory.
		- The higher the amount of buffer pool memory needed to store the extra pages in the buffer pool.
		
	- Как много памяти используется в данный момент на данные в кэше и как много из этого числа в пустую		
		SELECT
			COUNT (*) * 8 / 1024 AS MBUsed, 
			SUM (CONVERT (BIGINT, free_space_in_bytes)) / (1024 * 1024) AS MBEmpty
		FROM sys.dm_os_buffer_descriptors;
		GO
		
	-- Использование памяти внутри активной базы
		SELECT OBJECT_NAME(p.[object_id]) AS [ObjectName], p.[object_id], 
		p.index_id, COUNT(*)/128 AS [Buffer size(MB)],  COUNT(*) AS [Buffer_count] 
		FROM sys.allocation_units AS a
		INNER JOIN sys.dm_os_buffer_descriptors AS b
		ON a.allocation_unit_id = b.allocation_unit_id
		INNER JOIN sys.partitions AS p
		ON a.container_id = p.hobt_id
		WHERE b.database_id = DB_ID()
		GROUP BY p.[object_id], p.index_id
		ORDER BY buffer_count DESC;
		
	-- Использование памяти по базам (разбиение на объекты). Можно увидеть какие объекты нуждаются в доработке/по бд
		EXEC sp_MSforeachdb
			N'IF EXISTS (SELECT 1 FROM (SELECT DISTINCT DB_NAME ([database_id]) AS [name]
			FROM sys.dm_os_buffer_descriptors) AS names WHERE [name] = ''?'')
		BEGIN
		USE [?]
		SELECT
			''?'' AS [Database],
			OBJECT_NAME (p.[object_id]) AS [Object],
			p.[index_id],
			i.[name] AS [Index],
			i.[type_desc] AS [Type],
			--au.[type_desc] AS [AUType],
			--DPCount AS [DirtyPageCount],
			--CPCount AS [CleanPageCount],
			--DPCount * 8 / 1024 AS [DirtyPageMB],
			--CPCount * 8 / 1024 AS [CleanPageMB],
			(DPCount + CPCount) * 8 / 1024 AS [TotalMB],
			--DPFreeSpace / 1024 / 1024 AS [DirtyPageFreeSpace],
			--CPFreeSpace / 1024 / 1024 AS [CleanPageFreeSpace],
			([DPFreeSpace] + [CPFreeSpace]) / 1024 / 1024 AS [FreeSpaceMB],
			CAST (ROUND (100.0 * (([DPFreeSpace] + [CPFreeSpace]) / 1024) / (([DPCount] + [CPCount]) * 8), 1) AS DECIMAL (4, 1)) AS [FreeSpacePC]
		FROM
			(SELECT
				allocation_unit_id,
				SUM (CASE WHEN ([is_modified] = 1)
					THEN 1 ELSE 0 END) AS [DPCount],
				SUM (CASE WHEN ([is_modified] = 1)
					THEN 0 ELSE 1 END) AS [CPCount],
				SUM (CASE WHEN ([is_modified] = 1)
					THEN CAST ([free_space_in_bytes] AS BIGINT) ELSE 0 END) AS [DPFreeSpace],
				SUM (CASE WHEN ([is_modified] = 1)
					THEN 0 ELSE CAST ([free_space_in_bytes] AS BIGINT) END) AS [CPFreeSpace]
			FROM sys.dm_os_buffer_descriptors
			WHERE [database_id] = DB_ID (''?'')
			GROUP BY [allocation_unit_id]) AS buffers
		INNER JOIN sys.allocation_units AS au
			ON au.[allocation_unit_id] = buffers.[allocation_unit_id]
		INNER JOIN sys.partitions AS p
			ON au.[container_id] = p.[partition_id]
		INNER JOIN sys.indexes AS i
			ON i.[index_id] = p.[index_id] AND p.[object_id] = i.[object_id]
		WHERE p.[object_id] > 100 AND ([DPCount] + [CPCount]) > 12800 -- Taking up more than 100MB
		ORDER BY [FreeSpacePC] DESC;
		END';
		
	- Посмотреть чистые и грязные страницы в пуле по базам		    
		SELECT
		   (CASE WHEN ([is_modified] = 1) THEN N'Dirty' ELSE N'Clean' END) AS N'Page State',
		   (CASE WHEN ([database_id] = 32767) THEN N'Resource Database' ELSE DB_NAME ([database_id]) END) AS N'Database Name',
		   COUNT (*) AS N'Page Count'
		FROM sys.dm_os_buffer_descriptors
		   GROUP BY [database_id], [is_modified]
		   ORDER BY [database_id], [is_modified];
		GO
		
	- Использоваие памяти по объектам
		EXEC sp_MSforeachdb
			N'IF EXISTS (SELECT 1 FROM (SELECT DISTINCT DB_NAME ([database_id]) AS [name]
			FROM sys.dm_os_buffer_descriptors) AS names WHERE [name] = ''?'')
		BEGIN
		USE [?]
		SELECT
			''?'' AS [Database],
			OBJECT_NAME (p.[object_id]) AS [Object],
			p.[index_id],
			i.[name] AS [Index],
			i.[type_desc] AS [Type],
			--au.[type_desc] AS [AUType],
			--DPCount AS [DirtyPageCount],
			--CPCount AS [CleanPageCount],
			--DPCount * 8 / 1024 AS [DirtyPageMB],
			--CPCount * 8 / 1024 AS [CleanPageMB],
			(DPCount + CPCount) * 8 / 1024 AS [TotalMB],
			--DPFreeSpace / 1024 / 1024 AS [DirtyPageFreeSpace],
			--CPFreeSpace / 1024 / 1024 AS [CleanPageFreeSpace],
			([DPFreeSpace] + [CPFreeSpace]) / 1024 / 1024 AS [FreeSpaceMB],
			CAST (ROUND (100.0 * (([DPFreeSpace] + [CPFreeSpace]) / 1024) / (([DPCount] + [CPCount]) * 8), 1) AS DECIMAL (4, 1)) AS [FreeSpacePC]
		FROM
			(SELECT
				allocation_unit_id,
				SUM (CASE WHEN ([is_modified] = 1)
					THEN 1 ELSE 0 END) AS [DPCount],
				SUM (CASE WHEN ([is_modified] = 1)
					THEN 0 ELSE 1 END) AS [CPCount],
				SUM (CASE WHEN ([is_modified] = 1)
					THEN CAST ([free_space_in_bytes] AS BIGINT) ELSE 0 END) AS [DPFreeSpace],
				SUM (CASE WHEN ([is_modified] = 1)
					THEN 0 ELSE CAST ([free_space_in_bytes] AS BIGINT) END) AS [CPFreeSpace]
			FROM sys.dm_os_buffer_descriptors
			WHERE [database_id] = DB_ID (''?'')
			GROUP BY [allocation_unit_id]) AS buffers
		INNER JOIN sys.allocation_units AS au
			ON au.[allocation_unit_id] = buffers.[allocation_unit_id]
		INNER JOIN sys.partitions AS p
			ON au.[container_id] = p.[partition_id]
		INNER JOIN sys.indexes AS i
			ON i.[index_id] = p.[index_id] AND p.[object_id] = i.[object_id]
		WHERE p.[object_id] > 100 AND ([DPCount] + [CPCount]) > 12800 -- Taking up more than 100MB
		ORDER BY [FreeSpacePC] DESC;
		END';
		
	- Что можно сделать, чтобы улучшить ситуацию с неиспользованными данными в кэше
		- Change the table schema (e.g. vertical partitioning, using smaller data types).
		- Change the index key columns (usually only applicable to clustered indexes – e.g. changing the leading cluster key from a random value like a non-sequential GUID to a sequential GUID or identity column).>
		- Use index FILLFACTOR to reduce page splits, and…
		- Periodically rebuild problem indexes.
		- Consider enabling data compression on some tables and indexes.	
		
-- Счетчики
	SQLServer: Memory Manager – Memory Grants Pending (сколько запросов ждёт выделение памяти, данные запросы уже прошли все остальные стадии и ждут памяти, если больше 0 - проблемы)

	SQLServer: SQL Statistics – Compilations/sec более 10% от SQLServer: SQL Statistics – Batch Requests/sec и мы испытываем проблемы с SQLServer: Memory Manager – Memory Grants Pending - это проблемы с памятью

	-- Уменьшить потребление памяти
	1. Использовать параметризованные запросы
	2. Optimize for ad hoc (Properties SQL Server)
	

-- Buffer Pool Extension (буфер данных)
	- Кэш 2 уровня (SQL Server видит обычные диски и быстрые)
	- Вместо вытеснения данных из оперативки (Buffer Pool), данные будут уходить в Buffer Pool Extension. Это должен быть SSD
	- Рекомендуется использовать только если памяти меньше 128 Гб, иначе можем не получить прироста производительности
	- Максимум до 4-10х от доступном оперативной памяти
	- Быстрый диск
	- Когда страницы вытесняются из буферного кэша, то сиквел принимает решение сбросить их или положить в BPE
	
	-- Пример:
		ALTER SERVER CONFIGURATION 
		SET BUFFER POOL EXTENSION ON 
		(FILENAME = 'E:\SSDCACHE\MYCACHE.BPE', SIZE = 
		50 GB);		
		
		-- Отключение
			ALTER SERVER CONFIGURATION SET BUFFER POOL EXTENSION OFF;
		
	-- Посмотреть настройки
		SELECT [path], state_description, current_size_in_kb,
		CAST(current_size_in_kb/1048576.0 AS DECIMAL(10,2)) AS [Size (GB)]
		FROM sys.dm_os_buffer_pool_extension_configuration;
		
	-- Сколько и какая информация в BPE
		SELECT DB_NAME(database_id) AS [Database Name], COUNT(page_id) AS [Page Count],
		CAST(COUNT(*)/128.0 AS DECIMAL(10, 2)) AS [Buffer size(MB)],
		AVG(read_microsec) AS [Avg Read Time (microseconds)]
		FROM sys.dm_os_buffer_descriptors
		WHERE database_id <> 32767
		AND is_in_bpool_extension = 1
		GROUP BY DB_NAME(database_id)
		ORDER BY [Buffer size(MB)] DESC;
		
		
		-- Вместе с обычным buffer pool
			SELECT
			  (CASE WHEN ([is_modified] = 1 AND ([is_in_bpool_extension] IS NULL OR [is_in_bpool_extension] = 0)) THEN N'Dirty'
			WHEN ([is_modified] = 0 AND ([is_in_bpool_extension] IS NULL OR [is_in_bpool_extension] = 0)) THEN N'Clean'
			WHEN ([is_modified] = 0 AND [is_in_bpool_extension] = 1) THEN N'BPE' END) AS N'Page State',
			(CASE WHEN ([database_id] = 32767) THEN N'Resource Database' ELSE DB_NAME ([database_id]) END) AS N'Database Name', 
			COUNT(1) AS N'Page Count'
			FROM sys.dm_os_buffer_descriptors 
			GROUP BY [database_id], [is_modified], [is_in_bpool_extension]
			ORDER BY [database_id], [is_modified], [is_in_bpool_extension]
					
		
	-- Плюсы
		1. Прозрачно и включается легко
		2. Ускорение сервера целиком
		3. Отличие от табличных переменных - У табличных переменных проблемы с индексами, а у In-memory таких проблем нет и можно загонять большие объёмы
		
	-- Минусы
		1. Не такой большой прирост производительности. Лучше сначала полностью забить слоты памятью
		2. В такой кэше могут быть страницы только чистых данных, это не даёт большого прироста производительности.
		
	-- Где использовать
		1. Будет полезно в OLTP, не в DHW
	


-- Оценить необходимое количество памяти
	1. Те сервера, где экземпляры съедали не всю память, я смотрел сколько съел SQL, смотрел на параметр Page Life Expectancy, Total Server Memory и Target Server Memory и исходя из этого делал прогноз
	2. Там где память съедалась вся, смотрел на распределение памяти для экземпляров, для меня это был некий эталон, потом делал 1 шаг для каждого экземпляра и смотрел у кого могу забрать и кому отдать
	3. Смотрел по закросу, который скину ниже как часто сервер жалуется на нехватку памяти и то же вносил корректировки (E:\SQL Scripts\Оптимизация. Мониторинг\Экспресс данные о экземпляре.sql)
	4. Так же есть рекомендации что для обычных OLT система 15-30% от данных памяти будет достаточно

	-- Расчет памяти для некластеризованного, либо кластеризованного SQL Server работающего в режиме Актив/Пассив .
		Остаток для ОС – 5%. В нашем случае это около 25 GB (500*5%).
		Память под ядро SQL Server (различные *.exe, *.dll, *ocx и пр. модули), SQL heap, CLR. Обычно это до 500 MB, хотя за счет CLR это может быть и больше.
		Пямять под кэши “Worker thread”, рассчитываемая по формуле (512+(NumCpu-4)*16)*2 MB. В нашем случае это (512+(64-4)*16)* 2MB = 2944 MB (около 2.7 GB).
		Итого под “max server memory” остается:  500 – 25 – 0.5 – 2.7 = 471.2 GB. Т.е. размер Буферного пула (при таком значении “max server memory”) может вырасти до 471 GB.  
		Для версии SQL 2012 и далее “max server memory” включает в себя SQL heap и частично CLR.
		
		- Особенно актуален это расчет, если вы используете “Lock Pages In Memory” В этом случае завысив это число или оставив его по умолчанию (что обозначает – любой объем) вы можете поставить ОС в довольно неприятное положения, которое приведет к агрессивному триммированию рабочих наборов и, как следствие, резкому замедлению работы системы.
		
	-- Расчет памяти для кластеризованный SQL Server в режиме Актив/Актив.
		При расчете необходимо учитывать, что пункты 2, 3 и 4 должны быть удвоены, и при использовании права учетной записи SQL Server “Lock Pages In Memory”, вам необходимо подобрать не только “max server memory”, но и “min server memory”, что бы в случае переката обоих SQL Server на один узел вы не забрали всю память у ОС.
		
	-- Анализ необходимого количества памяти
		- Суть: собираем сколько памяти кушает БД в пике и складываем максимальные значения всех БД (https://m.habrahabr.ru/post/317426/ начиная с "Забегая вперед, скажу что дело")
	
-- Быстрый тест на нехватку памяти
	WITH RingBufferXML
	AS(SELECT CAST(Record AS XML) AS RBR FROM sys .dm_os_ring_buffers
	   WHERE ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR'
	  )
	SELECT DISTINCT 'Зафиксированы проблемы' =
			  CASE
						WHEN XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]','tinyint')  = 0 AND
							 XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]','tinyint')   = 2 
						THEN 'Недостаточно физической памяти для системы'
						WHEN XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]','tinyint')  = 0 AND 
							 XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]','tinyint')   = 4 
						THEN 'Недостаточно виртуальной памяти для системы' 
						WHEN XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint') = 2 AND 
							 XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]','tinyint')   = 0 
						THEN'Недостаточно физической памяти для запросов'
						WHEN XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint') = 4 AND 
							 XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]', 'tinyint')  = 4
						THEN 'Недостаточно виртуальной памяти для запросов и системы'
						WHEN XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]','tinyint')  = 2 AND 
							 XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]','tinyint')   = 4 
						THEN 'Недостаточно виртуальной памяти для системы и физической для запросов'
						WHEN XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint') = 2 AND 
							 XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]', 'tinyint')  = 2 
						THEN 'Недостаточно физической памяти для системы и запросов'
			 END
	FROM        RingBufferXML
	CROSS APPLY RingBufferXML.RBR.nodes ('Record') Record (XMLRecord)
	WHERE       XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]','tinyint') IN (0,2,4) AND
				XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]' ,'tinyint') IN (0,2,4) AND
				XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]','tinyint') +
				XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]' ,'tinyint') > 0
		
-- Сколько можно выделить памяти экземпляру
	IF OBJECT_ID('tempdb..#mem') IS NOT NULL DROP TABLE #mem
	GO

	DECLARE 
	@memInMachine DECIMAL(9,2)
	,@memOsBase DECIMAL(9,2)
	,@memOs4_16GB DECIMAL(9,2)
	,@memOsOver_16GB DECIMAL(9,2)
	,@memOsTot DECIMAL(9,2)
	,@memForSql DECIMAL(9,2)
	,@CurrentMem DECIMAL(9,2)
	,@sql VARCHAR(1000)

	CREATE TABLE #mem(mem DECIMAL(9,2))

	--Get current mem setting----------------------------------------------------------------------------------------------
	SET @CurrentMem = (SELECT CAST(value AS INT)/1024. FROM sys.configurations WHERE name = 'max server memory (MB)')

	--Get memory in machine------------------------------------------------------------------------------------------------
	IF CAST(LEFT(CAST(SERVERPROPERTY('ResourceVersion') AS VARCHAR(20)), 1) AS INT) = 9
	  SET @sql = 'SELECT physical_memory_in_bytes/(1024*1024*1024.) FROM sys.dm_os_sys_info'
	ELSE 
	   IF CAST(LEFT(CAST(SERVERPROPERTY('ResourceVersion') AS VARCHAR(20)), 2) AS INT) >= 11
		 SET @sql = 'SELECT physical_memory_kb/(1024*1024.) FROM sys.dm_os_sys_info'
	   ELSE
		 SET @sql = 'SELECT physical_memory_in_bytes/(1024*1024*1024.) FROM sys.dm_os_sys_info'

	SET @sql = 'DECLARE @mem decimal(9,2) SET @mem = (' + @sql + ') INSERT INTO #mem(mem) VALUES(@mem)'
	PRINT @sql
	EXEC(@sql)
	SET @memInMachine = (SELECT MAX(mem) FROM #mem)

	--Calculate recommended memory setting---------------------------------------------------------------------------------
	SET @memOsBase = 1

	SET @memOs4_16GB = 
	  CASE 
		WHEN @memInMachine <= 4 THEN 0
	   WHEN @memInMachine > 4 AND @memInMachine <= 16 THEN (@memInMachine - 4) / 4
		WHEN @memInMachine >= 16 THEN 3
	  END

	SET @memOsOver_16GB = 
	  CASE 
		WHEN @memInMachine <= 16 THEN 0
	   ELSE (@memInMachine - 16) / 8
	  END

	SET @memOsTot = @memOsBase + @memOs4_16GB + @memOsOver_16GB
	SET @memForSql = @memInMachine - @memOsTot

	--Output findings------------------------------------------------------------------------------------------------------
	SELECT
	@CurrentMem AS CurrentMemConfig
	, @memInMachine AS MemInMachine
	, @memOsTot AS MemForOS
	, @memForSql AS memForSql
	,'EXEC sp_configure ''max server memory'', ' + CAST(CAST(@memForSql * 1024 AS INT) AS VARCHAR(10)) + ' RECONFIGURE' AS CommandToExecute
	,'Assumes dedicated instance. Only use the value after you verify it is reasonable.' AS Comment
	
	
-- Типы клерков/type of clerks
	/*CACHESTORE_SQLCP*/ - The CACHESTORE_SQLCP is storing cache plans for SQL statement or batches that arent in stored procedure, functions and triggers, which are less to be reused than stored procedure (Many of them are only used once).
			SELECT 
				objtype AS 'Cached Object Type',
				COUNT(*) AS 'Number of Plans',
				SUM(CAST(size_in_bytes AS BIGINT))/1024/1024 AS 'Plan Cache Size (MB)',
				AVG(usecounts) AS 'Avg Use Count'
			FROM sys.dm_exec_cached_plans
			GROUP BY objtype
			ORDER BY 'Plan Cache Size (MB)' DESC

			-- Если хотим очистить кэш от таких запросов
			USE master;
			GO
			DBCC FREESYSTEMCACHE('SQL Plans');
			GO
	/*MEMORYCLERK_SQLOPTIMIZER*/ - In this SQL Server instance advisor detected the presence of a SQL Server build lower than the fixed build for a Memory Leak issue. This can happen when you have a stored procedure that contains a child-stored procedure, which uses temp tables that further uses cursors. You may notice MEMORYCLERK_SQLOPTIMIZER of sys.dm_os_memory_clerks and MEMOBJ_EXECCOMPILETEMP from sys.dm_os_memory_objects going very high.
		-- Решение 
			1. Установить обновление