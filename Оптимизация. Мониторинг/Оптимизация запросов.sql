-- Вредные советы (см. в папке Доклады>Вредные советы.sql)


-- Основное
	https://sqlperformance.com/author/paulwhitenzgmail-com
	- querytraceon требует админских прав, вместо этого можно использовтаь use hint (SELECT * FROM sys.dm_exec_valid_use_hints) -- Начиная с 2016	
	- http://rusanu.com/2013/08/01/understanding-how-sql-server-executes-a-query/
	- Добавить к запросу. Не забыть включить View > Output, чтобы увидеть всю информацию
		option(recompile, merge join
			,QUERYTRACEON 176  -- to prevent expansion of persisted computed columns (SQL Server 2016). It is a little unfortunate that it disables general expression matching as a side effect. It is also a shame that the computed column has to be persisted when indexed. There is then the risk of using a trace flag for other than its documented purpose to consider.
			,QUERYTRACEON 1504 -- Function: Dynamic memory grant expansion can also help with parallel index build plans where the distribution of rows across threads is uneven. The amount of memory that can be consumed this way is not unlimited, however. SQL Server checks each time an expansion is needed to see if the request is reasonable given the resources available at that time. Some insight to this process can be obtained by enabling undocumented trace flag 1504, together with 3604 (for message output to the console) or 3605 (output to the SQL Server error log). If the index build plan is parallel, only 3605 is effective because parallel workers cannot send trace messages cross-thread to the console.
			,QUERYTRACEON 2372 -- summury
			,querytraceon 2372 -- Memory for Phases
			,QUERYTRACEON 2861 -- enables forced caching of trivial plans
			,QUERYTRACEON 7352 -- final output memo tree
			,QUERYTRACEON 7357 -- unique hash optimization used
			,QUERYTRACEON 8795 -- отключить Sort?
			,QUERYTRACEON 8605 -- Показать дерево выполнения/parse tree/converted tree
			,QUERYTRACEON 8607 -- output memo tree
			,QUERYTRACEON 8609 -- task abd operation type counts
			,QUERYTRACEON 8615 -- final memor / покажет физическую стоимость операторов
			,querytraceon 8619 -- Show Applied Transformation Rules
			,QUERYTRACEON 8621 -- Показать какие правила оптимизацтора были применены
			,QUERYTRACEON 8649 -- Принудить использовать паралллельный план
			,QUERYTRACEON 8744  -- отключение prefetch
			,querytraceon 8671 -- disables the logic that prunes the memo and prevents the optimization process from stopping due to “Good Enough Plan found”. Can significantly increase the amount of time, CPU, and memory used in the compilation process
			бquerytraceon 8675 -- shows the query optimization phases for a specific optimization along with some other information like cost estimation, tasks, etc. You may want to test it with complex queries to see different optimization phases / покажет физическую стоимость операторов
			,QUERYTRACEON 8739 -- show group optimizer info and results
			,QUERYTRACEON 8757 -- отключить тривиальный план
			,querytraceon 8780 -- Он позволяет «отключить» Timeout. (позволяет делать полную оптимизацию, искать план запроса дольше), но даже с таким флагом максимальное количество преобразований 3 072 000 
			,querytraceon 8612 -- Add Extra Info to the Trees Output
			,QUERYTRACEON 9292 -- stats considered interesting by the optimizer when compiling or recompiling
			,QUERYTRACEON 9204 -- stats fully loaded
			
			-- Оптимзация			
			,querytraceon 8666 -- Добавит в план информация о статистике
			,querytraceon 2363 -- (2014, new:) TF Selectivity
			,QUERYTRACEON 4137 -- Minimum Selectivity for AND operator. С уровня совместимости 120 надо нужно использовать 9471 
			,QUERYTRACEON 8606 -- Показать дерево выполнения/parse tree (более подробно). Можно объединить с 8605	
			,querytraceon 3604 -- Output to Console		
			,querytraceon 2373 -- Memory for Deriving Properties. Он выводит информацию о состоянии памяти после каждого возможного преобразования, на разных стадиях оптимизации, но косвенно, может быть нам полезен, для просмотра того, что происходит
			,querytraceon 9292 -- show the statistics objects the optimizer is considering for the optimization process (до 2014)
			,querytraceon 9204 -- show the statistics objects used to procedure a cardinality estimated loaded during the optimization process (до 2014)
			);
			
		TF9130 -- will show the pushed predicate in the query plan		

		
	- Использование статистики не отображается в плане, только индекс, если не используется 9292
	
	-- DMV
		SELECT * FROM sys.dm_exec_query_optimizer_info --- ???
		SELECT * FROM sys.dm_xe_map_values WHERE name = 'query_optimizer_tree_id'
		SELECT * FROM sys.dm_exec_query_transformation_stats -- как много и каких операторов применялось
			
-- SET
	- SET SHOWPLAN_TEXT ON -- Приводит к тому, что Microsoft SQL Server не выполняет инструкции языка Transact-SQL. Вместо этого SQL Server возвращает подробные сведения о ходе выполнения инструкций.
	- SET STATISTICS PROFILE или SET STATISTICS XML в тексте запроса
	
-- Выбор оператора соединения
	https://sqlperformance.com/2012/12/t-sql-queries/left-anti-semi-join

-- Изменить поведение оптимизатора
	-- Заставить оптимизатор использовать оценку кардинальности 2012 и ниже 
		option(querytraceon 9481)
