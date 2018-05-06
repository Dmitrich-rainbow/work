-- SmartTest SQL SERVER/первоначальное тестирование SQL Server
	E:\SQL Scripts\Скрипты\sp_Blitz.sql
	
-- sysinternals/утилиты/прозводительность/анализ	
	- https://technet.microsoft.com/ru-ru/sysinternals

-- Performance Monitor
	Пуск >> Выполнить >> MMC >> File >>  add snapin >> perfmon >> настроить счётчики >> Сохранить

-- Raid
	Raid 0: I/O на диск = (чтений + записей) / число дисков массива
	Raid 1: I/O на диск = [чтений + (записей *2)] / 2
	Raid 5: I/O на диск = [чтений + (записей *4)] / число дисков массива
	Raid 10: I/O на диск = [чтений + (записей *2)] / число дисков массива

-- Память
	- Наиболее важные счётчики для памяти (http://simplesqlserver.com/2013/08/19/fixing-page-life-expectancy-ple/):
		1. SQLServer:Buffer Manager - Free List Stalls/sec -- Number of requests per second that had to wait for a free page
		2. SQL Server:Buffer Manager - Lazy Writes/sec -- Должно быть < 20. How many pages are written to disk outside of a checkpoint due to memory pressure. Indicates the number of buffers written per second by the buffer manager's lazy writer. The lazy writer is a system process that flushes out batches of dirty, aged buffers (buffers that contain changes that must be written back to disk before the buffer can be reused for a different page) and makes them available to user processes. The lazy writer eliminates the need to perform frequent checkpoints in order to create available buffers.
		3. SqlServer:Buffer Manager - Page reads/sec -- Количество текущих чтений. Number of physical database page reads that are issued per second. This statistic displays the total number of physical page reads across all databases. Because physical I/O is expensive, you may be able to minimize the cost, either by using a larger data cache, intelligent indexes, and more efficient queries, or by changing the database design
		4. SqlServer:Buffer Manager - Page writes/sec -- Количество текущех записей
		5. SQLServer: Buffer Manager\Page life expectancy /* Если < 300, то возможна нехватка памяти.  Adam Machanic утверждает что это было актуально 10 лет назад, когда было макс 4гб оперативной памяти. Сейчас это может означать что в системе выполняется больше дисковых операций, чем нужно. Формула от Jonathan Kehayias - DataCacheSizeInGB/4GB *300.
			-- Причины:
				1. DBCC CHECKDB
				2. INDEX REBUILD
				3. Сброс памяти (Flush)
			-- Исследование
				1. sys.dm_os_waiting_tasks (на наличие запросов с большим количеством чтений, PAGEIOLATCH_SH)
				2. sys.dm_exec_query_stats (искать запросы с большим количеством чтений)
				3. sys.dm_exec_query_memory_grants (искать запросы, которые требуют много памяти)
			- Стоит обращать внимание на количество NUMA node, так как нехватка памяти одной ноде, может сказаться на всю статистику 
			- if there is a memory pressure. Either it will be external or internal. if there is a external memory pressure that means os is not having sufficient amount of free memory to os.
			- Drop Unused Indexes
			- Merge Duplicate Indexes
			- Watch for Big Queries
			- Index Maintenance – Defrag
			- Index Maintenance – Statistics
			- Purge Your Data
			- Missing Indexes
			- Лишние столбцы в индексе			
			- Включить 'Lock Pages in Memory', чтобы не отдавать остальным память
			- Обязательно посмотреть счётчик Buffer Cache Hit Ratio 
			
			-- Отображает информацию о объёме использования оперативной памяти по данным по БД.   -- Get total buffer usage by database
			SELECT DB_NAME(database_id) AS [Database Name],
			COUNT(*) * 8/1024.0 AS [Cached Size (MB)]
			FROM sys.dm_os_buffer_descriptors
			WHERE database_id > 4 -- exclude system databases
			AND database_id <> 32767 -- exclude ResourceDB
			GROUP BY DB_NAME(database_id)
			ORDER BY [Cached Size (MB)] DESC;
			
			-- Найти Index Scan в кэше планов
			SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
			DECLARE @IndexName AS NVARCHAR(128) = 'PK__TestTabl__FFEE74517ABC33CD';

			-- Make sure the name passed is appropriately quoted
			IF (LEFT(@IndexName, 1) <> '[' AND RIGHT(@IndexName, 1) <> ']') SET @IndexName = QUOTENAME(@IndexName);
			--Handle the case where the left or right was quoted manually but not the opposite side
			IF LEFT(@IndexName, 1) <> '[' SET @IndexName = '['+@IndexName;
			IF RIGHT(@IndexName, 1) <> ']' SET @IndexName = @IndexName + ']';

			-- Dig into the plan cache and find all plans using this index
			;WITH XMLNAMESPACES 
			   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')    
			SELECT 
			 stmt.value('(@StatementText)[1]', 'varchar(max)') AS SQL_Text,
			 obj.value('(@Database)[1]', 'varchar(128)') AS DatabaseName,
			 obj.value('(@Schema)[1]', 'varchar(128)') AS SchemaName,
			 obj.value('(@Table)[1]', 'varchar(128)') AS TableName,
			 obj.value('(@Index)[1]', 'varchar(128)') AS IndexName,
			 obj.value('(@IndexKind)[1]', 'varchar(128)') AS IndexKind,
			 cp.plan_handle,
			 query_plan,
			cp.size_in_bytes
			FROM sys.dm_exec_cached_plans AS cp 
			CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
			CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS batch(stmt)
			CROSS APPLY stmt.nodes('.//IndexScan/Object[@Index=sql:variable("@IndexName")]') AS idx(obj)
			OPTION(MAXDOP 1, RECOMPILE);			
		*/
		5.1. SQLServer:Buffer Node - Page life expectancy -- Демонстрирует PLE по каждой NUMA node
		6. SQLServer:Memory Manager - Target Server Memory (KB) -- постоянно показывает высокие значения по сравнению с объемом физической памяти компьютера, это может означать, что требуется установить в компьютер больше памяти. Tells you how much memory SQL Server would like to use to operate efficiently. If the SQLServer:Memory Manager: Total Server Memory (KB) counter is more or equal than the SQLServer:Memory Manager: Target Server Memory (KB) counter, this indicates that SQL Server may be under memory pressure and could use access to more physical memory.
		7. SQLServer:Memory Manager - Total Server Memory (KB) -- Tells you how much memory your SQL Server is currently using.	
		8. SQL Server:Buffer Manager - Database pages и SQL Server:Buffer Manager - Total pages -- Если величина Database pages- большая часть от числа Total pages (более 50 процентов), знайте, что вы имеете дело с приложением, которому требуется перерабатывать большое количество данных. 
		9. SQL Server:Access Methods:Full Scans/sec -- позволяет контролировать число полных сканирований за секунду, выполняемых SQL Server. Если пользователь решит, что для него слишком частое применение полного сканирования нежелательно, можно использовать SQL Server Profiler и, просматривая события в Showplan Statistics в категории Performance, найти то из предложений SQL Server, которое приводит к полному сканированию. должно быть 1 к 1000 SQL Server:Access Methods:Index Search
		10. SQL Server:Plan Cache -> Cache Hit Ratio -- This deals with the procedure cache. This indicates how many query plans exist in the cache vs how many were compiled at run time. This number starts very low after the system restart and should consistently stay close to 95-100%
		11. SQL Server:Plan Cache -> Cache Pages -- This deals with the procedure cache and tells how many 8 KB pages are used for the procedure cache. Low Plan Cache: Cache Hit Ratio coupled with high number of Plan Cache: Cache pages tells that the system might be suffering from dynamic sql issues.
		12.  SQL Server:Memory Manager:Granted Workspace Memory (KB) -- Общий объем памяти, предоставленный в настоящее время для выполнения процессов, таких как хэш, сортировка, массовое копирование и создание индекса.
		13. SQL Server:Memory Manager - Connection Memory (KB) -- Общий объем динамической памяти, которую использует сервер для обслуживания соединений.
		14. SQL Server:Memory Manager - Lock Memory (KB) -- Общий объем динамической памяти, которую использует сервер для блокировок.
		15. SQL Server:Memory Manager - Maximum Workspace Memory (KB) -- Максимальный объем памяти, доступный для выполнения процессов, таких как хэш, сортировка, массовое копирование и создание индекса.
		16. SQL Server:Memory Manager - Memory Grants Outstanding -- Общее число процессов, успешно получивших предоставление памяти рабочего пространства.
		17. SQL Server:Memory Manager - Memory Grants Pending -- Общее число процессов, ожидающих предоставления памяти рабочего пространства. Если больше Memory Grants Outstanding, значит память перегружена
		18. SQL Server:Memory Manager - SQL Cache Memory (KB) -- Общий объем динамической памяти, которую использует сервер для динамического кэша SQL.
		19. SQL Server:Memory Manager - Optimizer Memory (KB) -- Общий объем динамической памяти, которую использует сервер для оптимизации запросов.		
		20. SQL Server:Access Methods - Page Split -- разбиение страниц
		21. SQL Server:Locks - Average wait time -- общая очередь на наложение блокировки
		22. SQL Server:Buffer Manager - Free list stalls/sec -- Число инициированных за одну секунду запросов, которым пришлось дожидаться свободной страницы.
		23. SQL Server:Buffer Manager - Page lookups/sec -- Число инициируемых за секунду запросов поиска страницы в буферном пуле.
		24. SQL Server:Buffer Manager - Page reads/sec --Число инициируемых за одну секунду физических операций чтения страниц баз данных. Этот статистический показатель отражает общее количество физических операций чтения страниц из всех баз данных. Физический ввод-вывод связан с большой тратой ресурсов, но иногда ее можно свести к минимуму, используя более объемный кэш данных, интеллектуальные индексы и более эффективные запросы или изменяя структуру базы данных.
		25. SQL Server:Buffer Manager - Page writes/sec -- Число инициируемых за одну секунду физических операций записи страниц баз данных.
		26. SQL Server:General Statistics - Process blocked -- количество заблокированных процессов
		27. SQL Server:Buffer Manager:Free Pages
		28. Для этого надо знать, использует или нет SQL Server право учетной записи SQL Server "Lock Page In Memory", Выяснить это можно из свойств учетной записи, а можно косвенно, через счетчики Performance Monitor. Дело в том, что если право учетной записи SQL Server "Lock Page In Memory" не установлено, то вся (или почти вся) используемая память будет частью рабочего набора процесса sqlservr.exe. Если же это право установлено, то при этом (скрыто) используется механизм AWE (Address Windows Extension) и основная память под Буферный пул будет размещена за пределами процесса sqlservr.exe.
		29. Окончательный ответ нам поможет дать счетчик SQL Server: Lazy Writes/sec, отображающий как часто срабатывает процесс Lazy Writer. Мы знаем, что это процесс активируется тогда, когда у SQL Server заняты около 75% выделенных буферов. Его задача выполнить фиксацию данных и очистить буферы. Для систем имеющих значительный запас памяти этот счетчик должен быть близок к нулю
		
		-- Нехватка памяти по логам SQL Server (RESOURCE_MEMPHYSICAL_LOW)
			SELECT 
				EventTime,
				record.value('(/Record/ResourceMonitor/Notification)[1]', 'varchar(max)') as [Type],
				record.value('(/Record/ResourceMonitor/IndicatorsProcess)[1]', 'int') as [IndicatorsProcess],
				record.value('(/Record/ResourceMonitor/IndicatorsSystem)[1]', 'int') as [IndicatorsSystem],
				record.value('(/Record/MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint') AS [Avail Phys Mem, Kb],
				record.value('(/Record/MemoryRecord/AvailableVirtualAddressSpace)[1]', 'bigint') AS [Avail VAS, Kb]
			FROM (
				SELECT
					DATEADD (ss, (-1 * ((cpu_ticks / CONVERT (float, ( cpu_ticks / ms_ticks ))) - [timestamp])/1000), GETDATE()) AS EventTime,
					CONVERT (xml, record) AS record
				FROM sys.dm_os_ring_buffers
				CROSS JOIN sys.dm_os_sys_info
				WHERE ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR') AS tab
			ORDER BY EventTime DESC;
					
	-- Profiler
	
		-- Блокировки
			Errors and Warnings: Blocked process report -- Для его отображения надо включить через конфигурацию сервера blocked process threshold
		
		-- Для памяти
			1. SP:CacheMiss -- которое сообщит, что SQL Server искал и не нашел план запроса
			2. SP:CacheRemove -- Класс событий SP:CacheRemove указывает на то, что хранимая процедура была удалена из кэша планов.
			3. SP:CacheInsert -- Которое сообщает, что SQL Server создал новый план запроса в кэше плана
			4. Errors and Warnings - Hash Warning -- Неправильная оценка плана и скидывание данных на диск
			5. Errors and Warnings - Sort Warning -- Неправильная оценка плана и скидывание данных на диск
			
		-- Ошибки
				Errors and Warnings:
					Exception
					User Error Message
	
	-- Остальные		
		SQL Server:Buffer Manager/Free Pages -- > 640 (Measure of how many free pages are in the buffer pool for use). Total number of pages on all free lists (free lists track all of the pages in the buffer pool that are not currently allocate to a data page, and are therefore available for usage immediately)		
		SqlServer:Buffer Manager\Stolen pages -- (Stolen + Reserved) / 100  = min sharing memmory
		SqlServer:Buffer Manager\Reserved pages -- Stolen + Reserved < max sharing memmory
		SQLServer:Buffer Manager\Database pages		
		SQLServer: Buffer Manager: Buffer Cache Hit Ratio /*Очень сомнительный счётчик, так как он может показывать хорошее значение, но не будет свободных страниц и жизнь страницы будет меньше 1 (https://www.simple-talk.com/content/article.aspx?article=1426). Желательно значение коэффициента, равное 90 процентам или выше. Добавляйте память, пока значение не будет постоянно больше 90 % для OLAP и 95% для OLTP. Значение выше 90 процентов указывает на то, что более 90 процентов всех запрошенных данных были получены из кэша данных.*/  
			- Не может использоваться как индикатор недосттка памяти и показатель достаточности размера буферного пула, поскольку на выполнение операции ReadAhead данный счетчик никак не реагирует, хотя при этом считывается огромные объемы данных. Связано такое поведение с тем, что данный счётчик учитывает только чисто физические операции чтения выполнение которых инициировано процессором запросов для загрузки страниц необходимых для выполнения данного запроса, и он никак не учитывает операции ReadAhead, которые по объему загружаемых с диска данных могут в разы превышать эти операции. (http://blogs.technet.com/b/sqlruteam/archive/2014/03/12/sql_5f00_server_5f00_disk_5f00_analysis_5f00_overview.aspx)
		SQLServer:Buffer Manager\Total pages -- Если Database pages 50% и более от Total pages - приложение, которому требуется перерабатывать большое количество данных		
		SQLServer:Memory Manager\Database Cache Memory (KB) -- Указывает объем памяти, который используется в настоящий момент сервером для кэша страниц базы данных.(SQL Server 2012)	
		Memory - Available Mbytes -- Лучше чтобы было 500 Мб
		Memory - Pages/sec 
		Pagind File - % Usage
		Норма на соотношение Workfiles Created/sec к Batch Requests/sec  соствляет не более 20%.
		Для этого необходимо просмотреть состав процедурного кэша. Сделать это можно используя объект Plan Cache и счетчик Cache Pages. Данный счетчик измеряет количество 8-ми килобайтных страниц  выделенных под хранение различных типов планов выполнения. Типы планов отображаются через Instance, и могут быть:
			Bound Trees (Результаты алгебраизации View, можно сказать, что это алгоритмы выборки данных из View)
			Extended Storage procedures (Планы выполнения расширенных хранимых процедур)
			Object Plans (Планы выполнения хранимых процедур, триггеров и некоторых видов функций)
			SQL Plans (Планы выполнения динамического TSQL кода, сюда же попадают автопараметризованные запросы) 
			Temporary Tables & Tables Variables (Кэшированные метаданные по временным таблицам и табличным переменным).
			Проанализировав показания этих счетчиков мы видим, что 80...90%% объема процедурного кэша составляет SQL Plans, что и приводит к перегрузке процессоров.

-- Tempdb
	SQLServer:Transactions \ Free Space in tempdb (KB)
		
-- Уровень активности на сервере
	SqlServer: SQL Statistics - Batch Requests/sec -- represents the number of SQL Statements that are being executed per second. Основной параметр активности сервера
	SQLServer: Databases - Transactions/sec -- Можно смотреть активность на БД, но данный параметр отслеживает не все команды. Данный параметр показывает огромные цифры и не может сраниваться с SqlServer: SQL Statistics - Batch Requests/sec 
	SqlServer: SQL Statistics - SQL Compilations/sec -- Обычно должно быть около 10% от Batch Requests/sec
	SqlServer: SQL Statistics - SQL Recompilations/sec -- В идеале должно быть малым 1% от Batch Requests/sec. Соотношение Recompilations/sec и Compilations/sec около 10%
		- The SQL Compilations/Sec measure the number of times SQL Server compiles an execution plan per second. Compiling an execution plan is a resource-intensive operation. Compilations/Sec should be compared with the number of Batch Requests/Sec to get an indication of whether or not complications might be hurting your performance.
	SQLServer: General Statistics - User Connections -- Если этот счётчик постоянно ростёт, то возможно приложение не корректно завершает сессии
	SQLServer: Latches - Latch Waits/sec -- Latch`s, которые не могут быть наложены немедленно (in memory access)
	SQLServer: Locks - Lock Waits/sec -- Lock`s, которые не могут быть наложены немедленно (физический уровень) и ожидают
	SQLServer: Locks - Number of Deadlocks/sec		
	SQLServer: Locks - Average Wait Time -- This is the average wait time in milliseconds to acquire a lock. Lower the value the better it is. If the value goes higher then 500, there may be blocking going on; we need to run blocker script to identify blocking.
	SQLServer: Access Method - Workfiles Created/sec -- Норма на соотношение Workfiles Created/sec к Batch Requests/sec  соствляет не более 20%.
			-- Отличие Workfile от Worktable состоит в том, что Worktable содержит страницы файла связанные структурами метаданных (IAM) и зарегистрированными в системных таблицах, а Workfile это просто страницы файла данных не объединенные воедино метаданными (IAM). SQL Server активно использует Workfiles для выполнения операций хеширования и хранения промежуточных результатов хеширования (
			-- Большое количество создаваемых Workfiles может косвенно указывать на отсутствие индексов, которые может использовать SQL Server для выполнения операций соединения таблиц. В результате чего он вынужден  выполнять соединения таблиц через хеширование. 

-- Репликация
	SQL Server: Replication Snapshot — счетчики для мониторинга работы Snapshot Agent;
	SQL Server: Replication Dist. — информация о работе Distribution Agent;
	SQL Server: Replication Logreader — счетчики Log Reader Agent;
	SQL Server: Replication Merge — статистика работы Merge Agent;
	SQL Server: Replication Agents — для этого объекта предусмотрен единственный счетчик, который показывает, сколько агентов работает в настоящий момент.

-- Работа с диском
	-- Чтобы понять является ли жётский диск узким местом, достаточно проанализировать 2 счётчика и если их значение для ldf более 8 мс и для mdf более 20 (40 Warning) в среднем, то надо проводить более детальный анализ. Это счётчики
		- Avg. Disk sec/Read - среднее время чтения с диска
		- Avg. Disk sec/Write - среднее время записи на диск
	-- Если есть проблемы, то надо изучать следующие счётчики
		- Avg. Disk sec/Transfer - Среднее время обращения к диску на чтение и запись, задержка  (0.25-0.1)
		- Disk Transfers/sec – демонстрирует нагрузку операций чтения и записи на диск в секунду
		- Disk Reads/sec - нагрузка операций чтения с диска, нельзя ориентироваться на это без Avg. Disk Queue Length и Current Disk Queue Length
		- Disk Writes/sec - нагрузка операций записи на диск.
		- Avg. Disk Queue Length (средняя длина очереди) - показывает среднее значение числа запросов чтения и записи, которые стояли в очереди к выбранному диску во время интервала измерений.
		- Current Disk Queue Length (текущая длина очереди) - показывает число запросов, адресованных выбранному диску в то время, когда непосредственно выполнялись измерения.	По рекомендации Microsoft этот параметр может быть до 2-х для каждого шпинделя. Если RAID 10 из 20 дисков, то этот параметр будет 20/2 (делим на 2, потому что это R1+R0) = 10*2(умножаем на 2, потому что по 2 значения на каждый шпиндель)*[количество шпинделей в диске].
		- соотношение SQLServer:Access Method: Index Searches/sec и SQLServer:Access Method: Full Scans/sec должно быть около или более 1000.
		
-- Работа с сетью/Network
	1. Network Interface:Output queue length
	2. Network Interface:Bytes Total/sec (смотреть пропускную способность канала)
	3. Redirector:Network errors/sec
	4. TCPv4: Segments retransmitted/sec

-- Диски
	1. Среднее время записи на диск (LogicalDisk:Avg.Disk sec\Write) - 5-10 хорошо, 10-25 средне, выше - проблемы
	2. Среднее время чтения с диска  (LogicalDisk:Avg.Disk sec\Read) - 5-10 хорошо, 10-25 средне, выше - проблемы
	3. Обращений записи на диск/c (LogicalDisk:Disk Writes\sec)
	4. Обращений чтения с диска/c	(LogicalDisk:Disk Reads\sec) 
	5. Средняя длина очереди диска на запись (LogicalDisk:Avg. Disk Write Queue Length)
	6. Средняя длина очереди диска на чтение (LogicalDisk:Avg. Disk Read Queue Length)
	7. % активности диска	 
	8. Physical Disk:Disk Bytes/sec (смотреть пропускную способность диска)
	9. Счетчики монитора производительности Avg Disk Bytes/Transfer, Avg Disk Bytes/Read и Avg Disk Bytes/Write сообщают, сколько байтов задействуется при каждой операции ввода/вывода. Буфера диска гарантируют, что база данных SQL Server никогда не будет иметь менее чем 8196 байт за оборот диска, но что нам нужно, так это последовательные 65,536 (или более) байт за оборот (65,536 байт, или 64 Кбайт). Если вы видите, что данная величина меньше, чем 65,536, значит, возникли проблемы с фрагментацией данных.
	10. Если монитор производительности показывает чрезмерное количество операций ввода/вывода, о чем это говорит? И если FileMon показывает по крайней мере 65,536 байт при выполнении ввода/вывода? Это означает, что файл самой базы данных фрагментирован.

-- Кэши
	SQL Server:Plan Cache
		- Bound Trees (Результаты алгебраизации View, можно сказать, что это алгоритмы выборки данных из View)
		- Extended Storage procedures (Планы выполнения расширенных хранимых процедур)
		- Object Plans (Планы выполнения хранимых процедур, триггеров и некоторых видов функций)
		- SQL Plans (Планы выполнения динамического TSQL кода, сюда же попадают автопараметризованные запросы)
		- Temporary Tables & Tables Variables (Кэшированные метаданные по временным таблицам и табличным переменным).

-- Работа с CPU/Процессор
	Processor\% Privileged Time -- если больше 25-30%, то плохо. Соответствует проценту процессорного времени, затраченного на выполнение команд ядра операционной системы Microsoft Windows, таких как обработка запросов ввода-вывода SQL Server. Если значение этого счетчика постоянно высокое, в то время как счетчики для объекта Физический диск также имеют высокие значения, то необходимо рассмотреть вопрос об установке более быстрой и более эффективной дисковой подсистемы. На обработку запросов от различных контроллеров дисков и самих дисковых накопителей ядром операционной системы тратится различное количество времени. Эффективные контроллеры и дисковые накопители используют меньше привилегированного времени, оставляя больше времени для обработки запросов пользовательских приложений, увеличивая общую пропускную способность.
		Общение винды и дров например, так же контекстные переключения между нодами. Если значение высокое, то возможно система работает на себя, а не на нас
	Processor\% User Time -- работа на службы пользователей.
	Processor\% Proccessor Time -- Утилизация процессора
	Process (sqlserver)\% Privileged Time -- Сможем опеределить эту нагрузку создаёт SQL или нет
	Process (sqlserver)\% Proccessor Time
	System - Proccessor Queue LENGTH -- Лучше чтобы было 0
	System\Context Switches/sec -- The average Context Switches/sec value should be below 2,000 per processor. Some DBAs consider this limit to be 5,000 per processor. Higher values can be caused by excessive page faults caused by insufficient memory. Also, if hyper-threading is turned on, turn it off and test the performance. It can significantly reduce the threading and solve performance problems
	
	-- Total waits are wait_time_ms (high signal waits indicate CPU pressure)
		SELECT CAST(100.0 * SUM(signal_wait_time_ms) / SUM(wait_time_ms) AS NUMERIC(20,2)) AS [%signal (cpu) waits] , CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM(wait_time_ms) AS NUMERIC(20, 2)) AS [%resource waits]FROM sys.dm_os_wait_stats ;
		
	-- Поиск БД, которые потребляют много CPU
		WITH DB_CPU_Stats
		AS
		(SELECT DatabaseID, DB_Name(DatabaseID) AS [DatabaseName], SUM(total_worker_time) AS [CPU_Time_Ms]
		 FROM sys.dm_exec_query_stats AS qs
		 CROSS APPLY (SELECT CONVERT(int, value) AS [DatabaseID] 
					  FROM sys.dm_exec_plan_attributes(qs.plan_handle)
					  WHERE attribute = N'dbid') AS F_DB
		 GROUP BY DatabaseID)
		SELECT ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [row_num],
			   DatabaseName, [CPU_Time_Ms], 
			   CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPUPercent]
		FROM DB_CPU_Stats
		WHERE DatabaseID > 4 -- system databases
		AND DatabaseID <> 32767 -- ResourceDB
		ORDER BY row_num OPTION (RECOMPILE);
		
	-- Запросы, которые потребляют много CPU (те, что сейчас в кэше)
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
		WITH XMLNAMESPACES 
		(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
		SELECT TOP 10
		CompileTime_ms,
		CompileCPU_ms,
		CompileMemory_KB,
		qs.execution_count,
		qs.total_elapsed_time/1000 AS duration_ms,
		qs.total_worker_time/1000 as cputime_ms,
		(qs.total_elapsed_time/qs.execution_count)/1000 AS avg_duration_ms,
		(qs.total_worker_time/qs.execution_count)/1000 AS avg_cputime_ms,
		qs.max_elapsed_time/1000 AS max_duration_ms,
		qs.max_worker_time/1000 AS max_cputime_ms,
		SUBSTRING(st.text, (qs.statement_start_offset / 2) + 1,
		(CASE qs.statement_end_offset
		WHEN -1 THEN DATALENGTH(st.text)
		ELSE qs.statement_end_offset
		END - qs.statement_start_offset) / 2 + 1) AS StmtText,
		query_hash,
		query_plan_hash
		FROM
		(
		SELECT 
		c.value('xs:hexBinary(substring((@QueryHash)[1],3))', 'varbinary(max)') AS QueryHash,
		c.value('xs:hexBinary(substring((@QueryPlanHash)[1],3))', 'varbinary(max)') AS QueryPlanHash,
		c.value('(QueryPlan/@CompileTime)[1]', 'int') AS CompileTime_ms,
		c.value('(QueryPlan/@CompileCPU)[1]', 'int') AS CompileCPU_ms,
		c.value('(QueryPlan/@CompileMemory)[1]', 'int') AS CompileMemory_KB,
		qp.query_plan
		FROM sys.dm_exec_cached_plans AS cp
		CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
		CROSS APPLY qp.query_plan.nodes('ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS n(c)
		) AS tab
		JOIN sys.dm_exec_query_stats AS qs
		ON tab.QueryHash = qs.query_hash
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
		ORDER BY CompileTime_ms DESC
		OPTION(RECOMPILE, MAXDOP 1);
		
	-- История использования процессора
		DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks) FROM sys.dm_os_sys_info WITH (NOLOCK)); 
 
		SELECT TOP(256) SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
					   SystemIdle AS [System Idle Process], 
					   100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
						DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] 
		 FROM (SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
					 record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
					 AS [SystemIdle], 
					 record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') 
					AS [SQLProcessUtilization], [timestamp] 
		  FROM (SELECT [timestamp], CONVERT(xml, record) AS [record] 
					FROM sys.dm_os_ring_buffers WITH (NOLOCK)
					WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
					AND record LIKE N'%<SystemHealth>%') AS x) AS y 
		 ORDER BY record_id DESC OPTION (RECOMPILE);
		
	-- Количество компиляций и перекомпиляций	
		SELECT counter_name, cntr_value
		  FROM sys.dm_os_performance_counters
		  WHERE counter_name IN 
		  (
			'SQL Compilations/sec',
			'SQL Re-Compilations/sec'
		  );
		  
	-- Тяжелые запросы, выполняемые в данный момент
		SELECT resource_semaphore_id, -- 0 = regular, 1 = "small query"
		  pool_id,
		  available_memory_kb,
		  total_memory_kb,
		  target_memory_kb
		FROM sys.dm_exec_query_resource_semaphores;

		SELECT StmtText = SUBSTRING(st.[text], (qs.statement_start_offset / 2) + 1,
				(CASE qs.statement_end_offset
				  WHEN -1 THEN DATALENGTH(st.text) ELSE qs.statement_end_offset
				 END - qs.statement_start_offset) / 2 + 1),
		  r.start_time, r.[status], DB_NAME(r.database_id), r.wait_type, 
		  r.last_wait_type, r.total_elapsed_time, r.granted_query_memory,
		  m.requested_memory_kb, m.granted_memory_kb, m.required_memory_kb,
		  m.used_memory_kb
		FROM sys.dm_exec_requests AS r
		INNER JOIN sys.dm_exec_query_stats AS qs
		ON r.plan_handle = qs.plan_handle
		INNER JOIN sys.dm_exec_query_memory_grants AS m
		ON r.request_id = m.request_id
		AND r.plan_handle = m.plan_handle
		CROSS APPLY sys.dm_exec_sql_text(r.plan_handle) AS st;

	-- Тяжелые запросы, выполняемые в данный момент (кэш)
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

		;WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
		SELECT TOP (10) CompileTime_ms, CompileCPU_ms, CompileMemory_KB,
		  qs.execution_count,
		  qs.total_elapsed_time/1000.0 AS duration_ms,
		  qs.total_worker_time/1000.0 as cputime_ms,
		  (qs.total_elapsed_time/qs.execution_count)/1000.0 AS avg_duration_ms,
		  (qs.total_worker_time/qs.execution_count)/1000.0 AS avg_cputime_ms,
		  qs.max_elapsed_time/1000.0 AS max_duration_ms,
		  qs.max_worker_time/1000.0 AS max_cputime_ms,
		  SUBSTRING(st.text, (qs.statement_start_offset / 2) + 1,
			(CASE qs.statement_end_offset
			  WHEN -1 THEN DATALENGTH(st.text) ELSE qs.statement_end_offset
			 END - qs.statement_start_offset) / 2 + 1) AS StmtText,
		  query_hash, query_plan_hash
		FROM
		(
		  SELECT 
			c.value('xs:hexBinary(substring((@QueryHash)[1],3))', 'varbinary(max)') AS QueryHash,
			c.value('xs:hexBinary(substring((@QueryPlanHash)[1],3))', 'varbinary(max)') AS QueryPlanHash,
			c.value('(QueryPlan/@CompileTime)[1]', 'int') AS CompileTime_ms,
			c.value('(QueryPlan/@CompileCPU)[1]', 'int') AS CompileCPU_ms,
			c.value('(QueryPlan/@CompileMemory)[1]', 'int') AS CompileMemory_KB,
			qp.query_plan
		FROM sys.dm_exec_cached_plans AS cp
		CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
		CROSS APPLY qp.query_plan.nodes('ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS n(c)
		) AS tab
		JOIN sys.dm_exec_query_stats AS qs ON tab.QueryHash = qs.query_hash
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
		ORDER BY CompileMemory_KB DESC
		OPTION (RECOMPILE, MAXDOP 1);
	
-- Работа с памятью 
	select * from sys.dm_os_memory_brokers
	select * from sys.dm_os_process_memory
	select * from sys.dm_os_wait_stats order by wait_time_ms desc
	DBCC MEMORYSTATUS
	
	Memory: Page/sec -- Shows the rate at which pages are read from or written to disk to resolve hard page faults. This counter is a primary indicator of the kinds of faults that cause system-wide delays.
	Memory: Page Faults/sec -- A page fault occurs when a program requests an address on a page that is not in the current set of memory resident pages. When a page fault is encountered, the program execution stops and is set to the Wait state. The operating system searches for the requested address on the disk. When the page is found, the operating system copies it from the disk into a free RAM page. The operating system allows the program to continue with the execution afterwards. There are two types of page faults – hard and soft page faults. Hard page faults occur when the requested page is not in the physical memory. Soft page faults occur when the requested page is in the memory, but cannot be accessed by the program as it is not on the right address, or is being accessed by another program
		- Хорошо когда меньше 750
	
	Memory Manager: Stolen Server Memory (Kb) -- shows the amount of memory used by SQL Server, but not for database pages. Stolen memory describes buffers that are in use for sorting or for hashing operations (query workspace memory), or for those buffers that are being used as a generic memory store for allocations to store internal data structures such as locks, transaction context, and connection information. The lazywriter process is not permitted to flush Stolen buffers out of the buffer pool.
	
	Memory Manager: Granted Workspace Memory (KB) -- Total amount of memory currently granted to executing processes such as hash, sort, bulk copy, and index creation operations.
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
		
	
	
	Buffer Manager: Page reads/sec -- This statistic displays the total number of physical page reads across all databases
	Buffer Manager: Page writes/sec
	Buffer Manager: Page loockups/sec
	Memory Manager: Memory Grants Pending (количество процессов ожидающих памяти)
	Buffer Manager: Checkpoint Pages/sec -- shows the number of pages that are moved from buffer to disk per second during a checkpoint process. If more pages are flushed at each checkpoint, it might indicate an I/O problem.
	
-- SQL Server: Access Methods
	SQL Server: Access Methods - Forwarded Records/sec -- Number of records per second fetched through forwarded record pointers. Работа с heap
	SQL Server: Access Methods - Full Scans/sec -- Table Scan and Index Scan
	SQL Server: Access Methods - Index Searches/sec

-- Использование памяти (Sakthivel Chidambaram)
	-- We don't need the row count
	SET NOCOUNT ON

	-- Get size of SQL Server Page in bytes
	DECLARE @pg_size INT, @Instancename varchar(50) 
	SELECT @pg_size = low from master..spt_values where number = 1 and type = 'E' 

	-- Extract perfmon counters to a temporary table
	IF OBJECT_ID('tempdb..#perfmon_counters') is not null DROP TABLE #perfmon_counters
	SELECT * INTO #perfmon_counters FROM sys.dm_os_performance_counters

	-- Get SQL Server instance name
	SELECT @Instancename = LEFT([object_name], (CHARINDEX(':',[object_name]))) FROM #perfmon_counters WHERE counter_name = 'Buffer cache hit ratio' 

	-- Print Memory usage details
		PRINT '----------------------------------------------------------------------------------------------------' 
		PRINT 'Memory usage details for SQL Server instance ' + @@SERVERNAME + ' (' + CAST(SERVERPROPERTY('productversion') AS VARCHAR) + ' - ' + SUBSTRING(@@VERSION, CHARINDEX('X',@@VERSION),4) + ' - ' + CAST(SERVERPROPERTY('edition') AS VARCHAR) + ')' 
		PRINT '----------------------------------------------------------------------------------------------------' 
		SELECT 'Memory visible to the Operating System' 
		SELECT CEILING(physical_memory_in_bytes/1048576.0) as [Physical Memory_MB], CEILING(physical_memory_in_bytes/1073741824.0) as [Physical Memory_GB], CEILING(virtual_memory_in_bytes/1073741824.0) as [Virtual Memory GB] FROM sys.dm_os_sys_info 
		SELECT 'Buffer Pool Usage at the Moment' 
		SELECT (bpool_committed*8)/1024.0 as BPool_Committed_MB, (bpool_commit_target*8)/1024.0 as BPool_Commit_Tgt_MB,(bpool_visible*8)/1024.0 as BPool_Visible_MB FROM sys.dm_os_sys_info 
		SELECT 'Total Memory used by SQL Server Buffer Pool as reported by Perfmon counters' 
		SELECT cntr_value as Mem_KB, cntr_value/1024.0 as Mem_MB, (cntr_value/1048576.0) as Mem_GB FROM #perfmon_counters WHERE counter_name = 'Total Server Memory (KB)' 
		SELECT 'Memory needed as per current Workload for SQL Server instance' 
		SELECT cntr_value as Mem_KB, cntr_value/1024.0 as Mem_MB, (cntr_value/1048576.0) as Mem_GB FROM #perfmon_counters WHERE counter_name = 'Target Server Memory (KB)' 
		SELECT 'Total amount of dynamic memory the server is using for maintaining connections' 
		SELECT cntr_value as Mem_KB, cntr_value/1024.0 as Mem_MB, (cntr_value/1048576.0) as Mem_GB FROM #perfmon_counters WHERE counter_name = 'Connection Memory (KB)' 
		SELECT 'Total amount of dynamic memory the server is using for locks' 
		SELECT cntr_value as Mem_KB, cntr_value/1024.0 as Mem_MB, (cntr_value/1048576.0) as Mem_GB FROM #perfmon_counters WHERE counter_name = 'Lock Memory (KB)' 
		SELECT 'Total amount of dynamic memory the server is using for the dynamic SQL cache' 
		SELECT cntr_value as Mem_KB, cntr_value/1024.0 as Mem_MB, (cntr_value/1048576.0) as Mem_GB FROM #perfmon_counters WHERE counter_name = 'SQL Cache Memory (KB)' 
		SELECT 'Total amount of dynamic memory the server is using for query optimization' 
		SELECT cntr_value as Mem_KB, cntr_value/1024.0 as Mem_MB, (cntr_value/1048576.0) as Mem_GB FROM #perfmon_counters WHERE counter_name = 'Optimizer Memory (KB) ' 
		SELECT 'Total amount of dynamic memory used for hash, sort and create index operations.' 
		SELECT cntr_value as Mem_KB, cntr_value/1024.0 as Mem_MB, (cntr_value/1048576.0) as Mem_GB FROM #perfmon_counters WHERE counter_name = 'Granted Workspace Memory (KB) ' 
		SELECT 'Total Amount of memory consumed by cursors' 
		SELECT cntr_value as Mem_KB, cntr_value/1024.0 as Mem_MB, (cntr_value/1048576.0) as Mem_GB FROM #perfmon_counters WHERE counter_name = 'Cursor memory usage' and instance_name = '_Total' 
		SELECT 'Number of pages in the buffer pool (includes database, free, and stolen).' 
		SELECT cntr_value as [8KB_Pages], (cntr_value*@pg_size)/1024.0 as Pages_in_KB, (cntr_value*@pg_size)/1048576.0 as Pages_in_MB FROM #perfmon_counters WHERE object_name= @Instancename+'Buffer Manager' and counter_name = 'Total pages' 
		SELECT 'Number of Data pages in the buffer pool' 
		SELECT cntr_value as [8KB_Pages], (cntr_value*@pg_size)/1024.0 as Pages_in_KB, (cntr_value*@pg_size)/1048576.0 as Pages_in_MB FROM #perfmon_counters WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Database pages' 
		SELECT 'Number of Free pages in the buffer pool' 
		SELECT cntr_value as [8KB_Pages], (cntr_value*@pg_size)/1024.0 as Pages_in_KB, (cntr_value*@pg_size)/1048576.0 as Pages_in_MB FROM #perfmon_counters WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Free pages' 
		SELECT 'Number of Reserved pages in the buffer pool' 
		SELECT cntr_value as [8KB_Pages], (cntr_value*@pg_size)/1024.0 as Pages_in_KB, (cntr_value*@pg_size)/1048576.0 as Pages_in_MB FROM #perfmon_counters WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Reserved pages' 
		SELECT 'Number of Stolen pages in the buffer pool' 
		SELECT cntr_value as [8KB_Pages], (cntr_value*@pg_size)/1024.0 as Pages_in_KB, (cntr_value*@pg_size)/1048576.0 as Pages_in_MB FROM #perfmon_counters WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Stolen pages' 
		SELECT 'Number of Plan Cache pages in the buffer pool' 
		SELECT cntr_value as [8KB_Pages], (cntr_value*@pg_size)/1024.0 as Pages_in_KB, (cntr_value*@pg_size)/1048576.0 as Pages_in_MB FROM #perfmon_counters WHERE object_name=@Instancename+'Plan Cache' and counter_name = 'Cache Pages' and instance_name = '_Total'
		SELECT 'Page Life Expectancy - Number of seconds a page will stay in the buffer pool without references' 
		SELECT cntr_value as [Page Life in seconds],CASE WHEN (cntr_value > 300) THEN 'PLE is Healthy' ELSE 'PLE is not Healthy' END as 'PLE Status'  FROM #perfmon_counters WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Page life expectancy'
		SELECT 'Number of requests per second that had to wait for a free page' 
		SELECT cntr_value as [Free list stalls/sec] FROM #perfmon_counters WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Free list stalls/sec'
		SELECT 'Number of pages flushed to disk/sec by a checkpoint or other operation that require all dirty pages to be flushed' 
		SELECT cntr_value as [Checkpoint pages/sec] FROM #perfmon_counters WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Checkpoint pages/sec'
		SELECT 'Number of buffers written per second by the buffer manager"s lazy writer'
		SELECT cntr_value as [Lazy writes/sec] FROM #perfmon_counters WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Lazy writes/sec'
		SELECT 'Total number of processes waiting for a workspace memory grant'
		SELECT cntr_value as [Memory Grants Pending] FROM #perfmon_counters WHERE object_name=@Instancename+'Memory Manager' and counter_name = 'Memory Grants Pending'
		SELECT 'Total number of processes that have successfully acquired a workspace memory grant'
		SELECT cntr_value as [Memory Grants Outstanding] FROM #perfmon_counters WHERE object_name=@Instancename+'Memory Manager' and counter_name = 'Memory Grants Outstanding'

-- Рабочие потоки
	sp_configure 'max worker threads'
	
	-- Посмотреть текущую активности воркеров
	select scheduler_id,current_tasks_count,
	current_workers_count,active_workers_count,work_queue_count
	from sys.dm_os_schedulers
	where status = 'Visible Online'
	
	-- Активные воркеры
		SELECT  COUNT(*)
		FROM    sys.dm_os_workers AS dow
		WHERE   state = 'RUNNING';

-- Возвращает по строке на каждый счетчик производительности
	SELECT * FROM sys.dm_os_performance_counters

-- Наиболее нагруженные файлы баз
	SELECT DB_NAME(saf.dbid) AS [База данных],
		   saf.name AS [Логическое имя],
		   vfs.BytesRead/1048576 AS [Прочитано (Мб)],
		   vfs.BytesWritten/1048576 AS [Записано (Мб)],
		   saf.filename AS [Путь к файлу]
	  FROM master..sysaltfiles AS saf
	  JOIN ::fn_virtualfilestats(NULL,NULL) AS vfs ON vfs.dbid = saf.dbid AND
													  vfs.fileid = saf.fileid AND
													  saf.dbid NOT IN (1,3,4)
	  ORDER BY vfs.BytesRead/1048576 + BytesWritten/1048576 DESC
	 
	Process: Page Faults/sec или Процесс: Ошибки страниц/с -- Желательно чтобы значение было малым (до 20)
	Физический диск(диск)\Средняя длина очереди диска -- Загруженность диска. Если более 60 постоянно, то нужно улучшать систему

	Физический диск: Скорость записи на диск (байт/c) -- Если надо узнать объём передаваемой информации на диск
	Физический диск: Скорость чтения с диска (байт/c) -- Если надо узнать объём получаеме информации с диска

-- AlwaysOn
	SQL Server:Database Replica – Log Send Queue -- This is the counter which tells how much kilobytes of transaction log content is remaining on the primary to be transferred to the specific replica.
	
	-- Как много накопилось данных на Primary для репликации на одну из реплик
		SQL Server:Databases – Log Pool Requests/sec
		SQL Server:Databases – Log Pool Disk Reads/sec
		SQL Server:Databases – Log Pool Cache Misses/sec
		SQL Server:Memory Manager – Log Pool Memory (KB)
		
	-- Отставание реплики
		SQL Server:Database Replica –> Transaction Delay
		SQL Server:Database Replica –> Mirrored Write Transactions/sec
		
	-- На Secondary
		SQL Server:Database Replica – Recovery Queue
		SQL Server:Database Replica – ReDone Bytes/sec
		SQL Server:Database Replica – Redo blocked/sec
		
	-- Объём передавемых данных
		SQL Server:Availability Replica –> Bytes Sent to Replica/sec
		SQL Server:Availability Replica –> Sends to Replica/sec
		
	-- Обнаружение проблем с сетью для Always On
		SQL Server:Availability Replica –> Flow Control Time (ms/sec)
		SQL Server:Availability Replica –> Flow Control Time
		SQL Server:Availability Replica –> Resent messages/sec
		
	-- AlwaysOn DMV
	
		-- 1 (основная)
		SELECT ag.name AS ag_name, ar.replica_server_name AS ag_replica_server, dr_state.database_id as database_id,
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
		
		-- 2 (Только на Primary)
			select wait_type, waiting_tasks_count, wait_time_ms, wait_time_ms/waiting_tasks_count as 'time_per_wait'
			from sys.dm_os_wait_stats where waiting_tasks_count >0
			and wait_type = 'HADR_SYNC_COMMIT'

		

	
-- Процедуры начинающиеся на sp_oa*
- Приводят к утечке памяти и другим проблемам

-- Reports in SSMS
- Perfomance - Object Execution Statistics (показывает тяжёлые процедуры и запросы)

-- Ожидания/Рабочие потоки
- Рабочие потоки (sp_config)

SELECT * FROM sys.dm_os_wait_stats
SELECT * FROM sys.dm_os_performance_counters
SELECT * FROM sys.dm_os_sys_memory
SELECT * FROM sys.dm_os_process_memory 

-- waits/ожидание/Paul Randal
	WITH Waits AS
    (SELECT
        wait_type,
        wait_time_ms / 1000.0 AS WaitS,
        (wait_time_ms - signal_wait_time_ms) / 1000.0 AS ResourceS,
        signal_wait_time_ms / 1000.0 AS SignalS,
        waiting_tasks_count AS WaitCount,
        100.0 * wait_time_ms / SUM (wait_time_ms) OVER() AS Percentage,
        ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS RowNum
    FROM sys.dm_os_wait_stats
    WHERE wait_type NOT IN (
        'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK',
        'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 'LOGMGR_QUEUE',
        'CHECKPOINT_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT', 'BROKER_TO_FLUSH',
        'BROKER_TASK_STOP', 'CLR_MANUAL_EVENT', 'CLR_AUTO_EVENT', 'DISPATCHER_QUEUE_SEMAPHORE',
        'FT_IFTS_SCHEDULER_IDLE_WAIT', 'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN', 'BROKER_EVENTHANDLER',
        'TRACEWRITE', 'FT_IFTSHC_MUTEX', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP')
     )
	SELECT
		 W1.wait_type AS WaitType, 
		 CAST (W1.WaitS AS DECIMAL(14, 2)) AS Wait_S,
		 CAST (W1.ResourceS AS DECIMAL(14, 2)) AS Resource_S,
		 CAST (W1.SignalS AS DECIMAL(14, 2)) AS Signal_S,
		 W1.WaitCount AS WaitCount,
		 CAST (W1.Percentage AS DECIMAL(4, 2)) AS Percentage
	FROM Waits AS W1
	INNER JOIN Waits AS W2
		 ON W2.RowNum <= W1.RowNum
	GROUP BY W1.RowNum, W1.wait_type, W1.WaitS, W1.ResourceS, W1.SignalS, W1.WaitCount, W1.Percentage
	HAVING SUM (W2.Percentage) - W1.Percentage < 95; -- percentage threshold
	GO

-- Clear Wait Stats
DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR) ;

-- Isolate top waits for server instance since last restart
-- or statistics clear
WITH Waits AS ( SELECT wait_type , wait_time_ms / 1000. AS wait_time_s , 100. * wait_time_ms / SUM(wait_time_ms) OVER ( ) AS pct ,
ROW_NUMBER() OVER ( ORDER BY wait_time_ms DESC ) AS rn FROM sys.dm_os_wait_stats WHERE wait_type NOT IN ( 'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 'LOGMGR_QUEUE', 'CHECKPOINT_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT', 'BROKER_TO_FLUSH', 'BROKER_TASK_STOP', 'CLR_MANUAL_EVENT', 'CLR_AUTO_EVENT', 'DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT', 'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN' ) ) SELECT W1.wait_type , CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s , CAST(W1.pct AS DECIMAL(12, 2)) AS pct , CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct FROM Waits AS W1 INNER JOIN Waits AS W2 ON W2.rn <= W1.rn GROUP BY W1.rn , W1.wait_type , W1.wait_time_s , W1.pct HAVING SUM(W2.pct) - W1.pct < 95 ; -- percentage threshold


-- Recovery model, log reuse wait description, log file size,
-- log usage size and compatibility level for all databases on instance
SELECT db.[name] AS [Database Name] , db.recovery_model_desc AS [Recovery Model] , db.log_reuse_wait_desc AS [Log Reuse Wait Description] , ls.cntr_value AS [Log Size (KB)] , lu.cntr_value AS [Log Used (KB)] , CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT) AS DECIMAL(18,2)) * 100 AS [Log Used %] , db.[compatibility_level] AS [DB Compatibility Level] , db.page_verify_option_desc AS [Page Verify Option]FROM sys.databases AS db INNER JOIN sys.dm_os_performance_counters AS lu ON db.name = lu.instance_name INNER JOIN sys.dm_os_performance_counters AS ls ON db.name = ls.instance_name WHERE lu.counter_name LIKE '%Log File(s) Used Size (KB)%' AND ls.counter_name LIKE 'Log File(s) Size (KB)%' ;


-- 7 наиболее важных счётчика
1. Bytes Total/sec
Счетчик Bytes Total/sec, который находится среди объектов Network Interface, может помочь Вам определить,
является ли сетевой адаптер узким местом. Сравните значение этого счётчика с максимальной пропускной
способностью вашей сетевой платы. Вообще, этот счётчик должен показать не более 50% утилизации пропускной
способности сетевого адаптера.
2. Total Server Memory
Этот счетчик, расположенный среди объектов SQL Server: Memory Manager, показывает общую сумму динамически
выделяемой памяти в килобайтах. Необходимо увеличить размер памяти, если среднее значение этого счётчика
постоянно выше, чем доступное количество физической памяти в системе. (Замечание автора перевода: эта
рекомендация не относится к тем случаям, когда для SQL Server установлен максимальный, фиксированный размер
занимаемой им оперативной памяти).
3. Average Disk Queue Length
Этот счетчик показывает эффективность дисковой подсистемы и расположен среди объектов PhysicalDisk.
Средняя длина очереди диска - это среднее общее количество запросов на чтение и на запись, которые были
поставлены в очередь для соответствующего диска в течение интервала измерения. Согласно рекомендациям
Microsoft, среднее число запросов ожидающих I/O не должно быть больше, чем в 1,5 - 2 раза числа шпинделей
физических дисков. (Замечание автора перевода: по-видимому, автор статьи имеет ввиду значение с учётом
масштаба по умолчанию для этого счётчика, т.к. на графике представляются умноженные на 100 значения).
Если значения этого счётчика постоянно выше рекомендованных, Вы можете поднять производительность дисковой
подсистемы установим более быстрые диски или увеличив их количество.
4. Cache Hit Ratio
Этот счетчик среди объектов SQL Server: Cache Manager показывает, может ли SQL Server размещать полностью
планы исполнения запросов в кэше процедур. В идеале, это значение должно всегда быть выше 85 процентов.
Если Вы наблюдаете снижение среднего значения этого счётчика, рассмотрите возможность добавление ОЗУ или
оптимизации ваших запросов.
5. Buffer Cache Hit Ratio
Счетчик Buffer Cache Hit Ratio среди объектов SQL Server: Buffer Manager показывает, насколько полно
SQL Server может разместить данные в буфере кэша. Чем выше это значение, тем лучше, т.к. для эффективного
обращения SQL сервера к страницам данных, они должны находиться в буфере кэша, и операции физического
ввода-вывода (I/O) должны отсутствовать. Если Вы наблюдаете устойчивое снижение среднего значения этого
счётчика, рассмотрите возможность добавление ОЗУ.
6. Pages/Sec
Счетчик Pages/Sec, расположенный среди объектов Memory, показывает число страниц, которые SQL Server считал
с диска или записал на диск для того, чтобы разрешить обращения к страницам памяти, которые не были
загружены в оперативную память в момент обращения. Эта величина является суммой величин Pages Input/sec
и Pages Output/sec, а также учитывает страничный обмен (подкачку/свопинг) системной кэш-памяти для доступа
к файлам данных приложений. Кроме того, сюда включается подкачка не кэшированных файлов, непосредственно
отображаемых в память. Это основной счетчик, за которым следует следить в том случае, если наблюдается
большая нагрузка на использование памяти и связанный с этим избыточный страничный обмен. Этот счётчик
характеризует величину свопинга и его нормальное (не пиковое) значение должно быть близко к нолю.
Увеличение свопинга говорит о необходимости наращивания ОЗУ или уменьшения числа исполняемых на сервере
прикладных программ. (до 20)
7. % Processor Time
Один из наиболее жизненно-важных счетчиков, который необходимо контролировать, это счетчик % Processor Time
среди объектов Processor. Этот счетчик показывает процентное отношение времени, которое процессор был занят
выполнением операций для не простаивающих потоков (non-Idle thread). Эту величину можно рассматривать как
долю времени, приходящегося на выполнение полезной работы. Каждый процессор может быть назначен
простаивающему потоку, который потребляет непродуктивные циклы процессора, не используемые другими потоками.
Для этого счётчика характерны непродолжительные пики, которые могут достигать 100 процентов. Однако, если
Вы видите продолжительные периоды, когда утилизация процессора выше 80 процентов, ваша система будет более
эффективной при использовании большего числа процессоров.

-- Помощь
-- что сейчас происходит на сервере
select session_id, status, wait_type, command, last_wait_type, percent_complete, qt.text, total_elapsed_time/1000 as [total_elapsed_time, сек],
       wait_time/1000 as [wait_time, сек], (total_elapsed_time - wait_time)/1000 as [work_time, сек]
  from sys.dm_exec_requests as qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  where session_id >= 50 and session_id <> @@spid
  order by 1

-- что сейчас происходит на сервере (подробнее)
select *
  from sys.sysprocesses where spid > 50 and spid <> @@spid and status <> 'sleeping'
  order by spid, ecid

-- фрагментированные индексы
SELECT TOP 100
       DatbaseName = DB_NAME(),
       TableName = OBJECT_NAME(s.[object_id]),
       IndexName = i.name,
       i.type_desc,
       [Fragmentation %] = ROUND(avg_fragmentation_in_percent,2),
       page_count,
       partition_number,
       'alter index [' + i.name + '] on [' + sh.name + '].['+ OBJECT_NAME(s.[object_id]) + '] REBUILD' + case
                                                                                                           when p.data_space_id is not null then ' PARTITION = '+convert(varchar(100),partition_number)
                                                                                                           else ''
                                                                                                         end + ' with(maxdop = 1,  SORT_IN_TEMPDB = on)' [sql]
  FROM sys.dm_db_index_physical_stats(db_id(),null, null, null, null) s
  INNER JOIN sys.indexes as i ON s.[object_id] = i.[object_id] AND
                                 s.index_id = i.index_id
  left join sys.partition_schemes as p on i.data_space_id = p.data_space_id
  left join sys.objects o on  s.[object_id] = o.[object_id]
  left join sys.schemas as sh on sh.[schema_id] = o.[schema_id]
  WHERE s.database_id = DB_ID() AND
        i.name IS NOT NULL AND
        OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0 and
        page_count > 100 and
        avg_fragmentation_in_percent > 10
  ORDER BY 4,page_count

-- задержки
SELECT TOP 10
 [Wait type] = wait_type,
 [Wait time (s)] = wait_time_ms / 1000,
 [% waiting] = CONVERT(DECIMAL(12,2), wait_time_ms * 100.0 
               / SUM(wait_time_ms) OVER())
  FROM sys.dm_os_wait_stats
  WHERE wait_type NOT LIKE '%SLEEP%' 
  ORDER BY wait_time_ms DESC;

-- итоговое число отсутствующих индексов для каждой базы данных
SELECT [DatabaseName] = DB_NAME(database_id),
       [Number Indexes Missing] = count(*) 
  FROM sys.dm_db_missing_index_details
  GROUP BY DB_NAME(database_id)
  ORDER BY 2 DESC

-- Отсутствующие индексы, вызывающие издержки
SELECT TOP 10 
       [Total Cost] = ROUND(avg_total_user_cost * avg_user_impact * (user_seeks + user_scans),0),
       avg_user_impact,
       TableName = statement,
       [EqualityUsage] = equality_columns,
       [InequalityUsage] = inequality_columns,
       [Include Cloumns] = included_columns
  FROM sys.dm_db_missing_index_groups g 
  INNER JOIN sys.dm_db_missing_index_group_stats s ON s.group_handle = g.index_group_handle 
  INNER JOIN sys.dm_db_missing_index_details d ON d.index_handle = g.index_handle
  WHERE database_id = DB_ID()
  ORDER BY [Total Cost] DESC;

-- Неиспользуемые индексы
SELECT DatabaseName = DB_NAME(),
       TableName = OBJECT_NAME(s.[object_id]),
       IndexName = i.name,
       user_updates,
       system_updates,
       'EXEC sp_rename ''[dbo].['+OBJECT_NAME(s.[object_id])+'].['+i.name+']'',''disable_'+i.name+''',''INDEX''' as Rename,
       'ALTER INDEX '+i.name+' ON '+OBJECT_NAME(s.[object_id])+' DISABLE' as [Disable]
  FROM sys.dm_db_index_usage_stats s 
  INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id] AND
                              s.index_id = i.index_id
  WHERE s.database_id = DB_ID() AND
        OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0 AND
        user_seeks = 0     AND
        user_scans = 0     AND
        user_lookups = 0   AND
        i.is_disabled <> 1 AND
        i.is_primary_key <> 1
  order by user_updates + system_updates desc

-- Запросы с высокими издержками на ввод-вывод
SELECT TOP 10
       [Average IO] = (total_logical_reads + total_logical_writes) / qs.execution_count,
       [Total IO] = (total_logical_reads + total_logical_writes),
       [Execution count] = qs.execution_count,
       [Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, (CASE
                                                                               WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
                                                                               ELSE qs.statement_end_offset
                                                                             END - qs.statement_start_offset)/2),
       [Parent Query] = qt.text,
       [DatabaseName] = DB_NAME(qt.dbid)
  FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  ORDER BY [Average IO] DESC

-- Запросы с высоким использованием ресурсов ЦП
SELECT TOP 10
       [Average CPU used] = total_worker_time / qs.execution_count,
       [Total CPU used] = total_worker_time,
       [Execution count] = qs.execution_count,
       [Individual Query] = SUBSTRING(qt.text,qs.statement_start_offset/2, 
         (CASE
            WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
            ELSE qs.statement_end_offset
          END - qs.statement_start_offset)/2),
       [Parent Query] = qt.text,
       [DatabaseName] = DB_NAME(qt.dbid)
  FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  ORDER BY [Average CPU used] DESC;

-- Запросы, страдающие от блокировки
SELECT TOP 10
       [Average Time Blocked] = (total_elapsed_time - total_worker_time) / qs.execution_count,
       [Total Time Blocked] = total_elapsed_time - total_worker_time,
       [Execution count] = qs.execution_count,
       [Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE
            WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
            ELSE qs.statement_end_offset
          END - qs.statement_start_offset)/2),
       [Parent Query] = qt.text,
       [DatabaseName] = DB_NAME(qt.dbid)
  FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  ORDER BY [Average Time Blocked] DESC;

