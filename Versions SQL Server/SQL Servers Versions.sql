-- SQL Express LocalDB
	- Data Source=(localdb)\v11.0 or (localdb)\MyInstance
	- introduce a dedicated version of SQL Express for developers - LocalDB that delivers the simplicity and yet is compatible with other editions of SQL Server at the API level. 
 
	-- Отличие от SQL Express
		- LocalDB is a lightweight deployment option for SQL Server Express Edition with fewer prerequisites and quicker installation.
		- LocalDB has all of the same programmability features as SQL Express, but runs in "user mode"* with applications and not as a service.
		- LocalDB is not intended for multi-user scenarios or to be used as a server. (If you need to accept remote connections or administer remotely, you need SQL Server Express.)
		- "Express with Tools" (which includes SS Management Studio Express, Azure, etc) can be used with LocalDB or without. (The same goes for "Express with Advanced Services".)
		
-- Windows Internal Database/SQL Server Embedded
	- https://en.wikipedia.org/wiki/SQL_Server_Embedded
	- is a variant of SQL Server Express 2005–2012 that is included with Windows Server 2008 (SQL 2005), Windows Server 2008 R2 (SQL 2005) and Windows Server 2012 (SQL 2012), and is included with other free Microsoft products released after 2007 that require an SQL Server database backend.
	- Windows Internal Database is not available as a standalone product for use by end-user applications. Microsoft provides SQL Server Express and Microsoft SQL Server for this purpose. Additionally, it is designed to only be accessible to Windows Services running on the same machine.
		
-- Полная информация по поддерживаемым ресурсам SQl Server/support features
	https://msdn.microsoft.com/en-us/library/cc645993(v=sql.110).aspx		

-- Возможность работы нескольких эксзепляров на 1 PC
	https://msdn.microsoft.com/en-us/library/ms143694(v=sql.110).aspx
	
-- ***** SQL Server 2000 *****
	-- Startup Parametrs
		HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSSQLServer\MSSQLServer\Parameters
	-- »справление проблем с Backup
		- Change the SQL Server startup parameter from SQL Enterprise Manager (SEM). Under the server properties, click Startup Parameters, type -T3111, and then click Add.
		- Start SQL Server and set the trace flag from a command prompt:-
		sqlservr -d"C:\Program Files\Microsoft SQL Server\MSSQL\Data\master.mdf" -T3111
		
-- ***** SQL Server 2008 *****
	- Новшества:
		1. Stream insight (обработка большого потока пакетов). См  'Сторонние разработки'
		2. Централизованное управление серверами и приложениями (SQL Server Utility Point). См  'Сторонние разработки'
		
-- *****Отличия SQL Server 2005 от SQL Server 2008 *****
	1. Присвоение переменных в одну строку. 
	2. Математический синтаксис    
		DECLARE @myVar int = 5 
		SET @myVar += 1
	3. Компрессия	
		- 2 вида компрессии
		- Бекапы автоматически сжимаются
		- В целом сообщается, что нагрузка на процессор может возрасти и использование памяти уменьшится.
	4. Появились индексы с фильтрацией.
	5. В SQL Server 2008 есть автоматический аудит
	6. Новый дебаггер
	7. Прозрачное шифрование БД
	8. Замораживание плана запросов (Plan freezing). --?
	9. Resource Governor
	10. Новые типы данных (DATE, TIME, DATETIMEOFFSET, DATETIME2, Hierarchyid, GEOMETRY, GEOGRAPHY, FILESTREAM)
	11. Table Value Parameters (можно передавать таблицы как параметр)
	12. IntelliSense 
	13. Обновился Activity Monitor 
	14. New Replication improvements (Change Data Capture , Change tracking etc.) 
	15. Partitioned Indexed Views
	16. Powershell 
	17. Policy Based Management 
	18. XEvents
	19. Change data capture
	
