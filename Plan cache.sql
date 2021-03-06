-- Якобы одинаковые планы запросов
	1. Могут появляться если разные параметры
	2. Где-то есть пробел, а где-то нету, большие-маленькие буквы. То есть важен синтаксис/стиль написания и т.д.

-- Посмотреть план запроса сессии/spid
		dbcc inputbuffer (57)
		
-- Описание 
	query_hash - Binary hash value calculated on the query and used to identify queries with similar logic. You can use the query hash to determine the aggregate resource usage for queries that differ only by literal values.
	
	query_plan_hash - Binary hash value calculated on the query execution plan and used to identify similar query execution plans. You can use query plan hash to find the cumulative cost of queries with similar execution plans. Will always be 0x000 when a natively compiled stored procedure queries a memory-optimized table.
	
	sql_handle - хэш похожих запросов по символам, если символы меняются, то sql_handle будет разным
	
	plan_handle - хэш группы похожих запросов (statement), уникальный в рамках одинаковых настроек SET и каждого плана группы запросов. Если в одноим из планов statement что-то меняется, поменяется plan_handle
	
-- Поиск запросов, которые попали под подозрение одноразового использования
	SELECT * FROM sys.dm_exec_cached_plans 
	WHERE cacheobjtype LIKE 'Compiled Plan%' -- В конце должно добавиться или Stu или Stub
	
	-- Более подброно
		SELECT * FROM sys.dm_exec_cached_plans cp
		CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
		CROSS APPLY sys.dm_exec_sql_text (cp.plan_handle) st
		WHERE cacheobjtype LIKE 'Compiled Plan%' -- В конце должно добавиться или Stu или Stub
		
-- Получить информацию о плане через plan_handle или query_hash
	SELECT query_hash as gerg,* FROM sys.dm_exec_query_stats cp
	CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
	CROSS APPLY sys.dm_exec_sql_text (cp.plan_handle) st
	WHERE query_plan_hash = CONVERT(BINARY(8), CONVERT(BIGINT, 729285453471236635)) -- -- Нужно указать данный параметр
	OR plan_handle = 0x0600050001F7AC1850C2B87F0300000001000000000000000000000000000000000000000000000000000000 -- Нужно указать данный параметр
	OR query_hash = 0x07BFE4A481CD2E57
	
-- Одинаковые планы в Кэше
	SELECT TOP 10 query_hash,
	'Performance' AS FindingsGroup,
	'Many Plans for One Query' AS Finding,
	'https://BrentOzar.com/go/parameterization' AS URL,
	CAST(COUNT(DISTINCT plan_handle) AS NVARCHAR(50)) + ' plans are present for a single query in the plan cache - meaning we probably have parameterization issues.' AS Details


	FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_plan_attributes(qs.plan_handle) pa
    WHERE pa.attribute = 'dbid'
    GROUP BY qs.query_hash, pa.value
    HAVING COUNT(DISTINCT plan_handle) > 50
	ORDER BY COUNT(DISTINCT plan_handle) DESC OPTION (RECOMPILE);
	
-- Информация о планах и параметрах в процедуре
	- Обязательно указать БД и название процедуры
		DECLARE @dbname    nvarchar(256),
				@procname  nvarchar(256)
		SELECT @dbname = 'Northwind',
			   @procname = 'up_Save_DisPacket_nights'
		; WITH basedata AS (
		   SELECT qs.statement_start_offset/2 AS stmt_start,
				  qs.statement_end_offset/2 AS stmt_end,
				  est.encrypted AS isencrypted, est.text AS sqltext,
				  epa.value AS set_options, qp.query_plan,
				  charindex('<ParameterList>', qp.query_plan) + len('<ParameterList>')
					 AS paramstart,
				  charindex('</ParameterList>', qp.query_plan) AS paramend
		   FROM   sys.dm_exec_query_stats qs
		   CROSS  APPLY sys.dm_exec_sql_text(qs.sql_handle) est
		   CROSS  APPLY sys.dm_exec_text_query_plan(qs.plan_handle,
													qs.statement_start_offset,
													qs.statement_end_offset) qp
		   CROSS  APPLY sys.dm_exec_plan_attributes(qs.plan_handle) epa
		   WHERE  est.objectid  = object_id (@procname)
			 --AND  est.dbid      = db_id(@dbname)
			 AND  epa.attribute = 'set_options'
		), next_level AS (
		   SELECT stmt_start, set_options, query_plan,
				  CASE WHEN isencrypted = 1 THEN '-- ENCRYPTED'
					   WHEN stmt_start >= 0
					   THEN substring(sqltext, stmt_start + 1,
									  CASE stmt_end
										   WHEN 0 THEN datalength(sqltext)
										   ELSE stmt_end - stmt_start + 1
									  END)
				  END AS Statement,
				  CASE WHEN paramend > paramstart
					   THEN CAST (substring(query_plan, paramstart,
										   paramend - paramstart) AS xml)
				  END AS params
		   FROM   basedata
		)
		SELECT set_options AS [SET], n.stmt_start AS Pos, n.Statement,
			   CR.c.value('@Column', 'nvarchar(128)') AS Parameter,
			   CR.c.value('@ParameterCompiledValue', 'nvarchar(128)') AS [Sniffed Value],
			   CAST (query_plan AS xml) AS [Query plan]
		FROM   next_level n
		CROSS  APPLY  n.params.nodes('ColumnReference') AS CR(c)
		ORDER  BY n.set_options, n.stmt_start, Parameter
		
