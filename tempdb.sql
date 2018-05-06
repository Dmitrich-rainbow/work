-- Основное
	- Есть спец часть tempdb для snapshot isolation level - version store
		-- Как много занимает место данный раздел 
			SELECT SUM(version_store_reserved_page_count) AS [version store pages used],
			(SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB]
			FROM sys.dm_db_file_space_usage;
		-- Посмотреть транзакции в данном режиме
			SELECT transaction_id
			FROM sys.dm_tran_active_snapshot_database_transactions 
			ORDER BY elapsed_time_seconds DESC;

-- Настройка
	- ссылка для подтверждение слов http://www.sqlskills.com/blogs/paul/correctly-adding-data-files-tempdb/
	- Количество файлов данных:
		1 вариант: 1 ядро = 1 файл данные (но только на больших и сильных системах)
		2 вариант: 1/2 или 1/4 от количества ваших ядер
		3 вариант: if you have less than 8 cores, use #files = #cores. If you have more than 8 cores, use 8 files and if you’re seeing in-memory contention, add 4 more files at a time
	- Все файлы данных должны быть одного размера
	- Нет смысла увеличивать количество файлов лога
	- Расположить на быстрых дисках или на RAM DRIVE
	- Множественные файлы данных не обязательно должны быть на разных дисках
	- Чтобы производить манипуляции с tempdb надо затронуть системные объекты и одновременно с ними не могут работать много операций. Это является узким место, но большее количество файлов tempdb улучшает ситуацию
	- Запись большого числа данных в tempdb - Дорогая операция
	-- Когда стоит использовать tempdb
		1. Упрощение запросов (сложный запрос). Например вместо того, чтобы делать JOIN с функцией, которая возвращает табличное значение, лучше создать временную таблицу, записать туда данные из этой функции и сделать с ней JOIN
		2. Уменьшение блокировок, если долго работаем с данными. Чтобы не держдать на них блокировку, мы их помещаем во временную таблицу и потом записываем в основную
	-- Как улучшить работу tempdb
		1. Уменьшайте нагрузку на эту базу, не используйте временные объекты, если нет необходимости
		2. Размещайте на наиболее быстром диске
		3. Флаг 1118, 1117
		4. Несколько файлов данных
		5. Дать права 'Perform Volume task'
		6. 	USE [master]
			GO
			ALTER DATABASE [tempdb] SET PAGE_VERIFY NONE  WITH NO_WAIT
			GO
			ALTER DATABASE [tempdb] SET DELAYED_DURABILITY = ALLOWED WITH NO_WAIT
			GO
			ALTER DATABASE [tempdb] SET AUTO_UPDATE_STATISTICS OFF WITH NO_WAIT
			GO
			ALTER DATABASE [tempdb] SET AUTO_UPDATE_STATISTICS_ASYNC ON WITH NO_WAIT
			GO
		7. Во время вставки во временные таблицы включить tablock
			
-- Запуск базы при потере файлов tempdb
	- Пуск >> Выполнить >> cmd >> cd 'место папки bin sql server' >> sqlservr.exe /f /c >> оставляем окно в покое
	- Пуск >> Выполнить >> cmd >> sqlcmd - e >> меняем расположение файла tempdb
	- Добавить параметр запуска -T3608
		alter database tempdb
		modify file(
		name = templog,
		filename = N'C:\templog.ldf')
		go
		alter database tempdb
		modify file(
		name = tempdev,
		filename = N'C:\tempdb.mdf')
		go	
	
-- Ограничений
	1. Нельзя создать View
	2. Нельзя создать Trigger
	
-- Trace Flag 1118
	- На версия выше 2005 не даёт особого эффекта (Paul Randal) и если он на них включён, то не получится поставить некоторые хотфисксы	 
	
-- CHECKPOINT
	- A checkpoint is only done for tempdb when the tempdb log file reaches 70% full – this is to prevent the tempdb log from growing if at all possible (note that a long-running transaction can still essentially hold the log hostage and prevent it from clearing, just like in a user database)
	- В отличие от пользовательских баз данных в tempdb не сбрасываются на диск, кроме моментов когда lazywriter process (part of the buffer pool) has to make space for pages from other databases и кроме моментов ручноого выоза команды CHECKPOINT
	- The other operation that occurs during a checkpoint of databases in the SIMPLE recovery model is that the VLFs in the log are examined to see if they can be made inactive 

