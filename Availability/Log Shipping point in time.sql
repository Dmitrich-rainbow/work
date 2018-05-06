ALTER PROC rt_rsnews_db1_logshipping_point_in_time_restore
(@db_name VARCHAR(100), @point_in_time datetime, @second_restore bit = 0)

AS

-- Работает исключительно на проекте rsnews-db1, с учётом того, что интервал backup log 15 минут
-- Если данный скрипт будет использоваться повторно до автоматического Restore, тогда нужно будет взять ещё 1 предыдущий backup, так как он ранее был восстановлен не полностью
-- @second_restore указать = 1 если это повторный вызов скрипта

-- Объявляем переменные
DECLARE @date datetime
DECLARE @second_restore_time int

-- Проверка на повторное восстановление (использование скрипта)
IF @second_restore <> 0
	SET @second_restore_time = -15
ELSE 
	SET @second_restore_time = 0

-- Получаем время последнего восстановления БД
SELECT TOP 1 @date = backup_start_date
FROM msdb.dbo.backupset s
INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
WHERE s.database_name = @db_name
ORDER BY backup_finish_date DESC

-- Получаем список файлов backup, которые необходимо восстановить и выполняем восстановление
DECLARE  @fileName nvarchar(800), @point nvarchar(800)
DECLARE PointInTime CURSOR FOR
SELECT     
	  REVERSE(SUBSTRING(REVERSE(physical_device_name),0,CHARINDEX('\',REVERSE(physical_device_name)))) as fileName,CONVERT(VARCHAR(23), @point_in_time, 121) as point
FROM 
(
SELECT * FROM [MSCL4-NODE1].msdb.dbo.backupset bs
UNION 
SELECT * FROM [MSCL4-NODE2].msdb.dbo.backupset bs2
) as bs
INNER JOIN 
(SELECT * FROM [MSCL4-NODE1].msdb.dbo.backupmediafamily bs
UNION 
SELECT * FROM [MSCL4-NODE2].msdb.dbo.backupmediafamily bs2
) as bms
ON bs.media_set_id = bms.media_set_id
WHERE backup_start_date > DATEADD(mi,@second_restore_time,@date) AND backup_finish_date < DATEADD(mi,15,@point_in_time) AND database_name = @db_name
ORDER BY backup_start_date ASC
OPEN PointInTime
	FETCH NEXT FROM PointInTime INTO @fileName,@point
WHILE @@FETCH_STATUS = 0
    BEGIN

	--print 'RESTORE LOG ['+@db_name+'] FROM DISK = ''D:\Backup\'+@fileName+''' WITH FILE=1, NORECOVERY, STOPAT = '''+@point+''''
		exec('RESTORE LOG ['+@db_name+'] FROM DISK = ''D:\Backup\'+@fileName+''' WITH FILE=1, NORECOVERY, STOPAT = '''+@point+'''')	

	FETCH NEXT FROM PointInTime INTO @fileName,@point
	END
CLOSE PointInTime
DEALLOCATE PointInTime