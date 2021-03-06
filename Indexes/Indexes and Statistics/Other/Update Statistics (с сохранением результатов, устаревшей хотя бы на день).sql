-- Если используется версия ниже SQL Server R2(Sp2), то там нет DMV sys.dm_db_stats_properties

Use YourDB

DECLARE @schema nvarchar(255),
@table nvarchar(255),
@statistic nvarchar(255),
@query  nvarchar(4000),
@start_time DATETIME,
@end_time DATETIME,
@currentProcID INT,
@action varchar(4000)


 --Выбираем последний номер, и просто добавляем единичку
SELECT @currentProcID = ISNULL(MAX(proc_id), 0) + 1 FROM dba_tasks.dbo.Outdated_statistics

INSERT INTO dba_tasks.dbo.Outdated_statistics (
    proc_id,
    database_id,
    [object_id],
    table_name,
    statistic_name,
    [schema_name],
    [Last_updated],
    [Rows_modified_before])
SELECT
	@currentProcID,
	DB_ID(),
	so.object_id,
	so.name as 'Table',
	ss.name AS 'Statistic',
    sch.name  AS 'Schema',
    sp.last_updated,
    sp.modification_counter  
FROM sys.stats ss
JOIN sys.objects so ON ss.object_id = so.object_id
JOIN sys.schemas sch ON so.schema_id = sch.schema_id
OUTER APPLY sys.dm_db_stats_properties(so.object_id, ss.stats_id) AS sp
WHERE so.TYPE = 'U'
AND sp.modification_counter > 3000
AND sp.last_updated < getdate() - 1
ORDER BY sp.last_updated
DESC

DECLARE CursUpdateStatistic CURSOR FOR
SELECT [schema_name],[table_name],[statistic_name] FROM dba_tasks.dbo.Outdated_statistics WHERE proc_id = @currentProcID

OPEN CursUpdateStatistic

FETCH NEXT FROM CursUpdateStatistic INTO @schema,@table,@statistic

WHILE @@FETCH_STATUS = 0
	BEGIN
		
		BEGIN TRY
		
		SET @start_time = NULL
		SET @end_time = NULL
		SET @action = ''
		
		SET @query= 'UPDATE STATISTICS ['+ @schema+'].[' + @table+ '] [' + @statistic +'] WITH FULLSCAN'
		
		--Фиксируем время старта
		SET @start_time = GETDATE()

		exec(@query)		

		--И время завершения
		SET @end_time = GETDATE()
		SET @action = 'Success'
		
		-- Обновляем время завершения		
		UPDATE dba_tasks.dbo.Outdated_statistics
		SET
			start_time = @start_time,
			end_time = @end_time,
			[action] = @action
		WHERE	proc_id = @currentProcID
			AND [schema_name] = @schema
			AND [table_name] = @table
			AND [statistic_name] = @statistic
			
		END TRY
		
		BEGIN CATCH	
		
		SET @action = '***Filed*** ' + ERROR_MESSAGE()	
		
		UPDATE dba_tasks.dbo.Outdated_statistics
		SET
			start_time = @start_time,
			end_time = @end_time,
			[action] = @action
		WHERE	proc_id = @currentProcID
			AND [schema_name] = @schema
			AND [table_name] = @table
			AND [statistic_name] = @statistic		
		
		END CATCH
	
		FETCH NEXT FROM CursUpdateStatistic INTO @schema,@table,@statistic
	END
	
CLOSE CursUpdateStatistic
DEALLOCATE CursUpdateStatistic

UPDATE dba
SET
    dba.Rows_modified_after = sp.modification_counter
FROM sys.stats ss
JOIN sys.objects so ON ss.object_id = so.object_id
JOIN sys.schemas sch ON so.schema_id = sch.schema_id
INNER JOIN dba_tasks.dbo.Outdated_statistics dba ON dba.object_id = ss.object_id
OUTER APPLY sys.dm_db_stats_properties(so.object_id, ss.stats_id) AS sp
WHERE dba.proc_id = @currentProcID AND dba.object_id = ss.object_id