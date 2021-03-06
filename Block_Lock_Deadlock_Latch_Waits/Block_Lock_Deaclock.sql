-- Уровни изоляции/уровень изоляции/isolation level
	- Таблица защиты данных https://msdn.microsoft.com/en-us/library/ms378149(v=sql.110).aspx
	- Режим по-умолчанию READ COMMITTED
	- Писсимист
		1. Read uncommitted
			- Самый лёгкий
			- На чтение не ставится Shared блокировка, можем читать данные на которых стоит Exclusive блокировка. Но проблема в том, что появляется грязное чтрение
			- Shared lock не накладываются (Короткевич)
		2. Read committed
			- Нет грязных чтений
			- Неповторяемое чтение (Относится к UPDATE, одна и так же строка вернёт разные значения)
			- Фантомные записи
			- Shared lock накладываются и сразу же снимаются (Короткевич)
		3. Repeatable read
			- Запрещает грязное чтение
			- Запрещает неповторяемое чтение (не даёт изменять данные пока идёт выборка)
			- Фантомные записи (Относится к INSERT/DELETE. 2 выборки вернут разное количество строк)
			- Shared lock Держатся до конца транзакции (Короткевич)
		4. SERIALIZABLE
			- Нет предыдущих недостатков
			- Все запросы выполняются последовательно. За счёт блокировки Range
			- Есть моменты когда этот уровень изоляции используется неявно.
			- Shared lock накладываются блокировки на интервалы и держатся до конца транзакции (Коротвевич)
	- Оптимист
		- Версионность не Isolation Level, а режим работы БД
		1. Read COMMITTED SNAPSHOT 
			- http://www.larionov.pro/2013/07/readcommittedsnapshot.html
			- Использует версионность в tempdb
			- Используется отдельное хранилище в tempdb до конца транзакции
			- Не ставим Shared блокировки
			- Нет грязных чтений
			- После применения сразу будет действовать на все запросы в READ COMMITED, ничего переписывать не надо.
			- Помогает только когда нужно чтобы писатели не блокировали читателей
			- Могут возникнуть проблемы при одновременном обновлении данных
			-- Включение
				ALTER DATABASE test SET READ_COMMITTED_SNAPSHOT ON
				
			-- Обратить внимание
				1. Дополнительная нагрузка на tempdb
				2. Long version chains could be created, causing query performance to get super slow
				3. Может тратить больше памяти
				4. Целостность данных на уровне запроса
				5. Чтобы связать оригинальную строку и версию в tempdb к оригинальной строке будет добавлено 14 байт, что увеличит фрагментацию если FILLCATIOR = 100
				
			-- Активация	
				- Если транзакция моментального снимка попытается зафиксировать изменения в данных, произошедшие после начала транзакции, то будет произведен откат транзакции и возникнет ошибка.
				- Если транзакция моментального снимка попытается зафиксировать обновление строки, которая была изменена другой транзакцией после начала текущей, возникнет ошибка и будет произведен откат текущей транзакции.

				ALTER DATABASE [Моя База]
				SET READ_COMMITTED_SNAPSHOT ON -- Меняет режим по умолчанию с READ COMMITED на READ COMMITED SNAPSHOT. Если этого не сделать, то потребуется явно указывать уровень изуляции в транзакциях
				ALTER DATABASE [Моя База] SET MULTI_USER WITH ROLLBACK IMMEDIATE
				GO
				
			-- Проверка активности уровня изоляции
				SELECT DB_NAME(database_id), snapshot_isolation_state,snapshot_isolation_state_desc,is_read_committed_snapshot_on FROM sys.databases
			
		2. SNAPSHOT
			- Использует версионность в tempdb
			- Запрещает любые коллизии данных. За счёт Update conflict detection (две транзакции меняют одни данные и так которая сделала быстрее - она выигрывает, а вторая откатывается)
			-  You start using an extra 14 bytes per row (XSN) on tables in the database itself. Also, versions are created in the tempdb version store to hold the previous value of data for updates, deletes, and some inserts. This happens even if no queries are run using SNAPSHOT isolation
			- При активации его на БД, на самом деле запросы не будут его использовать, пока вы их не измените
			-- Включение
				ALTER DATABASE test SET ALLOW_SNAPSHOT_ISOLATION ON
				Далее необходимо в запросе указать SET TRANSACTION ISOLATION LEVEL SNAPSHOT
				
			-- Отличия от Read COMMITTED SNAPSHOT
				- READ_COMMITTED_SNAPSHOT - обеспечивает statement consistency;
				- ALLOW_SNAPSHOT_ISOLATION - обеспечивает transaction consistency при условии явного указания SET TRANSACTION ISOLATION LEVEL SNAPSHOT
				
			-- Обратить внимание
				- Целостность данных на уровне транзакции
				- Чтобы связать оригинальную строку и версию в tempdb к оригинальной строке будет добавлено 14 байт, что увеличит фрагментацию если FILLCATIOR = 100
				- Дополнительная нагрузка на tempdb
				- Требует изменений в коде
				- Писатели не блокируют писателей если обновляют разные данные
				
		-- Посмотреть уровень изоляции
			1. DBCC USEROPTIONS
			2. SELECT CASE  
						  WHEN transaction_isolation_level = 1 
							 THEN 'READ UNCOMMITTED' 
						  WHEN transaction_isolation_level = 2 
							   AND is_read_committed_snapshot_on = 1 
							 THEN 'READ COMMITTED SNAPSHOT' 
						  WHEN transaction_isolation_level = 2 
							   AND is_read_committed_snapshot_on = 0 THEN 'READ COMMITTED' 
						  WHEN transaction_isolation_level = 3 
							 THEN 'REPEATABLE READ' 
						  WHEN transaction_isolation_level = 4 
							 THEN 'SERIALIZABLE' 
						  WHEN transaction_isolation_level = 5 
							 THEN 'SNAPSHOT' 
						  ELSE NULL
					   END AS TRANSACTION_ISOLATION_LEVEL ,transaction_isolation_level
				FROM   sys.dm_exec_sessions AS s
					   CROSS JOIN sys.databases AS d
				WHERE  session_id = @@SPID
				  AND  d.database_id = DB_ID();			
				
		-- Блокировки
			1. Только на DDL операциях
			2. При работе транзакции накладывают Sch-S (стабильность схемы)
				
		-- Особенности
			- Получаем commit данные на момент начала операции
			- Вся строка идёт в tempdb
			- blob (только поле blob идёт в tempdb)
			- DELETE (фоновый процесс который удаляет все транзакции до наименьшей commited)
			- Rollback если пытаемся изменить уже изменённые данные
			- Можно получить доступ к уже изменённым данным, чтобы не получаь ошибку на момент выполнения операции. Для этого используем UPLOCK
			- Hints in your code still apply. Let’s say you have a problem with locking. Over the years NOLOCK hints are added in many places to help make this better. You finally get confirmation from your dev team that READ_COMMITTED_SNAPSHOT is safe for your applications and your change is approved, so you turn it on. You’re spending all those performance resources on versioning, but guess what? Those NOLOCK hints are still causing queries to do dirty reads instead of using the data versioning! The NOLOCK hints gotta go.
			- Update conflicts aren’t the same as deadlocks. Update conflicts are only possible when you use SNAPSHOT isolation for data modification queries– you don’t have to worry about these with READ_COMMITTED_SNAPSHOT. However, it’s often more practical for people to implement SNAPSHOT because of the testing issues I outline above. Even if you’re only implementing SNAPSHOT for read transactions, familiarize yourself with the error codes and messages for update conflicts and make sure your code handles error 3960 (“Snapshot isolation transaction aborted due to update conflict…”).
			- Enabling READ_COMMITTED_SNAPSHOT on a busy system is harder than it sounds. As I mentioned before, turning READ_COMMITTED_SNAPSHOT on or off is a little unusual. You don’t technically have to put the database into single user mode, but to get the command to complete you need to be running the only active command at the moment. The simplest way to do this is to use the ‘WITH ROLLBACK IMMEDIATE’ clause of the ALTER DATABASE command. However, I have not found this to run predictably or easily on very high transaction systems. I recommend planning a change to turn the READ_COMMITTED_SNAPSHOT setting on or off in a database in a very low volume time if you need to keep things predictable.
			- Rolling back and disabling SNAPSHOT requires more code changes. In order to stop row versioning, you need to disable SNAPSHOT — and as soon as you do that, queries that set the isolation level to SNAPSHOT and try to run will fail with Error 3292: “Snapshot isolation transaction failed accessing database ‘dbname’ because snapshot isolation is not allowed in this database”
			- When you use snapshot (how to use is discussed in the next section) isolation levels, any update (please note many updates to the same data in a single transaction does not create multiple versions but rather many updates from multiple transactions do) will be marked with a timestamp and will create a version with old committed data in version store and a pointer (14 bytes needed for pointer and additional overhead) is stored with the changed/new data. This storage of pointers will also add to the cost of using snapshot isolation level. If changes are very frequent, successive prior versions are stored in tempdb using a linked list structure and the newest committed value is always stored in a page in the database.
			
		-- Дополнительно
			Просмотреть наличие версий строк данных можно с помощью системного представления sys.dm_tran_version_store. Транзакции, работающие в режиме версионности доступы с помощью системных представлений sys.dm_tran_transactions_snapshot и sys.dm_tran_active_snapshot_database_transactions.
		

