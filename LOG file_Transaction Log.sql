-- Основное
	- Нет смысла создавать несколько файлов журнала, только если для отказоустойчивости
	- Запись в журнал, как и запись на диски, так же происходит через кэш
	- Если более старая транзакция активна, то скорее всего это репликация и тд
	- Записи журнала для изменения данных содержат либо выполненную логическую операцию, либо исходный и результирующий образ измененных данных. Исходный образ записи — это копия данных до выполнения операции, а результирующий образ — копия данных после ее выполнения.
	- Действия, которые необходимо выполнить для восстановления операции, зависят от типа журнальной записи:
		- Зарегистрирована логическая операция.
			Для наката логической операции выполняется эта операция.
			Для отката логической операции выполняется логическая операция, обратная зарегистрированной.
		- Зарегистрированы исходный и результирующий образы записи.
			Для наката операции применяется результирующий образ.
			Для отката операции применяется исходный образ.
	- В журнал транзакций записываются различные типы операций, например:
			- начало и конец каждой транзакции;
			- любые изменения данных (вставка, обновление или удаление), включая изменения в любой таблице (в том числе и в системных таблицах), производимые системными хранимыми процедурами или инструкциями языка DDL;
			- любое выделение и освобождение страниц и экстентов;
			- создание и удаление таблиц и индексов.
			- Кроме того, регистрируются операции отката. Каждая транзакция резервирует в журнале транзакций место, чтобы при выполнении инструкции отката или возникновения ошибки в журнале было достаточно места для регистрации отката. Объем резервируемого пространства зависит от выполняемых в транзакции операций, но обычно он равен объему, необходимому для регистрации каждой из операций. Все это пространство после завершения транзакции освобождается.
			
-- Факторы, которые могут вызвать задержку усечения журнала
	- Причину, препятствующую усечению журнала транзакций в конкретном случае, выполните запрос по столбцам log_reuse_wait и log_reuse_wait_desc представления каталога sys.database.
		SELECT name,log_reuse_wait,log_reuse_wait_desc FROM sys.databases
		
		-- Примеры задержек:
			1. LOG_SCAN (Производится просмотр журнала. (Все модели восстановления) Это очень распространенная (и обычно кратковременная) причина задержки усечения журнала транзакций.)
			2. AVAILABILITY_REPLICA (Вторичная реплика группы доступности применяет записи журнала транзакций этой базы данных к соответствующей базе данных-получателю. (Модель полного восстановления))
			3. OLDEST_PAGE (Если база данных настроена для использования косвенных контрольных точек, самая старая страница в базе данных может быть старше контрольной точки с номером LSN. В этом случае самая старая страница может задержать усечение журнала. (Все модели восстановления))
			4. Активная транзакция
			