-- Временные таблицы/temporal table
	- Временные таблицы в процедурах/temporal table in sp
		1. Даже если временная таблица удаляется в процедуре, на самом деле она не удаляется, а truncate + rename. Как следствие статистика для неё остаётся старой и обновляется только если сработает автоматического обновление статистики, основываясь на количестве строк при прошлом обновлении или запускать автоматически. Так если было вставлено 10 строк, то потребуется обновить в данной таблице 10+500 строк (если строк много, то будем ожидать обновление 20% данных), то есть множественный вызов процедуры всё-таки произведёт обновление статистики, но это будет не регулярно и не оптимально для разных вызовов. В данном случае TRUNCATE так же генерирует обновление строк.
		2. RECOMPILE не помогает, так как на обновление статистики это не влияет во временных таблицах
		3. Update statistics на временных таблицах в процедуре так же не поможет, та как оставит старый план, поэтому выходом будет RECOMPILE + Update Stastics

	-- Оптимизация работы
		1. Не использовать SELECT *
		2. Фильтруйте выборку, чтобы не выбирать всё
	
-- Свободное место
	-- Общее
		SELECT SUM(unallocated_extent_page_count) AS [free pages], 
		(SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB]
		FROM sys.dm_db_file_space_usage;
	-- По файлам
		SELECT
			[name]
			,CONVERT(NUMERIC(10,2),ROUND([size]/128.,2))											AS [Size]
			,CONVERT(NUMERIC(10,2),ROUND(FILEPROPERTY([name],'SpaceUsed')/128.,2))				AS [Used]
			,CONVERT(NUMERIC(10,2),ROUND(([size]-FILEPROPERTY([name],'SpaceUsed'))/128.,2))		AS [Unused]
		FROM [sys].[database_files]
	
-- Место под Internal объкты
	SELECT SUM(internal_object_reserved_page_count) AS [internal object pages used],
	(SUM(internal_object_reserved_page_count)*1.0/128) AS [internal object space in MB]
	FROM sys.dm_db_file_space_usage;
	
-- Место занятое пользователискими БД
	SELECT SUM(user_object_reserved_page_count) AS [user object pages used],
	(SUM(user_object_reserved_page_count)*1.0/128) AS [user object space in MB]
	FROM sys.dm_db_file_space_usage;
	
-- Использование tempdb сессиями/кто пишет в tempdb
	SELECT session_id, 
	  SUM(internal_objects_alloc_page_count) AS task_internal_objects_alloc_page_count,
	  SUM(internal_objects_alloc_page_count)*8/1024 as task_internal_objects_alloc_page_count_mb,
	  SUM(internal_objects_dealloc_page_count) AS task_internal_objects_dealloc_page_count 
	FROM sys.dm_db_task_space_usage 
	GROUP BY session_id
	ORDER BY task_internal_objects_alloc_page_count DESC;
	
-- Какие объекты созданы в tempdb
	select * from tempdb.sys.all_objects
	where is_ms_shipped = 0;
	
-- Использование tempdb (размер)
	SELECT SUM(user_object_reserved_page_count)*8 as usr_obj_kb, -- сколько данных во временной базе данных используется в прикладном коде
	SUM(internal_object_reserved_page_count)*8 as internal_obj_kb, -- показывает, сколько данных используется для системных задач
	SUM(version_store_reserved_page_count)*8 as version_store_kb, -- оказывает объем данных для хранения версий строк при использовании
	SUM(unallocated_extent_page_count)*8 as freespace_kb,
	SUM(mixed_extent_page_count)*8 as mixedextent_kb
	FROM tempdb.sys.dm_db_file_space_usage
		
		-- Более детально
			SELECT es.session_id
			, ec.connection_id
			, es.login_name
			, es.host_name
			, st.text
			, su.user_objects_alloc_page_count
			, su.user_objects_dealloc_page_count
			, su.internal_objects_alloc_page_count
			, su.internal_objects_dealloc_page_count
			, ec.last_read
			, ec.last_write
			, es.program_name
			FROM tempdb.sys.dm_db_session_space_usage su
			INNER JOIN sys.dm_exec_sessions es ON su.session_id = es.session_id
			LEFT OUTER JOIN sys.dm_exec_connections ec ON su.session_id = ec.most_recent_session_id
			OUTER APPLY sys.dm_exec_sql_text(ec.most_recent_sql_handle) st
	

	