-- Подсказки
	- Чтобы перейти в режим Read uncommitted
		SELECT ... WITH NOLOCK
			
			
	- SELECT %%lockres%% FROM users -- Получить блокировки и хеш кластерного ключа
	- Обязателно посмотреть презентацию и файлы где описано %%lockres%%

-- Почитать
	http://www.mssqltips.com/sql-server-tip-category/61/locking-and-blocking/
	
-- Выставить таймаут на блокировку (мс 1/1000)
	SET LOCK_TIMEOUT timeout_period

-- Гранулярность блокировок
	https://technet.microsoft.com/ru-ru/library/ms189849(v=sql.105).aspx
	
-- Кто кого блочит
	SELECT DB_NAME(pr1.dbid) AS 'DB'
		  ,pr1.waittime AS 'Waittime'
		  ,pr1.spid AS 'ID æåðòâû'
		  ,RTRIM(pr1.loginame) AS 'Login æåðòâû'
		  ,pr2.spid AS 'ID âèíîâíèêà'
		  ,RTRIM(pr2.loginame) AS 'Login âèíîâíèêà'
		  ,pr1.program_name AS 'ïðîãðàììà æåðòâû'
		  ,pr2.program_name AS 'ïðîãðàììà âèíîâíèêà'
		  ,txt.[text] AS 'Çàïðîñ âèíîâíèêà'
	FROM   MASTER.dbo.sysprocesses pr1(NOLOCK)
		   JOIN MASTER.dbo.sysprocesses pr2(NOLOCK)
				ON  (pr2.spid = pr1.blocked)
		   OUTER APPLY sys.[dm_exec_sql_text](pr2.[sql_handle]) AS txt
	WHERE  pr1.blocked <> 0
	
	-- или
	
	SELECT
	db.name DBName,
	tl.request_session_id,
	wt.blocking_session_id,
	OBJECT_NAME(p.OBJECT_ID) BlockedObjectName,
	tl.resource_type,
	h1.TEXT AS RequestingText,
	h2.TEXT AS BlockingTest,
	tl.request_mode
	FROM sys.dm_tran_locks AS tl
	INNER JOIN sys.databases db ON db.database_id = tl.resource_database_id
	INNER JOIN sys.dm_os_waiting_tasks AS wt ON tl.lock_owner_address = wt.resource_address
	INNER JOIN sys.partitions AS p ON p.hobt_id = tl.resource_associated_entity_id
	INNER JOIN sys.dm_exec_connections ec1 ON ec1.session_id = tl.request_session_id
	INNER JOIN sys.dm_exec_connections ec2 ON ec2.session_id = wt.blocking_session_id
	CROSS APPLY sys.dm_exec_sql_text(ec1.most_recent_sql_handle) AS h1
	CROSS APPLY sys.dm_exec_sql_text(ec2.most_recent_sql_handle) AS h2
	GO	

