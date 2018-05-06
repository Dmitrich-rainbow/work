-- Первоисточник с более детальной информацией
	https://msdn.microsoft.com/ru-ru/library/ms179886(v=sql.120).aspx

-- COLLATION (способ сортивки и сравнения данных в таблицах)
	- SELECT * FROM fn_helpcollations();
	- Влияет на сортировку, LIKE
	- Немного различаются по скорости работы
	- Возникают проболемы когда идут сравнивания строк
	- Возникают проблемы когда идёт неявное преобразование типов

-- Какой бывает
	1. Уровня сервера
	2. Уровня базы
	3. Уровня столбца
	
-- Сменить Collation
	1. Через свойства базы данных, выставив базу в SINGLE_USER
	2.  ALTER DATABASE имя_БД SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		ALTER DATABASE имя_БД COLLATE нужная_кодировка 
		ALTER DATABASE имя_БД SET MULTI_USER

-- Описание COLLATE
select * from fn_helpcollations()
where name = 'SQL_Latin1_General_CP1_CI_AS'
or name = 'SQL_Latin1_General_CP1_CS_AS'

-- Проблемы
	1. Не декодируется русский
		- используем CAST(test as nvarchar(255)) -- Unicode
		- Изменить настройки драйвера (Remote Collation)
		
-- Особенности
	1. Предложение COLLATE можно применять только к типам данных char, varchar, text, nchar, nvarchar и ntext.
	2. Операторы сравнения и операторы MAX, MIN, BETWEEN, LIKE, IN выполняются с учетом параметров сортировки.
	3. Оператор UNION выполняется с учетом параметров сортировки 
	4. При выполнении операции конкатенации строк учитываются заданные параметры сортировки.
	5. Операторы UNION ALL и CASE выполняются без учета параметров сортировки
	6. Функции CAST, CONVERT и COLLATE учитывают параметры сортировки при работе с данными типа char, varchar и text
	7. BUT… if you go from case sensitive to case insensitive… be careful
	8. Если сортировка у tempdb и вашей отличается, то могут быть проблемы при comparisons/lookups/joins
	
-- Автономная БД/containment DB
	Меняет COLLATION tempdb на COLLATION user DB
	
