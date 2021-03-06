-- Основное
	- Inside the SQL Server 2012 Columnstore Indexes
		http://rusanu.com/2012/05/29/inside-the-sql-server-2012-columnstore-indexes/
	- Niko Neugebauer -- CISL
		https://github.com/NikoNeugebauer/CISL
		
	- НЕ ВЫБИРАЕШЬ КОЛОНКИ, СОЗДАЁШЬ НА ВСЮ ТАБЛИЦУ
	- Высокая компрессия. Как минимум в 2-3 раза лучше компрессии на обычных таблицах
	- Нет смысла переносить если у вас не так много строк. Например до миллиона нет смысла переносить
	- Используйте больший уровень совместимости, чтобы получить Batch mode и другие крутые штуки
	- Используйте секционирование с колоночнымии индексами
	- Используйте Параллельную загрузку
	- Не используйте native compile store procedures
	- Traditional/regular clustered indexes physically sort data, but data within a columnstore index is unordered (that’s true for clustered and nonclustered columnstore indexes).
	-- Используйте COMPRESSION DELAY
		- http://www.nikoport.com/2016/02/04/columnstore-indexes-part-76-compression-delay/
		- Чтобы начать использовать, надо включить флаг трассировки
			dbcc traceon(10213, -1);
			
		-- Посмотреть настройки у индексов
			select name, object_name(object_id) as table_name, index_id, type, type_desc, compression_delay
			from sys.indexes
			where type in (5,6);
			
		-- Best practice
			- Insert/Query workload: If your workload is primarily inserting data and querying it, the default COMPRESSION_DELAY of 0 is the recommended option. The newly inserted rows will get compressed once 1 million rows have been inserted into a single delta rowgroup.Some example of such workload are (a) traditional DW workload (b) click-stream analysis when you need to analyze the click pattern in a web application
			- OLTP workload: If the workload is DML heavy (i.e. heavy mix of Update, Delete and Insert), you may see columnstore index fragmentation by examining the DMV sys. dm_db_column_store_row_group_physical_stats. If you see that > 10% rows are marked deleted in recently compressed rowgroups, you can use COMPRESSION_DELAY option to add time delay when rows become eligible for compression. For example, if for your workload, the newly inserted stays ‘hot’ (i.e. gets updated multiple times) for say 60 minutes, you should choose COMPRESSION_DELAY to be 60.
		
		-- Установка
			alter index NCCI_Test on dbo.FactOnlineSales_NCCI set ( COMPRESSION_DELAY = 30 Minutes );
		
	- Во время загрузки используйте TABLOCK
	- Используйте умножение и др. мат функции вне агрегаций. Например надо вот так SUM(order.net) * 1.12
	- Старайтесь везде сделать так, чтобы использовался Agregate pushdown
	
	-- Недостатки
		1. По возможности не используйте string в колоночных индексах
		2. Старайтесь добавить больше памяти в сервер, если используете колоночне индексы
		3. До 2016 Batch mode мог работать только с 2 ядрами и больше
		4. Rebuild колоночный индекс когда мало памяти, приводит к образованию большого количества Row Group, что ужасно сказывается на производительности
		5. Не используйте MERGE с колоночными индексами
		6. Колоночные индексы могут съесть весь ваш процессор, чтобы этого не было используйте Resource Governor
		7. No index SEEK operations

-- Delete/Update
	Not only it looks over 2.5 times faster to delete & insert data instead of executing a direct update, but such aspects as locking & blocking can become quite an issue as it was shown in the
		
