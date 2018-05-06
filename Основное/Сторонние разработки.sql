-- Performance Dashboard Reports
	- Создаётся в таблице msdb
	- Статья на Books Online - KB 822101
	- Отображает только текущее состояние сервера
	- Искать в программах\SQLServer2012_PerformanceDashboard

	-- Установка
	1. Качаем Microsoft SQL Server 2005 Performance Dashboard Reports
	2. Устанавливаем
	3. В установленнай папке берём скрипт и прогоняем по базе
	4. Custom Reports > в установленной папке выбираем отчёт

	-- Удаление
	- Установка/удаление программ

	Cache Hit Ratio - отношение логических чтений к физическим

	DTA (DataBase Tuning Advizor)
	Quest SpotLite

	-- Рекомендации
	1. Использовать версию SSMS Больше или = версии SQL Server

	-- Блок по данной технологии
	http://blogs.msdn.com/b/psssql/
	
-- Best practice analiser
	http://www.microsoft.com/en-us/download/details.aspx?id=16475
	http://www.microsoft.com/en-us/download/details.aspx?id=29302
	- После установки скопировать из C:\Windows\System32\BestPractices\v1.0\Models в C:\ProgramData\Microsoft\Microsoft Baseline Configuration Analyzer 2\Models папку SQL2012BPA
	- Должны быть права sysadm на проверяемом инстансе. Права через группу не прокинутся

-- Pal (Perfomance Analysis of Logs)
- pal.codexplex.com

-- SQL backup status reporter
- http://www.idera.com/Free-Tools/SQL-backup-status-reporter/

-- SQL safe backup
- http://www.idera.com/SQL-Server/SQL-safe-backup/?s=TAB_SQLstatus_SQLsafe&utm_source=SQLstatus&utm_medium=InProduct&utm_campaign=SQLsafe&utm_content=TAB

-- Stream insight
- Обработка большого потока пакетов
- Не требует SQL Server
- Разрабатывается на VS 2008 или VS 2010
- Прежде чем можно обрабатывать данные, их надо куда-то загрузить
- CEP (системы обработки потоков событий). Streaim Inside это одна из CEP
- Отличия от обычной обработки данных, от СУБД (в скобках указано как в обычной СУБД):
	1. Запросы обрабатываются непрерывно (Запросы выполняются по требованию)
	2. Задержки милисекунды или меньше (секунды, часы, дни)
	3. Десятки/сотни тысяч записей в секунду (сотни записей в секунду)
	4. Реляционная и временная аналитика (декларативная реляционная аналитика)
- Область применения практически не ограничена
- Не зависима от движка БД, это расширение Sql Server
- События:
	1. Мгновенные (не имеют длительность)
	2. Длительность известная
	3. Длительность неизвестна
- Типы данных событий
	1. Заполняет временные события, мы заполняем все остальные поля
- Потоки событий (возможно бесконечная последовательность событий)
	1. Можно вставлять события или изменять в поток
	2. Может быть неупорядоченными
	3. Может быть случайными
	4. Может быть равномерными
- Адаптеры. Класс, которые пишет разработчик для Streaminsight, который определяет как данные понятные
  устройству превращаются в данные понятные системе Streaminsight
- Можно группировать и агрегировать запросы, можно отслеживать корреляции, можно использовать
  внешние источники, чтобы понять как обрабатывать приходящие данные
- Можно расширять с помощью языка C#

-- Централизованное управление серверами (SQL Server Utility Point) (UCP)
- Отдельный сервер
- Основная задача - простота настройки и использования
- Что можно измерять:
	1. Утилизация процессора
	2. Утилизация диска
- Можно определять на разных уровнях
- Установка: 
	1. SSMS>View>Utility Explorer
	2. Добавить контрольную точку
