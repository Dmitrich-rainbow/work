-- О фрагментации
Когда запись удаляется, в файле БД высвобождается место. Когда вставляется новая запись, это может привести к расщеплению страниц, что приводит к появлению пустого пространства на страницах данных. Когда данный обновляются, это может привести к изменению размера записи и к возникновению двух ранее упоминавшихся случаев. Все это приводит к фрагментации. В SQL Server рассматриваются два типа фрагментации: внутренняя и внешняя.

Внутренняя подразумевает пустоты внутри страницы. Внешняя – непоследовательность связей страниц.

Если страницы не полностью заполнены данными, это приводит к дополнительным операциям I/O и переиспользованью оперативной памяти. Помните что страницы в оперативной памяти есть зеркальное отражение страниц на диске.

В идеале страницы должны быть подлинкованы слева направо в порядке хранения данных. Вследствие расщепления страниц этот порядок может быть нарушен. Это приводит как к неполному заполнению страниц, так и к увеличению операций I/O вследствие непоследовательного положения цепочек страниц на диске – это вызывает дополнительные перемещения головок с цилиндра на цилиндр диска. А это одна из наиболее медленных дисковых операций.

Команда "DBCC SHOWCONTIG" помогает определить как внутреннюю так и внешнюю фрагментацию

-- Insert
Вставка может приводить к фрагментации на leaf level. Кластерные индексы особенно чувствительны к вставке данных.
Проблема в том что при расщеплении страниц, новая страница будет расположена в первом попавшемся свободном месте базы данных. При многочисленных вставках база данных рискует стать очень фрагментируемой.

-- Updates
При обновлении SQL Server всегда старается оставить запись на старом месте и избежать ее переноса на новое место. Но это невозможно при увеличении длины записи. В случае переноса записи SQL Server использует указатели на новое место. Это позволяет не перестраивать индексы.
Стремление не обновлять индексы наносит негативный удар по производительности поскольку приводит к фрагментированию базы данных. Данный алгоритм вполне оправдан для OLTP БД.

-- Deletes
Как мы видели вставки приводят к внутренней и внешней фрагментации, а обновления к внешней. Удаления записи приводит к внутренней фрагментации – делает “дырки” на страницах. При удалении записи, SQL Server не удаляет физически эти записи, а помечает их как удаленные. При вставке или обновлении записей, свободное место от удаленных записей может быть переиспользовано. В противном случае каждые пол часа запускается процесс, который утилизирует удаленные записи.

Удаление записей приводит в внутренней фрагментации и переиспользование места на диске приводит к дополнительным операциям I/O. И не забывайте что страницы на диске копируются в память – нерациональное использование дисковой памяти приводит к переиспользованью оперативной памяти.

-- DBCC SHOWCONTIG
	- DBCC SHOWCONTIG('Orders')
	Pages Scanned - указывает количество страниц в таблице. В нашем примере их 20.
	Extents Scanned - показывает количество экстентов занимаемых таблицей. Это сразу указывает на фрагментированность данных – для сохранения 20 страниц хватает 3х экстентов.
	Extent Switches - говорит о количестве раз переключения с экстента на экстент при последовательном чтении данных. В идеальной ситуации это число равно Extents Scanned – 1
	Avg. Pages per Extent - говорит о среднем количестве страниц на экстент при перемещении по цепочке страниц. Это значение должно быть как можно ближе к 8
	Scan Density - представляет собой значение для внешней фрагментации. Этот результат получается от соотношения идеальной смены экстентов к фактической. Вполне очевидно, это что должно быть близко к 100%
	Logical Scan Fragmentation - дает процент страниц не в логическом порядке. Если страницы находятся в строгой последовательности слева направо, то данный параметр будет иметь значение 0
	Extent Scan Fragmentation - дает процент экстентов не в логическом порядке. Имеет то же логическое значение что и Logical Scan Fragmentation
	Avg. Bytes Free per Page – должно быть как можно ближе к 0 если fill factor 100. Иное значение требует незначительных расчетов. Если fill factor 80, это обеспечивает примерно 1600 свободных байтов на страницу.
	Avg. Page Density - должно быть как можно ближе к 100%. Avg. Bytes Free per Page и Avg. Page Density дают хорошее представление о внутренней фрагментации.