-- Журнал транзакций/Log file/transaction log
	- Записи журнала могут оставаться активными по множеству причин, которые описываются в этом разделе. Чтобы определить, что препятствует усечению журнала транзакций в конкретном случае, используйте столбцы log_reuse_wait и log_reuse_wait_desc представления каталога sys.database (http://msdn.microsoft.com/ru-ru/library/ms345414.aspx)
	- Журнал хранит физическое представление данных
	- В нём хранится и старое и новое состояние данных
	- Для вставки 50Мб данных вполне может использоваться 100 Мб лога
	- Посмотреть активную часть журнала транзакций, ту часть, которая используется сейчас
		SELECt * FROM sys.fn_dblog(NULL,NULL)-- Здесь перечислены физические, а не логические операции
	- Аналог sys.fn_dblog(NULL,NULL)
		DBCC LOG('DBName',-1) WITH TABLERESULTS, NOT_INFOMSGS	
	- VLF позволяет очищать место на диске за счёт перезаписи VLF, если там нет необходимых данных для восстановления
	- DBCC LOGINFO, поле Status показывает активен ли лог, если там значение больше 0, значит он не может быть перезаписан, так как там есть необходимые данные. SQL Server пишет либо вначало, либо вконец журнала и если мы видим что Status где-то прерывается, значит это фрагментация	

-- Посмотреть log файла базы/sql log/file log (недокументированная функция)
	SELECT [Current LSN], [Operation], [Context], [Log Record Length], [Page ID], [Slot ID] FROM fn_dblog (NULL, NULL);

-- Улучшить работу Log-файла/файл лога/журнал транзакций/VLF/усечение лога
	1. Произвести дефрагментацию дисков, где будут лежать логи
	2. Создавать только по 1 файлу журнала
	3. Делайте увеличение журнала примерно на 400-800 мегобайт (чтобы увеличение происходило на 8 кусков, а не на 16), не стоит делать увеличение мелкими порциями. До 64 Мб получается 4 курсокв жунарала (Virtual Log Files), от 64Мб до 1Гб 8 кусков, всё что свыше 1Гб - 16.
	4. Если функция DBCC LOGINFO возвращает больше 200, то исправить ситуацию (лучше делать в момент наименьшей активности)
		1. Сделайте backup лога
		2. DBCC SHRINKFILE(transactionloglogicalfilename, TRUNCATEONLY)
		3. Увеличте файл журнала до нужного размера ALTER DATABASE databasename MODIFY FILE ( NAME = transactionloglogicalfilename, SIZE = newtotalsize)
		sp_helpfile -- посмотреть размер файлов и информацию о них
	5. Посмотреть рекомендации сервера по логу каждой базы/Что делать с логом(LOG)/рекомендуемые действия с логом(LOG)
		SELECT name,log_reuse_wait,log_reuse_wait_desc FROM sys.databases
	6. Пложить на отдельный диск
	7. Удалить неиспользуемые неластерные индексы и производить регулярную дефрагментацию, которая создаёт page split, которая в свою очередь нагружает лог. Page split создаёт в 40 раз большую нагрузку чем обычный INSERT. Те же можно использовать FILLFACTOR, чтобы сократить page split
		-- Поиск page split в логе
			select
				 tblDBLog.Operation 
				, tblDBLog.AllocUnitName     
				, [typeLiteral] 
				= max(tblSI.type_desc) 
				, fill_factor
				= max(tblSI.fill_factor) 
				, NumberofIncidents
				= COUNT(*)  
			from   ::fn_dblog(null, null) tblDBLog
				left outer join sys.indexes tblSI 
				   on tblDBLog.AllocUnitName = 
					+  object_schema_name(tblSI.object_id)
					+ '.'
					+  object_name(tblSI.object_id)
					+ '.'
					+ tblSI.name 
			where tblDBLog.Operation = N'LOP_DELETE_SPLIT' 
			group by
				  tblDBLog.Operation
				, tblDBLog.AllocUnitName 
			order by 
				COUNT(*) desc
		
	8. Используйте RAID 1, если не нужна очень большая нагрузка	
	
-- VLF
	- Нужно указывать разумный размер, чтобы он был не очень большим, так как им турдно будет управлять серверу, слишком малый то же очень плохо.
		- Желательно чтобы размер 1 VLF был менее 1 Гб
		- Верхний лимит VLF - 1000
	- Each time your SQL Server starts up, each VLF is examined, and during certain operations that affect the log, the header of each active VLF needs to be examined.
	- FSeqNo - номер VLF файла (DBCC LOGINFO). Часто будет начинаться не с 0 или 1, так как при его перезаписывании это число увеличивается. Так же число может начинаться не с 0 или 1, при создании новой БД, потому что значение берётся из БД model
	- CreateLSN (можно узнать сколько LSN Было добавлено за такт)
	- Если никогда не происходит backup, то мы сами должны выполнять truncate, чтобы позволить занятым VLF перезаписываться (FULL RECOVERY MODEL)
	
	-- Количество vlf файлов
		Up to 1MB	2 VLFs, each roughly 1/2 of the total size
		1MB to 64MB	4 VLFs, each roughly 1/4 of the total size
		64MB to 1GB	8 VLFs, each roughly 1/8 of the total size
		More than 1GB	16 VLFs, each roughly 1/16 of the total size
	
-- Проблемы с файлом лога
	1. Асинхронные репликации и зеркалирование... могут увеличивать размер журнала
	2. Долгие транзакции могут автоматически не освобождаться, можно использовать CHECKPOINT, чтобы вызвать освобождение ресурсов

-- log flush occurs/сброс данных лога на диск
	- A transaction commit log record is generated.
	- A transaction abort log record is generated at the end of a transaction roll back.
	- 60KB of log records have been generated since the previous log flush.
	- Может происходить только 32 одновременных log flush, если нам нужно увеличить это число, то придётся создавать более долгие транзакции, чтобы сбросов было меньше
		- Чтобы посмотреть, используем sys.dm_io_pending_io_requests			

-- recovery interval
	- Если стоит 0 это означает что SQL Server сам решает, когда нужно выполнить CHECKPOINT
	
-- autotruncate mode
	- SELECT DB_NAME(database_id),last_log_backup_lsn,* FROM sys.database_recovery_status --catalog view and looking in the column called last_log_backup_lsn. If that column value is null, the database is in autotruncate mode.
	- В режиме журналирования FULL, autotruncate mode = OFF, в SIMPLE = ON
	- Можно в режиме FULL выполнить runcate выполнив backup...WITH TRUNCATE_ONLY. Это прервёт цепочку backup. Сейчас это не поддерживается и лучше перевести в режим SIMPLE и обратно

-- Использование файла лога по сессиям
		SELECT  
		 DB_NAME(tdt.[database_id]) [DatabaseName] 
		,d.[recovery_model_desc] [RecoveryModel] 
		,d.[log_reuse_wait_desc] [LogReuseWait] 
		,es.[original_login_name] [OriginalLoginName] 
		,es.[program_name] [ProgramName] 
		,es.[session_id] [SessionID] 
		,er.[blocking_session_id] [BlockingSessionId] 
		,er.[wait_type] [WaitType] 
		,er.[last_wait_type] [LastWaitType] 
		,er.[status] [Status] 
		,tat.[transaction_id] [TransactionID] 
		,tat.[transaction_begin_time] [TransactionBeginTime] 
		,tdt.[database_transaction_begin_time] [DatabaseTransactionBeginTime] 
		--,tst.[open_transaction_count] [OpenTransactionCount] --Not present in SQL 2005 
		,CASE tdt.[database_transaction_state] 
		 WHEN 1 THEN 'The transaction has not been initialized.' 
		 WHEN 3 THEN 'The transaction has been initialized but has not generated any log records.' 
		 WHEN 4 THEN 'The transaction has generated log records.' 
		 WHEN 5 THEN 'The transaction has been prepared.' 
		 WHEN 10 THEN 'The transaction has been committed.' 
		 WHEN 11 THEN 'The transaction has been rolled back.' 
		 WHEN 12 THEN 'The transaction is being committed. In this state the log record is being generated, but it has not been materialized or persisted.' 
		 ELSE NULL --http://msdn.microsoft.com/en-us/library/ms186957.aspx 
		 END [DatabaseTransactionStateDesc] 
		,est.[text] [StatementText] 
		,tdt.[database_transaction_log_record_count] [DatabaseTransactionLogRecordCount] 
		,tdt.[database_transaction_log_bytes_used] [DatabaseTransactionLogBytesUsed] 
		,tdt.[database_transaction_log_bytes_reserved] [DatabaseTransactionLogBytesReserved] 
		,tdt.[database_transaction_log_bytes_used_system] [DatabaseTransactionLogBytesUsedSystem] 
		,tdt.[database_transaction_log_bytes_reserved_system] [DatabaseTransactionLogBytesReservedSystem] 
		,tdt.[database_transaction_begin_lsn] [DatabaseTransactionBeginLsn] 
		,tdt.[database_transaction_last_lsn] [DatabaseTransactionLastLsn] 
		FROM sys.dm_exec_sessions es 
		INNER JOIN sys.dm_tran_session_transactions tst ON es.[session_id] = tst.[session_id] 
		INNER JOIN sys.dm_tran_database_transactions tdt ON tst.[transaction_id] = tdt.[transaction_id] 
		INNER JOIN sys.dm_tran_active_transactions tat ON tat.[transaction_id] = tdt.[transaction_id] 
		INNER JOIN sys.databases d ON d.[database_id] = tdt.[database_id] 
		LEFT OUTER JOIN sys.dm_exec_requests er ON es.[session_id] = er.[session_id] 
		LEFT OUTER JOIN sys.dm_exec_connections ec ON ec.[session_id] = es.[session_id] 
		--AND ec.[most_recent_sql_handle] <> 0x 
		OUTER APPLY sys.dm_exec_sql_text(ec.[most_recent_sql_handle]) est 
		--WHERE tdt.[database_transaction_state] >= 4 
		ORDER BY tdt.[database_transaction_begin_lsn]
	
-- Обрезка лога
	1. DBCC SQLPERF(LOGSPACE)
		GO
		ALTER DATABASE [test] SET RECOVERY SIMPLE WITH NO_WAIT
		GO
		ALTER DATABASE [test] SET RECOVERY FULL WITH NO_WAIT
		GO  
		DBCC SQLPERF(LOGSPACE)
	2. Создание FULL или DIFF backup
	3. Backup LOG
	
	-- Rebuild log
		1. Attach без файла лога, тогда лог сам rebuild. Не забыть удалить лог как сущность
		2. Использовать T-SQL	
			
			USE [master]
			GO
			CREATE DATABASE [test] ON 
			( FILENAME = N'F:\DataBases\test.mdf' )
			FOR ATTACH
		3. ALTER DATABASE abs_V1 REBUILD LOG ON (NAME=<dbname>,FILENAME='<logfilepath>')
			
-- SQL Server Log Manager
	-- Когда происходит сброс данных на диск
		1. A transaction commit log record is generated.
		2. A transaction abort log record is generated at the end of a transaction roll back.
		3. 60KB of log records have been generated since the previous log flush.
		
	- Для улучшения ситуации можно использовать отложенную запись в SQL Server 2014
	-- Amount of "outstanding log I/O" Limit.
		a. SQL Server 2008: limit of 3840K at any given time
		b. Prior to SQL Server 2008: limit of 480K at any given time
		c. Prior to SQL Server 2005 SP1: based on the number of outstanding requests (noted below)	 

	-- Amount of Outstanding I/O limit.
		a. SQL Server 2005 SP1 or later (including SQL Server 2008 ):
		i. 64-bit: Limit of 32 outstanding I/O’s
		ii. 32-bit: Limit of 8 outstanding I/O’s
		b. Prior to SQL Server 2005 SP1: Limit of 8 outstanding I/O’s (32-bit or 64-bit)
		c. SQL Server 2012 имеет 112 потоков
		
	-- Счетчики/Мониторинг работы с логом
		Log Bytes Flushed/sec (от 512 до 61440)
		Log Flushes/sec (количество сброса в секунду)
		Log Flush Waits/sec (количество ожиданий в секунду)
		
-- Текущие ожидания работы с файлами
	SELECT
		COUNT (*) AS [PendingIOs],
		DB_NAME ([vfs].[database_id]) AS [DBName],
		[mf].[name] AS [FileName],
		[mf].[type_desc] AS [FileType],
		SUM ([pior].[io_pending_ms_ticks]) AS [TotalStall]
	FROM sys.dm_io_pending_io_requests AS [pior]
	JOIN sys.dm_io_virtual_file_stats (NULL, NULL) AS [vfs]
		ON [vfs].[file_handle] = [pior].[io_handle]
	JOIN sys.master_files AS [mf]
		ON [mf].[database_id] = [vfs].[database_id]
		AND [mf].[file_id] = [vfs].[file_id]
	WHERE
	   [pior].[io_pending] = 1
	GROUP BY [vfs].[database_id], [mf].[name], [mf].[type_desc]
	ORDER BY [vfs].[database_id], [mf].[name];

-- Размер генерируемого лога транзакциями
	SELECT [database_transaction_log_bytes_used]
	FROM sys.dm_tran_database_transactions
	WHERE [database_id] = DB_ID (N'tempdb');

-- *********************************************************
-- Чтение лога/log reader/log viewer/backup log reader ****
-- **********************************************************

-- fn_dblog 
	- Данная функция и все её столбцы регистразависимые
	- Посмотреть операции в логе
	SELECT
		[Current LSN],
		[Operation],
		[Context],
		[Transaction ID],
		[Description]
	FROM
		fn_dblog (NULL, NULL),
		(SELECT
			[Transaction ID] AS [tid]
		FROM
			fn_dblog (NULL, NULL)
		WHERE
			[Transaction Name] LIKE '%DROPOBJ%') [fd] -- WHERE [Transaction Name] IN ('DELETE','INSERT','UPDATE')
	WHERE
		[Transaction ID] = [fd].[tid];
	GO
	
	- Получаем LSN c помощью fn_dblog где параметр LOP_BEGIN_XACT, далее переводим этот LSN в другой вид:
		Take the rightmost 4 characters (2-byte log record number) and convert to a 5-character decimal number, including leading zeroes, to get stringA
		Take the middle number (4-byte log block number) and convert to a 10-character decimal number, including leading zeroes, to get stringB
		Take the leftmost number (4-byte VLF sequence number) and convert to a decimal number, with no leading zeroes, to get stringC
		The LSN string we need is stringC + stringB + stringA
		So 0000009d:0000021e:0001 becomes ’157′ + ’0000000542′ + ’00001′ = ’157000000054200001′.
		
	-- Восстанавливаем backup на нужное место
		RESTORE DATABASE [FNDBLogTest2]
			FROM DISK = N'D:\SQLskills\FNDBLogTest_Full.bak'
		WITH
			MOVE N'FNDBLogTest' TO N'C:\SQLskills\FNDBLogTest2.mdf',
			MOVE N'FNDBLogTest_log' TO N'C:\SQLskills\FNDBLogTest2_log.ldf',
			REPLACE, NORECOVERY;
		GO
		 
		RESTORE LOG [FNDBLogTest2]
			FROM DISK = N'D:\SQLskills\FNDBLogTest_Log1.bak'
		WITH
			NORECOVERY;
		GO
		
		-- Чтобы конвертировать Current LSN из файла лога в STOPBEFOREMARK:
			Declare @LSN varchar(22),
				@LSN1 varchar(11),
				@LSN2 varchar(10),
				@LSN3 varchar(5),
				@NewLSN varchar(26)

			-- LSN to be converted to decimal
			Set @LSN = '00000023:000001c4:0002';

			-- Split LSN into segments at colon
			Set @LSN1 = LEFT(@LSN, 8);
			Set @LSN2 = SUBSTRING(@LSN, 10, 8);
			Set @LSN3 = RIGHT(@LSN, 4);

			-- Convert to binary style 1 -> int
			Set @LSN1 = CAST(CONVERT(VARBINARY, '0x' +
					RIGHT(REPLICATE('0', 8) + @LSN1, 8), 1) As int);

			Set @LSN2 = CAST(CONVERT(VARBINARY, '0x' +
					RIGHT(REPLICATE('0', 8) + @LSN2, 8), 1) As int);

			Set @LSN3 = CAST(CONVERT(VARBINARY, '0x' +
					RIGHT(REPLICATE('0', 8) + @LSN3, 8), 1) As int);

			-- Add padded 0's to 2nd and 3rd string
			Select CAST(@LSN1 as varchar(8)) +
				CAST(RIGHT(REPLICATE('0', 10) + @LSN2, 10) as varchar(10)) +
				CAST(RIGHT(REPLICATE('0', 5) + @LSN3, 5) as varchar(5));
		 
		RESTORE LOG [FNDBLogTest2]
		FROM
			DISK = N'D:\SQLskills\FNDBLogTest_Log2.bak'
		WITH
			STOPBEFOREMARK = 'lsn:157000000054200001',
			NORECOVERY;
		GO
		 
		RESTORE DATABASE [FNDBLogTest2] WITH RECOVERY;
		GO
			
	- Теперь мы восстановились на момент удаления таблицы
	
	- Программное получение конвертируемого LSN (Mike Matthews from Dell)
		DECLARE @LogFile varchar(max);
 
		SET @LogFile = 'H:\MSSQL11.MSSQLSERVER\MSSQL\Backup\BigDemoDB\ ';
		SET @LogFile = @LogFile + 'BigDemoDB_Log_20120614_1345.trn';
		 
		WITH LSN_CTE
		AS
		(
		SELECT TOP 1
			   LogRecords.[Current LSN],
			   LEFT( LogRecords.[Current LSN], 8 )          AS Part1,
			   SUBSTRING( LogRecords.[Current LSN], 10, 8 ) AS Part2,
			   RIGHT( LogRecords.[Current LSN], 4 )         AS Part3
		FROM   fn_dump_dblog( DEFAULT, DEFAULT,DEFAULT, DEFAULT, @LogFile, DEFAULT,DEFAULT,
							  DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
							  DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
							  DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
							  DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
							  DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
							  DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
							  DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
							  DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
							  DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT ) AS LogRecords
		WHERE  [Transaction Name] LIKE '%DROPOBJ%'
		)
		SELECT [Current LSN],
			   CAST( CAST( CONVERT( varbinary, Part1, 2 ) AS int ) AS varchar ) +
			   RIGHT( '0000000000' + CAST( CAST( CONVERT( varbinary, Part2, 2 ) AS int ) AS varchar ), 10 ) +
			   RIGHT( '00000'      + CAST( CAST( CONVERT( varbinary, Part3, 2 ) AS int ) AS varchar ), 5 ) AS [Converted LSN]
		FROM   LSN_CTE;

-- fn_dump_dblog
	- Данная функция и все её столбцы регистразависимые
	- AllocUnitName не удаётся получить из backup log, но его можно преобразовать из AllocUnitID
			SELECT o.name AS table_name,p.index_id, i.name AS index_name , au.type_desc AS allocation_type, au.data_pages, partition_number
			FROM sys.allocation_units AS au
				JOIN sys.partitions AS p ON au.container_id = p.partition_id
				JOIN sys.objects AS o ON p.object_id = o.object_id
				JOIN sys.indexes AS i ON p.index_id = i.index_id AND i.object_id = p.object_id
			WHERE allocation_unit_id = 72057594045792256 -- AllocUnitID
			ORDER BY o.name, p.index_id;
		
	SELECT
		SUSER_SNAME([Transaction SID]), -- Чтобы узнать кто это сделал, нужно узнать Transaction ID и сделать выборку по данному полю
		[Transaction SID],
		[Current LSN],
		[Operation],
		[Context],
		[Transaction ID],		
		AllocUnitName, -- Нет в 
		[Description],
    [Begin Time],
    [Transaction Name],*
	FROM
		fn_dump_dblog (
			NULL, NULL, N'DISK', 1, N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\second3.trn',
			DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
			DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
			DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
			DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
			DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
			DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
			DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
			DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
			DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT)
	WHERE 
    Operation = 'LOP_DELETE_ROWS' -- DELETE
	OR Operation = 'LOP_INSERT_ROWS' -- INSERT
	--Operation = 'LOP_MODIFY_ROW' -- UPDATE
	--Operation = 'LOP_COMMIT_XACT'
	--[Transaction Name] = 'DROPOBJ' -- DROP
	--[Transaction ID] = '0000:0000040e' -- Чтобы узнать кто это сделал, нужно узнать Transaction ID и сделать выборку по данному полю, чтобы было меньше вывода, можно ограничить Operation = 'LOP_BEGIN_XACT'