-- Основное (LOCK)
	-http://aboutsqlserver.com/lockingblocking/
	- Для блокировок сервер используем память
	- Динамический пул блокировки не получит больше чем 60 процентов памяти, выделенной для компонента Компонент Database Engine
	- Каждая блокировка занимает 96 байт
	- Параметр locks также оказывает влияние при укрупнении блокировки (эскалация). Когда параметр locks установлен в 0, укрупнение блокировки происходит тогда, когда память, используемая текущими структурами блокировки, достигает 40 процентов от пула памяти компонента Компонент Database Engine. Если параметр locks установлен не в значение 0, укрупнение блокировки происходит, когда количество блокировок достигает 40 процентов от значения, указанного для параметра locks.
	- SQL Server работает с блокировками на уровне хэшей, а не записей
		SELECT %%lockres%% FROM MyTable WHERE ...< 10
		
	- IX - блокировка о намерении. Говорит о том, что у детей есть блокировки конкретного типа
	- При обновлении использует сначала блокировка U, а потом всё равно X (момент обновления)
	- Возможно можно использовать Serializable когда один пользователь и данные статичны
	- READ UNCOMMITTED накладывает только блокировки на уровне схемы, чтобы гарантировать что она не изменится
	- READ COMMITTED после чтения блокировка отпускается
	- REPEATABLE READ сначала блокировки на все объекты и только после прочтения всех объектов, они отпускаются
	- Serializable как REPEATABLE READ только блокируются не конкретные записи, а блоки записей с 1 по 10 например
	
-- Секционирование блокировок
	- Механизм активируется только при 16+ процессоров
	- Если следующий скрипт возвращает что-то выше 0, значит механизм активировался
		SELECT DISTINCT resource_lock_partition FROM sys.dm_tran_locks
	