-- нагрузку на подсистему ввода-вывода
select top 5 
    (total_logical_reads/execution_count) as avg_logical_reads,
    (total_logical_writes/execution_count) as avg_logical_writes,
    (total_physical_reads/execution_count) as avg_phys_reads,
     Execution_count, 
    statement_start_offset as stmt_start_offset, 
    plan_handle,
    qt.text
from sys.dm_exec_query_stats  qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
order by  (total_logical_reads + total_logical_writes) Desc

-- какой процессор что делает
SELECT DB_NAME(ISNULL(s.dbid,1)) AS [Имя базы данных],
       c.session_id AS [ID сессии],
       t.scheduler_id AS [Номер процессора],
       s.text AS [Текст SQL-запроса]
  FROM sys.dm_exec_connections AS c
  CROSS APPLY master.sys.dm_exec_sql_text(c.most_recent_sql_handle) AS s
  JOIN sys.dm_os_tasks t ON t.session_id = c.session_id AND
                            t.task_state = 'RUNNING' AND
                            ISNULL(s.dbid,1) > 4
  ORDER BY c.session_id DESC
  
-- контроль "несжатости"
SELECT tbl.name,
       i.name,
       p.partition_number AS [PartitionNumber],
       p.data_compression_desc AS [DataCompression],
       p.rows  AS [RowCount]
  FROM sys.tables AS tbl
  LEFT JOIN sys.indexes AS i ON (i.index_id > 0 and i.is_hypothetical = 0) AND (i.object_id=tbl.object_id)
  INNER JOIN sys.partitions AS p ON p.object_id = CAST(tbl.object_id AS int) AND
                                    p.index_id = CAST(i.index_id AS int)
  where p.data_compression_desc <> 'PAGE' and
        p.rows >= 1000000
  order by p.rows desc, 3