-- ***** SQL Server 2012 *****
	-- Новшества:
		1. Более лучшая работа с памятью
		2. Автономные БД
		3. Колоночные индексы (проект Apollo)/column store
			Нельзя Update
		4. Более лучшие файловые таблицы
		5. Новшества в T-SQL
			- Постраничный вывод результатов (OFFSET...FETCH)
			- Оконная агрегация SUM() OVER ()
			- Перебор результирующего набора Lag,Lead
			- Последовательности	
		6. TRY_CAST,TRY_CONVERT,TRY_PARSE (при ошибке возвращает NULL)
		7. Создание ролей сервера
		8. Можно делать REBUILD online на кластерном индексе
		9. restart recovery can be run on multiple databases in parallel, each handled by a different thread.
		10. Симантический поиск/semantic search
		11. Inderect checkpoint для БД
			-- если в sp_configure recovery interval стоит 0, то это означание 1 минуту
			ALTER DATABASE AdventureWorks2008R2 SET TARGET_RECOVERY_TIME = 120 SECONDS; 
		12. AlwaysON. Только 5 реплик
		13. Если у вас редакция Enterprise, то добавление non-NULL колонки, происходит быстро и заполнеяется по мере обращения к строкам (http://rusanu.com/2011/07/13/online-non-null-with-values-column-add-in-sql-server-11/)
			
		-- Sql Operation System (SQLOS) 2012.
		- Это тонкий слой между SQL Server и Windows. Занимается планирование задач, управлением памяти, ввод-вывод,
		  отладка, маштабирование, горячая замена памяти/процессоров, монитор ресурсов, блокировок.
		- Используется SQL Server`ом и SSRS

		-- Изменения в диспетчере памяти в SQL SERVER 2012
		- Вне ограничиваемой памяти остался только CLR и небольшая служебная часть SQL
		- Зачем понадобилось менять
			1. Сложно было регулировать расчет потребления памяти
			2. Раньше ограничивало не всю память, а только часть
			3. Регулятор ресурсов не мог следить за всеми страницами памяти
			4. Сложно работать с большими запросами, которые выделяют больше 8 кб
			5. Неоднородная обработка памяти

		-- Изменения в регуляторе ресурсов SQL SERVER 2012
		- Зачем:
			1. Мало пулов
			2. Изменились процессоры и аппаратура
		- Что:
			1. Пулов стало больше для 64 битрых версий
			2. Более предстазуемый учет, изоляция при установке ограничения по использованию процессора
			3. Вертикальная изоляция ресурсов машины
			4. Новый DMV для ассоциации ресурсов пула (sys.dm_resource_governor_resource_pool_af_finity)
			5. Новый синтаксис
			
		-- Изменения в программировании SQL SERVER 2012
		- Что?
			- Поддержка .Net Framework 4
			- Библиотеки переносных классов
			- Глобализационные возможности
			- Числа Biginteger и Complex
			- новые tuple-классы
			
		-- Изменения в Диагностике и трассировке SQL SERVER 2012
		- sp_server_diagnostics (собирает диагног. данные, показывает состояние исправности)
			1. Существует отдельно от планировщика
			2. Увеличенный приоритет потока
			3. Предвариельное резервирование памяти
			4. Нет в/в, блокировок и т.п.
			5. Требуется сетевая подсистема
			6. Не влияет на TPC-E
			7. Требует доступа VIEW SERVER STATE
		- Компоненты:
			1. Обработчик запросов
			2. Ресурсы
			3. Система
			4. Подсистема в/в
			5. События
			
		-- Изменения в ресурсных DLL кластера
		- Что:
			1. Используют хранимые процедуры для определения момента отказа
			2. Настраиваемый уровень чувствительности
			3. Настраиваемый уровень проверки
			4. Интеграция с XEvents
			5. Управление соединениями в фоновом потоке
			
		-- Изменения в расширенных событиях
		- Что:
			1. Графический интерфейс
			2. Управление APIs
			3. Новые события и обновленные имена целей (более чем в 2 раза)
			4. Через расширенные события можно получать те же данные, что и через SQL Trace
			5. Расширенные события для счётчиков производительности
			6. Новые DMV
				- sys.dm_server_services
				- sys.dm_os_volume_stats
				- sys.dm_os_windows_info
				- sys.dm_server_registry
				
		-- Изменения в масштабировании
		- Что:
			1. Поддерживает максмум памяти и процессоров под Windows 8
			2. Поддержка памяти с RAS для улучшенной доступности (если планка памяти позвреждена, SQL возможно
			   её опознает и не будет использовать)
			3. Поддержка динамической памяти в Standart Edition
			
-- ***** SQL Server 2014 *****
	-- Ограничения
	1. Объём оперативной памяти увеличен с 64 Гб до 128 Гб на Standard версии

	-- Новшества:
	0. Восстановление страницы через графический интерфейс
	
	0.1. Шифрование резервных копий 
				
	1. Buffer Pool Extension в SQL Server 2014. Возможность вместо кэша указать SSD
		alter server configuration	set buffer pool extension	on ( filename = 'X:\MyCache.bpe' , size = 64 gb );
		alter server configuration	set buffer pool extension off;
		- Особенности		
			1. Возможность будет доступна только в редакции Enterprise Edition.
			2. Вы не можете задать файл для BPE размером меньше, чем размер текущей оперативной памяти. По крайней мере судя по моим тестам с использованием SQL Server 2014 CTP1, вы будете получать ошибку вида:
				Msg 868, Level 16, State 1, Line 18	Buffer pool extension size must be larger than the current memory allocation threshold 2048 MB. Buffer pool extension is not enabled.
			3. Максимальный поддерживаемый размер оперативной памяти 128 Гб, т.е. обладатели систем с большим размером памяти воспользоваться опцией не смогут. И это довольно неприятный момент, т.к. такой и больший объемы вполне доступны покупателям даже для серверов начального уровня.
			4. Размер файла BPE не может превышать 32 размера вашей оперативной памяти. Т.е. максимально допустимый размер для него будет 32 x 128 Гб = 4 Тб. Рекомендуется задавать размер BPE не более 4-10 размеров оперативной памяти.
			5. Естественно располагать файл следует на быстром SSD диске, иначе смысл опции полностью теряется. И, хотя нет никаких требований к надежности, следует учесть, что если вдруг диск выйдет из строя – вы останетесь без BPE, что может существенно повлиять на производительность вашей системы, если она сильно зависит от этой опции.
	2. In-memory таблиц и процедур (Hekaton)
		- Требует Enterprise Edition
		- Полный список ограничений http://msdn.microsoft.com/en-us/library/dn246937.aspx
		- Чтобы посмотреть подходит ли таблица для перемещения в IN-MEMORY, так же покажет что именно не так >> пкм >> Memory Optimization Advizor
		- Чтобы посмотреть подходит ли процедура для перемещения в IN-MEMORY, так же покажет что именно не так >> пкм >> Native Compilation Advizor
		- Чтобы произвести тестирование рабочей нагрузки на улучшение от in-memory >> настроить Management Data Warehouse на нужную БД >> настроить Collection >> подождать пока будет идти нагрузка >> пкм на БД >> Reports > Management Data Warehouse > Transaction Performance Analysis Overview
		-- Основы
			1. Таблица в памяти, внешнее хранилище используется только для сброса грязных данных и журналирования
			2. Структура хранения не использует блокировки и latch - никаких семафоров, spinlock или критических секций
			3. Весь код компилируется в машинный, которые оперирует напрямую со службами ядра, никаких интерприаторов
			4. Уровень изоляции
				- Задаётся в блоке Atomic или в хинте
				- Snapshot (основной уровень). Никаких latch
				- Repeatable READ
				- SERIALIZABLE
				- Read comitted (поддерживается, но частично)
			5. Комбинирование in-memory и обычных таблиц - всё работает
			6. Более оптимизированная запись в журнал транзакций, есть вообще отключенный журнал транзакций
			7. Появляются табличные типы (CREATE TYPE)
			8. Появились Native Compile PROCEDURE (WITH NATIVE_COMPILATION)
				- В критических частях системы
				- Часто выполняются
		-- Отказались от
			1. Блокировки
			2. Latch (вместо них легковесные блокировки)
			3. Интерпритатор кода исполнения
		-- Индексы
			- Появляется 2 новых индекса:
				1. Hash
					- Только если используем операцию "="
				2. Range/Nonclustered
		-- Ограничения
			1. Не поддерживаются типы: varchar(max), image,xml,text,ntext
			2. Отсутствуют Foreign key и check
			3. alter table - создать таблицу заного
			4. Нет добавления индексов - создать таблицу заного
			5. Нет вычисляемых полей
			6. Табличные переменные (CREATE TYPE NAME as TABLE)
				- Имеют опцию MEMORY_OPTIMIZED = ON
				- Должны иметь хотя бы 1 индекс
				- Ограничения на использование типов такие же как и для таблиц
				- Не поддерживают параллельные планы
				- Должны умещаться в памяти
				- Создаются в пользовательской ДБ
				- Не поддерживается cross db
				- Не могут участвовать в пользовательских транзакциях
				- Нельзя сделать TRANCATE Table
				- Динамические курсоры и keyset-курсоры автоматически переводятся в static
				- Нет многочисленных блокировочных хинтов (TABLOCK, XLOCK, PAGLOCK...)
			7. Должны умещаться в памяти
			8. Индексы
				- Кластерных индексов нет
				- Все индексы - покрывающие
				- Фрагментация и fillfactor не имет смысла
				- Hash индекс
				- Не более 8 на таблицу, включая PRIMARY KEY
				- Не поддерживают nullable поля
				- Бывают HASH (хэш функция, Col1+Col2+Col3) и Range (похож на кластерный)
			9. Статистика
				- Не поддерживает Auto update statistics, но можно обновлять руками
			10. Нет точной информации сколько сейчас данных находится в in-memory
			11. Нельзя менять таблицы/табличные типы, если их используют скомпилированные процедуры (native compile)
			12. Общая длина строки не должна превышать 8060 байт
			13. Индексируемые поля должны быть с COLLATION Binary
			14. Не поддерживаются DML триггеры
			15. Единственным уникальным индексом может быть только PRIMARY KEY
			16. Не более 250 Гб данных
			17. Не поддерживаются транзакции между БД или серверами
		-- Когда стоит применять
			1. В OLTP системах
			2. Когда блокировки (latch) вызывают проблему
			3. Для таблиц ETL
			4. На таблицы с интенсивным чтением
			5. Интенсивная запись/изменение из нескольких потоков (аудит, статусная)
			6. Табличные типы, вместо временных таблиц
		-- Когда не стоит применять
			1. Когда не оптимизированы индексы, ускорение может быть, но незначительное если сравнивать с улучшением индексов
			2. Вы не хотите использовать Hekaton с колоночными индексами и наоборот
		-- Минусы
			1. Не ведётся сбор статистики о выполнении процедур
			2. ALTER TABLE/INDEX не работает
		-- Применить
			1. Добавить файловую группу, которая будет содержать MEMORY_OPTIMIZED_DATA
				ALTER TABLE TableName Add FILEGROUP fg_hekaton CONTAINS MEMORY_OPTIMIZED_DATA
			2. Добавить файл (на самом деле будет папка). Требуется для восстановления после перезагрузки. При необходимости можно создать без логирования на диск
			3. При создании таблицы обязательно указать 1 индекс
			4. Указать WITH (MEMORY_OPTIMIZED = ON)
			5. Индексируемые поля должны быть с COLLATION Binary
			6. Чтобы создать процедуру в памяти (машинный код) нужно добавить WITH NATIVE_COMPILATION (остальные доп. параметры посмотреть в интернете) 
		
	3. Update column store
		Остался необновляемым, просто добавили Delta store (обычное хранения данных), которое обновляется и B-Tree дерево удалённых записей. При этом работает фоновый процесс, которые переводит из Delta store в columns store и удаляет записи
		
	4. Компиляция
		- Перевод процедур, t-sql в машинный код. Хранятся как dll, но загружаются в память каждый раз заного. Такие процедуры работают только с in-memory таблицами
		- Вместо recompile, придётся пересоздавать процедуру, если сильно меняется план
		- Большое количество ограничени
		
	5. Улучшенная скорость работы с tempdb
		
	6. Таблицы в памяти	
		- Кандидаты на таблицы в память	
			- Редко INSERT, но часто UPDATE
			- Если загружаем куда-то данные, обогощаем их, агрегируем и выгружаем
			- Интенсивный доступ на чтение (справочники)
			- Конкуретная запись в одно место
			- Временные таблицы можно заменить на табличные типы
		- Недостатки
			1. Нет статистики
			2. Только loop join
			3. Только последовательные планы
			4. Большую таблицу в память не перенести, память кончится
			5. Транзакция, где участвуют несколько БД
			6. Распределённые транзакции
			7. Все поля могут быть только nvarchar, нужны обязателно явно преобразовывать varchar в nvarchar
			4. Non-clustered Индексы занимают неоправданно много места в памяти
			
	7. Операция SELECT INTO теперь может выполнятся параллельно
	
	8. Теперь операции с tempdb могут не использовать диск, если SQL Server поймёт что они простые и будет достаточно памяти (CREATE #m, INDEX REBUILD...)
		- Это так же доступно и в SQL 2012 SP1 CU10 Improvement
	9. AlwaysON. Максимальное количество реплик увеличено до 8
	

	-- buffer pool extension (SQL Server 2014)
		- Доступно в Standard Edition
		- buffer pool - та область памяти, которую SQL Server любит отъедать себе
		- конфигурация на уровне сервера
		- исключительно на чтение
		- Можем использовать данную технологию, даже не доверяя диску, при его аварии, ничего страшного не случится
		-- Недостатки:
			1. 1 файл расширения, возможно придётся объединять SSD в сторадж
			2. Стоит делать, когда объём активных данных = или < размера SSD
			3. Не более чем х32 от оперативной памяти, но рекомендуется х4-х8
			4. Ухудшение производительности при отключении BPE до рестарта (сервер не отдаёт оперативку, используемую для BPE)
			5. Ускорение будет не моментально, пока не прочитается база. Можно выполнить сканирование таблицы
			
	-- Delayed Transaction Durability: чем вы готовы пожертвовать ради производительности. Гурьянов Михаил (Москва) (DELAYED_DURABILITY)
		- Under delayed durability, log blocks are only flushed to disk when they reach their maximum size of 60KB
		- Журнал транзакций нужен для обеспечения ACID (атомарность,согласованность,изолированность,устойчивость(живёчесть)). Всё это понижает производительность
		- Server 2014 предлагает
			- Не ожидать физической записи для возврата управления клиенту
			- Может быть выполнена очистка буфера на диск большими частями
			- Позволяет уменьшить число конфликтов и учеличить пропускную способность транзакций
			- Доступна во всех редакция SQL Server 2014. Наибольший эффект если используется OLTP in Memmory
		- Можно на уровне базы, в запросе, хранимых процедур с in memmory OLTP
		-- Минусы
			- Когда приложение должно быть уверено в COMMIT на диск, например банки
			- Даже при обычном рестарта может возникнуть потеря данных, так как данный механизм не видит разницы между крахов и рестартом
				- Можно вызвать принудительный сброс данных sys.sp_flush_log 
			- CHECKPOINT не поможет
		- Когда происходит физическое сохранение
			- Автоматически, по мере заполнения буфуров
			- При фиксировании транзакции с полной устойчивостью
			- При выполнении sys.sp_flush_log для текущей базы
		- Ограничение технологий
			- Failover cluster
			- Transaction Replication
			- Log shipping
			- Log Backup
			- Change data capture
			- Восстановление после сбоя
			- Межбазовые транзакции и DTC
			- Always On availability groups и зеркалирование
		- Где использовать
			- на хранилищах данных
			- Где лог узкое место
			- где не критична устойчивость, если операцию можно сделать повторно
			
		-- На каком уровне используется/Где можно вкл	
			- Уровень БД
			- Уровень транзакции (COMMIT TRANSACTION WITH (DELAYED_DURABILITY = ON);)
			- В процедурах для работы с in-memory (BEGIN ATOMIC WITH (DELAYED_DURABILITY = ON, ...))
			
	-- Полнотекстовый поиск fulltext
		- Улучшился полнотекстовый поиск

-- ***** SQL SERVER 2016 *****
	-- Новшества
		1. Всегда зашифрована (Always Encrypted)
			- Шифруется и дешефруется с помощью драйвера на клиенте
		2. Stretch Database
			- Таблицы БД в Azure. Прозрачно для пользователя
			- Standard Etition
			- https://docs.microsoft.com/en-us/sql/sql-server/stretch-database/stretch-database
			- https://docs.microsoft.com/en-us/sql/sql-server/stretch-database/stretch-database-databases-and-tables-stretch-database-advisor
			- https://docs.microsoft.com/en-us/sql/sql-server/stretch-database/limitations-for-stretch-database
			
			-- Моменты:
				1. Требует хорошего канала между нами и Azure
				2. То что локально backup`им мы, то что в Azure - Azure backup
				3. Но и в целом хорошо когда такие данные, которые уедут в AZure, не часто менялись. Так как они сначала сохранются локально, мигрируются прозрачно в Azure, потом удаляются локально
				4. If you have ever worked with linked servers, you should be aware of potential performance issues with the technology.
				5. Вроде работает с AlwaysON
				
			-- Ограничения
				1. There are quite a few such blocking issues in SQL Server 2016 RTM. For example, a table cannot have DEFAULT and CHECK constraints nor be referenced by foreign keys. The table cannot use XML , text , ntext , image , timestamp , sql_variant , or CLR data types, nor be included in the indexed views.
				2. There are other limitations after stretch is enabled. The most notable is that SQL Server does not enforce UNIQUE and PRIMARY KEY constraints nor allow you to UPDATE and DELETE migrated data.
				3. Be careful, however, if you need to modify remote data in the scope of the active transaction. This operation can take a considerable amount of time, and can even fail if SQL Server cannot access the remote database. It is better to implement data modifications asynchronously using Service Broker or other queue-based technologies. 		
				
		3. Real-time Operational Analytics & In-Memory OLTP
		4. Built-in Advanced Analytics, PolyBase and Mobile BI
		5. Additional security enhancements for Row-level Security and Dynamic Data Masking to round out our security investments with Always Encrypted.
		6. Improvements to AlwaysOn for more robust availability and disaster recovery with multiple synchronous replicas and secondary load balancing.
			- Round-robin load balancing in readable secondaries
			- Increased number of auto-failover targets
			- Enhanced log replication throughput and redo speed
			- Support for group-managed service accounts
			- Support for Distributed Transactions (DTC)
			- Basic HA in Standard edition
			- Direct seeding of new database replicas
		7. Native JSON support to offer better performance and support for your many types of your data.
		8. SQL Server Enterprise Information Management (EIM) tools and Analysis Services get an upgrade in performance, usability and scalability.
		9. Faster hybrid backups, high availability and disaster recovery scenarios to backup and restore your on-premises databases to Azure and place your SQL Server AlwaysOn secondaries in Azure.
		10. Исторические таблицы (temporal tables/log table)
			- Работает быстрее за счёт того, что это на уровне ядра
		11. В SQL Server 2016 появилась ещё одна интересная возможность. Это скрытие данных от конечного пользователя по определенному шаблону (Dynamic Data Masking). Basic security (Row-level security, data masking, basic auditing, separation of duties)
			- Безопасность на уровне строк встроена в ядра
		12. В SQL Server 2016 появилась ещё одна новая интересная функциональность. Это Query Store. Она может помочь вам в устранении неполадок производительности запросов.
			- Не вносит существенных задержек, так как реализовано на уровне ядра
			- Есть встроенные отчёты, которые будут добавляться
			- Есть DMV для Query Store
		13. В продолжении темы об оптимизации следует отметить ещё одну интересную возможность. Это Live Query Statistics. Теперь можно реалтайм смотреть как выполняется запрос.
			- Несёт доп. нагрузку, достаточно затратная
		14. Maximum number of cores 
		15. Tail Of Log Caching ( https://blogs.msdn.microsoft.com/bobsql/2016/11/08/how-it-works-it-just-runs-faster-non-volatile-memory-sql-server-tail-of-log-caching-on-nvdimm/ ). DAX access
			- Прямой доступ к памяти
			- Можно создать диск из обычных дисков и из диска NVDIMM-N на write-cache
				https://docs.microsoft.com/ru-ru/sql/relational-databases/performance/configuring-storage-spaces-with-a-nvdimm-n-write-back-cache
		16. Последние ожидания сессии	
			SELECT * FROM sys.dm_exec_session_wait_stats
		
	-- Улучшения
		1. Soft-NUMA (seldom seen on older hardware, is now the norm for better memory and CPU partitioning. This provides a series of cascading benefits to other internal structures, such as spinlocks, latches, mutexes, and semaphores. Gains of 10% to 30% are not uncommon on certain OLTP workloads.)
		2. Ускоряет DBCC в 7 раз
		3. Multiple log writers (improve multi-threaded processing, and optimize storage reclamation and cleanup.). Количество равно NUMA node, не более 4 (https://blogs.msdn.microsoft.com/psssql/2016/04/19/sql-2016-it-just-runs-faster-multiple-log-writer-workers/)
		4. Улучшение работы tempdb
		5. Better Thread Scheduling enables SQL Server to better schedule worker tasks and balance the workload for higher scalability. This, combined with the Soft NUMA improvements, means that many background SQL Server processes can run within a NUMA-node rather than outside of the NUMA-node.
		6. Automatic TEMPDB Configuration(https://blogs.msdn.microsoft.com/psssql/2016/03/17/sql-2016-it-just-runs-faster-automatic-tempdb-configuration/)
		7. SQL Server 2016 (X64 installations) increase the number of contiguous, 8K pages from 32 to 128 (1MB) when performing (Lazy, checkpoint, select into, create index and bulk insert write operations.)   These write operations encompass 95%+ of the write operations for data file.
		8. AlwaysON - Отказоустойчивость на уровне БД, а не всего экземпляра
		9. AlwaysON до 3 синхронных реплик
		10. AlwaysON - улучшен транспорт передачи данных (LOG)
		11. AlwaysON - балансировка реплик с доступом на чтение
		12. AlwaysON - 2016 можно строить кластеры без домена, аутентификация на сертификатах, sql аутентификации
		13. SP1+ Отдельная стратистика по партициям
		14. SP1 CU+ Возможность указать SAMPLE для каждой отдельной статистики вместо дефолтного, но для этого необходимо обновить статистику с ключём
					ALTER DATABASE current SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = ON ); 
		15. Aggregate pushdown
			- In SQL Server 2016 Microsoft has implemented a possibility to push some of the Aggregations right into the storage level, thus greatly improving performance of this type of analytical queries.
			- thus improving the overall performance of the query through sparing additional work for the CPU.
			- Выполнение агрегации в момент скана.
			- Тип данных менее 8 байт
			- Работает с MIN,MAX,SUM,COUNT,AVG
		16. String predicate pushdown
		17. SQL Server 2016 DBCC CHECKDB with MAXDOP
			
		
-- ***** SQL SERVER 2017 *****
	-- Новшества
		1. SQL Server for Linux
		2. advanced analytics using Python in a parallelized and highly scalable way
		3. the ability to store and analyze graph data
			- Встроено в SQL Server
		4. adaptive query processing
			-- Чтобы включить нужно перейти на 140 уровень совместимости
			-- Начинает работать только со следующего запуска
			-- Требует Enterprise
			
			- http://www.queryprocessor.ru/adaptive-query-processing/
			- https://docs.microsoft.com/ru-ru/sql/relational-databases/performance/adaptive-query-processing
			
			-- batch mode adaptive join
				Может поменять с nesred loop на hash join
			-- batch mode memory grant feedback	
				Recalculates the actual memory required for a query and then updates the grant value for the cached plan				
		5. resumable online indexing
		6. автоматическая подмена планов, если он был перестроен и запрос стал выполняться плохо. Работает на осное Query Store
			- https://docs.microsoft.com/en-us/sql/relational-databases/automatic-tuning/automatic-tuning
			
		7. Indirect Checkpoint Scalability
		8. Improve Scan and Read Ahead Algorithms
		9. Go after Hot spinlocks
		10. CHECKDB Read Ahead Optimization
		11. Query Store Cloud Learning
		12. AlwaysOn без кластера
			