-- Колоночные индексы / Columnstore Indexes
	- Некластерный может быть только 1
	-- Библиотека
		http://www.nikoport.com/columnstore/
		https://github.com/NikoNeugebauer/CISL
		https://habrahabr.ru/post/324544/
	
	- Советы:		
		1. Load data using only bulk inserts with 100k rows or more, thus bypassing the Delta Store (but the closer you get to 1 million rows in a bulk, the better)
		2. Delete data only using the Switch Partition operation, thus not using the Delete Bitmap	
	
	-- Columnstore Indexes
	- Для хранилищ данных
	- Только в Enterprise
	- Для малых таблик такие индексы лучше не создавать, так как не будет толку
	
	-- Кластеризованный
		- Не комбинируется с др. индексами до 2016, в 2016 другие индексы должны быть выровнены по кластерному колоночному
		- Обновляемы
		
	-- Некластеризованный
		- Комбинируется с др. индексами
		- Не обновляемый до 2016
		
	-- View row groups
		SELECT o.[Name]As TableName,  c.index_id, c.row_group_id, c.state_description, c.total_rows
		FROM sys.sysobjects o
		JOIN sys.column_store_row_groups c
		ON o.id = c.object_id
		
	-- Columnstore
	- RowGroup примерно по 1 млн строк, далее эта граппа делится на Segments по колонкам, которые сжимаются. Плохо если в Row Group меньше строк
	- Единица чтения с диска является сегмент
	-  (SQL Server 2016). Поддержка обновляемого некластерного колоночного индекса стоит примерно 5-10%. Можно сократить эти издержки за счёт отложенной записи в некластерный колоночный индекс (Compression delay) или фильтрованный некластерный колоночный индекс
	- Если существенная порция данных была изменена в кластерном колоночном индексе, то лучше его перестроить, так как данные реально не удаляются, а хранятся на диске, просто в отдельной структуре они помечены как удалённые и через неё исключаются из выборки
	- Delta store хранится в виде B-tree по заполнению около 1 000 000 помещается в основной кластерный колоночный индекс
	- (SQL Server 2016). Чтобы оптимизировать удаление их обновляемого некластерного индекса, была сделана доп. структура "Deleted Buffer", когда там набирается 1 млн строк, он сбрасывает эти данные в Deleted Bitmap. Из-за этого появляется доп. сканирование (сначала NOT IN "Deleted Bitmap", далее NOT IN "Deleted Bufer" + данные из Delta Store + данные из индекса)
	- (SQL Server 2016) Обычный некластерный индекс по верх кластерного колоночного имеет по доп структуру (Mapping index), которая подсказывает текущий RID (так как этот RID меняется когда данные из delta store попадают в колоночный кластерный)
	- (SQL Server 2016) Можно включить Trace Flag 8666, чтобы увидеть в плане запроса соединение со внутренними структурами, изначально они скрываются.
	- (SQL Server 2016) В плане запроса обновляемого колоночного некластерного индекса может быть показано неверное возвращаемое количество строк, так как будет скрываться операция с log buffer без определённого флага трассировки (8666)
	- sys.internal_partitions -- получить данные из log buffer
	
	-- Ускорение
		1. Сжатие
		2. Чтение только нужных колонок
		3. Чтение только нужных сегментов в колонках (WHERE id > ...). Сегмент имеет метаданные минимального и максимального значения, что позвляет пропускать сегменты. Это можно посмотреть в SET STATISTICS OI (segments skipped), но так как порядок данных внутри сегментов не гарантирован, то есть вероятность что будет прочитано больше сегментов, так как в одном сегменте могут быть абсолютно любые значения. Это можно обойти тем, что сначала построить кластерный индекс по нужному ключу, потом создать колоночный с DROP_EXISTING, который построиться по упорядоченным данным кластерного индекса (либо просто дропаем обычный кластерный). Некластерный колоночный индекс будет использовать порядок кластерного обычного для своего построения
		4. Пакетная обработка batch

	-- Версии
		- 2012
			Некластерный, необновляемый
		- 2014
			Кластерный, обновляемый, но несовместим с обычными индексам. Некластерный до сих пор не обновляемый
		- 2012
			Некластереный обновляемый, кластерный колоночный может быть совместим с другими обычными индексами
			
	-- Batch mode
		- https://docs.microsoft.com/en-us/sql/relational-databases/indexes/columnstore-indexes-query-performance
		- Начиная с 2012
		- Может называться векторной обработкой
		- структура 64 кб, от 64 до 900 строк, как следствие строки фильтруются не по 1, а пакетом
		- Доступно только если колоночный индекс. Можно создать в 2016 фильтрованный колоночный индекс по заведомо несущствующему значений. Например ID < 0, затрат на поддерку не будет
		- Оптимизировано для современных CPU

		-- Улучшения (2016)
			1. Возможен для не параллельных запросов
			2. Поддержка MULTIPLE DISTINCT aggregate
			3. Поддерка сортировки
			4. Динамическое выделение памяти
			
		-- Ограничения
			- Outer join prevents batch processing
			- Using IN and EXISTS with subqueries can prevent batch mode execution
			- UNION ALL canprevent batch modeexecution
			- 	Push GROUP BY and aggregation over UNION ALL
				Do final GROUP BY and aggregation of results
				Called “local-global aggregation”
				-- with+union+group by at the end
			- Aggregate without group by doesn’t get batch processing
			- Multiple DISTINCT aggregates 
				- Generates atable spool
				- Spool write/read is single threaded
				-- Решение with + несколько запросов в нём


