DECLARE @Name varchar(100)
DECLARE @query varchar(8000)
DECLARE @dbname table (name nvarchar(255))
DECLARE @query_result table (name nvarchar(255))

-- Формируем таблицу 
INSERT INTO @dbname 
SELECT name FROM sys.databases WHERE name NOT IN ('tempdb','model')

-- Отменяем обслуживание, если мы не на Primary
-- Для AlwaysOn (заходим в процерку только начиная с 2008 редакции)
IF (SELECT SUBSTRING(CAST(SERVERPROPERTY('productversion') as nvarchar(50)),1,CHARINDEX('.', CAST(SERVERPROPERTY('productversion') as nvarchar(50)))-1)) > 10
BEGIN
	
	-- Очищаем временную таблицу для начала работы с ней
	DELETE FROM @query_result

	-- Добавляем в таблицу признак Primary/Secondary
	INSERT INTO @query_result
	exec ('SELECT primary_replica FROM sys.dm_hadr_availability_group_states')	
	
	-- Производим проверку Secondary or not
	IF (SELECT @@SERVERNAME) <> (SELECT name FROM @query_result)
	BEGIN
		
		-- Очищаем временную таблицу для начала работы с ней
		DELETE FROM @query_result

		-- Заносим значения БД, которые входят в AlwaysOn
		INSERT INTO @query_result
		exec ('SELECT name FROM sys.databases WHERE name NOT IN (''tempdb'') AND replica_id IS NOT NULL')

		-- Так как мы на Secondary, то исключаем из обслуживания БД, которые входят в AlwaysOn
		DELETE FROM @dbname WHERE name in (SELECT name FROM @query_result)
	END
END

-- Для Mirroring
DELETE FROM @dbname WHERE name IN (SELECT name FROM sys.databases WHERE name NOT IN ('tempdb','model') AND state_desc <> 'ONLINE') 

-- Объявляем курсом для определения количества БД
DECLARE dblist CURSOR FOR
	SELECT name FROM @dbname
OPEN dblist
	FETCH NEXT FROM dblist INTO @Name
WHILE @@FETCH_STATUS = 0
    BEGIN

-- Формируем скрипт выполнения
SET @query = '
SET LOCK_TIMEOUT 600000
SET QUOTED_IDENTIFIER ON

USE ['+@Name+']

DECLARE @schemaName VARCHAR(250)
DECLARE @tableName VARCHAR(250) 
DECLARE @indexName VARCHAR(250)
DECLARE @defrag FLOAT
DECLARE @partition_number VARCHAR(250)
DECLARE @max_partition_number VARCHAR(250)
DECLARE @sql NVARCHAR(MAX)
DECLARE @database_name nvarchar(255)
DECLARE @columnstore_exists int
DECLARE @indexes_count int
DECLARE @columnstore_indexes_count int

SET @database_name = DB_ID()
SET @indexes_count = 0
SET @columnstore_indexes_count = 0


DECLARE defragCur CURSOR FOR

SELECT 
	''[''+sh.name+'']'', 
    ''[''+tbl.name+'']'', 
    ''[''+idx.name+'']'', 
    dm.avg_fragmentation_in_percent,
	partition_number,
	MAX (partition_number) OVER (PARTITION BY idx.name),
	ISNULL((SELECT COUNT(*) FROM sys.indexes idx1 WHERE idx1.[object_id] = idx.[object_id] AND idx1.type_desc LIKE ''%COLUMNSTORE%''),0) AS columnstore_exists
FROM sys.dm_db_index_physical_stats(@database_name, null, null, null, ''LIMITED'') dm
    INNER JOIN sys.tables tbl ON dm.object_id = tbl.object_id
    INNER JOIN sys.indexes idx ON dm.object_id = idx.object_id AND dm.index_id = idx.index_id
	INNER JOIN sys.schemas sh ON sh.schema_id = tbl.schema_id
WHERE page_count > 8
    AND avg_fragmentation_in_percent > 15
    AND dm.index_id > 0 
    AND idx.is_disabled = 0
    AND tbl.name not like ''%$%''
	AND idx.type_desc NOT LIKE ''%COLUMNSTORE%''
