USE YourDB

-- Проверяем модель восстановления, если FULL, то переключаемся в BULK_LOGGED
DECLARE @DBName nvarchar(255) = (SELECT DB_NAME()), @query nvarchar(4000), @RecoveryModelHitn bit = 0, @queryStatistics nvarchar(4000)

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

DECLARE @currentProcID INT --Порядковый номер процедуры дефрагментации
 --Выбираем последний номер, и просто добавляем единичку
SELECT @currentProcID = ISNULL(MAX(proc_id), 0) + 1 FROM dba_tasks.dbo.index_defrag_statistic
--И заполняем таблицу данными о состоянии индексов
INSERT INTO dba_tasks.dbo.index_defrag_statistic (
    proc_id,
    database_id,
    [object_id],
    table_name,
    index_id,
    index_name,
    avg_frag_percent_before,
    fragment_count_before,
    pages_count_before,
    fill_factor,
    partition_num)
SELECT
    @currentProcID,
    dm.database_id,
    dm.[object_id],
    tbl.name,
    dm.index_id,
    idx.name,
    dm.avg_fragmentation_in_percent,
    dm.fragment_count,
    dm.page_count,
    idx.fill_factor,
    dm.partition_number
FROM sys.dm_db_index_physical_stats(DB_ID(), null, null, null, 'LIMITED') dm
    INNER JOIN sys.tables tbl ON dm.object_id = tbl.object_id
    INNER JOIN sys.indexes idx ON dm.object_id = idx.object_id AND dm.index_id = idx.index_id
WHERE page_count > 1000
    AND avg_fragmentation_in_percent > 15
    AND dm.index_id > 0 
    AND idx.is_disabled = 0
    AND tbl.name not like '%$%'

----------------------------------------

--Обьявим необходимые переменные
DECLARE @partitioncount INT --Количество секций
DECLARE @action VARCHAR(4000) --Действие, которые мы будем делать с индексом
DECLARE @start_time DATETIME --Начало выполнения запроса ALTER INDEX
DECLARE @end_time DATETIME --Конец выполнения запроса ALTER INDEX
--см описание таблицы
DECLARE @object_id INT
DECLARE @index_id INT
DECLARE @tableName VARCHAR(250)
DECLARE @indexName VARCHAR(250)
DECLARE @defrag FLOAT
DECLARE @partition_num INT
DECLARE @fill_factor INT
--Сам запрос, который мы будем выполнять, я поставил MAX, потому как иногда меняю такие скрипты, и забываю поправить размер данной переменной, в результате получаю ошибку.

DECLARE @sql NVARCHAR(Max)

--Далее объявляем курсор
DECLARE defragCur CURSOR FOR
    SELECT
        [object_id],
        index_id,
        table_name,
        index_name,
        avg_frag_percent_before,
        fill_factor,
        partition_num
    FROM dba_tasks.dbo.index_defrag_statistic
    WHERE proc_id = @currentProcID 
    ORDER BY [object_id], index_id DESC --Сначала не кластерные индексы 

OPEN defragCur
FETCH NEXT FROM defragCur INTO @object_id, @index_id, @tableName, @indexName, @defrag, @fill_factor, @partition_num
WHILE @@FETCH_STATUS=0
BEGIN

	BEGIN TRY
	
	SET @start_time = NULL
	SET @end_time = NULL
	SET @action = ''	
	
    SET @sql = N'ALTER INDEX [' + @indexName + '] ON [' + @tableName+']'

    SELECT @partitioncount = count (*)
    FROM sys.partitions
    WHERE object_id = @object_id AND index_id = @index_id;

   
    --В моем случае, важно держать неможко пустого места на страницах, потому, что вставка в тоже таблицы имеете место, и не хочеться тратить драгоценное время пользователей на разбиение страниц

    IF (@fill_factor != 90)
    BEGIN
        SET @sql = @sql + N' REBUILD WITH (FILLFACTOR = 90, SORT_IN_TEMPDB = ON)'
        SET @action = 'rebuild90'
    END
    ELSE
    BEGIN --Тут все просто, действуем по рекомендации MS
        IF (@defrag > 30) --Если фрагментация больше 30%, делаем REBUILD
        BEGIN
            SET @sql = @sql + N' REBUILD WITH (SORT_IN_TEMPDB = ON)'
            SET @action = 'rebuild'
        END
        ELSE --В противном случае REORGINIZE
        BEGIN
            SET @sql = @sql + N' REORGANIZE'
            SET @action = 'reorginize'
        END
    END   

    --Если есть несколько секций
    IF @partitioncount > 1
        SET @sql = @sql + N' PARTITION=' + CAST(@partition_num AS nvarchar(5)) + ' WITH (SORT_IN_TEMPDB = ON)'

    --Фиксируем время старта
    SET @start_time = GETDATE()
    EXEC sp_executesql @sql

    --И время завершения
    SET @end_time = GETDATE()   

    --Сохраняем время в таблицу
    UPDATE dba_tasks.dbo.index_defrag_statistic
    SET
        start_time = @start_time,
        end_time = @end_time,
        [action] = @action
    WHERE proc_id = @currentProcID
        AND [object_id] = @object_id
        AND index_id = @index_id
        
    END TRY    
    
    BEGIN CATCH
    
    SET @action = '***Filed*** ' + ERROR_MESSAGE()
    
    UPDATE dba_tasks.dbo.index_defrag_statistic
    SET
        start_time = @start_time,
        end_time = @end_time,
        [action] = @action
    WHERE proc_id = @currentProcID
        AND [object_id] = @object_id
        AND index_id = @index_id
        
    END CATCH
  
    FETCH NEXT FROM defragCur INTO @object_id, @index_id, @tableName, @indexName, @defrag, @fill_factor, @partition_num

END

CLOSE defragCur

DEALLOCATE defragCur


-- DECLARE @currentProcID INT
-- set @currentProcID=2
UPDATE dba
SET
    dba.avg_frag_percent_after = dm.avg_fragmentation_in_percent,
    dba.fragment_count_after = dm.fragment_count,
    dba.pages_count_after = dm.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), null, null, null, null) dm
    INNER JOIN dba_tasks.dbo.index_defrag_statistic dba
        ON dm.[object_id] = dba.[object_id]
            AND dm.index_id = dba.index_id
WHERE dba.proc_id = @currentProcID
    AND dm.index_id > 0
	
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