-- статистика по операциям в БД
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

-- дата обновления статистики
SELECT STATS_DATE(t1.object_id, stats_id), 'UPDATE STATISTICS [' + object_name(t1.object_id) + ']([' + t1.name + ']) WITH FULLSCAN',
       i1.rows
  FROM sys.stats as t1
  inner join sys.sysobjects as t2 on t1.object_id = t2.id
  left join sysindexes as i1 on i1.id = t1.object_id and
                                i1.indid = 1
  where xtype = 'U' and
        STATS_DATE(t1.object_id, stats_id) < GETDATE()-5 and
        -- не учитываем: мусор, постоянные данные, таблицы на удаление
        t1.name not like 'disable%' and
        object_name(t1.object_id) not like '[__]%' and
        object_name(t1.object_id) not like 'T[_]%' and
        object_name(t1.object_id) not like 'OSMP%' and
        -- исключаем автостатистику,
        -- она создана по ad-hoc запросам, поэтому не является необходимой
        -- во время ночных расчетов
         t1.name not like '[_]WA[_]Sys[_]%'
  order by STATS_DATE(t1.object_id, stats_id)

-- i/o-нагрузка на файлы
SELECT TOP 10 DB_NAME(saf.dbid) AS [База данных],
       saf.name AS [Логическое имя],
       vfs.BytesRead/1048576 AS [Прочитано (Мб)],
       vfs.BytesWritten/1048576 AS [Записано (Мб)],
       saf.filename AS [Путь к файлу]
  FROM master..sysaltfiles AS saf
  JOIN ::fn_virtualfilestats(NULL,NULL) AS vfs ON vfs.dbid = saf.dbid AND
                                                  vfs.fileid = saf.fileid AND
                                                  saf.dbid NOT IN (1,3,4)
  ORDER BY vfs.BytesRead/1048576 + BytesWritten/1048576 DESC