- На каждом сервере, который подключается к нему, выполняются Job`s, которые собирают данные и передают
  их на сервер UCP. Собираем каждые 15 секунд, а раз в 15 минут, мы агрегируем всю информацию о PC и
  передаём на UCP. На сервере UCP рассчитывается нормальное ли состояние сервера или нет
- Требуемые права - sysadmin
- Ограничения:
	1. Enterprise поддерживает 25 серверов
	2. Datacenter Edition - не имеет ограничения (до 200-х серверов работает стабильно)
	3. Сервера, которые можно добавлять любая кроме Express
	4. Возможно дублирование данных, если экземпляры серверов находятся на одном компьютере
- Требования для сервера UCP
	1. 2 Гб в год на каждый управляемый сервер
	2. Скорость дисков 8-10k RPM RAID 10
	3. Процессор 4x 2.5 Intel Xeon или эквивалент
- Требования для управляемых серверов минимальны
- Технический обзор: http://www.microsoft.com/sqlserver/2008/en/us/R2-multi-server.aspx
- Books Online http://msdn.microsoft.com/en-us/library/ee210557(SQL.105).aspx 
- Reports http://blogs.msdn.com/hutch/archive/2010/02/21/sql-server-2008-r2-accessing-utility-control-point-data.aspx

-- DACs (Data-tier Application/Data-tier Application Component)
- Аналог DB project
- Для маленьких приложений
- Ограничения (см. в презентации)
- Берём базу, экспортируем его в DAC (Состоит из Структуры базы). Далее в VS создаём проект
 'SQL Server Data-tier Application'. Импортируем в приложение dacpakt-файл. После редактирования можно
 экспортировать из VS и импортировать в SQL Server
- При развёртывании на SQL создаётся копия текущей БД, далее копируем данные, поэтому нужно
  достаточное место. Переименовываем оригинальную базу, а старая остаётся с названием старой версии
- Что вообще можно делать:
	1. Ограниченная поддержка объектов
	2. Не поддерживает ALTER 
	3. Можно использовать и в Azure
	4. Не поддерживается SQL 2005
- Технический обзор: http://go.microsoft.com/fwlink/?LinkID=183214
- Books online: http://msdn.microsoft.com/en-us/library/ee240739(SQL.105).aspx

-- Удалённое хранение данных
	1. Яндекс Диск
	2. DropBox

-- Management Data Warehouse/Data Collection
- Collation у базы и сервера должны быть одинаковы
- Создаются Job`s
1. Ensure that SQL Server Agent is running.
2. In Object Explorer, expand the Management node.
3. Right-click Data Collection, and then click Configure Management Data Warehouse.
4. Жмём первую галочку и выбираем базу, в которую будет всё писаться
5. Заходим опять в Data Collection и теперь жмём вторую галочку, где выбираем какой Data Collection вкл
6. Заходим в Data Collection, пкм > Reports > Management Data Warehouse

- Удаление
	- Если SQL 2012 - [msdb].dbo].[sp_syscollector_cleanup_collector]
	- Если версия ниже
	/*USE MSDB
	GO
	-- Disable constraints
	ALTER TABLE dbo.syscollector_collection_sets_internal NOCHECK CONSTRAINT FK_syscollector_collection_sets_collection_sysjobs
	ALTER TABLE dbo.syscollector_collection_sets_internal NOCHECK CONSTRAINT FK_syscollector_collection_sets_upload_sysjobs

	-- Delete data collector jobs
	DECLARE @job_id uniqueidentifier
	DECLARE datacollector_jobs_cursor CURSOR LOCAL 
	FOR
		SELECT collection_job_id AS job_id FROM syscollector_collection_sets
		WHERE collection_job_id IS NOT NULL
		UNION
		SELECT upload_job_id AS job_id FROM syscollector_collection_sets
		WHERE upload_job_id IS NOT NULL

	OPEN datacollector_jobs_cursor
	FETCH NEXT FROM datacollector_jobs_cursor INTO @job_id
	  
	WHILE (@@fetch_status = 0)
	BEGIN
		IF EXISTS ( SELECT COUNT(job_id) FROM sysjobs WHERE job_id = @job_id )
		BEGIN
			DECLARE @job_name sysname
			SELECT @job_name = name from sysjobs WHERE job_id = @job_id
			PRINT 'Removing job '+ @job_name
			EXEC dbo.sp_delete_job @job_id=@job_id, @delete_unused_schedule=0
		END
		FETCH NEXT FROM datacollector_jobs_cursor INTO @job_id
	END
		
	CLOSE datacollector_jobs_cursor
	DEALLOCATE datacollector_jobs_cursor

	-- Enable Constraints back
	ALTER TABLE dbo.syscollector_collection_sets_internal CHECK CONSTRAINT FK_syscollector_collection_sets_collection_sysjobs
	ALTER TABLE dbo.syscollector_collection_sets_internal CHECK CONSTRAINT FK_syscollector_collection_sets_upload_sysjobs

	-- Disable trigger on syscollector_collection_sets_internal
	EXEC('DISABLE TRIGGER syscollector_collection_set_is_running_update_trigger ON syscollector_collection_sets_internal')

	-- Set collection sets as not running state
	UPDATE syscollector_collection_sets_internal
	SET is_running = 0

	-- Update collect and upload jobs as null
	UPDATE syscollector_collection_sets_internal
	SET collection_job_id = NULL, upload_job_id = NULL

	-- Enable back trigger on syscollector_collection_sets_internal
	EXEC('ENABLE TRIGGER syscollector_collection_set_is_running_update_trigger ON syscollector_collection_sets_internal')

	-- re-set collector config store
	UPDATE syscollector_config_store_internal
	SET parameter_value = 0
	WHERE parameter_name IN ('CollectorEnabled')

	UPDATE syscollector_config_store_internal
	SET parameter_value = NULL
	WHERE parameter_name IN ( 'MDWDatabase', 'MDWInstance' )

	-- Delete collection set logs
	DELETE FROM syscollector_execution_log_internal
	GO*/

-- SQLIO
	- Для тестирования дисковой подсистемы, когда мы хотим протестировать возможность передачи какого-то объёма данных или вообще количество каких-то IO
		
-- SQLIOSim
	- Утилита SQLIOSim выпущена взамен SQLIOStress. Она используется для тестирования характерной SQL Server нагрузки ввода-вывода, и не требует для этого установки самого SQL Server.