-- Как узнать информацию о LOCK
	sp_lock
	sp_lock [ [ @spid1 = ] 'session ID1' ] [ , [@spid2 = ] 'session ID2' ]
	
-- Блокировки (это дефолное поведение при read committed)
	1. Shared (могут читать множество пользователей)
	2. Exclusive (изменение данных, другой пользователь будет ждать пока она не будет снята)
	3. Update (поиск данных в таблицы для удаления или обновления. показывает намерение изменить строку. пока он ищет, эти даннные можно читать, но если приходит вторая update блокировка, то она будет ждать)
	4. Intent locks (Перед блокировкой на уровне строки, то вначале он ставит на уровне таблицы, потом на уровне страницы и только потом скажем обычную shared)

	-- Как можно смотреть
		1. Performance Monitor
			- SQL Server:Locks - Average Wait Time
			- SQL Server:Locks - Number of Deadlocks
			- SQL Server: General Statistics - Processes blocked
		2. Настроить Alert
			- На событие SQL Server: General Statistics - Processes blocked > 1
		3. Посмотреть статистику ожиданий
			E:\SQL Scripts\Скрипты\Triage Wait Stats in SQL Server.sql
			- Посмотреть совместимость блокировок http://technet.microsoft.com/en-us/library/ms186396(v=sql.105).aspx
		4. Использовать процедры сбора статистики
			- Искать E:\SQL Scripts\Скрипты\sp_AskBrent.sql
			sp_AskBrent
			GO
			sp_AskBrent @expertmode=1, @seconds=15
		5. sp_Blitzindex @database_name = 'DBName'
			E:\SQL Scripts\Скрипты\sp_BlitzIndex.sql
		6. sp_configure blocked process threshold (s), 5 (порог, в секундах, когда регистрируем блокировки)
		7. Profiler
			- Events: Errors and Warnings - Blocked process Report -- Для его отображения надо включить через конфигурацию сервера blocked process threshold
				Columns: Text, spid
			- Для просмотра трассы воспользуйтесь E:\SQL Scripts\Скрипты\sp_blocked_process_report_viewer.sql
				sp_blocked_process_report_viewer @Trace =  'TraceFileOrTable'  
		8.  Включение логирования deadlock
		9. sys.dm_tran_lock (нужно джойнить с waits)
		10. Exended Events
		11. Event Notifications (скрипт в блоге автора Дмитрий Короткевич) (http://aboutsqlserver.com/2013/04/08/locking-in-microsoft-sql-server-part-16-monitoring-blocked-processes-report-with-event-notifications/)
	
	-- Как бороться
		1. Создание индексов. Неиндексированное сканирование часто падает в блокировку на обновляемые объекты
		2. READ UNCOMMITTED. Только если одни Update, а другие READ, 2 UPDATE будут ждать
		3. Оптимизация
		4. Используйте короткие транзакции
		5. Не изменять запись несколько раз во время одной транзакции/не меняйте записи в нескольких индексов
		6. Осторожно с фреймворками


-- Получить блокировки и хеш кластерного ключа
	- SELECT %%lockres%% FROM users 	

-- WAIT_AT_LOW_PRIORITY/Low priority locks
	- Сделана для онлайн перестроение индексов и переключения секций
	- Позволяет реагировать на блокировки при возникновении таковых по вашему усмотрению
	
	-- Примеры
		- Отключит себя если упадёт в блокировку через 1 минуту
			ALTER TABLE [AdventureWorksDW2012].[dbo].[FactInternetSales] SWITCH PARTITION 37 TO  [AdventureWorksDW2012].[dbo].[staging_FactInternetSales] WITH (WAIT_AT_LOW_PRIORITY (MAX_DURATION = 1 MINUTES, ABORT_AFTER_WAIT = SELF));
		- Отлюкчит того, кто блокирует
			ALTER TABLE [AdventureWorksDW2012].[dbo].[staging_FactInternetSales] SWITCH PARTITION 37 TO  [AdventureWorksDW2012].[dbo].[FactInternetSales] WITH (WAIT_AT_LOW_PRIORITY (MAX_DURATION = 1 MINUTES, ABORT_AFTER_WAIT = BLOCKERS));
	
-- sys.dm_tran_locks, which is described by BOL as:
	- Returns information about currently active lock manager resources. Each row represents a currently active request to the lock manager for a lock that has been granted or is waiting to be granted. The columns in the result set are divided into two main groups: resource and request. The resource group describes the resource on which the lock request is being made, and the request group describes the lock request.

-- Look at active Lock Manager resources for current database
	SELECT request_session_id, DB_NAME(resource_database_id) AS [Database], 
	resource_type, resource_subtype, request_type, request_mode, 
	resource_description, request_mode, request_owner_type,resource_associated_entity_id,p.[object_id],request_status
	FROM sys.dm_tran_locks l
	LEFT JOIN sys.partitions p ON  p.hobt_id= l.resource_associated_entity_id
	WHERE request_session_id > 50
	AND resource_database_id = DB_ID()
	AND request_session_id <> @@SPID
	ORDER BY request_session_id;	
	
-- Заблокированные сессии/заблокированные процессы (пользоваться этой)
	SELECT  blocking.session_id AS blocking_session_id ,
		blocked.session_id AS blocked_session_id ,
		waitstats.wait_type AS blocking_resource ,
		waitstats.wait_duration_ms/1000 as wait_duration_sec ,
		waitstats.wait_duration_ms/1000/60 as wait_duration_min ,
		waitstats.wait_duration_ms/1000/60/60 as wait_duration_hour ,
		waitstats.resource_description ,
		blocked_cache.text AS blocked_text ,
		blocking_cache.text AS blocking_text
	FROM    sys.dm_exec_connections AS blocking
		INNER JOIN sys.dm_exec_requests blocked
			ON blocking.session_id = blocked.blocking_session_id
		CROSS APPLY sys.dm_exec_sql_text(blocked.sql_handle)
							blocked_cache
		CROSS APPLY sys.dm_exec_sql_text(blocking.most_recent_sql_handle)
							blocking_cache
		INNER JOIN sys.dm_os_waiting_tasks waitstats
			ON waitstats.session_id = blocked.session_id

-- Detect blocking
	SELECT blocked_query.session_id AS blocked_session_id,
	blocking_query.session_id AS blocking_session_id,
	sql_text.text AS blocked_text, sql_btext.text AS blocking_text, waits.wait_type AS blocking_resource
	FROM sys.dm_exec_requests AS blocked_query
	INNER JOIN sys.dm_exec_requests AS blocking_query 
	ON blocked_query.blocking_session_id = blocking_query.session_id
	CROSS APPLY
	(SELECT * FROM sys.dm_exec_sql_text(blocking_query.sql_handle)
	) sql_btext
	CROSS APPLY
	(SELECT * FROM sys.dm_exec_sql_text(blocked_query.sql_handle)
	) sql_text
	INNER JOIN sys.dm_os_waiting_tasks AS waits 
	ON waits.session_id = blocking_query.session_id

-- Index Contention (блокировки индексов)
	SELECT dbid=database_id, objectname=object_name(s.object_id),
	indexname=i.name, i.index_id, row_lock_count, row_lock_wait_count,
	[block %]= CAST (100.0 * row_lock_wait_count / (1 + row_lock_count) AS NUMERIC(15,2)),
	row_lock_wait_in_ms,
	[avg row lock waits in ms]= CAST (1.0 * row_lock_wait_in_ms / (1 + row_lock_wait_count) AS NUMERIC(15,2))
	FROM sys.dm_db_index_operational_stats (db_id(), NULL, NULL, NULL) AS s
	INNER JOIN sys.indexes AS i
	ON i.object_id = s.object_id
	WHERE objectproperty(s.object_id,'IsUserTable') = 1
	AND i.index_id = s.index_id
	ORDER BY row_lock_wait_count DESC

-- Look for blocking
	SELECT tl.resource_type, tl.resource_database_id,
		   tl.resource_associated_entity_id, tl.request_mode,
		   tl.request_session_id, wt.blocking_session_id, 
		   wt.wait_type, wt.wait_duration_ms
	FROM sys.dm_tran_locks as tl
	INNER JOIN sys.dm_os_waiting_tasks as wt
	ON tl.lock_owner_address = wt.resource_address
	ORDER BY wait_duration_ms DESC;
	
	-- Посмотреть lock/посмотреть локи
		DBCC TRACEON (3604, 1200, -1);
		  SELECT * FROM [dbo].[Category] WHERE c =1
		DBCC TRACEOFF (3604, 1200, -1);
	
-- Заблокированные транзакции/заблокированные запросы/Блокировки
	SELECT
		db.name DBName,
		tl.request_session_id,
		wt.blocking_session_id,
		OBJECT_NAME(p.OBJECT_ID) BlockedObjectName,
		tl.resource_type,
		h1.TEXT AS RequestingText,
		h2.TEXT AS BlockingTest,
		tl.request_mode
		FROM sys.dm_tran_locks AS tl
		INNER JOIN sys.databases db ON db.database_id = tl.resource_database_id
		INNER JOIN sys.dm_os_waiting_tasks AS wt ON tl.lock_owner_address = wt.resource_address
		INNER JOIN sys.partitions AS p ON p.hobt_id = tl.resource_associated_entity_id
		INNER JOIN sys.dm_exec_connections ec1 ON ec1.session_id = tl.request_session_id
		INNER JOIN sys.dm_exec_connections ec2 ON ec2.session_id = wt.blocking_session_id
		CROSS APPLY sys.dm_exec_sql_text(ec1.most_recent_sql_handle) AS h1
		CROSS APPLY sys.dm_exec_sql_text(ec2.most_recent_sql_handle) AS h2	
		
-- Lock on tables/блокировки на таблице
	select request_session_id,resource_type, resource_associated_entity_id = CASE       
   WHEN resource_type = 'OBJECT'  THEN object_name(resource_associated_entity_id) 
   WHEN resource_type IN ('DATABASE', 'FILE', 'METADATA') THEN  CONVERT (varchar,resource_associated_entity_id)
   WHEN resource_type IN ('KEY', 'PAGE', 'RID') THEN  object_name(sp.object_id) 
   end,						 
	host_name,program_name,status,last_request_start_time from sys.dm_tran_locks dtl inner join sys.dm_exec_sessions des
	on dtl.request_session_id=des.session_id
	inner join  sys.partitions sp
	on dtl.resource_associated_entity_id=sp.hobt_id
	where dtl.resource_database_id=DB_ID() and dtl.resource_type in ('OBJECT', 'PAGE', 'KEY', 'EXTENT', 'RID','HOBT')
	--group by request_session_id,resource_type, resource_associated_entity_id ,host_name,program_name,status,last_request_start_time,sp.object_id

	SELECT  L.request_session_id AS SPID, 
			DB_NAME(L.resource_database_id) AS DatabaseName,
			O.Name AS LockedObjectName, 
			P.object_id AS LockedObjectId, 
			ER.wait_type as SessionWaitType,
			L.resource_type AS LockedResource, 
			L.request_mode AS LockType,
			ST.text AS SqlProcedureText,        
			SUBSTRING (st.text,er.statement_start_offset/2, 
			 (CASE
				WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), st.text)) * 2 
				ELSE er.statement_end_offset
			  END - er.statement_start_offset)/2) as SqlStatementText,
			ES.login_name AS LoginName,
			ES.host_name AS HostName,
			ES.status AS Status,
					 
		   -- TST.is_user_transaction as IsUserTransaction,
		   -- AT.name as TransactionName,
			CN.auth_scheme as AuthenticationMethod
	FROM    sys.dm_tran_locks L
			JOIN sys.partitions P ON P.hobt_id = L.resource_associated_entity_id
			JOIN sys.objects O ON O.object_id = P.object_id
			JOIN sys.dm_exec_sessions ES ON ES.session_id = L.request_session_id
			--JOIN sys.dm_tran_session_transactions TST ON ES.session_id = TST.session_id
			--JOIN sys.dm_tran_active_transactions AT ON TST.transaction_id = AT.transaction_id
			JOIN sys.dm_exec_connections CN ON CN.session_id = ES.session_id
			left JOIN sys.dm_exec_requests ER on ES.session_id=ER.session_id
			CROSS APPLY sys.dm_exec_sql_text(CN.most_recent_sql_handle) AS ST
	WHERE   resource_database_id = db_id()
	ORDER BY L.request_session_id

