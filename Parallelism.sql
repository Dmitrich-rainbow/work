-- max degree of parallelism/maxdop/cxpachet
	- https://www.red-gate.com/simple-talk/sql/learn-sql-server/understanding-and-using-parallelism-in-sql-server/
	- https://sqlperformance.com/2013/10/sql-plan/parallel-plans-branches-threads
	- Определяет оптимальную степень параллелизма, то есть количество процессоров, задействованных
	  для выполнения одной инструкции, для каждого из планов параллельного выполнения
	- 0 для включения, 1 для отключения, если больше, то укажем какое количество процессоров
	- Если установлен Hyper-trading, то указывать число реальных ядер
	- Указывать параллелизм не более чем количество процессоров в ноде памяти
	- Потоки делялся на отдельные однопоточные сессии 
	- Переопределить глобальную настройку для конкретного запроса
		SELECT ProductID, OrderQty
		FROM Sales.SalesOrderDetail
		ORDER BY ProductID, OrderQty
		OPTION (MAXDOP 2);			
	-- или
		ALTER INDEX ALL ON Person.Person REBUILD OPTION (MAXDOP 8)
		ALTER INDEX [IX_SalesOrderDetail_ProductID] ON [Sales].[SalesOrderDetail] REBUILD WITH (MAXDOP = 8);
		
	- If you have very small number of queries that are executing at the same time compared with the number of processors, you can set the MAXDOP value to a larger value. For example, you can set the MAXDOP value to 16.  
	- If you a have very large number of queries that are executing at the same time compared with the number of processors, you can set the MAXDOP value to a smaller value. For example, you can set the MAXDOP value to 4. 

	- Рекомендации
		"Отсюда следует, что для систем, в которых больше 8-и процессоров рекомендуется ставить 'max degree of parallelism' = 8. Далее следует ещё одно пояснение, в котором говорится, что 8 – общая рекомендация. И в системах, где число одновременно выполняющихся запросов невелико имеет смысл ставить большее значение, а в системах с большим количеством конкурентных запросов ноборот меньшее. И, выбирая конкретный параметр, необходимо смотреть на его влияние на систему и тестировать на конкретных запросах."

	- Рекомендации от PINAL DAVE and Paul Randal
		1. На OLTP лучше ставить 1;
		2. На Warehouse - 0;
		3 Set MAXDOP to 1 if youre seeing CXPACKET waits as the prevalent wait type.
		4. Set MAXDOP to the number of cores in the NUMA node
		5. На смешанном режиме (2 и повысить цену попадения в параллелизм):
		EXEC sys.sp_configure N'cost threshold for parallelism', N'25'
		GO
		EXEC sys.sp_configure N'max degree of parallelism', N'2'
		GO
		RECONFIGURE WITH OVERRIDE
		GO		
		
	-- Рекомендации
		1. Не более чем процессоров в 1 Нуме, чтобы не использовать др. память. (лучше половину процессоров внутри нумы)
			select parent_node_id, Count(*)
				from sys.dm_os_schedulers
				where [status] = 'VISIBLE ONLINE'
					and parent_node_id < 64
				GROUP BY parent_node_id 
				
-- Проблемы
	1. Некачественное разделение строк, но Parallel Page Supplier помогает загружать другие потоки пока плохой считает
	2. Загруженность ряда ядер другими процессами

-- Особенности
	1. Количество зарешервированных threads = количество branches * DOP
	2. used threads - the number of branches reported is the maximum number that can be executing concurrently. 
					- The second part of the answer is that threads may still be reused if they happen to complete before a thread in another branch starts up
	
-- Операторы
	-- Stream Aggregate
		Sort?
		
	-- Gather Streams exchange
		It always runs on a single thread – the same one used to run the whole of a regular serial plan. This thread is always labelled 'Thread 0' in execution plans and is sometimes called the 'coordinator' thread (a designation I dont find particularly helpful).
		
	-- Parallel Page Supplier 
		Занимается распределением строк между потоками
		
	-- Partitioning Type
		Hash - Most common. The consumer is chosen by evaluating a hash function on one or more column values in the current row.
		Round Robin - Each new row is sent to the next consumer in a fixed sequence.
		Broadcast - Each row is sent to all consumers.
		Demand - The row is sent to the first consumer that asks for one. This is the only partitioning type where rows are pulled from the producer by the consumer inside the exchange operator.
		Range - Each consumer is assigned a non-overlapping range of values. The range into which a particular input column falls determines which consumer gets the row.

	-- Вызывающие Sort
		 Stream Aggregate, Segment, and Merge Join
		
-- Посмотреть как ведут себя планировщики
	SELECT * FROM dm_os_schedulers

-- Посмотреть активность потоков
	SELECT
		[owt].[session_id],
		[owt].[exec_context_id],
		[owt].[wait_duration_ms],
		[owt].[wait_type],
		[owt].[blocking_session_id],
		[owt].[resource_description],
		[er].[database_id],
		[eqp].[query_plan]
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
		
