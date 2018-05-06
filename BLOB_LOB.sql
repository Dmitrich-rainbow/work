-- Основное
	- При создании таблицы можно указать параметр TEXTIMAGE_ON (Указывает, что текст, ntext, изображение, xml, varchar(max), nvarchar(max), varbinary(max), и столбцов определяемого пользователем типа данных CLR (включая geometry и geography) хранятся в указанной файловой группе.)


-- Возможность хранения блобов в строке 
	http://sqlmag.com/database-administration/text-row-internals
	sp_tableoption Mytable, 'text in row', value

-- Посмотреть размер
	select 
		index_id, partition_number, alloc_unit_type_desc
		,index_level
		,page_count
		,page_count * 8 / 1024 as [Size MB]
	from 
		sys.dm_db_index_physical_stats
		(
			db_id() /*Database */
			,object_id(N'dbo.MyTable') /* Table (Object_ID) */
			,1 /* Index ID */
			,null /* Partition ID – NULL – all partitions */
			,'detailed' /* Mode */
		)
	
	-- вариант 2 (недокументированный)		
		DBCC IND('master','dbo.TestLOBTable',-1)
		
		
-- Поиск где используются MAX тип данных
	
	-- Ищем БД, где больше 2х файлов (ищем FILESTREAM)
	SELECT DB_NAME(database_id),Count(*) FROM sys.master_files 
		GROUP BY database_id
		HAVING Count(*) > 2
		
	-- Ищем столбцы с типом данных MAX
		SELECT OBJECT_NAME(c.object_id) as g,t.name,* FROM sys.columns c  INNER JOIN sys.types t ON c.system_type_id = t.system_type_id AND t.max_length > 1024 AND c.max_length < 1 and c.object_id > 100
		INNER JOIN sys.tables tb ON c.object_id = tb.object_id -- Убираем JOIN, если хотим получить что-то кроме таблиц