-- Какие колонки из кластерного индекса включены в колоночный
	select p.partition_number as [partition], c.name as [column], s.column_id, s.segment_id
	,p.data_compression_desc as [compression], s.version, s.encoding_type, s.row_count
	, s.has_nulls, s.magnitude,s.primary_dictionary_id, s.secondary_dictionary_id,
	, s.min_data_id, s.max_data_id, s.null_value
	, convert(decimal(12,3),s.on_disk_size / 1024.0 / 1024.0) as [Size MB]
	from sys.column_store_segments s join sys.partitions p on
	p.partition_id = s.partition_id
	join sys.indexes i on
	p.object_id = i.object_id
	left join sys.index_columns ic on
	i.index_id = ic.index_id and
	i.object_id = ic.object_id and
	s.column_id = ic.index_column_id
	left join sys.columns c on
	ic.column_id = c.column_id and
	ic.object_id = c.object_id
	where i.name = 'IDX_FactSales_ColumnStore'
	order by p.partition_number, s.segment_id, s.column_id


			
	-- Поиск возможных таблиц для колоночных индексов
	
	-- 	-------------------------------------------------------
	-- The queries below need to be executed per database. 
	-- Also, please make sure that your workload has run for
	-- couple of days or its full cycle including ETL etc
	-- to capture the relevant operational stats
	-------------------------------------------------------
	-- picking the tables that qualify CCI
	-- Key logic is
	-- (a) Table does not have CCI
	-- (b) At least one partition has > 1 million rows and does not have unsupported types for CCI
	-- (c) Range queries account for > 50% of all operations
	-- (d) DML Update/Delete operations < 10% of all operations
	select table_id, table_name 
	from (select quotename(object_schema_name(dmv_ops_stats.object_id)) + N'.' + quotename(object_name (dmv_ops_stats.object_id)) as table_name,
		 dmv_ops_stats.object_id as table_id, 
		 SUM (leaf_delete_count + leaf_ghost_count + leaf_update_count) as total_DelUpd_count,
		 SUM (leaf_delete_count + leaf_update_count + leaf_insert_count + leaf_ghost_count) as total_DML_count,
		 SUM (range_scan_count + singleton_lookup_count) as total_query_count,
		 SUM (range_scan_count) as range_scan_count
	  from sys.dm_db_index_operational_stats (db_id(), 
		null,
		null, null) as dmv_ops_stats 
	  where  (index_id = 0 or index_id = 1) 
		 AND dmv_ops_stats.object_id in (select distinct object_id 
										 from sys.partitions p
										 where data_compression <= 2 and (index_id = 0 or index_id = 1) 
										 AND rows >= 1048576
										 AND object_id in (select distinct object_id
														   from sys.partitions p, sysobjects o
														   where o.type = 'u' and p.object_id = o.id))
		 AND dmv_ops_stats.object_id not in ( select distinct object_id 
								from sys.columns
								where user_type_id IN (34, 35, 241)
								OR ((user_type_id = 165 OR user_type_id = 167)  and max_length = -1))
	  group by dmv_ops_stats.object_id 
	 ) summary_table
	where ((total_DelUpd_count+0 * 100.0/NULLIF(total_DML_count+1, 0) < 10.0))
	 AND ((range_scan_count*100.0/NULLIF(total_query_count, 0) > 50.0))
	 
