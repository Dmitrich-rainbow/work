-- Основное
	https://www.simple-talk.com/sql/performance/sql-server-statistics-questions-we-were-too-shy-to-ask/
	- Обновление статистики приводит к рекомпиляции планов
	- REORGANIZE Index не приводит к обновлению статистики
	- AUTO_UPDATE_STATISTICS влияет на поле last_updated
	- Иногда лучше не перестраивать статистику, а обновлять планы
	- Обновление статистики вызывает перекомпиляцию планов начиная с 2008 версии
	- Начиная с 2012 на read-only db и snapshot можно обновлять статистику, которая будет храниться в tempdb
	
-- Минусы
	1. Обновление статистики не только требует много ресурсов, но и вызывает RECOMPLIE
	
-- Как наблюдать AUTO_UPDATE_STATISTICS
	1. Profiler >> Performance >> Auto STATS
	2. xEvents (SQL Server 2012)

-- Возможности работы со статистикой
	1. manually update all existing statistics - ручное обновление статистики во всей базе данных (sp_updatestats).
	2. list statistics objects - просмотр существующих объектов статистики таблицы или базы данных (sp_helpstats, представления каталога sys.stats,
	   sys.stats_columns)
	3. display descriptive information about statistics objects - просмотр описаний объектов статистики DBCC SHOW_STATISTICS('dbo.OffersConditions','Index')
	4. enable and disable automatic creation and update of statistics - включение/выключение автоматического создания и обновления статистики
	   для всей базы данных или для определенной таблицы или объекта статистики (опции ALTER DATABASE: AUTO_CREATE_STATISTICS
	   и AUTO_UPDATE_STATISTICS; sp_autostats; и опции NORECOMPUTE: CREATE STATISTICS и UPDATE STATISTICS)
	5. enable and disable asynchronous automatic update of statistics - включение/выключение автоматического, асинхронного обновления
	   статистики (ALTER DATABASE, опция AUTO_UPDATE_STATISTICS_ASYNC)

-- Когда стоит самостоятельно обновлять статистику
	1. После BULK LOAD
	2. Статистика по нескольким столбцам
	3. Фильтрованная статистика
	4. Большая точность
	5. Когда активна только часть таблицы
   