-- Статистика по блокировкам в текущей БД/lock on table/objcts
	- Обнуляется после рестарта или исчезновения объекта из кэша
	SELECT t.name AS [TableName],
		   fi.page_count AS [Pages],
		   fi.record_count AS [Rows],
		   CAST(fi.avg_record_size_in_bytes AS int) AS [AverageRecordBytes],
		   CAST(fi.avg_fragmentation_in_percent AS int) AS [AverageFragmentationPercent],
		   SUM(iop.leaf_insert_count) AS [Inserts],
		   SUM(iop.leaf_delete_count) AS [Deletes],
		   SUM(iop.leaf_update_count) AS [Updates],
		   SUM(iop.row_lock_count) AS [RowLocks],
		   SUM(iop.page_lock_count) AS [PageLocks]
	  FROM sys.dm_db_index_operational_stats(DB_ID(),NULL,NULL,NULL) AS iop
	  JOIN sys.indexes AS i ON iop.index_id = i.index_id AND
							   iop.object_id = i.object_id
	  JOIN sys.tables AS t ON i.object_id = t.object_id AND
							  i.type_desc IN ('CLUSTERED', 'HEAP')
	  JOIN sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'SAMPLED') AS fi ON fi.object_id=CAST(t.object_id AS int) AND
																						 fi.index_id=CAST(i.index_id AS int)
	  GROUP BY t.name, fi.page_count, fi.record_count, fi.avg_record_size_in_bytes, fi.avg_fragmentation_in_percent
	  ORDER BY [RowLocks] desc
		
		