-- Получить план триггера
	SELECT query_plan,* FROM sys.dm_exec_query_stats cp
		CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
		CROSS APPLY sys.dm_exec_sql_text (cp.plan_handle) st
	WHERE plan_handle IN (select plan_handle
	from sys.dm_exec_trigger_stats AS ETS
		 INNER JOIN
		 sys.triggers AS TRG
			 ON ETS.object_id = TRG.object_id
	WHERE name = 'tr_update_doc_status')
		
-- Получить планы по объекту
	SELECT   * FROM sys.dm_exec_query_stats qs
		   CROSS  APPLY sys.dm_exec_text_query_plan(qs.plan_handle,
													qs.statement_start_offset,
													qs.statement_end_offset) qp
		outer apply sys.dm_exec_query_plan((qs.plan_handle)) qpp WHERE qp.objectid = 1589580701
		AND qpp.[dbid]= 6

-- Plan attributes	
		SELECT qs.plan_handle, a.attrlist
		FROM   sys.dm_exec_query_stats qs
		CROSS  APPLY sys.dm_exec_sql_text(qs.sql_handle) est
		CROSS  APPLY (SELECT epa.attribute + '=' + convert(nvarchar(127), epa.value) + '   '
					  FROM   sys.dm_exec_plan_attributes(qs.plan_handle) epa
					  WHERE  epa.is_cache_key = 1
					  ORDER  BY epa.attribute
					  FOR    XML PATH('')) AS a(attrlist)
		WHERE  est.objectid = object_id ('dbo.List_orders_6')
		  AND  est.dbid     = db_id('Northwind')
		  
	-- Сравнить атрибуты 2х планов (предварительно нужно получить plan_handle сравниваемых запросов)
		DECLARE @sql1 varbinary(64) = 0x050005008B31FC1840412AB2090000000000000000000000
		DECLARE @sql2 varbinary(64) = 0x050005008B31FC1840412AB2090000000000000000000000
		  
		SELECT t1.attribute,t1.value,t1.value,
		t1.is_cache_key -- Влияет ли не создание плана
		FROM  sys.dm_exec_plan_attributes(@sql1) as t1 INNER JOIN sys.dm_exec_plan_attributes(@sql2) as t2 ON t1.attribute = t2.attribute
		
		  
-- Что вызывает перекомпиляцию
	1. Изменение схемы объектов даже внутри хранимой процедуры
		CREATE PROCEDURE List_orders_7 @fromdate datetime, @ix       bit AS
	   IF @ix = 1 CREATE INDEX test ON Orders(ShipVia)
	   SELECT * FROM  Orders WHERE OrderDate > @fromdate
	2. Табличные переменные (DECLARE @t TABLE). Обычно SQL Server оценивает табличные переменные как таблицы, возвращающие одну строку, но когда происходит перекомпиляция, оценка может отличаться:
	3. RECOMPILE во все не сохраняет план
	4. Statement involving temp table. Data could have been changed when the statement is actually executed.  So it doesn’t make sense to compile right off the beginning.
	5. Часть запросов внутри процедуры могут не компилироваться по причине того, что они ниразу не вызывались
	
	-- Из книги SQL Internals
		Note that although some of these operations affect only a single database, the entire plan cache is cleared.
		- Upgrading any database to SQL Server 2012
		- Running the DBCC FREEPROCCACHE or DBCC FREESYSTEMCACHE commands
		- Changing any of the following configuration options: 
		- cross db ownership chaining 
		- index create memory 
		- cost threshold for parallelism 
		- max degree of parallelism 
		- max text repl size 
		- min memory per query
		- min server memory 
		- max server memory 
		- query governor cost limit 
		- query wait 
		- remote query timeout 
		- user options

		The following operations clear all plans associated with a particular database:
		- Running the DBCC FLUSHPROCINDB command
		- Detaching a database
		- Closing or opening an auto-close database
		- Modifying a collation for a database using the ALTER DATABASE...COLLATE command
		- Altering a database with any of the following commands: 
		- ALTER DATABASE...MODIFY_NAME 
		- ALTER DATABASE...MODIFY FILEGROUP 
		- ALTER DATABASE...SET ONLINE 
		- ALTER DATABASE...SET OFFLINE
		- Chapter 12 Plan caching and recompilation 731 
		- ALTER DATABASE...SET EMERGENCY
		- ALTER DATABASE...SET READ_ONLY 
		- ALTER DATABASE...SET READ_WRITE 
		- ALTER DATABASE...COLLATE
		- Dropping a database