-- Словали
	SELECT * FROM sys.column_store_dictionaries 

-- online
	- ONLINE = ON на CLUSTERED COLUMNSTORE INDEXES не поддерживается
	- В 2016 добавили поддержку ONLINE NONCLUSTERED COLUMNSTORE
		- Может создержать до 33.5 million rows (2^25) в "row group"
		- There is another structure called delete buffer that is used as temporary storage for information about deleted rows. It reduces the overhead that delete bitmap managements would introduce to OLTP transactions.
	
-- Практика
	-- Как создать кластерный колоночный индекс с секционированием
		1. Сначала создаём кластерный индекс
			DROP INDEX [ClusteredColumnStoreIndex-20171018-132027] ON [dbo].[Category] 
			CREATE CLUSTERED INDEX [ClusteredColumnStoreIndex-20171018-132027] ON [dbo].[Category] (c) WITH (DROP_EXISTING = OFF) ON [par_s] (c)
			
		2. Дропаем его и создаём по верх него кластерный колоночный
			CREATE CLUSTERED COLUMNSTORE INDEX [ClusteredColumnStoreIndex-20171018-132027] ON [dbo].[Category] WITH (DROP_EXISTING = ON) ON [par_s] (c)
			
		3. При необходимости создаём другие некластерные индексы, которые будут выровнены с кластерным колоночным
			DROP INDEX [NonClusteredIndex-20171018-132148] ON [dbo].[Category]  
			CREATE NONCLUSTERED INDEX [NonClusteredIndex-20171018-132148] ON [dbo].[Category]([name] ASC) ON [par_s]

-- Оптимизация
	- High min server memory setting 
	- Set REQUEST_MAX_MEMORY_GRANT_PERCENT to 50
	- Add memory
	- Omit columns
	- Reduce parallelism 
	- create columnstore index <name> on <table>(<columns>) with (maxdop = 1);
	- Избавиться от строковых данных
	- Use star schema
	- Put columnstores on large tables only
	- Include every column of table in columnstore index
	- Если колонка не должна содержать NULL, то обязательно определить её как NOT NULL
	-- Agregate pushdown
		Работает только на 8 байтах

	
	-- Избегать
		- Join/filter on string columns
		- Join pairs of very large tables if you don’t have to
		- NOT IN <subquery> on columnstore table
		- OUTER JOIN on columnstore table
		- UNION ALL to combine columnstore tables with other tables
		
	-- Обращать внимание на
		- Spill в hash join, sort
		- Строковые предикаты и соединение по строкам
		- Compute Scalar после CS Index Scan
		- Возможно заменить CROSS APPLY на JOIN

-- Parallelism
	- Максимум 1 поток на 1 rowgroup
	- Нет распределения по потокам, берётся первая попавшаяся строка, по этой причине сильного расхождения количества строк в потоках быть не может
			