-- i/o-нагрузка на диски
SELECT SUBSTRING(saf.physical_name, 1, 1)    AS [Диск],
       SUM(vfs.num_of_bytes_read/1048576)    AS [Прочитано (Мб)],
       SUM(vfs.num_of_bytes_written/1048576) AS [Записано (Мб)]
  FROM sys.master_files AS saf
  JOIN sys.dm_io_virtual_file_stats(NULL,NULL) AS vfs ON vfs.database_id = saf.database_id AND
                                                         vfs.file_id = saf.file_id AND
                                                         saf.database_id NOT IN (1,3,4) AND
                                                         saf.type < 2
  GROUP BY SUBSTRING(saf.physical_name, 1, 1)
  ORDER BY [Диск]

-- Занимаемое на диске место
SELECT TOP 1000
       (row_number() over(order by (a1.reserved + ISNULL(a4.reserved,0)) desc))%2 as l1,
       a3.name AS [schemaname],
       a2.name AS [tablename],
       a1.rows as row_count,
      (a1.reserved + ISNULL(a4.reserved,0))* 8 AS reserved,
       a1.data * 8 AS data,
      (CASE WHEN (a1.used + ISNULL(a4.used,0)) > a1.data THEN (a1.used + ISNULL(a4.used,0)) - a1.data ELSE 0 END) * 8 AS index_size,
      (CASE WHEN (a1.reserved + ISNULL(a4.reserved,0)) > a1.used THEN (a1.reserved + ISNULL(a4.reserved,0)) - a1.used ELSE 0 END) * 8 AS unused,
      'ALTER TABLE [' + a2.name  + '] REBUILD' as [sql]
  FROM (SELECT ps.object_id,
               SUM(CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END) AS [rows],
               SUM(ps.reserved_page_count) AS reserved,
               SUM(CASE WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count) ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count) END) AS data,
               SUM(ps.used_page_count) AS used
          FROM sys.dm_db_partition_stats ps
          GROUP BY ps.object_id
       ) AS a1
  LEFT JOIN (SELECT it.parent_id,
                    SUM(ps.reserved_page_count) AS reserved,
                    SUM(ps.used_page_count) AS used
               FROM sys.dm_db_partition_stats ps
               INNER JOIN sys.internal_tables it ON (it.object_id = ps.object_id)
               WHERE it.internal_type IN (202,204)
               GROUP BY it.parent_id
            ) AS a4 ON (a4.parent_id = a1.object_id)
  INNER JOIN sys.all_objects a2  ON ( a1.object_id = a2.object_id )
  INNER JOIN sys.schemas a3 ON (a2.schema_id = a3.schema_id)
  WHERE a2.type <> N'S' and a2.type <> N'IT'
  ORDER BY 8 DESC
  
