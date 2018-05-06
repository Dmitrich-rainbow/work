--***** ПОДДЕРЖКА БАЗ ДАННЫХ В SQL SERVER 2008*****

-- Версия сервера
	SELECT SERVERPROPERTY('Edition');
	
-- Системные таблицы
	- Посмотреть инфомрацию из этих таблиц можно только с помощью подключения DAC
	USE master;
	SELECT name FROM sys.objects
	WHERE type_desc = 'SYSTEM_TABLE';

-- Обратная связь с Microsoft
https://connect.microsoft.com/sqlserver/feedback

ADVENTUREWORKS\Administrator
Pa$$w0rd

-- Выбор редакции SQL SERVER
	- http://msdn.microsoft.com/en-us/library/ms144275.aspx

-- ***** Session/Сессии *****	
-- Посмотреть кто подключён к SQL
	sp_who 
	sp_who2
	sp_who2 114
	exec sp_who 'active'	
	-- Более подробная статистика
		SELECT host_process_id,*  FROM sys.dm_exec_sessions WHERE host_process_id IS NOT NULL
		SELECT * FROM sys.sysprocesses -- более подробно по spid
		
	-- Посмотреть активные транзакции в базе
		DBCC OPENTRAN ()
		
	-- Последний запрос/ last query
		DBCC INPUTBUFFER(117)

		DECLARE @sqltext VARBINARY(128)
		SELECT @sqltext = sql_handle
		FROM sys.sysprocesses
		WHERE spid = 117
		SELECT TEXT
		FROM sys.dm_exec_sql_text(@sqltext)
		GO

		DECLARE @sqltext VARBINARY(128)
		SELECT @sqltext = sql_handle
		FROM sys.sysprocesses
		WHERE spid = 117
		SELECT TEXT
		FROM ::fn_get_sql(@sqltext)
		GO
		
	-- Не активные пользователи более суток
		select dc.session_id as [SPID],
		dc.client_net_address as [IP клиента],
		sp.hostname as [Имя PC клиента],
		sp.loginame,
		sp.last_batch as [Дата последенего запроса],
		dc.last_read as [Дата последенего чтения],
		dc.last_write as [Дата последенего записи],
		sp.[program_name] as [Имя программы],
		DB_NAME(dt.dbid) as [Имя БД],
		dt.text
		FROM sys.dm_exec_connections dc
		inner join master.sys.sysprocesses sp
		CROSS APPLY sys.dm_exec_sql_text(sp.sql_handle) dt
		on dc.session_id=sp.spid
		where last_batch < GETDATE() - 1
		and sp.spid>50
		
	-- Как долго осталось до завершении операции по spid
		- Можно посмотреть для
			ALTER INDEX REORGANIZE
			AUTO_SHRINK с ALTER DATABASE
			BACKUP DATABASE
			CREATE INDEX
			DBCC CHECKDB
			DBCC CHECKFILEGROUP
			DBCC CHECKTABLE
			DBCC INDEXDEFRAG
			ALTER INDEX REORGANIZE
			DBCC SHRINKDATABASE
			DBCC SHRINKFILE
			KILL (Transact-SQL)
			RESTORE DATABASE
			UPDATE STATISTICS
			ROLLBACK
		
		SELECT session_id,percent_complete,DATEADD(MILLISECOND,estimated_completion_time,CURRENT_TIMESTAMP) Estimated_finish_time,
		(total_elapsed_time/1000)/60 Total_Elapsed_Time_MINS ,
		DB_NAME(Database_id) Database_Name ,command,sql_handle
		FROM sys.dm_exec_requests WHERE session_id=58
		
		- Весь список
			SELECT ost.session_id
				 , DB_NAME(ISNULL(s.dbid,1)) AS dbname
				 , er.command
				 , er.percent_complete
				 , dateadd (ms, er.estimated_completion_time, getdate()) AS [Прогноз завершения]
				 , er.status
				 , osth.os_thread_id
				 , ost.pending_io_count
				 , ost.scheduler_id
				 , osth.creation_time
				 , ec.last_read
				 , ec.last_write
				 , s.text
				 , owt.exec_context_id
				 , owt.wait_duration_ms
				 , owt.wait_type
			FROM   master.sys.dm_os_tasks AS ost
			JOIN   master.sys.dm_os_threads AS osth ON ost.worker_address = osth.worker_address
			AND    ost.pending_io_count > 0 AND ost.session_id IS NOT NULL
			JOIN   master.sys.dm_exec_connections AS ec ON ost.session_id = ec.session_id
			CROSS  APPLY master.sys.dm_exec_sql_text(ec.most_recent_sql_handle) AS s
			JOIN   master.sys.dm_os_waiting_tasks AS owt ON ost.session_id = owt.session_id
			AND    owt.wait_duration_ms > 0
			JOIN   master.sys.dm_exec_requests AS er ON ost.session_id = er.session_id
			AND    er.percent_complete > 0
			ORDER BY ost.session_id		
			
	- Every node also has its own Resource Monitor, which a hidden scheduler manages (you can see the hidden schedulers in sys.dm_os_schedulers). Each Resource Monitor has its own SPID, which you can see by querying the sys.dm_exec_requests and sys.dm_os_workers DMVs:
		SELECT session_id,
		CONVERT (varchar(10), t1.status) AS status,
		CONVERT (varchar(20), t1.command) AS command,
		CONVERT (varchar(15), t2.state) AS worker_state
		FROM sys.dm_exec_requests AS t1
		JOIN sys.dm_os_workers AS t2
		ON t2.task_address = t1.task_address
		WHERE command = 'RESOURCE MONITOR';
		
	- This view returns one row per scheduler in SQL Server.
		sys.dm_os_schedulers
		
	- This view returns a row for every worker in the system.
		sys.dm_os_workers
		
	- This view returns a list of all SQLOS threads running under the SQL Server process. 
		sys.dm_os_threads
		
	- This view returns one row for each task that is active in the instance of SQL Server.
		sys.dm_os_tasks
		sys.dm_os_waiting_tasks

-- Исполнить команду по всем базам (недокументированная)
	sp_msForEachDB @command1= 'SELECT @@VERSION'
	- Лучше добавить 
		sp_msForEachDB @command1= 'USE [?]; SELECT @@VERSION'
	- если нужно исполнить процедуру, то не забываем писать 'exec'

-- Исполнить команду по всем таблицам
	sp_MSForEachTable
	
-- Посмотреть текст процедуры
	sp_helptext
	
	- Аналог но через SELECT 
		SELECT object_definition (object_id('sys.tables'));
		
	-- Аналог через запрос
		SELECT * FROM sys.sql_modules
		SELECT object_name(object_id),* FROM sys.sql_modules WHERE definition like '%calchotelprice%'
	
-- Посмотреть параметры процедуры, таблицы, объекта
	sp_help (можно выделить нужный объект и нажать ALT+F1)
	
-- Посмотреть информацию о файлах текущей БД/расположение файлов БД	
	sp_helpfile
	
-- Пользователи, утратившие связь с учетной записью/потерянные пользователи
	USE Arttour
	GO
	sp_change_users_login @Action='Report';
	GO
	-- То же самое, только по всем базам
		sp_msForEachDB @command1= 'sp_change_users_login @Action=''Report''' 

-- Файл подкачки
	- Размер файла подкачки Windows в случае размещения на сервере только SQL Server не играет такой важной роли, как в типовых сценариях. SQL Server старается избегать листания. Размер файла подкачки можно выбрать небольшим, чтобы его было достаточно для формирования мини-дампов. Если сервер также обслуживает приложения, которые нуждаются в файле подкачки, размер его стоит выбирать в полтора раза больше, чем размер физической памяти сервера, но не более 50Гб.
	- Располагайте подальше от файлов данных, чтобы не было конкуренции за ресурсы
 
-- Страница в mssql/ms sql
	- Состоит 8 кб страница (8096 байт)

-- Однопользовательский режим/single user
net stop msssqlserver -- Останавливаем MSSQL
net start mssqlserver /m -- Запускаем в однопользовательском режиме
sqlcmd -e -- Подключаемся к серверу от имени локального админа. Чтобы это сработало, надо дать пользователю права "serveradmin"
RESTORE DATABASE master FROM DISK = 'C:\master.bak' WITH REPLACE -- Восстанавливаем системную базу
GO
net start msssqlserver -- Запускаем MSSQL

-- Если хотим добавить нового админа/восстановление админа/утеря админа
		net stop msssqlserver -- Останавливаем MSSQL
		net start mssqlserver /m -- Запускаем в однопользовательском режиме
		sqlcmd - e -- Подключаемся к серверу от имени локального админа
	- Добавить объект безопасности Windows (локального или доменного пользователя или группу) в базу данных пользователей SQL Server
		CREATE LOGIN [builtin\администраторы] FROM WINDOWS;
		GO;
	- Назначить этому пользователю права администратора SQL Server’a
		EXEC sp_addsrvrolemember 'builtin\администраторы', 'sysadmin';
		GO;

-- Если админ SQL утерян
	В службах найти SQL Server > Свойства > Параметры запуска > -m. Запущенный таким образом SQL-сервер
	позволит подключиться локальному администратору независимо от настроек аутентификации.
	
-- Параметры запуска
	- g 512 (Определяет объем памяти в мегабайтах (МБ), которую SQL Server будет оставлять другим приложениям внутри процесса SQL Server, но за пределами пула памяти SQL Server. Память за пределами пула памяти является областью, используемой SQL Server для загрузки элементов, например DLL-файлов расширенных процедур, поставщиков OLE DB, на которые ссылаются распределенные запросы, и объектов автоматизации, на которые ссылаются инструкции Transact-SQL. Значение по умолчанию — 256 МБ.
	Этот параметр может помочь при настройке выделения памяти, но только в том случае, если объем физической памяти превышает предел, установленный операционной системой для виртуальной памяти, доступной для приложений. Использование данного параметра может быть целесообразным в конфигурациях с большим объемом памяти, в которых требования SQL Server к использованию памяти являются нетипичными и виртуальное адресное пространство процесса SQL Server используется в полной мере. Неверное использование этого параметра может привести к появлению условий, при которых экземпляр SQL Server не будет запущен или может вызвать ошибки времени выполнения.
	Используйте значение параметра -g по умолчанию, только если в файле журнала ошибок SQL Server не присутствуют следующие предупреждения:
	«Ошибка виртуального выделения байтов: FAIL_VIRTUAL_RESERVE <размер>»
	«Ошибка виртуального выделения байтов: FAIL_VIRTUAL_COMMIT <размер>»
	Эти сообщения могут свидетельствовать о попытках SQL Server освободить часть пула памяти SQL Server, чтобы выделить пространство для таких элементов, как DLL-файлы расширенных хранимых процедур или объекты автоматизации. В этом случае рассмотрите возможность увеличения размера памяти, зарезервированной ключом -g.
	Если используемое значение меньше значения по умолчанию, объем памяти, доступной пулу ресурсов, управляемому диспетчером памяти SQL Server, и стекам потоков, увеличивается. В свою очередь увеличивается производительность требовательных к памяти рабочих нагрузок в системах, не использующих большое количество расширенных хранимых процедур, распределенных запросов и объектов автоматизации.)
		
-- Удаление всех актиных сеансов базы/отключение всех пользователей от базы
DECLARE @spid VARCHAR(200)
DECLARE @kill_spid VARCHAR(200)

DECLARE kill_session CURSOR FOR

SELECT spid FROM [master].dbo.sysprocesses
WHERE dbid=db_id('NameDB') --and spid != 14 --(указать)

-- spid
	- In SQL Server 2012, a SPID isn’t bound to a particular scheduler. Each SPID has a preferred scheduler, which is one that most recently processed a request from the SPID. The SPID is initially assigned to the scheduler with the lowest load.
	- One restriction is that all tasks for one SPID must be processed by schedulers on the same NUMA node. The exception to this restriction is when a query is being executed as a parallel query across multiple CPUs. The optimizer can decide to use more available CPUs on the NUMA node processing the query so that other CPUs (and other schedulers) can be used.
	- идентификатор сеанса SQL Server.
		OPEN kill_session;

		FETCH NEXT FROM kill_session INTO @spid
		WHILE @@FETCH_STATUS = 0

		BEGIN

		   SET @kill_spid='KILL ' + @spid + char(10)
		   --PRINT @kill_spid
		   EXEC (@kill_spid)
		   
		 FETCH NEXT FROM kill_session
		 INTO @spid;
		END;
		 DEALLOCATE kill_session;

-- Как долго осталось до завершении операции по spid
	- Use it for:  BACKUP \ RESTORE, DBCC CHECKDB , DBCC CHECKTABLE,DBCC SHRINKDB , dbcc SHRINKFILE,DBCC INDEXDEFRAG,ALTER INDEX REORGANIZE, ROLLBACK
	
	SELECT session_id,percent_complete,DATEADD(MILLISECOND,estimated_completion_time,CURRENT_TIMESTAMP) Estimated_finish_time,
	(total_elapsed_time/1000)/60 Total_Elapsed_Time_MINS ,
	DB_NAME(Database_id) Database_Name ,command,sql_handle
	FROM sys.dm_exec_requests WHERE session_id=58
 
-- Убить процесс
	- KILL
	- KILL <spid> WITH STATUSONLY -- Посмотреть как долго ещё будет идти убивание процесса
	
-- Scheduler
	- You can think of the SQL Server scheduler as a logical CPU used by SQL Server workers.
	- Посмотреть загрузку расписаний
		SELECT load_factor,* FROM sys.dm_os_schedulers
 
 -- Вставка автоинкремента/IDENTITY/Идентификатор/Инкремент/Уникальный идентификатор/increment
 SET IDENTITY_INSERT MyTable ON
 GO
 INSERT INTO MyTable(ID_Employee,vchLogin,vchDuties,intAccessRights,bitActual) VALUES (0,'net','Нет',0,0)
 GO
 SET IDENTITY_INSERT MyTable OFF	

-- Настройка контактной зоны 
- пкм на сервере > Facets > выбрать Surface Area Configuration

-- Для просмотра планов выполнения используем
	1. SSMS (неудобно)
	2. SQL Sentry Plan Explorer (хороший инструмент)
	
