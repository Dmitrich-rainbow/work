USE [master]
GO

 Object  StoredProcedure [dbo].[sp_restore_from_mscrm]    Script Date 20.01.2017 143232 
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- Не подходит для AlwaysON или Mirroring (история backup хранится на разных экземплярах)

CREATE PROCEDURE [dbo].[sp_restore_from_mscrm]
(
@date datetime, -- Скрипт старается найти backup, максимально подходящее под переданное время. Используют только FULL и DIFF backup
@dboriginal nvarchar(512), -- Оригинальное имя БД, backup которого необходимо восстановить
@dbdestination nvarchar(512), -- Имя БД в котрое нужно восстановить
@filesdestination nvarchar(512) = 'HMSSQL12.MSCRMMSSQLDATA' -- Место восстановления
)
as


	Для своей работы скрипт использует заранее созданный Linked Server - [MS-CLUSTER1-CRMMSCRM]. С данного сервера скрипт получает список Backup нужной БД и куда он был сделан. Далее производить восстановление на последний DIFF, если последним был FULL, то восстанавливает только его. 


-- Удаляем таблицу для сохранения цветов
IF OBJECT_ID (N'tempdb..#color','U') IS NOT NULL
DROP TABLE #color

-- Пересоздаём таблице цветов
CREATE TABLE #color (DataAreaId varchar(3),
BrushColor int,
HatchStyle int,
BrushStyle int,
OpacityState int,
Opacity int,
ShowDesktop int)

-- Создаём таблице для помещения в неё информации из backup
IF OBJECT_ID (N'tempdb..#backup','U') IS NULL
CREATE TABLE #backup (
      LogicalName VARCHAR(128) ,
      [PhysicalName] VARCHAR(128) ,
      [Type] VARCHAR ,
      [FileGroupName] VARCHAR(128) ,
      [Size] VARCHAR(128) ,
      [MaxSize] VARCHAR(128) ,
      [FileId] VARCHAR(128) ,
      [CreateLSN] VARCHAR(128) ,
      [DropLSN] VARCHAR(128) ,
      [UniqueId] VARCHAR(128) ,
      [ReadOnlyLSN] VARCHAR(128) ,
      [ReadWriteLSN] VARCHAR(128) ,
      [BackupSizeInBytes] VARCHAR(128) ,
      [SourceBlockSize] VARCHAR(128) ,
      [FileGroupId] VARCHAR(128) ,
      [LogGroupGUID] VARCHAR(128) ,
      [DifferentialBaseLSN] VARCHAR(128) ,
      [DifferentialBaseGUID] VARCHAR(128) ,
      [IsReadOnly] VARCHAR(128) ,
      [IsPresent] VARCHAR(128) ,
       TDE varbinary(32)
    )

-- Объявление переменных
DECLARE @query nvarchar(4000)
DECLARE @full nvarchar(512)
DECLARE @full_date datetime
DECLARE @full_physical nvarchar(512)
DECLARE @diff nvarchar(512)
DECLARE @diff_date datetime
DECLARE @diff_physical nvarchar(512)
DECLARE @query_color nvarchar(4000)
DECLARE @logical_files_names nvarchar(4000) -- данные о логических именах оригинальной БД и куда их следует восстановить на текущем сервере
DECLARE @difference_name nvarchar(50) -- для создания уникальности файла БД на файловой системе
SET @difference_name = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(19), GETDATE(), 120), ' ','_'),'-',''),'','') 
SET @logical_files_names = ''

-- Получаем названия и дату backup
SELECT TOP 1 @full=name,@full_date=backup_finish_date FROM [MS-CLUSTER1-CRMMSCRM].msdb.dbo.backupset bs WHERE database_name = @dboriginal and type = 'D' AND backup_finish_date  @date ORDER BY backup_finish_date DESC
SELECT TOP 1 @diff=name,@diff_date=backup_finish_date FROM [MS-CLUSTER1-CRMMSCRM].msdb.dbo.backupset bs WHERE database_name = @dboriginal and type = 'I' AND backup_finish_date  @date ORDER BY backup_finish_date DESC

-- Формируем местонахождение full backup
SELECT @full_physical = bms.physical_device_name FROM [MS-CLUSTER1-CRMMSCRM].msdb.dbo.backupset bs
INNER JOIN [MS-CLUSTER1-CRMMSCRM].msdb.dbo.backupmediafamily bms ON bs.media_set_id=bms.media_set_id WHERE bs.name = @full

