USE [msdb]
GO

-- Формируем таблицу для хранения ошибок выполнения
IF OBJECT_ID (N'master.dbo.dbmaintenance','U') IS NULL
CREATE TABLE master.dbo.dbmaintenance (dbname nvarchar(255) NULL, error_desc nvarchar(4000) NULL, [date] [datetime] NULL)

GO

-- Увеличиваем историю хранения о выполнении задания
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=10000, 
        @jobhistory_max_rows_per_job=1000
GO

-- Удаляем старыt job с таким же названием
IF EXISTS (SELECT * FROM msdb..sysjobs WHERE name = 'CHECKDB')
exec msdb..sp_delete_job @job_name = 'CHECKDB'

IF EXISTS (SELECT * FROM msdb..sysjobs WHERE name = 'Rebuild Indexes')
exec msdb..sp_delete_job @job_name = 'Rebuild Indexes'

IF EXISTS (SELECT * FROM msdb..sysjobs WHERE name = 'Update Statistics')
exec msdb..sp_delete_job @job_name = 'Update Statistics'

DECLARE @schedule_id uniqueidentifier

/****** Object:  Job [CHECKDB]    Script Date: 26.01.2018 14:53:12 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 26.01.2018 14:53:12 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'CHECKDB', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name='', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [checkdb]    Script Date: 26.01.2018 14:53:12 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'checkdb', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @Name varchar(255)
DECLARE Checkdb CURSOR FOR
	SELECT name FROM sys.databases WHERE name NOT IN (''tempdb'',''model'') and state_desc = ''ONLINE''
OPEN Checkdb
	FETCH NEXT FROM Checkdb INTO @Name
WHILE @@FETCH_STATUS = 0
    BEGIN
	
		BEGIN TRY

		print @Name

		exec (''DBCC CHECKDB(''''''+@Name+'''''') WITH NO_INFOMSGS'')	  

		END TRY
		
		BEGIN CATCH

			DECLARE @database_name nvarchar(255)
			SET @database_name = DB_NAME()

			INSERT INTO master.dbo.dbmaintenance 
			VALUES (@database_name,''CHECKDB - Номер ошибки ''+CAST(ERROR_NUMBER() as nvarchar(50)) + '', в строке '' + CAST(ERROR_LINE() as nvarchar(50)) +''. Сообщение об ошибке: '' + CAST(ERROR_MESSAGE() as nvarchar(400)),GETDATE())

		END CATCH

	FETCH NEXT FROM Checkdb INTO @Name
	END
CLOSE Checkdb
DEALLOCATE Checkdb', 
		@database_name=N'master', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'checkdb', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=2, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20160420, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959, 
		@schedule_uid=@schedule_id
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
USE [msdb]
GO

DECLARE @schedule_id uniqueidentifier

/****** Object:  Job [Rebuild Indexes]    Script Date: 05.02.2018 12:42:59 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 05.02.2018 12:42:59 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Rebuild Indexes', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'mssql-alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [rebuild]    Script Date: 05.02.2018 12:43:00 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'rebuild', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @Name varchar(100)
DECLARE @query varchar(8000)
DECLARE @dbname table (name nvarchar(255))
DECLARE @query_result table (name nvarchar(255))

-- Формируем таблицу 
INSERT INTO @dbname 
SELECT name FROM sys.databases WHERE name NOT IN (''tempdb'',''model'')

-- Отменяем обслуживание, если мы не на Primary
-- Для AlwaysOn (заходим в процерку только начиная с 2008 редакции)
IF (SELECT SUBSTRING(CAST(SERVERPROPERTY(''productversion'') as nvarchar(50)),1,CHARINDEX(''.'', CAST(SERVERPROPERTY(''productversion'') as nvarchar(50)))-1)) > 10
BEGIN
	
	-- Очищаем временную таблицу для начала работы с ней
	DELETE FROM @query_result

	-- Добавляем в таблицу признак Primary/Secondary
	INSERT INTO @query_result
	exec (''SELECT primary_replica FROM sys.dm_hadr_availability_group_states'')	
	
	-- Производим проверку Secondary or not
	IF (SELECT @@SERVERNAME) <> (SELECT name FROM @query_result)
	BEGIN
		
		-- Очищаем временную таблицу для начала работы с ней
		DELETE FROM @query_result

		-- Заносим значения БД, которые входят в AlwaysOn
		INSERT INTO @query_result
		exec (''SELECT name FROM sys.databases WHERE name NOT IN (''''tempdb'''') AND replica_id IS NOT NULL'')

		-- Так как мы на Secondary, то исключаем из обслуживания БД, которые входят в AlwaysOn
		DELETE FROM @dbname WHERE name in (SELECT name FROM @query_result)
	END
END

-- Для Mirroring
DELETE FROM @dbname WHERE name IN (SELECT name FROM sys.databases WHERE name NOT IN (''tempdb'',''model'') AND state_desc <> ''ONLINE'') 

-- Объявляем курсом для определения количества БД
DECLARE dblist CURSOR FOR
	SELECT name FROM @dbname
OPEN dblist
	FETCH NEXT FROM dblist INTO @Name
WHILE @@FETCH_STATUS = 0
    BEGIN

-- Формируем скрипт выполнения
SET @query = ''
SET LOCK_TIMEOUT 600000
SET QUOTED_IDENTIFIER ON

USE [''+@Name+'']

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
	''''[''''+sh.name+'''']'''', 
    ''''[''''+tbl.name+'''']'''', 
    ''''[''''+idx.name+'''']'''', 
    dm.avg_fragmentation_in_percent,
	partition_number,
	MAX (partition_number) OVER (PARTITION BY idx.name),
	ISNULL((SELECT COUNT(*) FROM sys.indexes idx1 WHERE idx1.[object_id] = idx.[object_id] AND idx1.type_desc LIKE ''''%COLUMNSTORE%''''),0) AS columnstore_exists
FROM sys.dm_db_index_physical_stats(@database_name, null, null, null, ''''LIMITED'''') dm
    INNER JOIN sys.tables tbl ON dm.object_id = tbl.object_id
    INNER JOIN sys.indexes idx ON dm.object_id = idx.object_id AND dm.index_id = idx.index_id
	INNER JOIN sys.schemas sh ON sh.schema_id = tbl.schema_id
WHERE page_count > 8
    AND avg_fragmentation_in_percent > 15
    AND dm.index_id > 0 
    AND idx.is_disabled = 0
    AND tbl.name not like ''''%$%''''
	AND idx.type_desc NOT LIKE ''''%COLUMNSTORE%''''
ORDER BY dm.avg_fragmentation_in_percent DESC

OPEN defragCur
FETCH NEXT FROM defragCur INTO @schemaName,@tableName, @indexName, @defrag,@partition_number,@max_partition_number,@columnstore_exists
WHILE @@FETCH_STATUS=0
BEGIN

	IF OBJECT_ID(@schemaName+''''.''''+@tableName,''''U'''') is not null
	BEGIN

		IF @partition_number = 1 AND @max_partition_number = 1
		SET @partition_number = ''''ALL''''

		SET @sql = N''''ALTER INDEX '''' + @indexName + '''' ON '''' + @schemaName+''''.''''+@tableName

		BEGIN TRY		

			IF (@defrag > 30 AND @columnstore_exists < 1) 
			BEGIN
				
				-- Выполняем онлайн перестроение если редакция Enterprise

				IF (SELECT @@VERSION) LIKE ''''%Enterprise Edition%''''
					SET @sql = @sql + N'''' REBUILD PARTITION = ''''+@partition_number+'''' WITH (ONLINE = ON)''''
				ELSE
					SET @sql = @sql + N'''' REORGANIZE PARTITION = ''''+@partition_number

			END
			ELSE 
			BEGIN
				SET @sql = @sql + N'''' REORGANIZE PARTITION = ''''+@partition_number
			END				
		
		--print @sql+''''
		--''''
	       
		exec (@sql) 

		SET @indexes_count = @indexes_count + 1

		END TRY
		BEGIN CATCH
			IF ERROR_NUMBER() = 2725
			BEGIN
				SET @sql = N''''ALTER INDEX '''' + @indexName + '''' ON '''' + @schemaName+''''.''''+@tableName+ N'''' REORGANIZE PARTITION = ''''+@partition_number		
		
			--print @sql+''''
		--''''
				exec (@sql) 
			END
			ELSE IF ERROR_NUMBER() IN (2552,1943)
			BEGIN
				SET @sql =  N''''ALTER INDEX '''' + @indexName + '''' ON '''' + @schemaName+''''.''''+@tableName+ N'''' SET (ALLOW_PAGE_LOCKS = ON )''''
				
				--print @sql
				exec (@sql) 
	
				SET @sql = N''''ALTER INDEX '''' + @indexName + '''' ON '''' + @schemaName+''''.''''+@tableName+ N'''' REORGANIZE PARTITION = ''''+@partition_number
				
				--print @sql
				exec (@sql) 		
				
			END
			ELSE
			BEGIN
				SET @database_name = DB_NAME()
				INSERT INTO master.dbo.dbmaintenance 
				VALUES (@database_name,''''INDEX - Номер ошибки ''''+CAST(ERROR_NUMBER() as nvarchar(50)) + '''', в строке '''' + CAST(ERROR_LINE() as nvarchar(50)) +''''. Сообщение об ошибке: '''' + CAST(ERROR_MESSAGE() as nvarchar(400)),GETDATE())
			END
		END CATCH
	END
    FETCH NEXT FROM defragCur INTO @schemaName,@tableName, @indexName, @defrag,@partition_number,@max_partition_number,@columnstore_exists
END
CLOSE defragCur
DEALLOCATE defragCur

-- Приступаем к обновлению колоночных индексов если версия SQL Server 2016+
IF (SELECT SUBSTRING(CAST(SERVERPROPERTY(''''productversion'''') as nvarchar(50)),1,CHARINDEX(''''.'''', CAST(SERVERPROPERTY(''''productversion'''') as nvarchar(50)))-1)) > 12
BEGIN

DECLARE @type int

SET @schemaName = ''''''''
SET @tableName = ''''''''
SET @indexName = ''''''''
SET @partition_number = ''''''''
SET @max_partition_number = ''''''''
SET @defrag = ''''''''
SET @sql = ''''''''


DECLARE defragCC CURSOR FOR

	SELECT ''''[''''+sh.name+'''']'''',   
		''''[''''+object_name(i.object_id)+'''']'''' AS TableName,   
		''''[''''+i.name+'''']'''' AS IndexName,   
	    MAX(100*(ISNULL(deleted_rows,0))/total_rows) AS ''''Fragmentation'''' , 
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

	IF OBJECT_ID(@schemaName+''''.''''+@tableName,''''U'''') is not null
	BEGIN
		BEGIN TRY				
				/* -- Отключил так как даже на 2016 появляются проблемы с ONLINE = ON
				IF @type = 6 and (SELECT @@VERSION) LIKE ''''%Enterprise Edition%''''
					IF @max_partition_number > 1
						SET @sql = ''''ALTER INDEX ''''+@indexName+'''' ON ''''+@schemaName+''''.''''+@tableName+'''' Rebuild PARTITION = ''''+@partition_number+'''' WITH (ONLINE = ON);''''
					ELSE
						SET @sql = ''''ALTER INDEX ''''+@indexName+'''' ON ''''+@schemaName+''''.''''+@tableName+'''' Rebuild PARTITION = ALL WITH (ONLINE = ON);''''
				ELSE
				BEGIN */
					IF @max_partition_number > 1
						BEGIN
							SET @sql = ''''ALTER INDEX ''''+@indexName+'''' ON ''''+@schemaName+''''.''''+@tableName+'''' REORGANIZE PARTITION = ''''+@partition_number+'''' WITH (COMPRESS_ALL_ROW_GROUPS = ON);
							
							ALTER INDEX ''''+@indexName+'''' ON ''''+@schemaName+''''.''''+@tableName+'''' REORGANIZE PARTITION = ''''+@partition_number

						END
					ELSE 
						BEGIN

							SET @sql = ''''ALTER INDEX ''''+@indexName+'''' ON ''''+@schemaName+''''.''''+@tableName+'''' REORGANIZE PARTITION = ALL WITH (COMPRESS_ALL_ROW_GROUPS = ON);
							
							ALTER INDEX ''''+@indexName+'''' ON ''''+@schemaName+''''.''''+@tableName+'''' REORGANIZE PARTITION = ALL''''

						END
				--END

				--print @sql
				exec (@sql)
				
				SET @columnstore_indexes_count = @columnstore_indexes_count +1 

		END TRY
		BEGIN CATCH

				SET @database_name = DB_NAME()
				INSERT INTO master.dbo.dbmaintenance 
				VALUES (@database_name,''''INDEX - Номер ошибки ''''+CAST(ERROR_NUMBER() as nvarchar(50)) + '''', в строке '''' + CAST(ERROR_LINE() as nvarchar(50)) +''''. Сообщение об ошибке: '''' + CAST(ERROR_MESSAGE() as nvarchar(400)),GETDATE())

		END CATCH
	END
    FETCH NEXT FROM defragCC INTO @schemaName,@tableName, @indexName, @defrag,@partition_number,@max_partition_number,@type
END
CLOSE defragCC
DEALLOCATE defragCC

END

print ''''Indexes done - ''''+ CAST(@indexes_count as nvarchar(50))
print ''''Columnstore Indexes done - ''''+ CAST(@columnstore_indexes_count as nvarchar(50)) 

''

print @Name

exec (@query)

FETCH NEXT FROM dblist INTO @Name
	END
CLOSE dblist
DEALLOCATE dblist
GO
exec msdb..sp_start_job @job_name = ''Update Statistics''', 
		@database_name=N'master', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'indexes', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20160422, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959, 
		@schedule_uid=@schedule_id
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO




DECLARE @schedule_id uniqueidentifier
/****** Object:  Job [Update Statistics]    Script Date: 26.01.2018 14:53:42 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 26.01.2018 14:53:42 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Update Statistics', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name='', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [statistics]    Script Date: 26.01.2018 14:53:42 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'statistics', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Объявляем объекты
DECLARE @Name varchar(100)
DECLARE @query nvarchar(4000)
DECLARE @dbname table (name nvarchar(255))
DECLARE @query_dynamic nvarchar(4000)
DECLARE @query_result table (name nvarchar(255))

-- Формируем таблицу 
INSERT INTO @dbname 
SELECT name FROM sys.databases WHERE name NOT IN (''tempdb'',''model'')

-- Отменяем обслуживание, если мы не на Primary
-- Для AlwaysOn (заходим в процерку только начиная с 2008 редакции)
IF (SELECT SUBSTRING(CAST(SERVERPROPERTY(''productversion'') as nvarchar(50)),1,CHARINDEX(''.'', CAST(SERVERPROPERTY(''productversion'') as nvarchar(50)))-1)) > 10
BEGIN
	
	-- Очищаем временную таблицу для начала работы с ней
	DELETE FROM @query_result

	-- Добавляем в таблицу признак Primary/Secondary
	INSERT INTO @query_result
	exec (''SELECT primary_replica FROM sys.dm_hadr_availability_group_states'')	
	
	-- Производим проверку Secondary or not
	IF (SELECT @@SERVERNAME) <> (SELECT name FROM @query_result)
	BEGIN
		
		-- Очищаем временную таблицу для начала работы с ней
		DELETE FROM @query_result

		-- Заносим значения БД, которые входят в AlwaysOn
		INSERT INTO @query_result
		exec (''SELECT name FROM sys.databases WHERE name NOT IN (''''tempdb'''') AND replica_id IS NOT NULL'')

		-- Так как мы на Secondary, то исключаем из обслуживания БД, которые входят в AlwaysOn
		DELETE FROM @dbname WHERE name in (SELECT name FROM @query_result)
	END
END

-- Для Mirroring
DELETE FROM @dbname WHERE name IN (SELECT name FROM sys.databases WHERE name NOT IN (''tempdb'',''model'') AND state_desc <> ''ONLINE'') 

-- Объявляем курсом для определения количества БД
DECLARE dblist CURSOR FOR
	SELECT * FROM @dbname
OPEN dblist
	FETCH NEXT FROM dblist INTO @Name
WHILE @@FETCH_STATUS = 0
    BEGIN

-- Если редакция сервера до 2008 SP2, то применяем старый механизм сбора статистики
IF (SELECT SUBSTRING(CAST(SERVERPROPERTY(''productversion'') as nvarchar(50)),1,CHARINDEX(''.'', CAST(SERVERPROPERTY(''productversion'') as nvarchar(50)))-1)) < 10
OR ((SELECT @@VERSION) like ''%SQL Server 2008%'' AND (SELECT SERVERPROPERTY(''ProductLevel'')) not in (''SP2'',''SP3''))
SET @query_dynamic = ''select DISTINCT SCHEMA_NAME(uid) as gerg, 
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
		WHEN ((si.rows) > 100000000)
			THEN ((si.rows) * 0.01 + 500)
		END
		AND i.name not like ''''sys%''''
		AND object_name(i.id) not like ''''sys%''''
		AND STATS_DATE(i.id, i.indid) < GetDATE()-1''
else
SET @query_dynamic = ''SELECT
    sch.name  AS ''''Schema'''',
    so.name as ''''Table'''',
    ss.name AS ''''Statistic''''
FROM sys.stats ss
JOIN sys.objects so ON ss.object_id = so.object_id
JOIN sys.schemas sch ON so.schema_id = sch.schema_id
OUTER APPLY sys.dm_db_stats_properties(so.object_id, ss.stats_id) AS sp
WHERE so.TYPE = ''''U''''
AND [rows] > 1000 
AND (sp.modification_counter >
    CASE WHEN (sp.rows <= 5000000)
		THEN ((sp.rows) * 0.10 + 500)
	WHEN ((sp.rows) > 5000000 AND (sp.rows) <= 10000000)
		THEN ((sp.rows) * 0.5 + 500)
	WHEN ((sp.rows) > 10000000 AND (sp.rows) <= 100000000)
		THEN ((sp.rows) * 0.03 + 500)
	WHEN ((sp.rows) > 100000000)
		THEN ((sp.rows) * 0.01 + 500) END
OR (rows_sampled < rows/2 and ss.name NOT LIKE ''''_WA_Sys%''''))
ORDER BY sp.last_updated DESC''

-- Формируем скрипт выполнения
SET @query = ''
SET LOCK_TIMEOUT 600000

USE [''+@Name+'']

DECLARE @schema nvarchar(255), @table nvarchar(255), @statistic nvarchar(255), @sql  nvarchar(4000)
DECLARE @database_name nvarchar(255)

IF OBJECT_ID (N''''tempdb..#TempTable'''',''''U'''') IS NOT NULL
DROP TABLE #TempTable

CREATE TABLE #TempTable(
	schema_name nvarchar(250),
	table_name nvarchar(250),
	statistic_name nvarchar(250))

INSERT INTO #TempTable (
    schema_name, 
    table_name, 
    statistic_name) 
''+@query_dynamic+''

DECLARE CursUpdateStatistic CURSOR FOR
SELECT * FROM #TempTable

OPEN CursUpdateStatistic

FETCH NEXT FROM CursUpdateStatistic INTO @schema,@table,@statistic

WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRY
		SET @sql= ''''UPDATE STATISTICS [''''+ @schema+''''].['''' + @table+ ''''] ['''' + @statistic +''''] WITH FULLSCAN''''
		
		print @sql+''''
		''''
		exec(@sql)
		END TRY
		BEGIN CATCH
			SET @database_name = DB_NAME()
			INSERT INTO master.dbo.dbmaintenance 
			VALUES (@database_name,''''Statistic - Номер ошибки ''''+CAST(ERROR_NUMBER() as nvarchar(50)) + '''', в строке '''' + CAST(ERROR_LINE() as nvarchar(50)) +''''. Сообщение об ошибке: '''' + CAST(ERROR_MESSAGE() as nvarchar(400)),GETDATE())
		END CATCH		
	
		FETCH NEXT FROM CursUpdateStatistic INTO @schema,@table,@statistic
	END
	
CLOSE CursUpdateStatistic
DEALLOCATE CursUpdateStatistic

IF OBJECT_ID (N''''tempdb..#TempTable'''',''''U'''') IS NOT NULL
DROP TABLE #TempTable
''

print @Name
exec (@query)

FETCH NEXT FROM dblist INTO @Name
	END
CLOSE dblist
DEALLOCATE dblist', 
		@database_name=N'master', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'statistics', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=16, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20160422, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959, 
		@schedule_uid=@schedule_id
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



