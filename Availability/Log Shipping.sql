-- Log shipping (http://technet.microsoft.com/ru-ru/library/ms190640.aspx#Prerequisites)
	- Таблицы доставки журналов (http://technet.microsoft.com/ru-ru/library/ms175106(v=sql.105).aspx)
	- Чтобы не нарушить Log Shipping надо использовать параметр COPY ONLY
	- Медленная, неторопливая транзакционная репликация, с помощью INC backup, который поднимается на подписчике
	- База на сервере назначения всегда в No Recovery/StandBy
	- База данных-получатель должна быть инициализирована и восстановлена из полной резервной копии базы данных-источника. Восстановление может быть завершено с помощью параметра NORECOVERY или STANDBY. Это можно сделать вручную или через среду Среда SQL Server Management Studio.
	- Технически это 3 Джоба:
		1. LSBackup (Основной сервер. Делаем INC backup)
		2. LSCopy (Сервер назначения. Смотрит появились ли новые файлы и копирует их)
		3. LSRestore (Сервер назначения. Восстанавливает все скопированные файлы)
		-- Плюсы:
			1. Простая
			2. Можно настроить чтобы на сервере назначения бэкап восстановился не сразу
			3. Несколько резервных серверов
			4. Можно поставить задержку
			5. Возможность использования резервного сервера для отчетов
		-- Минусы
			1. Не моментальная/медленная
			2. Многоходовое решение задачи № 2
			3. Не решает задачу 3
			4. Занимает дополнительное место для backup log и при копировании данных логов на сервере назначения
			5. Не даёт возможность снимать backup log, разве что COPY_ONLY
			6. Нагрузка от обслуживания БД попадает в лог
			7. Даёт удалить БД, даже если она вовлечена в LS, необходимо в ручную потом чистить все задания
	-- Как работает:
		1. Создаём базу
		2. Создаём шару, через которую всё это будет передаваться
		3. В свойствах нужной базы > Transaction Log Shipping > кнопка Backup Settings (1 Джоб) > Secondary Databases
		  (резервные сервера). На второй закладке указать куда будут копироваться файлы с основного сервера >
		  на 3 вкладке третий джоб. Там можно указать, выбрасывать ли пользователей, когда делается бэкап или
		  нет ("disconnect users..."), но только если включён Standly mode(указывающий будем ли использовать второй
		  сервер для отчётов)
	-- Действия при аварии
		1. Заблокировать все 3 джоба (LS Backup, LS Copy, LS Restore) + 2 Job Alerts
		2. Снять последний, инкрементальный backup с параметром WITH NO_TRUNCATE
		3. Докопировать все backup (файлы, которыми обменивается log shipping) + хвостовой backup
		4. Восстановить всё то, что не успел восстановить с WITH RECOVERY
		
	-- Особенности
		1. Можно снимать FULL и DIFF backup, они не влияют на LSN. Log backup снимать нельзя
		2. Получается количество backup логов будет 1+количество реплик, так как каждый backup хранится ещё и локально, но можно указать не локальный диск, а сетевой, тот где лежат эти копии, тогда копирования не будет.
		3. Чтобы произвести отложенную настройку необходимо:
			- Full backup
			- После чего все backup лог необходимо уже сохранять,а ещё лучше не снимать до момента первичной синхронизации, тогда сервер сделает backup log и передаст его на реплику
			- Resrote на реплике с опцией WITH NORECOVERY
			- Выполнить первичную настрокуй		
		4. Memory required for Log shipping file copy depending on the size of log backups (if LS is configured) +
		5. Название файла пормируется по UTC+0
	-- Модель восстановления/Recovery model
		- Работает как в Full так в Bulk-logged Recovery Model
	-- Log Shipping Monitor
		-- TABLES
			log_shipping_monitor_alert - alert job ID.
			log_shipping_monitor_error_detail -	Stores error details for log shipping jobs. You can query this table see the errors for an agent session. Optionally, you can sort the errors by the date and time at which each was logged. Each error is logged as a sequence of exceptions, and multiple errors (sequences) can per agent session.
			log_shipping_monitor_history_detail - Contains history details for log shipping agents. You can query this table to see the history detail for an agent session.
			log_shipping_monitor_primary - Stores one monitor record for the primary database in each log shipping configuration, including information about the last backup file and last restored file that is useful for monitoring. Позволяет посмотреть все детали log shipping`а
			log_shipping_monitor_secondary - Stores one monitor record for each secondary database, including information about the last backup file and last restored file that is useful for monitoring.
		-- Процедуры
			sp_help_log_shipping_monitor
			sp_help_log_shipping_monitor_primary - Returns monitor records for the specified primary database from the log_shipping_monitor_primary table (Monitor server or primary server)
			sp_help_log_shipping_monitor_secondary - Returns monitor records for the specified secondary database from the log_shipping_monitor_secondary table (Monitor server or secondary server)
			sp_help_log_shipping_alert_job - Returns the job ID of the alert job (Monitor server, or primary or secondary server if no monitor is defined)
			sp_help_log_shipping_primary_database - Retrieves primary database settings and displays the values from the log_shipping_primary_databases and log_shipping_monitor_primary tables (Primary server)
			sp_help_log_shipping_primary_secondary - Retrieves secondary database names for a primary database (Primary server)
			sp_help_log_shipping_secondary_database - Retrieves secondary-database settings from the log_shipping_seconda, log_shipping_secondary_databases and log_shipping_monitor_secondary tables (Secondary server)
			sp_help_log_shipping_secondary_primary - This stored procedure retrieves the settings for a given primary database on the secondary server (Secondary server)		
			sp_delete_log_shipping_secondary_database - Удалить БД со вторичной реплики
			
		-- Запрос (не забываем указать БД)
			-- Assign the database name to variable below
			DECLARE @db_name VARCHAR(100)
			SELECT @db_name = 'RSNewsDb'
			-- query
			SELECT TOP (30) s.database_name
			,m.physical_device_name
			,CAST(CAST(s.backup_size / 1000000 AS INT) AS VARCHAR(14)) + ' ' + 'MB' AS bkSize
			,CAST(DATEDIFF(second, s.backup_start_date, s.backup_finish_date) AS VARCHAR(4)) + ' ' + 'Seconds' TimeTaken
			,s.backup_start_date
			,CAST(s.first_lsn AS VARCHAR(50)) AS first_lsn
			,CAST(s.last_lsn AS VARCHAR(50)) AS last_lsn
			,CASE s.[type] WHEN 'D'
			THEN 'Full'
			WHEN 'I'
			THEN 'Differential'
			WHEN 'L'
			THEN 'Transaction Log'
			END AS BackupType
			,s.server_name
			,s.recovery_model
			FROM msdb.dbo.backupset s
			INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
			WHERE s.database_name = @db_name
			ORDER BY backup_start_date DESC
			,backup_finish_date
			
	-- Ускорение
		- В момент восстановления выключаем STANDBY, потом включаем. Для этого надо:
			- Перед заданием restore
			DECLARE @LS_Add_RetCode2 AS int
			EXEC @LS_Add_RetCode2 = master.dbo.sp_change_log_shipping_secondary_database
			@secondary_database = N'<secondary database name>'
			,@disconnect_users = 0
			,@restore_mode = 0
			SELECT @LS_Add_RetCode2
			
			- После
			EXEC @LS_Add_RetCode2 = master.dbo.sp_change_log_shipping_secondary_database
			@secondary_database = N'<secondary database name>'
			,@disconnect_users = 1
			,@restore_mode = 1			
			
-- Минусы
	1. Если на основной БД включена репликация, то её видимость придёт и на копию, удалить видимость можно вместе с удалением БД (SQL Server 2008)