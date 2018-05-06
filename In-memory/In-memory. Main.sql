-- In-memory
	- Сравнение 2014 и 2016
		https://www.simple-talk.com/sql/learn-sql-server/introducing-sql-server-in-memory-oltp/ (таблица внизу)
	- Интересно	
		https://www.youtube.com/watch?time_continue=1&v=uXZF1gug6pU

	Старая система - поблочное храрение, обмен данных между диском и памятью
	Нет блокировок и латчей, появляется конфликт записи
	
	-- Какая стояла задача на момент начала установки
		- Optimized for data that was stored completely in-memory but was also durable on SQL Server restarts.
		- Fully integrated into the existing SQL Server engine.
		- Very high performance for OLTP operations.
		- Architected for modern CPUs (e.g. use of complex atomic instructions).
	
	-- Нововведения 2016
		- ALTER 
		- Почти полное покрытие TSQL
		- До 2Тб данных (но это не лимит, только рекомендации. При этом не размер БД, а размер данных в памяти (таблицы...))
	
	-- Вопросы
		- В чём отличие снэпшота и in memory
		- Как обеспечивается durability
		- Как работает free lock?

	-- Основное
		1. Требуется быстрый диск для файла лога, иначе можно не получить прироста. Идёт полное логирование, но без операции UNDO
		2. Создаётся отдельная файловая группа, в которой 2 сущности (работают как пара): файл данных и Delta File (страницы внутри). В файл данных попадают строки, которые всталяются
		3. Удаляемые записи не удаляются сразу, а помечаются на удаление. В Delta File создаётся ссылка на удаляемую строку, то есть происходит логическое удаление.
		4. При поднятии таблицы в память, поднимаются только те строки, которых нет в Delta File
		5. Update выглядит как DELETE старой строки и вставка новой
		6. Из-за не явного удаления место высвобождается не моментально, есть теневой процесс, который объединяет страницы, на которых много строк помечено для удаления (MERGE процесс). Данный процесс берёт 2 пары (файл данных и Delta File), создаёт новую пару и копирует туда только те строки, которые не помечены на удаление, после чего удаляет старые
		7. В памяти операции происходят параллельно с диском. Записи так же не удаляются, а помечаются на добавление, новые вставляются
		8. Можно настроить отложенную запись, будет быстрее, но появится риск потери данных
		9. CHECKPOINT выполнятся только когда файл лога выростет до 1,5 Гб, можно увеличить это значение до 12 Гб (2016). Актуально когда лог ростёт более 300 Мб/сек. Для этого необходимо включить флаг -T9912 
		10. Работает и с Cluster и c AlwaysOn
		11. Новый сопособ хранения не по страницам, а по строкам. Создан дополнительный, новый Engine без блокировок и latch
		12. Использует отдельные структуры памяти для хранения своей информации
		13. Только COMMIT вызывает запись в лог
		14. Отедьлный CHECKPOINT от обычного хранения (это реализовано в виде файлов на диске и сделано чтобы не читать весь лог, а чтобы можно было прочитать эти файлы и понять как восстанавливать работу), хранит только незафиксированные транзакции. Нет UNDO recovery для таблиц в памяти
		15. Версионность не использует tempdb
		16. Является частью Buffer Pool
		
	-- За счёт чего лучшение производительности
		1. Все данные таблицы держатся в памяти и не уходят от туда
		2. Спец. процедуры, которые компилируются 1 раз и хранятся в коде C
		3. Нет Latch/LOCK
			Latch Contention
			A typical scenario is contention on the last page of an index when inserting rows concurrently in key order. Because In-Memory OLTP does not take latches when accessing data, the scalability issues related to latch contentions are fully removed.
			Spinlock Contention
			Because In-Memory OLTP does not take latches when accessing data, the scalability issues related to spinlock contentions are fully removed.
			Locking Related Contention
			If your database application encounters blocking issues between read and write operations, In-Memory OLTP removes the blocking issues because it uses a new form of optimistic concurrency control to implement all transaction isolation levels. In-Memory OLTP does not use TempDB to store row versions.
			If the scaling issue is caused by conflict between two write operations, such as two concurrent transactions trying to update the same row, In-Memory OLTP lets one transaction succeed and fails the other transaction. The failed transaction must be re-submitted either explicitly or implicitly, re-trying the transaction. In either case, you need to make changes to the application.
			If your application experiences frequent conflicts between two write operations, the value of optimistic locking is diminished. The application is not suitable for In-Memory OLTP. Most OLTP applications don’t have a write conflicts unless the conflict is induced by lock escalation.
		4. Запись в лог больщими блоками (только во время commit), больше оптимизации. Так же логируются только логические операции, а так же только redo + логиру
			- only logical changes are logged into the transaction log.
			- For example, it doesnt log any changes to data in indexes. It will also never write log records associated with uncommitted transactions, since SQL Server will never write dirty data to disk for in-memory tables. Also, rather than write every atomic change as a single log record, in-memory OLTP will combine many changes into a single log record. 
		5. Нет update, строк удаляются, а старые чистит фоновый процесс.  Delete только логически помечается как удалённый и не генерит IO. Информация о удалённых строках хранится в Delta file
		6. Получает данные на момент начала транзакции
		7. undo-phase will never ever happen during crash recovery
		8. Можно заменить таблицы tempdb на таблицы в памяти для ускорения. in-memory не использует lock and latch за счёт этого достигается огромный прирост в производительности
		9. Inmemory 2016 пишет в лог, только если был COMMIT
		10. Записи состоят из нескольких операций
		11. Нет страниц и экстентов. Всё работает через указатели
		12. Страницы в Bw-tree индексе, могут иметь динамичный размер
	
	-- Особенности	
		- SET STATISTICS IO ON не работает
		- План выполнения посмотреть нельзя
		- Нет параллелизма (2014)
		- Вместо begin tran > Begin atomic
		- Из новых процедур не можем работать с обычными таблицами
		- Прежде чем создать процедуру, нужно обновить статистику иначе создаться с неактуальной и будет так выполняться
		- Есть счётчики с расширением xtp (perfmon)

		- не следует все процедуры переписывать, только те, что работают с таблицами in-memory
		- При создании индекса, экспериментально создавать пачки разбиения (bucket), чтобы была меньше цепочка (меньше 50, 5 - хорошо) (max...length)
		- При создании файловой группы In-memory указываются каталоги, где будет храниться delta checkpoint file и data checkpoint file. Если указано 1 точка, то будут храниться вместе, если 2, то по отдельности
	
	-- Что нужно решить перед тем как применить in-memory
		1. Хватит ли памяти (размер бд, view, версии строк, рост)
		2. Hash or Non-clustered index (долежен быть хотя бы 1. Hash для уникальных строк, Non-clustered для  range)
		3. Доступность (только схема или схема и данные)
		4. Использовать или нет native compile procesure
		5. .ldf должен лежать на быстром хранилище (рандомная запись, например SSD), чтобы он не тормозил in-memory. Для быстрой загрузки данных в память нужно чтобы было много файлов БД и быстрая дисковая подсистема
		6. Желательно создать 2 папки с быстрым последовательным доступом для delta checkpoint file и data checkpoint file
		7. Fully integrated with the SQL Server memory manager is the in-memory OLTP memory manager, which will react to memory pressure when possible, by becoming more aggressive in cleaning up old row versions.
	
	-- Минусы
		1. mirroring and replication of memory-optimized tables are unsupported (2014)
		2. Once you create a memory-optimized filegroup, you can only remove it by dropping the database. In a production environment, it is unlikely that you will need to remove the memory-optimized filegroup.