-- Поиск сваливаний в tempdb данных
	WITH 
	XMLNAMESPACES (DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
	SELECT 
	Query_Plan.query('ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') TempDbSpillWarnings
	INTO #test
	FROM sys.dm_exec_cached_plans as s
	CROSS APPLY sys.dm_exec_query_plan(s.plan_handle) AS deqp

	SELECT * FROM #test WHERE CAST(TempDbSpillWarnings as varchar(MAX)) like  '%Spool%'
	DROP TABLE #test
	
-- Найти allocation page contention in tempDB. Можно сказать если тут нет проблем, значит нет смысла менять количество файлов данных базы tempdb
	Select session_id,
	wait_type,
	wait_duration_ms,
	blocking_session_id,
	resource_description,
		  ResourceType = Case
	When Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 1 % 8088 = 0 Then 'Is PFS Page'
				When Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 2 % 511232 = 0 Then 'Is GAM Page'
				When Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 3 % 511232 = 0 Then 'Is SGAM Page'
				Else 'Is Not PFS, GAM, or SGAM page'
				End
	From sys.dm_os_waiting_tasks
	Where wait_type Like 'PAGE%LATCH_%'
	And resource_description Like '2:%' -- 2 это id БД	
	
-- Сравнение результатов от количества файлов tempdb
	- Настроить Performance Monitor на SQLServer:Databases - Transaction/sec в tempdb и если tempdb стал пропускать больше транзакций при той же нагрузке, значит вы идёте в нужнмо направлении
	
-- Проверка на необходимость нескольких файлов tempdb (Paul Randal)
	SELECT
		[owt].[session_id],
		[owt].[exec_context_id],
		[owt].[wait_duration_ms],
		[owt].[wait_type],
		[owt].[blocking_session_id],
		[owt].[resource_description],
		CASE [owt].[wait_type]
			WHEN N'CXPACKET' THEN
				RIGHT ([owt].[resource_description],
				CHARINDEX (N'=', REVERSE ([owt].[resource_description])) - 1)
			ELSE NULL
		END AS [Node ID],
		[es].[program_name],
		[est].text,
		[er].[database_id],
		[eqp].[query_plan],
		[er].[cpu_time]
	FROM sys.dm_os_waiting_tasks [owt]
	INNER JOIN sys.dm_exec_sessions [es] ON
		[owt].[session_id] = [es].[session_id]
	INNER JOIN sys.dm_exec_requests [er] ON
		[es].[session_id] = [er].[session_id]
	OUTER APPLY sys.dm_exec_sql_text ([er].[sql_handle]) [est]
	OUTER APPLY sys.dm_exec_query_plan ([er].[plan_handle]) [eqp]
	WHERE
		[es].[is_user_process] = 1
	ORDER BY
		[owt].[session_id],
		[owt].[exec_context_id];
	GO
	
	-If you see a lot of lines of output where the wait_type is PAGELATCH_UP or PAGELATCH_EX, and the resource_description is 2:1:1 then that’s the PFS page (database ID 2 – tempdb, file ID 1, page ID 1), and if you see 2:1:3 then that’s another allocation page called an SGAM.

	There are three things you can do to alleviate this kind of contention and increase the throughput of the overall workload:
		Stop using temp tables
		Enable trace flag 1118 as a start-up trace flag
		Create multiple tempdb data files

-- Посмотреть активность в tempdb
	SELECT
	 SPID = s.session_id,
	 s.[host_name],
	 s.[program_name],
	 s.status,
	 s.memory_usage,
	 granted_memory = CONVERT(INT, r.granted_query_memory*8.00),
	 t.text, 
	 sourcedb = DB_NAME(r.database_id),
	 workdb = DB_NAME(dt.database_id), 
	 mg.*,
	 su.*
	FROM sys.dm_exec_sessions s
	INNER JOIN sys.dm_db_session_space_usage su
	   ON s.session_id = su.session_id
	   AND su.database_id = DB_ID('tempdb')
	INNER JOIN sys.dm_exec_connections c
	   ON s.session_id = c.most_recent_session_id
	LEFT OUTER JOIN sys.dm_exec_requests r
	   ON r.session_id = s.session_id
	LEFT OUTER JOIN (
	   SELECT
		session_id,
		database_id
	   FROM sys.dm_tran_session_transactions t
	   INNER JOIN sys.dm_tran_database_transactions dt
		  ON t.transaction_id = dt.transaction_id 
	   WHERE dt.database_id = DB_ID('tempdb')
	   GROUP BY  session_id,  database_id
	   ) dt
	   ON s.session_id = dt.session_id
	 CROSS APPLY sys.dm_exec_sql_text(COALESCE(r.sql_handle,
	 c.most_recent_sql_handle)) t
	 LEFT OUTER JOIN sys.dm_exec_query_memory_grants mg
	   ON s.session_id = mg.session_id
	 WHERE (r.database_id = DB_ID('tempdb')
	   OR dt.database_id = DB_ID('tempdb'))
	  AND s.status = 'running'
	 ORDER BY SPID;
	
-- Дмитрий Артемов. tempdb
- Отливия:
	1. Часто используется неявно
	2. Пишем очень много в неё и часто удаляем
	3. После рестарта создаётся новая
	4. Работа с таблицей в tempdb на порядок быстрее, чем с реальной, потому что там проще
	   система журналирования
	   
- Создаётся на базе модели
	1. Накладываем блокировки на model и tempdb
	2. Копируем из model в tempdb
	3. Расширяем tempdb
	...
- Если проблема с tempdb
	1. запускаем sql с параметром -f
	2. Создаём 1 файл размером с модел (ulimited,fixed auto grow)
	3. Создаём файл журнала 516096 bytes (unlimited,10% autogrow)
	4. Перемещаем их в папку умолчания для БД
	5. Рестарт
- Второй вариант исправления проблемы
	1. Смотрим какой файл система не может найти
	2. запускаем sql с параметром -f
	3. Скриптом переносим этот файл на другой диск
	4. Рестарт
- Что попадает в tempdb
	1. Временные таблицы
	2. Табличные переменные, так же то, что возвращают табличные функции и табличные параметры
	3. Временные процедуры (# и ##)
	4. Обычные таблицы, созданные в tempdb
	5. Сортировки (order by & index rebuild)
	6. Рабочие таблицы (Worktable -внут. таблицы SQL SErver)
	7. Рабочие файлы (WOrkfile - Hash joins)
	8. Version store
	
- Если файлов несколько
	1. Лучше делать одинакого размера, потому что куда писать определяется за счёт свободного места

- Узнать есть ли проблемы
	1. Ожидания PAGELATCH
	2. Большие ожидания на 2:<fileid>:<fixed page #>
	3. Ожилание буфера, не диска (PAGELATCH не PAGELATHIO)
- Решения
	1. Кэширование # таблицы
	2. Trace flag 1118
	3. Несколько файлов
	4. Не давайть autogrow (Trace flag 1117)
	5. Оценить использования временных таблиц
	6. МОниторинг потребления внутрених объектов
- Сколько файлов нужно
	- Если меньше 8 процессоров, то по 1 файлу данных на CPU
	- Если больше - 8 файлов данных
	
--	Андрей Коршиков
	- Не используйте временные таблицы, когда это не нужно
	- Размещайте на самых быстрых дисках
	- Размещение в RAMDrive
		- Если Standard редакция, так как есть ограничение на память
	- используйте флаг 1118 (sql server перестаёт использовать смешанные участки). Улучшает производительность. Все его советуют
	- Создавайте несколько файлов данных. Если ядер меньше 8, то 8, если больше то начните с 8 и прибавляйте по 4
	- tempdb как временная зона как рабочая площадка. Хороший вариант
	
-- Удаление файлов/сжать
	USE [tempdb]
	GO
	CHECKPOINT
	GO
	DBCC DROPCLEANBUFFERS
	GO
	DBCC FREEPROCCACHE
	GO
	DBCC FREESESSIONCACHE
	GO
	DBCC FREESYSTEMCACHE ( 'ALL')
	GO
	DBCC SHRINKFILE (N'templog_default_ram' , EMPTYFILE)
	GO
	ALTER DATABASE [tempdb]  REMOVE FILE [templog_default_ram]
	GO