ORDER BY dm.avg_fragmentation_in_percent DESC

OPEN defragCur
FETCH NEXT FROM defragCur INTO @schemaName,@tableName, @indexName, @defrag,@partition_number,@max_partition_number,@columnstore_exists
WHILE @@FETCH_STATUS=0
BEGIN

	IF OBJECT_ID(@schemaName+''.''+@tableName,''U'') is not null
	BEGIN

		IF @partition_number = 1 AND @max_partition_number = 1
		SET @partition_number = ''ALL''

		SET @sql = N''ALTER INDEX '' + @indexName + '' ON '' + @schemaName+''.''+@tableName

		BEGIN TRY		

			IF (@defrag > 30 AND @columnstore_exists < 1) 
			BEGIN
				
				-- Выполняем онлайн перестроение если редакция Enterprise

				IF (SELECT @@VERSION) LIKE ''%Enterprise Edition%''
					SET @sql = @sql + N'' REBUILD PARTITION = ''+@partition_number+'' WITH (ONLINE = ON)''
				ELSE
					SET @sql = @sql + N'' REORGANIZE PARTITION = ''+@partition_number

			END
			ELSE 
			BEGIN
				SET @sql = @sql + N'' REORGANIZE PARTITION = ''+@partition_number
			END				
		
		--print @sql+''
		--''
	       
		exec (@sql) 

		SET @indexes_count = @indexes_count + 1

		END TRY
		BEGIN CATCH
			IF ERROR_NUMBER() = 2725
			BEGIN
				SET @sql = N''ALTER INDEX '' + @indexName + '' ON '' + @schemaName+''.''+@tableName+ N'' REORGANIZE PARTITION = ''+@partition_number		
		
			--print @sql+''
		--''
				exec (@sql) 
			END
			ELSE IF ERROR_NUMBER() IN (2552,1943)
			BEGIN
				SET @sql =  N''ALTER INDEX '' + @indexName + '' ON '' + @schemaName+''.''+@tableName+ N'' SET (ALLOW_PAGE_LOCKS = ON )''
				
				--print @sql
				exec (@sql) 
	
				SET @sql = N''ALTER INDEX '' + @indexName + '' ON '' + @schemaName+''.''+@tableName+ N'' REORGANIZE PARTITION = ''+@partition_number
				
				--print @sql
				exec (@sql) 		
				
			END
			ELSE
			BEGIN
				SET @database_name = DB_NAME()
				INSERT INTO master.dbo.dbmaintenance 
				VALUES (@database_name,''INDEX - Номер ошибки ''+CAST(ERROR_NUMBER() as nvarchar(50)) + '', в строке '' + CAST(ERROR_LINE() as nvarchar(50)) +''. Сообщение об ошибке: '' + CAST(ERROR_MESSAGE() as nvarchar(400)),GETDATE())
			END
		END CATCH
	END
    FETCH NEXT FROM defragCur INTO @schemaName,@tableName, @indexName, @defrag,@partition_number,@max_partition_number,@columnstore_exists
END
CLOSE defragCur
DEALLOCATE defragCur

-- Приступаем к обновлению колоночных индексов если версия SQL Server 2014+
IF CAST(SUBSTRING(CAST(SERVERPROPERTY (''productversion'') as nvarchar(50)),1,2) as int) > 12
BEGIN

DECLARE @type int