-- под какие объекты выделена память в текущей бд
select count(*)as cached_pages_count,
       obj.name as objectname,
       ind.name as indexname,
       obj.index_id as indexid
  from sys.dm_os_buffer_descriptors as bd
  inner join (select object_id as objectid,
                     object_name(object_id) as name,
                     index_id,allocation_unit_id
                from sys.allocation_units as au
                inner join sys.partitions as p on au.container_id = p.hobt_id and (au.type = 1 or au.type = 3)
                union all
                select object_id as objectid,
                       object_name(object_id) as name,
                       index_id,allocation_unit_id
                  from sys.allocation_units as au
                  inner join sys.partitions as p on au.container_id = p.partition_id and au.type = 2
             ) as obj on bd.allocation_unit_id = obj.allocation_unit_id
  left outer join sys.indexes ind on obj.objectid = ind.object_id and
                                     obj.index_id = ind.index_id
  where bd.database_id = db_id() and
        bd.page_type in ('data_page', 'index_page')
  group by obj.name, ind.name, obj.index_id
  order by cached_pages_count desc
  
-- Место, занимаемое разовыми запросами в кэше/размер памяти для планов
SELECT objtype AS [CacheType]
		, count_big(*) AS [Total Plans]
		, sum(cast(size_in_bytes as decimal(18,2)))/1024/1024 AS [Total MBs]
		, avg(usecounts) AS [Avg Use Count]
		, sum(cast((CASE WHEN usecounts = 1 THEN size_in_bytes ELSE 0 END) as decimal(18,2)))/1024/1024 AS [Total MBs - USE Count 1]
		, sum(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) AS [Total Plans - USE Count 1]
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY [Total MBs - USE Count 1] DESC
go
  