-- Какие запросы используют параллельные планы
	SELECT TOP 10
	p.*,
	q.*,
	qs.*,
	cp.plan_handle
	FROM
	sys.dm_exec_cached_plans cp
	CROSS apply sys.dm_exec_query_plan(cp.plan_handle) p
	CROSS apply sys.dm_exec_sql_text(cp.plan_handle) AS q
	JOIN sys.dm_exec_query_stats qs
	ON qs.plan_handle = cp.plan_handle
	WHERE
	cp.cacheobjtype = 'Compiled Plan' AND
	p.query_plan.value('declare namespace p="http://schemas.microsoft.com/sqlserver/2004/07/showplan";
	max(//p:RelOp/@Parallel)', 'float') >0
	OPTION (MAXDOP 1)
	
-- Экспресс тест MAXDOP/max degree of parallelism
	declare @hyperthreadingRatio int
	declare @logicalCPUs int
	declare @HTEnabled int
	declare @physicalCPU int
	declare @SOCKET int
	declare @logicalCPUPerNuma int
	declare @NoOfNUMA int
	declare @MaxDOP int
	declare @MaxDOP_Cur int

	select @logicalCPUs = cpu_count -- [Logical CPU Count]
		,@hyperthreadingRatio = hyperthread_ratio --  [Hyperthread Ratio]
		,@physicalCPU = cpu_count / hyperthread_ratio -- [Physical CPU Count]
		,@HTEnabled = case
			when cpu_count > hyperthread_ratio
				then 1
			else 0
			end -- HTEnabled
	from sys.dm_os_sys_info
	option (recompile); 

	select @logicalCPUPerNuma = COUNT(parent_node_id) -- [NumberOfLogicalProcessorsPerNuma]
	from sys.dm_os_schedulers
	where [status] = 'VISIBLE ONLINE'
		and parent_node_id < 64
	group by parent_node_id
	option (recompile); 

	select @NoOfNUMA = count(distinct parent_node_id)
	from sys.dm_os_schedulers -- find NO OF NUMA Nodes
	where [status] = 'VISIBLE ONLINE'
		and parent_node_id < 64 

	IF @NoofNUMA > 1 AND @HTEnabled = 0
		SET @MaxDOP= @logicalCPUPerNuma
	ELSE IF  @NoofNUMA > 1 AND @HTEnabled = 1
		SET @MaxDOP=round( @NoofNUMA  / @physicalCPU *1.0,0)
	ELSE IF @HTEnabled = 0
		SET @MaxDOP=@logicalCPUs
	ELSE IF @HTEnabled = 1
		SET @MaxDOP=@physicalCPU 

	IF @MaxDOP > 10
		SET @MaxDOP=10
	IF @MaxDOP = 0
		SET @MaxDOP=1 

	PRINT 'logicalCPUs : '         + CONVERT(VARCHAR, @logicalCPUs)
	PRINT 'hyperthreadingRatio : ' + CONVERT(VARCHAR, @hyperthreadingRatio)
	PRINT 'physicalCPU : '         + CONVERT(VARCHAR, @physicalCPU)
	PRINT 'HTEnabled : '           + CONVERT(VARCHAR, @HTEnabled)
	PRINT 'logicalCPUPerNuma : '   + CONVERT(VARCHAR, @logicalCPUPerNuma)
	PRINT 'NoOfNUMA : '            + CONVERT(VARCHAR, @NoOfNUMA)

	PRINT '---------------------------'

	Print 'MAXDOP setting should be : ' + CONVERT(VARCHAR, @MaxDOP)

	--sp_configure 'max degree of parallelism'

	set @MaxDOP_Cur=(SELECT CAST([value] as int)

	FROM sys.configurations where name='max degree of parallelism')

	Print 'MAXDOP current is        : ' + convert(varchar,@MaxDOP_Cur)			
	
-- cost threshold for parallelism
	- Параметр cost threshold for parallelism предназначен для указания порогового значения, по которому
	  SQL Server создает и выполняет параллельные планы запросов. Стоимость означает оценочное значение
	  времени (в секундах), необходимое для выполнения последовательного плана на данной конфигурации
	  оборудования. Параметр cost threshold for parallelism следует устанавливать только на симметричных
	  мультипроцессорах (SMP). Параметр вступает в силу немедленно, без перезапуска сервера.
	  
	-- Поиск запросов, которым бы помог параллелизм. Так же можно узнать какое число для threshold for parallelism необходимо выбрать
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 

		WITH XMLNAMESPACES   
		   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')  
		SELECT  
				query_plan AS CompleteQueryPlan, 
				n.value('(@StatementText)[1]', 'VARCHAR(4000)') AS StatementText, 
				n.value('(@StatementOptmLevel)[1]', 'VARCHAR(25)') AS StatementOptimizationLevel, 
				n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)') AS StatementSubTreeCost, -- Оцениваем по данному параметру
				n.query('.') AS ParallelSubTreeXML,  
				ecp.usecounts, 
				ecp.size_in_bytes 
		FROM sys.dm_exec_cached_plans AS ecp 
		CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS eqp 
		CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qn(n) 
		WHERE  n.query('.').exist('//RelOp[@PhysicalOp="Parallelism"]') = 1
			   -- n.value('(@StatementSubTreeCost)[1]', 'float') > 10	Если хотим поискать просто дорогие запросы
  
  
-- Параллелизм/parallelism
	- Всегда есть root exchange
	- Mergind Exchange означает что используется сортировка
	- В плане выполнения, в свойствах, есть ThreadStats >> Branches (какое количество одновременное выполнялось)
  
-- В каких случаях параллелизм не работает
	- scalar user defined functions
	
-- Columnstore
	- Максимум 1 поток на 1 rowgroup