-- Reducing fragmentation:
Reducing Fragmentation in a Heap: To reduce the fragmentation of a heap, create a clustered index on the table. Creating the clustered index, rearrange the records in an order, and then place the pages contiguously on disk.
Reducing Fragmentation in an Index: There are three choices for reducing fragmentation, and we can choose one according to the percentage of fragmentation:
If avg_fragmentation_in_percent > 5% and < 30%, then use ALTER INDEX REORGANIZE: This statement is replacement for DBCC INDEXDEFRAG to reorder the leaf level pages of the index in a logical order. As this is an online operation, the index is available while the statement is running.
If avg_fragmentation_in_percent > 30%, then use ALTER INDEX REBUILD: This is replacement for DBCC DBREINDEX to rebuild the index online or offline. In such case, we can also use the drop and re-create index method.
(Update: Please note this option is strongly NOT recommended)Drop and re-create the clustered index: Re-creating a clustered index redistributes the data and results in full data pages. The level of fullness can be configured by using the FILLFACTOR option in CREATE INDEX.
	
-- Непонятный способ посмотреть фрагментированные индексы базы
	SELECT OBJECT_NAME(OBJECT_ID), index_id,index_type_desc,index_level,
	avg_fragmentation_in_percent,avg_page_space_used_in_percent,page_count -- avg_page_space_used_in_percent желательно чтобы было более 75%
	FROM sys.dm_db_index_physical_stats
	(DB_ID(N'WWWBRON'), NULL, NULL, NULL , 'SAMPLED')
	ORDER BY avg_fragmentation_in_percent DESC

-- Ещё 1 способ посмотреть фрагментацию индексов
	DECLARE @db_name varchar(50) = N'WWWBRON_T84',
					@table_name varchar(250) = N'NULL'

	SELECT  IndStat.database_id, 
					IndStat.object_id, 
					QUOTENAME(s.name) + '.' + QUOTENAME(o.name) AS [object_name], 
					IndStat.index_id, 
					QUOTENAME(i.name) AS index_name,
					IndStat.avg_fragmentation_in_percent,
					IndStat.partition_number, 
					(SELECT count (*) FROM sys.partitions p
							WHERE p.object_id = IndStat.object_id AND p.index_id = IndStat.index_id) AS partition_count 
	FROM sys.dm_db_index_physical_stats
		(DB_ID(@db_name), OBJECT_ID(@table_name), NULL, NULL , 'LIMITED') AS IndStat
			INNER JOIN sys.objects AS o ON (IndStat.object_id = o.object_id)
			INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
			INNER JOIN sys.indexes i ON (i.object_id = IndStat.object_id AND i.index_id = IndStat.index_id)
	WHERE IndStat.avg_fragmentation_in_percent > 10 AND IndStat.index_id > 0
	ORDER BY IndStat.avg_fragmentation_in_percent
	
-- Узнать % фрагментации индексов в таблице
	SELECT a.index_id, name, avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats (DB_ID(N'WWWBRON'), OBJECT_ID(N'WWWBRON.dbo.Cat_Claim'), NULL, NULL, NULL) AS a
	JOIN sys.indexes AS b ON a.object_id = b.object_id AND a.index_id = b.index_id; 
		
-- Фрагментация индексов базы
SELECT 
    dm.database_id, 
    tbl.name, 
    dm.index_id, 
    idx.name, 
    dm.avg_fragmentation_in_percent,    
    idx.fill_factor
