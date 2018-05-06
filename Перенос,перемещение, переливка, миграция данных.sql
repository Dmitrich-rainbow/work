-- 
	- https://technet.microsoft.com/en-us/library/dd537533%28v=sql.100%29.aspx?f=255&MSPPError=-2147217396
	- https://technet.microsoft.com/en-us/library/dd425070(v=sql.100).aspx
	- BULK INSERT
	- SSIS
	- https://orderbyselectnull.com/2017/08/16/the-trillion-row-table/
	- Лить в разные таблицы быстрее, разными коннектами -- узнать почему
	
	
	
	
вообще лучше включить минимальное протоколирование. Например заливка в один поток 70 Гб.  как сейчас помню с tablockx и T610 8 мин. без в класике 25 мин.

Вообще по хорошему залить бы данные в разные таблицы паралельно, а потом свичнуть в одну. т.к. при tablockx работать можент только 1 поток. Но выделение блокировок не будет и выделение дополнительных страниц будет либо кластерами, либо экстентами. в зависимости от версии и редакции.



1 Сопособ (Полностью перемещает данные из данного файла):
DBCC SHRINKFILE (Test1data, EMPTYFILE);
2. 
-- Создать новую файловую группу
-- Создать новый ndf
-- Присвоить ему данную группу
-- Присвоить нужному кластерному индексу ndf-файл
3. Обычный Rebuld позволяет размазать данные по файлам
4. Удаление и создание индекса

-- Перемещение таблицы по файловым группам 
	1. https://gallery.technet.microsoft.com/scriptcenter/c1da9334-2885-468c-a374-775da60f256f
	2. Перестроение кластерного индекса
	3. Если это heap, то необходимо создать/удалить кластерный индекс

-- Равномерность распределения данных
	- Всё зависит от свободного пространства в других файлах, чем его больше, тем больше данных он переместит в другие файлы
	
-- Посмотреть сколько данных в файлах БД (SQL Server 2012, чтобы получить для меньших версий необходимо зайти в профайлер и поймать раздел SHRINK)
	select
	db_name()           AS [DatabaseName],
	s.name              AS [DB_File_Name],
	s.physical_name     AS [FileName],
	s.size * CONVERT(float,8) AS [TotalSize],
	CAST(CASE s.type WHEN 2
			THEN s.size * CONVERT(float,8)
			ELSE dfs.allocated_extent_page_count*convert(float,8)
		END AS float)   AS [UsedSpace],
	CASE s.type WHEN 2
		THEN 0
		ELSE s.size * CONVERT(float,8) - dfs.allocated_extent_page_count*convert(float,8)
	END                 AS [AvailableFreeSpace]
	from sys.database_files AS s
	left outer join sys.dm_db_file_space_usage as dfs
	ON dfs.database_id = db_id()
	AND dfs.file_id = s.file_id
	where (s.drop_lsn IS NULL)
	
	
---   Узнать свободное пространство в файлах базы данных перед обрезанием (Работает на всех версиях SQL)
	SELECT
		 name AS 'LogicalName'
		,physical_name AS 'PhysicalName'
		,CONVERT(INT,ROUND(size/128,0)) AS 'Size (MB)'
		,CONVERT(INT,ROUND(FILEPROPERTY(name,'SpaceUsed')/128,0)) AS 'SpaceUsed (MB)'
	FROM sys.database_files
	WHERE type = 0;
	
-- Распределение данных по файлам БД (Ерунда)
		SELECT DB_NAME(saf.database_id) AS [База данных]
		, saf.name AS [Логическое имя]
		, vfs.BytesWritten/1048576 AS [Записано (Мб)]
		, vfs.BytesOnDisk/1048576 AS [Размер БД(Mб)]
		, saf.physical_name AS [Путь к файлу]
		, 100*(vfs.BytesWritten/1048576)/(SELECT SUM(BytesWritten/1048576)
		FROM fn_virtualfilestats(NULL,NULL) AS vfs1
		WHERE vfs1.dbid = saf.database_id
		AND vfs1.fileid <> 2) AS '%'
		FROM sys.master_files AS saf
		JOIN fn_virtualfilestats(DB_ID(),NULL) AS vfs ON vfs.dbid = saf.database_id
		AND vfs.fileid = saf.file_id
		--AND saf.database_id NOT IN (1,3,4)
		AND saf.type < 2
		AND saf.file_id <> 2
		AND DB_NAME(saf.database_id) = DB_NAME()
		ORDER BY BytesWritten/1048576 DESC