-- Информация 	
	-- Сегменты/сегменты
		select p.partition_number as [partition], c.name as [column], s.column_id, s.segment_id
		,p.data_compression_desc as [compression], s.version, s.encoding_type, s.row_count
		, s.has_nulls, s.magnitude,s.primary_dictionary_id, s.secondary_dictionary_id
		, s.min_data_id, s.max_data_id, s.null_value
		, convert(decimal(12,3),s.on_disk_size / 1024.0 / 1024.0) as [Size MB]
		from sys.column_store_segments s join sys.partitions p on
		p.partition_id = s.partition_id
		join sys.indexes i on
		p.object_id = i.object_id
		left join sys.index_columns ic on
		i.index_id = ic.index_id and
		i.object_id = ic.object_id and
		s.column_id = ic.index_column_id
		left join sys.columns c on
		ic.column_id = c.column_id and
		ic.object_id = c.object_id
		where i.name = 'ClusteredColumnStoreIndex-20171018-132027'
		order by p.partition_number, s.segment_id, s.column_id
		
		-- Максимальное и минимальное значение в группах/распределение данных по группам/сегрментам
			select g.state_description, g.row_group_id, s.column_id
			,s.row_count, s.min_data_id, s.max_data_id, g.deleted_rows
			from
			sys.column_store_segments s join sys.partitions p on
			s.partition_id = p.partition_id
			join sys.column_store_row_groups g on
			p.object_id = g.object_id and s.segment_id = g.row_group_id
			where p.object_id = object_id(N'dbo.Category')
			order by g.row_group_id, s.column_id;
			
		-- Распределение по секциям
			SELECT	t.name [table], p.rows, p.partition_number, v.boundary_id, v.value
			FROM	sys.tables t
			JOIN	sys.partitions p
			On	p.object_id = t.object_id
			INNER JOIN	sys.partition_range_values v 
			ON	v.boundary_id = p.partition_number 
			WHERE t.object_id = object_id('dbo.Category')
			order by [table]
			
					
	-- Словари
		select p.partition_number as [partition], c.name as [column], d.column_id, d.dictionary_id
		,d.version, d.type, d.last_id, d.entry_count
		,convert(decimal(12,3),d.on_disk_size / 1024.0 / 1024.0) as [Size MB]
		from sys.column_store_dictionaries d join sys.partitions p on
		p.partition_id = d.partition_id
		join sys.indexes i on
		p.object_id = i.object_id
		left join sys.index_columns ic on
		i.index_id = ic.index_id and
		i.object_id = ic.object_id and
		d.column_id = ic.index_column_id
		left join sys.columns c on
		ic.column_id = c.column_id and
		ic.object_id = c.object_id
		where i.name = 'ClusteredColumnStoreIndex-20171018-132027'
		order by p.partition_number, d.column_id
		
	-- Delta store
		Delta store всё что не СCOMPRESS (SELECT * FROM sys.column_store_row_groups)?
		
	-- Deleted rows/удалённые строки/связь с некластерным индексом
		select ip.object_id, ip.index_id, ip.partition_id, ip.row_group_id, ip.internal_object_type
		,ip.internal_object_type_desc, ip.rows, ip.data_compression_desc, ip.hobt_id
		from sys.internal_partitions ip
		where ip.object_id = object_id(N'dbo.Category');
					