-- Вытестение планов из кэша
	- Этот процесс называется eviction policy и как пишут, он отличается для разных типов плана. То что ниже, относится к Object Plan и SQL Plans. По другим нет информации в книге (Bound Trees,Extended Stored Procedures)
	
	For ad hoc plans, the cost is considered to be zero, but it’s increased by 1 every time the plan is reused. For other types of plans, the cost is a measure of the resources required to produce the plan. When one of these plans is 744 Microsoft SQL Server 2012 Internals reused, the cost is reset to the original cost. For non–ad hoc queries, the cost is measured in units called ticks, with a maximum of 31. The cost is based on three factors: I/O, context switches, and memory. Each has its own maximum within the 31-tick total:
	- I/O Each I/O costs 1 tick, with a maximum of 19.	
	- Compilation-related context switches Each switch costs 1 tick each, with a maximum of 8.
	- Compile memory Compile memory costs 1 tick per 16 pages, with a maximum of 4.	
	
	--Посмотреть эти цифры по текущим планам 
		SELECT text, objtype, refcounts, usecounts, size_in_bytes,
		disk_ios_count, context_switches_count,
		pages_kb as MemoryKB, original_cost, current_cost
		FROM sys.dm_exec_cached_plans p
		CROSS APPLY sys.dm_exec_sql_text(plan_handle)
		JOIN sys.dm_os_memory_cache_entries e
		ON p.memory_object_address = e.memory_object_address
		WHERE cacheobjtype = 'Compiled Plan'
		AND type in ('CACHESTORE_SQLCP', 'CACHESTORE_OBJCP')
		ORDER BY objtype desc, usecounts DESC;
		
		
-- Следующий пример возвращает текст инструкции SQL и среднее время ЦП для пяти первых запросов.		
		 SELECT TOP 5 total_worker_time/execution_count AS [Avg CPU Time],
			SUBSTRING(st.text, (qs.statement_start_offset/2)+1, 
				((CASE qs.statement_end_offset
				  WHEN -1 THEN DATALENGTH(st.text)
				 ELSE qs.statement_end_offset
				 END - qs.statement_start_offset)/2) + 1) AS statement_text
		FROM sys.dm_exec_query_stats AS qs
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
		ORDER BY total_worker_time/execution_count DESC;

-- Поиск одразовых планов в кэше
	-- Лечение: Optimize for ad hoc (Properties SQL Server)
	SELECT [text],cp.objtype,cp.size_in_bytes FROM sys.dm_exec_cached_plans as cp CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st 
	WHERE cp.cacheobjtype = N'Compiled Plan'
	AND cp.objtype IN (N'Adhoc',N'Prepared') -- Prepared (Подготовленная инструкция). Adhoc (Нерегламентированный запрос)
	AND cp.usecounts = 1
	ORDER BY cp.size_in_bytes DESC
	OPTION (RECOMPILE)
	
	-- В цифрах
		SELECT cp.objtype, Count(*) FROM sys.dm_exec_cached_plans as cp CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st 
		WHERE cp.cacheobjtype = N'Compiled Plan'
		AND cp.objtype IN (N'Adhoc',N'Prepared')
		AND cp.usecounts = 1
		GROUP BY cp.objtype