-- Изменение COLLATION
	- https://msdn.microsoft.com/ru-ru/library/dd207003(v=sql.120).aspx
	- Вы не можете изменить COLLATION БД model, на основе которого стоится tempdb при restart
	- При этом имеется ряд ограничений – нельзя изменить схемы для вычисляемых полей, индексированных полей, полей с ограничением CHECK или внешних ключей. Необходимо вначале удалить их, а после изменения схемы сопоставления заново создать. Так что работа здесь может быть проделана большая и серьезная.
	1. Поменять на БД
		alter database OLD_BASE collate Cyrillic_General_CI_AS
	2. Поменять на всех колонках
		alter table Report alter column char_key char(5) collate Cyrillic_General_CI_AS
	3. Можно создать View, который преобразует COLLATION из разных источников к одному
		create view View1 as select Col3, Col4 collate French_CI_AS as Col4 from 
	4. Можно указывать принудительный COLLATION когда создаём таблицу в tempdb
	5. Можно взять БД model из другого экземпляра с такой же версией и с нужным COLLATION и восстановить на нужный.
	
	-- You cannot change the collation of a column that is currently referenced by any one of the following:
		- A computed column
		- An index
		- Distribution statistics, either generated automatically or by the CREATE STATISTICS statement
		- A CHECK constraint
		- A FOREIGN KEY constraint
				
	-- Изменение параметров сортировки сервера	путём REBUILD (проверил лично, работает)			
			-- Перед началом работ
				1. Зафиксировать SELECT * FROM sys.configurations;
				2. Зафиксировать текущие обновления
					SELECT
					SERVERPROPERTY('ProductVersion ') AS ProductVersion,
					SERVERPROPERTY('ProductLevel') AS ProductLevel,
					SERVERPROPERTY('ResourceVersion') AS ResourceVersion,
					SERVERPROPERTY('ResourceLastUpdateDateTime') AS ResourceLastUpdateDateTime,
					SERVERPROPERTY('Collation') AS Collation;
				3. Зарегистрируйте текущее расположение всех файлов данных и журналов для системных баз данных.При перестроении системных баз данных они устанавливаются в исходное расположение.Если системные файлы данных и журналов были перемещены в другие расположения, необходимо вернуть их в исходное место.
				
			-- Сами работ
				1. Проверьте наличие данных и скриптов, необходимых для повторного создания пользовательской базы данных и всех ее объектов.
				2. Экспортируйте все данные с помощью такого средства, как Программа bcp.Дополнительные сведения см. в разделе Массовый импорт и экспорт данных (SQL Server).
				3. Перестройка обнулит master,msdb...
				4. Удалите все пользовательские базы данных.
				5. Перестройте базу данных master, задав новые параметры сортировки в свойстве SQLCOLLATION команды setup (БД будут удалены и созданы заного). Например:
					Setup /QUIET /ACTION=REBUILDDATABASE /INSTANCENAME=InstanceName /SQLSYSADMINACCOUNTS=accounts /[SAPWD= StrongPassword] /SQLCOLLATION=CollationName
				
			-- После работ
				1. Восстановить последнюю резервную копию системных БД. При этом восстановится и COLLATION, но COLLATION tempdb останется прежним
				2. Перезагрузитесь, так как после этого SQL Server может не запускаться и ничего не писать в лог
				2. Применить обновления установленные ранее -- В моих тестов это не требуется
					setup > Maintenance > Repair > Select instance > Repair
				3. Переместить системные БД в нужное место
		
		- Дополнительные сведения см. в разделе Перестроение системных баз данных (https://msdn.microsoft.com/ru-ru/library/dd207003(v=sql.120).aspx).
		- Создайте все базы данных и все их объекты.
		- Импортируйте все данные.
	
		-- Второй способ (наверняка плохой, так как данные уже хранятся в каком-то виде)
			- изменится COLLATION системных БД
			sqlservr -m -T4022 -T3659 -s"SQLEXP2014" -q"SQL_Latin1_General_CP1_CI_AI" 
	
-- Найти преобразование типов в памяти/implicit conversion
	
	-- Мой (преобразования типов с ошибкой)
	
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		SELECT TOP 50 SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
			((CASE qs.statement_end_offset
			WHEN -1 THEN DATALENGTH(qt.TEXT)
			ELSE qs.statement_end_offset
			END - qs.statement_start_offset)/2)+1),
			qs.execution_count,
			qs.total_elapsed_time/1000 total_elapsed_time_ms,
			qs.last_elapsed_time/1000 last_elapsed_time_ms,
			qs.max_elapsed_time/1000 max_elapsed_time_ms,
			qs.min_elapsed_time/1000 min_elapsed_time_ms,
			qs.max_worker_time/1000 max_worker_time_ms,
			qs.min_worker_time/1000 min_worker_time_ms,
			qs.last_worker_time/1000 last_worker_time_ms,
			qs.total_worker_time/1000 total_worker_time_ms,
			qs.total_logical_reads, qs.last_logical_reads,
			qs.total_logical_writes, qs.last_logical_writes,
			qs.last_execution_time,
			CAST(qp.query_plan as XML),
			--CAST(qp.query_plan as XML).value('(.//ScalarOperator/@ScalarString)[3]', 'varchar(8000)') ,
			qt.[objectid] -- по данному id можно вычислить что за объект SELECT name FROM sys.objects WHERE [object_id] = 238623893
			,qp.dbid
			,qt.dbid
		FROM sys.dm_exec_query_stats qs
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
		CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
		WHERE last_execution_time > GETDATE()-1
		AND qp.query_plan.value('(.//@Expression)[1]', 'varchar(8000)') like '%CONVERT_IMPLICIT%'		
		--ORDER BY (qs.total_logical_reads + qs.total_logical_writes) / qs.execution_count  DESC-- по-умолчанию
		-- ORDER BY qs.total_logical_writes DESC -- logical writes
		--AND CAST(qp.query_plan as varchar(8000)) like '%Convert_impli%'
		ORDER BY qs.total_worker_time DESC -- CPU time
	
	-- Мой (все возможные преобразования типов)
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		SELECT TOP 30 SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
			((CASE qs.statement_end_offset
			WHEN -1 THEN DATALENGTH(qt.TEXT)
			ELSE qs.statement_end_offset
			END - qs.statement_start_offset)/2)+1),
			qs.execution_count,
			qs.total_elapsed_time/1000 total_elapsed_time_ms,
			qs.last_elapsed_time/1000 last_elapsed_time_ms,
			qs.max_elapsed_time/1000 max_elapsed_time_ms,
			qs.min_elapsed_time/1000 min_elapsed_time_ms,
			qs.max_worker_time/1000 max_worker_time_ms,
			qs.min_worker_time/1000 min_worker_time_ms,
			qs.last_worker_time/1000 last_worker_time_ms,
			qs.total_worker_time/1000 total_worker_time_ms,
			qs.total_logical_reads, qs.last_logical_reads,
			qs.total_logical_writes, qs.last_logical_writes,
			qs.total_elapsed_time/1000000 total_elapsed_time_in_S,
			qs.last_elapsed_time/1000000 last_elapsed_time_in_S,
			qs.last_execution_time,
			CAST(qp.query_plan as XML),
			--CAST(qp.query_plan as XML).value('(.//ScalarOperator/@ScalarString)[3]', 'varchar(8000)') ,
			qt.[objectid] -- по данному id можно вычислить что за объект SELECT name FROM sys.objects WHERE [object_id] = 238623893
		FROM sys.dm_exec_query_stats qs
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
		CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
		WHERE last_execution_time > GETDATE()-1
		AND qp.query_plan.value('(.//@ScalarString)[2]', 'varchar(8000)') like '%CONVERT_IMPLICIT%'
		--ORDER BY (qs.total_logical_reads + qs.total_logical_writes) / qs.execution_count -- по-умолчанию
		-- ORDER BY qs.total_logical_writes DESC -- logical writes
		--AND CAST(qp.query_plan as varchar(8000)) like '%Convert_impli%'
		ORDER BY qs.total_worker_time DESC -- CPU time
		
		
	
	-- Старый	
	-- Обязательно сменить контекст БД на нужный

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @dbname SYSNAME 
	SET @dbname = QUOTENAME(DB_NAME());

	WITH XMLNAMESPACES 
	   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan') 
	SELECT 
	   stmt.value('(@StatementText)[1]', 'varchar(max)'), 
	   t.value('(ScalarOperator/Identifier/ColumnReference/@Schema)[1]', 'varchar(128)'), 
	   t.value('(ScalarOperator/Identifier/ColumnReference/@Table)[1]', 'varchar(128)'), 
	   t.value('(ScalarOperator/Identifier/ColumnReference/@Column)[1]', 'varchar(128)'), 
	   ic.DATA_TYPE AS ConvertFrom, 
	   ic.CHARACTER_MAXIMUM_LENGTH AS ConvertFromLength, 
	   t.value('(@DataType)[1]', 'varchar(128)') AS ConvertTo, 
	   t.value('(@Length)[1]', 'int') AS ConvertToLength, 
	   query_plan 
	FROM sys.dm_exec_cached_plans AS cp 
	CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
	CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS batch(stmt) 
	CROSS APPLY stmt.nodes('.//Convert[@Implicit="1"]') AS n(t) 
	JOIN INFORMATION_SCHEMA.COLUMNS AS ic 
	   ON QUOTENAME(ic.TABLE_SCHEMA) = t.value('(ScalarOperator/Identifier/ColumnReference/@Schema)[1]', 'varchar(128)') 
	   AND QUOTENAME(ic.TABLE_NAME) = t.value('(ScalarOperator/Identifier/ColumnReference/@Table)[1]', 'varchar(128)') 
	   AND ic.COLUMN_NAME = t.value('(ScalarOperator/Identifier/ColumnReference/@Column)[1]', 'varchar(128)') 
	WHERE t.exist('ScalarOperator/Identifier/ColumnReference[@Database=sql:variable("@dbname")][@Schema!="[sys]"]') = 1

		