-- Александр Гладченко  
  
PhysicalDisk Object: Avg. Disk Queue Length. --Этот счетчик показывает среднее число запросов чтения и записи, которые были поставлены в очередь для указанного физического диска. Чем выше это число, тем большее дисковых операций ожидает ввода-вывода. Если это значение во время пиковой нагрузки на SQL Server частенько превышает двойку, следует задуматься о необходимости принятия адекватных мер. Если используется несколько дисков, показания счётчика нужно разделить на число дисков в массиве и убедиться, не превышает ли результирующее значение число 2. Например, у Вас есть 4 диска и длина очереди диска 10, искомая глубина очереди находится следующим образом: 10/4 = 2,5, это и будет значением, которое нужно анализировать, а не 10.

Avg. Disk Sec/Read и Avg. Disk Sec/Write --показывают среднее время чтения и записи данных на диск. Хорошо, если это значение не превышает 10 ms, но все еще приемлемо, если значение меньше 20 ms. Значения, превышающие этот порог, требуют исследования возможностей оптимизации.

Physical Disk: %Disk Time -- время, которое диск был занят обслуживанием запросов записи или чтения. Это значение должно быть ниже 50%.
Disk Reads/Sec и Disk Writes/Sec - показатель уровня загруженности диска операциями чтения - записи. Значение должно быть меньше 85% от пропускной способности диска, поскольку при превышении этого порога время доступа увеличивается по экспоненте.
Пропускную способность диска можно определить постепенно увеличивая нагрузку на систему. Одним из способов определения пропускной способности дисковой подсистемы является использование специализированной утилиты SQLIO. Она позволяет определить ту точку, где пропускная способность перестаёт расти при дальнейшем увеличении нагрузки.