SET @schemaName = ''''
SET @tableName = ''''
SET @indexName = ''''
SET @partition_number = ''''
SET @max_partition_number = ''''
SET @defrag = ''''
SET @sql = ''''


DECLARE defragCC CURSOR FOR

	SELECT ''[''+sh.name+'']'',   
		''[''+object_name(i.object_id)+'']'' AS TableName,   
		''[''+i.name+'']'' AS IndexName,   
	    MAX(100*(ISNULL(deleted_rows,0))/total_rows) AS ''Fragmentation'' , 
		partition_number,
		MAX (partition_number) OVER (PARTITION BY i.name),
		MAX(i.[type])
	FROM sys.indexes AS i  
		INNER JOIN sys.tables tbl ON i.object_id = tbl.object_id
		INNER JOIN sys.schemas sh ON sh.schema_id = tbl.schema_id
		INNER JOIN sys.dm_db_column_store_row_group_physical_stats AS CSRowGroups  
		ON i.object_id = CSRowGroups.object_id AND i.index_id = CSRowGroups.index_id
		WHERE CSRowGroups.deleted_rows > 0 AND CSRowGroups.total_rows > 0
		GROUP BY sh.name,object_name(i.object_id),i.name,partition_number
		HAVING MAX(100*(ISNULL(deleted_rows,0))/total_rows) > 20
		ORDER BY MAX(100*(ISNULL(deleted_rows,0))/total_rows) DESC

OPEN defragCC
FETCH NEXT FROM defragCC INTO @schemaName,@tableName, @indexName, @defrag,@partition_number,@max_partition_number,@type
WHILE @@FETCH_STATUS=0
BEGIN

	IF OBJECT_ID(@schemaName+''.''+@tableName,''U'') is not null
	BEGIN
		BEGIN TRY				
				/* -- Отключил так как даже на 2016 появляются проблемы с ONLINE = ON
				IF @type = 6 and (SELECT @@VERSION) LIKE ''%Enterprise Edition%''
					IF @max_partition_number > 1
						SET @sql = ''ALTER INDEX ''+@indexName+'' ON ''+@schemaName+''.''+@tableName+'' Rebuild PARTITION = ''+@partition_number+'' WITH (ONLINE = ON);''
					ELSE
						SET @sql = ''ALTER INDEX ''+@indexName+'' ON ''+@schemaName+''.''+@tableName+'' Rebuild PARTITION = ALL WITH (ONLINE = ON);''
				ELSE
				BEGIN */
					IF @max_partition_number > 1
						BEGIN
							SET @sql = ''ALTER INDEX ''+@indexName+'' ON ''+@schemaName+''.''+@tableName+'' REORGANIZE PARTITION = ''+@partition_number+'' WITH (COMPRESS_ALL_ROW_GROUPS = ON);
							
							ALTER INDEX ''+@indexName+'' ON ''+@schemaName+''.''+@tableName+'' REORGANIZE PARTITION = ''+@partition_number

						END
					ELSE 
						BEGIN

							SET @sql = ''ALTER INDEX ''+@indexName+'' ON ''+@schemaName+''.''+@tableName+'' REORGANIZE PARTITION = ALL WITH (COMPRESS_ALL_ROW_GROUPS = ON);
							
							ALTER INDEX ''+@indexName+'' ON ''+@schemaName+''.''+@tableName+'' REORGANIZE PARTITION = ALL''

						END
				--END

				--print @sql
				exec (@sql)
				
				SET @columnstore_indexes_count = @columnstore_indexes_count +1 

		END TRY
		BEGIN CATCH

				SET @database_name = DB_NAME()
				INSERT INTO master.dbo.dbmaintenance 
				VALUES (@database_name,''INDEX - Номер ошибки ''+CAST(ERROR_NUMBER() as nvarchar(50)) + '', в строке '' + CAST(ERROR_LINE() as nvarchar(50)) +''. Сообщение об ошибке: '' + CAST(ERROR_MESSAGE() as nvarchar(400)),GETDATE())

		END CATCH
	END
    FETCH NEXT FROM defragCC INTO @schemaName,@tableName, @indexName, @defrag,@partition_number,@max_partition_number,@type
END
CLOSE defragCC
DEALLOCATE defragCC

END

print ''Indexes done - ''+ CAST(@indexes_count as nvarchar(50))
print ''Columnstore Indexes done - ''+ CAST(@columnstore_indexes_count as nvarchar(50)) 

'

print @Name

exec (@query)

FETCH NEXT FROM dblist INTO @Name
	END
CLOSE dblist
DEALLOCATE dblist
GO
exec msdb..sp_start_job @job_name = 'Update Statistics'