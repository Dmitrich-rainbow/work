-- Зеркалирование/Mirroring
	- Работает только в FULL модели восстановления
	- На сервере назначения лог файл весит мало
	- Между Основным и зеркальным сервером устанавливается быстрый канал связи через tcpip
	- Перекачиваются транзакции
	- Быстрее обычной репликации и кластера
	- База на Mirror находится в No Recovery/Restoring
	- Не копирует начальное состояние базы
	- Немного нагружает principal server
	- Если зеркалирование приостановлено, то невозможно урезать файл лога
	- Если авария была не так долго, то сервер сможет восстановить сломанную базу в Mirror с помощью буфера.
	  Этот буфер контролируется хранимыми процедурами и в базе мастер
		- Режимы:
			1. Синхронный (Сначала транзакция фиксируется на Mirror, потом на основном)
			2. Асинхронный (Сначала на основном, потом на Mirror). Поддерживается только в Enterprise
			3. Синхронный со свидетелем
				- Появляется 3 сервер (Witness), который пингует основной сервер и если основной умер, то он Mirror
				приказывает влючаться. Только пинг основного и передачу с основного на Mirror надо вешать
				на разные свитчи, иначе при аварии 3 сервер подумает что основной сломался
				- На стороне пользователя делается SQL Native Client, который знает где основной сервер и где
				есть Mirror (с помощью коннекшен стринг) и если основной не отвечает, то он пересылает команду
				на Mirror (указывается в настройках SQL Native Client - Failover Partner)
				- После возврата сервера в боевой режим, основной станет Mirror
		- Установка
			1. На другом сервере восстановить последний backup текущей базы в режиме NORECOVERY
				- Иногда требуется восстановить log, даже если был сделан только что FULL
			2. В настройках базы Principal - Mirroring -> Configure Security
			3. Настраиваем с Witness или без
			4. Запускаем
		- Ручное переключение
			- В разделе Mirroring > Failover
		- Плюсы:
			1. Автоматически решает все 3 задача
			2. Переключение происходит мгновенно
			3. Недорогое решение
		- Минусы
			1. Зеркало может быть только 1
			
	-- Оптимизация
		- Чтобы не нагружать Зеркалирование перестроение индексов, надо переключить режим на High-Perfomance на время перестроения индексов
		- Приостановить зеркалирование на момент важных команд, чтобы они прошли быстрее. При это mirror server переходит в SUSPENDED
	
	-- Мониторинг
		- Вы можете наблюдать за очередями SEND и REDO, установив уведомления с помощью Database Mirroring Monitor в SQL Server Management Studio. Также вы можете наблюдать за ними напрямую, используя perfmon-счетчики объекта Database Mirroring — Log Send Queue KB и Redo Queue KB.
		-   USE msdb;
			EXEC sp_dbmmonitorresults AdventureWorks2012, 2, 0;
			
			- Значение второго параметра:
				Указывает количество возвращенных строк:
				0 = последняя строка
				1 = строки за последние два часа
				2 = строки за последние четыре часа
				3 = строки за последние восемь часов
				4 = строки за последний день
				5 = строки за последние два дня
				6 = последние 100 строк
				7 = последние 500 строк
				8 = последние 1 000 строк
				9 = последние 1 000 000 строк
				
		- На каких БД включено зеркалирование
			SELECT * FROM sys.database_mirroring
			
		- Информация о wintess
			sys.database_mirroring_witnesses
			
		- Открытые подключения
			sys.dm_db_mirroring_connections
			
		- Returns the current update period.
			- Returns the current update period, that is, the number of minutes between updates of database mirroring status table. This value ranges from 1 to 120 minutes.
			sp_dbmmonitorhelpmonitoring
			
		- SELECT * FROM sys.dm_db_mirroring_auto_page_repair
		
	-- Терминалогия
		- High-performance mode
			The database mirroring session operates asynchronously and uses only the principal server and mirror server. The only form of role switching is forced service (with possible data loss).
		- High-safety mode
			The database mirroring session operates synchronously and, optionally, uses a witness, as well as the principal server and mirror server.
		- redo queue
			Received transaction log records that are waiting on the disk of a mirror server.
		- send queue
			Unsent transaction log records that have accumulated on the log disk of the principal server.
			
-- Особенности/ограничения
	- Можно использовать для Wintess - Express Edition
	- Witness не может быть на другой версии SQL Server (2008 и 2005)
	- Principal and Mirror сервера должны иметь одну редакцию и SP, битность не имеет значение даже для Witness
	- Note that you cannot mirror a database that contains FILESTREAM data, and mirroring is not appropriate if you need multiple databases to failover simultaneously, or if you use cross-database transactions or distributed transactions. 
	
-- Witness
	- Создан для голосования (quorum)
	- В себе хранит endpont и всё
	
-- Alerts
	USE [msdb]
	GO
	EXEC msdb.dbo.sp_add_alert @name=N'Database Mirroring Change State', 
			@message_id=0, 
			@severity=0, 
			@enabled=1, 
			@delay_between_responses=60, 
			@include_event_description_in=0, 
			@database_name=N'', 
			@notification_message=N'', 
			@event_description_keyword=N'', 
			@performance_condition=N'', 
			@wmi_namespace=N'\\.\root\Microsoft\SqlServer\ServerEvents\MSSQLSERVER', 
			@wmi_query=N'SELECT * FROM DATABASE_MIRRORING_STATE_CHANGE', 
			@job_id=N'00000000-0000-0000-0000-000000000000'
	GO
	
-- Отключить БД от Mirroring
	ALTER DATABASE [KG-Digispot] SET PARTNER OFF  
	- Если не получается, то выключать сиквел и удалять файлы под БД
	
	
-- Ошибки
	-- https://blogs.msdn.microsoft.com/docast/2015/07/30/database-mirroring-configuration-failure-scenarios/

	-- Mirroring не сможет добавить зеркало или свидетеля если разное время на серверах
	
	-- ОШибки, связанные с шифрованием. 
		SELECT
		name,
		role_desc AS Role,
		state_desc AS State,
		connection_auth_desc AS ConnAuth,
		encryption_algorithm_desc AS Algorithm -- используется ли шифрование или нет
		FROM sys.database_mirroring_endpoints;

		DROP ENDPOINT Mirroring;  -- удалить ENDPOINT
		
		Grant connect on ENDPOINT::Mirroring to [Node\SQLServiceAccount]
		
	-- Witness
		Может потребоваться руками создать контрольную точку и дать права на неё
		
		CREATE ENDPOINT Mirroring 
			STATE = STARTED  
			AS TCP ( LISTENER_PORT = 5022 )  
			FOR DATABASE_MIRRORING (  
			   AUTHENTICATION = WINDOWS NEGOTIATE,  
		 
				ENCRYPTION = SUPPORTED ALGORITHM RC4,

			   ROLE=WITNESS );  
		GO  
				Grant connect on ENDPOINT::Mirroring to [MSK-RIAN\Администраторы MSSQL]
				
	-- IOPS
		Due to failover optimization of SQL Server, certain workloads can generate greater I/O load on the mirror than on the principal. This functionality can result in higher IOPS on the secondary instance. We therefore recommend that you consider the maximum IOPS needs of both the primary and secondary when provisioning the storage type and IOPS of your RDS DB instance.