-- Spinlock
	- Легковесная блокировка, при доступ к данным на очень короткое время
	- Режимов и матрицы совместимости нет
	- Симптомы
		- Большое значение backoff событий на опередённом типа spinlock. Backoff - ресурс был недоступен после нескольких попыток запроса
		- Высокое потребление CPU
		- Количество ядер от 24
		- Неравномерное потребление CPU при повышении нагрузки
	- MUTEX
	select * from sys.dm_os_spinlock_stats order by spins desc
	- Для доступа к HASH table, Buff array
	
-- Эскалация блокировок (укрупнение блокировок)
	- Укрупнение блокировки включается в том случае, если не выключено для таблицы с помощью параметра ALTER TABLE SET LOCK_ESCALATION, и если выполняется одно из следующих условий. 
		1. Одна инструкция Transact-SQL получает более 5 000 блокировок в одной несекционированной таблице или индексе.
		2. Одна инструкция Transact-SQL получает более 5 000 блокировок в одной секции секционированной таблицы, а параметр ALTER TABLE SET LOCK_ESCALATION установлен в значение AUTO.
		3. Число блокировок в экземпляре компонента Database Engine превышает объем памяти или заданные пороговые значения.
	- Если блокировки не могут быть укрупнены из-за конфликтов блокировок, компонент Database Engine периодически инициирует укрупнение блокировки при получении каждых 1 250 новых блокировок.
	- Блокировки требуют ресурсы (память, процессор)
	- Если запрос более 5000 блокировок на объект, блокирует таблицу. Если нельзя укрупнить сразу, то процесс будет повторяться каждые 1250 блокировок
	- Сначала будут накладываться мелкие блокировки и только потом эскалация, сразу сервер не может понять что требуется эскалация
	- READ COMMITTED SNAPSHOT (версионность за счёт доп. нагрузки на tempdb). Только между читателями и писателями. На уровне БД		
		- Хорош в Reporting
	- SNAPSHOT (уровень изоляции)
		- Если используем, то не делаем FILLFACTOR	
	
	--Порог укрупнения для экземпляра компонента Database Engine
		Каждый раз, когда количество блокировок превышает порог памяти для укрупнения блокировки, компонент Database Engine инициирует укрупнение блокировки. Порог памяти зависит от параметра конфигурации locks:
			- Если параметр locks имеет значение по умолчанию 0, порог укрупнения блокировок достигается, если память, используемая объектами блокировки, составляет 24 % от памяти компонента Database Engine, исключая память AWE. Структура данных, представляющая блокировку, имеет длину примерно в 100 байт. Этот порог динамический, поскольку компонент Database Engine динамически получает и освобождает память в целях компенсации меняющейся рабочей нагрузки.
			- Если параметр locks имеет значение, отличное от 0, порог укрупнения блокировок составляет 40 процентов (или меньше, если памяти мало) от значения параметра locks.
		Компонент Database Engine может выбирать для укрупнения любую активную инструкцию из сеанса, и для 1 250 новых блокировок он выбирает инструкции для повышения, если используемая блокировками память в экземпляре превышает порог повышения.
		
	-- объем блокирования следует сократить следующим образом.
		- Используя уровень изоляции, при котором не требуются совмещаемые блокировки для операций чтения.
			- Уровень изоляции READ COMMITTED, если параметр базы данных READ_COMMITTED_SNAPSHOT включен (ON).
			- Уровень изоляции SNAPSHOT.
			- Уровень изоляции READ UNCOMMITTED. Это может использоваться только в системах с «грязным» чтением.
			- T1211 (уровень сервера)
			- alter table... set lock_escalation (SQL Server 2008+)
			- Оптимистичные уровни изоляции (версионность)
		- Используя табличные подсказки PAGLOCK или TABLOCK, чтобы компонент Database Engine использовал блокировку страниц, кучи или индекса вместо блокировки строк. Однако при этом увеличивается вероятность блокирования пользователями других пользователей, которые пытаются получить доступ к тем же данным. Следует использовать только в системах с небольшим количеством пользователей.
		- В секционированных таблицах параметр LOCK_ESCALATION инструкции ALTER TABLE позволяет произвести укрупнение до уровня HoBT (вместо уровня таблицы) или отключить укрупнение блокировок.
		 
		Можно также использовать флажки трассировки 1211 и 1224, чтобы отключить все или некоторые укрупнения блокировок. Дополнительные сведения см. в разделе Флаги трассировки (Transact-SQL). Отследить укрупнение блокировок можно с помощью события Приложение SQL Server Profiler Lock:Escalation. Дополнительные сведения см. в разделе Работа с приложением SQL Server Profiler
		
		
