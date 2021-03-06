-- Основное
	- Переход занимает секунды
	- https://blogs.msdn.microsoft.com/psssql/2013/04/22/how-it-works-always-onwhen-is-my-secondary-failover-ready/
	- Увеличилось количество нод до 8 в SQL Server 2014
	- Можно перебрасывать не по 1 бд, а всю группу БД
	- В синхронном режиме транзакция сначала регистирируется в журнале, потом идёт одновременно и начало выполнение и запись в лог секондари, где REDO Log выполнит данную операцию. Операция считается завершённое после её выполнения на Primary и записи в лог на Secondary. 
	- В синхронном режиме всё равно есть дельта T, до появления данных даже в синхронном режиме, пока REDO LOG прочтёт новую транзакцию и применить её
	- В асинхронном режиме скорее всего команда уходит после COMMIT, но возможно при долгих транзакциях есть что-то вроде упреждающего чтения только для синхронизаци
	- До 2016 доступно только в Enterprise Edition. Ограничения на Standart Edition 2016
		A basic availability group may not contain replicas on instances older than SQL Server 2016.
		Only one database may exist in a basic availability group.
		The AUTOMATED_BACKUP_PREFERENCE setting of the availability group will be restricted to ‘PRIMARY’.
		The secondary replica is not readable:
		Any backup operations on the secondary will fail.
		CHECKDB will not be allowed on a secondary.
		The replicas in a basic availability group may be configured for synchronous or asynchronous commit.
		Basic availability groups may form a hybrid availability group (one replica on premise and one in an Azure virtual machine).
	
	-- Основное
	- http://www.brentozar.com/sql/sql-server-alwayson-availability-groups/
	- https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/prereqs-restrictions-recommendations-always-on-availability
	- Не использовать на Windows 2008
	- При failover соединения будут разорваны и могут не подняться, пока promary не будет в online
	- Позволяет обеспечить отказоучистойчивое решение с возможностью вынесение нагрузки от backup, SELECT на другие сервера
	- Даже если ваша БД не находится в Sapshot Isolation Level, AlwaysON всё равно работает в данном режиме чтобы уменьшить блокировки
	
	-- Плюсы
		1. Позволяет автоматически исправлять ошибки повреждения данных с реплики, но это бывает не моментально и запрос может завершиться с ошибкой (особенно backup), но следующий запуск будет успешным
		2. Может создавать статистику в tempdb для secondary, но обновлять её может только сам SQL Server, удалять можем самостоятельно. Очищается после перезагрузки или failover на текущую ноду
		3. Можно выполнить тонкую настройку как именно чтение будет уходить на secondary
			https://msdn.microsoft.com/en-us/library/hh213002(v=sql.130).aspx
		4. Передаваемые данные сжимаются и шифруются, чтобы уменьшить и защитить нагрузку для сети. На практике мы видели сжатие до 2.3 раз
	
	-- Минусы
		1. All queries that are executed against a readable secondary are automatically run using read-committed snapshot isolation.
			- Из-за этого все записи, которые передаются на AG имеют доп. 14 байт в конце строки для поддержки версионности. При включённом режиме readable secondary.
			- Получается индексы и таблицы начинают весить на 14 байт больше в каждой строке
			- Если не хватает места в page, то происходит Page Split
			-- Решение
				- Использовать fillfactor
		2. Лучше обеспечить резервный канал общения нод, чтобы не возникли проблемы с их "общением", в ином случае может сложится ситуация, когда и главная и реплики будут недоступны или доступны но на момент сбоя откатятся все транзакции
		3. Так как при запросе на реплику используется Sapshot Isolation Level, то долие запросы могут препятствовать очистки журнала от записей (Sapshot Isolation Level), которые требуются для репликации
		4. Ряд действий с primary replica может быть завершенё с ошибкой, если записи нужные secondary (DBCC SHRINKFILE)
		5. При активации чтения с secondary, Primary добавляет 14 байт к deleted, modified, or inserted data rows, чтобы поддерживать версионность
		6. Если запустить долгий запрос на чтение на Secondary, а на Primary удалить принадлежащий к этому запросу индекс, то будет ошибка
		7. Можно случайно с Secondary удалить реплику, что повлечёт за собой удаление её и на Primary
		8. Цепочка логов не синхронизируется, можно запутаться
		9. Не делает failover, когда под БД пропадают файлы или с БД что-то происходит. Это происходит по той причине, что AON может состоять не из 1 БД
		10. Если одна из реплик отвалилась, то AlwaysOn будет накапливать SQL Server:Memory Manager – Log Pool Memory (KB), чтобы восстановить реплику как можно быстрее. Что увеличит потребление памяти
		
	-- ВАЖНО
		1. Ассинхронная реплика никогда не может быть в режиме Automatic Failover. При переводе на ассинхронную реплику, ломается синхронность всего кластера
		2. Обязательно нужно поставить автоматический failover на главную ноду, чтобы она могла переехать в случае необходимости
		3. Прописываем роутинг, иначе сервер сам будет решать как производить переезд
		4. Для работы требуется кластер
		5. Не забыть в SQL Server Managment указать название кластера в разделе HAG для каждой ноды и поставить галочку, иначе SQL Server не сможет использовать данный кластер
		6. Исправление проблем	
			https://msdn.microsoft.com/en-us/library/ff878308(v=sql.110).aspx#ror
		7. Почему работает быстрее без доступа на чтение, не только из-за конкуренции ресурсов
			https://blogs.msdn.microsoft.com/sqlserverstorageengine/2011/12/22/alwayson-impact-of-mapping-reporting-workload-on-readable-secondary-to-snapshot-isolation/
		8. Если из под Primary пропадёт файл лога или данных, то автоматический failover не произойдёт
		9. Если исключим сервер из AON, то она может выйти из состояния NORECOVERY и заного добавить не получится, но можно отключить только БД 
			use master
			Alter Database [StackExchange.Bicycles.Meta] SET HADR OFF;
			RESTORE LOG WITH NORECOVERY
			ALTER DATABASE [StackExchange.Bicycles.Meta] SET HADR AVAILABILITY GROUP = [SENetwork_AG];
			ALTER DATABASE [StackExchange.Bicycles.Meta] SET HADR RESUME;
		10. Не понятно как отслеживать цепочку backup
		11. При добавлении/измении файлов БД основной реплики, на секондари произойдёт то же изменение.
		12. Нужна синхронизация джобов, пользователей, Linked Server
		13. Желательно чтобы пути файлов совпадали
		14. Безопасность уровня экземпляра
		15. Если экземпляр кластеризован, автоматический файловер невозможен
		16. 2016 можно строить кластеры без домена, аутентификация на сертификатах, sql аутентификации
		17. на секондари только архивация логов

	-- Производительность
		- Automatic Seeding & Compression. Параметр запуска -T9567 (http://www.sqlpassion.at/archive/2017/08/31/automatic-seeding-compression/?utm_source=DBW&utm_medium=pubemail)
		
-- Мониторинг/отставание
	SELECT 
	DB_NAME(database_id) AS [database],
	ag.name AS ag_name, ar.replica_server_name AS ag_replica_server, dr_state.database_id as database_id,
	is_ag_replica_local = CASE
	WHEN ar_state.is_local = 1 THEN N'LOCAL'
	ELSE 'REMOTE'
	END ,
	ag_replica_role = CASE
	WHEN ar_state.role_desc IS NULL THEN N'DISCONNECTED'
	ELSE ar_state.role_desc
	END,
	dr_state.last_hardened_lsn, dr_state.last_hardened_time,
	dr_state.log_send_queue_size,
	dr_state.redo_queue_size,
		datediff(s,last_hardened_time,
	getdate()) as 'seconds behind primary'
	FROM (( sys.availability_groups AS ag JOIN sys.availability_replicas AS ar ON ag.group_id = ar.group_id )
	JOIN sys.dm_hadr_availability_replica_states AS ar_state ON ar.replica_id = ar_state.replica_id)
	JOIN sys.dm_hadr_database_replica_states dr_state on ag.group_id = dr_state.group_id and dr_state.replica_id = ar_state.replica_id;
	
-- Инициализация/Запуск/Установка
	- Если хотим создать AON через самостоятельный RESTORE, то на SECONDARY необходимо восстановить БД в NORECOVERY
	
-- Удаление БД из группы достурности/DELETE
	- Можно выполнить только с Primary
	- После удаления БД на Primary будет как stand-alone, а на Secondary в Restoring, можно перевести БД в online (with recovery)
	1. Через SSMS	
			
-- Repair
	sys.dm_hadr_auto_page_repair again -- Позволяет посмотреть кае страницы были исправлены с реплики
	
-- Cluster		
	- Новые представления
	- Работа в одном домене, но в разных подсетях
	- Улучшен мониторинг
	
-- Обновление/upgrade
	https://msdn.microsoft.com/en-us/library/dn178483.aspx?f=255&MSPPError=-2147217396
	
-- HAG (https://msdn.microsoft.com/en-us/hh213151.aspx)
	- Всё равно на основе кластера
	- Нужно настраивать листенера (имя для подключения)
	- Обязательно требует кластер
	- Можно в HAG включить группу баз (несколько шт)
	- Может быть и синхронная реплика и асинхронная
	- Readable secondary replicas remain available when disconnected from the primary replica. 
	- To use active secondary replicas, you can create an availability group listener to route read requests to the active secondary replicas
	- Почитать про Routing  и url Routing  (https://msdn.microsoft.com/en-us/library/hh710054.aspx). Чтобы работал routing, мы должны приложению дать IP Listner. Всё равно строка подключения должна содержать (Server=tcp:MyAgListener,1433;Database=Db1;IntegratedSecurity=SSPI;ApplicationIntent=ReadOnly;MultiSubnetFailover=True). Такой настройкой мы только управляем поведением переключения.
		-- Read-only/read secondary/Обязательно настроить
		ALTER AVAILABILITY GROUP [AG1]
		 MODIFY REPLICA ON
		N'COMPUTER01' WITH 
		(SECONDARY_ROLE (ALLOW_CONNECTIONS = READ_ONLY));
		ALTER AVAILABILITY GROUP [AG1]
		 MODIFY REPLICA ON
		N'COMPUTER01' WITH 
		(SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://COMPUTER01.contoso.com:1433'));

		ALTER AVAILABILITY GROUP [AG1]
		 MODIFY REPLICA ON
		N'COMPUTER02' WITH 
		(SECONDARY_ROLE (ALLOW_CONNECTIONS = READ_ONLY));
		ALTER AVAILABILITY GROUP [AG1]
		 MODIFY REPLICA ON
		N'COMPUTER02' WITH 
		(SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://COMPUTER02.contoso.com:1433'));

		ALTER AVAILABILITY GROUP [AG1] 
		MODIFY REPLICA ON
		N'COMPUTER01' WITH 
		(PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=('COMPUTER02','COMPUTER01')));

		ALTER AVAILABILITY GROUP [AG1] 
		MODIFY REPLICA ON
		N'COMPUTER02' WITH 
		(PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=('COMPUTER01','COMPUTER02')));
		GO
	
	- Опция Readable - Read-intent (в контексте коннекта должно быть явно указано, если не указано, то БД не будет доступна). Если поставить "Yes", то бд будет доступна на чтение всегда, при этом на праймари нужно установить "Allow read/write connections", чтобы подключения с "ApplicationIntent=ReadOnly" уходили на Secondary
	
	-- Балансировка нагрузки
		- До 2016 версии вся нагрузка идёт на первую реплику, указанную в read_only_routing_server_name
		- Начиная с 2016 READ_ONLY_ROUTING_LIST = (('Server1','Server2'), 'Server3', 'Server4')  -- будет равномерно распределяться внутри первой группы (Server1 и Server2), если она недоступна, идёт далее 'Server3', 'Server4'
	
	-- Информация о HAG
		- Буду использовать следующие DMV sys.dm_hadr_availability_replica_states, sys.dm_hadr_database_replica_cluster_states, sys.dm_hadr_database_replica_states. На данный момент отсутствует полигон для написания конечных вариантов скриптов
		
		select* from sys.availability_groups

		select * from sys.dm_hadr_availability_group_states

		select
		T2.name as group_name,
		T3.replica_server_name,
		T1.role,
		T1.role_desc,
		T1.operational_state,
		T1.operational_state_desc,
		T1.connected_state,
		T1.connected_state_desc,
		T1.recovery_health,
		T1.recovery_health_desc,
		T1.synchronization_health,
		T1.synchronization_health_desc
		from sys.dm_hadr_availability_replica_states T1 
		inner join sys.availability_groups T2 on T2.group_id=T1.group_id
		inner join sys.availability_replicas T3 on T3.replica_id=T1.replica_id
		where T1.role_desc='PRIMARY'
		
		-- Посмотреть настройки/маршрутизацию readonly
			select ar.replica_server_name, rl.routing_priority, (select ar2.replica_server_name from sys.availability_read_only_routing_lists rl2 join sys.availability_replicas AS ar2 ON rl2.read_only_replica_id = ar2.replica_id where rl.replica_id=rl2.replica_id and rl.routing_priority =rl2.routing_priority and rl.read_only_replica_id=rl2.read_only_replica_id) as 'read_only_replica_server_name', read_only_routing_url
			from sys.availability_read_only_routing_lists rl join sys.availability_replicas AS ar ON rl.replica_id = ar.replica_id
		
		-- БД, в которых одновременно и автономные и обычные пользователи
			exec sp_msforeachdb @command1 = 
			'USE [?];

			IF (SELECT Count(DISTINCT authentication_type) FROM sys.database_principals WHERE authentication_type IN (1,2)) > 1
			BEGIN
				SELECT DB_NAME()
			END'

		-- Все пользователи сервера, включая атономных
			CREATE TABLE #contained_users (name nvarchar(255),[type] nvarchar(255),type_desc nvarchar(255))

			INSERT INTO #contained_users
			exec sp_msforeachdb @command1 = 'USE [?]; SELECT name,type,type_desc FROM sys.database_principals WHERE authentication_type = 2 '

			SELECT name COLLATE database_default,type COLLATE database_default,type_desc COLLATE database_default FROM sys.server_principals WHERE type IN ('S','U','G')
			UNION 
			SELECT name COLLATE database_default,type COLLATE database_default,type_desc COLLATE database_default FROM #contained_users

			DROP TABLE #contained_users 
	
	-- Мониторинг
		SELECT ag.name AS ag_name, ar.replica_server_name AS ag_replica_server,
		is_ag_replica_local = CASE
		WHEN ar_state.is_local = 1 THEN N'LOCAL'
		ELSE 'REMOTE'
		END ,
		ag_replica_role = CASE
		WHEN ar_state.role_desc IS NULL THEN N'DISCONNECTED'
		ELSE ar_state.role_desc
		END,
		dr_state.last_hardened_time,
		dr_state.log_send_queue_size,
		dr_state.redo_queue_size,
		dr_state.last_commit_time,
		dr_state.last_redone_time,
		dr_state.last_received_time,
		dr_state.last_sent_time,
		dr_state.log_send_queue_size,
		 datediff(s,last_hardened_time,
		getdate()) as 'seconds behind primary'
		FROM (( sys.availability_groups AS ag JOIN sys.availability_replicas AS ar ON ag.group_id = ar.group_id )
		JOIN sys.dm_hadr_availability_replica_states AS ar_state ON ar.replica_id = ar_state.replica_id)
		JOIN sys.dm_hadr_database_replica_states dr_state on ag.group_id = dr_state.group_id and dr_state.replica_id = ar_state.replica_id
	
	-- Listener
		- Становится кластерной ролью/ресурс со своим IP
		- Имя Listener нужно прописывать как источник данных
		- Будет зарегистрировано в DNS и как кластерный ресурс
		- То имя, которое дадим пользователям
		
	-- BACKUP на secondary
		- Не понятно как отслеживать цепочку backup в системных представлениях, если нода ездиет туда-сюда
		- Обязательно указать в настройках где именно может делаться backup
		- Можно настроить где делать backup свойства конкретной HAG > Backup Preferences
		- Только FULL (только COPY-only) и LOG
		
		- BACKUP DATABASE supports only copy-only full backups of databases, files, or filegroups when it is executed on secondary replicas. Note that copy-only backups do not impact the log chain or clear the differential bitmap.
		- Differential backups are not supported on secondary replicas.
		- BACKUP LOG supports only regular log backups (the COPY_ONLY option is not supported for log backups on secondary replicas).
		- A consistent log chain is ensured across log backups taken on any of the replicas (primary or secondary), irrespective of their availability mode (synchronous-commit or asynchronous-commit).
		- To back up a secondary database, a secondary replica must be able to communicate with the primary replica and must be SYNCHRONIZED or SYNCHRONIZING.
		
		-- Backup на Secondary
		- Требуется на каждом сервере установить данный скрипт
			IF sys.fn_hadr_backup_is_preferred_replica('RSNewsDb') <> 1
			Backup не делаем
			ELSE
			Backup делаем
		
	-- Пример:
		1. Создаём новую HAG
		2. Добавляемноды
		3. Создаём Listner
		4. Ставим автоматический файловер на те ноды, на которые будем переводить. Если перевести на непоставленный, то сломается синхронизация. На основную ноду нужно так же поставить эту галочку, иначе ничего не произойдёт
		5. Не забываем прописать роутинг
			https://msdn.microsoft.com/en-us/library/hh710054(v=sql.110).aspx

-- Подключение readonly
	-- sqlcmd
		sqlcmd -S rsnews-db1 -E -d rsnewsdb -K readonly
	-- Код
		<add name="RsConnectionString" connectionString="Server=tcp:rsnews-db1;Database=RSNewsDb;persist security info=True;user id=EfCodeFirstUser;password=Q!w2e3r4t5;MultipleActiveResultSets=True;ApplicationIntent=ReadOnly;MultiSubnetFailover=True;App=RS.ES.Server.Filters UAT" providerName="System.Data.SqlClient" />
	-- SSMS	
		Initial Catalog=DB NAME;ApplicationIntent=ReadOnly;
	
-- Изыскания
	1. Система работает через pull, то есть Secondary спрашивает у Primary новые данные
	2. Передаётся файл лога (block log) и в синхронном режиме Primary ждёт когда записи попадут в лог Secondary (harder aknoladge)
	3. Sync always commit only if both replica harder commit in log
	4. В каспесрком возникают проблемы когда нагрузка на AlwaysOn достигает 250 batch/sec
	5. Без доступа на чтение работает быстрее (так как нет snapshot isilation level и до 14 byte)
	6. Если был Restore, то нужно пересобирать все реплики

-- Конфигурация
	1. Просто HAG на разных машинах
		-- Плюсы
			1. Меньше слоёв (меньше точек отказа)
			2. Легко управлять
			3. Физически разные сервера
		-- Минусы
			1. Возможны случаи автоматического отключение failover
			2. Дополнительная задержка на Sync режим
			3. В случае отказа вся нагрузка ляжет на primary
	2. 2 хоста 2 кластерные группы и по верх них HAG
		-- Плюсы
			1. Обеспечение переключений пользователей на стороне кластера
			2. Будут жить оба экземпляра
		-- Минусы
			1. Сложность управления
			2. Больше точек отказа
			3. При потере дисков на Primary не будет автоматического переезда HAG
	3. 3 хоста, 2 для обычного Cluster и 1 для HAG на него
	
-- Ручное добавление ноды/Manually Prepare a Secondary Database for an Availability Group
	1. Восстановить последний FULL/DIFF WITH NORECOVERY
	2. Восстановить все сделанные после него LOG WITH NORECOVERY
	3. Добавить новую ноду в AlwaysOn
	
-- Ошибки/Error
	-- Recovery Pending
	1. Потеря файла лога Primary/Secondary
		- Если лог можно вернуть, то просто делаем ALTER DATABASE test SET ONLINE. Это позволит заставить SQL Server заного поискать лог
		- Если не получается вернуть лог, то делаем failover на другую ноду, отключаем эту и занимаемся её восстановлением. При этом необходимо будет заного пересобрать реплику
	2. Пауза/Pause
		- Статус может появится, если поставить реплику на паузу, достаточно просто возобновить репликацию
	3. Если что-то случилось
			use master
			Alter Database [StackExchange.Bicycles.Meta] SET HADR OFF;
			RESTORE LOG WITH NORECOVERY
			ALTER DATABASE [StackExchange.Bicycles.Meta] SET HADR AVAILABILITY GROUP = [SENetwork_AG];
			ALTER DATABASE [StackExchange.Bicycles.Meta] SET HADR RESUME;
			
	-- Не хватает потоков/worker
		sp_configure 'max worker threads'
			
			
-- Alert/Мониторинг/Catch errors
	-- Обратить внимание на ('35273'),('35274'),('35275'),('35254'),('35279'),('35262'),('35276')
	-- 1480 - AG Role Change (failover)
	EXEC msdb.dbo.sp_add_alert
			@name = N'AG Role Change',
			@message_id = 1480,
		@severity = 0,
		@enabled = 1,
		@delay_between_responses = 0,
		@include_event_description_in = 1;
	GO
	EXEC msdb.dbo.sp_add_notification 
			@alert_name = N'AG Role Change', 
			@operator_name = N'mssql-alerts', 
			@notification_method = 1; 
	GO

	-- 35264 - AG Data Movement - Resumed
	EXEC msdb.dbo.sp_add_alert
			@name = N'AG Data Movement - Suspended',
			@message_id = 35264,
		@severity = 0,
		@enabled = 1,
		@delay_between_responses = 0,
		@include_event_description_in = 1;
	GO
	EXEC msdb.dbo.sp_add_notification 
			@alert_name = N'AG Data Movement - Suspended', 
			@operator_name = N'mssql-alerts', 
			@notification_method = 1; 
	GO

	-- 35265 - AG Data Movement - Resumed
	EXEC msdb.dbo.sp_add_alert
			@name = N'AG Data Movement - Resumed',
			@message_id = 35265,
		@severity = 0,
		@enabled = 1,
		@delay_between_responses = 0,
		@include_event_description_in = 1;
	GO
	EXEC msdb.dbo.sp_add_notification 
			@alert_name = N'AG Data Movement - Resumed', 
			@operator_name = N'mssql-alerts', 
			@notification_method = 1; 
	GO
	
-- Список событий о AlwaysON
	SELECT * FROM sys.messages WHERE 
	[text] like '%availability%'
	AND language_id = 1033
	
	SELECT message_id, severity, is_event_logged, text 
	FROM sys.messages AS m 
	WHERE m.language_id = SERVERPROPERTY('LCID') 
	  AND  (m.message_id=(9691) 
			OR m.message_id=(35204) 
			OR m.message_id=(9693) 
			OR m.message_id=(26024) 
			OR m.message_id=(28047) 
			OR m.message_id=(26023) 
			OR m.message_id=(9692) 
			OR m.message_id=(28034) 
			OR m.message_id=(28036) 
			OR m.message_id=(28048) 
			OR m.message_id=(28080) 
			OR m.message_id=(28091) 
			OR m.message_id=(26022) 
			OR m.message_id=(9642) 
			OR m.message_id=(35201) 
			OR m.message_id=(35202) 
			OR m.message_id=(35206) 
			OR m.message_id=(35207) 
			OR m.message_id=(26069) 
			OR m.message_id=(26070) 
			OR m.message_id>(41047) 
			AND m.message_id<(41056) 
			OR m.message_id=(41142) 
			OR m.message_id=(41144) 
			OR m.message_id=(1480) 
			OR m.message_id=(823) 
			OR m.message_id=(824) 
			OR m.message_id=(829) 
			OR m.message_id=(35264) 
			OR m.message_id=(35265) 
	)
	
	
-- Active Directory
	1. Создать учётку Listener и disable
	2. Дать на неё полные права тому кто устанавливает, обеим нодам + учётке кластера