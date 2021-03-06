-- Страницы
	- http://www.sqlskills.com/blogs/paul/inside-the-storage-engine-gam-sgam-pfs-and-other-allocation-maps/
	1 – data page
	2 – index page
	3 and 4 – text pages
	8 – GAM page -- Global Allocation Map
	9 – SGAM page  -- Shared Global Allocation Map
	10 – IAM page
	11 – PFS page

-- Обязательно включить, чтобы можно было получить информацию
	DBCC TRACEON (3604)

-- Получить информацию о станицах
	-- dbcc page ( {‘dbname’ | dbid}, filenum, pagenum [, printopt={0|1|2|3} ])

	DBCC PAGE (WWWBRON_H_6,1,1142833,3)
	DBCC PAGE (tempdb,8,497538,3)
	DBCC PAGE (WWWBRON_T15_S6,1,969680,3)
	DBCC PAGE (tempdb,3,70401,3)
	DBCC PAGE (tempdb,1,1533,3)
	DBCC PAGE (tempdb,6,488426,3)
	DBCC PAGE (tempdb,8,497538,3)

-- Найти объект

	SELECT * FROM sys.indexes WHERE [object_id] = 229575856
	SELECT * FROM sys.objects WHERE [object_id] = 229575856
	SELECT * FROM sys.tables WHERE [object_id] = 229575856
	SELECT * FROM sys.stats WHERE [object_id] = 229575856
	SELECT * FROM sys.allocation_units WHERE allocation_unit_id = 72057594059227136
	SELECT OBJECT_NAME(229575856)

	-- Найти таблицу по allocation_unit
	
		SELECT au.allocation_unit_id, OBJECT_NAME(p.object_id) AS table_name, fg.name AS filegroup_name,
		au.type_desc AS allocation_type, au.data_pages, partition_number,*
		FROM sys.allocation_units AS au
		JOIN sys.partitions AS p ON au.container_id = p.partition_id
		JOIN sys.filegroups AS fg ON fg.data_space_id = au.data_space_id
		WHERE au.allocation_unit_id = 72057594095927296
		ORDER BY au.allocation_unit_id

-- read ahead
	- Попытка SQL Server предугадать какие ещё страницы понадобятся и тем самым прочитать больше, чтобы потом понадобилось
	- Используется начиная с 16 страниц
	- Перестаёт работать когда достигается максимульный лимит выделения памяти или нет болье свободной патимя (менее 2048 страниц)
	
	
-- Пустые страницы / empty space
	;WITH db_pages
	AS
	(
		SELECT  DDDPA.page_type,
			 DDDPA.allocated_page_file_id,
			 DDDPA.allocated_page_page_id,
			 DDDPA.page_level,
			 DDDPA.page_free_space_percent,
			 DDDPA.is_allocated
		FROM      sys.dm_db_database_page_allocations
			 (
			   DB_ID(),
			   OBJECT_ID(N'', N'U'), -- Укахать таблицу
			   NULL,
			   NULL,
			   'DETAILED'
			 ) AS DDDPA
	)
	SELECT  DOBD.file_id,
		 DOBD.page_id,
		 DOBD.page_level,
		 DOBD.page_type,
		 DOBD.row_count,
		 DOBD.free_space_in_bytes,
		 DP.page_free_space_percent,
		 DP.is_allocated,*
	FROM      sys.dm_os_buffer_descriptors AS DOBD
		 INNER JOIN db_pages AS DP ON
		 (
			 DOBD.file_id = DP.allocated_page_file_id
			 AND DOBD.page_id = DP.allocated_page_page_id
			 AND DOBD.page_level = DP.page_level
		 )
	WHERE   DOBD.database_id = DB_ID() and free_space_in_bytes > 8000 -- Ищем где на странице более 8000 байт
	ORDER BY
		 DP.page_type DESC,
		 DP.page_level DESC,
		 DOBD.page_id,
		 DOBD.file_id;