-- Пример
	ALTER DATABASE t ADD FILEGROUP IMDB_mod_FG CONTAINS MEMORY_OPTIMIZED_DATA;

	ALTER DATABASE t ADD FILE (name='imoltp_mod1', filename='D:\data\imoltp_mod1') TO FILEGROUP mo

	CREATE TABLE [mod]
	(
		id [int] NOT NULL,
		[name] [nvarchar](500) NOT NULL,

		CONSTRAINT [PK_Common.RegisteredFilters] PRIMARY KEY NONCLUSTERED HASH 
		(
			id
		)WITH (BUCKET_COUNT = 1024),
		INDEX ix_name NONCLUSTERED ([name]),
		INDEX ix_id HASH (id) WITH (BUCKET_COUNT = 10000),
		INDEX ix_cc CLUSTERED COLUMNSTORE WITH (COMPRESSION_DELAY = 60)

	)WITH (MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_and_data)

	DROP TABLE [mod]

		
-- Уровни изоляции/ISOLATION LEVEL
	When accessing memory-optimized tables from interpreted T-SQL, we mustspecify the isolation level using a table-level hint, or via a new database option called MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT. For a natively compiled stored procedure, we must specify the transaction isolation level as part of an ATOMIC block
	
	-- Чтобы изменить уровень изоляции для таблиц в памяти на SNAPSHOT, надо выполнить. То есть мы можем внутри обычной транзакции обратиться к таблице в памяти, то это обращение в режиме SNAPSHOT
		ALTER DATABASE HKDB
		SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT ON;
		
		-- Проверить текущее значение
			SELECT is_memory_optimized_elevate_to_snapshot_on
			FROM sys.databases
			WHERE name = 'HKDB';
			SELECT DATABASEPROPERTYEX('HKDB',
			'IsMemoryOptimizedElevateToSnapshotEnabled');
			
