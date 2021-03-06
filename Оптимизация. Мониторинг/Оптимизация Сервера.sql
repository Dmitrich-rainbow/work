-- Настройка базы (если есть какие-то ссылки на внутренности файла, смотреть в 6231.sql)
 1. Настроить память (http://msdn.microsoft.com/en-us/library/cc645993(v=SQL.110).aspx#CrossBoxScale - ограничения по памяти в зависимости от редакции/ограничение памяти)
 2. Настроить приоритет фоновым задачам (свйоство "мой компьютер" > "Быстродействие")
 3. Натсроить приоритет приложениям в памяти
 4. Настроить в сети "Файлы и приложения", приоритет приложениям
 5. Отключить автоматическое сжатие таблиц (Auto Shrink), чтобы не тратились ресурсы
 6. Распределить файл базы и логов на разные диски и в разные файловые группы
 7. Желательно вынести базу данных на другой дисковый массив от системы
 8. Желательно не использовать сервер, как сервер файловое хранилище
 9. Файл подкачки желательно располагать не на одном диске с файлами БД. Для производительности SQL сервера роли не играет, нужно добавлять столько, сколько нужно для сторонних приложений или создания дампа памяти
 10. Дать локальному админу права "serveradmin", чтобы можно было заходить в single mode
 11. Отключить службы (если не используются):
		- SQL Full-text Filter Daemon Launcher (MSSQLSERVER)
		- SQL Server VSS Writer 
 12. Добавить файлы баз в исключения антивируса
 13. Запускать sql под пользователем с минимальными правами
 14. Закрыть порты udp 137(netBIOS),138 (через настройки сети)
 15. Закрыть порты TCP 139,445 (через настройки сети)
 16. Отключить начальную трассировку
	exec sp_configure 'default trace enabled', 0
	RECONFIGURE;
	GO
 17. Проверить фрагментацию дисков
 18. Проверить в конфигурации оборудования включено ли кеширование у дискового массива
 19. (Проверять обязательно) 
	ALTER DATABASE MyDatabase
	SET ALLOW_SNAPSHOT_ISOLATION ON

	ALTER DATABASE MyDatabase
	SET READ_COMMITTED_SNAPSHOT ON
21. Настроить пинг серверов и пинг сервера мониторинга
22. Наладить работу проверки backup (RestoreChecker - создаёт в master 2 базы,одна - результат работы, вторая - какие сервера проверять с параметрами)
23. Настроить предупреждение важности выше 24
24. Включить моментальное увеличение файла журнала (instant file initialization)	
25. Update Indexes
26. Update Statistics
27. Настроить Alert на 1205 и сделать, чтобы deadlock регистрировались в журнале. Так же настроить алерты для особых важностей F:\SQL Scripts\Скрипты\Add SQL Server Agent Alerts.sql
29. Установить в базу master процедуру sp_WhoIsActive (\SQL Scripts\Скрипты) от Adam Machanic
30. Включить блокировку страниц в памяти ('lock page in memory')
32. Сделать холодную копию master/model
33. Рассмотреть возможность включения флагов 1117,1118,2371,3226,4199,8048,845
34. Отключить полнотекстовый поиск, если не используем
35. Сделать в локальной политике безопастности "Выполнение задач по обслуживанию томов" для пользователя БД
36. Forced Parameterization, если много планов с 1 вызовом
37. Диагностика сервера (F:\SQL Scripts\Скрипты\SQL Server 2005 Diagnostic Information Queries...)
38. Проверить "Использование памяти по базам" (искать в этом файле)
39. Улучшение пропускной способоности сетевой платы (http://sqlcom.ru/dba-tools/ethernet-rss/)
40. Выдавате для SQL Server Standart Edition памяти больше, чем возможные лимиты
41. Флаги для ускорения работы SQL Server http://support.microsoft.com/kb/920093/ru и http://sqlcom.ru/helpful-and-interesting/settings-windows-server-20032008-for-sql-server-2008/
42. Размещать пользовательские данные не в группе PRIMARY, например чтобы можно было потом переместить данные в другой файл
44. Можно добавить сжатие для архивных таблиц, это позволит уменьшить нагрузку на диск. Не добавлять сжатие для активной части БД (OLTP нагрузка)
45. Не совмещайте работы SQL Server с любыми другими приложениями
46. Установите "Max Server Memory" и "Min Server Memory". Второе чтобы SQL Server не тратил ресурсы на высвобождение памяти ниже нижней границы
47. Выставить High Performance в Power Option (https://sqlserverperformance.wordpress.com/2010/09/28/windows-power-plans-and-cpu-performance/)
48. Всегда включайте hyper-threading and Turbo Boost (https://sqlserverperformance.wordpress.com/2010/09/28/windows-power-plans-and-cpu-performance/)
49. Несколько файлов tempdb и флаг 1117. Флаг 1118 должен быть включён на всех серверах по мнению Poul Randal (поведение не изменилось даже в SQL Server 2016)
	-- Так же рассмотреть
		USE [master]
		GO
		ALTER DATABASE [tempdb] SET PAGE_VERIFY NONE  WITH NO_WAIT
		GO
		ALTER DATABASE [tempdb] SET DELAYED_DURABILITY = ALLOWED WITH NO_WAIT
		GO
		ALTER DATABASE [tempdb] SET AUTO_UPDATE_STATISTICS OFF WITH NO_WAIT
		GO
		ALTER DATABASE [tempdb] SET AUTO_UPDATE_STATISTICS_ASYNC ON WITH NO_WAIT
		GO
50. Обычно Количество max worker threads стоит в дефолтном значении (0), что позволяет SQL Server самостоятельно управлять потоками, но иногда это требутеся поменять (см. описание в этой файле)
51. Если сервер давно живёт, то можно удалить логи backup, заданий и тд ("Очистка истории" см. в этом файле)
52. На серверах с большим количеством CPU, не оставлять 'max degree of parallelism' на 0. Беспроигрышный вариант 1, но не самый оптимальный. Для запросов с hash join можно руками задать больший параллелизм, это будет быстрее
53. cost threshold for parallelism начиная с 25
54. Проверить настройку питания "сохранение энергии" в биосе, cpuz.exe покажет на каких частотах работает процессор
55. В 2014 новый движок оценки стоимости запросов, его можно отключить опцией в БД
56. Выставить в SSMS опцию SET ARITHABORT в OFF, чтобы мы работали как ADO.Net и др языки и получали те же планы
57. Если SQL Server 2012 ниже SP3, то надо включить TF 272, чтобы не ловить проблему RESEED IDENTITY если значение меньше 1000 и был рестарт (https://connect.microsoft.com/SQLServer/feedback/details/739013/failover-or-restart-results-in-reseed-of-identity%E2%80%8C%E2%80%8C)
58. Можно включить буферизацию на запись на диске с tempdb
59. Найти проблемы с индексами - EXEC master.dbo.sp_BlitzIndex @DatabaseName = N'WWWBRON_H_6'
60. Найти большие кучи
	WITH table_space_usage ( schema_name, table_name, used, reserved, ind_rows, tbl_rows ) 
	AS (
	SELECT 
		s.Name 
		, o.Name 
		, p.used_page_count * 8 / 1024
		, p.reserved_page_count * 8 / 1024
		, p.row_count 
		, case when i.index_id in ( 0, 1 ) then p.row_count else 0 end 
	FROM sys.dm_db_partition_stats p 
		INNER JOIN sys.objects as o ON o.object_id = p.object_id 
		INNER JOIN sys.schemas as s ON s.schema_id = o.schema_id 
		LEFT OUTER JOIN sys.indexes as i on i.object_id = p.object_id and i.index_id = p.index_id and i.type=0
	WHERE o.type_desc = 'USER_TABLE' and o.is_ms_shipped = 0
		) 

	SELECT t.schema_name 
			, t.table_name 
			, sum(t.used) as used_in_mb 
			, sum(t.reserved) as reserved_in_mb
			,sum(t.tbl_rows) as rows 
	FROM table_space_usage as t 
	GROUP BY t.schema_name , t.table_name 
	ORDER BY used_in_mb desc

	-- Потом сделать по ним анализ	
		EXEC master.dbo.sp_BlitzIndex @DatabaseName = N'Crap',
                              @SchemaName = N'dbo',
                              @TableName = N'HeapMe';
61. Нати проблемы Page Split (искать в файле "Page Split.sql")
62. Флаги для высоконагруженных систем	(искать в файле "Flags.sql")
63. Рассмотреть принудительную параметризацию, если много запросов со схожим query_hash и с execution_count = 1
64. Изучить dm_exec_query_optimizer_info
65. Рассмотреть возможность T8780 для отдельных запросов
66. Рассмотреть возможность включение ad-hoc
67. Рассмотреть возможность отключения параметризации
	
	

-- Диагностика сервера/оптимизация сервера/наблюдение за сервером
	F:\SQL Scripts\Скрипты\SQL Server 2005 Diagnostic Information Queries...
	
	-- Статистика/Оптимизация/Запросы (Кимберли)
		- DBCC SHOW_STATISTICS('Table','Index') WITH HISTOGRAM
		- Если выполнить запрос с конкретным значением, то оптимизатор поймёт его и будет пользоваться статистикой, если передать в запрос параметр - он не будет знать значение этого параметра и будет пользоваться не статистикой, а гистограммой. Как будто вы запустили процедуру в параметром WITH UNKNOWN
		- Если отключить автоматическое создание статистики, удалить её по нужному полю и выполнить запрос по нему, то у сервера не будет никакой информации, но ему нужно будет выполнить запрос и он будет рассчитывать что запрос вернёт 10% от строк
		- Если значения нет в гистограмме, но есть значение больше и меньше, то сервер будет использовать среднее значение между известными палями, это значение указано в большем значении (AVG_RANGE_ROWS)
		- Если разбить статистику на части, то может возникнуть ситуация, когда запросу понадобятся разные части и оптимизатор не сможет их взять и не возьмёт никакую, но можно разбить на 2 запроса и соединить их через UNION ALL
		- Для запросов и процедур с параметрами лучше RECOMPILE писать в запросе, а не в процедуре	
	
	-- Нужно проверить
		0. https://www.simple-talk.com/sql/database-administration/exploring-query-plans-in-sql/
		
		1. Если не знаю структуру, то ищу Scan Table и Clustered Index Scan (CROSS APPLY n.nodes('.//RelOp[IndexScan/Object[@Schema!="[sys]"]]') as s(i) -- Заменить последнее условие) -- Index scan
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
			
		2. Lookup
			SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
			WITH XMLNAMESPACES
			   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
			SELECT
				n.value('(@StatementText)[1]', 'VARCHAR(4000)') AS sql_text,
				n.query('.'),
				i.value('(@PhysicalOp)[1]', 'VARCHAR(128)') AS PhysicalOp,
				i.value('(./IndexScan/Object/@Database)[1]', 'VARCHAR(128)') AS DatabaseName,
				i.value('(./IndexScan/Object/@Schema)[1]', 'VARCHAR(128)') AS SchemaName,
				i.value('(./IndexScan/Object/@Table)[1]', 'VARCHAR(128)') AS TableName,
				i.value('(./IndexScan/Object/@Index)[1]', 'VARCHAR(128)') as IndexName,
				i.query('.'),
				STUFF((SELECT DISTINCT ', ' + cg.value('(@Column)[1]', 'VARCHAR(128)')
				   FROM i.nodes('./OutputList/ColumnReference') AS t(cg)
				   FOR  XML PATH('')),1,2,'') AS output_columns,
				STUFF((SELECT DISTINCT ', ' + cg.value('(@Column)[1]', 'VARCHAR(128)')
				   FROM i.nodes('./IndexScan/SeekPredicates/SeekPredicateNew//ColumnReference') AS t(cg)
				   FOR  XML PATH('')),1,2,'') AS seek_columns,
				i.value('(./IndexScan/Predicate/ScalarOperator/@ScalarString)[1]', 'VARCHAR(4000)') as Predicate,
				cp.usecounts,
				query_plan
			FROM (  SELECT plan_handle, query_plan
					FROM (  SELECT DISTINCT plan_handle
							FROM sys.dm_exec_query_stats WITH(NOLOCK)) AS qs
					OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) tp
				  ) as tab (plan_handle, query_plan)
			INNER JOIN sys.dm_exec_cached_plans AS cp 
				ON tab.plan_handle = cp.plan_handle
			CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/*') AS q(n)
			CROSS APPLY n.nodes('.//RelOp[IndexScan[@Lookup="1"] and IndexScan/Object[@Schema!="[sys]"]]') as s(i)			
			OPTION(RECOMPILE, MAXDOP 1);
			
		3. Spool (сброс данных в tempdb или сортировка там)
		4. Смотреть параллелизм
			SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
			WITH XMLNAMESPACES   
			(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')  
			SELECT  
				 query_plan AS CompleteQueryPlan, 
				 n.value('(@StatementText)[1]', 'VARCHAR(4000)') AS StatementText, 
				 n.value('(@StatementOptmLevel)[1]', 'VARCHAR(25)') AS StatementOptimizationLevel, 
				 n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)') AS StatementSubTreeCost, 
				 n.query('.') AS ParallelSubTreeXML,  
				 ecp.usecounts, 
				 ecp.size_in_bytes 
			FROM sys.dm_exec_cached_plans AS ecp 
			CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS eqp 
			CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qn(n) 
			WHERE  n.query('.').exist('//RelOp[@PhysicalOp="Parallelism"]') = 1 
		5. Оценочную величину строк и реальную
		6. Физические чтения
		7. Курсоров часто можно избежать http://bit.ly/AB-cursors
			Многие функции курсора не используются:
				- Вместо Global >> Local
				- Scrollable >> FAST_FORWARD
				- Dynaming (прочитать)
		8. Смотреть на NOT IN и значения NULL в нём. Можно заменить на NOT EXISTS (вернёт все строки) или EXCEPT (вернёт уникальные строки) http://bit.ly/AB-NOTIN
		9. WHERE IN против WHERE EXISTS (лучше, когда не нужны строки из другой таблицы, так как не надо делать JION)
		10. Используйте RECOMPILE на уровне запроса
		11. Если используйте DYnamic SQL, то включите "optimize for ad hoc workloads"
		12. Создавайте параметры с таким же типом, как и колонки. Неявное преобразование типов в памяти
				-- implicit conversion
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
				   stmt.value('(QueryPlan/@CompileTime)[1]', 'int') AS CompileTime_ms,
				   stmt.value('(QueryPlan/@CompileCPU)[1]', 'int') AS CompileCPU_ms,
				   stmt.value('(QueryPlan/@CompileMemory)[1]', 'int') AS CompileMemory_KB,
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
				OPTION (MAXDOP 8)
		13. Планы с высокой стоимостью компиляции
				SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
				WITH XMLNAMESPACES 
				(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
				SELECT TOP 10
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
				SUBSTRING(st.text, (qs.statement_start_offset / 2) + 1,
				(CASE qs.statement_end_offset
				WHEN -1 THEN DATALENGTH(st.text)
				ELSE qs.statement_end_offset
				END - qs.statement_start_offset) / 2 + 1) AS StmtText,
				query_hash,
				query_plan_hash
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
				ORDER BY CompileTime_ms DESC
				OPTION(RECOMPILE, MAXDOP 1);
		14. Достаточность памяти. Александр Гладченко
			-- По мотивам: http://bit.ly/LkT05M
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


-- sp_configure
	- Выполняет обновление конфигурации сервера
	- Если обычный 'RECONFIGURE' не помогает, значит изменение параметра не безопасно и выполнять его нужно с осторожностью и с опцией 'RECONFIGURE WITH OVERRIDE', возможно параметр выходит за пределы разрешённых значений
	- Если run_value=config_value, значит настройка применилась и сервер перезагружать не надо
	- Перед тем, как выполнить обновление, следует посмотреть есть ли не применённые настройки:
		SELECT * FROM sys.configurations WHERE [value] <> value_in_use
	- Параметры, которые могут быть применены без перезагрузки SQL SERVER
		SELECT * FROM sys.configurations WHERE is_dynamic = 1;
		
	-- lightweight pooling
		- By default, SQL Server operates in thread mode, which means that the workers processing SQL Server requests are threads. As described earlier, SQL Server also lets user connections run in fiber mode. Fibers are less expensive to manage than threads. The Lightweight Pooling option can have a value of 0 or 1; 1 means that SQL Server should run in fiber mode. Using fibers can yield a minor performance advantage, particularly when you have eight or more CPUs and all available CPUs are operating at or near 100 percent. However, the tradeoff is that certain operations, such as running queries on linked servers or executing extended stored procedures, must run in thread mode and therefore need to switch from fiber to thread. The cost of switching from fiber to thread mode for those connections can be noticeable and in some cases offsets any benefit of operating in fiber mode. If you’re running in an environment that uses a high percentage of total CPU resources, and if System Monitor shows a lot of context switching, setting Lightweight Pooling to 1 might yield some performance benefit.		
		
		- Certain SQL Server components don’t work—or don’t work well—when SQL Server runs in fiber mode. These components include SQLMail and SQLXML. Other components, such as heterogeneous and CLR queries, aren’t supported at all in fiber mode because they need certain thread-specific facilities provided by Windows.
		- In most environments, the performance benefit gained by fibers is quite small compared to the benefits you can get by tuning in other areas.
		
		-- Context switching
			- Когда более 2000-5000 на процессор - плохо
			
			-- Решение
				- 834
				- 8012
				- 8020
				- lightweight pooling

	-- max worker threads/максимальное количество одновременных запросов (формула)		
		- You can think of the SQL Server scheduler as a logical CPU used by SQL Server workers.
		- Если стоит значение 0, то сервер устанавливает следующие значения (когда max worker threads = 0)
				<= 4 процессоров	256 32-bit	512 64-bit
				8 процессоров	288	576
				16 процессоров	352	704
				32 процессора	480	960
				64 процессора	736	1472
				128 процессоров	4224	4480
				256 процессоров	8320	8576
		
		- 32x: 256 + (к-во логических CPU) * 8
		- 64x: 512 + (к-во логических CPU) * 8
		
		- 1024 является максимальным значением, рекомендуемым для 32-разрядных операционных систем SQL Server, 2048 — для 64-разрядных систем SQL Server.	
		- Если все потоки исполнителей заняты выполнением длительных запросов, SQL Server может не отвечать на другие запросы, пока один из потоков не завершит работу и не станет доступным. Хотя это и не ошибка, такое поведение иногда нежелательно. Если процесс не отвечает и новые запросы не могут быть обработаны, подключитесь к SQL Server через выделенное административное подключение (DAC) и уничтожьте процесс. Во избежание этого увеличьте максимальное число потоков управления.
		
		-- Как посчитать
			1. Каждое подключение создаёт поток
			2. Узнать какое количество потоков может использоваться
				SELECT max_workers_count FROM sys.dm_os_sys_info
				SELECT * FROM sys.dm_os_workers -- доступные в данный момент
			3. Если результат выполнения около 1, то значит есть очередь на потоки и требуется их добавить
				select AVG (work_queue_count) from sys.dm_os_schedulers where status = 'VISIBLE ONLINE'
				-- Более подробно
				select SUM(current_tasks_count) as current_tasks_count,
				SUM(current_workers_count) as current_workers_count,
				SUM(active_workers_count) as active_workers_count,
				AVG(work_queue_count) as work_queue_count
				from sys.dm_os_schedulers 
				where status = 'Visible Online'
			3
				
		
		-- Дополнительные системные потоки, которые так же должны быть посчитаны
			SELECT
				s.session_id,
				r.command,
				r.status,
				r.wait_type,
				r.scheduler_id,
				w.worker_address,
				w.is_preemptive,
				w.state,
				t.task_state,
				t.session_id,
				t.exec_context_id,
				t.request_id
			FROM sys.dm_exec_sessions AS s
			INNER JOIN sys.dm_exec_requests AS r
				ON s.session_id = r.session_id
			INNER JOIN sys.dm_os_tasks AS t
				ON r.task_address = t.task_address
			INNER JOIN sys.dm_os_workers AS w
				ON t.worker_address = w.worker_address
			WHERE s.is_user_process = 0;

-- Память/memmory
	SQLServer: Memory Manager – Memory Grants Pending (сколько запросов ждёт выделение памяти, данные запросы уже прошли все остальные стадии и ждут памяти, если больше 0 - проблемы)

	SQLServer: SQL Statistics – Compilations/sec более 10% от SQLServer: SQL Statistics – Batch Requests/sec и мы испытываем проблемы с SQLServer: Memory Manager – Memory Grants Pending - это проблемы с памятью

	-- Уменьшить потребление памяти
	1. Использовать параметризованные запросы
	2. Optimize for ad hoc
	
	-- Настройка
		1. Остаток для ОС 5% всей или 2-4 ГБ , что больше
		2. Память под ядро SQL Server (различные *.exe, *.dll, *ocx и пр. модули),	SQL heap, CLR. Обычно это до 500 MB, хотя за счет CLR это может	быть и больше.
		3. Память под кэши "Worker thread", рассчитываемая по формуле
		(512+(NumCpu-4)*16)*2 MB
		4. Итого под "max server memory" остается: OS Mem – 1. – 2(500 MB) - 3.7	= 471.2 GB. Т.е. размер Буферного пула (при таком значении "max	server memory") может вырасти до 471 GB. Для версии SQL 2012 и далее "max server memory" включает в себя SQL
		heap и частично CLR.


-- VLF
	1. Произвести дефрагментацию дисков, где будут лежать логи
	2. Создавать только по 1 файлу журнала
	3. Делайте увеличение журнала примерно на 400-800 мегобайт (чтобы увеличение происходило на 8 кусков, а не на 16), не стоит делать увеличение мелкими порциями. До 64 Мб получается 4 курсокв жунарала (Virtual Log Files), от 64Мб до 1Гб 8 кусков, всё что свыше 1Гб - 16.
		-- До SQL Server 2014
			- Менее 1 Мб, тут всё довольно сложно, игнорируйте этот вариант.
			- До 64 МБ: 4 новых VLF, каждый примерно 1/4 размера прироста
			- От 64 МБ до 1 ГБ: 8 новых VLF, каждый примерно 1/8 размер прироста
			- Более 1 GB: 16 новых VLF, каждый примерно 1/16 размер прироста
		-- В SQL Server 2014
			- Является ли размер прироста менее 1/8 размера журнала?
			- Да: создать 1 новый VLF, равный размеру прироста
			- Нет: воспользоваться приведенной ранее формулой			
	4. Если функция DBCC LOGINFO возвращает больше 50-200, то исправить ситуацию (лучше делать в момент наименьшей активности)
		1. Сделайте backup лога
		2. DBCC SHRINKFILE(transactionloglogicalfilename, TRUNCATEONLY)
		3. Увеличте файл журнала до нужного размера ALTER DATABASE databasename MODIFY FILE ( NAME = transactionloglogicalfilename, SIZE = newtotalsize)
		sp_helpfile -- посмотреть размер файлов и информацию о них
	5. Посмотреть рекомендации сервера по логу каждой базы/Что делать с логом(LOG)/рекомендуемые действия с логом(LOG)
		SELECT name,log_reuse_wait,log_reuse_wait_desc FROM sys.databases
	6. Пложить на отдельный диск
	7. Удалить неиспользуемые неластерные индексы и производить регулярную дефрагментацию, которая создаёт page split, которая в свою очередь нагружает лог. Page split создаёт в 40 раз большую нагрузку чем обычный INSERT
	8. Используйте RAID 1, если не нужна очень большая нагрузка

-- Размер кластера диска (NTFS)
	-- Общее
		64 Кб на файлы данных
		32 Кб на файлы логов
	-- Детали	
		Характер нагрузки |	Доступ:	случайный / последовательный | Преобладает:	чтение / запись | Размер запроса ввода-вывода
		Журнал транзакций OLTPсистемы	последовательный	запись	512 Б – 64 КБ
		Файлы данныхOLTPсистемы	случайный	чтение – запись	8 КБ
		Массовая вставка	последовательный	запись	от 8 КБ до 256 КБ
		Упреждающее чтение, просмотр индекса	последовательный	чтение	от 8 КБ до 256 КБ
		Резервное копирование	последовательный	чтение / запись	1 МБ
		Отложенная запись	последовательный	запись	от 128 КБ до 2 МБ
		Восстановление из копии	последовательный	чтение / запись	64 КБ
		Контрольная точка	последовательный	запись	от 8 КБ до 128 КБ
		CREATE DATABASE	последовательный	запись	512 КБ
		CHECKDB	последовательный	чтение	8 КБ – 64 КБ
		DBREINDEX	последовательный	чтение / запись	чтение: от 8 КБ до 256 КБ запись: от 8 КБ до 128 КБ
		SHOWCONTIG	последовательный	чтение	8 KБ – 64 КБ	
		
	-- Типы нагрузки/тип нагрузки
		Operation	Random/Sequential	Read/Write	Size Range
		OLTP - Log	Sequential	Write	512 bytes - 64KB
		OLTP - Data	Random	Read/Write	8K
		Bulk Insert	Sequential	Write	8KB - 128KB
		(in multiples of 8KB)
		Read Ahead	Sequential	Read	8KB - 256KB
		(in multiples of 8K)
		CREATE DATABASE	Sequential	Write	512KB
		Backup	Sequential	Read/Write	1MB
		Restore	Sequential	Read/Write	64KB
		DBCC CHECKDB	Sequential	Read	8KB - 64KB
		DBCC DBREINDEX
		(read phase)	Sequential	Read	(See Read Ahead)
		DBCC DBREINDEX
		(write phase)	Sequential	Write	8KB - 128KB
		(multiples of 8KB)
		DBCC SHOWCONTIG	Sequential	Read	8KB - 64KB
		
-- Размер кластера диска (массив)
	- Обычно это 1024 КБ
	- Рекомендации вендора для SQL Server
	
-- Тонкая оптимизация
	- ВАЖНО, ТОЛЬКО ДЛЯ TEMPDB (чтобы исключить потерю данных). Для включения кэширования операционной системой операций ввода-вывода логических дисков воспользуйтесь оснасткой Disk Management или Device Manager, перейдя в ней в узел Disk Drives. Для каждого настраиваемого устройства логического диска нужно выбрать Свойства (Properties) и перейти на закладку Policies. Для индивидуальной настройки дисков лучше подходит оснастка Disk Management, там настройки выполняются из свойств дисков, которые вызываются в графической, нижней части окна оснастки. Включение чекбокса “Enable write caching on the disk” разрешает кэширование записи на диск. После пометки этого чекбокса становится доступен для пометки второй чекбокс: “Enable advanced performance“. Включение обеих чекбоксов не только разрешает кэширование, но и заставляет операционную систему изымать из запросов ввода-вывода команды прямой записи на диск и сброса дискового кэша. Не рекомендуется включать эти чекбоксы если аппаратные кэши не имеют защиты от потери электропитания.
	- Необходимо настроить исключение сканирования файлов баз данных, журналов транзакций и резервных копий, которые типично имеют разрешения: mdf, ldf, ndf, bak и trn. Это позволит предотвратить повреждение этих файлов при попытке со стороны SQL Server их открытия, когда они уже открыты для проверки антивирусным ПО. Кроме того, необходимо принять меры для защиты каталогов полнотекстового поиска и содержащих данные Analysis Services от повреждений, связанных с активностью антивирусного программного обеспечения. Исключите также папку журналов SQL Server (MSSQL\Log), журнал ошибок открыт постоянно и в него может выводиться много событий. Если антивирусное ПО планируется использовать совместно с SQL Server работающем в кластере, нужно исключить сканирование кворум – диска и каталога: “c:\Windows\Cluster”. Для получения более подробной информации о требованиях к настройкам антивирусного ПО обратитесь к статье базы знаний Майкрософт: Guidelines for choosing antivirus software to run on the computers that are running SQL Server (http://support2.microsoft.com/kb/309422/ru)
	- network packet size
		Следующим параметром глобальной конфигурации, изменение которого может в некоторых случаях способствовать повышению производительности приложений баз данных, является “network packet size (B)”. Увеличение размера сетевого пакета до 8192 Байт может позволить добиться выигрыша за счёт лучшего выравнивания размера пакета с размером страницы SQL Server, которая равна 8 КБ. Однако, следует учитывать, что значение этого параметра по умолчанию (4096Б), является лучшим для большинства приложений. Только тестирование позволит выбрать для этого параметра оптимальную установку.
	- UseLargePages
		Включение поддержки больших страниц может оказаться полезным для тех систем с SQL Server x64, которые оснащение большим объёмом оперативной памяти. Большие страницы способствуют повышению производительности за счёт увеличения TLB буфера процессора. Большие страницы могут использоваться для буферного пула и для кодовых страниц SQL Server. Для включения больших страниц на уровне SQL Server нужно задать флаг трассировки -T834 (это можно сделать через стартовые параметры). Кроме того, следует добавить ключ системного реестра. Содержимое reg-файла для добавления показано ниже:

		Windows Registry Editor Version 5.00

		[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\sqlservr.exe]
		“UseLargePages”=dword:00000001

		Для вступления изменений в силу потребуется перезагрузка системы.
		
	- LargeSystemCache/Size и IdleFrom0Delay
		Установив значение LargeSystemCache в 0, тем самым устанавливается стандартный размер кэша файловой системы, который равен приблизительно 8 Мб, максимальный размер кэша файловой системы не будет превышать 512 Мб. Эта установка рекомендуется для таких программ, которые осуществляют кэширование памяти самостоятельно, и к таким программам относится SQL Server. Ниже показан reg-файла для задания такой установки:

		Windows Registry Editor Version 5.00

		[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management]
		“LargeSystemCache”=dword:00000000

		То, насколько агрессивно будет заниматься физическая память под задачи файлового кэша, зависит от установки следующего ключа реестра:

		Windows Registry Editor Version 5.00

		[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters]
		“Size”=dword:00000001

		Возможные значения: 1-вяло, 2-сбалансировано, 3-агресивно. Для установок с малой нагрузкой на файловый кэш, вполне достаточно 1.. Другие установки свойственны файловым серверам разного масштаба, впрочем, для тестов TPC-E часто выбирают 3.

		Отключить режим экономии энергии, который тоже может замедлять некоторые операции, можно с помощью ключа IdleFrom0Delay. Сделать это можно так:

		Windows Registry Editor Version 5.00

		[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management]
		“IdleFrom0Delay”=dword:00000000
		
	- IoPageLockLimit, DisablePagingExecutive и DontVerifyRandomDrivers

		В одном из документов по оптимизации мне попадалась следующая формула: “IoPageLockLimit = (RAMMb – 65) * 1024″. С помощью ключа IoPageLockLimitможно повлиять на то, сколько байт система будет читать или писать на логичекский диск за один раз.

		Когда оперативной памяти предостаточно, с помощью установкиDisablePagingExecutive можно не позволять SQL Server вытеснять в файл подкачки компоненты драйверов привилегированного и непривилегированного режимов, как и компоненты самого ядра ОС. УстановкаDontVerifyRandomDrivers в единицу позволяет сэкономить несколько процессорных циклов за счёт отключения отладочной проверки драйверов.

		Вот как могут выглядеть значения этих ключей на практике:

		Windows Registry Editor Version 5.00

		[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management]
		“DisablePagingExecutive”=dword:00000001
		“DontVerifyRandomDrivers”=dword:00000001
		“IoPageLockLimit”=dword:00d9bc00

	- CountOperations
		Параметр CountOperations позволяет отключить сбор данных по некоторым счётчикам производительности, которые относятся к запросам ввода-вывода дисковой подсистемы и сетевых интерфейсов. Чтобы это сделать, нужно в ключе системного реестра “I/O System” установить значение 0 для следующего параметра:

		Windows Registry Editor Version 5.00

		[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\I/O System]
		“CountOperations”=dword:00000000

		Требуется перезагрузка.

	- NumberOfRequests и MaximumSGList
		Эта пара ключей системного реестра предназначена для управления драйвером минипорта в момент инициализации последнего.

		Увеличивая значение NumberOfRequests может способствовать повышению производительности обслуживания в Windows запросов дискового ввода-вывода, адресованных логическим дискам, и бывает эффективно только если эти логические диски являются аппаратными RAID-массивами, которые обладают возможностью распараллеливания запросов ввода-вывода. Рекомендованное значение можно найти в документации производителя FC-адаптера или RAID-контроллера. Увеличивать значение нужно осторожно, т.к. большое значение может привести даже к отказу системы. Например, для HBA адаптера QLogic, управляемого драйвером “QLogic Fibre Channel Miniport Driver”, в документации не рекомендуется превышать значение 150. Новое значение вступает в силу после перезагрузки системы или, в некоторых случаях, достаточно перезапустить адаптер (заблокировать/разблокировать).

		Ключ MaximumSGList позволяет изменять используемый по умолчанию размер пакета передачи данных по шине (64Кб), который актуален для команд интерфейса SCSI. Если установить значение 255, то размер передаваемого одной командой объёма данных будет равняться мегабайту. Современные адаптеры умеют объединять до 265 сегментов данных, каждый по 4096 байт, что в сумме может дать размер одной передачи до 1048576 байт. Этот параметр широко используется для повышения эффективности использования ленточных накопителей, а также для оптимизаций таких задач SQL Server, которые оперируют большими запросами ввода-вывода, например, резервное копирование и восстановление.

		В описаниях тесов TPC-C встречается установка обоих ключей в значение 255, как это показано в примере ниже:

		Windows Registry Editor Version 5.00

		[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\ql2300\Parameters\Device]
		“DriverParameter”=””
		“BusType”=dword:00000006
		“NumberOfRequests”=dword:000000ff
		“MaximumSGList”=dword:000000ff
		“CreateInitiatorLU”=dword:00000001
		“DriverParameters”=”UseSameNN=1;buschange=0″
		
	- IdlePrioritySupported
		Windows Server 2008 умеет учитывать приоритет запроса ввода-вывода и использует его для обслуживания фоновых задач. Однако, если система обслуживает только одно приложение, подобное SQL Server, и это приложение само заботится о приоритетах запросов ввода-вывода, отвлечение системных ресурсов на приоритезацию становится излишним. Отучить Windows от обслуживания приоритетов запросов можно внеся изменения в системный реестр для каждого из выбранных дисков, как это показано на примере использования ключа IdlePrioritySupported:

		Windows Registry Editor Version 5.00

		[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\SCSI\Disk&Ven_IBM&Prod_1726-4xx__FAStT\5&22c73432&0&000000\Device Parameters\Classpnp]
		“IdlePrioritySupported”=dword:00000000

		Ключ Classpnp скорее всего придётся добавить. Подобные тонкие настройки были мной замечены у IBM в тестах TPC-E.
		
	- Рекомендуемые к отключению службы
		Application Management Alerter, Clipbook, Computer Browser, Distributed file system, Distributed link tracking client, Error Reporting Service, Fax Service, File Replication, Help and Support HTTP SSL, License Logging, Messenger, Portable Media Serial Number Service, Shell Hardware Detection, Windows Audio, Wireless Configuration.

-- Local Computer Policy/Блокировка страниц в памяти/Locked Pages in Memory (LPIM)/Lock Pages in Memory
	- https://docs.microsoft.com/ru-ru/sql/database-engine/configure-windows/enable-the-lock-pages-in-memory-option-windows
	- if it's 64-bit, you have more than 16-32 GB RAM installed, you've, set 'max server memory' appropriately, and you monitor the Memory\Available Mbytes counter, then you should enable it by default
	- При включении данной настройки, SQL Server не будет использовать paging file (swap file)
	- При виртуализации не включать эту опцию
	- Не работает на Standard версии
	- При включении блокировки страниц в памяти обязательно нужно установить Max Server Memory, так как SQL Server перестаёт отдавать память операционной системе
	- gpedit.msc > Конфигурация компьютера > Конфигурация Windows > Локальные политики > Назначение прав пользователя > Блокировка страниц в памяти > добавить пользователя > перезагрузить SQL Server
	- gpedit.msc > Group Policy console, expand Computer Configuration > Windows Settings > Expand Security Settings > Local Policies > User Rights Assignment > Lock pages in memory.
	- Для SQL Server 2008 Standart x64 необходимо установить флаг трассировки при старте -T845
	
	-- Особенности
		1. Если указать 'max server memory' и 'lock page in memory' больше чем доступно в ОС, то будут проблемы 
	
	-- Под кем запущен SQL/SQL Server Services information 
		SELECT servicename, process_id, startup_type_desc, status_desc, 
		last_startup_time, service_account, is_clustered, cluster_nodename, [filename]
		FROM sys.dm_server_services WITH (NOLOCK) OPTION (RECOMPILE);
		
	-- Активен ли режим?
		1. -- Как много заблокировано страниц в памяти. SQL Server Process Address space info (shows whether locked pages is enabled, among other things)
			SELECT physical_memory_in_use_kb/1024 AS [SQL Server Memory Usage (MB)], 
				   locked_page_allocations_kb
			FROM sys.dm_os_process_memory WITH (NOLOCK) OPTION (RECOMPILE);	
		2. Error log > find > locked pages
		
	-- Windows version information 
		SELECT windows_release, windows_service_pack_level, 
			   windows_sku, os_language_version
		FROM sys.dm_os_windows_info WITH (NOLOCK) OPTION (RECOMPILE);

		-- Gives you major OS version, Service Pack, Edition, and language info for the operating system 
		-- 6.3 is either Windows 8.1 or Windows Server 2012 R2
		-- 6.2 is either Windows 8 or Windows Server 2012
		-- 6.1 is either Windows 7 or Windows Server 2008 R2
		-- 6.0 is either Windows Vista or Windows Server 2008		

-- Более быстрое восстановление/локальные политики
		- Чтобы система восстанавливала Бд быстрее, надо учетной записи предоставить права на "Выполнение задач по обслуживанию томов"
		  Это делается через: Локальная политика безопасности->Параметры безопасности->Назначение прав пользователя->
		  ->"Выполнение задач по обслуживанию томов" (Perform volume maintenance tasks)
		  - secpol.msc 		  
		  
-- instant file initialization
	- open secpol.msc, go to my Local Policies and check User Rights Assignment. Only Administrators have permission to "Perform volume maintenance task". Добавить нужного пользователя
	- DBCC TRACEON(3004,3605,-1) -- позволяет подробнее логировать процесс восстановления, что позволит посмотреть работает ли instant file initialization или нет
	- Можно просто проверить error log по фразе "instant"
	
	
-- Если ваш сервер работает долго
	-- Сбросить кэш планов (применять очень аккуратно)	
		FREEPROCCACHE
	
	-- Очистка истории старше 90 дней
		DECLARE @d datetime = GETDATE()-90
		exec msdb.dbo.sp_delete_backuphistory @d
		EXEC msdb.dbo.sp_purge_jobhistory  @oldest_date=@d
		EXECUTE msdb..sp_maintplan_delete_log null,null,@d
		
		-- Удаление почты старше сколько-то дней
			SELECT * FROm msdb.dbo.sysmail_mailitems 
			DECLARE @d datetime = GETDATE()
			exec sysmail_delete_mailitems_sp @sent_before=@d
			
			sysmail_delete_log_sp -- аналог
			
		-- SSIS пакеты
			delete		
			FROM [msdb].[dbo].[sysssislog] where starttime<@dt

		
	-- Если лог большой, нужно его обрезать
		exec master.dbo.sp_cycle_errorlog

-- Soft-Numa
	https://docs.microsoft.com/ru-ru/sql/database-engine/configure-windows/soft-numa-sql-server
	https://docs.microsoft.com/ru-ru/sql/database-engine/configure-windows/map-tcp-ip-ports-to-numa-nodes-sql-server
	
-- Page split
	-- Поиск
		SELECT TOP 10 SO.[object_id]
			, SO.[name] AS table_name
			, SI.index_id
			, SI.[name] as index_name
			, SI.fill_factor
			, SI.type_desc AS index_type
			, ixO.partition_number
			, ixO.leaf_allocation_count -- количество сплитов
			, ixO.nonleaf_allocation_count -- количество сплитов
		FROM sys.dm_db_index_operational_stats (db_id(), NULL, NULL, NULL) AS ixO
			INNER JOIN sys.indexes SI 
				ON ixO.[object_id] = SI.[object_id] 
					AND ixO.[index_id] = SI.[index_id] 
			INNER JOIN sys.objects SO ON SI.[object_id] = SO.[object_id]
		ORDER BY ixO.leaf_allocation_count DESC;
		
	-- Поиск в активной части журнала, если БД недоступна
		
		SELECT
			[AllocUnitName] AS N'Index',
			(CASE [Context]
				WHEN N'LCX_INDEX_LEAF' THEN N'Nonclustered'
				WHEN N'LCX_CLUSTERED' THEN N'Clustered'
				ELSE N'Non-Leaf'
			END) AS [SplitType],
			COUNT (1) AS [SplitCount]
		FROM
			fn_dblog (NULL, NULL)
		WHERE
			[Operation] = N'LOP_DELETE_SPLIT'
		GROUP BY [AllocUnitName], [Context];
		GO
		
	-- Поиск в активной части журнала, если БД доступна
		SELECT
			CAST ([s].[name] AS VARCHAR) + '.' + CAST ([o].[name] AS VARCHAR) + '.' + CAST ([i].[name] AS VARCHAR) AS [Index],
			[f].[SplitType],
			[f].[SplitCount]
		FROM
			(SELECT
				[AllocUnitId],
				(CASE [Context]
					WHEN N'LCX_INDEX_LEAF' THEN N'Nonclustered'
					WHEN N'LCX_CLUSTERED' THEN N'Clustered'
					ELSE N'Non-Leaf'
				END) AS [SplitType],
				COUNT (1) AS [SplitCount]
			FROM
				fn_dump_dblog (NULL, NULL, N'DISK', 1, N'C:\SQLskills\SplitTest_log.bck',
					DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
					DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
					DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
					DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
					DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
					DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
					DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
					DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
					DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT)
			WHERE
				[Operation] = N'LOP_DELETE_SPLIT'
			GROUP BY [AllocUnitId], [Context]) f
		JOIN sys.system_internals_allocation_units [a]
			ON [a].[allocation_unit_id] = [f].[AllocUnitId]
		JOIN sys.partitions [p]
			ON [p].[partition_id] = [a].[container_id]
		JOIN sys.indexes [i]
			ON [i].[index_id] = [p].[index_id] AND [i].[object_id] = [p].[object_id]
		JOIN sys.objects [o]
			ON [o].[object_id] = [p].[object_id]
		JOIN sys.schemas [s]
			ON [s].[schema_id] = [o].[schema_id];
		GO