-- Фрагментация
	- Neither tuple mover nor index reorganizing prevent other sessions from inserting new data into a table. New data will be inserted into different and open delta stores. However, deletions and data modifications would be blocked for the duration of the operation. In some cases, you may consider forcing index reorganization manually to reduce execution, and therefore locking, time.
	
		SELECT '['+sh.name+']',   
		'['+object_name(i.object_id)+']' AS TableName,   
		'['+i.name+']' AS IndexName,   
	    MAX(100*(ISNULL(deleted_rows,0))/total_rows) AS 'Fragmentation' , 
		partition_number,
		MAX (partition_number) OVER (PARTITION BY i.name),
		MAX(i.[type])
		FROM sys.indexes AS i  
		INNER JOIN sys.tables tbl ON i.object_id = tbl.object_id
		INNER JOIN sys.schemas sh ON sh.schema_id = tbl.schema_id
		INNER JOIN sys.dm_db_column_store_row_group_physical_stats AS CSRowGroups  
		ON i.object_id = CSRowGroups.object_id AND i.index_id = CSRowGroups.index_id
		WHERE deleted_rows > 0 AND  total_rows > 0
		GROUP BY sh.name,object_name(i.object_id),i.name,partition_number
		HAVING MAX(100*(ISNULL(deleted_rows,0))/total_rows) > 20
		
	-- Посмотреть фрагментированные rowgroup
		SELECT '['+sh.name+']',   
		'['+object_name(i.object_id)+']' AS TableName,   
		'['+i.name+']' AS IndexName,   
		partition_number,
		total_rows,
		deleted_rows,
		row_group_id,
		*
		FROM sys.indexes AS i  
		INNER JOIN sys.tables tbl ON i.object_id = tbl.object_id
		INNER JOIN sys.schemas sh ON sh.schema_id = tbl.schema_id
		INNER JOIN sys.dm_db_column_store_row_group_physical_stats AS CSRowGroups  
		ON i.object_id = CSRowGroups.object_id AND i.index_id = CSRowGroups.index_id
		WHERE deleted_rows > 0 AND  total_rows > 0
	
	-- Устранение фрагментации/обслуживание
		Index reorganization, by default, is compressing and moving the data from closed delta stores to row groups. Delete bitmap and open delta stores stay intact.
		You can use the ALTER INDEX REORGANIZE WITH (COMPRESS_ALL_ROW_GROUPS = ON) statement to close and compress all open row groups. SQL Server does not merge row groups during this operation		
		
		SET @sql = 'ALTER INDEX '+@indexName+' ON '+@schemaName+'.'+@tableName+' REORGANIZE PARTITION = ALL WITH (COMPRESS_ALL_ROW_GROUPS = ON);
							
		ALTER INDEX '+@indexName+' ON '+@schemaName+'.'+@tableName+' REORGANIZE PARTITION = ALL'
		
	-- Более сильное сжатие (быстрое чтение, но более медленное изменение)
		ALTER INDEX cci_SimpleTable ON SimpleTable REBUILD WITH (DATA_COMPRESSION = COLUMNSTORE_ARCHIVE);  
		
		
-- Статистика
	- Статистики по колоночному индексу создаётся в момент создания , но не используется в будущем. Поэтому хорошая практика создавать колоночную статистику самому или позволить делать это системе автоматически
	- Обычный скрипт обновления статистики не возьмёт в работу колоночную статистику, так как в информации о количестве строк будет 0
	
	-- Дата обновления
		SELECT indid, o.name AS Table_Name, i.name AS Index_Name, 
		   STATS_DATE(o.id,i.indid) AS Date_Updated, rowmodctr--, i.*
		   , st.is_incremental
		FROM sysobjects o 
			JOIN sysindexes i 
				ON i.id = o.id
			JOIN sys.stats st
				ON st.object_id = o.id and st.stats_id = i.indid
		WHERE xtype = 'U' AND i.name IS NOT NULL and o.id = object_id('dbo.Category')
		ORDER BY Date_Updated 
	
	- Просто так в 2016 и ниже её не обновить (скорее всего и не надо)
		- Получаем значение для STATS_STREAM
			DBCC SHOW_STATISTICS(N'[dbo].[Category]', N'ClusteredColumnStoreIndex-20171018-132027') WITH STATS_STREAM
		
		- Обновляем
			UPDATE STATISTICS [dbo].[Category] [ClusteredColumnStoreIndex-20171018-132027] WITH STATS_STREAM =0x010000000300000000000000000000009CBC791100000000E8010000000000007801000000000000380300003800000004000A00000000000000000000000000E7030000E7000000FE0100000000000015D0000000000000380200003800000004000A0000000000000000000000000007000000260CB70077A8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000003000000040000000000000000000000000000000000000000000000
			
-- Скользящее окно
	As you can see, implementation of Sliding Window pattern with columnstore indexes is very similar to B-Tree tables. The only differences are:
		- You must have empty right-most partition pre-allocated to perform the split. I’d like to reiterate that even though it is not required with B-Tree indexes, such empty partition would reduce I/O overhead and table locking during split operation there.
		- You must have another empty left-most partition to perform the merge. This is not required nor needed with B-Tree indexes.

-- Partition/Секционирование
	- Не создавайте слишком малых секций, хорошо когда rowgroup заполнены (1 млн строк)
	- Не даёт объединять партиции если они в разных файловых группах
	- Не даёт разделять не пустые секции
		- Приходится выгружать данные, делать SPLIT и загружать обратно