-- Формирование имёт файлов восстановления
IF DB_ID(@dbdestination) IS NOT NULL
BEGIN

	DECLARE @NameC varchar(512), @TypeC nvarchar(10), @DestC varchar(512)
	DECLARE MyCursor CURSOR FOR
	SELECT name,type_desc, physical_name FROM sys.master_files WHERE DB_NAME(database_id) = @dbdestination
	OPEN MyCursor
		FETCH NEXT FROM MyCursor INTO @NameC,@TypeC,@DestC
	WHILE @@FETCH_STATUS = 0
		BEGIN

			IF @TypeC = 'ROWS'
			SET @logical_files_names = @logical_files_names + 'MOVE '''+@NameC+''' TO '''+@DestC+''','
			ELSE IF @TypeC = 'LOG'
			SET @logical_files_names = @logical_files_names + 'MOVE '''+@NameC+''' TO '''+@DestC+''','

		FETCH NEXT FROM MyCursor INTO @NameC,@TypeC,@DestC
		END
	CLOSE MyCursor
	DEALLOCATE MyCursor	

END
ELSE
BEGIN
	-- Получаем информацию о файле backup
	INSERT INTO #backup
	EXEC ('RESTORE FILELISTONLY  
	FROM DISK = '''+@full_physical+''' 
	WITH NOUNLOAD')

	-- Получаем названия логических имём файлов для Restore
	DECLARE @Name varchar(512), @Type nvarchar(10)
	DECLARE MyCursor CURSOR FOR
	SELECT LogicalName, [Type] FROM #backup
	OPEN MyCursor
		FETCH NEXT FROM MyCursor INTO @Name,@Type
	WHILE @@FETCH_STATUS = 0
		BEGIN

			IF @Type = 'D'
			SET @logical_files_names = @logical_files_names + 'MOVE '''+@Name+''' TO '''+@filesdestination+''+@dbdestination+'_'+@Name+'.mdf'','
			ELSE IF @Type = 'L'
			SET @logical_files_names = @logical_files_names + 'MOVE '''+@Name+''' TO '''+@filesdestination+''+@dbdestination+'_'+@Name+'.ldf'','

		FETCH NEXT FROM MyCursor INTO @Name,@Type
		END
	CLOSE MyCursor
	DEALLOCATE MyCursor
END

-- Убираем крайний символ
SET @logical_files_names =  left(@logical_files_names,len(@logical_files_names)-1)

-- Выпоняем обработку необходимого количество восстановлений
IF @full_date  @diff_date 
BEGIN

-- Формируем местонахождение diff backup. Подразумевается, что количество логических файлов и у FULL и у DIFF совпадают
SELECT @diff_physical = bms.physical_device_name FROM [MS-CLUSTER1-CRMMSCRM].msdb.dbo.backupset bs
INNER JOIN [MS-CLUSTER1-CRMMSCRM].msdb.dbo.backupmediafamily bms ON bs.media_set_id=bms.media_set_id WHERE bs.name  = @diff

SET @query = N'RESTORE DATABASE ['+@dbdestination+'] FROM DISK ='''+@full_physical+''' WITH NORECOVERY, REPLACE,
'+@logical_files_names+'

RESTORE DATABASE ['+@dbdestination+'] FROM DISK ='''+@diff_physical+''' WITH NORECOVERY, REPLACE,
'+@logical_files_names

IF DB_ID(@dbdestination) IS NOT NULL
SET @query='ALTER DATABASE ['+@dbdestination+'] SET SINGLE_USER WITH ROLLBACK IMMEDIATE

ALTER DATABASE ['+@dbdestination+'] SET RECOVERY SIMPLE

'+@query+'
ALTER DATABASE ['+@dbdestination+'] SET MULTI_USER'

END
ELSE
BEGIN

SET @query = N'RESTORE DATABASE ['+@dbdestination+'] FROM DISK ='''+@full_physical+''' WITH NORECOVERY, REPLACE,
'+@logical_files_names

IF DB_ID(@dbdestination) IS NOT NULL
SET @query='ALTER DATABASE ['+@dbdestination+'] SET SINGLE_USER WITH ROLLBACK IMMEDIATE

ALTER DATABASE ['+@dbdestination+']  SET RECOVERY SIMPLE

'+@query+'
ALTER DATABASE ['+@dbdestination+'] SET MULTI_USER'

END

-- Выполняем восстановление
exec (@query)
--print @query

-- Удаляем за собой временную таблицу
IF OBJECT_ID (N'tempdb..#backup','U') IS NOT NULL
DROP TABLE #backup

-- Возвращаем информацию от какого числа backup
	SELECT TOP 1 backup_finish_date as [backup от]
	FROM msdb.dbo.restorehistory rsh
	 INNER JOIN msdb.dbo.backupset bs ON rsh.backup_set_id = bs.backup_set_id
	 INNER JOIN msdb.dbo.restorefile rf ON rsh.restore_history_id = rf.restore_history_id
	 INNER JOIN msdb.dbo.backupmediafamily bmf ON bmf.media_set_id = bs.media_set_id
	WHERE destination_database_name = @dbdestination
	ORDER BY rsh.restore_history_id DESC

GO


