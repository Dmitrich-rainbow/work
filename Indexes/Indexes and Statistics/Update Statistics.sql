-- Объявляем объекты
DECLARE @Name varchar(100)
DECLARE @query varchar(8000)
DECLARE @dbname table (name nvarchar(255))
DECLARE @query_dynamic varchar(8000)
DECLARE @query_dynamic_incremantal varchar(8000)
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
    SELECT * FROM @dbname
OPEN dblist
    FETCH NEXT FROM dblist INTO @Name
WHILE @@FETCH_STATUS = 0
    BEGIN

-- Если редакция сервера до 2008 SP2, то применяем старый механизм сбора статистики
IF (SELECT SUBSTRING(CAST(SERVERPROPERTY('productversion') as nvarchar(50)),1,CHARINDEX('.', CAST(SERVERPROPERTY('productversion') as nvarchar(50)))-1)) < 10
OR ((SELECT @@VERSION) like '%SQL Server 2008%' AND (SELECT SERVERPROPERTY('ProductLevel')) not in ('SP2','SP3'))
SET @query_dynamic = 'select DISTINCT SCHEMA_NAME(uid) as gerg, 
        object_name (i.id)as objectname,        
        i.name as indexname
        from sysindexes i INNER JOIN dbo.sysobjects o ON i.id = o.id
        LEFT JOIN sysindexes si ON si.id = i.id AND si.rows > 0 
        where i.rowmodctr > 
        CASE WHEN (si.rows <= 5000000)
            THEN ((si.rows) * 0.10 + 500)
        WHEN ((si.rows) > 5000000 AND (si.rows) <= 10000000)
            THEN ((si.rows) * 0.5 + 500)
        WHEN ((si.rows) > 10000000 AND (si.rows) <= 100000000)
            THEN ((si.rows) * 0.03 + 500)
        WHEN ((si.rows) > 100000000 AND (si.rows) <= 500000000)
            THEN ((si.rows) * 0.01 + 500)
        WHEN ((si.rows) > 500000000 AND (si.rows) <= 1000000000)
            THEN ((si.rows) * 0.005 + 500)
        WHEN ((si.rows) > 1000000000)
            THEN ((si.rows) * 0.003 + 500)
        END
        AND i.name not like ''sys%''
        AND object_name(i.id) not like ''sys%''
        AND STATS_DATE(i.id, i.indid) < GetDATE()-1'
ELSE IF CAST(SUBSTRING(CAST(SERVERPROPERTY ('productversion') as nvarchar(50)),1,2) as int) < 12
SET @query_dynamic = 'SELECT
    sch.name  AS ''Schema'',
    so.name as ''Table'',
    ss.name AS ''Statistic''
FROM sys.stats ss
JOIN sys.objects so ON ss.object_id = so.object_id
JOIN sys.schemas sch ON so.schema_id = sch.schema_id
OUTER APPLY sys.dm_db_stats_properties(so.object_id, ss.stats_id) AS sp
WHERE so.TYPE = ''U''
AND [rows] > 1000 
AND (sp.modification_counter >
    CASE WHEN (sp.rows <= 5000000)
        THEN ((sp.rows) * 0.10 + 500)
    WHEN ((sp.rows) > 5000000 AND (sp.rows) <= 10000000)
        THEN ((sp.rows) * 0.5 + 500)
    WHEN ((sp.rows) > 10000000 AND (sp.rows) <= 100000000)
        THEN ((sp.rows) * 0.03 + 500)
	WHEN ((si.rows) > 100000000 AND (si.rows) <= 500000000)
            THEN ((si.rows) * 0.01 + 500)
	WHEN ((si.rows) > 500000000 AND (si.rows) <= 1000000000)
            THEN ((si.rows) * 0.005 + 500)
	WHEN ((si.rows) > 1000000000)
            THEN ((si.rows) * 0.003 + 500)
	END
OR (rows_sampled < rows/2 and ss.name NOT LIKE ''_WA_Sys%'')) -- Сделано для исправления проблем auto_update statistics. При auto_update statistics сбарсывается счётчик sp.modification_counter и сервер считает что статистика обновлена, но она может быть обновлена с очень плохим SAMPLE. В данном скрипте обрабатывается ситуация когда SAMPLE < 50%
AND sp.last_updated < getdate() - 1 -- Ограничиваем отбор статистикой обновляемой более деня назад
ORDER BY sp.last_updated DESC'
ELSE 
SET @query_dynamic = 'SELECT
    sch.name  AS ''Schema'',
    so.name as ''Table'',
    ss.name AS ''Statistic''