-- DiskPar.exe
	Утилита diskpar предназначена для предотвращения проблем в работе сервера, связанных с выравниванием и нарушением границ сектора. Во время работы подсистем SQL Server выравнивание по границам сектора должно быть правильным, иначе не получить оптимальной производительности. Производители подсистем ввода-вывода должны следовать имеющимся рекомендациям, которые необходимо выполнять для обеспечения правильного, с точки зрения SQL Server, выравнивания по границам сектора. Эти же рекомендации применимы и к Microsoft Exchange Server. То, что написано ниже, взято из документации по Microsoft Exchange Server и всё это применимо к SQL Server.
	Не смотря на то, что некоторое хранилища выдают неправильную информацию о размере сектора и трека, использование утилиты diskpar помогает предотвращать нарушение границ в кэше. Если мы имеем дело с подобным диском, то каждое энное (обычно 8-ое) чтение или запись будет выходить за границу, и диск должен будет выполнить две физические операции.
	Вначале любого диска есть раздел, который зарезервирован для мастер-блока начальной загрузки (MBR) и который занимает 63 сектора. Это означает, что если наш пользовательский раздел начинается с 64-го сектора, он может пострадать от нарушения границ раздела. Большинство производителей использует начальное смещение по 64-й сектор.
	Стоит заглянуть в предлагаемую производителем спецификацию, чтобы убедиться в стандартности этой установки для выбранного Вами дискового массива.

-- sys of sandra (driveragent-492)
	Подробная статистика о системе, похоже на AIDA

-- Idera SQL check (Idera)
	- текущее состояние системы SQL
	
-- SQL admin toolset (Idera)
	- Обслуживание системы 

-- SQL backup status reporter (Idera)
	- Статистика/создание/восстановление backup

-- SQL Monitor от Red Gate
	1. Открыть порты 135,445,1433 на добавляемом сервере
	2. В настройках сети включить "Служба доступа к файлам и принтерам сетей Microsoft"

-- SQL Prompt от Red Gate
	- Помогает писать код (подсказки)

-- dbForge SQL Complete (devart)
	- Помогает писать код (подсказки, форматирование текста)

-- SQL Search от Rad Gate
	- Помогает искать данные в таблицах

-- IOMeter
	- Сэмулировать нагрузку на сеть

-- ApexSQL Audit
	- Отслеживание кто и что менять в базе
	
-- ApexSQL Complete
	- Помогает набирать код
	
-- Контроль версий
	- ApexSQL Version
	
-- Ignite PI
	Отличный мониторинг
	
-- CloudBerry Backup
	- Backup на облака

-- SteelEye DataKeeper Cloud Edition
	- Кластеризация в облаке Amazon. Нет необходимости самому строить сети SAN
	
-- Netbackup
	- Централизованный механизм для backup
	- Нужно установить сервера, добавить девайсы и создать политику
	- На клиентах то же необходимо устанавливать ПО
	-- Типы мест хранения
		-- Media Manager 
			- Types, Robots, Optical Device
		-- Disk Storage
			- Hard Drive
		-- NDMP
		-- Disk Staging
			- Hard Drive >> с тем условием, что мы можем указать в какой момент он работает, а в какой нет
	-- Storage Unit
		- Путь для хранения backup на девайсах
	
	-- Процесс снятия backup
		1. Создаётся batch скрипт, который интерпретируется агентом SQL Server
		
	-- Процесс восстановления
		1. Проверяется наиболее свежий backup
		2. Генерируется скрипт восстановления
		
	-- dbbackex
		- Управление с помощью консольного режима
		
-- sql load generator
	- Для нагрузочного тестироания
	
-- ClearTrace
	- Для удобного просмотра снятой трассы Profiler
	- Не надо устанавливать
	- Лёгок в освоении
	
-- ReadTrace (RML)
	- Для удобного просмотра снятой трассы Profiler
	- В него входит Ostress и другие доп. программы
	- Даёт больше информации чем ClearTrace, позволяем сравнивать 2 трассы, даёт графическое отображение результата
	
-- TableDiff
	- Программа для сравнивания таблиц в репликации
	- Работает только с SQL Server
	- Утилита для идентификации записей требует наличия на таблицах первичных ключей, или полей со свойством identity, rowguid или уникальных ключей, соответственно при их отсутствии вы получите сообщение об ошибке
	
-- Удобрый просмотр трассы (Profiler)
	E:\SQL Scripts\Скрипты\sp_blocked_process_report_viewer.sql
	sp_blocked_process_report_viewer @Trace =  'TraceFileOrTable'  
	
-- Разбор системной инфомрации файлов
	- Заголовков страниц и тд
	- Может помочь при сбоях
	- https://github.com/improvedk/orcamdf
	- http://improve.dk/category/SQL%20Server%20-%20OrcaMDF/
	
-- SqlQueryStress
	- Нагрузочное тестирование с вашим кодом
	
-- tSqlt 
	модульное тестирование в Sql Server
	https://habrahabr.ru/post/234673/