-- Key Lookup 
	- Указывает, что запрос может выиграть от настройки производительности. Например, производительность запроса можно повысить, добавив покрывающий индекс (чтобы включал и столбцы в предикате и столбца вывода)
	
	- Поиск запросов с Key Lookup
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
		WITH XMLNAMESPACES
		   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
		SELECT
			n.value('(@StatementText)[1]', 'VARCHAR(4000)') AS sql_text,
			n.query('.'),
			i.value('(@PhysicalOp)[1]', 'VARCHAR(128)') AS PhysicalOp,
			i.value('(./IndexScan/Object/@Database)[1]', 'VARCHAR(128)') AS DatabaseName,
			i.value('(./IndexScan/Object/@Schema)[1]', 'VARCHAR(128)') AS SchemaName,
			i.value('(./IndexScan/Object/@Table)[1]', 'VARCHAR(128)') AS TableName,
			i.value('(./IndexScan/Object/@Index)[1]', 'VARCHAR(128)') as IndexName,
			i.query('.'),
			STUFF((SELECT DISTINCT ', ' + cg.value('(@Column)[1]', 'VARCHAR(128)')
			   FROM i.nodes('./OutputList/ColumnReference') AS t(cg)
			   FOR  XML PATH('')),1,2,'') AS output_columns,
			STUFF((SELECT DISTINCT ', ' + cg.value('(@Column)[1]', 'VARCHAR(128)')
			   FROM i.nodes('./IndexScan/SeekPredicates/SeekPredicateNew//ColumnReference') AS t(cg)
			   FOR  XML PATH('')),1,2,'') AS seek_columns,
			i.value('(./IndexScan/Predicate/ScalarOperator/@ScalarString)[1]', 'VARCHAR(4000)') as Predicate,
			cp.usecounts,
			query_plan
		FROM (  SELECT plan_handle, query_plan
				FROM (  SELECT DISTINCT plan_handle
						FROM sys.dm_exec_query_stats WITH(NOLOCK)) AS qs
				OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) tp
			  ) as tab (plan_handle, query_plan)
		INNER JOIN sys.dm_exec_cached_plans AS cp 
			ON tab.plan_handle = cp.plan_handle
		CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/*') AS q(n)
		CROSS APPLY n.nodes('.//RelOp[IndexScan[@Lookup="1"] and IndexScan/Object[@Schema!="[sys]"]]') as s(i)
		OPTION(RECOMPILE, MAXDOP 1);

-- функции MS SQL
	- Если функция начинается с BEGIN и заканчивается END, то SQL сервер считает что она всегда возвращает 1 запись
	- http://msdn.microsoft.com/ru-ru/library/ms173823.aspx	
	- Если функция не возвращает данные, то используйте WITH SCHEMABINDING

-- Статистические системные функции
- Следующие серверные функции позволяют DBA в реальном масштабе времени получать статистическую информацию о производительности MS SQL Server:
@@cpu_busy - возвращает время в миллисекундах со времени последнего запуска сервера, которое процессор потратил на свою работу.
@@io_busy - возвращает время в миллисекундах со времени последнего запуска сервера, которое SQL Server потратил на выполнение операций ввода - вывода.
@@idle - возвращает время в миллисекундах со времени последнего запуска сервера, которое SQL Server простаивал.
@@pack_sent - возвращает число отправленных в сеть SQL сервером пакетов, со времени последнего запуска сервера.
@@pack_received - возвращает число полученных SQL сервером из сети пакетов, со времени последнего запуска сервера.
@@packet_errors - возвращает число ошибок сетевых пакетов, которые произошли при подключении к серверу баз данных, со времени последнего запуска сервера.
@@total_read - возвращает число операций дискового чтения, выполненных SQL сервером со времени последнего запуска.
@@total_write - возвращает число операций записи на диск, выполненных SQL сервером со времени последнего запуска.
@@total_errors - возвращает число ошибок операций чтения/записи с дисков, которые выполнял SQL сервер со времени последнего запуска сервера.
@@connections - возвращает число подключений (или их попыток) к SQL Server, со времени последнего запуска сервера.
@@VERSION - версия SQl
@@LOCK_TIMEOUT - Время ожидания времени ожидания блокировки в миллисекундах для текущего сеанса
@@MAX_CONNECTIONS - Максимально возможно количество подключенных пользователей
@@NESTLEVEL - Возвращает уровень вложенности выполняющейся в данный момент хранимой процедуры (изначально равен 0).
@@SERVERNAME - Возвращает имя локального сервера, на котором выполняется SQL Server. 
@@SERVICENAME - Имя экземпляра
@@SPID - Возвращает идентификатор сеанса для текущего пользовательского процесса.


 SELECT * FROM fn_virtualfilestats(DB_ID(N'Arttour'),NULL)  - Возвращает статистику ввода-вывода для файлов базы данных, включая журналы транзакций/информация о размере файлов базы/размер файлов базы
 
 --Именованный экземпляр
 .\SQLSERVER
 "<имя_компьютера>"
"<имя_компьютера>\<имя_экземпляра>" для именованного экземпляра
"(local)"
"(local)\<имя_экземпляра>" для именованного экземпляра
"Localhost"
"localhost\<имя_экземпляра>" для именованного экземпляра
Точка: "."
".\<имя_экземпляра>" для именованного экземпляра
 
--DAC (http://msdn.microsoft.com/ru-ru/library/ms189595(v=sql.100).aspx)
	- By default, the DAC is available only locally
	- The user login to connect via the DAC must be a member of the sysadmin server role
	- Не все команды могут быть выполнены в DAC
	- Задания в DAC режиме имеют максимальный приоритет
	- Чтобы подключиться в DAC режиме, надо полностью отключиться от сервера -> нажать новый запрос -> ввести ADMIN:Имя Инстанса (Его можно посмотреть либо в службах или @@ServiceName)
	- Чтобы разрешить клиентским приложениям на удаленных компьютерах подключение DAC, используйте параметр remote admin connections хранимой процедуры sp_configure.
		sp_configure 'remote admin connections', 1;
		GO
		RECONFIGURE;
		GO
		
	SQLCMD - A
	ADMIN:SERVERNAME
	ADMIN:SERVERNAME\INSTANCENAME
		
	- Поиск активных DAC
		SELECT s.session_id
		FROM sys.tcp_endpoints as e
		INNER JOIN sys.dm_exec_sessions as s
		ON e.endpoint_id = s.endpoint_id
		WHERE e.name=N'Dedicated Admin Connection';		

-- DAC (data-tier application)		
	- Позволяет регулировать простое обновление системы, версионность
	- Требуется создать проект и развернуть его на сервере. Готовое решение отсутствует

-- Запрос вернёт, подключён ли кто-то в данном режиме
select * from sys.dm_exec_connections ec join sys.endpoints e on (ec.endpoint_id=e.endpoint_id) where e.name='Dedicated Admin Connection' and session_id=@@spid

--Запрос к Linked Server/ODBC:
	SELECT * FROM linked_server_name.database.schema.tables
	SELECT * FROM linked_server_name...tables -- Для Access, так как нет имени каталога и имени схемы
	SELECT * FROM inked_server_name..schema.tables -- Для Oracle
	
	-- CHECKDB удалённого сервера/CHECKDB linked server/checkdb remote server/удалённый сервер/вызов процедуры на удалённом сервере
		 SERVER_MOR.master.dbo.sp_executesql N'dbcc checkdb(''master'')'
	
	-- Зарегистрировать провайдеров
		exec master.dbo.sp_MSset_oledb_prop 'ORAOLEDB.Oracle', N'AllowInProcess', 1
		exec master.dbo.sp_MSset_oledb_prop 'ORAOLEDB.Oracle', N'DynamicParameters', 1

-- Все триггеры таблицы
select object_name(parent_obj) as 'Таблица', [name] as 'Триггер' from sysobjects where xtype = 'tr' order by 1,2 

select * from sys.dm_exec_connections -- Как подключены spid

--Временные таблицы:
	# - локальные (видны только текущему соединению пользователя и удаляются, когда пользователь отключается от экземпляра SQL Server)
	## - глобальные (видны любому пользователю и удаляются, когда все пользователи, которые на них ссылаются, отключаются от экземпляра SQL Server)	
	@ - таблицы в "памяти" (табличые переменные) (declare @tabName table(id int,description nvarchar(50))) 
		-- Табличная переменная
			1. Не хранится в памяти, данные хранятся в tempdb. Однако это облегчённая версия временных таблиц
			2. Нет поддержки индексов за исключением первичных и уникальных ключей
			3. Нет поддержки транзакций
			4. Нет поддержки статистики. SQL Server всегда считает что в табличной переменной всегда 1 запись, но если мы сделаем RECOMPILE в запросе, то SQL Server может правильно оценить количество строк, но гистограммы (какие там внутри значения) всё равно не будет, это значит что он оценит частично верно
				-- Используйте табличные переменные если отсутсвие статистики не повлияет на выполнение запросов
					1. Небольшой объём данных
					2. Отсутствие соединений
					3. План выполнение - полное сканирование или получение единичной записи
			
	@@ - глобальная таблица в памяти
		- Не используйте табличные переменные для хранения больших объемов данных (более 100 строк)
		- При изменении очень больших переменных table или переменных table в сложных запросах может
		  снизиться производительность
		- На переменных table нельзя создавать индексы и статистику
		- Поскольку переменные table имеют ограниченную область действия и не являются частью постоянных
		  баз данных, они не изменяются в случае откатов транзакций.
		- Табличные переменные нельзя изменить после их создания.
		- Рекомендуется использовать, когда соображения повторной компиляции являются доминирующими
		- Обычно их следует использовать в запросах с соединениями, решениях в отношении параллелизма
		  и при выборе индекса.
		- Переменная table ведет себя как локальная переменная.Она имеет точно определенную область
		  применения.Это функция, хранимая процедура или пакет, в котором она объявлена.
		- При использовании в хранимых процедурах переменных table приходится прибегать к повторным
		  компиляциям реже, чем при использовании временных таблиц в случае отсутствия необходимости 
		  осуществлять выбор, основанный на стоимости, который влияет на производительность. Вследствие
		  этого, они не должны использоваться при необходимости осуществления выбора с учетом затрат
		  для получения эффективного плана запроса.
		- Транзакции с использованием переменных table продолжаются только во время процесса обновления
		  соответствующей переменной table.Поэтому переменные table реже подвергаются блокировке
		  и требуют меньших ресурсов для ведения журналов регистрации.

		- Пример:
			DECLARE @MyTableVar table(
			EmpID int NOT NULL,
			OldVacationHours int,
			NewVacationHours int,
			ModifiedDate datetime);
	-- Table-valued параметры (TVP)
		- Передача набора записей через параметр в t-sql объекты (процедур, динамический sql)
	- Локальные могут называться одинаковыми именами разными пользователями, и обращаться каждый к своей, но такой способо не работает с constraint
	- Локальная временная таблица, созданная хранимой процедурой, удаляется автоматически при завершении хранимой процедуры. К этой таблице могут обращаться любые вложенные хранимые процедуры, выполняемые хранимой процедурой, создавшей таблицу. Процесс, вызвавший хранимую процедуру, создавшую таблицу, к этой таблице обращаться не может.
	-- Проверить существование локальной временной таблицы
		IF Object_ID(N'Tempdb..#Table1',N'U') IS NULL
			SELECT 'Таблицы с выбранным именем нет'	
	-- Поиск временных таблицы
		SELECT * FROM TempDb.sys.Tables
		SELECT * FROM TempDB.Information_Schema.Tables

-- Советы по локальным временным таблицам:
	1. Удалять их в конце процедуры
	2. Не задавать явно constaint, тогда SQL сам будет присваивать произвольные имена, что не позволит вызвать дуюликата несколько одинаковых процедур в одной транзакции.


Обязательно указать windows, чтобы отдавал предпочтение не сервисам, а программам - пкм Мой компьютер - быстродействие

SELECT *
FROM sys.tables t INNER JOIN sys.columns

Обязательная настройка оповещений.

-- Информация обо всех базах/размер бд/размер всех бд
	exec sp_helpdb 
	
-- Информация о системе/системная информация/версия сервера
	exec sp_server_info
	
-- Посмотреть размер БД в контексте конкретной БД
	sys.database_files
	
-- Общий размер БД/размер всех бд/размех всех баз данных
    select SUM(size * 8.0 / 1024) size
    from sys.master_files
	
-- Занимаемый размер БД по дискам
	select SUBSTRING(physical_name,0,2), SUM(size * 8.0 / 1024) as [Size, Mb]
	from sys.master_files
	GROUP BY SUBSTRING(physical_name,0,2)

-- Размер объекта БД	
	exec sp_spaceused - информация по базе(размеры бд, индексов и иные)
		-- reserved - Общий объем пространства, выделенный объектам в базе данных.

	EXEC xp_readerrorlog -- Посмотреть лог ошибок серера
	sys.dm_tran_database_transactions  -- Возвращает сведения о транзакциях на уровне базы данных.
	select * from sys.indexes
	select * from key_constaints
	select * from sys.foreign_keys
	select * from sys.foreign_keys_columns
	Размер БД мог сильно вырости после перестроении индексов
	BACKUP LOG имя_базы_данных TO <устройство_резервного_копирования>WITH CONTINUE_AFTER_ERROR - если база повреждена

	with recompile для временных таблиц и представлений данных

	-- Размер файла лога
		1. DBCC SQLPERF (LOGSPACE) -- реальное использование файлов логов баз
		2. SELECT instance_name as [Database],
			cntr_value as "LogFullPct"
			FROM sys.dm_os_performance_counters
			WHERE counter_name LIKE 'Percent Log Used%'
			AND instance_name not in ('_Total', 'mssqlsystemresource')
			AND cntr_value > 0;
	
-- sp_dboption
	- Обновление/Изменение настрое базы данных
	- sp_dboption DBName, 'auto update statistics', 'off';
	- Чтобы посмотреть что влючено на БД	
		- sp_dboption DBName
	
-- Условия, лишения плана законной силы и создания момента перекомпиляции (The conditions that invalidate a plan include the following:)
	
	Changes made to a table or view referenced by the query (ALTER TABLE and ALTER VIEW).
	Changes made to a single procedure, which would drop all plans for that procedure from the cache (ALTER PROCEDURE).
	Changes to any indexes used by the execution plan.
	Updates on statistics used by the execution plan, generated either explicitly from a statement, such as UPDATE STATISTICS, or generated automatically.
	Dropping an index used by the execution plan.
	An explicit call to sp_recompile.
	Large numbers of changes to keys (generated by INSERT or DELETE statements from other users that modify a table referenced by the query).
	For tables with triggers, if the number of rows in the inserted or deleted tables grows significantly.
	Executing a stored procedure using the WITH RECOMPILE option.

http://msdn.microsoft.com/ru-ru/library/ms143506(SQL.105).aspx#SE32 - совместимость SQL SERVER
http://support.microsoft.com/kb/307487/ru - Уменьшение размера tempdb
http://msdn.microsoft.com/ru-ru/library/ms162819.aspx - Sqlservr(можно запускать через net start mssqlserver /m - /m то же самое что и -m через sqlservr.exe)

SELECT User_name() -- Показывает текущего юзера
SELECT Current_User -- Субъект уровня базы
SELECT SYSTEM_USER -- Показывает имя текущего пользователя
SUSER_NAME() -- Имя пользователя
HOST_NAME() -- Показывает имя компа/хоста

SELECT *
FROM   inc_out..Income -- Выбрать таблицу из другой базы

$(Name) --Макро подстановки/параметры

--CMD
	SQLCMD -S HOU-SQL-01 -E--(Логиниться с виндоывм паролем к серверу)
	далее -i "C:\....\My First Query.txt"--Где лежит запрос
	-i "C:\....\My First Query.txt" > C:\...Result.txt --Перенаправление вместо > можно -o
	SQLCMD -S HOU-SQL-01 -E -i "C:\....\My First Query.txt" -v TableName="Sys.Databases" ColumnName=Name --Чтобы запустить скрипт с макромараметрами
	go -- выполнить команду в cmd
	
	-- Назначение прав на папку и всё её содержимое
		cacls "R:\SIEM\SQL Server" /t /e /g "fs01.vwf.vwfs-ad\DKX4S42582":f

--Посмотреть все БД
SELECT * FROM sys.Databases

--Базы:
	-- model
		- С неё создаются все новые БД, образец
		-- The following operations cannot be performed on the model database:
			Adding files or filegroups.
			Changing collation. The default collation is the server collation.
			Changing the database owner. model is owned by sa.
			Dropping the database.
			Dropping the guest user from the database.
			Enabling change data capture.
			Participating in database mirroring.
			Removing the primary filegroup, primary data file, or log file.
			Renaming the database or primary filegroup.
			Setting the database to OFFLINE.
			Setting the primary filegroup to READ_ONLY.
			Creating procedures, views, or triggers using the WITH ENCRYPTION option. The encryption key is tied to the database in which the object is created. Encrypted objects created in the model database can only be used in model.

Reverse(параметр) --Написать наоборот, перевернуть текст

--Перенос базы с диска на диск
1. Detach&Attach
2. a) Перераспределить данные из желаемого файла в другие с помощью Shrink>File>Empty fule by migrating...
   б) Зайди в свойство базы>Files>Remove(нужную файловую группу)
   в) Не работает если у вас 1 фаил с данными(*.mdf)

--Резеврное копирование. Критерии стратегий:
1. Место на диске
2. Точность резервирования
3. Скорость восстановления
4. Скорость резервирования
5. Простота стратегии
--------------------------------------------
--Обазятальено обеспечить:
1. Безопасность(шифровать, охрана...)
2. Место хранения.Off-site Location(Бэкапы храним рядом с сервером, но раз в неделю копируем дальше от него, для надёжности)
3. План восстановления
4. Тестовое восстановление. Тестирование
--------------------------------------------
--Стратегии:
1. Full бэкап. Копия всей БД.
2. Diff(скорость). Дифференциальная/Разностная. Только то, что изменилось с последнего полного Бэкапа. Если Бэкап был вчера то за сегодня, позавчера - с понедельника и так далее. Поэтому надо делать полный Бэкап периодично, так как процесс пойдёт заного и изменения будут вноситься с момента последнего бэкапа.
3. INC(точность). Инкрементальная/Добавочная/Транзакционная. От полного бэкапа, к последнему INC бэкапу. При восстановлении надо будет восстановить основную базу и все последующие INC бэкапы. Делает бэкап журнала транзакций(логов). Требует Full журналирование
4. Comb(точность+скорость). Комбинированный. Втечении дня INC, в конце дня Diff, в конце недели Full. Поднять надо будет Full, последний Dif, все INC между Dif

-- Название и остальные данные сделанных backup`ов/история backup
SELECT * FROM msdb.dbo.backupset

-- История job
	select * from msdb..sysjobhistory

--Показать все бэкапы
RESTORE HEADERONLY
	FROM DISK='Full.bak'
--Восстановить первую базу в списке	
RESTORE DATABASE Test1
	FROM DISK='Full.bak'
	WITH FILE=1
--Восстановить первую базу в списке и оставить базу в блоке, для дальнейшего восстановления
RESTORE DATABASE Test1
	FROM DISK='Full.bak'
	WITH FILE=1, NORECOVERY
-- Восстановление с перемещением файлов
RESTORE DATABASE Test1
	FROM DISK='Full.bak'
	WITH FILE=1, NORECOVERY,
	MOVE 'AdventureWorks2012_Data' TO 'C:\MySQLServer\testdb.mdf'


--Если случайно написали лишний NORECOVERY, то следующая команда переведёт базу в нормальное состояние
RESTORE LOG/DATABASE WITH RECOVERY 
--Завершение восстановления
RESTORE DATABASE Test1
	FROM DISK='Full.bak'
	WITH FILE=3, RECOVERY
--Diff
BACKUP DATABASE Test1
	TO DISK='Full.dif'
	WITH DIFFERENTIAL

-- Восстановить DIF
	RESTORE DATABASE Arttour_test
	FROM DISK='D:\Backups\Bak.bak'
	WITH FILE=1, NORECOVERY	
	GO
    RESTORE DATABASE Arttour_test
    FROM DISK='D:\Backups\DIF.dif'
	WITH FILE=1, RECOVERY
	GO
	
-- Восстановить с потерей данных из лога
	WITH REPLACE

--Восстановление данных после последнего INC, то есть те операции, что были сделаны после INC
 RESTORE LOG Test1
	FROM DISK='Full.bak'
	WITH NO_TRUNCATE
	
--Восстановление данных между двумя INC(в последнем написать следующее)
	- Чтобы этим воспользоваться надо снять хвостовой бэкап (параметр NORECOVERY)
	 (BACKUP LOG [Petition] TO  DISK = N'd:\petition.INC' WITH NORECOVERY)
	- Можно восстановить через интерфейс, нажав в восстановлении 'To a point in time'
	RESTORE DATABASE Test1
		FROM DISK='Full.bak'
		WITH FILE=3, RECOVERY,
		STOPAT='2010-04-21 14:52' -- Иногда надо указывать вот так STOPAT=N'2013-04-26T14:47:03' 
		
-- Сделать backup log если бд повреждена
	- Случай, когда сервер доступен
		BACKUP LOG [DBMaint2008] TO DISK = N'D:\SQLskills\DemoBackups\DBMaint_Log_Tail.bck' WITH INIT, NO_TRUNCATE;
	- Случай, когда сервер не достуупен		
		- Не будет работать если новый сервер меньшей версии
		1. Create a dummy database with the same name as the one that we’re interested in (make sure you have instant file initialization enabled so the file creations don’t take ages)
		2. Set the database offline (or shutdown the server)
		3. Delete all the files from the dummy database
		4. Drop in the log file from our real database
		5. Подложите нужный лог и теперь воспользуйтесь случаем, когда сервер доступен
	- Случай когда БД надо перевести в Restoring (Создает резервную копию остатка журнала и оставляет базу данных в состоянии RESTORING)	
		BACKUP LOG database_name TO <backup_device> WITH NORECOVERY

-- Если была авария во время восстановления, то надло использовать RESTART
RESTORE DATABASE AdventureWorks2012
   FROM AdventureWorksBackups;
RESTORE DATABASE AdventureWorks2012 
   FROM AdventureWorksBackups WITH RESTART;
   
-- Копирование базы данных с помощью BACKUP и RESTORE
BACKUP DATABASE AdventureWorks2012 
   TO AdventureWorksBackups ;
RESTORE FILELISTONLY 
   FROM AdventureWorksBackups ;
RESTORE DATABASE TestDB 
   FROM AdventureWorksBackups 
   WITH MOVE 'AdventureWorks2012_Data' TO 'C:\MySQLServer\testdb.mdf',
   MOVE 'AdventureWorks2012_Log' TO 'C:\MySQLServer\testdb.ldf';
   
-- Создание девайся для backup
	EXEC master.dbo.sp_addumpdevice 'disk', 'mydiskdump', 'c:\dump\dump1.bak';
		  
--II.Безопасность/Права доступа
1. Аутентификация
2. Авторизация
3. Шифрование
-----
Владеть можно схемой, а в схеме уже будут права
-----
4. Аудит

-- dbo use only
	- Разрешает подключаться к бд только dbo_owner и серверная роль sysadmin	
	sp_dboption [ADMIN_SITE],'dbo use only', true

--Факторы
1. Список доступа(DACL)
	- Уровня сервера (пкм, на сервере)
	- Уровня БД (субъектами являются user`ы базы)
	- Уровень схемы
	- Объект (таблица, View, хранимая процедура)
	- Если работаем с таблицей и View можно дать права на столбцы, работает только с SELECT/UPDATE
	(в настройках таблицы > permissions > Column Permissions)
2. Роли БД (Database Role)
3. Роль приложения (Application Role)
4. Делегирование (WITH GRANT)	
5. "Наследование"
	- Если даём права на базу, то на таблицу внутри базы права будут автоматически, если не запретим
6. Владение(OWNER)
	- Доп. преимущества владения объектом. Может сделать всё что угодно с объектом. Права не нужны.
	- Начиная с 2005 нельзя владеть объектом, можно владеть схемой
	- Владельцами лучше не делать пользователей.
7. Явный запрет (DENY)
8. Цепочка владения (Ownership chain)(Часто спрашивают на собеседовании)
- Ситуация, когда пользовать имеет правна на процедуру, но не имеет права на SELECT в ней
	1. Когда надо прикинуться чтобы не сработало (администратор)
		- Данные очень важны и в списке доступа никого нету
		- Но если, схема сработает, то мне надо смотреть ещё и все процедуры?
	2. Когда надо прикинуться чтобы сработало (разработчик)
		- База большая, со множеством данных и процедур, разбираться лень
		- Я нахожу процедуру добавления клиента и хочу дать на неё доступ пользователю, чтобы не разбирать
		её и не смотреть куда она там обращается
		- Если я исследую процедуру и дам везде права, то будет не логично, так как я хочу разрешить
		одно действие, а даю права на другое. Получается непрозрачная схема управления безопасности
- Правила:
	
-----------------------------------2000 Server-------------------------------
- 2(1) Означает, что это исключение из правила 1
	1. 		Не сработает(все владельцы разные)
	2(1). 	'Цепочка владения'(Если есть права на процедуру, а у процедуры и нужных таблиц один
	owner, тогда срботает. Права пользователя на SELECT даже не проверяются). При этом страдает
	безопастность. Когда разные базы, но owner один и в одной базе он admin, а в другой пользователь,
	тогда там где он admin, я могу написать любую процедуру, поэтому есть 3(2)
	3(2). 'Разрыв цепочки владения на границе БД'(Так как если я администратор на одной базе, то я могу написать любую процедуру и обратиться с неё на другую базу, где я владелец, но являюсь обычным пользователем)	
	4(3). Активировать галочку "Межбазовые цепочки владения"(Можно разрещить либо на всём сервере
	в разделе Security, либо в базе - 'Cross databases ownership chain'. Если ставить на уровне базе, 
	то ставим на базе назначения, потому что она находится под угрозой)
	5(2). Динамические запросы разрывают ц.в.
-----------------------------------2005 Server-------------------------------
	6(5) (способ для борьбы с динамичесиким запросами). Смена контекста исполнения(процедуру
		  запускает один человек, а права проверяется для другого)
			- WITH EXECUTE AS CALLER (то, что было в по дефелту 2000 SERVER). Указывает, что инструкции, содержащиеся в модуле, выполняются в контексте пользователя, вызывающего этот модуль. Пользователь, выполняющий модуль, должен иметь соответствующие разрешения не только на сам модуль, но также и на объекты базы данных, на которые имеются ссылки из этого модуля. Ключевое слово CALLER не может быть указано в инструкции CREATE QUEUE или ALTER QUEUE.
			- WITH EXECUTE AS OWNER (Указывает, что инструкции, содержащиеся в модуле, выполняются в контексте текущего владельца этого модуля. Если для модуля не определен владелец, то подразумевается владелец схемы модуля. Ключевое слово OWNER не может указываться для триггеров DDL или триггеров входа.)
			- WITH EXECUTE AS 'T.Larina' (права проверяются для T.Larina)
			- WITH EXECUTE AS SELF (то же самое что и EXECUTE AS 'T.Larina', но вместо 'T.Larina' подставляется создатель процедуры. Используется если программа сама создаёт процедуры	и сама же их вызывает, но не знает под каким акком она работает. Чтобы посмотреть данную опцию, надо заглянуть в sys.sql_modules или в sys.service_queues, найдя там столбец execute_as_principal_id)

-- Default schema
- Где сервер будет искать таблицы, если схема не указано

-- Schema
	- Меня схему таблицы очень плохо, потому что:
		1. Сбрасывается список доступа
		2. Другое название таблицы
		3. Таблица подводится под другого владельца
	ALTER SCHEMA Products Transfer DBO.TableX -- Поменять схему с DBO на Transfer

	- Посмотреть владельцев схем
		SELECT s.name AS [schema_name], dp1.name AS [owner_name]
		FROM sys.schemas AS s
		INNER JOIN sys.database_principals AS dp1 ON dp1.principal_id = s.principal_id

	- Сменить владельца схемы
		ALTER AUTHORIZATION ON SCHEMA::[apps] TO [dbo] -- Владельцем схемы apps становится dbo
		
	- Именование Схем
		- Нет смысла называть схемы, как системные объекты в схеме sys.*, так как сначала будет произведена проверка системной таблицы и до вашей дело не дойдёт
			
--Логины/Credential
- Security>Credential -- Уровень сервера
- Proxies -- Уровень SQL Agent
- логин/пароль для вызова других функций за пределеами SQL SERVER
--Запустить программу от имени пользователя
RunAS /User:"MRSC\DZAytsev" cmd
--Подключиться к MS SQL с использованием текущего полльзователя на компе
sqlcmd -S IFOS -E
--Применение Application Roles
- Самое главное мы переходим от аутентификации пользователя, к аутентификации ролей
- Они имеют доступ к другим базам данных только с разрешениями guest 
- В отличие от ролей баз данных, роли приложений не содержат элементов и по умолчанию
находятся в неактивном состоянии
- В базе права раздаются только Application Roles
EXECUTE sp_SetAppRole 'FrontOffice','Pa$$w0rd'
--Посмотреть пользователей уровня сервера и БД
SELECT *
FROM   Sys.Server_Principals
SELECT *
FROM   Sys.Database_Principals
----Посмотреть права уровня сервера и БД
SELECT *
FROM   Sys.Server_Permissions
SELECT *
FROM   Sys.Database_Permissions

--Шифрование
- Для защиты базы от кражи
- Шифрование занимает много места, особенно обидно когда шифруем маленькие поля (было 4 байта, стало 200)
- Компрессия не помогает
- Где шифровать:
    1. Приложение
		1.1. Нет нагрузки на сервер БД. Серверов приложения можно создать множество.
		2.1. Раньше зашифруем - позже зашифруем - лучше защита.
	2. БД
		2.1  Уже реализованы все средства шифрования
		2.2. Медленней работает, больше места, проблемы с индексами
--Шифрование в БД(4 видео 1:15)/Keys
	1. Процедурная стратегия (2005 Server) (точно указать что шифруем, но всё это нужно
	программировать и это не просто)
		- Пароли 
			DECLARE @Text varchar(100), @Encrypted varbinary(Max)
			SET @Text = 'www.Specialist.ru'
			SET @Encrypted = ENCRYPTBYPASSPHRASE('Pa$$w0rd',@Text) -- Вместо переменной можем поставить столбец
			SELECT @Text,@Encrypted

			DECLARE @Decrypted varchar(100)
			SET @Decrypted = DECRYPTBYPASSPHRASE('Pa$$w0rd',@Encrypted)
			SELECT @Decrypted
		- Ключи (ключ шифруем паролем, а ключем шифруем данные)
			- Ключ хранится в базе (симметричный, ассиметричный, сертификат)
			- Можно подключить внешний Крипто Провайдер, который выносит шифрование на другой сервер, к
			которому не будет доступа даже у спец. служб и чтобы не гонять трафик используем только для
			расшифровки/шифровки. Этим мы шифруем симметричный ключ, например это может быть сертификат		
			- Симметричный
				- Создание
					CREATE SYMMETRIC KEY MyKey1 -- Хранится в базе
					WITH ALGORITHM = AES_256 -- алгоритм шифрования
					ENCRYPTION BY PASSWORD = 'Pa$$w0rd'
				- Использование
					OPEN SYMMETRIC KEY MyKey1 -- Открываем для шифрования
						DECRYPTION BY PASSWORD = 'Pa$$w0rd'	
					DECLARE @Text varchar(100), @Encrypted varbinary(Max)
					SET @Text = 'www.Specialist.ru'
					SET @Encrypted = ENCRYPTBYKey(KEY_GUID('MyKey1'),@Text) -- В функцию нельзя передать
																			-- объект, а ключ это объект.
																			-- Поэтому применяем KEY_GUID
					SELECT @Text,@Encrypted
					CLOSE SYMMETRIC KEY MyKey1
					------------------------------------------------------
					OPEN SYMMETRIC KEY MyKey1 -- Открываем для расшифрования
						DECRYPTION BY PASSWORD = 'Pa$$w0rd'
					
					DECLARE @Decrypted varchar(100)
					SET @Decrypted = DECRYPTBYKey(@Encrypted)-- При расшифровки надо чтобы типы данных
															 -- совпадали с тем, что было изначальное
					SELECT @Decrypted
						
					CLOSE SYMMETRIC KEY MyKey1
					------------------------------------------------------
					OPEN SYMMETRIC KEY MyKey1 -- Шифруем данные в таблице
					DECRYPTION BY PASSWORD = 'Pa$$w0rd'					
					UPDATE Employee
					SET Salary = ENCRYPTBYKey(KEY_GUID('MyKey1'),name) 
					CLOSE SYMMETRIC KEY MyKey1
				- Минусы
					1. Сложно
					2. Место много занимает
					3. Если шифруем данные в таблице, то делать по ним поиск невозможно, так как
					индексируем зашифрованные данные, а искать надо по расшифрованным
	2. Декларативная стратегия (2008 Server) (просто поставить галочку шифровать базу,
	но шифруется либо вся база, либо ничего)
		- При этом шифруется всё, даже лог/индексы, даже tempdb
		- При этом ключи никуда не деваются. Ключи хранятся в базе и попадают в backup
		- Размер может не увеличиться, увеличится эктропия
		- Свойство базы > Options > Encryption Enabled, но просто включать нельзя. Иначе ничего не
		получится (не сможем нормально зашифровать) или мы зашифруем так, что потом не расшифруем
		Как это сделать правильно:
			1. Барём/Создаём базу
			2. В базе master, нужно создать master-key
				CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Pa$$w0rd'
			3. В базе master, нужно создать сертификат
				CREATE CERTIFICATE MyCert1 WITH Subject = 'MyCert1'
			4. В нашей базе
				CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_256 ENCRYPTION BY SERVER CERTIFICATE MyCert1
			5. Только сейчас включаем шифрование базы
				ALTER DATABASE DbName SET ENCRYPTION ON
		- Как быстро сделать так, чтобы базу не вскрыл никто - удалить CERTIFICATE и лучше перезапустить сервер
			USE master
			DROP CERTIFICATE MyCert1
		- Схема работы:
			1. Данные шифруются Симметричным алгоритмом (DEK), который лежит в базе (симметричный)
			2. DEK шифруется ассиметричным ключом (CERTIFICATE), который лежит в мастере (ассиметричный)
			3. CERTIFICATE защищен master-key (один на весь сервер, симметричный)
		- Если потеряем один из 3-х верхних пунктов - базу можно выкинуть, поэтому надо backup
		master-key и CERTIFICATE
		- Восстановление на другом сервере
			- Поднимаем master-key и CERTIFICATE и потом поднимаем backup базы
			
	-- Как посмотреть ключи/Keys
		SELECT * FROM [sys].[openkeys]
		
		-- Проверить есть ли шифрование в БД
			USE [master]
			GO
			SELECT db.[name]
			, db.[is_encrypted]
			, dm.[encryption_state]
			, dm.[percent_complete]
			, dm.[key_algorithm]
			, dm.[key_length]
			FROM [sys].[databases] db
			LEFT OUTER JOIN [sys].[dm_database_encryption_keys] dm
			ON db.[database_id] = dm.[database_id];
			GO

	
-- SSIS (5 урок, 1:00:00)
- Если компонентов не хватает можно написать самим, скачать или купить
- Через пкм на стрелочке можно задать её свойства
- Toolbox
  Data Flow Task -- Регулирует все возможные перемещения данных(Сложный Task)
  Execute Process Task -- Запускает какую-то программу. Можно либо выбрать программ, либо написать calc.exe
  Seuqence Container -- Контейнер внутри пакета, может включать в себя что угодно. От него отходит стрелка,
                     -- которая перейдёт туда, только после завершения всего контейнера. Так же его
					 -- используют чтобы задать одно свойство всему содержимому
  GROUP -- выделяем диапазон > пкм > GROUP. Это неполноценный контейнер, который не имеет свойств и выходных
        -- стрелок. Роль - чисто визуальная
  Script Task -- Скрипт написанный на VB.NET, C#
  Execute SQL Task -- Выполнение SQL сценариев
  For Loop Container -- Цикл. Прокручивание содержимого несколько раз. Возможно писать надо на С,
                     -- переменные там обозначаются как в SQL - @
  Foreach Loop Container -- Перебор
  Data Flow Task -- Для любых перемещений данных. В нём меняется toolbox. Здесь стрелочки означают 
                 -- перемещение данных (зелёная - данные, которые не вызывают исключений, красные - ошибочные).
				 -- Сначала втыкаем стрелочку в компонент, потом настраиваем его
  Execute Package Task -- Запуск нескольких пакетов
  
	- Внутри него:
		1. OLE DB Source -- Источние данных
		2. Multicast -- Что пришло в него, он рассылает многократно по многих выходам
		3. Sort -- Сортировка. Настроить по каким полям сортировать
		4. Flat File Destination -- Выгрузка в файл
		5. Conditional Split -- Разделение строк по условию (switch case).
		6. Merge -- Сливает всё вместе. Работает только если на вход приходят отсортированные данные
		7. SQL Server Destination -- Подключение к серверу для загрузки в него данных
		8. OLE DB Destination -- Подключение к любой базе через OLE DB

- Точка останова
 - пкм на элементе > Edit Breakpoints  
 - Благодаря этому можно подменять значения по живому
 
- Data Viewer (показывает строки таблицу/гистограмму данных)
	- пкм на стрелке > DataViewr
  
- Размещение пакета
	1. Project>Thrid Properties>Deployment Utility>CreateDeploymenUtility=True.
	2. Build>Build Thrid
	3. На выходе файл с расширением .manifest, который при запуске будет работать
	4. После запуска можно выбрать где будем размещать пакет

- Как бороться с ошибками в SSIS
	1. Перехват ошибки (раздел Event Handlers. Например при исполнении пакета ошибка, то делай пакет,
	который нарисуем)
	2. Логирование ошибок (SSIS > Logging)

- Параметризация пакета/переменные
- Когда добавляем переменную, важно выбрать область видимости переменной, выделяем мышкой по холсту
	- SSIS > Variables
	- SSIS > Package Configuration > Включить > Добавить > Откуда будем брать настройки > Что я хочу
	настраивать (можно настроить переменную, VALUE). Создаётся xml файл, в котором можно указывать
	значение нашей выбранной переменной.
	- Если хотим испольщовать параметр в пакете - надо поставить ? или несколько. Потом в параметр Mapping
	указываем значения для этого ? например нашу переменную. Parametr Name пишет как порядковый номер ?,
	начиная с 0
	
- Посмотреть пакеты на сервере
	SELECT * FROM msdb.dbo.sysssispackages
	
-- Вызов пакета для пользователя (графический интерфейс)
	DTEexecUI -- Иногда надо установить  

-- Вызвать пакет, надо ещё указать сервер, логин с паролем и т.д.	
	DTExec /sql Test
	DTExec /File "c:/.../Test.dftx"
	
-- Отладка работы сервера.
	I. Есть ли проблема?
		1. Увидеть проблемы (Perfomance Monitor) (Чтобы понять как ситуация обстоит в целом используем счётчик "Физический диск>AVG Disk Queue Length". Если он измеряется в штуках, значит всё хорошо, если в десятках, то слабый диск или память, если в сотнях значит надо переписывать запросы)
		2. Журналирование(Perfomance Data Collector)
		3. Уведомления(Alert)
	II. Где проблема?
		1. SQL Server Profiler (tracing)
		2. sp_Trace...,fn_Trace...(трассировка через консоль, без визуализации, если необходимо строить свой профалер)
		3. Profiler + Perfomance Monitor(Одновременно снимаем показания в обоих системах и в профайлер подгружаем Perfomance Monitor (File>Import Perfomance Data). После чего они синхронизируются и при выборе времени на шкале, профайлер показывает что в этот момент происходило)
	III. Почему проблема?
		1. Execution Plan
			- Стоимость запроса(Actual Execution plan)(Estimated Subtree Coast - стоимость запроса в плане)
			- Состав операций
			- % вклад операций в общую стоимость
			- Детальные затраты
			- Толщина стрелок(количество срок, передающихся от одной операции к другой)(Лучше если толстые стрелочки кончается в самом начале, чтобы они не передавались дальше)

-- Автоматизация:
	1. Windows (Планировщик задачь Windows/Task Scheduler)(Task(асинхронно),Action(синхронно))
	2. SQL (SQL Server Agent)(Job(асинхронно),Step(синхронно))

-- Запуск Job от произвольного имени пользователя
	1. Создать учётку
	2. Добавить в Security>Credantial
	3. Создать Прокси Аккаунт (Proxy Account)(SQL Server Agent>Proxeis). Создать новый и выбрать Credantial аккаунт и выбираем права
	
-- Proxy Account
	1. В SQL Server > Properties > Security > "Enable Server Procxy account"
	2. В Агенте > Properties > Job System > "Job step proxy account"
	
-- Уведомления(Nitifications в Job). Чтобы сделать всего 1 раз уведомление, можно в той же закладке удалить Job после использования (Automatically delete job).
    1. Windows Applications
	2. Email (Operators)
	
-- Alert(уведомления, если что-то случилось, то делай что-то). Они нужны для разработчика и администратора.
	1. Perfomance Condition Alert (реагирует на счётчики, можно привязать только к счётчику этого экземпляра сервера). Можно выбрать разные счётчики. На закладке Response указывается что произойдёт при срабатывании. В Options надо поставить задержку, чтобы не запускался постоянно.
	2. Event Alert(события внутри SQL, все называются ERROR, хотя не всегда являются ошибками)(С помощью него разработчик сообщает администратору какие у пользователя происходят ошибки). Severity(уровень важности).
	
	- Номера Alert`ов
		1205 - взаимные блокировки (deadlock), но чтобы включить правильно EXEC master..sp_altermessage 1205, 'WITH_LOG', TRUE; GO. Этот код активирует в таблице SELECT * FROM master.sys.messages регистрацию в логах дедлоков
	
	-- DEADLOCK
		DBCC TRACEON(1204,1222,-1)
		
		-- Profiler (associated objid). Только в момент проблем
		SELECT OBJECT_SCHEMA_NAME([object_id]), 
		OBJECT_NAME([object_id]) 
		FROM sys.partitions 
		WHERE partition_id = 289180401860608;
	
	RAISERROR (50001,19,1) WITH LOG --ошибка(50001 - номер ошибки). Это добавляется в процедуру. 
	RAISERROR('This is a test', 16, 2) WITH LOG -- При указании WITH LOG, эта ошибка будет записана в лог сервера
	
	SELECT * FROM sys.Messages -показать все системные ошибки 
	
	Первые 50 000 ошибок зарезервированы под SQL.
-- Чтобы добавить свою ошибку
	EXECUTE sp_AddMessage
	50001, 19, 'Не хватает денег на счёте'	-- 19 это серьёзность ошибки
	@WITH_Log = 'True' -- Чтобы на эту ошибку можно было добавить Alert
	
-- Технология одного JOB на многих серверах через главный сервер. (6 видео 4:00). Система Master-Target.
-- Если сервер загружен, то можно заставить события обрабатываться через другой сервер (6 видео 4:10)

-- Подсказки
SET STATISTICS IO ON -- Включить статистику чтений в запросе
SET STATISTICS TIME ON -- включить статистику времени выполнения
set statistics profile on -- Показывает план запроса в строках
SET STATISTICS XML ON -- Возвращает сведения о выполнении для каждой инструкции после ее выполнения, в дополнение к стандартному результирующему набору, возвращаемому инструкцией
SET SHOWPLAN_XML ON -- показать план запроса в XML
	- Чтобы его подключить надо в конце запроса написать SELECT * FROM FAQ (OPTION USE PLAN N'<...>')
QUERYTRACEON -- Вкл трассировочные флаги на уровне опредлённого запроса

-- РОЛИ
	-- Роли базы
		- CREATE ROLE buyers AUTHORIZATION dbo; -- создать роль buyers принадлежащую dbo
		- Добавление/удаление из ролей
			ALTER ROLE Sales ADD/DROP MEMBER Barry;
		- Изменение роли
			ALTER ROLE buyers WITH NAME = purchasing;
	-- Роли уровня сервера
		- Создание серверной роли возможно только в 2012 версии
		- Список разрешения уровня сервера
			SELECT * FROM sys.fn_builtin_permissions('SERVER') ORDER BY permission_name;
		- Дать/отнять разрешение уровня базы у роли
			DENY/GRANT VIEW ANY DATABASE TO Paul
		- Список ролей сервера
			EXEC sp_helpsrvrole -- если указать в кавычках название роли, то вернётся её описание
		- Все члены роли
			EXEC sp_helpsrvrolemember 'sysadmin'
		- Все разрешения роли
			EXEC sp_srvrolepermission 'sysadmin';
		- Проверка вхождения в роль текущего пользователя
			SELECT IS_SRVROLEMEMBER ('sysadmin')
		- Проверка вхождения в роль другого пользователя
			SELECT IS_SRVROLEMEMBER('diskadmin', 'Contoso\Pat');
		- Общий список пользователей и их роли. public здесь не учитывается
			SELECT sys.server_role_members.role_principal_id, role.name AS RoleName, 
				sys.server_role_members.member_principal_id, member.name AS MemberName
			FROM sys.server_role_members
			JOIN sys.server_principals AS role
				ON sys.server_role_members.role_principal_id = role.principal_id
			JOIN sys.server_principals AS member
				ON sys.server_role_members.member_principal_id = member.principal_id;
		- Добавить пользователю роль
			EXEC sp_addsrvrolemember 'Corporate\HelenS', 'sysadmin';
		- Удалить у пользователя роль
			EXEC sp_dropsrvrolemember 'JackO', 'sysadmin';
		- Создать роль
			CREATE SERVER ROLE buyers AUTHORIZATION dbo; -- создать серверную роль buyers принадлежащую dbo
		- Переименование роли	
			ALTER SERVER ROLE Product WITH NAME = Production
		- Добавление учётной записи к роли
			ALTER SERVER ROLE diskadmin ADD MEMBER Ted ;
		- Удаление учётноё записи из роли
			ALTER SERVER ROLE Production DROP MEMBER Ted ;
		- Предоставление имени входа разрешения на добавление имен вход
			GRANT ALTER ON SERVER ROLE::Production TO Ted ;
		- Удаление роли
			DROP SERVER ROLE purchasing;		
			
-- Пользователи/Users/Работа с пользователями/сопоставление
	ALTER USER Philip 
	WITH  NAME = Philipe -- Изменение имени
    , DEFAULT_SCHEMA = Development -- Изменение схемы
    , PASSWORD = 'W1r77TT98%ab@#' OLD_PASSWORD = 'New Devel0per' -- Изменение пароля
    , DEFAULT_LANGUAGE  = French ;-- Изменения языка
	, LOGIN = MyLogin -- Сопоставляет пользователя с другим именем входа

	- Посмотреть у кого есть разрешения уровня сервера
		SELECT l.name as grantee_name, p.state_desc, p.permission_name 
		FROM sys.server_permissions AS p JOIN sys.server_principals AS l 
		ON   p.grantee_principal_id = l.principal_id
		WHERE permission_name = 'VIEW ANY DATABASE' ;
	
	- Дать/отнять разрешение уровня базы у пользователя
		DENY/GRANT VIEW ANY DATABASE TO Paul
		
	- Посмотреть последний запрос пользователя через session_id
		DBCC INPUTBUFFER(52)
		
	-- Перенос логинов (перенос пользователей) сервера на другой сервер
		- Сравнить sid
			Use master
			SELECT sid FROM dbo.syslogins WHERE name = 'SRV-1C\sql'
			Use ReportServerTempdb
			SELECT sid FROM dbo.sysusers WHERE name = 'SRV-1C\sql'
		- Поблем нет, если использовать Windows аутентификацию
		- Связь серверного и базового логина организована через идентификатор sys.Server_Principals
		  (Если нужного только SQL Server пользовали WHERE type = 'S') и sys.Database_Principals, поле - sd.
		  Их надо синхронизировать:
		- Первый способ:
			1. На втором сервере разворачиваю базу с первого
			2. Завожу логин какой-то
			3. ALTER USER [Е.Онегин] -- Пользователь базы
			   WITH LOGIN = [Евгений Онегин] -- Пользователь сервера
			- Проблемы:
				1. sid пользователя базы становится другим и поэтому базы на разных серверах уже не одинаковые
				2. Если хотим переместить базу обратно, то снова надо делать ALTER USER
		- Второй способ:
			1. На втором сервере разворачиваю базу с первого
			2. Узнаю sid нужного пользователя sys.Database_Principals в нужной базе
			2. Завожу логин какой-то с этим сидом (только кодом)
				CREATE LOGIN [Евгений Онегин]
				WITH PASSWORD = 'ferwg', SID = 0x4687867257...
			- Проблемы:
				1. Трудоёмко
				2. Работаю в ручную с паролями
	
-- Политики/апликейшен роли
	- Можно использовать на множестве серверов
	- Managment > Policy Managment > Facets (то, что мы можем изменять/взять под своё управление)
	- Managment > Policy Managment > Conditions (Правило, такое-то свойство должно быть таким)
	- Managment > Policy Managment > Policies (Управляющий объект, который является пачкой Conditions). На политике
	пкм > Evaluate (проверка, действительно ли все объекты соблюдают эту политику)

-- Аудит
	- Уровень Сервера
		1. Security>Audits (настройки аудита)
		2. Secutiry > Server Audit Specification (фильтры, чтобы что-то отлавливать. Необходимо выбрать в какой Audit писать)
	- Уровень Базы
		1. То же самое
		2. То же самое только другие события
-- Триггеры(основное применение)(INSERT, UPDATE, DELETE):
	1) Аудит
	2) Ограничение(скажем запрет удалени больше 20 строк за раз). Контроль целостности
	
	DDL-Trigger(CREATE, ALTER, DROP):
	1) Аудит
	2) Контроль целостности
	
	Триггеры синхронны, если нужны ассинхронные триггеры используется доп программа/функция
	
		Батник(запустить его планировщиком):
	SQLCMD -S HOU-SQL-01 -E -i "C:\Backup.txt"

OBJECT_ID:	
AF = агрегатная функция (среда CLR)
C = ограничение CHECK
D = значение по умолчанию (DEFAULT), в ограничении или независимо заданное
F = ограничение FOREIGN KEY
FN = скалярная функция SQL
FS = скалярная функция сборки (среда CLR)
FT = возвращающая табличное значение функция сборки (среда CLR)
IF = встроенная возвращающая табличное значение функция SQL
IT = внутренняя таблица
P = хранимая процедура SQL
PC = хранимая процедура сборки (среда CLR)
PG = структура плана
PK = ограничение PRIMARY KEY
R = правило (старый стиль, изолированный)
RF = процедура фильтра репликации
S = системная базовая таблица
SN = синоним
SQ = очередь обслуживания
TA = триггер DML сборки (среда CLR)
TF = возвращающая табличное значение функция SQL
TR = триггер DML SQL
TT = табличный тип
U = таблица (пользовательская)
UQ = ограничение UNIQUE
V = представление
X = расширенная хранимая процедура
	
-- Типы БД
- Снежинка (когда факты соединяются со справочниками через посредников)
	- Иногда база в виде снежинки бывает необходима, чтобы связать несвязные сущности, через что-то общее.
	  Например есть оптовые и розничные продажи, у каждого из них свои зависимости покупаели и реселлеры,
	  но они оба связаны с географией, поэтому мы можем построить продажи по городам и для того и для того.	
	  
-- LUN
	- Грубо говоря, LUN (Logical Drive), с представляет собой кусок рэйд массива, который контроллер представляет операционной системе
	  в качестве "физического" диска. 
	- Это Логический том внутри рейд-группы, который для сервера виден как физический диск.
	- Смысл разбиения массива на луны в том, что на разных лунах можно иметь разные политики кэширования, что невозможно в случае обычных
	  софтовых партиций. А на многих контроллерах еще и разные уровни рэйд (например контроллеры Адаптек или LSI). Еще момент - не всегда
	  операционки понимают диски более 2ТБ (хотя это со временем пройдет) - тогда большой массив можно просто порезать. 

-- Защита строк
	- Создать View и дать на него права нужному пользователю
	
-- Active Directory из Transact-SQL
	- SQL Server считает Active Directory внешним источником данных, так что обращаться к базе AD можно через механизм связанных серверов
	- Поставщик: OLE DB Provider for Microsoft Directory Services
	- Расположение: лучше доменное имя использовать(Contoso.com)
	- Безопасность: указать доменную учетку
	- Работа с AD
		SELECT * FROM OpenQuery (AD, -- Имя связанного серверва AD
								'SELECT objectCategory,adsPath,userPrincipalName FROM ''LDAP:/DC=Contoso,DC=com'''
								)
		WHERE objectCategory LIKE 'CN=Person%' AND adsPath LIKE '%OU=Специалист,%'
		или
		SELECT * FROM OpenQuery (AD,'<LDAP://OU=Cпециалист,DC=Contoso,DC=com>;(&(objectCategory=Person)(objectClass=user));
										name,adspath,sn,givenname,samaccountname,userprincipalname;subtree')
										
	-- Active Directory (найти группу или пользователей)
		rundll32 dsquery, OpenQueryWindow
		
	-- Active Directory (в какую группу входит пользователь)
		net user DKX6AO0ADM /domain

-- Артемов Дмитрий. Sql server 2012 – новый менеджер памяти
- В 32 битной архитектуре, чтобы система забирала себе не 2 Гб, а 1 надо:
	1. В Win 2003 - userva /3gB
	2. Остальные BCDEdit.exe
	
-- MARS
- позволяет приложениям сохранять более одного ожидающего выполнения запроса в расчете на соединение и,
  в частности, иметь более одного применяемого по умолчанию активного результирующего набора в расчете
  на одно соединение.
- Включается в запросе или строке соединения. Примерн а c#
	string connectionString = "Data Source=MSSQL1;" + 
    "Initial Catalog=AdventureWorks;Integrated Security=SSPI;" +
    "MultipleActiveResultSets=True";
  
-- Оперативная память/memory
	- Лучше отдать операционной системе 1 Гигобай из каждых 16
	- Счётчик SQL SERVER: Диспетчер буферов - Ожидаемый срок жизни страницы (SQL SERVER: Buffer Manager -
	  Page Life Expectancy). Должен быть больше 300, но ели терабайт памяти, то нижний показатель будет
	  более 1000
	- All memory not used by another memory component remains in the buffer pool to be used as a data cache for pages read in from the database files on disk.
	- The largest of other memory components is typically the cache for procedure and query plans
	
-- Сжатие/Data Compression
	- Доступно в редакции Enterprise
	- Бывает Page и Row	
		1. Row-level Data Compression: Row-level data compression is essentially turning fixed length data types into variable length data types, freeing up empty space. It also has the ability to ignore zero and null values, saving additional space. In turn, more rows can fit into a single data page. 
			The simplest method of data compression, row-level compression, works by:
			Reducing the amount of metadata used to store a row.
			Storing fixed length numeric data types as if they were variable-length data types. For example, if you store the value 1 in a bigint data type, storage will only take 1 byte, not 8 bytes, which the bigint data types normally takes.
			Storing CHAR data types as variable-length data types. For example, if you have a CHAR (100) data type, and only store 10 characters in it, blank characters are not stored, thus reducing the space needed to the store data.
			Not storing NULL or 0 values
			Row-level data compression offers less compression than page-level data compression, but it also incurs less overhead, reducing the amount of CPU resources required to implement it.
		2. Page-level Data Compression: Page-level data compression starts with row-level data compression, then adds two additional compression features: prefix and dictionary compression. As you can imagine, page-level compression offers increased data compression over row-level compression alone.
			Page-level data compression offers greater compression, but at the expense of greater CPU utilization. It works using these techniques:
			It starts out by using row-level data compression to get as many rows as it can on a single page.
			Next, prefix compression is run. Essentially, repeating patterns of data at the beginning of the values of a given column are removed and substituted with an abbreviated reference that is stored in the compression information (CI) structure that immediately follows the page header of a data page.
			And last, dictionary compression is used. Dictionary compression searches for repeated values anywhere on a page and stores them in the CI. One of the major differences between prefix and dictionary compression is that prefix compression is restricted to one column, while dictionary compression works anywhere on a data page.
			The amount of compression provided by page-level data compression is highly dependent on the data stored in a table or index. If a lot of the data repeats itself, then compression is more efficient. If the data is more random, then little benefits can be gained using page-level compression.
			
	-- Оценить сжатие (только на тех версиях SQL, которые это поддерживают)
	USE IntraTv;
	GO
	EXEC sp_estimate_data_compression_savings 'dbo', 'AllTerritories', NULL, NULL, 'ROW' ;
	GO
	
	-- Включить	
		ALTER TABLE [dbo].[SIEMAudit] REBUILD PARTITION = ALL
		WITH (DATA_COMPRESSION = PAGE)

-- Сохранение/backup флагов
- SQL Server Registry Hive

-- Последние backup/ last backup/ последний backup
	select
	  database_name,
	  MAX(backup_finish_date) as Last_backup_start_date,
	  max(backup_finish_date) as Last_backup_finish_date,
			case when [type]= 'D' then '1_Full Backup'
				 when [type] = 'I' then '2_Diff Backup'
				 when [type] = 'L' then '3_Log Backup'
				 end as [Backup TYPE],
	  count (1) as 'Count of backups'
	from msdb..backupset
	group by database_name,[type]
	order by database_name,[Backup TYPE] --desc --, Last_backup_finish_date
	go 

-- Проверка backup (можно указать в задании backup)
RESTORE VERIFYONLY FROM DISK= '<Backup_location>' WITH CHECKSUM

-- Существоание объекта
IF OBJECT_ID('TableName','U') IS NOT NULL -- select * from sys.object здесь смотрим какая буква соответсвует какому объекту

-- Активные запросы
SELECT * FROM sys.dm_exec_requests

-- Активные подключение/сколько используют памяти пользователи/сколько используют  памяти подключения
 SELECT * FROM sys.dm_db_task_space_usage

-- Синоним/алиас/alias
- Второе имя для базы данных
CREATE SYNONYM MyProduct FOR AdventureWorks2012.Production.Product;

-- Возвращает разнородный набор полезных сведений о компьютере, а также о ресурсах, доступных и используемых SQL Server.
	SELECT * FROM sys.dm_os_sys_info
		
-- Перемещение заданий, оповещений и операторов
Откройте средство SSMS и раскройте папку Управление.
Раскройте узел Агент SQL Server, а затем щелкните правой кнопкой мыши узел Оповещения, Задания или Операторы.
Выберите команду Все задачи и выберите пункт Формирование сценария SQL. Для SQL Server 7.0 выберите пункт Script All Jobs (создать сценарий для всех заданий), Alerts (оповещения) или Operators (операторы).

-- Перемещение планов выполнения
- Для SQL Server 2008 системные таблицы нужно выбрать другие:
- Суть, создать список команд для копирования пакетов. Команды, после анализа кода,
  нужно скопировать через буфер обмена в окно запроса и выполнить.
USE msdb
SELECT 'EXEC [master].[sys].[xp_cmdshell] ''dtutil /Q /SQL ' +
CASE f.foldername WHEN '' THEN '"' + p.[name] + '"' ELSE '"' + f.foldername + '\' + p.[name] + '"' END
+ ' /ENCRYPT FILE;'c:\temp\' + p.[name] + ".dtsx";0 /SOURCESERVER ' + @@SERVERNAME + ''''
FROM msdb.dbo.sysssispackages p
JOIN msdb.dbo.sysssispackagefolders f
ON p.folderid = f.folderid
WHERE p.folderid <> '00000000-0000-0000-0000-000000000000'
GO

- Это не надо
- Если  сервер не сконфигурирован, выполнить следующее
USE master
EXEC master.dbo.sp_configure 'show advanced options', 1
RECONFIGURE
EXEC master.dbo.sp_configure 'xp_cmdshell', 1
RECONFIGURE
GO
- Тут место для результирующего сценария резервирования Maintenance Plans
-USE master
-EXEC master.dbo.sp_configure 'xp_cmdshell', 0
-RECONFIGURE
-EXEC master.dbo.sp_configure 'show advanced options', 0
-RECONFIGURE
-GO


-- Перемещение пользователей и паролей на другой сервер
- http://support.microsoft.com/kb/246133/ru

-- Вход в качестве пакетного задания
	1. secpol.msc
	2. Локальные политики 
	3. Назначение прав пользователя
	4. Вход в качестве пакетного задания 
	


-- SQL Agent
	- Есть 3 роли, которые можно назначить для SQL Agent в msdb >> Security

-- Лог SQL Agent 
	- SQLAGENT.OUT

-- Вернуть исходный текст указанного объекта
print object_definition (object_id('sys.sysindexes'))

--Обход триггера на логон(LOGON)
Если вы попали в такую ситуацию, придётся воспользоваться специальной лазейкой, которая позволяет администратору подключиться к SQL-серверу в обход LOGON-триггеров. Такое "сервисное" подключение доступно только членам серверной роли SysAdmin. Обратите внимание, что возможность удалённого сервисного подключения может быть отключена в настройках, тогда придётся работать прямо на сервере.
Подключиться к серверу с параметром -A
А при подключении из студии используйте префикс ADMIN: перед именем сервера.
Такое подключение не предназначено для полноценной работы с данными, только для решения проблем с доступностью сервера. Но удалить или отключить триггер вы сможете.

--Ограничение подключений к серверу с параметрами
- Реализуется через триггер LOGON
	1. Ограничить количество подключений с 1 PC
		CREATE TRIGGER MyTrigger
			ON ALL Server
			WITH EXECUTE AS 'sa'
			FOR LOGON
		AS
			IF EXISTS (Select Count(*) FROM sys.dm_exec_sessions WHERE Is_User_Process = 1 AND Host_Name = Host_Name() HAVING Count(*) >= 10)
			ROLLBACK
	2. Число открытых сеансов именно этого пользователя
		... AND Login_Name = Original_Login() HAVING Count(*) >= 10
	3. Анализируя уже открытые сеансы по пользователям, компьютерам и приложениям одновременно
		... AND Login_Name = Original_Login() AND Host_Name = Host_Name() AND Program_Name=App_Name()
		
-- Регистрация 
		
--Ускорить запуск SSMS
- В свойсте ярлыка настроить строку подключения
	1. Быстрый вызов
	2. Объект
		Параметры:
			-S	Имя или адрес сервера, а также имя экземпляра. Подключение к этому серверу происходит сразу при запуске студии.
			-d	Название базы данных, с которой сразу начнёте работать.
			-nosplash	Отключение показа заставки перед запуском студии.
			-E	Этот параметр означает, что вы будете использовать текущую учётную запись Windows
			-U -P	Если используете SQL-режим аутентификации, то эти два параметра позволят вам сразу задать имя ползователя и пароль.
		Пример:
			1. "C:\Program Files (x86)\Microsoft SQL Server\100\Tools\Binn\VSShell\Common7\IDE\Ssms.exe" -S localhost -d DotaHelper -E
			2. "C:\Program Files (x86)\Microsoft SQL Server\100\Tools\Binn\VSShell\Common7\IDE\Ssms.exe" -S localhost -d DotaHelper -U Dmitrich -P 123
			
-- Принадлежность пользователя к группе или роли
- Анализируя системные представления Sys.Database_Principals и Sys.Database_Role_Members, вы получите полную картину о членстве в группах.
	WITH ListRoles
		AS	(
	-- Якорь рекурсии. Здесь только те роли, которые sa 
	-- использует непросредственно
		SELECT r.principal_id,r.sid,r.name
		FROM sys.database_principals p
		INNER JOIN sys.database_role_members m
		ON p.principal_id = m.member_principal_id
		AND p.type IN ('S','U','G')
		INNER JOIN sys.database_principals r
		ON m.role_principal_id=r.principal_id
		ON m.role_principal_id=r.principal_id
		WHERE p.name = N'sa'
		
		UNION ALL

	-- Рекурсивно раскручиваем все охватывающие роли 
	-- Их sa исполняет непосредственно
		SELECT r.principal_id,r.sid,r.name
		FROM ListRoles p 
		INNER JOIN sys.database_role_members m
		ON p.principal_id=m.member_principal_id
		INNER JOIN sys.database_principals r
		ON m.role_principal_id=r.principal_id		
		)

	-- Список всех ролей(с учётом вложенности), которые
	-- исполняет sa	
	SELECT * FROM ListRoles

- Если необходимо проверить членство в серверных ролях, то вместо p.type IN ('S','U','G'), указываем 'R'

- Просто проверить принадлежность текущего пользователя к одной конкретной роли:
	SELECT Is_Member(N'Роль БД') //Проверка производится для текущего пользователя
	SELECT Is_Member(N'ARTTOUR\Группа AD')

	
--Обновление SQL Server (SQL для Администраторов 09.2013)
	http://technet.microsoft.com/ru-ru/sqlserver/ff803383.aspx
	http://sqlserverbuilds.blogspot.ru/
		- Помощник обнолвения http://msdn.microsoft.com/en-GB/library/ms144256(u=sql.100).aspx
	
	-- Есть возможность поставить SQL Server без лицензии:
		1. Установить Express версию, которая бесплатная, но ограничена 1 ядром процессора и 1 Гб оперативной памяти, после чего его можно будет обновить до любой редакции
		2. Установить временную Enterprise версию на 180 дней, после чего нужно будет подсунуть ей ключ. Такой вариант сработает только если планируется установка Enterprise версии, так как подсунуть лицензию Standart на Enterprise не получится. 
	
-- Raid
	- Чем больше кэш рейда - тем лучше
	- Надо выставлять кэш только на запись, на чтение - пустая трата ресурсов (write cache mode = write-back)
	
-- Database in Recovery
- Варианты решения
1.
 Use master 
go 
sp_configure 'allow updates', 1 
reconfigure with override 
go 

Там же выполняем :
update sysdatabases set status= 32768 where name = '<db_name>' 

Перезапускаем SQL Server. Далее по обстоятельствам.

USE '<db_name>' 
GO 
sp_dboption '<db_name>', 'single_user', 'true' 
go 
DBCC CHECKDB 
go 

Если все в порядке, то:
sp_dboption '<db_name>', 'single_user', 'false' 
go 
Use master 
go 
sp_configure 'allow updates', 0 
go
	
2.
restore database <db> with recovery

-- MaximumErrorCount‎ / W_MAXIMUMERRORCOUNTREACHED
- Чтобы увеличить это число, надо зайти в пакет DTS, нажать F4 и увеличить это число


	
-- snapshot isolation
- Побочный эффект
	- Появление неожиданной фрагментации индекса. Можно исправить использование филл фактора

-- Компактное перечислении ряда чисел (7-52, 57-88...)
	- SQL для разработчиков стр. 9 от 10.2013

-- Планы выполнения запросов/plan_handle/plan cache
	
	DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS -- Удаляет все чистые буферы из буферного пула (то есть весь кэш, который не имеет грязных страниц). Чтобы удалить чистые буферы из буферного пула, необходимо сначала воспользоваться инструкцией CHECKPOINT для обеспечения холодного буферного кэша. Это вызовет принудительную запись всех «грязных» страниц текущей базы данных на диск и очистит буферы. После этого можно выполнить команду DBCC DROPCLEANBUFFERS, которая удалит все буферы из буферного пула.
	DBCC FLUSHPROCINDB(db_id) -- очистка кэша планов базы
	DBCC FREEPROCCACHE WITH NO_INFOMSGS; -- Сбросить весь кэш планов(стоит делать когда кэши изменяются сотнями тысяч)/план выполнения/перекомпиляция
	DBCC FREEPROCCACHE(0x05000F006FB9565D40615615050000000000000000000000) -- сбросить кэш определённого плана (plan_handle)
	DBCC FREESYSTEMCACHE ('All') -- Удаляет все неиспользуемые элементы из всех кэшей.
	DBCC FREESESSIONCACHE Flushes the distributed query connection cache. This has to do with distributed querie
	
	SELECT * FROM sys.dm_exec_query_plan(0x06000F00E3589F2640A179B2020000000000000000000000); -- посмотреть план выполнения запроса
	
	-- Освобождает оперативную память, которая используется неоптимально из "одноразовых запросов".
		E:\SQL Scripts\Plan Cache.sql
	
	-- Посмотреть данные о планах выполнения/планах в кэше/кеше по тексту процедуры/использование процедуры
	SELECT [qs].[execution_count], [s].[text], [qs].[query_hash], 
		[qs].[query_plan_hash], [qp].[query_plan], [qs].[plan_handle]
	FROM [sys].[dm_exec_query_stats] [qs]
	CROSS APPLY [sys].[dm_exec_query_plan]([qs].[plan_handle]) [qp]
	CROSS APPLY [sys].[dm_exec_sql_text]([qs].[plan_handle]) [s]
	WHERE [s].[text] LIKE '%up_WEB_2_best_List%'; -- тут можем вводить любой текст, который хранится внутри текста процедуры
	
	-- Сбросить планы для объекта, ниже базы (таблица, процедура, триггеров)
	sp_recompile N'Sales.Customer'
	
	-- Оптимизация
		- Включить "optimize for ad hoc workloads" (Эта опция позволяет заносить первый раз в кэш только часть запроса и если он будет вызван снова, то будет записана остальная его часть. Позволяет экономить оперативную память. You can see these stubs as cacheobjtype 'Compiled Plan Stub' in sys.dm_exec_cached_plans)
		USE master
		EXEC master.dbo.sp_configure 'show advanced options', 1
		RECONFIGURE
		EXEC master.dbo.sp_configure 'optimize for ad hoc workloads', 1
		RECONFIGURE WITH OVERRIDE
		GO
		- Включение данной опции не сбрасывает текущие планы.
		
-- Параметризация
		- SIMPLE
			- простые, безопасные запрос
			- которые не могут вернуть или 1 или 1000 строк, всё должно быть более очевидно
			- нет JOIN, подзапросы, хинты ...
		- FORCED (принудительная)
			- опасно
			
	- Можно использовать plan_guide чтобы указать хиндом PARAMETRIZATION = Force
	- Для явно параметризации можно использовать sp_executesql
	- Планы можно смотреть в sys.dm_exec_query_stats
	- Когда смотрим план, в свойствах (F4) можно найти неявное преобразование и в общей стоимости все параметры
	- Значением query_hash (хэш функция)/query_plan_hash одинаково для всех БД, инстансов и тд, но они разные на версиях SQL Server(2008-2012)
	- SQL Server умеет распознавать одинаковые запросы, написанные по разному. Например с комментариями и без, с инструкциями SET и без, BETWEEN и </>, IN и OR OR OR, не учитывает временные таблицы и даже если названия PK разные (когда создаются автоматически, без явного указания имени)
	
	SELECT * FROM sys.dm_exec_query_stats as qs 
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
	
	-- Советы
		1. Явно параметризируйте свои запросы
		2. Лучше сначала попробовать воспользоваться plan_guide	
		
	-- Forced Parameterization/если много планов с малым количеством  вызовов/использование планов
		- Посмотреть количество планов с одним вызовом
			- SELECT * FROM sys.dm_exec_cached_plans where usecounts = 1
		- Настройка уровня базы
		- В режиме Simple параметризирует только малую часть запросов:
			SELECT * FROM AdventureWorks2012.Sales.CreditCard WHERE CreditCardID = 11
			SELECT * FROM AdventureWorks2012.Sales.CreditCard WHERE CreditCardID = 207
			-- Для обоих запросов будет создан только 1 план, с параметром 11. Это и значит параметризировать и занести в кэш только 1 план
		- В режиме Forced параметризирует все запросы
			ISNULL(Date,'1/1/1900') > '6/1/2008'
		- Посмотреть настройку параметризации для всех баз
			SELECT name, is_parameterization_forced FROM sys.databases
		- Изменить настройку параметризации
			ALTER DATABASE AdventureWorks2012 SET PARAMETERIZATION FORCED
			ALTER DATABASE AdventureWorks2012 SET PARAMETERIZATION SIMPLE
		- Особенности
			- Принудительная параметризация, в сущности, преобразует литеральные константы в запросе в параметры при компиляции запроса. Следовательно, оптимизатор запросов может выбирать не самые оптимальные планы для запросов. В частности, уменьшается вероятность того, что оптимизатор запросов сопоставит запрос с индексированным представлением или индексом по вычисляемому столбцу. Он может также выбирать не самые оптимальные планы для запросов, ориентированных на секционированные таблицы или распределенные секционированные представления. Принудительная параметризация не должна использоваться в средах, в значительной степени опирающихся на индексированные представления и индексы по вычисляемым столбцам. Параметр PARAMETERIZATION FORCED должен использоваться только опытными администраторами баз данных и лишь после того, как будет определено, что такое использование не повредит производительности.
			- Распределенные запросы, ссылающиеся на более чем одну базу данных, пригодны для принудительной параметризации, если параметр PARAMETERIZATION установлен на FORCED в базе данных, в контексте которой выполняется запрос.
			- Установка параметра PARAMETERIZATION на FORCED производит очистку всех планов запросов из кэша планов в базе данных за исключением тех, которые компилируются, перекомпилируются или выполняются в настоящий момент. Планы для запросов, которые компилируются или выполняются в момент изменения настроек, параметризуются при следующем выполнении запроса.
			- Если параметр PARAMETERIZATION имеет значение FORCED, то отчеты об ошибках могут отличаться от отчетов, формируемых при простой параметризации: число сообщений об ошибках в некоторых случаях больше, чем при простой параметризации, а номера строк ошибок могут быть выданы неверно.	
		
-- Взлом
	- Поиск процедур, где есть потенциальная угроза взлома
		WITH vulnerabilities
		AS
		(
		SELECT OBJECT_NAME(object_id) AS [Procedure Name],
		  CASE
			  WHEN sm.definition LIKE '%EXEC (%' OR sm.definition LIKE '%EXEC(%' THEN 'WARNING: code contains EXEC'
			  WHEN sm.definition LIKE '%EXECUTE (%' OR sm.definition LIKE '%EXECUTE(%' THEN 'WARNING: code contains EXECUTE'
		  END AS [Dynamic Strings],
		  CASE
			  WHEN execute_as_principal_id IS NOT NULL THEN N'WARNING: EXECUTE AS ' + user_name(execute_as_principal_id)
			  ELSE 'Code to run as caller – check connection context'
		  END AS [Execution Context Status]
		FROM sys.sql_modules AS sm
		)

		SELECT * FROM vulnerabilities WHERE [Dynamic Strings] IS NOT NULL ORDER BY [Procedure Name]

-- Создание отслеживания действий с сервером/триггер уровня сервера/
	CREATE TABLE dbo.AuditDDLOperations
	(            OpID                int               NOT NULL identity
														   CONSTRAINT AuditDDLOperationsPK
															   PRIMARY KEY CLUSTERED,
				OriginalLoginName    sysname           NOT NULL,
				LoginName            sysname           NOT NULL,
				UserName             sysname           NOT NULL,
				PostTime             datetime          NOT NULL,
				EventType            nvarchar(100)     NOT NULL,
				DDLOp                nvarchar(2000)    NOT NULL
	);
	go

	ALTER TRIGGER LogAllDDL
	ON ALL SERVER
	WITH ENCRYPTION
	FOR DDL_DATABASE_LEVEL_EVENTS
	AS 
	IF ORIGINAL_LOGIN() <> 'ART-BASE\admuser'
		BEGIN
			DECLARE @data XML
			SET @data = EVENTDATA()

			INSERT Arttour.[arttour].[AuditDDLOperations]
									(OriginalLoginName,
									 LoginName,
									 UserName,
									 PostTime,
									 EventType,
									 DDLOp)
			VALUES   (ORIGINAL_LOGIN(), SYSTEM_USER, CURRENT_USER, GETDATE(),
			   @data.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(100)'),
			   @data.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'nvarchar(2000)') ) 
			RETURN;
		END
	go
	
-- Безопасность
	- В очередной раз напомним: доступ к SQL Server через Интернет должен осуществляться только посредством брандмауэра.
	- Использовать механизм SSL, используется в технологии https.
	- Механизм аутентификации Kerberos является наиболее защищенным, так как в нем используются более мощные по сравнению с другими механизмами алгоритмы шифрования. Кроме того, он способен аутентифицировать и сервер, и клиента, что позволяет избежать фарминга — получения конфиденциальных данных клиента с применением поддельного сервера.
	- Многие из служб SQL Server отключены по умолчанию, и при отсутствии реальной необходимости их применения рекомендуется оставить их в неактивном состоянии. Так, поддержка применения Microsoft.NET Framework в ядре СУБД должна быть включена только в тех случаях, когда использование управляемого кода в приложении действительно необходимо. Не рекомендуется без необходимости включать такие службы и опции, как Database Mail и SQL Mail, AdHoc Remote Queries, Web Assistant, Remote DAC (Dedicated Administrator Connection), делать доступной хранимую процедуру xp_cmdshell для выполнения команд операционной системы из ядра СУБД и средства применения COM-расширений функциональности сервера (OLE Automation extended stored procedures), создавать точки доступа по протоколу HTTP (HTTP Endpoints, рис. 9).
	- Отказ от динамически формируемых в приложении запросов и генерации команд, выполняемых на сервере, непосредственно из введенных пользователем данных, в пользу представлений, хранимых процедур или параметризованных запросов.
	- Проверка пользовательского ввода в приложении
	- Использование представлений
	
-- Протокол безопасности/Protocol
	- Посмотреть по какому протоколу я сейчас работаю
		SELECT net_transport
		FROM sys.dm_exec_connections
		WHERE session_id = @@SPID;
	
-- Изменить владельца БД
	- sp_changedbowner
	- Владельцы системных баз не могут быть изменены, их владелец всегда dbo (dbo можно сопоставить с любым пользователем сервера)
	
-- Dirty pages/Грязные страницы
	A dirty page is a page that has not yet been written to the disk. You can (and most often will) have many pages that are different in memory as opposed to the copy on disk. They are called dirty, because the application has "smudged" them with new data. Once they are written to disk and both the disk copy and the memory copy agree, then it is no longer dirty.

-- index create memory 
	- Свойста сервера > Память > index create memory 
	- Обычно настройка не требуется, но иногда надо указать явно
	
-- Опции базы/настройки базы
	- TRUSTWORTHY 	
		- Доверяет ли экземпляр SQL Server базе данных и ее содержимому. По умолчанию это свойство имеет значение OFF, но его можно установить в ON при помощи инструкции ALTER DATABASE.
		- Это свойство позволяет уменьшить уязвимость системы перед рядом угроз, связанных с присоединением базы данных (вредоносные сборки с параметром разрешения EXTERNAL_ACCESS или UNSAFE, вредоносные модули, выполняемые в контексте привилегированных пользователей)
		- Разрешенность выполнения модулей с WITH EXECUTE AS
		- Так как база данных, присоединенная к экземпляру SQL Server, не может сразу стать доверенной, то ей не разрешается доступ к ресурсам вне ее области до тех пор, пока не будет явно отмечена как доверенная
		- По умолчанию для всех системных баз данных, кроме msdb, параметру TRUSTWORTHY задано значение OFF
		- Это значение не может быть изменено для баз данных model и tempdb
		- Рекомендуется никогда не задавать параметру TRUSTWORTHY значение ON для базы данных master
		- ALTER DATABASE DatabaseName SET TRUSTWORTHY ON;
		- SELECT is_trustworthy_on FROM sys.databases WHERE name = 'DatabaseName';
	
-- Домен
	- Изменение имени доменного пользователя
		1. Найдите и щелкните правой кнопкой мышки следующий подраздел реестра:
			HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa
		2. Создайте новую переменную типа DWORD с именем LsaLookupCacheMaxSize
		3. Задайте значение созданной переменной равное 0
		Теперь можно смело переименовывать учетную запись на SQL сервере (сперва в учетных записях сервера, потом в учетных записях конкретной БД).
		По окончании переименования не забудьте удалить недавно созданную переменную LsaLookupCacheMaxSize, чтобы снова задействовать механизм кэширования сопоставления SID и имен пользователей - это существенно ускорит работу вашего SQL сервера.
		
-- RamDrive
	- Должна стоять только 1 галочка - использовать 'System' память
	- Файловая система - NTFS
	- Настроить конфигурацию свопа на диск (Конфигурация файла образа)
	
-- Расширенные свойства/extendedproperty/extended property 
	- Могут быть заданы для большинства объектов БД
	- Репликация расширенных свойств производится только в процессе первоначальной синхронизации между издателем и подписчиком. Если расширенное свойство добавляется или изменяется после этого, то эти изменения реплицированы не будут. 
	- Есть 3 уровня. 0 - SCHEMA/user/FILEGROUP, 1 - TABLE/Logical File Name/FUNCTION/TABLE/PROCEDURE, 2 - COLUMN/PARAMETER (функции)/INDEX
	- Расширенные свойства нельзя определить для следующих объектов:
		1. Объекты области базы данных, не указанные в приведенных выше таблицах. В их число входят объекты полнотекстовых запросов.
		2. Объекты, не входящие в область действия базы данных, такие как конечные точки HTTP.
		3. Безымянные объекты, такие как параметры функции секционирования.
		4. Сертификаты, симметричные ключи, асимметричные ключи и учетные данные.
		5. Системные объекты, такие как системные таблицы, представления каталога и системные хранимые процедуры.
	- Можно использовать для
		1. Указания версии объекта БД
		2. Для указания количества вызовов процедуры
		3. Указание заголовка таблицы, представления или столбца
		4. Определение правил форматирования данных столбца при их отображении.
	-- Зададим расширенное свойство столбцу SafetyStockLevel
		EXEC sys.sp_addextendedproperty 
		@name = N'MS_DescriptionExample', 
		@value = N'Minimum inventory quantity.', 
		@level0type = N'SCHEMA', @level0name = Production, 
		@level1type = N'TABLE',  @level1name = Product,
		@level2type = N'COLUMN', @level2name = SafetyStockLevel;
	-- Обновление расширенного свойства
		EXEC sp_updateextendedproperty 
		@name = N'Caption'
		,@value = 'Employee ID must be unique.'
		,@level0type = N'Schema', @level0name = dbo
		,@level1type = N'Table',  @level1name = T1
		,@level2type = N'Column', @level2name = id;
	-- Удаление расширенного свойства
		EXEC sp_dropextendedproperty 
		 @name = 'caption' 
		,@level0type = 'schema' 
		,@level0name = dbo
		,@level1type = 'table'
		,@level1name = 'T1'
		,@level2type = 'column'
		,@level2name = id;
	-- Посмотреть все расширенные свойства в базе данных
		SELECT OBJECT_NAME(major_id),* FROM sys.extended_properties
	-- Посмотреть все расширенные свойства определённого объекта. В данном случае dbo.up_WEB_3_bron_Claim_note
		SELECT objtype, objname, name, value FROM fn_listextendedproperty(NULL, 'schema', 'dbo', 'PROCEDURE', 'up_WEB_3_bron_Claim_note', default, default);

-- Удаление куков из Managment Studio
	--2000
	В SQL 2000 список серверов хранится в реестре: 
	HKEY_CURRENT_USER\Software\Microsoft\Microsoft SQL Server\80\Tools\Client\PrefServers 

	--2005
	C:\Documents and Settings\\Application Data\Microsoft\Microsoft SQL Server\90\Tools\Shell\mru.da

	--2008
	C:\Users\Администратор\AppData\Roaming\Microsoft\Microsoft SQL Server\100\Tools\Shell\SqlStudio.bin	
	
-- Файловые группы/FileGroups
	- Посмотреть что хранится в файловых группах
		SELECT * FROM sys.indexes i INNER JOIN sys.filegroups f ON i.data_space_id=f.data_space_id WHERE f.name = 'INDEXES' -- Смотрим что хранится в файловой группе INDEXES
		

-- определить порт экземпляра/instance port
	USE MASTER
		GO
		xp_readerrorlog 0, 1, N'Server is listening on'
		GO
		
-- Отчёты в SSMS		
	- Это ни что иное, как отчёты SSRS
	- Создаём в SSRS и подключаем к SSMS
	- Чтобы работало везде нужно указать только ip сервера, без параметров подлючения
	- Вложенные отчёты не работают, потому что Microsoft так подстраховался
	-- Параметры в SSRS
		- Параметры можно использовать в запросе просто @ParametrName
		1. SSMS всегда передаёт отчётам 5 параметров (ServerName,DatabaseName,ObjectName,ObjectTypeName,ErrorText), поэтому их можно создать в отчёте и использовать, задавать значение не надо, их задаст SSMS.
	
-- Размер баз данных
	SELECT D.name as DbName,SUM(mf.size)*8/1024 as Size_in_Mb FROM sys.databases D INNER JOIN sys.Master_Files MF ON D.Database_ID = MF.Database_ID
	GROUP BY d.name
	
-- Выключить сервер/отключить сервер
	SHUTDOWN WTIH NOWAIT
	- Если выключать без WHTI NOWAIT
		- Disabling logins (except for members of the sysadmin and serveradmin fixed server roles).
			To display a list of all current users, run sp_who.
		- Waiting for currently running Transact-SQL statements or stored procedures to finish. To display a list of all active processes and locks, run sp_who and sp_lock, respectively.
		- Inserting a checkpoint in every database.

-- Права сервера/пользователи сервера/доступ для учетных записей сервера
	1. Для SQL Server
		- SQLServerMSSQLUser$ComputerName$MSSQLSERVER
		- Что входит
			Вход в систему в качестве службы (SeServiceLogonRight)1
			Замена токена уровня процесса (SeAssignPrimaryTokenPrivilege)
			Обход проходной проверки (SeChangeNotifyPrivilege)
			Назначение квот памяти процессам (SeIncreaseQuotaPrivilege)
			Разрешение на запуск модуля поддержки Active Directory в службах SQL Server
			Разрешение на запуск службы SQL Writer
			Разрешение на чтение службы журнала событий
			Разрешение на чтение службы удаленного вызова процедур (RPC)
		- Важно! Что касается экземпляров SQL Server в Windows Vista и более поздних версиях, такие права пользователя процесса, как «Вход в систему в качестве службы», «Замена маркера уровня процесса», «Обход проходной проверки» и «Назначение квот памяти процессам», предоставляются идентификатору безопасности службы SQL Server.
	2. SQL Agent
		- SQLServerSQLAgentUser$ComputerName$MSSQLSERVER
		- Что входит
			Вход в систему в качестве службы (SeServiceLogonRight)
			Замена токена уровня процесса (SeAssignPrimaryTokenPrivilege)
			Обход проходной проверки (SeChangeNotifyPrivilege)
			Назначение квот памяти процессам (SeIncreaseQuotaPrivilege)
	3. Analysis Services
		- SQLServerMSASUser$ComputerName$MSSQLSERVER
		- Что входит
			Вход в систему в качестве службы (SeServiceLogonRight)
	4. SSRS
		- SQLServerReportServerUser$ComputerName$MSRS10_50.MSSQLSERVER
		- Что входит
			Вход в систему в качестве службы (SeServiceLogonRight)
	5. Integration Services 
		- SQLServerDTSUser$ComputerName
		- Что входит
			Вход в систему в качестве службы (SeServiceLogonRight)
			Разрешение на запись в журнал событий приложений
			Обход проходной проверки (SeChangeNotifyPrivilege)
			Олицетворение клиента после проверки подлинности (SeImpersonatePrivilege)
			Разрешение на создание глобальных объектов (SeCreateGlobalPrivilege)
	6. Full-text search
		- SQLServerFDHostUser$ ComputerName$MSSQL10_50.MSSQLSERVER
		- Что входит
			Вход в систему в качестве службы (SeServiceLogonRight)
		- Важно! Что касается экземпляров SQL Server в Windows Vista и более поздних версиях, то право «Вход в систему в качестве службы» предоставляется идентификатору безопасности службы средства запуска FD.
	7. Браузер служб SQL Server
		- SQLServerSQLBrowserUser$ComputerName
		- Что входит
			Вход в систему в качестве службы (SeServiceLogonRight)

-- Информация о системе
	- Пуск >> Выполнить >> msinfo32
	- Пуск >> Выполнить >> cmd >> systeminfo -- Можно узнать виртуальная машина или нет
	
-- Lazy Writer
	- Lazywriter is a thread which is present for each NUMA node (and every instance has at least one) that scans through the buffer cache associated with that node. The lazywriter thread sleeps for a speciﬁc interval of time, and when it wakes up, it examines the size of the free buffer list. If the list is below a certain threshold, which depends on the total size of the buffer pool, the lazywriter thread scans the buffer pool to repopulate the free list. As buffers are added to the free list, they are also written to disk if they are dirty.So if there is no memory pressure and memory notification is stable it sleeps.
	- The sole purpose of Lazy Writer is to maintain some free buffers in the SQL Server Buffer Pool. Lazy writer runs periodically and check which buffers can be flushed and returned to the free pool. So even SQL Server is not under memory pressure, it will also work regularly
	- The work of scanning the buffer pool, writing dirty pages, and populating the free buffer list is primarily performed by the lazywriter.
	- Each instance of SQL Server has one lazywriter thread for each SOS Memory node created in SQLOS
	-- ответ в тестировании:
		- software non-uniform memory access (soft-numa) should be configured
	
-- Client Statistics
	- Влючается в Managment Studio сверху
	Number of server roundtrips
		a roundtrip consists of a request sent to the server and a reply from the server to the client. For example, if your query has three select statements, and they are separated by ‘GO’ command, then there will be three different roundtrips.
	TDS Packets sent from the client 
		TDS (tabular data stream) is the language which SQL Server speaks, and in order for applications to communicate with SQL Server, they need to pack the requests in TDS packets. TDS Packets sent from the client is the number of packets sent from the client; in case the request is large, then it may need more buffers, and eventually might even need more server roundtrips.
	TDS packets received from server
		is the TDS packets sent by the server to the client during the query execution.
	Bytes sent from client
		is the volume of the data set to our SQL Server, measured in bytes; i.e. how big of a query we have sent to the SQL Server. This is why it is best to use stored procedures, since the reusable code (which already exists as an object in the SQL Server) will only be called as a name of procedure + parameters, and this will minimize the network pressure.
	Bytes received from server
		is the amount of data the SQL Server has sent to the client, measured in bytes. Depending on the number of rows and the datatypes involved, this number will vary. But still, think about the network load when you request data from SQL Server.
	Client processing time 
		is the amount of time spent in milliseconds between the first received response packet and the last received response packet by the client.
	Wait time on server replies
		is the time in milliseconds between the last request packet which left the client and the first response packet which came back from the server to the client.
	Total execution time
		is the sum of client processing time and wait time on server replies (the SQL Server internal processing time)
		
-- Дата установки сервера/Как давно установлен сервер
	SELECT @@SERVERNAME as [Server Name],createdate as [SQL Server Install Date] FROM sys.syslogins WHERE loginname = 'NT AUTHORITY\система' OR loginname = 'NT AUTHORITY\NETWORK SERVICE' OR loginname = 'NT AUTHORITY\SYSTEM'

-- Посмотреть логины для сетевых папок
	Панель управления >> Учетные записи пользователей >> Администрирование учетных записей пользователей
	
-- Page Verify (Glenn Berry)
	- Советует всегда ставить на CHECKSUM, он более сложный (не на много сложней), но более надёжный.
	
-- Torn Page/разрыв страниц/разорванные таблицы
	SELECT * FROM MSDB.dbo.suspect_pages
	
-- xp_delete_file
	- Удаление файлов в папке
		EXECUTE master.dbo.xp_delete_file 0, N'S:\SqlMaintFolder\ ', N'bak', N'2012-10-10', 1		
		
		First parameter is ‘FileTypeSelected’, it says what kind of files to delete; 1 means Report Files, 0 means Backup files.
		Second parameter indicates, the path where the files are located. Make sure there is a trailing ‘\’
		Third parameter indicates the file extension. Make sure there is no dot in the file extension  [ '.bak' ]
		Fourth parameter: delete all files before this date and time.
		Fifth parameter indicates if you want to delete files from sub-folders or not.
		
-- logical reads
	- Может быть большим, потому что сначала идём на root level >> intermedia >> leaf level. Например для чтения одной записи мы получим 3 logical reads
	
-- Дни недели
	SET DATEFIRST 1
	SELECT
	 CASE (DATEPART(WEEKDAY,GETDATE()))
	  WHEN 1 THEN 'понедельник'
	  WHEN 2 THEN 'вторник'
	  WHEN 3 THEN 'среда'
	  WHEN 4 THEN 'четверг'
	  WHEN 5 THEN 'пятница'
	  WHEN 6 THEN 'суббота'
	  WHEN 7 THEN 'воскресенье'
	 END;
	 
-- Журнал сервера и журнал агента/обрезать лог/cut errorlog
	- Начать новый журнал сервера sp_Cycle_ErrorLog 
	- Начать новый журнал агента sp_Cycle_Agent_ErrorLog
	
-- Работа с sp_WhoIsActive. Adam Machanic. (http://sqlblog.com/search/SearchResults.aspx?q=A+Month+of+Activity+Monitoring&PageIndex=1)
	- Вывести все скритые данные 	
		EXEC sp_WhoIsActive 
		@show_sleeping_spids = 2, 
		@show_system_spids = 1, -- показать системную активность
		@show_own_spid = 1	-- показать вашу собственную активность
		
	- Вывести весь текст, а не только текущий запрос и то, что вызвало этот запрос
		@get_full_inner_text = 1,  @get_outer_command = 1
	
	- Вывести планы выполнения (дорогая операция)
		@get_plans = 1
		
	- Вывести все ожидани
		One waiting task: (1x: MINms)[wait_type] where MINms is the number of milliseconds that the task has been waiting
		Two waiting tasks: (2x: MINms/MAXms)[wait_type] where MINms is the shorter wait duration between the two tasks, and MAXms is the longer wait duration between the two tasks
		Three or more waiting tasks: (Nx: MINms/AVGms/MAXms)[wait_type] where Nx is the number of tasks, MINms is the shortest wait duration of the tasks, AVGms is the average wait duration of the tasks, and MAXms is the longest wait duration of the tasks
		@get_task_info = 1
		
	- Все параметры
		@filter sysname = '' 
		@filter_type VARCHAR(10) = 'session' -- тип фильтра
		@not_filter sysname = '' 
		@not_filter_type VARCHAR(10) = 'session' 
		@show_own_spid BIT = 0 -- показать вашу собственную активность
		@show_system_spids BIT = 0 -- показать системную активность
		@show_sleeping_spids TINYINT = 1 
		@get_full_inner_text BIT = 0 -- показать не текущий, выполняемый контекст, а весь 
		@get_plans TINYINT = 0 -- получить план выполнения. Отключено в начальном варианте, так как это достаточно дорогая операция
		@get_outer_command BIT = 0 
		@get_transaction_info BIT = 0 -- выводит информацию обо всех транзакциях данной сессии
		@get_task_info TINYINT = 1 -- Если установить параметр = 2, то будут выведены не только основные, но и все остальные ожидания
		@get_locks BIT = 0 -- показать блокировки. Добавляет xml column
		@get_avg_time BIT = 0 -- показывает среднее время выполнения для данной операции
		@get_additional_info BIT = 0 -- добавляет xml поле с дополнительной информацией
		@find_block_leaders BIT = 0 -- Добавляет столбец [blocked_session_count], который отображает как много процессов заблокировано этой сессией
		@delta_interval TINYINT = 0 -- Указать какое количество секунд будет замеряться затраты CPU и тд для каждой сессии. Иногда может казаться что какой-то запрос тратит в данный момент много ресурсов, так как у него поле CPU очень большое, но это общее значение, подсчитанное с начала его выполнения. Чотобы определить какое потребление CPU сейчас происходит для каждой сессии, надо указать этот параметр и задать время для отслеживания
			-- Добавил следующие столбцы				
				physical_io_delta
				reads_delta
				physical_reads_delta
				writes_delta
				tempdb_allocations_delta
				tempdb_current_delta
				CPU_delta
				context_switches_delta
				used_memory_delta
		@output_column_list VARCHAR(8000) = '[dd%][session_id][sql_text][sql_command][login_name][wait_info][tasks][tran_log%][cpu%][temp%][block%][reads%][writes%][context%][physical%][query_plan][locks][%]' -- позволяет указать порядок и выводимые столбцы
		@sort_order VARCHAR(500) = '[start_time] ASC' -- указат порядок сортировки
		@format_output TINYINT = 1 -- выводить ли время выполнения. Если у вас фиксированная длина стоблца, то используйте 2
		@destination_table VARCHAR(4000) = '' 
		@return_schema BIT = 0 
		@schema VARCHAR(MAX) = NULL OUTPUT 
		@help BIT = 0 -- вывести информацию по всем параметрам
		
	- Возможные колонки
		[dd%] - время выполнения
		[percent_complete] - как много уже выполнилось
		[status] - состояние запроса
		[collection_time] - когда был выполнен запрос sp_WhoIsActive
		[session_id]
		[request_id] - почти всегда 0 для активных запросов
		[tempdb_allocations] - как много 8кб страниц было размещено в tempdb
		[tempdb_current] - как много страниц размещено сейчас
		[used_memory]  - количество 8кб страниц памяти, использующихся
		[open_tran_count] - как много транзакций открыто для данной сессии
		[sql_text] - подробности запроса
		[wait_info]- чего ожидает данная сессия
		[CPU] and [reads] - общая сумма для всей сессии
		[host_name]
		[login_name]
		[sql_command] - выводится только при вклчённом параметре @get_outer_command = 1
		[tran_log_writes] - Выводит каждую базу данных, в которую была совершена запись этой сессией. Выводится только с включённым @get_transaction_info
		[tran_start_time] - Отражает время первой записи в используемую БД. Выводится только с включённым @get_transaction_info
		[tasks] - is the number of active tasks currently being used by the request.
		[context_switches] is the number of context switches that have been done for all of the tasks currently being used by the request. This number is updated in real time and can give a closer approximation of CPU utilization when evaluating requests that are being processed using a parallel plan.
		[physical_io] is the number of physical I/O requests that have been issued on behalf of all of the tasks currently being used by the request. Again, this number is updated in real time.
		
	- Фильрация вывода (всегда помните, что фильтры совокупны/агрегированы для каждой сессии)
		EXEC sp_WhoIsActive 
			@filter_type = 'login', 
			@filter = 'Adam03\Adam'
		
	- Исключение из поиска (можно комбинировать с обычным фильтром)
		EXEC sp_WhoIsActive 
			@not_filter_type = 'login', 
			@not_filter = 'blat';
			
	-- Получить данные в таблице. Можно использовать для периодического сбора данных
		-- Создать таблицу с нужной струкрурой
		DECLARE @s VARCHAR(MAX)

		EXEC sp_WhoIsActive 
			@format_output = 0, 
			@return_schema = 1, 
			@schema = @s OUTPUT

		SET @s = REPLACE(@s, '<table_name>', 'tempdb.dbo.quick_debug')

		EXEC(@s) 
		GO
		
		-- Поместить данные в созданную таблицу
		EXEC sp_WhoIsActive 
			@format_output = 0, 
			@destination_table = 'tempdb.dbo.quick_debug'

		GO
		
		-- Сделать выборку из таблицы
		SELECT * FROM tempdb.dbo.quick_debug
		
		-- Удалить таблицу
		DROP TABLE tempdb.dbo.quick_debug
		
-- VSS
	- Volume Shadow Copy Service
	- Позволяющая копировать файлы, с которыми в данный момент времени ведется работа и даже с системными и заблокированными файлами
	
-- WMI
	- Windows Management Instrumentation 
	- В дословном переводе — это инструментарий управления Windows. Если говорить более развернутo, то WMI — это одна из базовых технологий для централизованного управления и слежения за работой различных частей компьютерной инфраструктуры под управлением платформы Windows.
	
-- SSPI
	- Security Support Provider Interface
	— Программный интерфейс между приложениями и провайдерами безопасности. SSPI используется для отделения протоколов уровня приложения от деталей реализации сетевых протоколов безопасности и обеспечивает уровень абстракции для поддержки множества механизмов аутентификации.

-- Системные Базы данных
	- Resource
		База данных Resource, доступная только для чтения, содержит все системные объекты, входящие в SQL Server 2005. Системные объекты SQL Server, такие как sys.objects, физически расположены в базе данных Resource, а логически отображаются для каждой базы данных в схеме sys. База данных Resource не содержит ни пользовательских данных, ни метаданных. Физические файлы базы данных Resource имеют имена mssqlsystemresource.mdf и mssqlsystemresource.ldf. Эти файлы расположены в папке «<диск>:\Program Files\Microsoft SQL Server\MSSQL10_50.<имя_экземпляра>\MSSQL\Binn\». С каждым экземпляром SQL Server может быть связан один и только один файл mssqlsystemresource.mdf; кроме того, экземпляры не могут использовать этот файл совместно. Резервное копирование базы данных Resource средствами SQL Server не предусмотрено. Пользователь может создать резервную копию файла mssqlsystemresource.mdf или диска с этим файлом так, будто это двоичный файл (EXE), а не файл базы данных; однако восстановить такие резервные копии с помощью SQL Server не удастся. Восстановить резервную копию файла mssqlsystemresource.mdf можно будет только вручную; при этом следует соблюдать осторожность, чтобы не перезаписать текущую базу данных Resource устаревшей или потенциально небезопасной версией.
		
		-- определить номер версии
		SELECT SERVERPROPERTY('ResourceVersion');
		
		-- дата последнего обновления
		SELECT SERVERPROPERTY('ResourceLastUpdateDateTime');

		
-- Разница между DELETE и TRUNCATE
	-- DELETE
		1. DELETE is a logged operation on a per row basis.  This means that the deletion of each row gets logged and physically deleted.
		2. You can DELETE any row that will not violate a constraint, while leaving the foreign key or any other contraint in place.
		
	-- TRUNCATE
		1. TRUNCATE is also a logged operation, but in a different way. TRUNCATE logs the deallocation of the data pages in which the data exists.  The deallocation of data pages means that your data rows still actually exist in the data pages, but the extents have been marked as empty for reuse.  This is what makes TRUNCATE a faster operation to perform over DELETE.
		
-- Transparent Data Encryption (TDE)
	- Защищает данные на всех стадиях (на файловой системе)
	- Не требуется ничего дополнительного, только включить TDE
	- Как включить TDE?
		1. Create a Database Master key (на базе мастер)
			This may also create a Service Master Key (if it didn’t already exist)
		2. Create a certificate based on the Master Key (на базе мастер)
		3. Create a database encryption key
		4. Set encryption to ON

	- Нагрузка увеличивается на 3-8%
	- Желательно делать backup Service Master Key, Master Key, Database Key
	
-- SSD
	-- Можно использовать для
		1. Кэша (флеш кэш)
		2. Транзакционных файлов
		
	-- Особенности		
		- SSDs are expensive, so you want to make sure you’re getting the best ROI from them.
		- SSDs provide the most performance gain for random I/O workloads, not sequential I/O workloads.
		- For any portion of an overloaded I/O subsystem, an SSD will provide a performance boost—regardless of the I/O pattern—due to its nature of vastly reducing read-and-write latency.
		- Direct-attached SSDs should provide a more profound performance boost than those accessed over any kind of communications fabric.
		- Transaction logs are sequential write, with mostly sequential reads (and some random reads if there’s a lot of potential for transactions rolling back).
		- Tempdb may be very lightly used on your SQL Server. Even if they’re moderately used, they may not experience a high amount of data-file write activity.
		- These may well be data files for a volatile online transaction processing (OLTP) database or a transaction log for a database with a heavy insert workload—or they may well be tempdb.
		- Another piece of bad advice regarding SSDs is that you can stop being concerned about index fragmentation when using SSDs to store data files.
		- Фрагментация индексов на SSD влияет не так сильно, как на HDD, но это по прежнему создаёт дополнительные IO. Так же фрагментация сильно влияет на упреждающее чтение, что приводит к большему числу неиспользуемых страниц в памяти
		
-- WAITFOR 
	WAITFOR DELAY '22:30:00' -- Ждать определённого времени
	WAITFOR TIME '00:00:30' -- Ждать 30 сек
	
-- Ghost cleanup
	- Запускается каждые 5 секунд. 
	- Запись, удалённая в индексе SQL Server
	- На больших БД рекомендуют отключать данный режим с помощью флага 661, но при этом может возрасти занимаемое пространство под БД, до момент выполнения index rebuild or reorganize
	
-- Процессор	
	- При старте SQL Server для каждого процессора (не важно с гипертредингом или без) создаёт своё собственное расписание
	-- Hyper threading
		- Возможность ядра разделять разные команды 
		- Разные команды могут выполняться на одном процессоре одновременно
		- Если средняя нагрузка на процессор более 70%, то следует выключить
		
		-- Производительность
			- HT может помочь, когда серверу приходится одновременно выполнять множество запросов, причем число конкурирующих запросов превышает число ядер процессора(ов).
			- Включение HT скорее всего скажется негативно в сценариях, когда запросов относительно немного, но они "тяжелые".
		
	
-- Turbo Boost
	- Занижает частоту одного ядра и повышает другого. Занижает намного сильнее, чем повышает
	- Если средняя нагрузка на процессор более 70%, то следует выключить
	
-- Boost SQL Server priority
	- Может повлиять на сеть, которая обслуживает пользователей и STORAge
	- Могут быть проблемы при выключении службы или выполнении других заданий над файловой системой
	- Лучше вынести SQL Server на отдельную машину и не включать данную опцию
	
-- Affinity
	- Не стоит включать
	- При переносе с железа на железо может создать проблемы
	- Не помогает ограничить лицензии
	
-- Результат процедуры в таблицу

-- remote query timeout 
	- Единственный таймаут
	
-- dump memory
	- Non-yielding scheduler (SQL Server 2005 and above for the first occurrence. This is equivalent to a 17883 dump in SQL Server 2000.)
	- Non-yielding resource monitor (SQL server 2005 and above for the first occurrence)
	- Non-yielding IOCP listener (SQL server 2005 and above for the first occurrence)
	- Deadlocked Schedulers (SQL server 2005 and above. This is equivalent to a 17884 in SQL Server 2000.)
	- Exceptions/Assertions
	- Database Corruption
	- Latch Timeout
	
	-- Решение:
		1. Для первых четырёх (http://technet.microsoft.com/library/Cc917684)
	
-- Stack Dump
	- Попробуйте обновить SQL SERVER
	- Посмотреть причину в dump с помощью специальной программы
	- Можно включить флаг 2551, который создаст полный dump памяти. Размер = Full Dump - Data/index Pages (So you can look at Total Server Memory counter and reduce (number of pages) * 8 K as shown in sys.dm_os_buffer_descriptors)
	- Выполнить CHECKDB по всем БД, возможно одна из них повреждена
	
-- min_active_rowversion()
	- Возвращает наименьшее активное значение rowversion в текущей базе данных. Значение rowversion является активным, если оно используется в незафиксированной транзакции.
	- Если в базе данных не существует активных значений, то функция MIN_ACTIVE_ROWVERSION возвращает то же значение, что и @@DBTS + 1.
	
	-- Значение не меняется
		- Значение может не меняться по причине того, что транзакции ещё не закомичены
		- This of course shouldnt be a problem since the MIN_ACTIVE_ROWVERSION() approach was introduced to avoid dirty reads and posterior issues
	
-- rowversion/timestamp 
	- Тип данных timestamp является синонимом типа данных rowversion и подчиняется правилам поведения синонимов типа данных. В инструкциях языка DDL используйте по возможности тип данных rowversion вместо timestamp.	
	- Это тип данных, который представляет собой автоматически сформированные уникальные двоичные числа в базе данных. Тип данных rowversion используется в основном в качестве механизма для отметки версий строк таблицы. Размер при хранении составляет 8 байт. Тип данных rowversion представляет собой увеличивающееся значение, которое не сохраняет дату или время.
	- Каждая база данных имеет счетчик, который увеличивается при каждой операции вставки или обновления в таблице, содержащей столбец типа rowversion в базе данных.
	- Столбец типа rowversion можно использовать, чтобы определить, было ли произведено изменение какого-либо значения в строке с момента ее последнего считывания.
	- Для получения текущего значения rowversion используйте функцию @@DBTS
	- Можно добавить столбец rowversion к таблице, чтобы обеспечить целостность базы данных в случаях одновременного обновления строк несколькими пользователями. Также может возникнуть необходимость в данных о количестве строк и указании обновленных строк без отправки повторного запроса в таблицу.
	
-- Поиск в файле
	findstr "Что ищем" *
	
-- Truncate table
	- Инструкция TRUNCATE TABLE удаляет все строки таблицы, но структура таблицы и ее столбцы, ограничения, индексы и т. п. сохраняются. Чтобы удалить не только данные таблицы, но и ее определение, следует использовать инструкцию DROP TABLE.
	- Если таблица содержит столбец идентификаторов, счетчик этого столбца сбрасывается до начального значения, определенного для этого столбца
	- Не активирует триггер
	
	-- Преимущества TRUNCATE 
		- Используется меньший объем журнала транзакций. (Инструкция DELETE производит удаление по одной строке и заносит в журнал транзакций запись для каждой удаляемой строки. Инструкция TRUNCATE TABLE удаляет данные, освобождая страницы данных, используемые для хранения данных таблиц, и в журнал транзакций записывает только данные об освобождении страниц.)
		- Обычно используется меньшее количество блокировок (Если инструкция DELETE выполняется с блокировкой строк, для удаления блокируется каждая строка таблицы. Инструкция TRUNCATE TABLE всегда блокирует таблицу и страницу, но не каждую строку.)
		- В таблице остается нулевое количество страниц, без исключений. (После выполнения инструкции DELETE в таблице могут все еще оставаться пустые страницы. Например, чтобы освободить пустые страницы в куче, необходима, как минимум, монопольная блокировка таблицы (LCK_M_X). Если операция удаления не использует блокировку таблицы, таблица (куча) будет содержать множество пустых страниц. В индексах после операции удаления могут оказаться пустые страницы, хотя эти страницы будут быстро освобождены процессом фоновой очистки.)
	
	-- Нельзя выполнять
		- На таблицу ссылается ограничение FOREIGN KEY. (Таблицу, имеющую внешний ключ, ссылающийся сам на себя, можно усечь.)
		- Таблица является частью индексированного представления.
		- Таблица опубликована с использованием репликации транзакций или репликации слиянием.

-- Объекты по файловым группам/Что находится в файловых группах/File group
	SELECT o.[name], o.[type], i.[name], i.[index_id], f.[name]
	FROM sys.indexes i
	INNER JOIN sys.filegroups f
	ON i.data_space_id = f.data_space_id
	INNER JOIN sys.all_objects o
	ON i.[object_id] = o.[object_id]
	WHERE i.data_space_id = f.data_space_id
	AND o.type = 'U' -- User Created Tables
	GO 
	
-- Распределённые транзакции 
	- https://technet.microsoft.com/ru-ru/library/ms191440(v=sql.105).aspx
	- Приложения, написанные с помощью OLE DB, Open Database Connectivity (ODBC), ActiveX Data Objects (ADO) или DB-Library
	- Ошибка при зеркалировании в кластере http://support.microsoft.com/kb/926150/ru	
	- Распределенные транзакции выполняются на двух или более серверах, которые называются диспетчерами ресурсов. Управление транзакцией должно координироваться между диспетчерами ресурсов компонентом сервера, который называется диспетчером транзакций. Каждый экземпляр компонента SQL Server Database Engine может действовать как диспетчер ресурсов в распределенных транзакциях, координируемых диспетчерами транзакций, например, координатором распределенных транзакций (Майкрософт) (MS DTC) или другими диспетчерами транзакций, поддерживающими спецификацию Open Group XA обработки распределенных транзакций. Дополнительные сведения см. в документации по MS DTC.
	- Распределенную транзакцию в Transact-SQL можно запустить следующими способами:
		 - Явно начать распределенную транзакцию, используя инструкцию BEGIN DISTRIBUTED TRANSACTION.
				Можно также выполнить распределенный запрос к связанному серверу. Экземпляр компонента Database Engine вызовет MS DTC для обслуживания распределенной транзакции на связанном сервере. В рамках распределенной транзакции можно также вызвать удаленные хранимые процедуры на удаленном экземпляре компонента Database Engine.
		- Находясь в локальной транзакции, выполнить распределенный запрос.
			Если источник данных OLE DB поддерживает интерфейс ITransactionJoin, транзакция превращается в распределенную, даже если этот запрос является запросом только для чтения. Если источник данных не поддерживает интерфейс ITransactionJoin, допустимы лишь инструкции только для чтения.
		- Если была выполнена инструкция SET REMOTE_PROC_TRANSACTIONS ON и локальная транзакция вызывает удаленную хранимую процедуру на другом экземпляре компонента Database Engine, локальная транзакция становится распределенной.
			Компонент Database Engine использует MS DTC, чтобы координировать транзакцию с удаленным сервером. Обращения к удаленным хранимым процедурам выполняются вне области локальной транзакции, если REMOTE_PROC_TRANSACTIONS установлен в OFF. При откате локальной транзакции изменения, сделанные удаленной процедурой, не возвращаются. Фиксация изменений, произведенных удаленной хранимой процедурой, производится во время ее завершения, а не при фиксации локальной транзакции.
	-- Особенности
		1. Откатывает только текущую транзакцию, а не всю цепочку вложенности
		2. TCP-порт 135
		3. Где используется:
			1. Linked SERVER
			2. Mirrorin
			3. Любые подключения к удалённым источникам данных связанные с изменениями данных или вызовов процедур
			4. обновляющие два или более защищенных транзакциями ресурсов, например базы данных, очереди сообщений, файловые системы и т. д. Эти защищенные транзакциями ресурсы могут располагаться на одном компьютере или быть распределены по большому числу подключенных к сети компьютеров.
		4. MSDTC не требуется для экземпляров только со службами Службы Analysis Services
		5. Возможные порты 1000-65536
		6. При настройке кластера добавить зависимость для DTC в сервис SQL Server
		7.  When creating the MS DTC, moving the resource group into a group other than SQL Server or Exchange Server group is highly recommended. Creating the MS DTC resource in its own resource group and assigning it to a separate cluster group keeps the resource highly available. 
	-- Настройка
		1. Выглядит как отдельная служба ("Координатор распределённых транзакций")
		2. Администрирование > Службы компонентов > Компьютеры > Координатор распределённых транзакций
		3. По умолчанию каждая система использует свой локальный диспетчер транзакций службы DTC (Distributed Transaction Coordinator) для инициирования и согласования транзакций
		4. Поменять MSDTC с локального на другой можно Администрирование > Службы компонентов > Компьютеры > Мой компьютер > Свойсва > MSDTC
		5. Настроить безопасность: Администрирование > Службы компонентов > Компьютеры > Мой компьютер > "Координатор распределённых транзакций" > Локальная DTC > Свойства
		
-- Выгрузка данных в файл
	- sqlcmd -Slocalhost -W -k -q "SELECT * FROM [SIEMDB].[dbo].[SIEMAudit] WHERE InstanceName = 'FSRUMOSDT0009\ABS2D' AND StartTime BETWEEN '2015-02-24 00:00:00.000' AND '2015-02-25 00:00:00.000'" -o C:\FSRUMOSDT0009_ABS2D_20150112.csv  -- Выгрзка за определённую дату и инстанс
	
-- Информация о типах данных
	- sys.types
	- Не создавайте фиксированный текстовый тип данных и не фиксированный в одной таблице. Исключением могут быть временные таблицы
	
-- Разделители
	- SET QUOTED_IDENTIFIER ON - позволит объединять слова в объект не только с помощью [], но и с помощью ""
	
-- Произвольный размер Numeric
	- vardecimal
	- на уровне таблицы sp_tableoption '<table-name>', 'vardecimal storage format', 1
	- На уровне Бд EXEC sp_db_vardecimal_storage_format '<database-name>', 'ON'
	- Увеличит нагрузку на cpu, но уменьшит занимаемое пространство
	
-- Sequence object
	- Уникальное значение в пределах нескольких таблиц
	
-- Размещение данных
	- Посмотреть как харянтся данные в таблице (allocation unit)
		SELECT convert(char(8),object_name(i.object_id)) AS table_name,
		i.name AS index_name, i.index_id, i.type_desc as index_type,
		partition_id, partition_number AS pnum, rows,
		allocation_unit_id AS au_id, a.type_desc as page_type_desc,
		total_pages AS pages
		FROM sys.indexes i JOIN sys.partitions p
		ON i.object_id = p.object_id AND i.index_id = p.index_id
		JOIN sys.allocation_units a
		ON p.partition_id = a.container_id
		WHERE i.object_id=object_id(N'dbo.SIEMAudit');
		
-- DataPage
	- 8 kb = 8192 b
	- 96 b - page header
	- The maximum size of a single data row is 8,060
	- Row offset array/OFFSET TABLE имеет по 2 байта на строку в странице
	- В начале страницы располагаются фиксированные типы данных
	- Посмотреть страницы данных, которые выведены		
		SELECT sys.fn_PhysLocFormatter (%%physloc%%) AS RID, * FROM SIEMAudit;
	- Изучить
		SELECT allocated_page_file_id, allocated_page_page_id, page_type_desc
		FROM sys.dm_db_database_page_allocations
		(db_id('testdb'), object_id('Fixed'), NULL, NULL, 'DETAILED');
		
-- The order of integrity checks
	1. Defaults are applied as appropriate.
	2. NOT NULL violations are raised.
	3. CHECK constraints are evaluated.
	4. FOREIGN KEY checks of referencing tables are applied.
	5. FOREIGN KEY checks of referenced tables are applied.
	6. The UNIQUE and PRIMARY KEY constraints are checked for correctness.
	7. Triggers fire.
	
-- Таблицы в определённой файловой группе/распределение таблиц по файловым группам
	SELECT DISTINCT st.name FROM sysindexes si INNER JOIN sys.tables st ON si.id=st.[object_id] WHERE groupid =2
	
-- Узнать порт
	USE master
	GO
	xp_readerrorlog 0, 1, N'Server is listening on' 
	GO
	
-- sp_configure
	- Посмотреть какие изменения не применились
		SELECT * FROM sys.configurations WHERE value <> value_in_use
		
-- пакетная обработка/batch
	- Чтобы был 1 батч при вставке, можно использовать WHILE @a < 1000, а не go 1000
	
	--View service information / информация о сервисах SQL Server 
		SELECT * FROM sys.dm_server_services

	--View registry information / информация о настройках регистра для SQL Server
		SELECT * FROM sys.dm_server_registry
		
-- Автоновные БД
		- Нет ограничений на редакцию
		- Сначала разрешить на уровне сервера
		- В свойства БД > Option > Partial
		- Приложение должно знать, что работает с БД, а не с сервером
		- На сервере назначения, где будем разворачивать такие БД, требуется чтобы тоже были разрешены автономные БД
		- Перенос пользователей из сервера в БД (автономные БД) - sP_migrate_user_to_contained
		
		-- Обратить внимание
			- Во-первых обсудим не только с разработчиком политику безопасноти (хэши паролей теперь будут находиться в БД), во-вторых надо понимать, что везде, где требуется разворачивать данную БД, должна быть включена возможность использование Автономных БД на уровне сервера, в-третьих обсужу с ним вопрос его понимания о том, что приложение должно знать что работает с БД, а не с сервером.
			
-- Change Data Capture
	- Изменение в БД
	- Работает только в Enterprise
	- В SSIS уже есть готовые пакеты для Change Data Capture (в лабах есть)
	
	-- Как вкл
		1. Сначала на уровне БД.
		2. Потом для таблицы
		
-- Data Quality Services
	- Сервис качества данных
	- Отдельная программа
	- Можно использовать данные пакеты в SSIS, но для Matching нужно скачать пакет с CodePlex
	- Данный сервис не удаляет записи, а создаёт Базу Знаний, на основе которой в SSIS происходит обработка данных
	- Данный сервис для Аналитиков
	
	- Для данных важно
		1. Доверие
		2. Согласованность
		3. Дублирование
		
	- Состоит из:
		1. SERVER
		2. Client
		3. Data Cleaning SSIS Transformation
		
	-- База знаний (Knowledge Base)
		1. Значения домена (тип данных) (Knowledge Discovery)
		2. Правила домена (Domain Management)
		
	-- Data Cleansing Project
		- Проверка данных по справочнику. Можно проверять данные в таблицах по справочнику
		- При подтверждении коррекции мы сохраняем все варианты изменений в выбранный источник (например файл)
		
	-- Duplicate (Data Matching)
		 - На основе Базы знаний, Data Cleansing
		 - Задаём правила и выполняем поиск
		 
		 
-- Master Data Services (https://technet.microsoft.com/ru-ru/sqlserver/ff943581.aspx)?
	- Общие справочники для всех систем (Единые справочники)
	- Составляется единый справочник для всех систем, где для каждой записи указан общий И частный ID 
	- Сначала можно проверить данные с помощью Data Quality Services, а потом будем использовать Master Data Services
	- Есть оснастка для Excel
	- Есть web приложение
	
	-- пропустил 3 видео, 2:27 - 3:35
	
-- Data Transformation Services
	- Старый пакет загрузки данных из разных источников в SQL Server. 
	- Убран в 2014 или ранее	

-- assembly		
	select * from sys.assemblies


	SELECT 
		assembly = a.name, 
		path     = f.name
	FROM sys.assemblies AS a
	INNER JOIN sys.assembly_files AS f
	ON a.assembly_id = f.assembly_id
	WHERE a.is_user_defined = 1;


	CREATE ASSEMBLY [TimeZoneUtilities]
	FROM 'D:\TDPSql\TimeZoneUtilities.dll'

	drop assembly [System.Core]
	
	select * from sys.dm_clr_properties
	
	CREATE Function fnRegExMatch(@pattern nvarchar(max), @matchstring
	nvarchar(max)) returns bit
	AS EXTERNAL NAME
	CLRSQLExample.Validation.RegExMatch 

	CREATE PROCEDURE spCountStringLength (@inputString nvarchar(max))
	AS 
	EXTERNAL NAME
	tryexceptAssembly.[tryExceptSQLCLR.Class1].CountStringLength
	go

-- Best practice analiser
	см. файл "Сторонние разработки"
	
-- Маршруты
	route add -p 10.41.57.172 MASK 255.255.255.128 10.38.164.89
	route print
	route delete 10.41.57.172
	
-- SORT
	-- Для данных
		1. Если не помещается в памяти, то сваливается в tempdb (spill)
		2. Во время выполнения не выделяет больше памяти, чем было оцененно сначала. Вроде изменилось в SQL Server 2016
		
	-- Индексы
		1. Уже хранятся в сортированном виде и не требуют сортировки во время выборки (правильная)
		2. Может запрашивать больше памяти на ходу (Возможно только с 2016)
		
-- .xel
	SELECT * FROM sys.fn_xe_file_target_read_file('P:\MSSQL11.DBAXCL\MSSQL\Log\MSK-DB01-N2_DBAXCL_SQLDIAG_0_131024015868930000.xel', null, null, null);
	
-- ключи SET
	https://technet.microsoft.com/ru-ru/library/ms180765(v=sql.105).aspx
	
-- узнать из под кого запущен sql server/от кого запущен экземпляр
	sp_MSGetServerProperties
	
-- hard link/жесткие ссылки
	mklink /h C:\distr\11.trn C:\distr\1.trn -- Куда создаём, на что создаём
	
-- Узнать о перезагрузке Windows
	Event log > System > EventID 1074
	
-- Проверка backup на количество 
	SELECT run_date, Count(*) FROM msdb..sysjobhistory j1 INNER JOIN msdb..sysjobs j2 ON j1.job_id = j2.job_id
	WHERE j2.name = 'LOG backup' and j1.run_date = 20160601
	GROUP BY run_date
	HAVING Count(*) < 6
	
-- restore log/restore history
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
	
sp_server_diagnostics

select * FROM sys.dm_server_services

select * FROM sys.dm_os_volume_stats(2,1) -- Информация о volume под конкретным файлом БД

select * FROM sys.dm_server_registry

select * FROM sys.dm_os_sys_info


но есть такая жопа как 
select * from sys.dm_tran_locks with(nolock) where request_session_id < 0

dbcc openteran как правило помогает найти виновника, так же 
select name, log_reuse_wait_desc 
from sys.databases
покажет причину роста лога
dbcc loginfo - тоже полезна что бы понять что с журналом

Через sys.sysindexses выяснить размер таблиц постараться найти запросы которые их создают и обсудить м разрабами а нужно ли это

-- startup procedures
	-- Получить список процедур startup
		SELECT name,create_date,modify_date
		FROM sys.procedures
		WHERE OBJECTPROPERTY(OBJECT_ID, 'ExecIsStartup') = 1
		
	-- Добавить
		exec sp_procoption N'startup_check_trace', 'startup', 'on'
	
	-- Удалить
		exec sp_procoption N'startup_check_trace', 'startup', 'off'

-- SERVERNAME
	-- После переименования сервера, надо обязательно переименовать его и в SQL Server
	-- Требует перезагрузки
		sp_dropserver <old_name\instancename>;
		GO
		sp_addserver <new_name\instancename>, local;
		GO
		
-- Асинхронное выполнение/множественный вызов
	https://www.codeproject.com/articles/29356/asynchronous-t-sql-execution-without-service-broke
	
-- Виртуализация
	Минус в производительности
	Плюс в миграции
	Средние накладные расходы виртуализации - 6%
	
-- Единица чтения с диска - страница (page)

-- конвертации физических дисков в виртуальные для платформы Microsoft Hyper-V
	http://www.vmgu.ru/news/microsoft-hyper-v-disk2vhd-p2v-conversion
	
-- Удалённая работа/выполнение команд на удалённом компьютере/remote work
	- https://technet.microsoft.com/ru-ru/library/ms186243(v=sql.105).aspx
	1. EXECUTE ( 'RAISERROR (N''Hello'',1,1) WITH LOG' ) AT [AX2009MIA-SQL] (Требуется включить на Linked Server 2 галочки RPC)
	2. IBBER REMOTE JOIN
	
-- recursion/рекурсия/cte
	-- http://www.sql.ru/forum/316343/sql2005-populyarnye-zadachi-foruma-i-cte
	IF OBJECT_ID(N'Tempdb..#MyTest',N'U') IS NOT NULL
	DROP TABLE #MyTest

	SELECT parent_object_id,Count(*) as co INTO #MyTest FROM sys.objects
	WHERE parent_object_id <> 0
	GROUP BY parent_object_id

	;WITH 
	cus (parent_object_id,co,steps) AS
	(
	SELECT *,0 as steps FROM #MyTest
	UNION ALL
	SELECT t1.parent_object_id,t1.co,steps+1 FROM cus
	INNER JOIN #MyTest as t1 ON cus.parent_object_id = t1.parent_object_id 
	WHERE steps < t1.co
	)
	SELECT * FROM cus WHERE steps <> 0
	
-- PDW/parallel data warehouse
	1. Нужно работать как с Heap, так как всё нацелено на быстрое сканирование
	
-- native client alias (на клиенте)
	[HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo] – this is for x64 machines who happen to need a 32-bit alias.
	[HKEY_LOCAL_MACHINE\SOFTWARE\ Microsoft\MSSQLServer\Client\ConnectTo] – this is for either x86 machines, or for x64 machines that need a regular alias.
	Добавить строковый параметр, название = alias, внутри DBMSSOCN,shared-db1\mssqlshared1
	
-- Мониторинг давления памяти через Windows
	System: Available Memory Mb
	
	perf_counter["\Memory\Available MBytes"]
	
	{$MSSQL3} - Memory pressure from Windows
	
	{T_SQL_Server_Instance_Named_Three:perf_counter["\Memory\Available MBytes"].min(#3)}<(({T_SQL_Server_Instance_Named_Three:perf_counter["\Memory\Available MBytes"].last()}*0.05)+512) and {T_SQL_Server_Instance_Named_Three:perf_counter["\MSSQL${$MSSQL3}:Buffer Manager\Page Life Expectancy"].min(#3)}<({T_SQL_Server_Instance_Named_Three:perf_counter["\MSSQL${$MSSQL3}:Memory Manager\Total Server Memory (KB)"].last()}/4096)*300 and {T_SQL_Server_Instance_Named_Three:perf_counter["\MSSQL${$MSSQL3}:Memory Manager\Granted Workspace Memory (KB)"].min(#3)}>0

-- Wireshark 	
	- (ранее — Ethereal) — программа-анализатор трафика для компьютерных сетей Ethernet и некоторых других.
	
-- Ограничения SQL Server 
	https://docs.microsoft.com/en-us/sql/sql-server/maximum-capacity-specifications-for-sql-server
	
-- Посмотреть все dmv и dmf на сервере
	SELECT name, type, type_desc
	FROM sys.system_objects
	WHERE name LIKE 'dm_%'
	ORDER BY name
	
-- Архитектура создания моделей данных/модели данных/примеры моделей данных
	http://www.databaseanswers.org/data_models/index.htm