-- Deadlock
	- два процесса конкурируют за 1 ресурс в разном порядке. Откатывается тот процесс, который легче откатить
	- Основные проблемы из-за сканирования во время обновления, а не из-за фундаментального значения блокировок (изменение одних данных)
	
	-- 3 правила дедлоков
		1. Если дедлок возможет, то он всегда произойдёт. Лучше обновлять таблицы в определённом порядке
		2. Дедлок не должен быть решён, пока вы не разобрались в нём полностью
		3. Не решеаемых дедлоков нет, но бывают варианты, которые могут устраивать не до конца
	
	-- Чем ловить
		- Можно ловить профайлером (есть багги. Например может не ловить дедлоки если стоят фильтры (до SQL Server 2008 версии))
		- Extended Events
		- Лог сервера (включить флаг T1222, 1204)
		- Если хотим ловить дедлок в лог - включаем флаг и перезагружаемся (DBCC TRACEON(1204) и DBCC TRACEON(1222)). Paul Randal советует ещё 1205 (ли старый тип флага или недокументированный)
		- Если хотим смотреть на дедлок - Профайлер
		
	-- Как недопустить
		1. Нормализованная БД
		2. Избегать курсоров
		3. Делать транзакции максимально маленькими + Отказ от взаимодействия с пользователем в транзакциях
		4. Уменьшать время блокировок
		5. По возможности использовать NOLOCK
		6. По возможности использовать минимальный уровень изоляции
		7. key lookup плохая операция и вызывает дедлоки на конкуренции обновление и селект, чтобы этого избежать, постройте индекс, которому не потребуется key lookup. Так же можно использовать Snapshot Isolation Level (READ COMMITED SNAPSHOT ISOLATION), что позволит не накладывать даже Shared lock
		8. Осуществление доступа к объектам в одинаковом порядке -- не обновлять в одной транзакции сначала Orders потом Customers, а во второй наоборот. Делать в обеих одинакого
		9. Использование низкого уровня изоляций
	
	-- Описание флагов
		Trace Flag 1204:- Focused on the nodes involved in the deadlock. Each node has a dedicated section, and the final section describes the deadlock victim.

		Trace Flag 1222:- Returns information in an XML-like format that does not conform to an XML Schema Definition (XSD) schema. The format has three major sections. The first section declares the deadlock victim. The second section describes each process involved in the deadlock. The third section describes the resources that are synonymous with nodes in trace flag 1204.
		
	-- Случаи блокировок
		1. Постоянный update и SELECT этого поля. Момент когда есть кластерный и некластерный индекс. Update ставить блокировку на кластерный, а SELECT на некластеный
			- Решение:
				- Сделать чтобы использоваться только некластерный индекс
		2. CONVERSION DEADLOCK. Уровень изоляции REPEATABLE READ. Работает с одними данными в одном порядке. Вначале оба запроса получают SHARED блокировку и в момент обновления обе транзакции хотят получить сначала UPDATE потом Exclusive блокировку, но не могут, так как блокируют друг друга
			- Решение:
				1. использовать хинт NOLOCK
				2. изменить одному запросу уровень изоляции
		3. Используется SERIALIZABLE (только в этом уровне изоляции может быть такой дедлок). Первая транзакция очищает сначала внутренню таблицу, а потом первичную. Второй обновляет первичную и выбирает из первой данные, поля используются разные. Блокируется немного больше записей, чем используется в запросе, поэтому происходит этот дедлок (тяжело удалить). 
	
	-- Deadlocks 2.0 или с чем ещё можно столкнуться (Denis Reznik)
		- Блокировки (это дефолное поведение при read committed)
			1. Shared (могут читать множество пользователей)
			2. Exclusive (изменение данных, другой пользователь будет ждать пока она не будет снята)
			3. Update (поиск данных в таблицы для удаления или обновления. показывает намерение изменить строку. пока он ищет, эти даннные можно читать, но если приходит вторая update блокировка, то она будет ждать)
			4. Intent locks (Перед блокировкой на уровне строки, то вначале он ставит на уровне таблицы, потом на уровне страницы и только потом скажем обычную shared)
		- Гранулярность (куда могут ставиться блокировки)
			1. Row (если таблица в куче, то минимальный уровень блокировки - строка)
			2. Key (Если есть индекс, то ключи индекса)
			3. Key Range
			4. Page
			5. Table
			
	-- Интересные случаи взаимоблокировок:
		1. Одна сессия порождает несколько requests и блокирует как бы сама себя
		2. Одна сессия (баг, на 20170907 не решено, называется interupt query threadpool), взаимодействие строк и потоков

			
-- metadata lock	
	- связано с system catalog information
	- This can happen only when locks are escalated, and only if you have specified that escalation to the partition level is allowed (and, of course, only when the table or index has been partitioned). We look at how you can specify that you want partition-level locking in the section entitled “Lock Escalation,” later in this chapter.
	-- SELECT * FROM sys.dm_tran_locks WHERE resource_type = 'METADATA'