FROM sys.stats ss
JOIN sys.objects so ON ss.object_id = so.object_id
JOIN sys.schemas sch ON so.schema_id = sch.schema_id
OUTER APPLY sys.dm_db_stats_properties(so.object_id, ss.stats_id) AS sp
WHERE so.TYPE = ''U''
AND [rows] > 1000 
AND is_incremental = 0
AND (sp.modification_counter >
    CASE WHEN (sp.rows <= 5000000)
        THEN ((sp.rows) * 0.10 + 500)
    WHEN ((sp.rows) > 5000000 AND (sp.rows) <= 10000000)
        THEN ((sp.rows) * 0.5 + 500)
    WHEN ((sp.rows) > 10000000 AND (sp.rows) <= 100000000)
        THEN ((sp.rows) * 0.03 + 500)
	WHEN ((si.rows) > 100000000 AND (si.rows) <= 500000000)
            THEN ((si.rows) * 0.01 + 500)
	WHEN ((si.rows) > 500000000 AND (si.rows) <= 1000000000)
            THEN ((si.rows) * 0.005 + 500)
	WHEN ((si.rows) > 1000000000)
            THEN ((si.rows) * 0.003 + 500)
	END
OR (rows_sampled < rows/2 and ss.name NOT LIKE ''_WA_Sys%'')) -- Сделано для исправления проблем auto_update statistics. При auto_update statistics сбарсывается счётчик sp.modification_counter и сервер считает что статистика обновлена, но она может быть обновлена с очень плохим SAMPLE. В данном скрипте обрабатывается ситуация когда SAMPLE < 50%
AND sp.last_updated < getdate() - 1 -- Ограничиваем отбор статистикой обновляемой более деня назад
ORDER BY sp.last_updated DESC'

-- Если редакция сервера выше 2014, то добавяем проверку на инкрементальную статистику
IF CAST(SUBSTRING(CAST(SERVERPROPERTY ('productversion') as nvarchar(50)),1,2) as int) > 11
BEGIN
SET @query_dynamic_incremantal = 
'

DECLARE @partition_number nvarchar(250)

IF OBJECT_ID (N''tempdb..#TempTableIncremental'',''U'') IS NOT NULL
DROP TABLE #TempTableIncremental

CREATE TABLE #TempTableIncremental(
    schema_name nvarchar(250),
    table_name nvarchar(250),
    statistic_name nvarchar(250),
	partition_number nvarchar(250))

INSERT INTO #TempTableIncremental (
    schema_name, 
    table_name, 
    statistic_name,
	partition_number) 
SELECT
    sch.name  AS ''Schema'',
    so.name as ''Table'',
    ss.name AS ''Statistic'',
	CAST(si.partition_number as nvarchar(50))
FROM sys.stats ss
JOIN sys.objects so ON ss.object_id = so.object_id
JOIN sys.schemas sch ON so.schema_id = sch.schema_id
OUTER APPLY sys.dm_db_stats_properties(so.object_id, ss.stats_id) AS sp
CROSS APPLY sys.dm_db_incremental_stats_properties(so.object_id,ss.stats_id) as si
WHERE so.TYPE = ''U'' and is_incremental = 1
AND si.[rows] > 1000 
AND (si.modification_counter >
    CASE WHEN (si.rows <= 5000000)
        THEN ((si.rows) * 0.10 + 500)
    WHEN ((si.rows) > 5000000 AND (si.rows) <= 10000000)
        THEN ((si.rows) * 0.5 + 500)
    WHEN ((si.rows) > 10000000 AND (si.rows) <= 100000000)
        THEN ((si.rows) * 0.03 + 500)
	WHEN ((si.rows) > 100000000 AND (si.rows) <= 500000000)
            THEN ((si.rows) * 0.01 + 500)
	WHEN ((si.rows) > 500000000 AND (si.rows) <= 1000000000)
            THEN ((si.rows) * 0.005 + 500)
	WHEN ((si.rows) > 1000000000)
            THEN ((si.rows) * 0.003 + 500)
	END
OR (si.rows_sampled < si.rows/2 and ss.name NOT LIKE ''_WA_Sys%''))


