USE [msdb]
GO

/****** Object:  Job [Maintenance. Update Statistics (dm 1st thread)]    Script Date: 05.03.2018 20:04:13 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 05.03.2018 20:04:14 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Maintenance. Update Statistics (dm 1st thread)', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'В скрипт добалена логика брать задания в работу только с 02:00 до 07:00', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [statistics]    Script Date: 05.03.2018 20:04:14 ******/
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
SELECT name FROM sys.databases WHERE name IN (''dm'')

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
SET @query_dynamic = ''SELECT [Schema],[Table],[Statistic] FROM (SELECT
    sch.name  AS ''''Schema'''',
    so.name as ''''Table'''',
    ss.name AS ''''Statistic'''',
	NTILE(2) OVER (ORDER BY so.name) AS ord,
	sp.last_updated
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
) AS stat
WHERE ord = 1
ORDER BY stat.last_updated DESC''

-- Формируем скрипт выполнения
SET @query = ''
SET LOCK_TIMEOUT 1200000

USE [''+@Name+'']

DECLARE @schema nvarchar(255), @table nvarchar(255), @statistic nvarchar(255), @sql  nvarchar(4000), @count int
DECLARE @database_name nvarchar(255)

SET @count = 0

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

		IF (DATEPART(hh,GETDATE())) < 7
		BEGIN 

		BEGIN TRY
		SET @sql= ''''UPDATE STATISTICS [''''+ @schema+''''].['''' + @table+ ''''] ['''' + @statistic +''''] WITH FULLSCAN''''
		
		exec(@sql)

		SET @count = @count + 1

		END TRY
		BEGIN CATCH
			SET @database_name = DB_NAME()
			INSERT INTO master.dbo.dbmaintenance 
			VALUES (@database_name,''''Statistic - Номер ошибки ''''+CAST(ERROR_NUMBER() as nvarchar(50)) + '''', в строке '''' + CAST(ERROR_LINE() as nvarchar(50)) +''''. Сообщение об ошибке: '''' + CAST(ERROR_MESSAGE() as nvarchar(400)),GETDATE())
		END CATCH

		END		
	
		FETCH NEXT FROM CursUpdateStatistic INTO @schema,@table,@statistic
	END
	
CLOSE CursUpdateStatistic
DEALLOCATE CursUpdateStatistic

IF OBJECT_ID (N''''tempdb..#TempTable'''',''''U'''') IS NOT NULL
DROP TABLE #TempTable

print ''''Statistics - ''''  + CAST(@count as nvarchar(50))
''

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
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'dm statistics', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=106, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180126, 
		@active_end_date=99991231, 
		@active_start_time=20000, 
		@active_end_time=235959, 
		@schedule_uid=N'e8a96243-2234-4a42-9b66-cbe6d65eb0a5'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


