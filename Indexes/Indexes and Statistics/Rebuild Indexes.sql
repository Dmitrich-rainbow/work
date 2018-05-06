USE DBName

DECLARE @DBName nvarchar(255) = (SELECT DB_NAME()), @query nvarchar(4000), @RecoveryModelHitn bit = 0, @queryStatistics nvarchar(4000)

-- Проверяем модель восстановления, если FULL, то переключаемся в BULK_LOGGED
IF (SELECT recovery_model FROM sys.databases WHERE name = @DBName) = 1
BEGIN
	SET @query = 'ALTER DATABASE ' + @DBName + ' SET RECOVERY BULK_LOGGED'
	exec (@query)
	SET @RecoveryModelHitn = 1
END

-- Отключение влиения перестроения индексов на статистику
SET @queryStatistics = 'alter database ' + @DBName + ' set auto_create_statistics off'
exec (@queryStatistics)
SET @queryStatistics = 'alter database ' + @DBName + ' set auto_update_statistics off'
exec (@queryStatistics)


CREATE TABLE #TempTable(
	database_id int,
	table_name varchar(250),
	index_id int,
	index_name varchar(250),
	avg_frag_percent float,
	fill_factor int
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
    '['+tbl.name+']', 
    dm.index_id, 
    '['+idx.name+']', 
    dm.avg_fragmentation_in_percent,   
    idx.fill_factor
FROM sys.dm_db_index_physical_stats(DB_ID(), null, null, null, 'LIMITED') dm
    INNER JOIN sys.tables tbl ON dm.object_id = tbl.object_id
    INNER JOIN sys.indexes idx ON dm.object_id = idx.object_id AND dm.index_id = idx.index_id
WHERE page_count > 1000
    AND avg_fragmentation_in_percent > 15
    AND dm.index_id > 0 
    AND idx.is_disabled = 0
    AND tbl.name not like '%$%'
    
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
		
		BEGIN TRY

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

		END TRY
		
		BEGIN CATCH
			 SELECT '***Filed*** ' + ERROR_MESSAGE()
		END CATCH
		
	END
    FETCH NEXT FROM defragCur INTO @index_id, @tableName, @indexName, @defrag,@fill_factor
END
CLOSE defragCur
DEALLOCATE defragCur

DROP TABLE #TempTable

-- Возвращаем модель восстановления
IF @RecoveryModelHitn = 1
BEGIN
	SET @query = 'ALTER DATABASE ' + @DBName + ' SET RECOVERY FULL'
	exec (@query)
	SET @RecoveryModelHitn = 0
END

-- Возвращаем обновление статистики
SET @queryStatistics = 'alter database ' + @DBName + ' set auto_create_statistics ON'
exec (@queryStatistics)
SET @queryStatistics = 'alter database ' + @DBName + ' set auto_update_statistics ON'
exec (@queryStatistics)