-- Планы с Warning
	;WITH XMLNAMESPACES(DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
	SELECT 
	cp.query_hash, cp.query_plan_hash,
	ConvertIssue = operators.value('@ConvertIssue', 'nvarchar(250)'), 
	Expression = operators.value('@Expression', 'nvarchar(250)'), qp.query_plan
	FROM sys.dm_exec_query_stats cp
	CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
	CROSS APPLY query_plan.nodes('//Warnings') rel(operators)
		
-- Планы, для которых не хватает индексов
	;WITH XMLNAMESPACES(DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan')       
	SELECT dec.usecounts, dec.refcounts, dec.objtype
		  ,dec.cacheobjtype, des.dbid, des.text      
		  ,deq.query_plan 
	FROM sys.dm_exec_cached_plans AS dec 
		 CROSS APPLY sys.dm_exec_sql_text(dec.plan_handle) AS des 
		 CROSS APPLY sys.dm_exec_query_plan(dec.plan_handle) AS deq 
	WHERE deq.query_plan.exist(N'/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup') <> 0 
	ORDER BY dec.usecounts DESC 

-- Планы с неявным предупреждением в кэше. При обнаружении таковых рекомендуется применить одно из действий: изменить тип столбца или текст запроса
	;WITH XMLNAMESPACES(DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
	SELECT 
	cp.query_hash, cp.query_plan_hash,
	ConvertIssue = operators.value('@ConvertIssue', 'nvarchar(250)'), 
	Expression = operators.value('@Expression', 'nvarchar(250)'), qp.query_plan
	FROM sys.dm_exec_query_stats cp
	CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
	CROSS APPLY query_plan.nodes('//Warnings/PlanAffectingConvert') rel(operators)

-- Find and fix plans with clustered index seeks and key lookups
	;WITH XMLNAMESPACES(DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
	SELECT 
	cp.query_hash, cp.query_plan_hash,
	PhysicalOperator = operators.value('@PhysicalOp','nvarchar(50)'), 
	LogicalOp = operators.value('@LogicalOp','nvarchar(50)'),
	AvgRowSize = operators.value('@AvgRowSize','nvarchar(50)'),
	EstimateCPU = operators.value('@EstimateCPU','nvarchar(50)'),
	EstimateIO = operators.value('@EstimateIO','nvarchar(50)'),
	EstimateRebinds = operators.value('@EstimateRebinds','nvarchar(50)'),
	EstimateRewinds = operators.value('@EstimateRewinds','nvarchar(50)'),
	EstimateRows = operators.value('@EstimateRows','nvarchar(50)'),
	Parallel = operators.value('@Parallel','nvarchar(50)'),
	NodeId = operators.value('@NodeId','nvarchar(50)'),
	EstimatedTotalSubtreeCost = operators.value('@EstimatedTotalSubtreeCost','nvarchar(50)')
	FROM sys.dm_exec_query_stats cp
	CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
	CROSS APPLY query_plan.nodes('//RelOp') rel(operators)
	
-- Finding Implicit Column Conversions in the Plan Cache
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

	DECLARE @dbname SYSNAME 
	SET @dbname = QUOTENAME(DB_NAME()); 

	WITH XMLNAMESPACES 
	   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan') 
	SELECT 
	   stmt.value('(@StatementText)[1]', 'varchar(max)'), 
	   t.value('(ScalarOperator/Identifier/ColumnReference/@Schema)[1]', 'varchar(128)'), 
	   t.value('(ScalarOperator/Identifier/ColumnReference/@Table)[1]', 'varchar(128)'), 
	   t.value('(ScalarOperator/Identifier/ColumnReference/@Column)[1]', 'varchar(128)'), 
	   ic.DATA_TYPE AS ConvertFrom, 
	   ic.CHARACTER_MAXIMUM_LENGTH AS ConvertFromLength, 
	   t.value('(@DataType)[1]', 'varchar(128)') AS ConvertTo, 
	   t.value('(@Length)[1]', 'int') AS ConvertToLength, 
	   query_plan 
	FROM sys.dm_exec_cached_plans AS cp 
	CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
	CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS batch(stmt) 
	CROSS APPLY stmt.nodes('.//Convert[@Implicit="1"]') AS n(t) 
	JOIN INFORMATION_SCHEMA.COLUMNS AS ic 
	   ON QUOTENAME(ic.TABLE_SCHEMA) = t.value('(ScalarOperator/Identifier/ColumnReference/@Schema)[1]', 'varchar(128)') 
	   AND QUOTENAME(ic.TABLE_NAME) = t.value('(ScalarOperator/Identifier/ColumnReference/@Table)[1]', 'varchar(128)') 
	   AND ic.COLUMN_NAME = t.value('(ScalarOperator/Identifier/ColumnReference/@Column)[1]', 'varchar(128)') 
	WHERE t.exist('ScalarOperator/Identifier/ColumnReference[@Database=sql:variable("@dbname")][@Schema!="[sys]"]') = 1

-- Поиск планов с Key Loop или Index SCAN
		- Если не знаю структуру, то ищу Scan Table и Clustered Index Scan (CROSS APPLY n.nodes('.//RelOp[IndexScan/Object[@Schema!="[sys]"]]') as s(i) -- Заменить последнее условие) -- Index scan
			SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
			DECLARE @IndexName AS NVARCHAR(128) = 'PK__TestTabl__FFEE74517ABC33CD';

			-- Make sure the name passed is appropriately quoted
			IF (LEFT(@IndexName, 1) <> '[' AND RIGHT(@IndexName, 1) <> ']') SET @IndexName = QUOTENAME(@IndexName);
			--Handle the case where the left or right was quoted manually but not the opposite side
			IF LEFT(@IndexName, 1) <> '[' SET @IndexName = '['+@IndexName;
			IF RIGHT(@IndexName, 1) <> ']' SET @IndexName = @IndexName + ']';

			-- Dig into the plan cache and find all plans using this index
			;WITH XMLNAMESPACES 
			   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')    
			SELECT 
			(SELECT execution_count FROM sys.dm_exec_query_stats cpp
			CROSS APPLY sys.dm_exec_query_plan(cpp.plan_handle) qp
			CROSS APPLY sys.dm_exec_sql_text (cpp.plan_handle) st
			WHERE cpp.plan_handle =  cp.plan_handle),
			 stmt.value('(@StatementText)[1]', 'varchar(max)') AS SQL_Text,
			 obj.value('(@Database)[1]', 'varchar(128)') AS DatabaseName,
			 obj.value('(@Schema)[1]', 'varchar(128)') AS SchemaName,
			 obj.value('(@Table)[1]', 'varchar(128)') AS TableName,
			 obj.value('(@Index)[1]', 'varchar(128)') AS IndexName,
			 obj.value('(@IndexKind)[1]', 'varchar(128)') AS IndexKind,
			 cp.plan_handle,
			 query_plan,
			cp.size_in_bytes
			FROM sys.dm_exec_cached_plans AS cp 
			CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
			CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS batch(stmt)
			CROSS APPLY stmt.nodes('.//IndexScan/Object[@Index=sql:variable("@IndexName")]') AS idx(obj)
			OPTION(MAXDOP 1, RECOMPILE);
			
	-- Поиск везде
		;WITH XMLNAMESPACES
			(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')   
		SELECT
			dm_exec_sql_text.text AS sql_text,
			CAST(CAST(dm_exec_query_stats.execution_count AS DECIMAL) / CAST((CASE WHEN DATEDIFF(HOUR, dm_exec_query_stats.creation_time, CURRENT_TIMESTAMP) = 0 THEN 1 ELSE DATEDIFF(HOUR, dm_exec_query_stats.creation_time, CURRENT_TIMESTAMP) END) AS DECIMAL) AS INT) AS executions_per_hour,
			dm_exec_query_stats.creation_time, 
			dm_exec_query_stats.execution_count,
			CAST(CAST(dm_exec_query_stats.total_worker_time AS DECIMAL)/CAST(dm_exec_query_stats.execution_count AS DECIMAL) AS INT) as cpu_per_execution,
			CAST(CAST(dm_exec_query_stats.total_logical_reads AS DECIMAL)/CAST(dm_exec_query_stats.execution_count AS DECIMAL) AS INT) as logical_reads_per_execution,
			CAST(CAST(dm_exec_query_stats.total_elapsed_time AS DECIMAL)/CAST(dm_exec_query_stats.execution_count AS DECIMAL) AS INT) as elapsed_time_per_execution,
			dm_exec_query_stats.total_worker_time AS total_cpu_time,
			dm_exec_query_stats.max_worker_time AS max_cpu_time, 
			dm_exec_query_stats.total_elapsed_time, 
			dm_exec_query_stats.max_elapsed_time, 
			dm_exec_query_stats.total_logical_reads, 
			dm_exec_query_stats.max_logical_reads,
			dm_exec_query_stats.total_physical_reads, 
			dm_exec_query_stats.max_physical_reads,
			dm_exec_query_plan.query_plan
		FROM sys.dm_exec_query_stats
		CROSS APPLY sys.dm_exec_sql_text(dm_exec_query_stats.sql_handle)
		CROSS APPLY sys.dm_exec_query_plan(dm_exec_query_stats.plan_handle)
		WHERE query_plan.exist('//RelOp[@PhysicalOp = "Index Scan"]') = 1
			   OR query_plan.exist('//RelOp[@PhysicalOp = "Clustered Index Scan"]') = 1
		ORDER BY dm_exec_query_stats.total_worker_time DESC;
	
			
-- Планы с проблемой Probe Residual
	WITH xmlnamespaces(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
	SELECT DEQP.query_plan,
		   DEST.text,
		   RO.X.value('@PhysicalOp', 'nvarchar(50)') as PhysicalOp,
		   RO.X.value('@LogicalOp', 'nvarchar(50)') as LogicalOp,
		   RO.X.value('@EstimatedTotalSubtreeCost', 'float') as EstimatedTotalSubtreeCost,DECP.*,DEQP.*,DEST.*
	FROM sys.dm_exec_cached_plans AS DECP
	  CROSS APPLY sys.dm_exec_query_plan(DECP.plan_handle) AS DEQP
	  CROSS APPLY sys.dm_exec_sql_text(DECP.plan_handle) as DEST
	  CROSS APPLY DEQP.query_plan.nodes('//RelOp[Hash/ProbeResidual]') as RO(X)
	--WHERE DEST.[text] not like '%sys.%' AND DEST.[text] not like '%syscollector%'
	ORDER BY EstimatedTotalSubtreeCost DESC


-- Похожие запросы в кэше, которые отличаются параметрами
	SELECT st.text, qs.query_hash
	FROM sys.dm_exec_query_stats qs 
	CROSS APPLY sys.dm_exec_sql_text (qs.sql_handle) st
	WHERE st.text = 'SELECT P.FirstName, P.LastName
	FROM Person.Person AS P
	WHERE P.FirstName = ''Amanda''
	' OR st.text = 'SELECT P.FirstName, P.LastName
	FROM Person.Person AS P
	WHERE P.FirstName = ''Logan''
	'
	GO

-- Подменить план запроса. Необходимо заменять все одинакрные кавычки двойными
	- SELECT * FROM Sys.Plan_Guides
	- Можно сделать параметризацию для простых планов с помощью @type = N'TEMPLATE'
	- Можно сделать план гайд на основе handle sp_create_plan_guide_from_handle  
	
	- EXECUTE sp_Create_Plan_Guide (создание плана) @hints N'Option(USE PLAN N"xml plan")', чтобы для OPTION получить xml план, надо сделать верный запрос и в соединении поставить флаг SET SHOWPLAN_XML ON
		EXEC sp_create_plan_guide 
		@name = N'Guide1',  -- имя плана
		@stmt = N'SELECT TOP 1 *  -- запрос
				  FROM Sales.SalesOrderHeader 
				  ORDER BY OrderDate DESC', 
		@type = N'SQL', -- тип
		@module_or_batch = NULL, -- процедура или её отсутвие
		@params = NULL, -- параметры
		@hints = N'OPTION (MAXDOP 1)'; -- хинты
		
	- EXECUTE sp_control_plan_guide
	- Удаление плана
		EXEC sp_control_plan_guide N’drop’, N’RemovePlan’
		
	- Имитация параметризации. На выходе получим то, как параметризирует сервер данный запрос
		DECLARE @my_templatetext nvarchar(max)
		DECLARE @my_parameters nvarchar(max)
		EXEC sp_get_query_template 
			N'SELECT pi.ProductID, SUM(pi.Quantity) AS Total
				FROM Production.ProductModel pm 
				INNER JOIN Production.ProductInventory pi
				ON pm.ProductModelID = pi.ProductID
				WHERE pi.ProductID = 2
				GROUP BY pi.ProductID, pi.Quantity
				HAVING SUM(pi.Quantity) > 400',
		@my_templatetext OUTPUT,
		@my_parameters OUTPUT;
		SELECT @my_templatetext;
		SELECT @my_parameters;
		
	-- Как часто использовались планы (Plan Guides)
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
		WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan') 
		SELECT  
		   dbName, 
		   PlanGuideName, 
		   SUM(refcounts) AS TotalRefCounts, 
		   SUM(usecounts) AS TotalUseCounts 
		FROM 
		( 
		   SELECT  
			   query_plan.value('(/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/@TemplatePlanGuideDB)[1]', 'varchar(128)') AS dbName, 
			   query_plan.value('(/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/@TemplatePlanGuideName)[1]', 'varchar(128)') AS PlanGuideName, 
			   refcounts, 
			   usecounts 
		   FROM sys.dm_exec_cached_plans 
		   CROSS APPLY sys.dm_exec_query_plan(plan_handle) 
		   WHERE query_plan.exist('(/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple[@TemplatePlanGuideName])[1]')=1 
		) AS tab 
		GROUP BY dbName, PlanGuideName
		
	-- Проверить корректность планов
		SELECT 
			plan_guide_id, msgnum, severity, state, message, 
			name, create_date, is_disabled, query_text, scope_type_desc, scope_batch, parameters, hints
		FROM sys.plan_guides
		CROSS APPLY fn_validate_plan_guide(plan_guide_id);
		
	-- Сохранить план запроса в памяти навсегда
		-- Получить план из кэша
			DECLARE @plan_handle varbinary(64);
			DECLARE @offset int;
			SELECT @plan_handle = plan_handle, @offset = qs.statement_start_offset
			FROM sys.dm_exec_query_stats AS qs
			CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS st
			CROSS APPLY sys.dm_exec_text_query_plan(qs.plan_handle, qs.statement_start_offset, qs.statement_end_offset) AS qp
			WHERE text LIKE N'%SELECT DISTINCT "pr"."id"  FROM  (((((((((((((((((("ProblemReport" "pr" LEFT OUTER JOIN "UserFields698"%';

			-- Сохранить план в памяти
			EXECUTE sp_create_plan_guide_from_handle 
				@name =  N'Guide1',
				@plan_handle = @plan_handle,
				@statement_start_offset = @offset;
			GO
			-- Проверить что план сохранился
			SELECT * FROM sys.plan_guides
			WHERE scope_batch LIKE N'SELECT WorkOrderID, p.Name, OrderQty, DueDate%';
			
	-- Увеличить время жизни запроса (увеличит в 2 раза счётчик при сбосе запросов)
		KEEP PLAN
		keep fixedplan 

-- Запросы с одинаковой логикой. Если значений много, то стоит позадуматься о замене их параметризированной инструкцией. Это позволит серверу использовать один план, а не много
	-- query_hash (хэш запроса) и Query_plan_hash (хэш плана запроса) уникальный для плана запроса при возможных различных написаний одного и того же запроса, например с лишним пробелом 
	SELECT COUNT(*) AS [Count], query_stats.query_hash, 
		query_stats.statement_text AS [Text]
	FROM 
		(SELECT QS.*, 
		SUBSTRING(ST.text, (QS.statement_start_offset/2) + 1,
		((CASE statement_end_offset 
			WHEN -1 THEN DATALENGTH(ST.text)
			ELSE QS.statement_end_offset END 
				- QS.statement_start_offset)/2) + 1) AS statement_text
		 FROM sys.dm_exec_query_stats AS QS
		 CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) as ST) as query_stats
	GROUP BY query_stats.query_hash, query_stats.statement_text
	ORDER BY 1 DESC

-- Место, занимаемое разовыми запросами в кэше/размер памяти для планов/plan cache count
	SELECT objtype AS [CacheType]
			, count_big(*) AS [Total Plans]
			, sum(cast(size_in_bytes as decimal(18,2)))/1024/1024 AS [Total MBs]
			, avg(usecounts) AS [Avg Use Count]
			, sum(cast((CASE WHEN usecounts = 1 THEN size_in_bytes ELSE 0 END) as decimal(18,2)))/1024/1024 AS [Total MBs - USE Count 1]
			, sum(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) AS [Total Plans - USE Count 1]
	FROM sys.dm_exec_cached_plans
	GROUP BY objtype
	ORDER BY [Total MBs - USE Count 1] DESC
	go

-- Решение вопроса
	1. Clearing *JUST* the 'SQL Plans' based on *just* the amount of Adhoc/Prepared single-use plans (2005/2008):
		DECLARE @MB decimal(19,3)
				, @Count bigint
				, @StrMB nvarchar(20)


		SELECT @MB = sum(cast((CASE WHEN usecounts = 1 AND objtype IN ('Adhoc', 'Prepared') THEN size_in_bytes ELSE 0 END) as decimal(12,2)))/1024/1024 
				, @Count = sum(CASE WHEN usecounts = 1 AND objtype IN ('Adhoc', 'Prepared') THEN 1 ELSE 0 END)
				, @StrMB = convert(nvarchar(20), @MB)
		FROM sys.dm_exec_cached_plans


		IF @MB > 10
				BEGIN
						DBCC FREESYSTEMCACHE('SQL Plans') 
						RAISERROR ('%s MB was allocated to single-use plan cache. Single-use plans have been cleared.', 10, 1, @StrMB)
				END
		ELSE
				BEGIN
						RAISERROR ('Only %s MB is allocated to single-use plan cache – no need to clear cache now.', 10, 1, @StrMB)
						– Note: this is only a warning message and not an actual error.
				END
		go

	2. Clearing *ALL* of your cache based on the total amount of wasted by single-use plans (2005/2008):
		DECLARE @MB decimal(19,3)
				, @Count bigint
				, @StrMB nvarchar(20)


		SELECT @MB = sum(cast((CASE WHEN usecounts = 1 THEN size_in_bytes ELSE 0 END) as decimal(12,2)))/1024/1024 
				, @Count = sum(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END)
				, @StrMB = convert(nvarchar(20), @MB)
		FROM sys.dm_exec_cached_plans

		IF @MB > 1000
				DBCC FREEPROCCACHE
		ELSE
				RAISERROR ('Only %s MB is allocated to single-use plan cache – no need to clear cache now.', 10, 1, @StrMB)
		go

	3. Stored Procedure to report/track + logic to go into a job based on percentage OR MB of wasted cache (2008 only):
		USE master
		go

		if OBJECTPROPERTY(OBJECT_ID('sp_SQLskills_CheckPlanCache'), 'IsProcedure') = 1
			DROP PROCEDURE sp_SQLskills_CheckPlanCache
		go

		CREATE PROCEDURE sp_SQLskills_CheckPlanCache
			(@Percent	decimal(6,3) OUTPUT,
			 @WastedMB	decimal(19,3) OUTPUT)
		AS
		SET NOCOUNT ON

		DECLARE @ConfiguredMemory	decimal(19,3)
			, @PhysicalMemory		decimal(19,3)
			, @MemoryInUse			decimal(19,3)
			, @SingleUsePlanCount	bigint

		CREATE TABLE #ConfigurationOptions
		(
			[name]				nvarchar(35)
			, [minimum]			int
			, [maximum]			int
			, [config_value]	int				-- in bytes
			, [run_value]		int				-- in bytes
		);
		INSERT #ConfigurationOptions EXEC ('sp_configure ''max server memory''');

		SELECT @ConfiguredMemory = run_value/1024/1024 
		FROM #ConfigurationOptions 
		WHERE name = 'max server memory (MB)'

		SELECT @PhysicalMemory = total_physical_memory_kb/1024 
		FROM sys.dm_os_sys_memory

		SELECT @MemoryInUse = physical_memory_in_use_kb/1024 
		FROM sys.dm_os_process_memory

		SELECT @WastedMB = sum(cast((CASE WHEN usecounts = 1 AND objtype IN ('Adhoc', 'Prepared') 
										THEN size_in_bytes ELSE 0 END) AS DECIMAL(12,2)))/1024/1024 
			, @SingleUsePlanCount = sum(CASE WHEN usecounts = 1 AND objtype IN ('Adhoc', 'Prepared') 
										THEN 1 ELSE 0 END)
			, @Percent = @WastedMB/@MemoryInUse * 100
		FROM sys.dm_exec_cached_plans

		SELECT	[TotalPhysicalMemory (MB)] = @PhysicalMemory
			, [TotalConfiguredMemory (MB)] = @ConfiguredMemory
			, [MaxMemoryAvailableToSQLServer (%)] = @ConfiguredMemory/@PhysicalMemory * 100
			, [MemoryInUseBySQLServer (MB)] = @MemoryInUse
			, [TotalSingleUsePlanCache (MB)] = @WastedMB
			, TotalNumberOfSingleUsePlans = @SingleUsePlanCount
			, [PercentOfConfiguredCacheWastedForSingleUsePlans (%)] = @Percent
		GO

		EXEC sys.sp_MS_marksystemobject 'sp_SQLskills_CheckPlanCache'
		go

		-----------------------------------------------------------------
		-- Logic (in a job?) to decide whether or not to clear - using sproc...
		-----------------------------------------------------------------

		DECLARE @Percent		decimal(6, 3)
				, @WastedMB		decimal(19,3)
				, @StrMB		nvarchar(20)
				, @StrPercent	nvarchar(20)
		EXEC sp_SQLskills_CheckPlanCache @Percent output, @WastedMB output

		SELECT @StrMB = CONVERT(nvarchar(20), @WastedMB)
				, @StrPercent = CONVERT(nvarchar(20), @Percent)

		IF @Percent > 10 OR @WastedMB > 10
			BEGIN
				DBCC FREESYSTEMCACHE('SQL Plans') 
				RAISERROR ('%s MB (%s percent) was allocated to single-use plan cache. Single-use plans have been cleared.', 10, 1, @StrMB, @StrPercent)
			END
		ELSE
			BEGIN
				RAISERROR ('Only %s MB (%s percent) is allocated to single-use plan cache - no need to clear cache now.', 10, 1, @StrMB, @StrPercent)
					-- Note: this is only a warning message and not an actual error.
			END
		go
		
-- parallel plans/параллельные планы
	SELECT
	p.dbid,
	p.objectid,
	p.query_plan,
	q.encrypted,
	q.TEXT,
	cp.usecounts,
	cp.size_in_bytes,
	cp.plan_handle
	FROM sys.dm_exec_cached_plans cp
	CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS p
	CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS q
	WHERE cp.cacheobjtype = 'Compiled Plan' AND p.query_plan.value('declare namespace
	p="http://schemas.microsoft.com/sqlserver/2004/07/showplan"; max(//p:RelOp/@Parallel)', 'float') > 0
	
	
-- Получить plan handle по query plan hash
	SELECT top 10 * FROM sys.dm_exec_query_stats WHERE query_plan_hash = 0x19FEAFBB9B62F12F

	-- сбросить план по plan handle
		DBCC FREEPROCCACHE(0x02000000BDD2DB12D651AE3E367410BA02D6617886A524F80000000000000000000000000000000000000000)