-- При выборе конфигураций RAID можно использовать следующие формулы вычисления числа операций ввода-вывода (I/Os), приходящихся на один диск:

Raid 0: I/O на диск = (чтений + записей) / число дисков массива
Raid 1: I/O на диск = [чтений + (записей *2)] / 2
Raid 5: I/O на диск = [чтений + (записей *4)] / число дисков массива
Raid 10: I/O на диск = [чтений + (записей *2)] / число дисков массива

-- Вот пример вычисления количества операций ввода-вывода на диск для RAID 1 на основе значений счетчиков:
Disk Reads/sec = 90
Disk Writes/sec = 75
Формула для ввода-вывода на RAID-1 массив является [чтений + (записей*2)] / 2 или [90 + (75*2)] / 2 = 120 I/Os на диск.

-- Динамические административные представления
   Есть полезные динамические административные представления (DMV), с помощью которых можно выявить узкие места ввода-вывода.
   Специальный тип ожидания краткой блокировки для операции ввода-вывода (I/O latch) имеет место тогда, когда задача переходит в состояние ожидания завершения кратковременной блокировки буфера, находящегося в состоянии обслуживания запроса ввода-вывода. В зависимости от типа запроса, это приводит к появлению ожиданий с именами PAGEIOLATCH_EX или PAGEIOLATCH_SH. Длительные ожидания могут указывать на проблемы с дисковой подсистемой. Чтобы посмотреть статистику таких ожиданий можно использовать системное представление sys.dm_os_wait_stats. Для того, что бы определить наличие проблем ввода-вывода, нужно посмотреть значения waiting_task_counts и wait_time_ms при нормальной рабочей нагрузке SQL Server и сравнить их со значениями, полученными при ухудшении производительности.

select * from sys.dm_os_wait_stats
where wait_type like 'PAGEIOLATCH%'
ORDER BY wait_type asc

