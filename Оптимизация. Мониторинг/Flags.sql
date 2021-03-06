-- Флаги
	- Держатся только до перезагрузки
	- -1 означает что флаг включается глобально
	DBCC TRACEON(1204); --  Логирование в ERRORLOG deadlock
	DBCC TRACEON(1205) -- Дополняет 1204 (или старый или недокументированный)
	DBCC TRACEON(1222, -1) -- Возвращает ресурсы и типы блокировок, участвующих во взаимоблокировке, а также текущую команду, на которую влияет взаимоблокировка, в формате XML, не соответствующем ни одной XSD-схеме.
	DBCC TRACEON(3502, -1); -- Логирование в ERRORLOG операции checkpoint
	DBCC TRACEON(2505) -- Отключение логирования DBCC TRACEON и DBCC TRACEOFF
	DBCC TRACEON(3604); -- Выводить информацию на экран при работа с DBCC/SSMS
	DBCC TRACEON(3604); -- Вывод информации в LOG
	OPTION (QUERYTRACEON 9292) -- With this enabled, we get a report of statistics objects which are considered ‘interesting’ by the query optimizer when compiling, or recompiling the query in question.  For potentially useful statistics, just the header is loaded.
	OPTION (QUERYTRACEON 9204) -- With this enabled, we see the ‘interesting’ statistics which end up being fully loaded and used to produce cardinality and distribution estimates for some plan alternative or other.  Again, this only happens when a plan is compiled or recompiled – not when a plan is retrieved from cache.
	DBCC TRACEON(2861); -- Используют системы мониторинга. Нагружает память
	DBCC TRACEON(2371); -- Изменить автоматическое обновление статистики, чтобы было чаще, а не при 20% изменений
	DBCC TRACEON(3226); --По умолчанию каждая успешная операция резервного копирования добавляет запись в журнал ошибок служб SQL Server и в журнал системных событий. При частом выполнении резервного копирования журнала такие сообщения об успешном выполнении быстро накапливаются, в результате чего создаются огромные журналы ошибок, в которых трудно найти другие сообщения. С помощью этого флага трассировки можно подавить такие записи журнала. Это может быть полезным при частом выполнении резервного копирования журнала и в случае, если ни один из используемых сценариев не зависит от этих записей.
	DBCC TRACESTATUS(-1); -- Посмотреть все включенные флаги
	DBCC TRACEOFF(); -- Отключить флаг
	DBCC HELP ('?')  -- Список флагов
	DBCC TRACEON(2588); -- Расширенная информация DBCC HELP ('?')
	T1118 -- увеличение параллелизма для Tempdb
	T845 -- Блокировка страниц в памяти (добавить к запуску сервера)
	T1117 -- Позволяет активировать рост сразу всех файлов бд одновременно, может применяться для равномерного роста файлов tempdb	
	661 -- отключить процесс удаления записей ghost (ghost cleanup)
	610 -- минимальное логирование (http://msdn.microsoft.com/ru-ru/library/dd425070.aspx), только для вставки и только там, где есть индексы. Вообще вот хорошая статья, которая покажет что может минимально логироваться (http://www.sqlservercentral.com/articles/Administration/100856/)
	DBCC TRACEON(3004,3605,-1) -- Расширенная информация в ERRORLOG о RESTORE. Включать на время RESTORE
	1807 - позволяет разместить БД на файловой шаре
	T8048 -- Обязательно включить если 8 и более CPU на сокет
		The issue is commonly identified by looking as the DMVs dm_os_wait_stats and dm_os_spinlock_stats for types (CMEMTHREAD and SOS_SUSPEND_QUEUE).   Microsoft CSS usually sees the spins jump into the trillions and the waits become a hot spot.  
	-T8079 -- Включение Soft-Numa на 2014, только если более 8 CPU на ядро
	T8690 -- отключение table and index spool	
	-T8008 -- заставляет игнорировать подсказку планировщика (task shedule). Привязка будет сделана к планировщику с наименьшей нагрузкой (на основе пулов в SQL 2012 Enterprise Edition или коэффициента нагрузки для предыдущих версий и младших редакций).
	-T8016 -- заставляет игнорировать балансировку нагрузки (task shedule). Всегда выбирается предпочтительный планировщик.	
	–T8780 -- Увеличение времени на поиск оптимального плана, не включать на уровне сервера, только на уровне запроса
	-T2453 -- Позволяет улучшить статистику табличных переменных
	7412 -- активировать на уровне сервера легковесный Live Query Statistics
	
	
-- Позволяет формировать дополнительный вывод по выполению процедуры
	OPTION
	(
    QUERYTRACEON 3604,
    QUERYTRACEON 9292,
    QUERYTRACEON 9204,
	, querytraceon 2363 -- <-- (2014, new:) TF Selectivity 
	Дерево физических операторов — TF 8607
	Дерево логических операторов — TF 8606
	9130
	, querytraceon 8619 -- <-- Show Applied Transformation Rules
	, querytraceon 8612 -- <-- Add Extra Info to the Trees Output
	, querytraceon 2372 -- <-- Memory for Phases
	, querytraceon 2373 -- <-- Memory for Deriving Properties
	, querytraceon 2313 -- Cardinality estimation до 2016	
	, querytraceon 9481 -- Cardinality estimation в 2016+
	)
	
	-- Влияние на оптимизацию запросов
		2340 --	Causes SQL Server not to use a sort operation (batch sort) for optimized nested loop joins when generating a plan. For more information, see this Microsoft Support article. Beginning with SQL Server 2016 SP1, to accomplish this at the query level, add the USE HINT query hint instead of using this trace flag. Note: Please ensure that you thoroughly test this option, before rolling it into a production environment.. Scope: global or session or query
		9481 -- Enables you to set the query optimizer cardinality estimation model to the SQL Server 2012 and earlier versions, irrespective of the compatibility level of the database. For more information, see Microsoft Support article. To accomplish this at the database level, see ALTER DATABASE SCOPED CONFIGURATION (Transact-SQL). Beginning with SQL Server 2016 SP1, to accomplish this at the query level, add the USE HINT query hint instead of using this trace flag. Scope: global or session or query
		4199 -- Trace flag 4199 enables all the fixes that were previously made for the query processor under many trace flags. The fixes are only enabled by using a trace flag
		4136 -- отключение parameter sniffing 
			- Что-то вроде 'Optimize for UNKNOWN' на уровне сервера
			- Включать лучше для форсированной параметризации (возможно)
			- Возможно не действует на процедуры и др объекты, работает только с ad-hock
				DBCC TRACEON(4136,-1)
				Потом выполнять запрос
		4137 -- Causes SQL Server to generate a plan using minimum selectivity when estimating AND predicates for filters to account for correlation, under the query optimizer cardinality estimation model of SQL Server 2012 and earlier versions. For more information, see this Microsoft Support article. Beginning with SQL Server 2016 SP1, to accomplish this at the query level, add the USE HINT query hint instead of using this trace flag. Note: Please ensure that you thoroughly test this option, before rolling it into a production environment. Scope: global or session or query
		9471 -- Causes SQL Server to generate a plan using minimum selectivity for single-table filters, under the query optimizer cardinality estimation model of SQL Server 2014 through SQL Server 2016 versions. Beginning with SQL Server 2016 SP1, to accomplish this at the query level, add the USE HINT query hint instead of using this trace flag. Note: Please ensure that you thoroughly test this option, before rolling it into a production environment. Scope: global or session or query
		4138 -- Causes SQL Server to generate a plan that does not use row goal adjustments with queries that contain TOP, OPTION (FAST N), IN, or EXISTS keywords. For more information, see this Microsoft Support article. Beginning with SQL Server 2016 SP1, to accomplish this at the query level, add the USE HINT query hint instead of using this trace flag. Note: Please ensure that you thoroughly test this option, before rolling it into a production environment. Scope: global or session or query
		4139 -- Enable automatically generated quick statistics (histogram amendment) regardless of key column status. If trace flag 4139 is set, regardless of the leading statistics column status (ascending, descending, or stationary), the histogram used to estimate cardinality will be adjusted at query compile time. For more information, see this Microsoft Support article. Beginning with SQL Server 2016 SP1, to accomplish this at the query level, add the USE HINT query hint instead of using this trace flag. Note: Please ensure that you thoroughly test this option, before rolling it into a production environment. Scope: global or session or query
		9476 -- Causes SQL Server to generate a plan using the Simple Containment assumption instead of the default Base Containment assumption, under the query optimizer cardinality estimation model of SQL Server 2014 through SQL Server 2016 versions. For more information, see Microsoft Support article. Beginning with SQL Server 2016 SP1, to accomplish this at the query level, add the USE HINT query hint instead of using this trace flag. Note: Please ensure that you thoroughly test this option, before rolling it into a production environment. Scope: global or session or query
		2312 -- Enables you to set the query optimizer cardinality estimation model to the SQL Server 2014 through SQL Server 2016 versions, dependent of the compatibility level of the database. For more information, see Microsoft Support article. Scope: global or session or query
		
-- Проверить состояние флага для текущей сессии
	SELECT quoted_identifier
	FROM sys.dm_exec_sessions
	WHERE session_id = @@spid;
	
Flag 1211 
	Отключает укрупнение блокировки, основанное на слишком активном использовании памяти или на количестве блокировок. Компонент SQL Server Database Engine не будет повышать уровень блокировки с блокировки строки или страницы до блокировки таблицы.
	При использовании этого флага трассировки может быть создано излишнее количество блокировок. Это может привести к снижению производительности компонента Компонент Database Engine или вызвать ошибки 1204 (невозможность выделить блокированный ресурс) из-за недостатка памяти
	Если установлены оба флага трассировки 1211 и 1224, то флаг 1211 имеет более высокий приоритет. Однако, так как флаг трассировки 1211 препятствует укрупнению во всех случаях, даже при слишком активном использовании памяти, рекомендуется использовать флаг 1224. Это помогает избежать ошибок «отсутствия блокировок» при использовании большого числа блокировок.
	Область: глобальная или сеанс.

Flag 1224
	Отключает укрупнение блокировок на основе количества блокировок. Однако слишком активное использование памяти может включить укрупнение блокировок. Компонент Компонент Database Engine укрупняет блокировки строк или страниц до блокировок таблиц (или секций), если объем памяти, используемый блокированными объектами, превышает одно из следующих условий.
	Сорок процентов памяти, которая используется компонентом Компонент Database Engine. Применимо только в случае, если параметр locks процедуры sp_configure имеет значение 0.
	Сорок процентов памяти блокировки, настроенной на использование параметра locks процедуры sp_configure. Дополнительные сведения см. в разделе Параметры конфигурации сервера (SQL Server).
	Если установлены оба флага трассировки 1211 и 1224, то флаг 1211 имеет более высокий приоритет. Однако, так как флаг трассировки 1211 препятствует укрупнению во всех случаях, даже при слишком активном использовании памяти, рекомендуется использовать флаг 1224. Это помогает избежать ошибок «отсутствия блокировок» при использовании большого числа блокировок.
	Примечание Примечание
	Укрупнением блокировки до уровня гранулярности таблицы или HoBT можно также управлять с помощью параметра LOCK_ESCALATION инструкции ALTER TABLE.

Flag 2301	
	Появившееся в SQL Server 2005 SP1 расширение оптимизатора Query Processor Modelling Extensions можно включить с помощью флага трассировки 2301. Это расширение обеспечивает возможность системы моделирования оптимизатора запросов выбирать более производительные планы исполнения сложных запросов к базе данных. Улучшенное моделирование планов запроса в некоторых случаях может привести к существенному повышению производительности исполнения запросов. Однако, эти расширения моделирования процессора запросов, могут привести к заметному увеличенному времени компиляции, и поэтому рекомендуются для использования только в тех приложениях, в которых компиляций бывает немного, и они происходят нечасто
		
Flag 2335
	Amount of memory available to SQL Server affects the execution plan generated though SQL Server generates the most optimal plan based on this value, but occasionally it may generate an inefficient plan for a specific query when you configure a large value for max server memory. Using 2335 as a startup parameter will cause SQL Server to generate a plan that is more conservative in terms of memory consumption when executing the query. It does not limit how much memory SQL Server can use. The memory configured for SQL Server will still be used by data cache, query execution & other consumers. KB 2413549. 
	
-- Флаги для высоконагруженных систем	
	
652 Флаг трассировки: отключение страницы pre-fetching просмотров/отключение упреждающего чтения
	Трассировка 652 отключает флаг страницы предварительное во время сканирования. Можно включить флаг трассировки 652 при запуске или во время сеанса пользователя. При включении 652 флага трассировки при запуске, флаг трассировки имеет глобальную область действия. При включении флага трассировки 652 в сеансе пользователя, флаг трассировки имеет областью действия сеанса. Если включить флаг трассировки 652 SQL Server больше не приносит страниц базы данных в буферном пуле перед просмотры потребляются этих страниц базы данных. Если включить флаг трассировки 652 запросы, которые выигрывают от функции pre-fetching страницы демонстрировать низкой производительности.

661 Флаг трассировки: отключить процесс удаления записей призрак
	Флаг трассировки 661 отключает процесс удаления записей ghost. Фантомная запись является результатом операции удаления. При удалении записи, удаленные записи сохраняются как фантомная запись. Позже удаленную запись удаляется, процесс удаления записей ghost. При отключении этого процесса удаленной записи не очищаются. Таким образом не освобождается пространство, которое использует удаленную запись. Данное поведение влияет на производительность операций сканирования и расход места на диске. 

	При включении флага трассировки 661 при запуске или во время сеанса пользователя, флаг трассировки 661 всегда применяется на сервере и имеет глобальную область действия. Если выключить этот флаг трассировки фантомных записей процесса удаления работает правильно.

834 Флаг трассировки (big pages): выделения больших страниц использовать Microsoft Windows для буферного пула/large page
	Флаг трассировки 834 приводит к SQL Server на использование выделения больших страниц Microsoft Windows для памяти, выделенной для буферного пула. Размер страницы зависит от аппаратной платформы, но размер страницы может быть от 2 МБ до 16 МБ. Большие страницы выделяются при запуске и сохраняются в течение всего процесса. Флаг трассировки 834 повышает производительность за счет увеличения эффективности буфера ассоциативные трансляции (TLB) в ЦП.
	
	the normal page size for Windows memory is 4Kb on x64 systems. But with large pages, the size is 2Mb.
	
	- Large page support is enabled on Enterprise Edition systems when physical RAM is >= 8Gb (and lock pages in memory privilege set)
	- SQL Server will allocate buffer pool memory using Large Pages on 64bit systems if Large Page Support is enabled and trace flag 834 is enabled
	- Large page for the buffer pool is definitely not for everyone. You should only do this for a machine dedicated to SQL Server (and I mean dedicated) and only with careful consideration of settings like ‘‘max server memory’. Furthermore, you should test out the usage of this functionality to see if you get any measureable performance gains before using it in production.
	- SQL Server startup time can be significantly delayed when using trace flag 834.
	
	- https://blogs.msdn.microsoft.com/psssql/2009/06/05/sql-server-and-large-pages-explained/
	
	-- Особенности
		-- будьте внимательны, для включения требуется указать Max Server Memory меньше чем есть памяти на сервере, иначе сервер не сможет использовать большие страницы в памяти
		-- Запуск SQL Server будет более долгим, так как ему потребуется отъесть всю память
	
	-- Когда использовать
		
		SQL Server Enterprise Edition
		The computer must have 8Gb or more of physical RAM
		The “Lock Pages in Memory” privilege is set for the service account.
		
	-- Как понять что работает
		-- Обязательно требует перезагрузку SQL		
		2009-06-04 12:21:08.16 Server      Large Page Extensions enabled. 
		2009-06-04 12:21:08.16 Server      Large Page Granularity: 2097152 
		2009-06-04 12:21:08.21 Server      Large Page Allocated: 32MB
		
		select large_page_allocations_kb, locked_page_allocations_kb from sys.dm_os_process_memory

	Флаг трассировки 834 применяется только к 64-разрядной версии SQL Server. Необходимо иметь Блокировка страниц в памяти Включите флаг трассировки 834 право пользователя. Можно включить флаг трассировки 834 только при запуске.

	Флаг трассировки 834 может предотвратить запуск фрагментации памяти и не может быть выделена больших страниц сервера. Таким образом флаг трассировки 834 лучше всего подходит для серверов, предназначенной для SQL Server.

	Для получения дополнительных сведений о поддержке больших страниц в Windows посетите следующий веб-узел Microsoft Developer Network (MSDN):
	http://msdn2.Microsoft.com/en-us/library/aa366720.aspx
	(http://msdn2.microsoft.com/en-us/library/aa366720.aspx) 

836 Флаг трассировки: параметр max server memory для буферного пула
	Флаг трассировки 836 приводит к размер буферного пула на основе значения при запуске сервера SQL Максимальный размер памяти сервера вместо параметра в зависимости от физической памяти. Флаг трассировки 836 можно использовать для уменьшения количества дескрипторы буфера, которые выдаются при запуске в 32-разрядном режиме Address Windowing Extensions (AWE).

	Флаг трассировки 836 применяется только для 32-разрядных версий SQL Server с распределением расширения AWE включены. Можно включить флаг трассировки 836 только при запуске.

2301 Флаг трассировки: включить дополнительные решения оптимизации поддержки
	Флаг трассировки 2301 позволяет дополнительно оптимизации, которые являются специфическими для запросов поддержки принятия решений. Этот параметр применяется для поддержки принятия решений обработки больших наборов данных. 


	Можно включить флаг трассировки 2301 при запуске или во время сеанса пользователя. При включении флага трассировки 2301 при запуске, флаг трассировки имеет глобальную область. При включении флага трассировки 2301 в сеансе пользователя, флаг трассировки имеет областью действия сеанса.
	Флаги, отключающие различные кольца буферов трассировки
	Буфер обмена — это внутренний механизм диагностики в SQL Server, который можно использовать для записи дополнительной информации о сервере. Как правило использовать эту информацию для устранения неполадок сервера. Может просматривать содержимое буферов обмена с помощью sys.dm_os_ring_buffers динамическое административное представление.

	Отключение кольцевого буфера обычно улучшает производительность. Однако отключение кольцевого буфера исключает диагностических сведений, использующая службу технической поддержки Майкрософт и может помешать успешной устранения неполадок. 

	Следующие флаги трассировки отключить различные кольцевые буферы.

Флаг 8011 трассировки: отключение кольцевого буфера для монитора ресурсов
	Флаг трассировки 8011 отключает коллекции дополнительные диагностические сведения для монитора ресурсов. Можно использовать данные в буфер обмена для выявления условий нехватки памяти. Флаг трассировки 8011 всегда применяется на сервере и имеет глобальную область действия. Можно включить флаг трассировки 8011 при запуске или во время сеанса пользователя.
	Флаг 8012 трассировки: отключение кольцевого буфера для планировщики
	SQL Server записывает события в буфере обмена расписание, каждый раз, когда происходит, что один из следующих событий:
	•Планировщик переключает контекст на другую.
	•Исполнитель находится в приостановленном состоянии.
	•Исполнитель возобновляется.
	•Исполнитель переходит в режиме или режиме с вытеснением.
	Диагностические сведения в буфер обмена можно использовать для анализа проблем с планированием. Например можно использовать данные в буфер обмена для устранения неполадок, когда SQL Server перестает отвечать на запросы.

Флаг 8012 отключает запись событий трассировки для планировщиков. Можно включить флаг трассировки 8012 только при запуске.

Флаг 8018 трассировки: отключение буфера для исключения

Флаг 8019 трассировки: отключение коллекции стека для исключения кольцевого буфера
	Исключение кольцевого буфера записи последнего 256 исключения, возникающие на узле. Каждая запись содержит некоторые сведения об ошибке, а трассировка стека. Запись добавляется в буфер обмена при возникновении исключения. 

	Отключает флаг трассировки 8018 создания кольцевого буфера и записывается информация не исключение. Трассировка сбора стека 8019 отключает флаг во время создания записи. Флаг трассировки 8019 не оказывает влияния, если включен флаг трассировки 8018. Отключение буфера для исключения усложняет для диагностики проблем, связанных с ошибками внутреннего сервера. Включите флаг трассировки 8018 и флага трассировки 8019 только при запуске.

	Флаг 8020 трассировки: отключение рабочего набора наблюдения
	SQL Server использует размер рабочего набора, когда SQL Server интерпретирует сигналы состояния глобальной памяти операционной системы. Флаг трассировки 8020 удаляет размер рабочего набора из рассмотрения, когда SQL Server интерпретирует сигналы состояния глобальной памяти. Неправильное использование этого флага трассировки большой файл подкачки и низкой производительности. Таким образом прежде чем включить флаг трассировки 8020 в службу поддержки корпорации Майкрософт.

	Можно включить флаг трассировки 8020 только при запуске.

Флаг 8744 трассировки: отключить предварительное диапазонов
	Флаг трассировки 8744 отключает предварительное для Вложенные циклы оператор. Неправильное использование этого флага трассировки может вызвать дополнительных физических чтений, когда SQL Server выполняет планы, содержащие Вложенные циклы оператор. Для получения дополнительных сведений о Вложенные циклы оператор, см. в разделе «Логических, так и физические операторы ссылки» в электронной документации по SQL Server 2005.

	Можно включить флаг трассировки 8744 при запуске или во время сеанса пользователя. При включении флага трассировки 8744 при запуске, флаг трассировки имеет глобальную область. При включении флага трассировки 8744 в сеансе пользователя, флаг трассировки имеет областью действия сеанса.