-- Параметры
	FULLSCAN - сканировать всю таблицу
	SAMPLE - сканировать указанный процент данных таблиц. Не влияет на логику auto update statistics
		- Rows Sample -- сколько строк было обновление после последнего update statistics
	RESAMPLE - использовать прошлый указанный SAMPLE для каждой статистики или использовать значение по-умолчению (http://www.sqlskills.com/blogs/joe/auto-update-stats-default-sampling-test/)
		- Notice the sample percent is identical between identical row/page tests (Чем больше строк, тем этот процент будет меньше)
		-- Примерная таблица распределения RESAMPLE
			стоки RESAMPLE(%)
			10	100.0000
			1,000,000	34.6964
			2,000,000	18.0480
			10,000,000	4
			20,000,000	2
			40,000,000	1.2
			80,000,000	0.8129

	
-- Статистика, созданная пользователями
	SELECT * FROM sys.stats WHERE user_created = 1
   
-- Посмотреть статистику
	DBCC SHOW_STATISTICS ('Table','Statistic')
	DBCC SHOW_STATISTICS (Films2,_WA_Sys_00000005_113584D1)
	DBCC SHOW_STATISTICS (Films2,_WA_Sys_00000005_113584D1) WITH HISTOGRAM -- посмотреть только гистограмму  
	
-- 	Histogram/Гистограма
	- Хранит не более 200 шагов статистики, на больших объёмах плохие планы
	- Только для первого левого столбца в индексе
	
-- Получение информации о статистики
	1. DBCC SHOWCONTIG WITH TABLERESULTS, ALL_INDEXES, FAST
	2. DBCC SHOW_STATISTICS
	3. Системные представления

-- Обновить статистику базы/update
	EXEC sp_updatestats -- Минус состоит в том, что он обновит всю статистику, даже у там, где было изменена всего 1 строка
	- Обновление статистики всей таблицы равноценно обновлению каждого объекта в ней (проверено), поэтому выгодней обновлять не всю таблицу, а только устаревшие объекты 

-- Auto Update Statistics
	- Происходит не после добавления данных, а после добавления данных и получения информации через SELECT
	- При плохой селективности работает очень хорошо
	-- Возникает
		A database table with no rows gets a row
		A database table had fewer than 500 rows when statistics was last created or updated and is increased by another 500 or more rows
		A database table had more than 500 rows when statistics was last created or updated and is increased by 500 rows + 20 percent of the number of rows in the table when statistics was last created or updated.

	- Можно включить или отключить не только на уровне БД, но и на уровне таблицы, индекса или столбца. Если параметр AUTO_UPDATE_STATISTICS отключен, то нельзя включить автоматическое обновление для отдельной таблицы, индекса или столбца
		- sp_autostats
		- Укажите параметр NORECOMPUTE в инструкции UPDATE STATISTICS
		- Укажите параметр NORECOMPUTE в инструкции CREATE STATISTICS
		- Укажите параметр STATISTICS_NORECOMPUTE в инструкции CREATE INDEX
		
	- Синхронную статистику рекомендуется использовать в следующем сценарии. Выполняются операции, которые изменяют распределение данных, например усечение таблицы или массовое обновление большого количества строк (в процентном отношении). Если после выполнения операции не обновить статистику, то использование синхронной статистики обеспечит создание актуальной статистики перед выполнением запросов к изменившимся данным.
	
	- Асинхронная статистика рекомендуется для достижения более прогнозируемого времени ответа на запросы в следующих сценариях. Приложение часто выполняет один и тот же запрос, схожие запросы или схожие кэшированные планы запроса. Асинхронное обновление статистики может обеспечить более прогнозируемое время ответа на запрос по сравнению с синхронным обновлением статистики, поскольку оптимизатор запросов может выполнять входящие запросы, не ожидая появления актуальной статистики. Это устраняет задержку в некоторых запросах, но не влияет на другие запросы. Дополнительные сведения о поиске схожих запросов см. в разделе Поиск и настройка сходных запросов с помощью хэширования запросов и планов запросов. Были случаи, когда в приложении истекало время ожидания клиентских запросов в результате ожидания обновленной статистики. В некоторых случаях ожидание синхронной статистики может вызвать аварийное завершение приложений, в которых задано малое время ожидания.
	
	Option 1
		Disable Auto Update Statistics for the database
		Create a job to update index and column level statistics with 100% sample on a regular basis (or rebuild indexes + update column statistics with 100% sample on a regular basis)
		Clear procedure cache or restart the instance after the update of statistics is complete
		
	Option 2*
		Disable Auto Update Statistics for the database
		Before running any update statistics jobs, enable the Auto Update Statistics for the database.
		Create a job to update index and column level statistics with 100% sample on a regular basis (or rebuild indexes + update column statistics with 100% sample on a regular basis)
		When the job is complete, disable the Auto Update Statistics for the database

	Option 3
		Enable Auto Update Statistics for the database
		Create a job to update index and column level statistics with 100% sample on a regular basis (or rebuild indexes + update column statistics with 100% sample on a regular basis)
		
	Option 4

		Enable Auto Update Statistics for the database
		Create a job to rebuild indexes and update statistics on a regular basis, dependent upon the level of fragmentation in an index and the need to update statistics because of changes to the data
		
-- Статистика, созданная автоматически
	
	SELECT OBJECT_NAME(s.object_id) AS object_name,
		COL_NAME(sc.object_id, sc.column_id) AS column_name,
		s.name AS statistics_name
	FROM sys.stats AS s Join sys.stats_columns AS sc
		ON s.stats_id = sc.stats_id AND s.object_id = sc.object_id
	WHERE s.name like '_WA%'
	ORDER BY s.name;
	 
-- Обновить статистику старше 24 часов (опять же уровень базы)
	--Set the thresholds when to consider the statistics outdated
	DECLARE @hours int
	DECLARE @modified_rows int
	DECLARE @update_statement nvarchar(300);

	SET @hours=24
	SET @modified_rows=10

	--Update all the outdated statistics
	DECLARE statistics_cursor CURSOR FOR
	SELECT 'UPDATE STATISTICS '+OBJECT_NAME(id)+' '+name
	FROM sys.sysindexes
	WHERE STATS_DATE(id, indid)<=DATEADD(HOUR,-@hours,GETDATE()) 
	AND rowmodctr>=@modified_rows 
	AND id IN (SELECT object_id FROM sys.tables)
	 
	OPEN statistics_cursor;
	FETCH NEXT FROM statistics_cursor INTO @update_statement;
	 
	 WHILE (@@FETCH_STATUS <> -1)
	 BEGIN
	  EXECUTE (@update_statement);
	  PRINT @update_statement;
	 
	 FETCH NEXT FROM statistics_cursor INTO @update_statement;
	 END;
	 
	 PRINT 'The outdated statistics have been updated.';
	CLOSE statistics_cursor;
	DEALLOCATE statistics_cursor;
	GO

-- Обновить статистику
	DECLARE @schema nvarchar(255), @table nvarchar(255), @statistic nvarchar(255), @query  nvarchar(4000)

	DECLARE CursUpdateStatistic CURSOR FOR
	SELECT
		sch.name  AS 'Schema',
		so.name as 'Table',
		ss.name AS 'Statistic'
	FROM sys.stats ss
	JOIN sys.objects so ON ss.object_id = so.object_id
	JOIN sys.schemas sch ON so.schema_id = sch.schema_id
	OUTER APPLY sys.dm_db_stats_properties(so.object_id, ss.stats_id) AS sp
	WHERE so.TYPE = 'U'
	AND ((sp.modification_counter > 200000
	AND sp.last_updated < getdate() - 3) OR sp.last_updated < getdate() - 30)
	ORDER BY sp.last_updated
	DESC

	OPEN CursUpdateStatistic

	FETCH NEXT FROM CursUpdateStatistic INTO @schema,@table,@statistic

	WHILE @@FETCH_STATUS = 0
		BEGIN
		
			SET @query= 'UPDATE STATISTICS ['+ @schema+'].[' + @table+ '] [' + @statistic +'] WITH FULLSCAN'
			exec(@query)		
		
			FETCH NEXT FROM CursUpdateStatistic INTO @schema,@table,@statistic
		END
		
	CLOSE CursUpdateStatistic
	DEALLOCATE CursUpdateStatistic
	
-- Анализирование статистики
SELECT * FROM sys.system_internals_partition_columns

SELECT * FROM sys.dm_db_index_operational_stats(DB_ID(N'Arttour'),OBJECT_ID(N'dbo.bank'),NULL,NULL)
- Отображает все изменения в таблице не зависимо от изменённого столбца
- Обновления столбцов ключа отображаются дважды, если вы агрегируете счетчики конечный уровней, что покажется слишком большим значением
- Обновление статистики не сбросит счётчик

SELECT * FROM sys.dm_db_stats_properties(OBJECT_ID(N'dbo.bank'),1)
- Есть только в 2012 версии и в 2008R2 SP2
- Служит для ослеживания только изменений ключа, не отслеживает изменения в стоблцах, не входящих в ключ, даже в кластерном индексе
- Обновление статистики сбросит счётчики
- Позволяет легко отслеживать изменения статистики

- При перестроении кластерного индекса счётчики сбрасываются везде

-- Задвоенная статистика
		
	/*
		Query to find redundant stats for 2005 and higher
	*/
	WITH indexstats ([schema_name],[object_id],[index_name],[column_id])
		AS (	SELECT 
					[s].[name] AS [schema_name],
					[o].[object_id] AS [object_id],
					[i].[name] AS [index_name],
					[ic].[column_id] AS [column_id]
				FROM [sys].[indexes] [i]
				JOIN [sys].[objects] [o] ON [i].[object_id]=[o].[object_id]
				JOIN [sys].[stats] [st] ON [i].[object_id]=[st].[object_id] AND [i].[name]=[st].[name]
				JOIN [sys].[schemas] [s] ON [o].[schema_id]=[s].[schema_id]
				JOIN [sys].[index_columns] [ic] ON [i].[index_id]=[ic].[index_id] AND [i].[object_id]=[ic].[object_id]
				JOIN [sys].[columns] [c] ON [ic].[object_id]=[c].[object_id] AND [ic].[column_id]=[c].[column_id]
				WHERE [o].[is_ms_shipped] = 0
				AND [i].[has_filter]=0
				AND [ic].[key_ordinal]=1
			) 
	SELECT 
		[o].[object_id] AS [ID], 
		[indexstats].[schema_name] AS [Schema],
		[o].[name] AS [Table], 
		[c].[name] AS [Column], 
		[s].[name] AS [AutoCreatedStatistic], 
		[indexstats].[index_name] AS [Index],
		'DROP STATISTICS [' + [indexstats].[schema_name] + '].[' + [o].[name] + '].[' + [s].[name] +']' AS [DropStatsStatement]
	FROM [sys].[stats] [s]
	JOIN [sys].[stats_columns] [sc] ON [s].[stats_id]=[sc].[stats_id] AND [s].[object_id]=[sc].[object_id]
	JOIN [sys].[objects] [o] ON [sc].[object_id]=[o].[object_id]
	JOIN [sys].[columns] [c] ON [sc].[object_id]=[c].[object_id] AND [sc].[column_id]=[c].[column_id]
	JOIN [indexstats] ON [o].[object_id] = [indexstats].[object_id] AND [indexstats].[column_id] = [c].[column_id]
	WHERE [o].[is_ms_shipped] = 0
	AND [s].[auto_created]=1
	AND [s].[has_filter]=0
	AND [sc].[stats_column_id]=1
	ORDER BY [o].[name], [s].[name];

	/*
		Query to find redundant stats for 2008R2 SP2 and 2012 SP1
		uses dm_db_stats_properties
	*/
	WITH indexstats ([schema_name],[object_id],[index_name],[column_id],[last_updated])
		AS (	SELECT 
					[s].[name] AS [schema_name],
					[o].[object_id] AS [object_id],
					[i].[name] AS [index_name],
					[ic].[column_id] AS [column_id],
					[sp].[last_updated] AS [last_updated]
				FROM [sys].[indexes] [i]
				JOIN [sys].[objects] [o] ON [i].[object_id]=[o].[object_id]
				JOIN [sys].[stats] [st] ON [i].[object_id]=[st].[object_id] AND [i].[name]=[st].[name]
				JOIN [sys].[schemas] [s] ON [o].[schema_id]=[s].[schema_id]
				JOIN [sys].[index_columns] [ic] ON [i].[index_id]=[ic].[index_id] AND [i].[object_id]=[ic].[object_id]
				JOIN [sys].[columns] [c] ON [ic].[object_id]=[c].[object_id] AND [ic].[column_id]=[c].[column_id]
				CROSS APPLY sys.dm_db_stats_properties([i].[object_id],[st].[stats_id]) [sp]
				WHERE [o].[is_ms_shipped] = 0
				AND [i].[has_filter]=0
				AND [ic].[key_ordinal]=1
			) 
	SELECT 
		[o].[object_id] AS [ID], 
		[indexstats].[schema_name] AS [Schema],
		[o].[name] AS [Table], 
		[c].[name] AS [Column], 
		[s].[name] AS [AutoCreatedStatistic], 
		[sp2].[last_updated] AS [AutoStatLastUpdated],
		[indexstats].[index_name] AS [Index],
		[indexstats].[last_updated] AS [IndexLastUpdated],
		'DROP STATISTICS [' + [indexstats].[schema_name] + '].[' + [o].[name] + '].[' + [s].[name] +']' AS [DropStatsStatement]
	FROM [sys].[stats] [s]
	JOIN [sys].[stats_columns] [sc] ON [s].[stats_id]=[sc].[stats_id] AND [s].[object_id]=[sc].[object_id]
	JOIN [sys].[objects] [o] ON [sc].[object_id]=[o].[object_id]
	JOIN [sys].[columns] [c] ON [sc].[object_id]=[c].[object_id] AND [sc].[column_id]=[c].[column_id]
	JOIN [indexstats] ON [o].[object_id] = [indexstats].[object_id] AND [indexstats].[column_id] = [c].[column_id]
	CROSS APPLY sys.dm_db_stats_properties([o].[object_id],[s].[stats_id]) [sp2]
	WHERE [o].[is_ms_shipped] = 0
	AND [s].[auto_created]=1
	AND [s].[has_filter]=0
	AND [sc].[stats_column_id]=1
	ORDER BY [o].[name], [s].[name];

-- Неиспользуемая статистика/лишняя статистика, которая была создана автоматически
	- Статистика, которая покрывается статистикой индексов
	WITH    autostats ( object_id, stats_id, name, column_id ) 
	AS ( SELECT   sys.stats.object_id , 
	sys.stats.stats_id , 
	sys.stats.name , 
	sys.stats_columns.column_id 
	FROM     sys.stats 
	INNER JOIN sys.stats_columns ON sys.stats.object_id = sys.stats_columns.object_id 
	AND sys.stats.stats_id = sys.stats_columns.stats_id 
	WHERE    sys.stats.auto_created = 1 
	AND sys.stats_columns.stats_column_id = 1 
	) 
	SELECT  OBJECT_NAME(sys.stats.object_id) AS [Table] , 
	sys.columns.name AS [Column] , 
	sys.stats.name AS [Overlapped] , 
	autostats.name AS [Overlapping] , 
	'DROP STATISTICS [' + OBJECT_SCHEMA_NAME(sys.stats.object_id) 
	+ '].[' + OBJECT_NAME(sys.stats.object_id) + '].[' 
	+ autostats.name + ']' 
	FROM    sys.stats 
	INNER JOIN sys.stats_columns ON sys.stats.object_id = sys.stats_columns.object_id 
	AND sys.stats.stats_id = sys.stats_columns.stats_id 
	INNER JOIN autostats ON sys.stats_columns.object_id = autostats.object_id 
	AND sys.stats_columns.column_id = autostats.column_id 
	INNER JOIN sys.columns ON sys.stats.object_id = sys.columns.object_id 
	AND sys.stats_columns.column_id = sys.columns.column_id 
	WHERE   sys.stats.auto_created = 0 
	AND sys.stats_columns.stats_column_id = 1 
	AND sys.stats_columns.stats_id != autostats.stats_id 
	AND OBJECTPROPERTY(sys.stats.object_id, 'IsMsShipped') = 0
	ORDER BY [Table]

-- Работа со статистикой от Пола Рендела (Paul Randal)
SELECT
    sch.name + '.' + so.name AS
'Table',
    ss.name AS
'Statistic',
      CASE
            WHEN ss.auto_Created = 0 AND ss.user_created = 0 THEN 'Index Statistic'
            WHEN ss.auto_created = 0 AND ss.user_created = 1 THEN 'User Created'
            WHEN ss.auto_created = 1 AND ss.user_created = 0 THEN 'Auto Created'
            WHEN ss.AUTO_created = 1 AND ss.user_created = 1 THEN 'Not Possible?'
      END AS
'Statistic Type',
    CASE
            WHEN ss.has_filter = 1 THEN 'Filtered Index'
            WHEN ss.has_filter = 0 THEN 'No Filter'
      END AS
'Filtered?',
    CASE
            WHEN ss.filter_definition
IS NULL THEN ''
            WHEN ss.filter_definition
IS NOT NULL THEN ss.filter_definition
      END AS 'Filter
Definition',
    sp.last_updated AS
'Stats Last Updated',
    sp.rows AS 'Rows',
    sp.rows_sampled AS
'Rows Sampled',
    sp.unfiltered_rows AS
'Unfiltered Rows',
      sp.modification_counter AS
'Row Modifications',
      sp.steps AS
'Histogram Steps'
FROM sys.stats ss
JOIN sys.objects so ON ss.object_id = so.object_id
JOIN sys.schemas sch ON so.schema_id = sch.schema_id
OUTER APPLY sys.dm_db_stats_properties(so.object_id, ss.stats_id) AS sp
WHERE so.TYPE = 'U'
AND sp.last_updated <
getdate() - 30
ORDER BY sp.last_updated
DESC;

-- Обновить статистику с MaxDop/ускорить обновление статистики
	sp_configure 'cost threshold for parallelism', 30
	GO
	sp_configure 'max degree of parallelism', 4
	RECONFIGURE

	UPDATE STATISTICS dbo.Test MyStatistics 

	GO
	sp_configure 'cost threshold for parallelism', 32767
	GO
	sp_configure 'max degree of parallelism', 4
	RECONFIGURE
	
	-- Другой способ
		- Запустить несколко потоков обновления

-- export statistics/экспорт статистики
	- пкм на БД > Tasks > Generate script > Set Script option > Script Statitic = Statistics and histogram
	
-- HISTOGRAM
	- The histogram is up to 200 rows and never exceeds that amount
	
-- Partition/Секционирование
	- Строится общая статистика на все секции
	- Лучше создавать фильтрованную статистику для каждой секции
	
-- Update Statistics (по всем БД, без логирования)
	DECLARE @SQL VARCHAR(1000)  
	DECLARE @DB sysname  

	DECLARE curDB CURSOR FORWARD_ONLY STATIC FOR  
	   SELECT [name]  
	   FROM master..sysdatabases 
	   WHERE [name] NOT IN ('model', 'tempdb') 
	   ORDER BY [name] 
		 
	OPEN curDB  
	FETCH NEXT FROM curDB INTO @DB  
	WHILE @@FETCH_STATUS = 0  
	   BEGIN  
		   SELECT @SQL = 'USE [' + @DB +']' + CHAR(13) + 'EXEC sp_updatestats' + CHAR(13)  
		   PRINT @SQL  
		   FETCH NEXT FROM curDB INTO @DB  
	   END  
		
	CLOSE curDB  
	DEALLOCATE curDB
	
-- Incremental статистика/Инкрементальная статистика
	
	-- Получить информацию
		SELECT object_id, stats_id ,partition_number , last_updated , rows , rows_sampled , steps 
		FROM sys.dm_db_incremental_stats_properties(OBJECT_ID('table'),stats_id); 
		
		SELECT * FROM sys.stats ss
		JOIN sys.objects so ON ss.object_id = so.object_id
		JOIN sys.schemas sch ON so.schema_id = sch.schema_id
		OUTER APPLY sys.dm_db_stats_properties(so.object_id, ss.stats_id) AS sp
		CROSS APPLY sys.dm_db_incremental_stats_properties(so.object_id,ss.stats_id) as si
		WHERE so.TYPE = 'U' and is_incremental = 1
		
	
	-- Инкреметальная статистика будет обновлять с тем SAMPLE, с которым была создана
		update statistics [table] (statistics) with INCREMENTAL=ON, FULLSCAN; 
		UPDATE STATISTICS [dbo].[par] incrementral_par with resample on partitions (1) -- Будет брать тот % выборки, как было определено при создании статистики

	-- Создание
		CREATE CLUSTERED INDEX IX_PartitionIncrStatDemo_ID
		ON [PartitionIncrStatDemo] (ID) WITH (STATISTICS_INCREMENTAL=ON);		

		CREATE STATISTICS incrementral_par 
		ON par (part) WITH INCREMENTAL=ON

	-- Посмотреть гистограмму конкретной инкрементальной статистики
		DBCC TRACEON(2309); -- Нужно чтобы увидеть инкрементальную
		DBCC SHOW_STATISTICS('dbo.par',par,4)