-- Пример
WHERE tt1.inc = tt2.Partner AND tt3.Dog = tt2.NDog COLLATE SQL_Latin1_General_CP1251_CI_AS

SELECT * FROM T1 AS t1 INNER JOIN T2 AS t2
ON t1.Name=t2.Name COLLATE [collation_name];
--
SELECT name COLLATE SQL_Latin1_General_CP1_CI_AS FROM testTable
--
SELECT * FROM T1
WHERE Name='sqlCMD' COLLATE [collation_name1] AND EmailAddress='SqLcMd' COLLATE [collation_name2]
--
SELECT * FROM T1
WHERE (Name COLLATE [collation_name1])='sqlCMD' AND EmailAddress='SqLcMd' COLLATE [collation_name2]
--
SELECT * FROM T1
WHERE Name COLLATE [collation_name1]='sqlCMD' COLLATE [collation_name2] AND EmailAddress='SqLcMd' COLLATE [collation_name3]
--
SELECT * FROM T1
ORDER BY Name COLLATE [collation_name]
--
SELECT * FROM T1
ORDER BY Name COLLATE [collation_name1], EmailAddress COLLATE [collation_name2]

-- UNICODE
	-- UTF
		- https://msdn.microsoft.com/ru-ru/library/bb330962.aspx
		- https://msdn.microsoft.com/ru-ru/library/ms143726.aspx?f=255&MSPPError=-2147217396
		- UTF-16 принята в качестве стандартной кодировки в корпорации Майкрософт, SQL Server не является исключением
		- Если приложению требуются данные в другой кодировке, оно само должно выполнить необходимые преобразования (например в UTF-8)
		- Чтобы занести данные в UTF, необходимо передавать их с N'', так же чтобы получить не англ названия из UTF, надо запрашивать c N''

	-- UCS-2.
		- Как правило, SQL Server хранит символы Юникода с помощью схемы кодирования UCS-2 (https://msdn.microsoft.com/ru-ru/library/bb330962.aspx)
	
	-- В Html
		- XML-данные SQL Server 2005 кодирует с помощью Юникода (UTF-16).
		- Можно попробовать <?xml version="1.0" encoding="utf-8"?>
		
	-- UTF-8
		Однако в среде Windows хранение в формате UTF-8 имеет несколько недостатков:
			- Интерфейсы модели COM, включая API, поддерживают только кодировку UTF-16/UCS-2. Следовательно, если данные хранятся в формате UTF-8, требуется их постоянное преобразование. Эта проблема имеет место, только когда используется модель COM, но обычно ядро базы данных SQL Server к ее интерфейсам не обращается.
			- Ядро операционной системы как в Windows XP, так и в Windows Server 2003 используют Юникод. Для Windows 2000, Windows XP и Windows Server 2003 в качестве стандартной кодировки используется UTF-16. Однако эти операционные системы распознают и UTF-8. Поэтому использование в качестве формата хранения данных кодировки UTF-8 требует множества лишних преобразований. Обычно лишние затраты ресурсов, необходимые для таких преобразований, не влияют на работу ядра базы данных SQL Server, но могут оказать влияние на многие операции, выполняемые на стороне клиента.
			- Использование UTF-8 может приводить к замедлению многих операций со строками. Сортировка, сравнение и, фактически, любые другие операции со строкам могут работать медленнее из-за того, что символы не имеют фиксированной ширины.
			- Часто для кодировки UTF-8 требуется более 2 байтов, а увеличение размера может вести к увеличению используемого дискового пространства и памяти.
	
-- Узнать COLLATE базы
SELECT DATABASEPROPERTYEX('ADMIN_SITE' , 'collation')