USE [master]
GO

/****** Object:  StoredProcedure [dbo].[sp_restore_from_mscrm_log]    Script Date: 20.01.2017 14:32:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- Не подходит для AlwaysON или Mirroring (история backup хранится на разных экземплярах)

CREATE PROCEDURE [dbo].[sp_restore_from_mscrm_log]
(
@date datetime, -- Скрипт старается найти backup, максимально подходящее под переданное время. Используют только FULL и DIFF backup
@dboriginal nvarchar(512), -- Оригинальное имя БД, backup которого необходимо восстановить
@dbdestination nvarchar(512), -- Имя БД в котрое нужно восстановить
@filesdestination nvarchar(512) = 'H:\MSSQL12.MSCRM\MSSQL\DATA\' -- Место восстановления
)
as

/*
	Для своей работы скрипт использует заранее созданный Linked Server - [MS-CLUSTER1-CRM\MSCRM]. С данного сервера скрипт получает список Backup нужной БД и куда он был сделан. Далее производить восстановление на последний DIFF, если последним был FULL, то восстанавливает только его. 
*/

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
DECLARE @current_backup_date datetime
DECLARE @query_color nvarchar(4000)
DECLARE @logical_files_names nvarchar(4000) -- данные о логических именах оригинальной БД и куда их следует восстановить на текущем сервере
DECLARE @difference_name nvarchar(50) -- для создания уникальности файла БД на файловой системе
SET @difference_name = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(19), GETDATE(), 120), ' ','_'),'-',''),':','') 
SET @logical_files_names = ''

DECLARE  @fileName nvarchar(800), @point nvarchar(800)

-- Получаем дату текущего восстановления
	  SELECT @current_backup_date = MAX(backup_finish_date)
	   FROM msdb.dbo.backupset bs 
	  INNER JOIN msdb.dbo.backupmediafamily bms ON bs.media_set_id=bms.media_set_id 
	  WHERE database_name = @dbdestination

-- Получаем названия и дату backup
SELECT TOP 1 @full=name,@full_date=backup_finish_date FROM [MS-CLUSTER1-CRM\MSCRM].msdb.dbo.backupset bs WHERE database_name = @dboriginal and type = 'D' AND backup_finish_date < @date ORDER BY backup_finish_date DESC
SELECT TOP 1 @diff=name,@diff_date=backup_finish_date FROM [MS-CLUSTER1-CRM\MSCRM].msdb.dbo.backupset bs WHERE database_name = @dboriginal and type = 'I' AND backup_finish_date < @date ORDER BY backup_finish_date DESC

-- Формируем местонахождение full backup
SELECT @full_physical = bms.physical_device_name FROM [MS-CLUSTER1-CRM\MSCRM].msdb.dbo.backupset bs
INNER JOIN [MS-CLUSTER1-CRM\MSCRM].msdb.dbo.backupmediafamily bms ON bs.media_set_id=bms.media_set_id WHERE bs.name = @full


-- Выполняем восстановление цепочки логов
IF @full_date < @diff_date 
BEGIN

DECLARE PointInTime CURSOR FOR
SELECT      
	  physical_device_name as fileName,CONVERT(VARCHAR(23), GETDATE(), 121) as point FROM [MS-CLUSTER1-CRM\MSCRM].msdb.dbo.backupset bs 
	  INNER JOIN [MS-CLUSTER1-CRM\MSCRM].msdb.dbo.backupmediafamily bms ON bs.media_set_id=bms.media_set_id 
	  WHERE backup_start_date > @diff_date AND database_name = @dboriginal AND [type] = 'L' AND backup_finish_date > ISNULL(@current_backup_date, @diff_date)
	  ORDER BY backup_finish_date ASC
	OPEN PointInTime
	FETCH NEXT FROM PointInTime INTO @fileName,@point
WHILE @@FETCH_STATUS = 0
    BEGIN

		exec('RESTORE LOG ['+@dbdestination+'] FROM DISK = '''+@fileName+''' WITH FILE=1, NORECOVERY, STOPAT = '''+@point+'''')	
		
		print 'RESTORE LOG ['+@dbdestination+'] FROM DISK = '''+@fileName+''' WITH FILE=1, NORECOVERY, STOPAT = '''+@point+''''

	FETCH NEXT FROM PointInTime INTO @fileName,@point
	END
CLOSE PointInTime
DEALLOCATE PointInTime	
	
END

ELSE
BEGIN

DECLARE PointInTime1 CURSOR FOR

	SELECT     
	  physical_device_name as fileName,CONVERT(VARCHAR(23), GETDATE(), 121) as point FROM [MS-CLUSTER1-CRM\MSCRM].msdb.dbo.backupset bs 
	  INNER JOIN [MS-CLUSTER1-CRM\MSCRM].msdb.dbo.backupmediafamily bms ON bs.media_set_id=bms.media_set_id 
	  WHERE backup_start_date > @full_date AND database_name = @dboriginal AND [type] = 'L' AND backup_finish_date > ISNULL(@current_backup_date,@full_date)
	  ORDER BY backup_finish_date ASC	
		OPEN PointInTime1
	FETCH NEXT FROM PointInTime1 INTO @fileName,@point
WHILE @@FETCH_STATUS = 0
    BEGIN

		exec('RESTORE LOG ['+@dbdestination+'] FROM DISK = '''+@fileName+''' WITH FILE=1, NORECOVERY, STOPAT = '''+@point+'''')	
		print 'RESTORE LOG ['+@dbdestination+'] FROM DISK = '''+@fileName+''' WITH FILE=1, NORECOVERY, STOPAT = '''+@point+''''

	FETCH NEXT FROM PointInTime1 INTO @fileName,@point
	END
CLOSE PointInTime1
DEALLOCATE PointInTime1

END

-- Производим перевод БД в доступное состояние
--exec('RESTORE DATABASE ['+@dbdestination+'] WITH RECOVERY')

-- Удаляем за собой временную таблицу
IF OBJECT_ID (N'tempdb..#backup','U') IS NOT NULL
DROP TABLE #backup



GO