FROM sys.dm_db_index_physical_stats(DB_ID(), null, null, null, null) dm -- Если указать последним параметром не null, а 'DETAILED', то будет произведена более серьёзная проверка, включая не только логический, но и физический уровень. Что-то среднее это - SAMPLED 
    INNER JOIN sys.tables tbl ON dm.object_id = tbl.object_id
    INNER JOIN sys.indexes idx ON dm.object_id = idx.object_id AND dm.index_id = idx.index_id
WHERE page_count > 8
    AND avg_fragmentation_in_percent > 15
    AND dm.index_id > 0
	
 
 -- План обслуживания индексов. Устранение фрагментации (АРТТУР)
	CREATE TABLE #TempTable(
		database_id int,
		table_name varchar(50),
		index_id int,
		index_name varchar(50),
		avg_frag_percent float,
		fill_factor tinyint
	)

	INSERT INTO #TempTable (
		database_id, 
		table_name, 
		index_id, 
		index_name, 
		avg_frag_percent,
		fill_factor)
	SELECT 
		dm.database_id, 
		tbl.name, 
		dm.index_id, 
		idx.name, 
		dm.avg_fragmentation_in_percent,    
		idx.fill_factor
	FROM sys.dm_db_index_physical_stats(DB_ID(), null, null, null, null) dm
		INNER JOIN sys.tables tbl ON dm.object_id = tbl.object_id
		INNER JOIN sys.indexes idx ON dm.object_id = idx.object_id AND dm.index_id = idx.index_id
	WHERE page_count > 8
		AND avg_fragmentation_in_percent > 15
		AND dm.index_id > 0 
		
		--см описание таблицы
	DECLARE @index_id INT
	DECLARE @tableName VARCHAR(250) 
	DECLARE @indexName VARCHAR(250)
	DECLARE @defrag FLOAT
	DECLARE @fill_factor int
		-- Сам запрос, который мы будем выполнять, я поставил MAX, потому как иногда меняю такие скрипты,
		-- и забываю поправить размер данной переменной, в результате получаю ошибку.
	DECLARE @sql NVARCHAR(MAX)

		-- Далее объявляем курсор
	DECLARE defragCur CURSOR FOR
		SELECT 
			index_id, 
			table_name, 
			index_name, 
			avg_frag_percent,
			fill_factor
			
		FROM #TempTable

	OPEN defragCur
	FETCH NEXT FROM defragCur INTO @index_id, @tableName, @indexName, @defrag,@fill_factor
	WHILE @@FETCH_STATUS=0
	BEGIN
		IF OBJECT_ID(''+@tableName+'','U') is not null
		BEGIN
			SET @sql = N'ALTER INDEX ' + @indexName + ' ON ' + @tableName
		  
			--В моем случае, важно держать неможко пустого места на страницах, потому, что вставка в тоже таблицы имеете место, и не хочеться тратить драгоценное время пользователей на разбиение страниц
			IF (@fill_factor != 90)
			BEGIN
				SET @sql = @sql + N' REBUILD PARTITION = ALL WITH (FILLFACTOR = 90, PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, ONLINE = OFF, SORT_IN_TEMPDB = ON )'
			END
			ELSE
			BEGIN -- Тут все просто, действуем по рекомендации MS
				IF (@defrag > 30) --Если фрагментация больше 30%, делаем REBUILD
				BEGIN
					SET @sql = @sql + N' REBUILD PARTITION = ALL WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, ONLINE = OFF, SORT_IN_TEMPDB = ON )'
				END
				ELSE -- В противном случае REORGINIZE
				BEGIN
					SET @sql = @sql + N' REORGANIZE'
				END
			END
			   
			exec (@sql) -- Выполнить запрос
		END
		FETCH NEXT FROM defragCur INTO @index_id, @tableName, @indexName, @defrag,@fill_factor
	END
	CLOSE defragCur
	DEALLOCATE defragCur

	DROP TABLE #TempTable