-- Сборщик мусора/Garbage collection
	To determine which rows can be safely deleted, the in-memory OLTP engine keeps track of the timestamp of the oldest active transaction running in the system, and uses this value to determine which rows are potentially still needed
	
	-- Можно получить информацию по которую использует сборщик мусора
		SELECT name AS 'index_name' ,
		s.index_id ,
		scans_started ,
		rows_returned ,
		rows_expired ,
		rows_expired_removed
		FROM sys.dm_db_xtp_index_stats s
		JOIN sys.indexes i ON s.object_id = i.object_id
		AND s.index_id = i.index_id
		WHERE OBJECT_ID('<memory-optimized table name>') = s.object_id;

-- Открытые транзакции для таблиц в памяти
	SELECT xtp_transaction_id ,
	transaction_id ,
	session_id ,
	begin_tsn ,
	end_tsn ,
	state_desc
	FROM sys.dm_db_xtp_transactions
	WHERE transaction_id > 0;		

-- CHECKPOINT
	SELECT file_type_desc ,
	state_desc ,
	internal_storage_slot ,
	file_size_in_bytes ,
	inserted_row_count ,
	deleted_row_count ,
	lower_bound_tsn ,
	upper_bound_tsn ,
	checkpoint_file_id ,
	relative_file_path
	FROM sys.dm_db_xtp_checkpoint_files
	ORDER BY file_type_desc ,
	state_desc ,
	lower_bound_tsn;	
	
	-- Со временем data file заполняются данными, которые уже удалены и их приходится объединять
		- Процесс происходит автоматически, но есть недокументированный флаг для отключения этого процесса - 9851
			EXEC sys.sp_xtp_merge_checkpoint_files 'CkptDemo', 1877, 12007
			
		-- Посмотреть результат merge
			SELECT request_state_desc ,
			lower_bound_tsn ,
			upper_bound_tsn
			FROM sys.dm_db_xtp_merge_requests;
			
			Requested - a merge request exists.
			Pending - the merge is being processing.
			Installed - the merge is complete.
			Abandoned - the merge could not complete, perhaps due to lack of storage.

-- Оптимизация / Мониторинг
	-- Количествоinsert/update
		sys.dm_db_xtp_object_stats 
	-- Проблемы merge deltra store
		sys.dm_db_xtp_merge_requests
	-- Занимаемое пространство
		SELECT * FROM sys.dm_db_xtp_table_memory_stats
	-- Есть ли очереди на garbage collector / сборщик мусора
		SELECT * FROM sys.dm_xtp_gc_queue_stats WHERE current_queue_depth > 0
	-- Проблемы bucket counts
		SELECT * FROM sys.dm_db_xtp_hash_index_stats
			
		