DECLARE CursUpdateStatistic CURSOR FOR
SELECT * FROM #TempTableIncremental

OPEN CursUpdateStatistic

FETCH NEXT FROM CursUpdateStatistic INTO @schema,@table,@statistic,@partition_number

WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
        SET @sql= ''UPDATE STATISTICS [''+ @schema+''].['' + @table+ ''] ['' + @statistic +''] WITH resample on partitions ('' + @partition_number+ '')''

        exec(@sql)
		
		SET @statistics_incremental = ISNULL(@statistics_incremental,0) +1
		
        END TRY
        BEGIN CATCH
            SET @database_name = DB_NAME()
            INSERT INTO master.dbo.dbmaintenance 
            VALUES (@database_name,''Statistic - Номер ошибки ''+CAST(ERROR_NUMBER() as nvarchar(50)) + '', в строке '' + CAST(ERROR_LINE() as nvarchar(50)) +''. Сообщение об ошибке: '' + CAST(ERROR_MESSAGE() as nvarchar(400)),GETDATE())
        END CATCH        

        FETCH NEXT FROM CursUpdateStatistic INTO @schema,@table,@statistic,@partition_number
    END

CLOSE CursUpdateStatistic
DEALLOCATE CursUpdateStatistic

IF OBJECT_ID (N''tempdb..#TempTableIncremental'',''U'') IS NOT NULL
DROP TABLE #TempTableIncremental

'
END


-- Формируем скрипт выполнения
SET @query = '
SET LOCK_TIMEOUT 600000

USE ['+@Name+']

DECLARE @schema nvarchar(255), @table nvarchar(255), @statistic nvarchar(255), @sql  nvarchar(4000)
DECLARE @statistics int
DECLARE @statistics_incremental int
DECLARE @database_name nvarchar(255)

IF OBJECT_ID (N''tempdb..#TempTable'',''U'') IS NOT NULL
DROP TABLE #TempTable

CREATE TABLE #TempTable(
    schema_name nvarchar(250),
    table_name nvarchar(250),
    statistic_name nvarchar(250))

INSERT INTO #TempTable (
    schema_name, 
    table_name, 
    statistic_name) 
'+@query_dynamic+'

DECLARE CursUpdateStatistic CURSOR FOR
SELECT * FROM #TempTable

OPEN CursUpdateStatistic

FETCH NEXT FROM CursUpdateStatistic INTO @schema,@table,@statistic

WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
        SET @sql= ''UPDATE STATISTICS [''+ @schema+''].['' + @table+ ''] ['' + @statistic +''] WITH FULLSCAN''

        --print @sql+''
        --''
        exec(@sql)
		
		SET @statistics = ISNULL(@statistics,0) +1
		
        END TRY
        BEGIN CATCH
            SET @database_name = DB_NAME()
            INSERT INTO master.dbo.dbmaintenance 
            VALUES (@database_name,''Statistic - Номер ошибки ''+CAST(ERROR_NUMBER() as nvarchar(50)) + '', в строке '' + CAST(ERROR_LINE() as nvarchar(50)) +''. Сообщение об ошибке: '' + CAST(ERROR_MESSAGE() as nvarchar(400)),GETDATE())
        END CATCH        

        FETCH NEXT FROM CursUpdateStatistic INTO @schema,@table,@statistic
    END

CLOSE CursUpdateStatistic
DEALLOCATE CursUpdateStatistic

IF OBJECT_ID (N''tempdb..#TempTable'',''U'') IS NOT NULL
DROP TABLE #TempTable

'+@query_dynamic_incremantal
+'

print ''Statistics - ''+CAST(ISNULL(@statistics,0) as nvarchar(50))
print ''Statistics incremental - ''+CAST(ISNULL(@statistics_incremental,0) as nvarchar(50))

'

print @Name
exec (@query)

FETCH NEXT FROM dblist INTO @Name
    END
CLOSE dblist
DEALLOCATE dblist