-- Советы
	- Пишут под конкретные задачи, универсального не бывает, всегда есть баланс
	- Думайте наборами
	- Не забывайте о NULL (SQL для администраторов 2013 № 7)
	- Избегайте NOLOCK (SQL для администраторов 2013 № 7)
	- Завершайте конструкцию - ;
	- Избегайте выборки через *
	- Стараться производить все вычисления не в таблице
	- Используйте аргументы поиска.
		- Использование индекса для запроса сильно зависит от предиката в фильтре запроса.
		- Нужно стараться избегать манипуляции с ключевыми столбцами поиска. (математические формулы, замена)
	- Проверка на существование объекта
		IF (SELECT OBJECT_ID('tempdb..#FramentedTableList')) IS NOT NULL 
			DROP TABLE #FramentedTableList; 
	- Проверка на блокировки
		if not exists (select object_name(resource_associated_entity_id)as TabName  from sys.dm_tran_locks  
		 inner join sys.objects on resource_associated_entity_id=object_id
		 where resource_database_id=@dbid and resource_type = 'object' and name =@table)
	- Можно подсказать оптимизатору порядок выполнения скобками 
	- Не создавать процедуры с префиксом sp_, xp_... (системные), так как это вопрос производительности и сопоставления (http://sqlcom.ru/dba-tools/stored-procedures-and-performance/)
	- Омтимизатора скорее возьмёт условие в WHERE чем в ON
	- Использование операции TOP заставляет оптимизатор форсировать использование IndexSeek. К таким же последствиям приводит использованием OUTER/CROSS APPLY вместе с TOP:
	- Кроме того, использование скалярных функций в запросе мешает SQL Server строить параллельные планы выполнения, что при больших объёмах данных может существенно подкосить производительность.
		- Во всех ли случаях скалярные функции — это зло? Нет. Можно создать функцию с опцией SCHEMABINDING и не использовать входящих параметров:
	- Если таблица была изменена, то ссылающаяс на неё view не увидит этого, надо делать EXEC sys.sp_refreshview @viewname = N'dbo.vw_tbl'
	- Если мы выбираем только часть информации из View, она всё равно будет лезть во все таблицы, но иногда у SQL Server получается обрезать ненужные соединения
	- Те, кто занимается оптимизацией запросов наверняка знают про то что функция coalesce раскрывается оптимизатором как case. Также плохо работает с подзапросами
	- ISNULL() возвращает данные согласно типу данных первого аргумента
	- Указывайте IS NOT NULL в JOIN, чтобы Hash Join отработал лучше
	
	-- Индексированное View. Положительный эффект
		- В Enterprise Edition используйте NOEXPAND
			https://sqlperformance.com/2015/12/sql-performance/noexpand-hints
		- https://msdn.microsoft.com/en-us/library/dd171921(SQL.100).aspx
		- Aggregations can be precomputed and stored in the index to minimize expensive computations during query execution.
		- Tables can be prejoined and the resulting data set stored.
		- Combinations of joins or aggregations can be stored.
		- Joins and aggregations of large tables.
		- Repeated patterns of queries.
		- Repeated aggregations on the same or overlapping sets of columns.
		- Repeated joins of the same tables on the same keys.
		- Combinations of the above.
		
		-- особенности
			 - SQL Server will only automatically create statistics on an indexed view when a NOEXPAND table hint is used. Omitting this hint can lead to execution plan warnings about missing statistics that cannot be resolved by creating statistics manually.
			- SQL Server will only use automatically or manually created view statistics in cardinality estimation calculations when the query references the view directly and a NOEXPAND hint is used. For all but the most trivial view definitions, this means the quality of cardinality estimates is likely to be lower when this hint is not used, often resulting in less optimal execution plans.
			- The lack of, or inability to use, view statistics can cause the optimizer to guess at cardinality estimates, even where base table statistics are available. This can happen where part of the query plan is replaced with an indexed view reference by the automatic view matching feature, but view statistics are not available, as described above.
	
	-- Пункты
		1. Максимально подсказывайте оптимизатору FK, Not Null, Uniqeu
		2. 2008 R2 не использует FK из мультиколоночных FK
		3. Можем использовать LEFT вместо INNER, когда можем чётко сказать зачем, когда есть FK/уникальность и знаем что вернётся не больше 1 строки
		4. 2008 R2 не использует информацию из уникальных фильтрованных индексов
		5. Можно использовать CLUSTER VIEW. Когда делаем выборку, лучше использовать with (noexpand) -- это позволяет работать с этой view как с кластерной view, так как по-умолчанию он всегда работает как с обычной view
		6. GROUP BY позволяет подсказать T-SQL что строка будет 1 для 1 значения
		7. Outer aplly + SELECT TOP 1 позволяет подсказать T-SQL что строка будет 1 для 1 значения
		8. Constraint помогают оптимизатору
		9. Можно создавать временные данные и  JOIN уже с ними
		10. Можно собирать информацию о расхождении ожидаемого количества строк и фактического (Extended Events > Channel Debug > inaccurate_cardinality_estimate) -- Выдаёт информацию не о конечном расхождении оценки и фактического плана, а о расхождении оценки и уже обработанных строк. Счётчик может постепенно увеличиваются и события будут возникать снова по тому же плану
		11. Подумать о вычисляемых столбцах
		
	-- Statistics/Статистика
		1. Использует только статистику первой колонки из индекса (кардинальность)
		2. На первое место выставлять значение с самой большой селективностью
		3. Если хотим чтобы LIKE использовал индекс, то индекс нужно начинать с поля для LIKE
		4. Если запрос сложный, то статиска важнее и можно пожертвовать чтением и тд.
		
	-- Возможные проблемы на продуктиве, которые не воспроизводятся у нас
		1. Проблемы с железом
		2. Разные настройки SQL
		3. Устаревшая статистика
		4. Нагрузка других БД
		5. Кэширование планов
	
	-- ad-hoc
		- Всегда включать "Optimize for ad-hoc"?
		- Включить 'Force parametrization'?
		
		4136 -- отключение parameter sniffing 
			- Что-то вроде 'Optimize for UNKNOWN' на уровне сервера
			- Включать лучше для форсированной параметризации (возможно)
			- Возможно не действует на процедуры и др объекты, работает только с ad-hock
				DBCC TRACEON(4136,-1)
				Потом выполнять запрос
				
	-- Параметризация/parametrization
		- NULL не параметризауется
	
	-- parameter sniffing
		-- Данамический sql
			1. OPTION RECOMPILE
			2. OPTION OPTIMIZE FOR(@id=2)
			3. OPTION OPTIMIZE FOR(@id=UNKNOWN) -- какое-то среднее значение
			4. SELECT * FROM /*id = 1*/ hotel WHERE id = @id -- комментарий позволит создать другой план
		-- Процедура
			1. WITH RECOMPILE
				- Иногда лучше указывать OPTION (RECOMPILE) на конкретных запросах
			
			2. Использовать локальные переменные вместо параметров
			3. OPTIMIZE FOR UNKNOWN
			4. Отключение на уровне экземпляра 4136
			5. На 2016+ можно отключить его на уровне БД
			6. IF + OPTIMIZE FOR 
			7. Динамический SQL через sp_executesql
		-- Другое
			1. Для BETWEEN предопределить передаваемые параметры новыми переменными внутри процедуры
			2. Сделать процедуру, которая в зависимости от передаваемых значений будет вызывать другие
			3. Отключение parameter sniffing на всём экземпляре
			
		-- Как влиять:
			
-- Порядок преобразования типов/Неявное преобразование
	-- Преобразуется всегда от низу к верху
	user-defined data types (highest)
	sql_variant
	xml
	datetimeoffset
	datetime2
	datetime
	smalldatetime
	date
	time
	float
	real
	decimal
	money
	smallmoney
	bigint
	int
	smallint
	tinyint
	bit
	ntext
	text
	image
	timestamp
	uniqueidentifier
	nvarchar (including nvarchar(max) )
	nchar
	varchar (including varchar(max) )
	char
	varbinary (including varbinary(max) )
	binary (lowest)
				

-- Дополнительные данные о выполнении запроса

	- Создание server side trace в том числе с одним из этих двух событий: “Showplan Statistics Profile” или “Showplan Statistics XML”. Кроме того, если вам так удобнее, можно использовать приложение SQL Server Profiler.
	- Создание сессии Extended Events и добавление в ней в качестве целевого события sqlserver.query_post_execution_showplan.
	-- Пример сценария сеанса SQL Server Extended Events для понимания как именно выполняются запросы
		USE master
		GO
		--Create Extended Events Session
		CREATE EVENT SESSION [Capture_Query_Plan] ON SERVER
		ADD EVENT sqlserver.query_post_execution_showplan(
			WHERE ([database_name]=N'AdventureWorks2012')) 
		ADD TARGET package0.ring_buffer
		WITH ( MAX_MEMORY = 4096 KB ,
				EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS ,
				MAX_DISPATCH_LATENCY = 30 SECONDS ,
				MAX_EVENT_SIZE = 0 KB ,
				MEMORY_PARTITION_MODE = NONE ,
				TRACK_CAUSALITY = OFF ,
				STARTUP_STATE = OFF )
		GO
		--Start Extended Events Session
		ALTER EVENT SESSION [Capture_Query_Plan] ON SERVER STATE = START
		GO
		--Stop Extended Events Session
		ALTER EVENT SESSION [Capture_Query_Plan] ON SERVER STATE = STOP
		GO
		--Drop Extended Events Session
		DROP  EVENT SESSION [Capture_Query_Plan] ON SERVER
		GO
		
	-- sys.dm_exec_query_profiles
		-- процент исполнения для каждого физического оператора в плане запроса, число используемых каждым оператором потоков, долю времени активности операторов и зависимых от них объектов, если это применимо.
		SELECT  session_id ,
				node_id ,
				physical_operator_name ,
				SUM(row_count) row_count ,
				SUM(estimate_row_count) AS estimate_row_count ,
				IIF(COUNT(thread_id) = 0, 1, COUNT(thread_id)) [Threads] ,
				CAST(SUM(row_count) * 100. / SUM(estimate_row_count) AS DECIMAL(30, 2)) [% Complete] ,
				CONVERT(TIME, DATEADD(ms, MAX(elapsed_time_ms), 0)) [Operator time] ,
				DB_NAME(database_id) + '.' + OBJECT_SCHEMA_NAME(QP.object_id,
																qp.database_id) + '.'
				+ OBJECT_NAME(QP.object_id, qp.database_id) [Object Name]
		FROM    sys.dm_exec_query_profiles QP
		GROUP BY session_id ,
				node_id ,
				physical_operator_name ,
				qp.database_id ,
				QP.OBJECT_ID ,
				QP.index_id
		ORDER BY session_id ,
				node_id
		GO
		-- Время до завершения операции основываясь на оценке количество строк на выходе
			SELECT  QP.session_id ,
					QP.node_id ,
					QP.physical_operator_name ,
					DB_NAME(database_id) + '.' + OBJECT_SCHEMA_NAME(QP.object_id,
																	qp.database_id) + '.'
					+ OBJECT_NAME(QP.object_id, qp.database_id) [Object Name] ,
					OT.task_state ,
					MAX(WT.wait_duration_ms) [wait_duration_ms] ,
					WT.wait_type
			FROM    sys.dm_exec_query_profiles QP
					INNER JOIN sys.dm_os_tasks OT 
			   ON OT.task_address = QP.task_address
					LEFT  JOIN sys.dm_os_waiting_tasks WT 
			   ON WT.waiting_task_address = QP.task_address
			GROUP BY QP.session_id ,
					QP.node_id ,
					QP.physical_operator_name ,
					OT.task_state ,
					QP.database_id ,
					QP.object_id ,
					WT.wait_type
			GO

-- Индексы
	- При построении индекса сначала строить по тому полю, где много одинаковых значений (по времени строить плохо как по первому полю)	
	
-- Не использовать/В крайних случаях
	1. Избегите использования звёздочки (*) в SELECT, всегда перечисляйте только необходимые столбцы.
	2. В инструкции INSERT всегда указывайте имена столбцов.
	3. Всегда присваивайте таблицам (а при необходимости и столбцам) псевдонимы – это позволяет избежать путаницы. При использовании псевдонима столбца обязательно добавляйте ключевое слово AS.
	4. При ссылке на объект всегда указывайте схему (владельца).
	5. Избегите использования non-SARGable предикатов (“IS NULL”, “<>”, “!=”, “!>”, “!<“, “NOT”, “NOT EXISTS”, “NOT IN”, “NOT LIKE”, “LIKE ‘%500′”, CONVERT и CAST, Строковые функции: LEFT(Column,2) = ‘GR’ , Функции даты/времени: DATEPART (mm, Datecolumn) = 5, Математические операции со столбцом: qty+1> 100 ).
	6. Для сокращения числа итераций старайтесь по возможности использовать строчный оператор CASE. Например:

	select sum(case when e.age < 20 then 1 else 0 end) as under_20
	 
			, sum(case when e.age >= 20 and age <= 40 then 1 else 0end) as between_20_40
	 
		   , sum(case when e.age > 40 then 1 else 0 end) as over_40
	 
	from dbo.employee e
	7. Используйте индексы. Что бы понять, работает ли индекс, всегда проверяйте планы исполнения разрабатываемых запросов.
	8. Используйте формат даты по стандарту ISO – yyyymmdd или ODBC – yyyy-mm-dd hh:mi:ss
	9. Используйте ANSI стиль соединений. Для левых соединений опускайте ключевое слово OUTER.
	10. Для форматирования кода используйте стандартный размер табуляции – четыре символа, и отделяйте логически независимые модули кода пустой строкой.
	11. Старайтесь не использовать недокументированные средства.
	12. Если важна безопасность, не используйте динамический SQL.
	13. Порядок сортировки задавайте только предложением ORDER BY.
	14. Старайтесь хранить скрипты объектов схемы и серверного кода в системе управления версиями (например: VSS или CVS), и включать теги редакций в блок описания назначения скрипта.
	15. Всегда располагайте все DLL команды в начале кода, дабы избежать лишних компиляций.
	16. Избегите использования триггеров и курсоров, оставьте эти инструменты на крайний случай, когда по-другому задачу решить невозможно. Если пришлось писать курсор, предпочтение отдавайте локальным, в режиме: FAST_FORWARD, они самые диетические из всех остальных.
	17. Для повышения производительности соединений, когда ничего другого уже не помогает, используйте индексированные представления соединяемых точно таким же образом таблиц (в не Enterprise редакциях нужно добавлять подсказку NOEXPAND).
	18. Следует помнить, что представления могут маскировать необходимые для оптимизации метаданные, например, когда они скрывают соединения/объединения таблиц из разных баз данных, или когда не задействованы используемые для внутреннего соединения столбцы. В подобных случаях, всегда проверяйте план исполнения запроса, что бы вовремя принять меры по исправлению ситуаций с не оптимальным планом запроса.
	19. Старайтесь делать определяемые пользователем функции детерминированными, они дают более эффективные планы исполнения.
	20. Никогда не используйте в именах процедур префикс “sp_”, он зарезервирован для системных процедур, которые вначале ищутся в базе master.
	
-- Диски
	- Глубина очереди: Обычно 2 на шпиндель, но когда пользователям не нужны данные прям сейчас, то можно увеличитьва глубину, чтобы контроллер мог грамотно запрашивать данные с диска
	- Кэширование на запись на СХД: обычно отключается, так как чаще создаст только проблемы
	- На больших СХД изменить голубину очереди HBA с 32 до макс. Так как СХД может обработать больше, чем получает. Всё зависит от дисков в СХД. Поним для для каждого шпинделя можно по 2 очереди

-- RECOMPILE	
	-- Включение
		1. CREATE PROCEDURE...WITH RECOMPILE -- При включении данной опции SQL Server не регистрирует данный запрос в DMV
		2. EXEC MyProce WITH RECOMPILE
		3. SELECT...OPTION (RECOMPILE) -- Регистрирует в DMV только последний вызов, но есть столбец plun_generation_num, который покажет сколько раз был сгенерирован данный план
		
-- Основное
	1. Если в выражении используется несколько переменных, рекомендуется создать вычисляемый столбец для выражения, а затем создать статистику или индекс по вычисляемому столбцу. Например, предикат запроса WHERE PRICE + Tax > 100 может иметь лучшую оценку количества элементов, если создать вычисляемый столбец для выражения Price + Tax.
	
	2. Если в предикате запроса используется локальная переменная, рекомендуется переписать запрос так, чтобы вместо локальной переменной в нем использовался параметр. Значение локальной переменной неизвестно в момент, когда оптимизатор запросов создает план выполнения запросов. Если в запросе используется параметр, то оптимизатор запросов использует оценку количества элементов для первого фактического значения параметра, передаваемого хранимой процедуре.
	
	3. Для хранения результатов функции (возвращающей табличное значение) с несколькими инструкциями рекомендуется использовать стандартную или временную таблицу. Оптимизатор запросов не создает статистику для функций (возвращающих табличное значение) с несколькими инструкциями. Такой подход позволяет оптимизатору запросов создавать статистику по столбцам таблицы и использовать их для создания улучшенного плана запроса. Дополнительные сведения о функциях (возвращающих табличное значение) с несколькими инструкциями см. в разделе Типы функций.
	
	4. Вместо табличных переменных рекомендуется использовать стандартную или временную таблицу. Оптимизатор запросов не создает статистику для табличных переменных. Такой подход позволяет оптимизатору запросов создавать статистику по столбцам таблицы и использовать их для создания улучшенного плана запроса. При выборе между временной таблицей и табличной переменной следует учитывать, что табличные переменные, используемые в хранимых процедурах, вызывают меньше перекомпиляций хранимой процедуры, чем временные таблицы. В зависимости от приложения использование временной таблицы вместо табличной переменной не обязательно приведет к повышению производительности.
	
	5. Если хранимая процедура содержит запрос, в котором используется переданный параметр, не следует изменять значение параметра в рамках хранимой процедуры до того, как он будет использоваться в запросе. Оценка количество элементов для запроса основывается на значение переданного параметра, а не на обновленном значении. Чтобы исключить изменение значения параметра, можно переписать запрос так, чтобы использовать две хранимые процедуры.
	
-- причины медленного выполнения запросов и обновлений.
	- Медленная передача данных в сети.
	- Недостаточно памяти на серверном компьютере или недостаточно памяти для SQL Server.
	- Не хватает полезной статистики.
	- Не хватает полезных индексов.
	- Не хватает полезных индексированных представлений.
	- Не хватает полезного расслоения данных.
	- Не хватает полезного секционирования.
	
-- Ускорение INSERT
	- http://msdn.microsoft.com/ru-ru/library/dd425070.aspx
	- Insert into a HEAP is minimally logged under TABLOCK but fully logged without TABLOCK
	
	1. При большом количестве ядер:
		- Выбрать не монотонно увеличивающийся столбец как кластерное поле, чтобы вставка была не в одну страницу
		- Секционировать таблицу и индексы, чтобы были разные B-tree
	2. Hints (INSERT … SELECT не поддерживает hints)
		- TABLOCK
		- ORDER (1)
		- ROWS_PER_BATCH.  Must use OPENROWSET with the bulk hint as the source
	3. FLAG
		- 610 (SQL Server 2008). Может замедлиться если медленная дисковая подсистема
	4. Увеличить размер строки, чтобы 1 строка была 8 кб
		
-- Подсказки
	- READPAST (позволяет читать не ожидая блокировок, пропуская записи, единственно на что мы можем тут наткнуть - блокировка на всю таблицу (эсказалция). Чтобы таких блокировок не было можно отключить эскалацию на уровне таблицы или, в SQL Server 2005, на всё сервере с помощью флага 1211)
	- Лучше держать эти параметры всегда в ON ANSI_NULLS и QUOTED_IDENTIFIER (http://www.t-sql.ru/post/QUOTED_IDENTIFIER.aspx)
	- DBCC SHOWONRULES/SHOWOFFRULES -- требует активного флага TRACEON 3604
		DBCC RULEOFF('GetToScan')
		DBCC RULEON('GetToScan')

		DBCC RULEON('JNtoHS')
		DBCC RULEON('JNtoSM')
	
	
	-- Отключить/включить операторы
		- OPTION (QUERYRULEOFF/QUERYRULEON GbAggBeforeJoin)
		- SelToIdxStrategy -- заставим оптимизатор убрать поиск (seek) по индексу
		- GetToIdxScan -- повлиять на index Scan		
		- GetToScan -- повлиять на весь Scan
		
	-- Список оптимизаций
		- Если мы не используем вторую таблицу, то оптимайзер отбросит операции с ней
		- Если View использует 3 таблицы, но при запросе к ней мы требуем данные только из 1, то обрабатываться будет одна
		SELECT * FROM sys.dm_exec_query_transformation_stats
		
	-- JOINS
		- SEMI join (для его использования нужно писать EXISTS, IN, EXCEPT)
			- Не даёт NULL
			- Не создаёт новых строк
			- Сравнивает левую таблицу по правой. Фильтрование без увеличения количества строк
		- Где помещать условия филтрации
			- В случае с LEFT JOIN фильтрацию надо добавить в WHERE, иначе мы получим все строки просто с NULL, когда мы помещаем в ON
			
		- CROSS APPLY
			- Даёт возможность вернуть много колонок с логикой выполнения подзапроса
			- Возвращает только 1 строку
			
		- OUTHER APPLY 
			- Как CROSS APLLY, но так же возвращает те строки, которые не нашли совпадения в подзапросе, то есть не исплючает из вывода строки левой таблицы
	
	
-- Чтение плана
	Движение строк - справа на лево
	Логические операторы - слева на право
	
-- Стоимость операторов/дорогие операторы
	1. Key Loop (дорогой оператор для CPU)
	2. Nested Loops (Дорогой по CPU)

-- Виды JOIN (физический уровень)
	- MERGE JOIN
		-- Может делаться с помощью
			- INNER JOIN/LEFT JOIN/OUTER APPLY/UNION/RIGHT JOIN
		-- Когда применять
			- Есть 2 таблицы с покрывающими уникальными (когда значения разные, а не одинаковые) индексами по ключу соединения
		- Соединение слиянием требует сортировки обоих наборов входных данных по столбцам слияния, которые определены предложениями равенства (ON) предиката объединения. Оптимизатор запросов обычно просматривает индекс, если для соответствующего набора столбцов такой существует, или устанавливает оператор сортировки под соединением слиянием. В редких случаях может быть несколько предложений равенства, но столбцы слияния берутся только из некоторых доступных предложений равенства.
		- Соединение слиянием — очень быстрая операция, но она может оказаться ресурсоемкой, если требуется выполнение операций сортировки. Однако если том данных имеет большой объем, и необходимые данные могут быть получены из существующих индексов сбалансированного дерева с выполненной предварительной сортировкой, соединение слиянием является самым быстрым из доступных алгоритмов соединения.
	- Nested Loops JOIN
		-- Может делаться с помощью
			- INNER JOIN/LEFT JOIN/CROSS JOIN/CROSS APPLY/OUTER APPLY
		-- Не работает с 
			- RIGTH JOIN/ FULL JOIN
		-- Когда применять
			- Во внешней таблице мало записей, а во внутренней проиндексирован по ключ соединения
			- Если в условии есть неравенство или сравнение, то будет использоваться этот оператор
		- Соединение вложенных циклов, называемое также вложенной итерацией, использует один ввод соединения в качестве внешней входной таблицы, а второй в качестве внутренней (нижней) входной таблицы. Внешний цикл использует внешнюю входную таблицу построчно. Во внутреннем цикле для каждой внешней строки производится сканирование внутренней входной таблицы и вывод совпадающих строк.
		- В простейшем случае во время поиска целиком просматривается таблица или индекс; это называется упрощенным соединением вложенных циклов. Если при поиске используется индекс, то такой поиск называется индексным соединением вложенных циклов. Если индекс создается в качестве части плана запроса (и уничтожается после завершения запроса), то он называется временным индексным соединением вложенных циклов. Все эти варианты учитываются оптимизатором запросов.
		- Соединение вложенных циклов является особенно эффективным в случае, когда внешние входные данные сравнительно невелики, а внутренние входные данные велики и заранее индексированы. Во многих небольших транзакциях, работающих с небольшими наборами строк, индексное соединение вложенных циклов превосходит как соединения слиянием, так и хэш-соединения. Однако в больших запросах соединения вложенных циклов часто являются не лучшим вариантом.
	- Hash JOIN
		-- Когда применять
			- Для соединения 2-х таблиц, когда одна небольшая и нет индексов по ключу
			- Когда памяти хватает
			- Грузит процессор
			- Pre-sorted input is not available
			- The hash build input is smaller than the probe input
			- The probe input is quite large				
			
		-- Как отслеживать, когда не хватает памяти и происходит сброс на диск
			- SQL Trace - Hash Warning
			- Extended Events (2012+) - hash_warning
			- Actual Execution PLAN (2012+). Желтый восклицательный знак
		-- Может делаться с помощью
			- со всеми типами логических операций
		- Хэш-соединение имеет два входа: конструктивный и пробный. Оптимизатор запросов распределяет роли таким образом, при котором меньшему входу присваивается значение «конструктивный».
		-- In-memmory Hash JOIN
			- Перед проведением хэш-соединения производится просмотр или вычисление входного конструктивного значения, а затем в памяти создается хэш-таблица. Каждая строка помещается в сегмент хэша согласно значению, вычисленному для хэш-ключа. В случае если конструктивное входное значение имеет размер, меньший объема доступной памяти, то все строки данных могут быть занесены в хэш-таблицу. После описанного конструктивного этапа предпринимается пробный этап. Производится построковое считывание или вычисление пробного входного значения, для каждой строки вычисляется значение хэш-ключа, затем происходит сканирование сегмента хэша и поиск совпадений.
		-- Grace Hash JOIN
			- Если размер конструктивного входного значения превышает максимально допустимый объем памяти, то хэш-соединение проводится в несколько шагов. Указанный процесс называется плавным хэш-соединением. Каждый шаг состоит из конструктивной и пробной частей. Исходные конструктивные и пробные входные данные разбиваются на несколько файлов (для этого используются хэш-функции ключей). При использовании хэш-функции для хэш-ключей обеспечивается гарантия нахождения соединяемых записей в общей паре файлов. Таким образом, задача соединения двух объемных входных значений разбивается на несколько более мелких задач. Затем хэш-соединение применяется к каждой паре разделенных файлов.
		-- Recursive Hash JOIn
			- Если объем информации, поступающей на конструктивный вход, настолько велик, что для использования обычного внешнего слияния требуется несколько уровней, то операцию разбиения необходимо проводить за несколько шагов на нескольких уровнях. Дополнительные шаги разбиения используются только для секций большого объема. Чтобы максимально ускорить проведение всех шагов разбиения, используются емкие асинхронные операции ввода-вывода, в результате чего один поток может занимать сразу несколько жестких дисков.
		-- Hash Bailout
			- Термин аварийная остановка хэша иногда используется для описания поэтапных и рекурсивных хэш-соединений. Наличие рекурсивных хэш-соединений и аварийных остановок снижает производительность сервера. Если в трассировке содержится много событий-предупреждений хэша, необходимо произвести обновление статистических данных соединяемых столбцов.		

			
	-- Особенности
		1. До 2012 процесс упрощения может выполнить сначала t1.b = 1 и t2.b = 1 и только потом JOIN, это не даст возможность использовать MERGE и HASH, чтобы это обойти надо указать t1.b > 0 and t1.b < 2, так как процесс упрощения тогда не будет выполнен
			select *
				from
					t1
					join t2 on t1.b = t2.b
				where
					t1.b = 1
				option(recompile,merge join,hash join);
		2. Внутри IN важен порядок соединения. До 2012 точно SQL Server не может провести упрощение для подзапроса в IN. Можно исправить используя EXISTS
			select * from Sales.SalesOrderHeader soh 
			where soh.CustomerID in (select sc.CustomerID from Sales.Customer sc where soh.CustomerID = sc.CustomerID)
			
-- Операторы
	-- Table spool
		Оператор Table Spool просматривает входную таблицу и помещает копию каждой строки в скрытую буферную таблицу, которая находится в базе данных tempdb и существует только в течение времени жизни запроса
	-- Compute Scalar
		- Как только вы увидите в плане перед сканированием columnstore индекса оператор compute scalar — подумайте, не может ли он предотвратить реальный режим Batch и проверьте это при помощи xEvents (событие expression_compile_stop_batch_processing)
	-- TOP
		- Иногда для top нужно указать forceseek или обратную сортировку (ORDER BY DESC)
		
-- Как заставить выделить больше памяти для запроса
	- Даёт возможность исключить spill to tempdb
	0. Настройка сервера - минимальное количество памяти для одного запроса
	0. SELECT * FROM Table1 ORDER BY Column1 OPTION (min_grant_percent = 10, max_grant_percent = 50) -- указывается в % соотношении от памяти SQL Server. Минимальное значение = 0.00, максимальное = 100.00. Работает с 2012 SP3. Возможно только если работает resource fovernor
	1. убедитесь что estimated number of rows равно или близко к actual number of rows 
	2. если это не помогло – рассмотрите вариант установить CU (https://support.microsoft.com/en-us/help/3088480/fix-sort-operator-spills-to-tempdb-in-sql-server-2012-or-sql-server-2014-when-estimated-number-of-rows-and-row-size-are-correct) и использовать TF (TF 7470)
	- dbcc traceon (9389) -- For a batch mode sort, in case you cannot fix the estimates there is a trace flag 9389, which turns on dynamic memory grants for batch mode operators (not only a Sort) in SQL Server 2016 and upwards. This trace flag may not help if you have not enough memory, for example, when I set an option ‘max server memory (MB)’ to 480 MB
	3. Заставить использовать больше памяти чем сейчас
		Memory and spilling Before a hash join begins execution, SQL Server tries to estimate how much memory it will need to build its hash table. It uses the cardinality estimate for the size of the build input along with the expected average row size to estimate the memory requirement. To minimize the memory required by the hash join, the optimizer chooses the smaller of the two tables as the build table. SQL Server then tries to reserve sufficient memory to ensure that the hash join can successfully store the entire build table in memory.

		When we talk about memory-consuming iterators, the first that should come to mind are:
		  - Sort
		  - Hash join
		  - Hash aggregation
		  
		-- Мои тесты
			Если запрос на физ. уровне использует Merge, то чтобы контролировать память, надо заставить делать его SORT или любой другой итератор, который запросит память, для HASH JOIN память всегда запрашивается. 
			Вот моё решение:
S
			MemoryGrant - 9352

			SELECT CAST(name as varchar(512)) FROM partner p INNER JOIN claim c ON p.inc = c .partner
			OPTION (HASH JOIN)

			MemoryGrant - 23240

			SELECT CAST(name as varchar(2000)) FROM partner p INNER JOIN claim c ON p.inc as bigint = c .partner
			OPTION (HASH JOIN)
			
			Суть в первом высланном абзаце на англ. Я заставляю SQL Server понять что для хэша, для большей длины строки, ему понадобится больше памяти. Странно, я думал тут играет роль ключ сравнения, но длина строки, получается, так же важна

			Опять ОГРОМНЫЙ минус в сторону SELECT *

			И сегодня, когда используется hash join, оценочное количество строк стало играть роль. То есть если я обновлю статистику с WITH ROWCOUNT = 50 000, потребуется меньше памяти нежели с WITH ROWCOUNT = 500 000
			
-- Отслеживание проблем с выделением памяти
	- Для этого, открываете Profiler, выбираете пустой шаблон, выбираете события "Errors and Warnings : Hash Warning", "Errors and Warnings : Sort Warnings". Ставите фильтр по SPID, указывая SPID того окна в котором будете выполнять запрос (select @@spid в SSMS). Стартуете сессию трассировки в профайлере, выполняете запро, смотрите, есть ли предупреждения и какие.
	
	-- Решение
	1. Создать многоколоночную статистику (create statistics . У вас проверяется на равенство, в этом случае, многоколоночная статистика может помочь.
	create statistics s_OrganizationActive on dbo.OneC_F_AccountingEntrie(Organization, Active);
	2. Вынести список организаций во временную таблицу и соединять с ней. Это скорее выстрел "на удачу", возможно оценки будут лучше, возможно нет, во всяком случае должны измениться.
	3. Использовать TF 4137 http://support.microsoft.com/kb/2658214. Который исправляет ситуацию с коррелированными предикатами.
	4. Разбитьзапрос на части, через промежуточные таблицы SQL Server Customer Advisory Team - When To Break Down Complex Queries. http://blogs.msdn.com/b/sqlcat/archive/2013/09/09/when-to-break-down-complex-queries.aspx
	
-- Адаптимные запросы/Adaptive Query Processing
	-- Interleaved Executions
		- The new feature can learn that even while the execution of the query, SQL Server Query Optimizer learns that if the estimates are way off than the actual ones, it adjusts the execution plan by actually executing a part of the query execution plan first and re-design the Query Execution Plan based on the actual amount of the rows. This leads to a much better plan, which is created and adjusted while the query is executing.
	-- Batch Mode Memory Grant Feedback
		- In SQL Server 2017, the Batch Mode Memory Grant Feedback feature enables the SQL Server Query Processing engine to learn that if the memory grants are not sufficient then the engine will change the cached execution plan and update the memory grants so that the later executions should benefit with the new grants.
	-- Batch Mode Adaptive Joins
		- Batch Mode Adaptive Joins are also a great way to improve the query performance based of the number of rows flowing through the actual execution plan. The concept here is simple; the execution engine defers the choice of a Hash Join or a Nested Loop Join until the first join in the query execution plan is made. After that first join has been executed and based on the number of records fetched, the SQL Server Query Processing engine decides whether to choose Hash Join or Nested Loop Join.
		
-- Batch mode
	- Появился в 2012 редакции
	- Применимо к колономным индексам
	- За раз выбирает 900 строк (http://www.queryprocessor.com/sort-spill-memory-and-adaptive-memory-grant-feedback/)
	
	-- Заставить использовать в обычных запросах
		- https://sqlworkbooks.com/2017/05/batch-mode-hacks-for-rowstore-queries-in-sql-server/
		- Создать некластерный колоночный индекс с несуществующим фильтром -- Требует SQL Server 2016
			CREATE NONCLUSTERED COLUMNSTORE INDEX nccx_agg_FirstNameByYearState 
			ON agg.FirstNameByYearState
				(FirstNameId)
			WHERE FirstNameId = -1 and FirstNameId = -2;
			
			LEFT JOIN dbo.hack on 1=0
		
		- Создать таблицу (можно временную) с 1 стобцом и по нему сделать некластерный колоночный индекс, после чего добавить в конце нужного запроса LEFT JOIN MyTable ON 1 =0 
	
	-- Особенности
		1. Позволяет динамично выделять память после начала выполнения
	
-- Columnstore
	Можно попробовать использовать OUTHER APPLY (вместо CROSS APPLY) чтобы заставить использовать HASH JOIN
		
-- Назначить выполнение конкретному процессору	
	SET PROCESS AFFINITY CPU=0;
	
-- Последние ожидания сессии
	SELECT * FROM sys.dm_exec_session_wait_stats
	
-- TVF (функции)
	- Multi-statement TVFs use table variables to store the result; thereby causing TEMPDB contention at scale
	- Inline TVFs do not need such temporary storage and scale much better
	- Beware of optional parameters in your TVFs. These can compound your performance problems. Whenever possible, replace TVFs which use optional parameters with specialized versions (with mandatory parameter values) for each case
	- OPTION (RECOMPILE) can be very handy to deal with the optional parameter problem, but that comes with its own cost. Be sure to test thoroughly at scale before finalizing the code
	
-- Live Query Statistics
	-- Активация
		- Before you start the query, run SET STATISTICS PROFILE ON or SET STATISTICS XML ON. With both statements, you will be able to view the Live Execution Plan through Activity Monitor, but you won’t see the live plan in the query window itself.
		- В SSMS
	-- Облегчённая версия (на уровень сервера)
		- DBCC TRACEON (7412)
		- You can enable the query_post_execution_showplan extended event. Be aware that this is a server-wide setting that will enable Live Query Statistics on any session. This can have of course a serious performance impact.
		
	-- Посмотреть через запрос
		select st.text
		, eqp.physical_operator_name
		, eqp.row_count
		, eqp.estimate_row_count
		, 100 * eqp.row_count /eqp.estimate_row_count as [PercentComplete]
		  from sys.dm_exec_query_profiles as eqp
			cross apply sys.dm_exec_sql_text (eqp.sql_handle) as st

-- Требования к таблице и коду, что бы поддерживалась концепция кэширования:
	- Таблица должена быть меньше восьми мегабайт. Большие таблицы не кэшируются.
	- Нет операторов DDL, которые изменяют структуру таблицы. Любые инструкции модификации схемы в коде, за исключением DROP TABLE, предотвращают кэширование временных объектов.       
	- В таблице не указаны именованные ограничения (в любом случае, плохая идея, поскольку одновременное выполнение может вызвать столкновение имен). Безымянные ограничения не будут препятствовать кешированию.
	- Таблица не создается с помощью динамического SQL.
	
	Кэшированный объект привязан к плану запроса, который ссылается на него. Если план выведен из кеша по любой причине (возможно, с помощью ALTER или DROP PROCEDURE или явной команды DBCC FREEPROCCACHE) фоновый поток удаляет объект из tempdb. SQL Server также удаляет кэшированные временные объекты, когда TempDB имеет мало свободного места. + можно еще вручную чистить именно CACHESTORE_TEMPTABLES dbcc freesystemcache ('Temporary Tables & Table Variables')	
	
	SELECT domcc.name
      ,domcc.[type]
      ,domcc.entries_count
      ,domcc.entries_in_use_count
	FROM   sys.dm_os_memory_cache_counters AS domcc
	WHERE  domcc.[type] = N'CACHESTORE_TEMPTABLES';

	SELECT dopc.[object_name]
		  ,dopc.counter_name 
		  ,dopc.cntr_value
	FROM   sys.dm_os_performance_counters AS dopc
	WHERE  dopc.[object_name] LIKE N'%Plan Cache%'
		   AND dopc.instance_name = N'Temporary Tables & Table Variables'
		   AND dopc.counter_name IN (N'Cache Object Counts', N'Cache Objects in use');

	SELECT dopc.[object_name]
		  ,dopc.counter_name 
		  ,dopc.cntr_value 
	FROM   sys.dm_os_performance_counters AS dopc 
	WHERE  dopc.counter_name = 'Temp Tables Creation Rate' 
		   AND dopc.object_name = 'SQLServer:General Statistics';

-- LEFT JOIN
	- FORCE ORDER
		   
-- Оконные функции / windows functions
	Для упрощения/уменьшения оценки стоимости сортировки можно использовать row_number() over (order by (select null)
	
-- Delete
	- Чтобы убрать Sort из delete, нужно обмануть сиквел, чтобы он не знал сколько строк будет удалено
		 DECLARE @d int = 99999999
		DELETE TOP (@d) FROM [t].[dbo].[par]

-- Computed columns/ вычисляемые столбцы
	1. Никогда не создавайте вычисляемые столбцы с пользовательской функцией (UDF). Оптимизатор не сможет применить к вашему запросу параллелизм
	2. is not being able to create a filtered index on a computed column
	3. Постоянные или даже обычные с индексом могут помочь с производительностью. Сиквел не всегда выбирает эти колонки, так как может оценить что они менее эффективны
	4. Чтобы сиквел использовать вычисляемые столбцы, иногда ему нужно добавить их явно T2.Computed = T1.Computed
	
-- Live Query Statistics
	7412 активировать на уровне сервера легковесный Live Query Statistics
 
-- Использовать параллелизм/parallel
	OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE')) (2016+)
	'ASSUME_JOIN_PREDICATE_DEPENDS_ON_FILTERS' (2016+) -- Материализует промежуточный результат в tempdb
	,QUERYTRACEON 8649 -- Принудить использовать паралллельный план
	
	-- отключить параллелизм 
		2528 -- Отключает параллельную проверку объектов с помощью инструкций DBCC CHECKDB, DBCC CHECKFILEGROUP и DBCC CHECKTABLE.
	
	-- Причина отсутствия параллельного плана
		- Надо найти в XML плане 
			<QueryPlan NonParallelPlanReason=»NoParallelPlansInDesktopOrExpressEdition« …/>
			
	-- Обратить внимание на
		Nested loops join parallelism may be limited due to:
			– Too few outer rows (e.g., partitioned table with two partitions)
			– Poor distribution of rows to pages (e.g., skewed parallel scan)
			– Showplan XML shows the number of rows processed per thread
		• Merging exchanges
			– May not scale as well as non-merging exchanges
			– Parallel deadlocks (rare – especially with SQL Server 2005)
		• Inserts, updates, and deletes are serial (except for index build)
			– Application level parallelization can help, but …
			– Cannot manually parallelize bulk load without giving up bulk logging
		• Some features, operators, and intrinsics may force serial plans or serial zones (and bottlenecks) within a parallel plan
		• On SQL Server 2000, reducing DOP may not reduce CPU usage
		
	-- Возможные причины отсутствия параллельного плана
		Forces a serial plan:
		• All TSQL UDFs
		• CLR UDFs with data access
		• Miscellaneous built-ins such as:
			OBJECT_ID(), ERROR_NUMBER(), @@TRANCOUNT, …
		• Dynamic cursors
		
		Forces a serial zone (within a parallel plan): -- A serial zone is when SQL Server gathers any preceding parallel streams into a single stream, performing the operation at hand. Once done, the streams can be distributed again if necessary.
		• System table scans • Sequence functions • TOP
		• “Backward” scans • Recursive queries • TVFs
		• Global scalar aggregate • Multi-consumer spool
		
		Serial zones may lead to bottlenecks and reduced performance

	
-- prefetch
	- Упреждающее чтение
	- https://www.red-gate.com/simple-talk/sql/performance/sql-server-prefetch-and-query-performance/
	- Для своей работы использует дополнительные блокировки для индекса даже при Index Seek и при READ UNCOMMITED. Необходимо осторожно использовать в конкуретной среде
	- Если Nested loop должен будет выполнится более 25 раз, то prefetch активируется
	
-- Aggregate Pushdown
	A normal execution path for aggregate computation to fetch the qualifying rows from the SCAN node and aggregate the values in Batch Mode. While this delivers good performance, but with SQL Server 2016, the aggregate operation can be pushed to the SCAN node to improve the performance of aggregate computation by orders of magnitude on top of Batch Mode execution provided the following conditions are met:

	The aggregates are MIN, MAX, SUM, COUNT and COUNT(*).
	Aggregate operator must be on top of SCAN node or SCAN node with GROUP BY.
	This aggregate is not a distinct aggregate.
	The aggregate column is not a string column.
	The aggregate column is not a virtual column.
	The input and output datatype must be one of the following and must fit within 64 bits.

	tinyint, int, bigint, smallint, bit
	smallmoney, money, decimal and numeric with precision <= 18
	smalldate, date, datetime, datetime2, time

-- Linked Server
	- Дать достаточные права, чтобы можно было использовать статистику
		sysadmin
		db_owner
		db_ddladmin
	- Использовать sp_executesql
	
	-- Синтаксис		
		- Не использовать JOIN между локальной и удалённой таблицей
		- Некоторые функции не смогут быть выполнены удалённо GETDATE()
		- OPENQUERY() чтобы выполнить запрос удалённо

-- Trivial plan/тривиальный план
	- Статистика подгружается, но используется не полностью -- статистика на стадии тривиального плана все же используется, другое дело, что на ее основе не применяются так называемые «cost based decisions», т.е решения по преобразованию операторов на основе стоимости (в этом мы еще убедимся в следующей части).
	
-- Rebinds, Rewinds
	Rebinds - хорошо. Переход к следующему значению на внешнем "цикле". Т.е. сразу, как только во внутренней таблице было найдено значение – происходит прерывание внутреннего цикла и смена искомого значения во внешнем. Можем помочь если сделаем например primary key
	Rewinds - плохо. Поиска во внутреннем цикле после нахождения во внешнем
	
-- optimizer_whatif
	DBCC TRACEON(3604) WITH NO_INFOMSGS
	GO
	dbcc optimizer_whatif('Status')
	
	-- Пример использования
		dbcc optimizer_whatif('CPUs',8)
	
	-- сбросить результаты экспериментов.
		dbcc optimizer_whatif('ResetAll')