-- Миграция на in-memory
	1. Отчёт по таблицам в SSMS (Transaction Performance Analysis Report), на сколько сложно выполнить миграцию
	2. Детальный отчёт по конкретной таблице (memory Opimization Advizor)
	3. Native Compilation Advizor (анализ процедуры на совместимость с in-memory, пкм на процедуре)
	
	-- Требования
		- Оценка необходимого количество памяти
			https://msdn.microsoft.com/library/dn282389.aspx
	
	-- Ограничения
		1. Максимальная длина строки 8кб
		
	-- Restore
		- Обычный
			БД не будет доступна, пока таблица не поднимется в память
			
		- Xастичный		
			If you back up (or restore) the primary filegroup you must specify the memory-optimized filegroup.
			If you backup (or restore) the memory-optimized filegroup you must specify the primary filegroup.
			
		- Crash recovery
			Сначала поднимаются в память Data file и Delta file, потом на них накатываются логи
				
	-- Memory-Optimizes tables/procedures
		- Нет блокировок данных, используется версионность
		- Компиляция в нативный видео процедур и данных
		- Не можем использовать большие объекты
		- Не поддерживается айдентити и внешние ключи (есть конструкции, как можно это обойти структурно в интернете)
		- Из-за специфики приложение должно уметь повторно выполнять команды
		- Чтобы поместить 100 Гб БД в память, нужно 200 Гб памяти
		- Создавать объекты в таблице можно только при её создании
		- Есть специальный встроенный анализ что можно вынести в память 
			
		-- Тонкости
			- Если из таблицы и так часто читаете, то выигрышь от In-memory скорее всего не получите, так как данные и так в памяти
			- Обязательно перевести процедуру в нативный код, чтобы точно было ускорение. Много ограничений
			- Свойство при создании таблицы DURABILITY = SCHEMA_ONLY (таблица на диске не сохраняется и очищается при рестарте. Как результат гораздо быстрее операции)
			- Свойство при создании таблицы DURABILITY = SCHEMA_AND_DATA (происходит запись на диск, хоть и менее большая)
			- Index Hash хорошо работает, когда нужно найти одну строку
			- Index Range (похожь на обычный индекс), для команды Between
			
		-- Кога применять
			- Если вы таблицу часто модифицируете
			- Простые модификации (много ограничений)
			- Когда можно поместить безопасно данные в память (возможность потери при перезагрузке)
			- Смотреть на временные таблицы и на табличные переменные
			
	-- Табличные типы
		- Замена временных таблиц и табличных переменных
	
	-- Какие приложения следует мигрировать
		In-memory OLTP addresses the major bottlenecks below.
		• Lock or latch contention
		The lock- and latch-free design of memory-optimized tables is probably the bestknown performance benefit. As discussed in detail in earlier chapters, the data structures used for the memory-optimized tables row versions mean that SQL Server can preserve ACID transaction properties without the need to acquire locks. Also, the fact that the rows are not stored within pages in memory buffers means that there is no latching. This allow for high concurrency data access and modification without the need for locks or latches. Tables used by an application showing excessive lock or latch wait times will likely show substantial performance improvement when migrated to in-memory OLTP.
		• I/O and logging
		Data rows in a memory-optimized table are always in memory, so no disk reads are ever required to make the data available. The streaming checkpoint operations are also highly optimized to use minimal resources to write the durable data to disk in the checkpoint files. In addition, in-memory OLTP never writes index information to disk, reducing the I/O requirements even further. If an application shows excessive page I/O latch waits, or any other waits associated with reading from, or writing to, disk, use of memory-optimized tables will likely improve performance.
		• Transaction logging
		Log I/O can be another bottleneck with disk-based tables since, in most cases for OLTP operations, SQL Server writes to the transaction log on disk a separate log record describing every table and index row modification. In-memory OLTP allows us to create SCHEMA_ONLY tables that do not require any logging, but even for tables defined as SCHEMA_AND_DATA, the logging overhead is significantly reduced. Each log record for changes to a memory-optimized table can contain information about many modified rows, and changes to indexes are never logged at all. If an application experiences high wait times due to log writes, migrating the most heavily-modified tables to memory-optimized tables is likely to result in performance improvements.
		• Hardware resource limitations
		In addition to the limits on disk I/O that can cause performance problems with disk-based tables, other hardware resources can also be the cause of bottlenecks. CPU resources are frequently stressed in compute-intensive OLTP workloads. In addition, CPU resources also cause slowdowns when small queries need to be executed repeatedly and the interpretation of the code needed by these queries needs to be repeated over and over again. Migrating such code to natively compiled procedures can greatly reduce the CPU resources required, because the natively compiled code can perform the same operations with far fewer CPU instructions than the interpreted code. If you have many small code blocks running repeatedly, especially if you are noticing a high number of recompiles, you may notice a substantial performance improvement from migrating this code into natively compiled procedures.
		- High volume of INSERTs
		- High volume of SELECTs
		- CPU-intensive operations
		- Extremely fast business transactions
		- Session state management
		
	-- Какие приложения не следует мигрировать
	• Inability to make changes
	If an application requires table features that are not supported by memory-optimized tables, you will not be able to create in-memory tables without first redefining the table structure. In addition, if the application code for accessing and manipulating the table data uses constructs not supported for natively compiled procedures, you may have to limit your T-SQL to using only interop code.
	• Memory limitations
	Memory-optimized tables must reside completely in memory. If the size of the tables	exceeds what SQL Server In-Memory OLTP or a particular machine supports, you will not be able to have all the required data in memory. Of course, you can have some memory-optimized tables and some disk-based tables, but youll need to analyze the workload carefully to identify those tables that will benefit most from migration to memory-optimized tables.
	• Non-OLTP workload
	In-memory OLTP, as the name implies, is designed to be of most benefit to Online Transaction Processing operations. It may offer benefits to other types of processing, such as reporting and data warehousing, but those are not the design goals of the feature. If you are working with processing that is not OLTP in nature, you should carefully test all operations to verify that in-memory OLTP provides measurable improvements.
	• Dependencies on locking behavior
	Some applications rely on specific locking behavior, supplied with pessimistic concurrency on disk-based tables. Its not a best practice, in most cases, because this locking
	behavior can change between SQL Server releases, but it does happen. For example, an application might use the READPAST hint to manage work queues, which requires SQL Server to use locks in order to find the next row in the queue to process. Alternatively, lets say the application is written to expect the behavior delivered by accessing
	disk-based tables using SNAPSHOT isolation. In the event of a write-write conflict,	the correct functioning of the application code may rely on the expectation that SQL Server will not report the conflict until the first process commits. This expected	behavior is incompatible with that delivered by the use of SNAPSHOT isolation with memory-optimized tables (the standard isolation level when accessing memoryoptimized	tables). If an application relies on specific locking behavior, then youll need to delay converting to in-memory OLTP until you can rewrite the relevant sections of your code.
	
	-- Рельные конторы, работающие с in-memory
	- Касперский
	• bwin (http://tinyurl.com/ltya25m), the worlds largest regulated online gaming	company. SQL Server 2014 allows bwin to scale its applications to 250 K requests a second, a 16x increase from before, and to provide an overall faster and smoother customer playing experience.
	• Ferranti (http://tinyurl.com/ozscnd4), which provides solutions for the energy market worldwide, is collecting large amounts of data using smart metering. They use in-memory OLTP to help utilities be more efficient by allowing them to switch from the traditional meter that is measured once a month to smart meters that provide usage measurements every 15 minutes. By taking more measurements, they can better	match supply to demand. With the new system supported by SQL Server 2014, they increased from 5 million transactions a month to 500 million a day.
	• TPP (http://tinyurl.com/q49j6wq), a clinical software provider, is managing more than 30 million patient records. With in-memory OLTP, they were able to get their new solution up and running in half a day, and their application is now seven times faster than before, peaking at about 34,700 transactions per second.
	• SBI Liquidity Market (http://tinyurl.com/kokhols), an online services provider for foreign currency exchange (FX) trading, wanted to increase the capacity of its trading
	platform to support its growing business and expansion worldwide. SBI Liquidity	Market is now achieving better scalability and easier management with in-memory	OLTP and expects to strengthen its competitive advantage with a trading platform that is ready to take on the global marketplace.
	• Edgenet (http://tinyurl.com/lnrls4u) provides optimized product data for suppliers, retailers, and search engines including Bing and Google. They	implemented SQL Server 2014 to deliver accurate inventory data to customers. They are now experiencing seven time faster throughput and their users are creating reports with Microsofts self-service Business Intelligence tools to model huge data volumes in seconds.
	
	
-- Проблемы, поиск проблем
	- Колизии (мало бакетов/частей индекса, а записей много)
		SELECT * FROM sys.dm_db_xtp_hash_index_stats (avg_chain_lengh, если больше 1, то это и есть колизии)
		- Решение 
			Создать больше бакетов. Оптимально - количество бакетов = количеству уникальныз значений. Больше делать не надо, так как будет израсходована память в пустую, которую к тому же надо ещё и сканировать
	- Открытые транзакции, даже которые не относятся к in memory, приведут к тому, что delta file не будет очищен до момента закрытия транзакции, что может привести к окончанию места на диске
	- Не автообновляется статистика
	- Занимает память и для SQL Server может не остаться памяти для комфортной работы
	- Нет параллелизма (2014)
	- Нет поддержки cross database транзакций
	- Нужно пересоздавать таблицу, ALTER не работает. Индексы так же могут быть добавлены только в момент создания
	- BIN2 - регистрозависимый
		
-- Индексы
	- На диске не представлены, сохраняются только данные и при перезагрузке индексы строятся заного
	- Работа с ними не попадает в лог
	
	-- Hash index
		- Хэшируется значение лёгкой функцией, а строки привязываются к этому хэшу
		- Только для точечного использования, FULLSCAN будет очень дорогим, так как будет делаться сортировка
		- Если указано несколько колонок, то в запросе надо указывать их обе, иначе не будет поиска по индексу, а будет SCAN	
		
	-- Nonclustered index (meaning the default internal structure of a B-tree).
		- Указан не физический, а логический номер страницы, так как в памяти они могут меняться и чтобы не менять этот номер стали использовать логический номер, а чтобы понять где это находится физически, SQL Server смотрит табличку Map loockup table (таблица связей), в которой и происходит изменение адреса этой страницы в памяти
		- Может использоваться если указать не все столбцы индекса в запросе, но надо указывать первые колонки индекса в запросе
		- Порядок страниц на листовом уровне только в одну сторону
		
-- BUCKET COUNT
	- Указывать в 1.5-2 раза больше чем значений в таблице (Совет Короткевича). Лучше переоценить, чем недооценить
	- ВСТАВКА: При недооценки приходится найти цепочку и вставить в конец данные
	- ЧТЕНИЕ: При переоценке сканировать ХЭШ очень дорого, так как надо зайти в корзину и просканировать её всю, затем в другую
	- При изменении этого числа, будет перестроен весь хэш индекс
	- Each bucket requires 8 bytes, so the memory required is simply the number of buckets times 8 bytes + размер индексов

-- CREATE TYPE
	- Может быть в памяти
	
-- Создание	
	CREATE TABLE [Common].[RegisteredFilters]
	(
		[HashCode] [int] NOT NULL,
		[RegisteredFilterEnvironment] [int] NOT NULL,
		[ServerName] [nvarchar](500) NOT NULL,
		[FilterSerial] [bigint] NOT NULL,
		[LastUpdateDate] [datetime] NOT NULL,

	CONSTRAINT [PK_Common.RegisteredFilters] PRIMARY KEY NONCLUSTERED HASH 
	(
		[HashCode],
		[RegisteredFilterEnvironment]
	)WITH (BUCKET_COUNT = 1024)
	)WITH (MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_ONLY)
	
	-- Процедура
		- SQL Server does not use parameter sniffing for compiling natively compiled stored procedures. All parameters to the stored procedure are considered to have UNKNOWN values.
	
		create procedure dbo.OrderInsert(@OrdNo integer, @CustCode nvarchar(5))  
		with native_compilation, schemabinding  
		as   
		begin atomic with  
		(transaction isolation level = snapshot,  
		language = N'English')  
		  
		  declare @OrdDate datetime = getdate();  
		  insert into dbo.Ord (OrdNo, CustCode, OrdDate) values (@OrdNo, @CustCode, @OrdDate);  
		end  
		go 
		
		-- Посмотреть созданные 
			SELECT name ,
			description
			FROM sys.dm_os_loaded_modules
			WHERE description = 'XTP Native DLL'
			
		
	-- Чтобы не заморачиваться с уровнем доступа по изоляции транзакций
		ALTER DATABASE CURRENT SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT=ON  
		

-- Мониторинг
	SELECT object_name(object_id) AS Name , *  
   FROM sys.dm_db_xtp_table_memory_stats  

	- sys.sp_xtp_control_query_exec_stats – enables per query statistics collection for all natively compiled stored procedures for the instance.
	- sys.sp_xtp_control_proc_exec_stats – enables statistics collection at the procedure level, for all natively compiled stored procedures.

	SELECT object_name AS ObjectName ,
		counter_name AS CounterName
		FROM sys.dm_os_performance_counters
		WHERE object_name LIKE 'XTP%';
			
	-- Memory consumption by internal system structures
	   SELECT memory_consumer_desc  
		 , allocated_bytes/1024 AS allocated_bytes_kb  
		 , used_bytes/1024 AS used_bytes_kb  
		 , allocation_count  
	   FROM sys.dm_xtp_system_memory_consumers  
	   
-- Найти все объекты, который ссылаются на таблице в памяти
	declare @t nvarchar(255) = N'Common.RegisteredFilters'  

	select r.referencing_schema_name, r.referencing_entity_name
	from sys.dm_sql_referencing_entities (@t, 'OBJECT') as r join sys.sql_modules m on r.referencing_id=m.object_id  
	where r.is_caller_dependent = 0 and m.is_schema_bound=1;  
	
-- Columnstore indexes in memory
	- Улучшение работы в 10-100 раз
	- Сжатие до 20 раз
	- Строки хранятся в rowgroup, rowgroup делятся на segments (по количеству колонок). Segments хранятся в LOB
	- Большая разница между колоночным индексом в памяти и на диске, это то, что в памяти это копия данных
	- Работа в пакетном режиме
		- по 1000 строк, CPU спадает до 40 раз
	- Комбинация появилас в 2016
		1. Оперативная аналитика. 		
			- Можно на OLTP таблицы добавлять колоночный индекс. Обновление и использование будет качественным
			- Можно сделать колоночный индекс на in memory таблицах
		2. Поддержка вторичных реплик AlwaysOn
		3. Ускорена работа индекса
		4. Поддержка оконных функций
		5. На колоночных индексах можно строить другие типы индексов, не только кластерный
		
-- Объекты, которые могут быть в памяти
	1. Функция (2016)
	2. Таблица (2014)
	3. Процедура (2014)
	4. Табличный тип (2014)
	
	-- Проблемы объектов в памяти
		1. Занимает память
		2. Статистика
		
-- Найти где используется/найти где включено
	EXEC sp_MSforeachdb 'USE ? IF EXISTS (SELECT 1 FROM sys.filegroups FG
		JOIN sys.database_files F
		ON FG.data_space_id = F.data_space_id
		WHERE FG.type = ''FX'' AND F.type = 2)
		PRINT ''?'' + '' can contain memory-optimized tables.'' ';
		GO
		
-- DMV
	- sys.dm_db_xtp_checkpoint_stats
	Returns statistics about the in-memory OLTP checkpoint operations in the current
	database. If the database has no in-memory OLTP objects, returns an empty result set.
	- sys.dm_db_xtp_checkpoint_files
	Displays information about checkpoint files, including file size, physical location and
	the transaction ID. For the current checkpoint that has not closed, the state column
	of this DMV will display UNDER CONSTRUCTION, for new files. A checkpoint closes
	automatically when the transaction log grows 512 MB since the last checkpoint, or if
	you issue the CHECKPOINT command.
	- sys.dm_xtp_merge_requests
	Tracks database merge requests. The merge request may have been
	generated by SQL Server or the request could have been made by a user,
	with sys.sp_xtp_merge_checkpoint_files.
	- sys.dm_xtp_gc_stats
	Provides information about the current behavior of the in-memory OLTP garbage
	collection process. The parallel_assist_count represents the number of rows
	processed by user transactions and the idle_worker_count represents the rows
	processed by the idle worker.
	189
	Chapter 8: SQL Server Support and Manageability
	- sys.dm_xtp_gc_queue_stats
	Provides details of activity on each garbage collection worker queue on the server
	(one queue per logical CPU). As described in Chapter 5, the garbage collection thread
	adds "work items" to this queue, consisting of groups of "stale" rows, eligible for
	garbage collection. By taking regular snapshots of these queue lengths, we can make
	sure garbage collection is keeping up with the demand. If the queue lengths remain
	steady, garbage collection is keeping up. If the queue lengths are growing over time,
	this is an indication that garbage collection is falling behind (and you may need to
	allocate more memory).
	- sys.dm_db_xtp_gc_cycle_stats
	For the current database, outputs a ring buffer of garbage collection cycles containing
	up to 1024 rows (each row represents a single cycle). As discussed in Chapter 5, to
	spread out the garbage collection work, the garbage collection thread arranges transactions
	into "generations" according to when they committed compared to the oldest
	active transaction. They are grouped into units of 16 transactions across 16 generations
	as follows:
	- Generation 0: Stores all transactions that have committed earlier than the oldest
	active transaction and therefore the row versions generated by them can be immediately
	garbage collected.
	- Generations 1–14: Store transactions with a timestamp greater than the oldest
	active transaction meaning that the row versions cant yet be garbage collected.
	Each generation can hold up to 16 transactions. A total of 224 (14 * 16) transactions
	can exist in these generations.
	- Generation 15: Stores the remainder of the transactions with a timestamp greater
	than the oldest active transaction. Similar to generation 0, there is no limit to the
	number of transactions in Generation 15.
	190
	Chapter 8: SQL Server Support and Manageability
	- sys.dm_db_xtp_hash_index_stats
	Provides information on the number of buckets and hash chain lengths for hash
	indexes on a table, useful for understanding and tuning the bucket counts (see
	Chapter 4). If there are large tables in your database, queries against sys.dm_db_
	xtp_hash_index_stats may take a long time since it needs to scan the entire table.
	- sys.dm_db_xtp_nonclustered_index_stats
	Provides information about consolidation, split, and merge operations on the
	Bw-tree indexes.
	- sys.dm_db_xtp_index_stats
	Contains statistics about index accesses collected since the last database restart.
	Provides details of expired rows eligible for garbage collection, detected during index
	scans (see Chapter 5).
	- sys.dm_db_xtp_object_stats
	Provides information about the write conflicts and unique constraint violations on
	memory-optimized tables.
	- sys.dm_xtp_system_memory_consumers
	Reports system-level memory consumers for in-memory OLTP. The memory for
	these consumers comes either from the default pool (when the allocation is in the
	context of a user thread) or from the internal pool (if the allocation is in the context
	of a system thread).
	-- sys.dm_db_xtp_table_memory_stats / Информация о занимаемом месте
	Returns memory usage statistics for each in-memory OLTP table (user and system)
	in the current database. The system tables have negative object IDs and are used to
	store runtime information for the in-memory OLTP engine. Unlike user objects,
	system tables are internal and only exist in memory, therefore they are not visible
	through catalog views. System tables are used to store information such as metadata
	for all data/delta files in storage, merge requests, watermarks for delta files to filter
	rows, dropped tables, and relevant information for recovery and backups. Given that
	the in-memory OLTP engine can have up to 8,192 data and delta file pairs, for large
	in-memory databases the memory taken by system tables can be a few megabytes.
	191
	Chapter 8: SQL Server Support and Manageability
	- sys.dm_db_xtp_memory_consumers
	Reports the database-level memory consumers in the in-memory OLTP database
	engine. The view returns a row for each memory consumer that the engine uses.
	- sys.dm_xtp_transaction_stats
	Reports accumulated statistics about transactions that have run since
	the server started.
	- sys.dm_db_xtp_transactions
	Reports the active transactions in the in-memory OLTP database engine
	(covered in Chapter 5).
	- sys.dm_xtp_threads (undocumented, for internal use only).
	Reports on the performance of the garbage collection threads, whether they are
	user threads or a dedicated garbage collection thread.
	- sys.dm_xtp_transaction_recent_rows (undocumented, for internal use only).
	Provides information that allows the in-memory OLTP database engine to perform its
	validity and dependency checks during post processing.
	
-- best practice/рекомендации/советы
	- Use the COLLATE clause at the column level, specifying the BIN2 collation for every
	character column in a table you want to memory-optimize, rather than the database
	level, because use at the database level will affect every table and every column in a
	database. Or, specify the COLLATE clause in your queries, where it can be used for any
	comparison, sorting, or grouping operation.
	- Do not over- or underestimate the bucket count for hash indexes if at all possible.
	The bucket could should be at least equal to the number of distinct values for the
	index key columns.
	- For very low cardinality columns, create range indexes instead of hash indexes.
	- Statistics are not updated automatically, and there are no automatic recompiles of any
	queries on memory-optimized tables.
	- Memory-optimized table variables behave the same as regular table variables, but
	are stored in your databases memory space, not in tempdb. You can consider using
	memory-optimized table variables	