--  Ожидания запросов ввода-вывода можно посмотреть с помощью соответствующих DMV и эту информацию можно использовать для определения того, какой именно диск является узким местом.

select db_name(database_id),
      file_id,
      io_stall,
      io_pending_ms_ticks,
      scheduler_address
from sys.dm_io_virtual_file_stats (NULL, NULL) iovfs,
     sys.dm_io_pending_io_requests as iopior
where iovfs.file_handle = iopior.io_handle

--Дисковая фрагментация
   Я рекомендую регулярно проверять уровень фрагментации и конфигурацию дисков, используемых экземпляром SQL Server.
   Фрагментация файлов на разделе NTFS может стать причиной существенной потери производительности. Диски должны регулярно дефрагментироваться. Исследование показывают, что в некоторых случаях диски, подключаемые из сетей SAN, менее производительны, если их файлы дефрагментированы, т.е. эти СХД оптимизированы под случайный ввод-вывод. Прежде чем устранять файловую фрагментацию, стоит выяснить, как она сказывается на производительности работы SAN.
   Фрагментация индексов также может стать причиной повышения нагрузки ввода-вывода на NTFS, но на это влияют уже другие условия, отличные от тех, что существенны для SAN, оптимизированных для случайного доступа.
   
-- Конфигурация дисков / Best Practices
   Как правило, для повышения производительности, файлы журналов кладут на отдельные физические диски, а файлы данных размещают на других физических дисках. Ввод-вывод для высоко нагруженных файлов данных (включая tempDB) носит случайный характер. Ввод-вывод для файла журнала транзакций носит последовательный характер, кроме случаев отката транзакций.
   Встроенные в шасси сервера (локальные) диски можно использовать только для файлов журнала транзакций, потому что они хорошо ведут себя при последовательном вводе-выводе, а при случайном вводе-выводе ведут себя плохо.
   Файлы данных и журналов должны размещаться на разных дисковых массивах, у которых используются разные наборы физических дисков. В большинстве случаев, когда решение должно укладываться в не большой бюджет, я рекомендую размещать файл журнала транзакций на массиве RAID1, собранном из локальных дисков. Файлы данных БД лучше разместить на внешней системе хранения в сети SAN, так, чтобы к используемым для данных физическим дискам доступ получал только SQL Server, что позволит контролировать обслуживание его запросов и получать достоверные отчёты загрузки дисковой подсистемы. От подключения дисковых подсистем напрямую к серверу лучше отказаться.
   Кэширование записи должно быть включено везде, где только это возможно, и вы должны удостовериться, что кэш защищен от перебоев в питании и других возможных отказов (независимая батарея подпитки кэша на контроллере).
   Во избежание появления узких мест ввода-вывода для OLTP систем, лучше не смешивать нагрузки, характерные для OLTP и OLAP. Кроме того, удостоверьтесь, что серверный код оптимизирован и, где это необходимо, созданы индексы, которые тоже позволяют избавиться от ненужного ввода-вывода.

 -- Быстрый тест проблем с памятью/memory/экспресс тестирование памяти
-- По мотивам: http://bit.ly/LkT05M
WITH RingBufferXML
AS(SELECT CAST(Record AS XML) AS RBR FROM sys .dm_os_ring_buffers
   WHERE ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR'
  )
SELECT DISTINCT 'Зафиксированы проблемы' =
          CASE
                    WHEN XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]','tinyint')  = 0 AND
                         XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]','tinyint')   = 2 
                    THEN 'Недостаточно физической памяти для системы'
                    WHEN XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]','tinyint')  = 0 AND 
                         XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]','tinyint')   = 4 
                    THEN 'Недостаточно виртуальной памяти для системы' 
                    WHEN XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint') = 2 AND 
                         XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]','tinyint')   = 0 
                    THEN'Недостаточно физической памяти для запросов'
                    WHEN XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint') = 4 AND 
                         XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]', 'tinyint')  = 4
                    THEN 'Недостаточно виртуальной памяти для запросов и системы'
                    WHEN XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]','tinyint')  = 2 AND 
                         XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]','tinyint')   = 4 
                    THEN 'Недостаточно виртуальной памяти для системы и физической для запросов'
                    WHEN XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint') = 2 AND 
                         XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]', 'tinyint')  = 2 
                    THEN 'Недостаточно физической памяти для системы и запросов'
         END
FROM        RingBufferXML
CROSS APPLY RingBufferXML.RBR.nodes ('Record') Record (XMLRecord)
WHERE       XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]','tinyint') IN (0,2,4) AND
            XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]' ,'tinyint') IN (0,2,4) AND
            XMLRecord.value('(ResourceMonitor/IndicatorsProcess)[1]','tinyint') +
            XMLRecord.value('(ResourceMonitor/IndicatorsSystem)[1]' ,'tinyint') > 0
		
-- Распределение памятьи
	 select 
	type,SUM(single_pages_kb +multi_pages_kb + virtual_memory_committed_kb+shared_memory_committed_kb+awe_allocated_kb) as Summ_KB,
	sum(virtual_memory_reserved_kb) as [VM Reserved],
	sum(virtual_memory_committed_kb) as [VM Committed],
	sum(awe_allocated_kb) as [AWE Allocated],
	sum(shared_memory_reserved_kb) as [SM Reserved], 
	sum(shared_memory_committed_kb) as [SM Committed],
	sum(multi_pages_kb) as [MultiPage Allocator],
	sum(single_pages_kb) as [SinlgePage Allocator],  convert(varchar,getdate(),120) as EventTime
	  
	from 
		sys.dm_os_memory_clerks 
	group by type order by Summ_KB desc
	
-- DAS и SAN
- SAN это система HBA (Host Bus Adapter) + FC Switch (часто 2 для распредления нагрузки и подстраховки) + DAS
- Пропускная способность PCI-E v 2.0:
	x1 = 800 MBps
	x2 = 1600
	x4 = 3200
	x8 = 6400
	x16 = 12800
- Не забыть выбрать правильный SFP
- За контроллерами на СХД можно и нужно закрепить разные лучны, чтобы балансировать нагрузку
- Лучше сделать 12 лун и в них рейды, чем 1 рейд, в котором будет 12 лун

-- Драйвера MPIO
- В нём есть необходимость, если используется несколько СХД

-- ********************************************* Paul Randal *********************************************
-- SQLPERF
- Выводятся сведения LOGSPACE для всех баз данных, содержащихся в экземпляре SQL Server.
	DBCC SQLPERF(LOGSPACE);
- Сбрасывается статистика ожидания для экземпляра SQL Server
	DBCC SQLPERF("sys.dm_os_wait_stats",CLEAR);	
	
-- Статистика задержек IO/IO latency
	SELECT
		--virtual file latency
		[ReadLatency] =
			CASE WHEN [num_of_reads] = 0
				THEN 0 ELSE ([io_stall_read_ms] / [num_of_reads]) END,
		[WriteLatency] =
			CASE WHEN [num_of_writes] = 0
				THEN 0 ELSE ([io_stall_write_ms] / [num_of_writes]) END,
		[Latency] =
			CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
				THEN 0 ELSE ([io_stall] / ([num_of_reads] + [num_of_writes])) END,
		--avg bytes per IOP
		[AvgBPerRead] =
			CASE WHEN [num_of_reads] = 0
				THEN 0 ELSE ([num_of_bytes_read] / [num_of_reads]) END,
		[AvgBPerWrite] =
			CASE WHEN [io_stall_write_ms] = 0
				THEN 0 ELSE ([num_of_bytes_written] / [num_of_writes]) END,
		[AvgBPerTransfer] =
			CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
				THEN 0 ELSE
					(([num_of_bytes_read] + [num_of_bytes_written]) /
					([num_of_reads] + [num_of_writes])) END,
		LEFT ([mf].[physical_name], 2) AS [Drive],
		DB_NAME ([vfs].[database_id]) AS [DB],
		--[vfs].*,
		[mf].[physical_name]
	FROM
		sys.dm_io_virtual_file_stats (NULL,NULL) AS [vfs]
	JOIN sys.master_files AS [mf]
		ON [vfs].[database_id] = [mf].[database_id]
		AND [vfs].[file_id] = [mf].[file_id]
	-- WHERE [vfs].[file_id] = 2 -- log files
	-- ORDER BY [Latency] DESC
	-- ORDER BY [ReadLatency] DESC
	ORDER BY [WriteLatency] DESC;
	GO

-- Использование индексов (sys.dm_db_index_usage_stats)
- Информация обнуляется после перезагрузки сервера или rebuild индекса, но не обнуляется при reorganize
	SELECT  DB_NAME(database_id) as DatabaseName, OBJECT_NAME(u.[object_id], database_id) as ObjectName, i.name,*
	FROM sys.dm_db_index_usage_stats u
	INNER JOIN sys.indexes i ON
		 u.object_id = i.object_id AND
		 u.index_id = i.index_id
		 
-- Split page/дробление страниц/разделение страниц
	- Очень дорогая операция = примерно 40 операциям вставки
	
-- Транзакции
	SELECT DB_NAME(database_id) AS DB,* FROM sys.dm_tran_database_transactions	
	
-- Replay Workload/проигрывание нагрузки
	1. Profiler
	2. RML OSTress
	3. Distributed Replay (SQL Server 2012)
	
-- Нагрузка на tempdb
	SELECT session_id,wait_type,wait_duration_ms,blocking_session_id,resource_description FROM sys.dm_os_waiting_tasks
	WHERE wait_type like 'PAGE%LATCH_%' and resource_description like '2:%'
	
-- PAL
	- Требуется скачать, установить и отдать на анализ собранную perfmon трассу
	- Можно анализирвать не все данные, а за указанную дату из него
	
-- SQLDIAG
	- Устанавливается вместе с SQL Server
	- Можно создать template (PSSDIAG) и предоставить админам, который запустят и пришлют трассу, которую можно анализировать
	- Можно подсунуть результат в PAL

-- Data Collection/Сбор Perfmon
	- выпонялть в cmd
	- Чтобы посмотреть отчёты после сбора статистики, надо нажать пкм на Data Collection > Reports...	
	- Запуск коллектора через cmd
		logman start NameOfDataCollector
	- Остановка
		logman stop NameOfDataCollector
	-- Импорт готового шаблона (xml)
		logman import datacollector_test -xml C:\test.xml
	-- Обновление шаблона (начало нового файла после 600 Мб)
		logman update datacollector_test -f bincirc -max 600 
