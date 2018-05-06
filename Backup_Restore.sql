-- Куда был сделан backup
	SELECT physical_device_name as pdn, * FROM msdb.dbo.backupset bs
	INNER JOIN .msdb.dbo.backupmediafamily bms ON bs.media_set_id=bms.media_set_id 


-- История Restore
	DECLARE @dbname sysname, @days int
	SET @dbname = NULL --substitute for whatever database name you want
	SET @days = -30 --previous number of days, script will default to 30
	SELECT
	 rsh.destination_database_name AS [Database],
	 rsh.user_name AS [Restored By],
	 CASE WHEN rsh.restore_type = 'D' THEN 'Database'
	  WHEN rsh.restore_type = 'F' THEN 'File'
	  WHEN rsh.restore_type = 'G' THEN 'Filegroup'
	  WHEN rsh.restore_type = 'I' THEN 'Differential'
	  WHEN rsh.restore_type = 'L' THEN 'Log'
	  WHEN rsh.restore_type = 'V' THEN 'Verifyonly'
	  WHEN rsh.restore_type = 'R' THEN 'Revert'
	  ELSE rsh.restore_type 
	 END AS [Restore Type],
	 rsh.restore_date AS [Restore Started],
	 bmf.physical_device_name AS [Restored From], 
	 rf.destination_phys_name AS [Restored To]
	FROM msdb.dbo.restorehistory rsh
	 INNER JOIN msdb.dbo.backupset bs ON rsh.backup_set_id = bs.backup_set_id
	 INNER JOIN msdb.dbo.restorefile rf ON rsh.restore_history_id = rf.restore_history_id
	 INNER JOIN msdb.dbo.backupmediafamily bmf ON bmf.media_set_id = bs.media_set_id
	WHERE rsh.restore_date >= DATEADD(dd, ISNULL(@days, -30), GETDATE()) --want to search for previous days
	AND destination_database_name = ISNULL(@dbname, destination_database_name) --if no dbname, then return all
	ORDER BY rsh.restore_history_id DESC
	GO
	
-- Замедление backup
	1. Resource Governor (MAX_IOPS_PER_VOLUME). Только с SQL Server 2016
	2. COMPRESS + CPU limit через Resource Governor (CAP_CPU_PERCENT)
	
-- Проверка backup/check restore
	- Although not required, verifying a backup is a useful practice. Verifying a backup checks that the backup is intact physically, to ensure that all the files in the backup are readable and can be restored, and that you can restore your backup in the event you need to use it. It is important to understand that verifying a backup does not verify the structure of the data on the backup. However, if the backup was created using WITH CHECKSUMS, verifying the backup using WITH CHECKSUMS can provide a good indication of the reliability of the data on the backup.
	- Restoring a database, does not guarantee that it can be recovered. Furthermore, a database recovered from a verified backup could have a problem with its data. This is because verifying a backup does not verify whether the structure of the data contained within the backup set is correct. For example, although the backup set may have been written correctly, a database integrity problem could exist within the database files that would comprise the backup set. However, if a backup was created with backup checksums, a backup that verifies successfully has a good chance of being reliable.
	
-- Восстановление на др версии
	1. Если проблемы с восстановлением с 2005 то нужно сначала восстановиться на 2008, потом дальше