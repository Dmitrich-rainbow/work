-- Индексы
	- Неотсортированные данные называеются - Heap(куча), отсортированные - (...Индекс)
	- HAVING нельзя ускорить, так как мы оперируем данными, которых на самом деле нет (виртуальные)
	- IAM (Idex Allocation map) у каждой секции таблицы есть IAM, который указывает где именно на диске находятся 8кб стр. от данной секции
	  (вариант когад нет кластерного индекса). Если он есть - То IAM ссылается на 8кб страницу, который указывает с 1-1000 заказ там и так
	  далее, если я выбрал  1-1000, то переходим на следующую страницу, где более точное указание.
	- Leaf Level - листовой элемент, элемент с данными, на которые приходим с указателей, которые описаны выше.
	- Галочка Pad в филфакторе индекса - FF распространяется только на Leaf Level, но не на страницы указателей. Если поставить галочку, то будет распространяться и на них
	- Rebuild index вызывает update statistics, но reorganize нет
	- при плохой селективности, индекс никогда не будет использоваться 
	- Количество уровней в индексе динамично (может быть много корневых уровней)
	- Не использовать слычайные значения в индексе
	- Что надо индексировать
	1. Внешние ключи, так как мы будем пользоваться JOIN
	2. GROUP BY
	3. ORDER BY
	4. WHERE 
	5. LIKE, но только для LIKE 'abc%', если будет LIKE '%abc', то надо создать вычисляемое поле REVERSE() и по нему индекс
	- Хорошо
	1. Если строим по тем полям, по которым ищем
	2. Если строим как можно более короткий
	3. Если строим по полю, которое только увеличивается (не надо будет делать Page Split(разрыв страницы))
	4. Поля, которые занимают мало байт
	- Плохо
	1. Если строим по тем полям, которые надо DELETE, UPDATE, INSERT

-- Важно
	- http://sqlblog.com/blogs/kalen_delaney/archive/2008/03/16/nonclustered-index-keys.aspx
	- http://sqlblog.com/blogs/kalen_delaney/archive/2010/03/07/more-about-nonclustered-index-keys.aspx
	- Поля любого индекса всегда должны быть уникальны. Если мы создаём неуникальный кластерный индекс, то к нему всегда добавляется поле uniqueifier. Данное поле нельзя увидеть, получается неуникальный кластерный индекс является составным индексом
	- Если на таблице есть уникальный кластерный индекс, то для поддержания уникальности он добавляется ко всем индексам, в уникальный добавлется в листовой уровень, но не в key.
	- С неуникальным кластерным индексом добавляется к неуникальному некластерному индексу не только ключ кластерного, но и кевидимое поле uniqueifier, к уникальному кластерному индексу добавляются поля кластерного только в лиф левел, но не в key (добавляется для того, чтобы можно было найти страницы индекса в таблице)
	- Разница в размещении особенно разметна на уровне выше. В случае неуникального некластерного индекса все поля присутствуют(даже uniqueifier), в случае уникального некластерного индекса присутствует только включённый в индекс ключ
	- Бывает, что Tunig Advizor во время анализа не подчищает за собой фейковые индексы, их приходится удалять в ручную (_dta_stat_8439154_2_8_1)
	
-- Опции
	1. allow_page_locks
		- При выставлении параметра в OFF, может привести к фрагментации
	
-- Составной индекс
1. Если используем несколько полей (составной индекс), то тогда фильтруется по первому полю, затем по последующим, поэтому всегда лучше
   первым ставить то поле, которое максимально сузить круг поиска, то есть то, чего намного больше. Но при этом в запросе надо в условии
   WHERE обязательно указывать такой же порядок, как был в составном индекса

-- Некластерный индекс
	- При наличии кластерного индекса хранит всё его значение в каждом индексе
	- Include columns, стоит добавлять, если мало используем update/delete/insert, очень хорошо на хранилищах данных
	- При переполнении страницы создаётся новая и туда переносится половина данных, плюс добавляется ссылка на перенесённые данные
	- При создании некластерного индекса, root level ссылается на некластерный индекс, а некл. индекс ссылается на кластерный и чтобы достучаться до данных, нам нужно будет 3 IO (root >> non-clustered >> data-clustered)
	1. В нём хранятся поля, которые добавили в индекс + поля кластерного индекса (это можно обойти, если включить нужные поля в
	некластерный индекс через Include, но эти поля не будут сортироваться, будут лежать там для балласта)
	2. Используем для вшених ключей, так как будем делать JOIN и это сильно ускорится
	3. Поля которые используем в WHERE, ORDER BY, GROUP BY
	4. Если результатов вывода очень много (например 65000), то серверу быстрее просканировать(Scan) основную таблицу/кластерный индекс,
	   чем делать 65000 Seek к кластреному индексу, так как поиск то мы ускорили и строки нашлись быстро, а вот то, что надо вывести
	   находится в основной таблице и надо перейти 65000 на указатели. В данном случае сервер смотрит на статистику и решает, если мне надо
	   будет вывести примерно более 1% всех строк, то лучше он сделаем Scan
	5. Хорош, когда надо вывести в результате немногострок, если надо будет много, то будет Scan по таблице. Но решение есть - INCLUDE
	   или кластерный индекс по этому полю
	   

   
-- Запретить сохранение изменений, требующих повторного создания таблицы
	- В SSMS меню Сервис-Параметры-Desinger убери галочку запретить сохранение изменений, требующих повторного создания таблицы

-- HEAP	
	- index_id = 0 (Heap) в sys.indexes
	- Некластерный индекс хранит ссылку на страницы данных
	- С 2008 можно делать REBUILD, но всем некластерным индексам необходимо будет обновить ссылку на строки в куче
	- PFS определяется процентами
		1. 0%
		2. 1-50
		3. 51-80
		4. 81-95
		5. 96+
	- Минусы
		1. Доп. операции из-за указателей. Не рекомендуется где происодит модификация данных, так как появляются указатели
		2. неоптимальный контроль свободного места на страницах
		3. При удалении распределение данных происходит крайне не эффективно и может получится так, что заполенение страниц будет менее 1%
		4. При модификации таблицы, блокирует всю таблицу
		5. Больше lock
	- Плюсы
		1. Создано для быстрой загрузки данных (DWH)	
		
	- Посмотреть заполнение страниц индекса и количество ссылок внутри кучи
		SELECT alloc_unit_type_desc,
		index_depth, page_count, avg_page_space_used_in_percent,
		record_count, forwarded_record_count
		FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('TAXUNCOMMITTED'), 0, NULL,'detailed');
		
	- Посмотреть как часто переходят по ссылкам куче (информация увеличивается при каждом переходе forwarded_fetch_count)
			select leaf_insert_count, leaf_update_count, forwarded_fetch_count
			from sys.dm_db_index_operational_stats(db_id(),object_id('TAXUNCOMMITTED'),0,null);
			
	- Размер всех таблиц HEAP
			WITH table_space_usage ( schema_name, table_name, used, reserved, ind_rows, tbl_rows ) 
			AS (
			SELECT 
				s.Name 
				, o.Name 
				, p.used_page_count * 8 / 1024
				, p.reserved_page_count * 8 / 1024
				, p.row_count 
				, case when i.index_id in ( 0, 1 ) then p.row_count else 0 end 
			FROM sys.dm_db_partition_stats p 
				INNER JOIN sys.objects as o ON o.object_id = p.object_id 
				INNER JOIN sys.schemas as s ON s.schema_id = o.schema_id 
				LEFT OUTER JOIN sys.indexes as i on i.object_id = p.object_id and i.index_id = p.index_id 
			WHERE o.type_desc = 'USER_TABLE' and o.is_ms_shipped = 0 and i.index_id = 0
				) 

			SELECT t.schema_name 
					, t.table_name 
					, sum(t.used) as used_in_mb 
					, sum(t.reserved) as reserved_in_mb
					,sum(t.tbl_rows) as rows 
			FROM table_space_usage as t 
			GROUP BY t.schema_name , t.table_name 
			ORDER BY used_in_mb desc	
			
-- INSERT	
	-- HEAP
		- В любое свободное место
	-- Index 
		- В порядке сортировки индекса
			
-- Кластерный индекс
	- При переполнении страницы создаётся новая и туда переносится половина данных, плюс добавляется ссылка на перенесённые данные
	- A clustered index CANNOT be rebuilt as an online operation IF the table has ANY LOB columns in it at all
	- Стоит делать всегда, так как это упорядочивает таблицы и поиск происходит намного быстрее, не через Scan (самый медленный),
	а через Seek, намного быстрее
	- Стоит делать поле для кластерного индекса наиболее короткое, так как оно подствляется во все остальные индексы
	- Кластеризованные индексы зачастую позволяют ускорить выполнение операций UPDATE и DELETE
	- Создание или изменение кластеризованного индекса может занимать продолжительное время, поскольку именно во время этих операций строки таблицы реорганизуются на диске.
	- Помогает при секционировании
	- Кластеризованные индексы сортируют и хранят строки данных в таблице, основываясь на их ключевых значениях. Может быть только один кластеризованный индекс на таблицу, потому что сами строки данных могут быть отсортированы
	только в одном порядке
	- Лучше в данный индекс включать как можно меньше столбцов
	- Ключ кластерного индекса будет дублируется во всех некластерных, чтобы можно было легко перейти в кластерный при Key Look Up
	- Когда использовать:
		1. Для столбцов, которые содержат ограниченное количество уникальных значений, например столбца state,
		   где хранятся	50 уникальных кодов штатов.
		2. Для запросов, которые возвращают диапазон значений, с использованием таких операторов,
		   как BETWEEN, >, >=, <, и <=.
		3. Для запросов, возвращающих большие результирующие наборы.
		4. ORDER BY или GROUP BY.
		5. Часто используются для сортировки данных, полученных из таблицы.
		6. Справочников, которые вообще никогда не меняются. 
		7. OLTP таблиц, в которые идет вставка с автоинкрементом 
		   первичного ключа 
	- Когда не использовать:
		1. Столбцов, которые подвергаются частым изменениям
		2. Составные ключи
		3. OLTP таблиц, в которых происходит модификация первичного ключа. 
		4. Ключ не уникальный, можно создать, но тогда сервер сам добавит к повторяющимся записям доп. идентификатор
	- В куче у нас есть только 1 уровень, когда создаём кластерный индекс, у нас появляется уровень root, в котором мы храним все ссылки intemedia page, то есть, чтобы обратиться к данным, нам уже нужно сделать 2 IO, а не 1, как в куче
	- Если мы удаляем и создаём заного кластерный индекс, то будут перестроены все некластерные индексы, но если нам нужно просто поменять структуру индекса, то можно использовать параметр DROP_EXISTING, чтобы не перестраивать некластерные индексы дважды
	
	-- Идеальный CI
		1. Статичность
		2. Малый размер
		3. Уникальный 
	
	-- Особенности
		1. Не подвержен фрагментации если не происходит добаление/обновление столбцов
		2. Чем больше размер кластерного ключа, тем больше размер таблицы, при 900 байтовом ключе увеличение примерно на 15%

-- Фильтрованный индекс
	- Обычный некластерный индекс с указанием фильтра в настройках
	
-- Индексированное представление
	- http://msdn.microsoft.com/ru-ru/library/ms191432(v=sql.105).aspx
	- Первым индексом, создаваемым для представления, должен быть уникальный кластеризованный индекс. После этого могут быть созданы дополнительные некластеризованные индексы.
	- При удалении кластеризованного индекса удаляются все некластеризованные индексы и автоматически созданные для представления статистики. Статистики, созданные пользователем, сохраняются.
	-- Условия
		- Пользователь, выполняющий инструкцию CREATE INDEX, должен быть владельцем представления.
		- При выполнении инструкции CREATE INDEX должны быть установлены в значение ON следующие параметры SET.
			ANSI_NULLS
			ANSI_PADDING
			ANSI_WARNINGS
			CONCAT_NULL_YIELDS_NULL
			QUOTED_IDENTIFIER
		- Параметр NUMERIC_ROUNDABORT должен быть установлен в OFF. Это установка по умолчанию.
		- Если база данных работает при уровне совместимости 80 или ниже, то параметр ARITHABORT должен быть установлен в значение ON.
		- При создании кластеризованного или некластеризованного индекса параметр IGNORE_DUP_KEY должен быть установлен в OFF (установка по умолчанию).
		- Представление не может содержать столбцы типа text, ntext или image, если даже на них нет ссылок в инструкции CREATE INDEX.
		- Если инструкция SELECT в определении представления содержит предложение GROUP BY, ключ уникального кластеризованного индекса может ссылаться только на столбцы, которые заданы в предложении GROUP BY.
		- Выражение с потерей точности, формирующее значение ключевого столбца индекса, должно ссылаться на хранимый столбец в базовой таблице данного представления. Этот столбец может быть либо обычным, либо материализованным вычисляемым столбцом. Никакие другие выражения с потерей точности не могут быть частью ключевого столбца индексированного представления.

-- SEEK
	- Невозможен при функциях и вычислениях в предикатах над предикатом

-- SCAN	
		
--	Секционирование
	- Каждая секция в non-clustered indexes имеет свою собственную B-tree структуру, основаннуй на схеме секционирования. Не секционированный non-clustered index имеет всего 1 секцию
	- Когда создаём non-clustered index на таблице с секционированием, мы должны явно указать схему секционирования, если укажем файловую группу, то индекс будет обычный
		Create NonClustered Index IX_myIndex On dbo.myTable(myColumn) On [Primary];
	-- Когда лучше работают секционированные индексы (в обычных условиях они проигрывают):
		1. Используется агрегация
		2. Когда большие объёмы данных, особенно на хранилищах данных

-- Создание/CREATE
	- An Sch-M lock is not required for online build of a new nonclustered index, though it is required in all other cases. A new nonclustered index requires only a table-level shared lock during the final phase, same as was needed during the preparation phase.

-- Обслуживание индексов/Обновление/Перестроение
	1. Делайте REBUILD или REBUILD WITH(DROP_EXISTING=ON) вместо DROP/CREATE INDEX (http://www.kendalvandyke.com/2010/09/index-operations-showdown-drop-create.html  ;   http://www.sqlskills.com/blogs/kimberly/content/binary/indexesrightbalance-defrag.pdf?e193aa ; http://www.patrickkeisler.com/2013/03/t-sql-tuesday-40-proportional-fill.html)
	2. WITH (ONLINE=ON)	-- http://msdn.microsoft.com/ru-ru/library/ms190981(v=sql.105).aspx
		- Когда во время этой операции происходит сильная утилизация CPU, необходимо обновля сначала статистику конкретного индекса, а потом сам индекс, чтобы строился норм план
		- Можно использовать MAXDOP
		- Определяет, будут ли базовые таблицы и связанные индексы доступны для запросов и изменения данных во время операций с индексами. Значение по умолчанию — OFF.
		- Для кластерного индекса, такое перестроение может быть в 5 раз дольше, для некластерного всего на 20-60%
		-- Недостатки
			1. Не работает с image, ntext, and text, xml
			2. Работает на столько дольше, на сколько интенсивней нагрузка на БД (операции обновления), так как проиходит модификация и старого индекса и нового
			3. Увеличивается потреблении ресурсов при вставке, обновлении и удалении
			4. Доступно в Enterprise
	3. REBUILD WITH SORT_IN_TEMPDB
		- Значение по-умочению ON
		- Увеличивает занимаемое пространство на диске
	4. ALLOW_ROW_LOCKS и ALLOW_PAGE_LOCKS 
		- Значение по-умочению ON
		- Если установлено в значение ON, то будет больше блокировок и выполнится быстрее
		
		
	-- Индексы (онлайн)/Indexes online
		- MAXDOP может увеличить фрагментацию WITH ALLOW_PAGE_LOCKS = OFF
		- When you create or rebuild a UNIQUE index online, the index builder and a concurrent user transaction may try to insert the same key, therefore violating uniqueness. If a row entered by a user is inserted into the new index (target) before the original row from the source table is moved to the new index, the online index operation will fail.
		- Although not common, the online index operation can cause a deadlock when it interacts with database updates because of user or application activities. In these rare cases, the SQL Server Database Engine will select the user or application activity as a deadlock victim.
		- You can perform concurrent online index DDL operations on the same table or view only when you are creating multiple new nonclustered indexes, or reorganizing nonclustered indexes. All other online index operations performed at the same time fail. For example, you cannot create a new index online while rebuilding an existing index online on the same table.
		- Generally, disk space requirements are the same for online and offline index operations. An exception is additional disk space required by the temporary mapping index. This temporary index is used in online index operations that create, rebuild, or drop a clustered index. Dropping a clustered index online requires as much space as creating a clustered index online.
	
	-- Sort_In_Tempdb
		- Хранятся промежуточные результаты сортировки
		- Требуется доп место
		- If a sort operation is not required, or if the sort can be performed in memory, the SORT_IN_TEMPDB option is ignored.
		- Можно использовать чтобы меньше загружать лог основной БД
	
	-- Требуемое место для обслуживания индексов
		- Размер старого индекса, размер нового и размер в tempdb, если стоит Sort_In_Tempdb
		The following index operations require no additional disk space:
			- ALTER INDEX REORGANIZE; however, log space is required.
			- DROP INDEX when you are dropping a nonclustered index.
			- DROP INDEX when you are dropping a clustered index offline without specifying the MOVE TO clause and nonclustered indexes do not exist.
			- CREATE TABLE (PRIMARY KEY or UNIQUE constraints)
		The following index DDL operations create new index structures and require additional disk space:
			- CREATE INDEX
			- CREATE INDEX WITH DROP_EXISTING
			- ALTER INDEX REBUILD
			- ALTER TABLE ADD CONSTRAINT (PRIMARY KEY or UNIQUE)
			- ALTER TABLE DROP CONSTRAINT (PRIMARY KEY or UNIQUE) when the constraint is based on a clustered index
			- DROP INDEX MOVE TO (Applies only to clustered indexes.)
	
	-- Сравнение с Oracle
		- Нет кластера на несколько таблиц. В данном случае будет построен объект, который объеденит 2 таблицы в одном кластере
		
	
-- *****ФРАГМЕНТАЦИЯ***** --
	- Когда физический порядок, не совпадает с логическим
	- она замедляет упреждающее чтение во время просмотра индекса. В результате этого увеличивается время ответа
	-  That is a 12% increase of read time for a 1% fragmentation
	- Если используется высокая доступность (HAG, Always On), подумать стоит ли выполнять устранение фрагментации, так как из-за этого может генерироваться много лога, что повлечёт за собой отставание реплик. Не страшно производить это в окна

	-- Причины плохой фрагментации кластерного индекса
		1. Его просто нет и база находится в режиме кучи (heap)
		2. Индекса маленький
		3. К тому времени, когда индексы перестроились он уже снова стал фрагментирован из-за большой нагрузки
		4. GUID
		5. Плохо настроенный FILLFACTOR
		6. Обновление длины колонки
		7. Использование столбцов большого фиксированного размера. Например фиксированный размер строки 5000 байт, на страницу мы сможем поместить только 1 такую строку и 3000 байт останется пустым
		8. Даже удаление может вызывать фрагментацию
		9. Версионность, каждой строке в самых данных добавляется 14 байт и приводит к фрагментации
		10. Триггеры, когда происходит модификация любого поля и есть большой столбец (nvarchar(max)), то есть когда значение может быть не только на 1 странице
			- Сервер добавляет 14 байт чтобы хранить информацию о версионности в tempdb
			- При этом может возникнуть ситуация, когда мы добавляем триггер на удаление и ничего в нём неделаем, удаляем данные, а количество страниц фактически увеличивается
		11. Модификация записи на больший размер
		
	-- Дополнительные причины фрагментации
		Don’t think that because you’re avoiding using GUIDs as cluster keys and avoiding updating variable-length columns in your tables then your clustered indexes will be immune to fragmentation. As I’ve described above, there are other workload and environmental factors that can cause fragmentation problems in your clustered indexes that you need to be aware of.

		Now don’t knee-jerk and think that you shouldn’t delete records, shouldn’t use snapshot isolation, and shouldn’t use readable secondaries. You just have to be aware that they can all cause fragmentation and know how to detect, remove, and mitigate it.
	
	-- Минусы фрагментации
		- Как дорог page split http://www.sqlskills.com/blogs/paul/how-expensive-are-page-splits-in-terms-of-transaction-log/
		- На оригинальном месте оставляет указатель (16 байт) на новое место (HEAP)
			- Это облегчает работу некластерного индекса
			- Избавление от повторного, ненужного чтения
			- Доп. время на переходы по указателям
		-- Посмотреть где и сколько указателей
			SELECT * FROM  SYS.dm_db_index_physical_stats(NULL,NULL,NULL,NULL,'DETAILED') WHERE forwarded_record_count > 0
		1. Занимает больше места, из-за page split, так как оставляет много свободного места позади
		2. Плохо влияет на забор данных
		3. Так как такой индекс занимает больше места, при подъёме в память он так же будет заниматься больше памяти
		4. Page split производит много логируемых транзакций
		
	-- Когда плоха фрагментация
		Фрагментация так страшна только при сканировании
			- она плоха при пакетных операциях
			- тратим больше памяти, чтобы держать эти пустые страницы в памяти
		
	- Посмотреть как устроено распределение страниц в в индексе (SQL Server 2012)
		SELECT * FROM sys.dm_db_database_page_allocations(DB_ID(),OBJECT_ID(N'dbo.Cat_Claim.IX_Cat_Claim_v2_1'),NULL,NULL,'DETAILED')
		WHERE page_type_desc='INDEX_PAGE' --and page_level = 0	
		
	-- Rebuild
		- В режиме журналирования FUll сильно использует файл лога. Желательно переключать на bulk logged в момент перестроения
		- Параллелиться только в Enterprise версии, можно указать MAXDOP, если не достаточно уровня сервера
		
	-- Reorganize
		- В режиме журналирования FUll не очень сильно использует файл лога. Желательно переключать на bulk logged в момент перестроения
		- Однопоточная операция		
		- if you happen to stop in the middle, it will roll back that particular page which is 8kb and not the whole thing.
	
	-- sys.dm_db_index_physical_stats
		- sys.dm_db_index_physical_stats(DB_ID(), null, null, null, null) -- Значеие последнего параметра (mode) по умолчанию LIMITED. 2 - object_id, 3 - index_id, 4 - partition_number
	
	-- Статистика по индексам
		dbcc showcontig
		dbcc showcontig ('dbo.OffersConditions',2) -- Можно указать объект. 2 - index id
			Extent Switches -- Как много Extent пришлось просмотреть, чтобы выбрать все
			Logical Scan Fragmentation and Extent Scan Fragmentation -- Отображает как хорошо отсортированы данные если присутствует Кластерный индекс
			Логическая фрагментация -- Это процент неупорядоченных страниц конечного уровня индекса. Неупорядоченной называется страница, для которой следующая физическая страница, выделенная для индекса, не является страницей, на которую ссылается указатель следующей страницы в текущей конечной странице.
			
	-- Информация о индеексе/распределение странц индекса/внутренности индекса
		TRUNCATE TABLE sp_index_info 
		INSERT INTO sp_index_info 
			EXEC ('DBCC IND ( testdb, Sales, -1)'  ); 
		GO

		SELECT PageFID, PagePID, IndexID 
		FROM sp_index_info 
		WHERE IndexID > 1 AND IndexLevel > 0 
		  AND PrevPagePID = 0 
		ORDER BY IndexID; 
		GO

		Here are my results:
		PageFID PagePID     IndexID 
		------- ----------- ------- 
		1       4056        2 
		1       904         3 
		1       1888        4

		Now use DBCC PAGE to look at each of these pages
		DBCC TRACEON (3604); 
		DBCC PAGE(testdb, 1, 4056, 3); 
		DBCC PAGE(testdb, 1, 904, 3); 
		DBCC PAGE(testdb, 1, 1888, 3);
	
	-- Узнать % фрагментации индексов в таблице/дефрагментация индексов
		SELECT a.index_id, name, avg_fragmentation_in_percent
		FROM sys.dm_db_index_physical_stats (DB_ID(N'WWWBRON'), OBJECT_ID(N'WWWBRON.dbo.Cat_Claim'), NULL, NULL, NULL) AS a
			JOIN sys.indexes AS b ON a.object_id = b.object_id AND a.index_id = b.index_id; 
	
	-- Увидеть фрагментацию в PerfMon
		 - Счетчики монитора производительности Avg Disk Bytes/Transfer, Avg Disk Bytes/Read и Avg Disk Bytes/Write сообщают, сколько байтов задействуется при каждой операции ввода/вывода. Буфера диска гарантируют, что база данных SQL Server никогда не будет иметь менее чем 8196 байт за оборот диска, но что нам нужно, так это последовательные 65,536 (или более) байт за оборот (65,536 байт, или 64 Кбайт). Если вы видите, что данная величина меньше, чем 65,536, значит, возникли проблемы с фрагментацией данных.
		 - Если монитор производительности показывает чрезмерное количество операций ввода/вывода, о чем это говорит? И если FileMon показывает по крайней мере 65,536 байт при выполнении ввода/вывода? Это означает, что файл самой базы данных фрагментирован.
		
	-- Уменьшение/Устранение
		- Решение для новых баз данных состоит в предоставлении с учетом роста достаточного места для создания базы данных. Если диск недавно отформатирован, NTFS предоставит все место в одной непрерывной области диска. После этого можно использовать команды DBCC и перестраивать индексы для минимизации фрагментации.
		- Более эффективное решение для уже существующих баз данных следующее: выполнить полное резервирование базы данных, удалить базу данных (с удалением файлов), дефрагментировать диск, затем восстановить базу данных. Процесс восстановления заставит Windows выделять дисковое пространство из самых больших доступных порций свободной дисковой памяти, поэтому страницы будут непосредственно на диске, скорее всего физически непрерывны. В итоге компонент ввода/вывода должен упорядочивать запросы на страницы более эффективно, потому что диспетчер может получить доступ к большим фрагментам данных при единственной операции ввода/вывода.
		- Установка FILL FACTOR
	
	-- Фрагментация индексов базы
		SELECT 
			dm.database_id, 
			tbl.name, 
			dm.index_id, 
			idx.name, 
			dm.avg_fragmentation_in_percent,    
			idx.fill_factor
		FROM sys.dm_db_index_physical_stats(DB_ID(), null, null, null, 'LIMITED') dm -- Вместо LIMITED можно указать DETAILED, но тогда нужно будет ограничить index_level = 0, иначе будет замножение, так как у индекса есть разные уровни (0 - Leaf Level, 1 - intermedia, 2 - Root)
			INNER JOIN sys.tables tbl ON dm.object_id = tbl.object_id
			INNER JOIN sys.indexes idx ON dm.object_id = idx.object_id AND dm.index_id = idx.index_id
		WHERE page_count > 8
			AND avg_fragmentation_in_percent > 15
			AND dm.index_id > 0
			AND tbl.name not like '%$%'	
			
	-- Глубокаяя информация об индексе/информация о индексе
		SELECT [ps].[index_id], [i].[name] [Index], [ps].[index_type_desc], 
		[ps].[index_depth], [ps].[index_level], [ps].[page_count], [ps].[record_count]
		FROM [sys].[dm_db_index_physical_stats](DB_ID(), OBJECT_ID('Sales.Big_SalesOrderHeader'), 5, NULL, 'DETAILED') [ps]
		JOIN [sys].[indexes] [i] ON [ps].[index_id] = [i].[index_id] 
			AND [ps].[object_id] = [i].[object_id];	
			
	-- Интресно
		Таким образом для перестройки всех индексов таблицы достаточно выдать команду для перестройки одного кластерного индекса. Это утверждение верно, если вы удаляете и создаёте заного кластерный индекс

	-- Дефрагментация индекса. Не так эффективно, зато занимает мало времени и накладывает кратковременные блокировки (онлайн)
		DBCC INDEXDEFRAG (AdventureWorks2012, "Production.Product", PK_Product_ProductID)
	 
	-- Перестроение индексов во всей таблице с фил фактром 70
		USE AdventureWorks2012; 
		GO
		DBCC DBREINDEX ('HumanResources.Employee', ' ', 70);
		GO

-- Как планировать индексы
	1. По горизонтали все столбцы
	2. По вертикали все хранимые процедуры, которые хоть как-то взаимодействуют с таблицей
	3. На пересечении надо описать что делает каждая процедура с каждым из стобцом
	4. Потом выделяем что для нас очень важно, какие процедуры
	5. Надо выявить чем можем пожертвовать
	6. На основе этого создаём индексы

		
-- Найти в каких планах используется выбранный индекс/Поиск индекса в планах/index in plan/использование индексов
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
	query_plan 
	FROM sys.dm_exec_cached_plans AS cp 
	CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
	CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS batch(stmt) 
	CROSS APPLY stmt.nodes('.//IndexScan/Object[@Index=sql:variable("@IndexName")]') AS idx(obj) 
	OPTION(MAXDOP 1, RECOMPILE);
	
-- Размеры бд, индексов и иные
	exec sp_spaceused - информация по базе

-- Информация по индексу
	select * from sysindexes
	select * from sys.indexes
	
-- Статистика по индексам в текущей базе
	SELECT OBJECT_NAME(s.[object_id]) AS [ObjectName], i.name AS [IndexName], i.index_id,
		   user_seeks + user_scans + user_lookups AS [Reads], user_updates AS [Writes],
		   i.type_desc AS [IndexType], i.fill_factor AS [FillFactor]
	FROM sys.dm_db_index_usage_stats AS s
	INNER JOIN sys.indexes AS i
	ON s.[object_id] = i.[object_id]
	WHERE OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
	AND i.index_id = s.index_id
	AND s.database_id = DB_ID()
	ORDER BY OBJECT_NAME(s.[object_id]), writes DESC, reads DESC;
	
-- sys.dm_fts_index_population which BOL describes as:
	- Returns information about the full-text index populations currently in progress.
	
	-- Что происходит с full-text в текущей БД
		SELECT c.name, c.[status], c.status_description, OBJECT_NAME(p.table_id) AS [table_name], 
		p.population_type_description, p.is_clustered_index_scan, p.status_description, 
		p.completion_type_description, p.queued_population_type_description, 
		p.start_time, p.range_count 
		FROM sys.dm_fts_active_catalogs AS c 
		INNER JOIN sys.dm_fts_index_population AS p 
		ON c.database_id = p.database_id 
		AND c.catalog_id = p.catalog_id 
		WHERE c.database_id = DB_ID()
		ORDER BY c.name;
		
-- *****УПЩЕННЫЕ ИНДЕКСЫ/НЕДОСТАЮЩИЕ ИНДЕКСЫ*****
	-- Ограничения
		https://technet.microsoft.com/en-us/library/ms345485.aspx?f=255&MSPPError=-2147217396
	- Обратить внимание на то, когда была последний seek, если он был очень давно, то возможно этот индекс вам не нужен, так как он мог показаться из-за редкой операции
	- Обратите внимание на user_seeks (количество попыток обращения к данному индексу)
	- Иногда упущенные индексы советую создать по 5 и более индексов на таблицу, не создавайте все 5, вы можете объединить тх
	- Для преобразования сведений, возвращенных представлением sys.dm_db_missing_index_details инструкции CREATE INDEX, столбцы равенства должны быть помещены перед столбцами неравенства, а вместе они должны образовать индекс ключа. Включенные столбцы должны быть добавлены в инструкцию CREATE INDEX с помощью предложения INCLUDE. Чтобы определить эффективный порядок столбцов равенства, разместите столбцы согласно частоте их выборки: перечислите наиболее часто выбираемые столбцы вначале (крайнее левое положение в списке столбцов).
	- Создавайте индексы по колонкам, которые в запросах используются в предложениях: WHERE, ORDER BY, GROUP BY или DISTINCT.
	- Предпочтительнее много коротких, чем один очень длинный индекс.
	
	-- sys.dm_db_missing_index_group_stats, which is described by BOL as:
		- Показывает какие были запросы и как сервер хотел их выполнить, но не получилось
		- Returns summary information about groups of missing indexes, excluding spatial indexes. Information returned by sys.dm_db_missing_index_group_stats is updated by every query execution, not by every query compilation or recompilation. Usage statistics are not persisted and are kept only until SQL Server is restarted. Database administrators should periodically make backup copies of the missing index information if they want to keep the usage statistics after server recycling.

	-- sys.dm_db_missing_index_group_stats and sys.dm_db_missing_index_details. The third one is sys.dm_db_missing_index_details, which BOL describes like this:
		- Returns detailed information about missing indexes, excluding spatial indexes.
		- Подробности смотри в файле Indexes.sql

	-- sys.dm_db_missing_index_groups, which BOL describes as:
		- Нужно только для связи sys.dm_db_missing_index_group_stats и sys.dm_db_missing_index_Details
		- Returns information about what missing indexes are contained in a specific missing index group, excluding spatial indexes.	
	
	-- sys.dm_db_missing_index_Details
		Относится к нехватающим индексам	
		
	-- sys.dm_db_missing_index_columns
		Подробное раскрытие колонок из таблицы sys.dm_db_missing_index_Details. Обратите внимание, где указано в колонке column_usage INEQUALITY
		
	-- Посчитать реальный процент улучшения индексов
		(user_seeks+user_scans)*avg_total_user_cost*avg_user_impact		
		
	-- Поле sys.dm_db_missing_index_details.inequality_columns
		Попробовать переписать запрос, возможно это поле отпадёт. Так же если стоит столбец тут, то не факт что поле "процент выигрыша" будет оценено правильно.
	
	-- *****Самородов Фёдов*****
		-- Посмотреть запросы в кэше (2 разных кода, которые возвращают одинаковые значения). Обычно подразумевается что запрос у вас уже есть
			SELECT CP.objtype,T.text
			FROM Sys.dm_Exec_cached_plans CP
				CROSS APPLY sys.dm_exec_query_plan(CP.plan_handle) QP -- Функции надо подключать через CROSS APPLY
				CROSS APPLY sys.dm_exec_sql_text(CP.plan_handle) T
			WHERE CAST(QP.query_plan as nvarchar(MAX)) LIKE '%<MissingIndexes>%'
			GO
			WITH XMLNAMESPACES(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
			SELECT CP.objtype,T.text
			FROM Sys.dm_Exec_cached_plans CP
				CROSS APPLY sys.dm_exec_query_plan(CP.plan_handle) QP -- Функции надо подключать через CROSS APPLY
				CROSS APPLY sys.dm_exec_sql_text(CP.plan_handle) T
			WHERE QP.query_plan.exist('//MissingIndexes') = 1
			
		-- Третий способ работы с упущенными индексами	
			1. Profiler (можно использовать готовый шаблон Tuning)
			2. Анализируем эффективность с помощью Tuning Advisor	

		-- Статистика недостающих индексов (второй вариант)
			- пкм на базе > Reports > Standart Reports > Index Use Statistics
	
	
	-- *****Glenn Berry*****
		-- Возможные индексы в текущей базе/отсутствующие индексы/упущенные индексы 			
			SELECT user_seeks * avg_total_user_cost * (avg_user_impact * 0.01) AS [index_advantage],  -- При значениие выше 10 000 индекс является обязательным, при значениие более 5000, рекомендуемым
			migs.avg_user_impact as [% выигрыша],
			migs.last_user_seek,
			migs.avg_total_user_cost as [Стоимость запроса],
			migs.user_seeks as [Предполагаемое количество вызовов],
			migs.unique_compiles as [Число компиляций и повторных компиляций],
			mid.[statement] AS [Database.Schema.Table],
			mid.equality_columns, mid.inequality_columns, mid.included_columns, 
			(
			SELECT SUM(au.total_pages) * 8 / 1024  FROM  sys.tables as st WITH (NOLOCK) 
			INNER JOIN sys.partitions as sp WITH (NOLOCK) ON st.object_id = sp.object_id
			INNER JOIN sys.allocation_units as au WITH (NOLOCK) ON au.container_id = sp.partition_id
			INNER JOIN sys.data_spaces as spp WITH (NOLOCK) ON spp.data_space_id = au.data_space_id	
			WHERE  st.object_id = OBJECT_ID(mid.statement)
			group by st.name
			)	as [Размер,мб], -- Чтобы было значение необходимо вызывать в контексте нужной БД
			 [Transact SQL код для создания индекса] = ''+
		  mid.statement + ' (' + ISNULL(mid.equality_columns,'') +
		  (CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ', '
			ELSE '' END) +
		  (CASE WHEN mid.inequality_columns IS NOT NULL THEN + mid.inequality_columns ELSE '' END) + ')' +
		  (CASE WHEN mid.included_columns IS NOT NULL THEN ' INCLUDE (' + mid.included_columns + ')'
			ELSE '' END) +      ';'
			FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
			INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
			ON migs.group_handle = mig.index_group_handle
			INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
			ON mig.index_handle = mid.index_handle
			WHERE mid.database_id = DB_ID()
			ORDER BY index_advantage DESC;


	-- *****Jonathan Kehayias*****
	-- Поиск упущенных индексов в кэше. 
			WITH XMLNAMESPACES  
			   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan') 
				
			SELECT query_plan, 
				   n.value('(@StatementText)[1]', 'VARCHAR(4000)') AS sql_text, 
				   n.value('(//MissingIndexGroup/@Impact)[1]', 'FLOAT') AS impact, 
				   DB_ID(REPLACE(REPLACE(n.value('(//MissingIndex/@Database)[1]', 'VARCHAR(128)'),'[',''),']','')) AS database_id, 
				   OBJECT_ID(n.value('(//MissingIndex/@Database)[1]', 'VARCHAR(128)') + '.' + 
					   n.value('(//MissingIndex/@Schema)[1]', 'VARCHAR(128)') + '.' + 
					   n.value('(//MissingIndex/@Table)[1]', 'VARCHAR(128)')) AS OBJECT_ID, 
				   n.value('(//MissingIndex/@Database)[1]', 'VARCHAR(128)') + '.' + 
					   n.value('(//MissingIndex/@Schema)[1]', 'VARCHAR(128)') + '.' + 
					   n.value('(//MissingIndex/@Table)[1]', 'VARCHAR(128)')  
				   AS statement, 
				   (   SELECT DISTINCT c.value('(@Name)[1]', 'VARCHAR(128)') + ', ' 
					   FROM n.nodes('//ColumnGroup') AS t(cg) 
					   CROSS APPLY cg.nodes('Column') AS r(c) 
					   WHERE cg.value('(@Usage)[1]', 'VARCHAR(128)') = 'EQUALITY' 
					   FOR  XML PATH('') 
				   ) AS equality_columns, 
					(  SELECT DISTINCT c.value('(@Name)[1]', 'VARCHAR(128)') + ', ' 
					   FROM n.nodes('//ColumnGroup') AS t(cg) 
					   CROSS APPLY cg.nodes('Column') AS r(c) 
					   WHERE cg.value('(@Usage)[1]', 'VARCHAR(128)') = 'INEQUALITY' 
					   FOR  XML PATH('') 
				   ) AS inequality_columns, 
				   (   SELECT DISTINCT c.value('(@Name)[1]', 'VARCHAR(128)') + ', ' 
					   FROM n.nodes('//ColumnGroup') AS t(cg) 
					   CROSS APPLY cg.nodes('Column') AS r(c) 
					   WHERE cg.value('(@Usage)[1]', 'VARCHAR(128)') = 'INCLUDE' 
					   FOR  XML PATH('') 
				   ) AS include_columns 
			INTO #MissingIndexInfo 
			FROM  
			( 
			   SELECT query_plan 
			   FROM (    
					   SELECT DISTINCT plan_handle 
					   FROM sys.dm_exec_query_stats WITH(NOLOCK)  
					 ) AS qs 
				   OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) tp     
			   WHERE tp.query_plan.exist('//MissingIndex')=1 
			) AS tab (query_plan) 
			CROSS APPLY query_plan.nodes('//StmtSimple') AS q(n) 
			WHERE n.exist('QueryPlan/MissingIndexes') = 1 

			-- Trim trailing comma from lists 
			UPDATE #MissingIndexInfo 
			SET equality_columns = LEFT(equality_columns,LEN(equality_columns)-1), 
			   inequality_columns = LEFT(inequality_columns,LEN(inequality_columns)-1), 
			   include_columns = LEFT(include_columns,LEN(include_columns)-1) 
				
			SELECT * 
			FROM #MissingIndexInfo 
			DROP TABLE #MissingIndexInfo
			
	-- Ещё 1 скрипт упущенных индексов
		-- описание https://danieladeniji.wordpress.com/2016/01/20/sql-server-missing-index-using-xpath/
		declare @columnKey sysname
		declare @columnIncluded sysname
		 
		set @columnKey = 'EQUALITY'
		set @columnIncluded = 'INCLUDE'
		 
		;WITH XMLNAMESPACES(DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan')       
		SELECT
				  [UseCountByImpact] =(dec.usecounts * r.node.value('@Impact', 'decimal(32,2)')) 
				, dec.usecounts 
				, dec.refcounts 
				, Impact = r.node.value('@Impact', 'decimal(32, 2)') 
				, dec.objtype 
				, dec.cacheobjtype 
				, [sqlText]= [des].[text] 
				, deq.query_plan  
				, xmlFragment = cast((cast(r.node.query('.') as nvarchar(max)) ) as xml) 
				, [Database] = cast(r.node.query('data(MissingIndex[1]/@Database)') as sysname) 
				, [Schema] = cast(r.node.query('data(MissingIndex[1]/@Schema)') as sysname) 
				, [Table] = cast(r.node.query('data(MissingIndex[1]/@Table)') as sysname)  
				, [ColumnKey] = cast(r.node.query('data(MissingIndex[1]/ColumnGroup[@Usage=sql:variable("@columnKey")]/Column/@Name)') as nvarchar(4000)) 
				, [ColumnIncluded] = cast(r.node.query('data(MissingIndex[1]/ColumnGroup[@Usage=sql:variable("@columnIncluded")]/Column/@Name)') as nvarchar(4000))             
		FROM sys.dm_exec_cached_plans AS dec 
		CROSS APPLY sys.dm_exec_sql_text(dec.plan_handle) AS des  
		CROSS APPLY sys.dm_exec_query_plan(dec.plan_handle) AS deq  
		cross apply deq.query_plan.nodes(N'/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup') as r(node) ORDER BY ((dec.usecounts * r.node.value('@Impact', 'decimal(30,3)'))) desc

	-- Проверить используется ли уже указанная первая колонка в индексе
		-- Найти id колонки (менять оба параметра)
		SELECT * FROM sys.columns WHERE object_name([object_id]) = 'UserFields658' AND name like 'f1[_]%'

		-- Найти используется ли указанная колонка на 1 месте в каком-то индексе в определённой таблице (менять UserFields698 и column_id)
		SELECT object_name(ic.[object_id]),i.name FROM sys.index_columns ic INNER JOIN sys.indexes i ON ic.index_id = i.index_id AND ic.[object_id] = i.[object_id]
		 WHERE object_name(ic.[object_id]) = 'UserFields698' and column_id = 3 AND index_column_id = 1

		
-- *****ИНФОРМАЦИЯ О ИНДЕКСАХ*****
-- sys.dm_db_index_usage_stats
	- Returns counts of different types of index operations and the time each type of operation was last performed. Every individual seek, scan, lookup, or update on the specified index by one query execution is counted as a use of that index and increments the corresponding counter in this view. Information is reported both for operations caused by user-submitted queries, and for operations caused by internally generated queries, such as scans for gathering statistics.
	-- Часть операция сбрасывает информацию из данного представления
		- https://www.littlekendra.com/2016/03/07/sql-server-2016-rc0-fixes-index-usage-stats-bug-missing-indexes-still-broken/
		- Index usage stats is always reset when a database goes offline (that includes restarting the SQL Server or failing the database over)
		- Dropping an index or CREATE with DROP_EXISTING will also reset usage stats
		- In SQL Server 2012, a bug occurred where index rebuilds started resetting index usage stats
		- Перед тем как трогать индекс на продуктивной системе надо обязательно проверить как часто он используется

-- Информация о индексе 
	-- Узнать нужный объект
		SELECT [object_id],index_id FROM sys.indexes WHERE name like '%2_1%'
	
	-- Получить по нему информацию
		select page_count, avg_record_size_in_bytes, avg_page_space_used_in_percent,avg_fragmentation_in_percent
		from sys.dm_db_index_physical_stats(db_id(),229575856,5,null,'DETAILED');

-- Определение полезности индексов (текущая активность IO, блокировки и кратковременные блокировки по секции индекса или таблицы)
	-- Узнать нужный объект
		SELECT [object_id],index_id FROM sys.indexes WHERE name like '%2_1%'
		
	-- Получить по нему информацию
		SELECT * FROM sys.dm_db_index_operational_stats(DB_ID(), 229575856, 5, NULL);	

-- Ожидания по индексам
	select object_schema_name(ddios.object_id) + '.' + object_name(ddios.object_id) as objectName,
			  indexes.name, case when is_unique = 1 then 'UNIQUE ' else '' end + indexes.type_desc as index_type,
			  page_latch_wait_count , page_io_latch_wait_count
	from  sys.dm_db_index_operational_stats(db_id(),null,null,null) as ddios
				 join sys.indexes
							on indexes.object_id = ddios.object_id
								 and indexes.index_id = ddios.index_id
	order by page_latch_wait_count + page_io_latch_wait_count desc
	
-- Размер индекса
	-- Примерный размер (достаточно точный)
		SELECT i.[name] AS IndexName
			,SUM(s.[used_page_count]) * 8 / 1024 / 1024 AS IndexSizeGb
		FROM sys.dm_db_partition_stats AS s
		INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
			AND s.[index_id] = i.[index_id]
		GROUP BY i.[name]
		ORDER BY 2 DESC


	-- Долгий вариант
	 DECLARE @index_id INT
	 SELECT @index_id = index_id 
	 FROM sys.indexes 
	 WHERE object_id = OBJECT_ID('WWWBRON.dbo.Cat_Claim') AND name = 'IX_Cat_Claim_v2_0' -- WWWBRON.dbo.Cat_Claim (таблица), IX_Cat_Claim_v2_0(индекс)
	 
	 SELECT sum(avg_record_size_in_bytes*record_count)/1024/1024
	 FROM sys.dm_db_index_physical_stats (DB_ID(), OBJECT_ID('WWWBRON.dbo.Cat_Claim'), @index_id , NULL, 'DETAILED')
	
-- Самые большие индексы в таблице (leaf level)
	SELECT TOP 10 SO.[object_id]
        , SO.[name] AS TABLE_NAME
        , SI.index_id
        , SI.[name] AS index_name
        , SI.fill_factor
        , SI.type_desc AS index_type
        , ixO.partition_number
        , ixO.leaf_allocation_count
        , ixO.nonleaf_allocation_count
	FROM sys.dm_db_index_operational_stats (db_id(), NULL, NULL, NULL) AS ixO
			INNER JOIN sys.indexes SI 
					ON ixO.[object_id] = SI.[object_id] 
							AND ixO.[index_id] = SI.[index_id] 
			INNER JOIN sys.objects SO ON SI.[object_id] = SO.[object_id]
	ORDER BY ixO.leaf_allocation_count DESC;
	
		
-- Статистика использования индексов таблицы/использование индексов/неиспользуемые индексы
	SELECT sys.indexes.name,sys.dm_db_index_usage_stats.* FROM sys.dm_db_index_usage_stats INNER JOIN
	 sys.indexes ON sys.indexes.object_id=sys.dm_db_index_usage_stats.object_id AND
	 sys.indexes.index_id = sys.dm_db_index_usage_stats.index_id
	 WHERE sys.dm_db_index_usage_stats.object_id =
	 ( SELECT object_id FROM sys.tables where name LIKE '%UserFields700%')
	-- AND sys.indexes.name IN ('IX_omni_f140','IX_omni_F136_f140') -- Выбрать только конкретные индексы
	-- AND user_lookups = 0 AND user_scans = 0 AND user_seeks = 0 -- Не было никакой активности на чтение
	-- AND STATS_DATE(sys.indexes.object_id , sys.indexes.index_id ) > GETDATE() - 30 -- Последнее обновление статистики более месяца назад
	
	-- Последний вариант
		SELECT sys.indexes.name,sys.dm_db_index_usage_stats.*,'ALTER INDEX '+sys.indexes.name+' ON '+ OBJECT_NAME(sys.indexes.object_id) +' DISABLE',*
		FROM sys.dm_db_index_usage_stats INNER JOIN
		 sys.indexes ON sys.indexes.object_id=sys.dm_db_index_usage_stats.object_id AND
		 sys.indexes.index_id = sys.dm_db_index_usage_stats.index_id
		 CROSS APPLY sys.dm_db_index_operational_stats(DB_ID(), sys.indexes.[object_id], sys.indexes.index_id, NULL)
		 WHERE user_lookups = 0 AND user_scans = 0 AND user_seeks = 0 -- Не было никакой активности на чтение
		 -- AND user_lookups + user_scans + user_seeks < user_updateы/10 -- 10 кратное превосходство обновлений над чтениями
		 AND sys.indexes.index_id > 1 -- исключить кластерные ключи
		 AND sys.indexes.is_disabled = 0
		 AND STATS_DATE(sys.indexes.object_id , sys.indexes.index_id ) > GETDATE() - 30 -- Последнее обновление статистики более месяца назад
		

-- Редко используемые индексы по БД
-- Possible Bad NC Indexes (writes > reads)
	SELECT OBJECT_NAME(s.[object_id]) AS [Table Name] , 
	i.name AS [Index Name] , 
	i.index_id , 
	user_updates AS [Total Writes] , 
	user_seeks + user_scans + user_lookups AS [Total Reads] , 
	user_updates - ( user_seeks + user_scans + user_lookups ) 
	AS [Difference],
	user_seeks,
	user_scans,
	user_lookups	,
	(SELECT SUM(p.[used_page_count]) * 8 / 1024 / 1024 AS IndexSizeGb
	FROM sys.dm_db_partition_stats AS p
	WHERE p.[object_id] = i.[object_id]	AND p.[index_id] = i.[index_id]
	GROUP BY p.[object_id]) as index_size
	FROM sys.dm_db_index_usage_stats AS s WITH ( NOLOCK ) 
	INNER JOIN sys.indexes AS i WITH ( NOLOCK ) 
	ON s.[object_id] = i.[object_id] 
	AND i.index_id = s.index_id
	WHERE OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1 
	AND s.database_id = DB_ID() 
	AND user_updates > ( user_seeks + user_scans + user_lookups ) 
	AND i.index_id > 1
	ORDER BY [Difference] DESC , 
	[Total Writes] DESC , 
	[Total Reads] ASC ;
	
	-- Мой метод
		SELECT sys.indexes.name,sys.dm_db_index_usage_stats.*,'ALTER INDEX '+sys.indexes.name+' ON '+ OBJECT_NAME(sys.indexes.object_id) +' DISABLE' FROM sys.dm_db_index_usage_stats INNER JOIN
		 sys.indexes ON sys.indexes.object_id=sys.dm_db_index_usage_stats.object_id AND
		 sys.indexes.index_id = sys.dm_db_index_usage_stats.index_id
		 AND user_lookups = 0 AND user_scans = 0 AND user_seeks = 0 -- Не было никакой активности на чтение
		 -- AND user_lookups + user_scans + user_seeks < user_updateы/10 -- 10 кратное превосходство обновлений над чтениями
		 AND sys.indexes.index_id > 1 -- исключить кластерные ключи
		 AND sys.indexes.is_disabled = 0
		 AND STATS_DATE(sys.indexes.object_id , sys.indexes.index_id ) > GETDATE() - 30 -- Последнее обновление статистики более месяца назад
	
-- Задвоенные индексы/duplicate indexes/похожие/одинаковые
	F:\SQL Scripts\Скрипты\Лишние индексы  -- установить 3 скрипты и воспользоваться вызовом
	
	-- Экспресс
		select
			s.Name + N'.' + t.name as [Table]
			,i1.index_id as [Index1 ID], i1.name as [Index1 Name]
			,dupIdx.index_id as [Index2 ID], dupIdx.name as [Index2 Name] 
			,c.name as [Column]
		from 
			sys.tables t join sys.indexes i1 on
				t.object_id = i1.object_id
			join sys.index_columns ic1 on
				ic1.object_id = i1.object_id and
				ic1.index_id = i1.index_id and 
				ic1.index_column_id = 1  
			join sys.columns c on
				c.object_id = ic1.object_id and
				c.column_id = ic1.column_id      
			join sys.schemas s on 
				t.schema_id = s.schema_id
			cross apply
			(
				select i2.index_id, i2.name
				from
					sys.indexes i2 join sys.index_columns ic2 on       
						ic2.object_id = i2.object_id and
						ic2.index_id = i2.index_id and 
						ic2.index_column_id = 1  
				where	
					i2.object_id = i1.object_id and 
					i2.index_id > i1.index_id and 
					ic2.column_id = ic1.column_id
			) dupIdx     
		order by
			s.name, t.name, i1.index_id
	
	-- Microsoft
		;with IndexColumns AS(
		select distinct  schema_name (o.schema_id) as 'SchemaName',object_name(o.object_id) as TableName, i.Name as IndexName, o.object_id,i.index_id,i.type,
		(select case key_ordinal when 0 then NULL else '['+col_name(k.object_id,column_id) +'] ' + CASE WHEN is_descending_key=1 THEN 'Desc' ELSE 'Asc' END end as [data()]
		from sys.index_columns  (NOLOCK) as k
		where k.object_id = i.object_id
		and k.index_id = i.index_id
		order by key_ordinal, column_id
		for xml path('')) as cols,
		case when i.index_id=1 then 
		(select '['+name+']' as [data()]
		from sys.columns  (NOLOCK) as c
		where c.object_id = i.object_id
		and c.column_id not in (select column_id from sys.index_columns  (NOLOCK) as kk    where kk.object_id = i.object_id and kk.index_id = i.index_id)
		order by column_id
		for xml path(''))
		else (select '['+col_name(k.object_id,column_id) +']' as [data()]
		from sys.index_columns  (NOLOCK) as k
		where k.object_id = i.object_id
		and k.index_id = i.index_id and is_included_column=1 and k.column_id not in (Select column_id from sys.index_columns kk where k.object_id=kk.object_id and kk.index_id=1)
		order by key_ordinal, column_id
		for xml path('')) end as inc
		from sys.indexes  (NOLOCK) as i
		inner join sys.objects o  (NOLOCK) on i.object_id =o.object_id 
		inner join sys.index_columns ic  (NOLOCK) on ic.object_id =i.object_id and ic.index_id =i.index_id
		inner join sys.columns c  (NOLOCK) on c.object_id = ic.object_id and c.column_id = ic.column_id
		where  o.type = 'U' and i.index_id <>0 and i.type <>3 and i.type <>5 and i.type <>6 and i.type <>7 
		group by o.schema_id,o.object_id,i.object_id,i.Name,i.index_id,i.type
		),
		DuplicatesTable AS
		(SELECT    ic1.SchemaName,ic1.TableName,ic1.IndexName,ic1.object_id, ic2.IndexName as DuplicateIndexName, 
		CASE WHEN ic1.index_id=1 THEN ic1.cols + ' (Clustered)' WHEN ic1.inc = '' THEN ic1.cols  WHEN ic1.inc is NULL THEN ic1.cols ELSE ic1.cols + ' INCLUDE ' + ic1.inc END as IndexCols, 
		ic1.index_id
		from IndexColumns ic1 join IndexColumns ic2 on ic1.object_id = ic2.object_id
		and ic1.index_id < ic2.index_id and ic1.cols = ic2.cols
		and (ISNULL(ic1.inc,'') = ISNULL(ic2.inc,'')  OR ic1.index_id=1 )
		)
		SELECT SchemaName,TableName, IndexName,DuplicateIndexName, IndexCols, index_id, object_id, 0 AS IsXML
		FROM DuplicatesTable dt
		ORDER BY 1,2,3

			
-- Количество индексов больше чем колонов/more indexes than columns.
	SELECT DISTINCT
	schema_name(so.schema_id) AS 'SchemaName', 
	object_name(so.object_id) AS 'TableName',
	CASE objectproperty(max(so.object_id), 'TableHasClustIndex')
	WHEN 0 THEN count(si.index_id) - 1
	ELSE count(si.index_id)
	END AS 'IndexCount',
	MAX(d.ColumnCount) AS 'ColumnCount'
	FROM sys.objects so (NOLOCK)
	JOIN sys.indexes si (NOLOCK) ON so.object_id = si.object_id AND so.type in (N'U',N'V')
	JOIN sysindexes dmv (NOLOCK) ON so.object_id = dmv.id AND si.index_id = dmv.indid
	FULL OUTER JOIN (SELECT object_id, count(1) AS ColumnCount FROM sys.columns (NOLOCK) GROUP BY object_id) d 
	ON d.object_id = so.object_id
	WHERE so.is_ms_shipped = 0
	AND so.object_id not in (select major_id FROM sys.extended_properties (NOLOCK) where name = N'microsoft_database_tools_support')
	AND indexproperty(so.object_id, si.name, 'IsStatistics') = 0
	GROUP BY so.schema_id, so.object_id
	HAVING(CASE objectproperty(MAX(so.object_id), 'TableHasClustIndex')
	WHEN 0 THEN COUNT(si.index_id) - 1
	ELSE COUNT(si.index_id)
	END > MAX(d.ColumnCount))


--Ниже представлен небольшой сценарий T-SQL, который возвращает список некластеризованных индексов и индексов материализованных представлений текущей базы данных, статистика для которых не обновлялась дольше месяца, или не создавалась вообще.
  SELECT CAST ('['+ OBJECT_NAME(id) + '].[' + name + ']' AS nvarchar(261)) AS [Индекс]
        ,CONVERT (char(11), STATS_DATE(id, indid),13)			  AS [Статиcтика от:]
        ,CASE
           WHEN indid > 1 
           THEN CAST ((8 * CAST (used AS decimal(9,0)))/1000 AS decimal(9,2))
           WHEN indid = 1 AND OBJECTPROPERTY(id, 'IsView') = 1
           THEN CAST ((8 * CAST (used AS decimal(9,0)))/1000 AS decimal(9,2))
           ELSE NULL	
         END							  AS [Вес (МБ)]
    FROM sysindexes
   WHERE OBJECTPROPERTY(id,       'IsSystemTable'   ) = 0 
     AND INDEXPROPERTY (id, name, 'IsAutoStatistics') = 0
     AND INDEXPROPERTY (id, name, 'IsHypothetical'  ) = 0
     AND INDEXPROPERTY (id, name, 'IsStatistics'    ) = 0
     AND INDEXPROPERTY (id, name, 'IsFulltextKey'   ) = 0
     AND (indid between 2 and 250 OR (indid = 1 AND OBJECTPROPERTY(id, 'IsView') = 1))
     AND (STATS_DATE(id, indid) IS NULL OR STATS_DATE(id, indid) < DATEADD(m, -1, GETDATE()))
ORDER BY CONVERT (char(6), STATS_DATE(id, indid),112), [Вес (МБ)]

-- Индексы в выбранной таблице
	USE DbName;
	GO
	SELECT o.name AS table_name,p.index_id, i.name AS index_name , au.type_desc AS allocation_type, au.data_pages, partition_number
	FROM sys.allocation_units AS au
		JOIN sys.partitions AS p ON au.container_id = p.partition_id
		JOIN sys.objects AS o ON p.object_id = o.object_id
		JOIN sys.indexes AS i ON p.index_id = i.index_id AND i.object_id = p.object_id
	WHERE o.name IN (SELECT name FROM sys.tables)
	ORDER BY o.name, p.index_id;
 
 --Размер индексов в табицах
	USE Database;
	-- DBCC UPDATEUSAGE (0); -- Очень сложная операция, запускать только если есть подозрение, что sp_spaceused возвращает неверные данные
	CREATE TABLE #t([имя таблицы] varchar(255), [строк] varchar(255), [зарезервировано] varchar(255), [всего данных] varchar(255), [размер индексов] varchar(255), [свободно] varchar(255));
	INSERT INTO #t
	exec sp_msforeachtable N'exec sp_spaceused ''?''';
	SELECT * FROM #t ORDER BY CONVERT(bigint, REPLACE([всего данных], ' KB', '')) DESC;
	DROP TABLE #t;
 
 -- План обслуживания индексов. Устранение фрагментации (АРТТУР)/автоматическое обновление индексов
	- 'STATISTICS_NORECOMPUTE  = ON' означает что не будет перестроена статистика по этому индексу
	CREATE TABLE #TempTable(
		database_id int,
		table_name varchar(50),
		index_id int,
		index_name varchar(50),
		avg_frag_percent float,
		fill_factor tinyint
	)

	INSERT INTO #TempTable (
		database_id, 
		table_name, 
		index_id, 
		index_name, 
		avg_frag_percent,
		fill_factor)
	SELECT 
		dm.database_id, 
		tbl.name, 
		dm.index_id, 
		idx.name, 
		dm.avg_fragmentation_in_percent,    
		idx.fill_factor
	FROM sys.dm_db_index_physical_stats(DB_ID(), null, null, null, null) dm
		INNER JOIN sys.tables tbl ON dm.object_id = tbl.object_id
		INNER JOIN sys.indexes idx ON dm.object_id = idx.object_id AND dm.index_id = idx.index_id
	WHERE page_count > 8
		AND avg_fragmentation_in_percent > 15
		AND dm.index_id > 0 
		
		--см описание таблицы
	DECLARE @index_id INT
	DECLARE @tableName VARCHAR(250) 
	DECLARE @indexName VARCHAR(250)
	DECLARE @defrag FLOAT
	DECLARE @fill_factor int
		-- Сам запрос, который мы будем выполнять, я поставил MAX, потому как иногда меняю такие скрипты,
		-- и забываю поправить размер данной переменной, в результате получаю ошибку.
	DECLARE @sql NVARCHAR(MAX)

		-- Далее объявляем курсор
	DECLARE defragCur CURSOR FOR
		SELECT 
			index_id, 
			table_name, 
			index_name, 
			avg_frag_percent,
			fill_factor
			
		FROM #TempTable

	OPEN defragCur
	FETCH NEXT FROM defragCur INTO @index_id, @tableName, @indexName, @defrag,@fill_factor
	WHILE @@FETCH_STATUS=0
	BEGIN
		IF OBJECT_ID(''+@tableName+'','U') is not null
		BEGIN
			SET @sql = N'ALTER INDEX ' + @indexName + ' ON ' + @tableName
		  
			--В моем случае, важно держать неможко пустого места на страницах, потому, что вставка в тоже таблицы имеете место, и не хочеться тратить драгоценное время пользователей на разбиение страниц
			IF (@fill_factor != 90)
			BEGIN
				SET @sql = @sql + N' REBUILD PARTITION = ALL WITH (FILLFACTOR = 90, PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, ONLINE = OFF, SORT_IN_TEMPDB = ON )'
			END
			ELSE
			BEGIN -- Тут все просто, действуем по рекомендации MS
				IF (@defrag > 30) --Если фрагментация больше 30%, делаем REBUILD
				BEGIN
					SET @sql = @sql + N' REBUILD PARTITION = ALL WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, ONLINE = OFF, SORT_IN_TEMPDB = ON )'
				END
				ELSE -- В противном случае REORGINIZE
				BEGIN
					SET @sql = @sql + N' REORGANIZE'
				END
			END
			   
			exec (@sql) -- Выполнить запрос
		END
		FETCH NEXT FROM defragCur INTO @index_id, @tableName, @indexName, @defrag,@fill_factor
	END
	CLOSE defragCur
	DEALLOCATE defragCur

	DROP TABLE #TempTable


-- Размещение столбцов кластерного индекса в некластерном
	use tempdb
	go
	if object_id ( 'dbo.t', 'U' ) is not null
	drop table dbo.t;
	go
	create table dbo.t ( a int not null, b int not null, c int not null, d int not null, e int not null);
	go
	create unique clustered index cl_xxx on dbo.t (a, b, d);
	go
	create unique nonclustered index ncl_xxx on dbo.t (c, a, b, e);
	go

	declare @i int = 0
	while @i < 1000
	begin
	insert into dbo.t
	values( @i,@i,@i,@i,@i );
	set @i += 1
	end
	go 

	dbcc ind ( 'tempdb', 'dbo.t', -1 );
	go
	dbcc traceon (3604)
	go
--Кластерный не листовой
dbcc page ( 2, 1, 338, 5 ) with tableresults;
--НеКластерный не листовой
dbcc page ( 2, 1, 340, 5 ) with tableresults;
go
--НеКластерный листовой
dbcc page ( 2, 1, 341, 5 ) with tableresults;
go

-- Анализ индексов (Paul Randal)
	- Создаём таблицу для анализа на сервере мониторинга
		SELECT
			GETDATE () AS [ExecutionTime],
			'                                      ' as [ServerName],
			*
		INTO
			Monitor.[dbo].[MyIndexUsageStats]
		FROM
			sys.dm_db_index_usage_stats
		WHERE
			[database_id] = 0;
		GO
		
	- Заливаем на сервер мониторинга данные с конкретного сервера
	INSERT
		[10.0.1.1].Monitor.[dbo].[MyIndexUsageStats]
	SELECT
		GETDATE (),
		'Online',
		*
	FROM
		sys.dm_db_index_usage_stats;
	GO
	
	- Анализируем
	SELECT getdate() AS RunTime
	, DB_NAME(i.database_id) as DatabaseName
	, OBJECT_NAME(i.object_id, i.database_id) as ObjectName
	, *
	FROM [10.0.1.1].Monitor.dbo.MyIndexUsageStats AS i
	WHERE object_id > 100 AND DB_NAME(i.database_id) = 'ADMIN_SITE' AND ServerName = 'Artbase'

-- FILLFACTOR/ FIll FACTOR
	- АККУРАТНО ВЫСТАВЛЯТЬ БОЛЬШОЕ ЗНАЧЕНИЕ, ТАК КАК СЕРВЕРУ ПОТРЕБУЕТСЯ ЧИТАТЬ БОЛЬШЕ ДАННЫХ ИЗ-ЗА ПУСТОГО МЕСТА
	- Оставляет свободное место на всех страницах
	- Не очень хорошо для OLTP систем
	- Не использовать FILLFACTOR = 100, если используем оптимистический уровень изоляции, иначе будет добавлено по 14 байт на каждую строку
	- Сначала поставить 70, потом уменьшать или увеличивать в зависимости от того, что показывает код, в поле avg_page_space_used _in_persent
	SELECT * FROM sys.dm_db_index_physical_stats (DB_ID('WWWBRON_T2_S6'), NULL, NULL, NULL, 'DETAILED') 
	
	- Here’s the thing: having a bunch of empty space on your data pages is ALSO bad for performance. Your data is more spread out so you probably have to read more pages into memory. You waste space in cache that’s just sitting there empty. That’s not only not awesome, it can be TERRIBLE in many cases.
	- page splits/sec -- Меняйте параметр пока число данного счётчика не будет минимальным
	- For example, a fill factor value of 50 can cause database read performance to decrease by two times
	- FILLFACTOR DOES NOT APPLY TO HEAPS
	- Советы:
		1. Static Tables – Set Fill Factor at 100 (or default server fill factor)
			As these tables are never changing, keeping the Fill Factor at 100 is the best option. They conserve the space, and also there is no fragmentation.

		2. Tables Updated Less Often – Set Fill Factor at 95.
			These tables are more or less having characteristics like static tables. As they are not updated often, they do not encounter much issues. To accommodate the updates, I like to keep the Fill Factor 95. Honestly, if you are rebuilding the indexes at regular intervals, then I would prefer a Fill Factor of 95.

		3. Frequently updated Tables – Set Fill Factor between 70 and 90.
			When I have to set the Fill Factor at the table level, I first start from 90 and observe the table for a while, If I notice that there is still a recurring issue with page split, which in turn leads to fragmentation, I lower it further down towards 70 with an interval of the 5 at one times. Fill factor has to main balance between reads/writes.

		6. Tables with Clustered Index on Identity Column – Set Fill Factor at 100.
			This is very often seen in an OLTP system. Many tables have the identity column as a clustered index. In this case, all the new data is always inserted at the end of table and a new row is never inserted in the middle of the table. In this situation, the value of Fill Factor does not play any significant role and it is advisable to have the Fill Factor set to 100.

	-- Мониторинг page split
		- Может помочь Джонатан Кохаес
		- С помощью Extended Events можно мониторить событие page split с разными настройками fillfactor
		
	-- split page
		-- Получить разрывы страниц по объектам
		-- Rebuild не обнуляет поля ixO.leaf_allocation_count и ixO.nonleaf_allocation_count
		-- Высикие значения ixO.leaf_allocation_count + ixO.nonleaf_allocation_count не означают 100% фрагментацию
		-- Высокое значение фрагментации и ixO.leaf_allocation_count + ixO.nonleaf_allocation_count поможет обнаружить индексы, которым будет полезно выставить fill factor
			SELECT TOP 10000000 SO.[object_id]
					, SO.[name] AS TABLE_NAME
					, SI.index_id
					, SI.[name] AS index_name
					, SI.fill_factor
					, SI.type_desc AS index_type
					, ixO.partition_number
					, ixO.leaf_allocation_count -- смотреть сюда
					, ixO.nonleaf_allocation_count -- смотреть сюда
			FROM sys.dm_db_index_operational_stats (db_id(), NULL, NULL, NULL) AS ixO
					INNER JOIN sys.indexes SI 
							ON ixO.[object_id] = SI.[object_id] 
									AND ixO.[index_id] = SI.[index_id] 
					INNER JOIN sys.objects SO ON SI.[object_id] = SO.[object_id]
			ORDER BY ixO.leaf_allocation_count + ixO.nonleaf_allocation_count DESC	
			
		-- Поиск в логе
			SELECT
				 COUNT(1) AS NumberOfSplits
				 ,AllocUnitName
				 ,Context
			FROM
				 fn_dblog(NULL,NULL)
			WHERE
				 Operation = 'LOP_DELETE_SPLIT'
			GROUP BY
				 AllocUnitName, Context
			ORDER BY
				 NumberOfSplits DESC
		
		-- Замерить изменения за определённое время
			IF OBJECT_ID('tempdb.dbo.#t', 'U') IS NOT NULL
			  DROP TABLE #t; 

			SELECT TOP 10000000 SO.[object_id]
					, SO.[name] AS TABLE_NAME
					, SI.index_id
					, SI.[name] AS index_name
					, SI.fill_factor
					, SI.type_desc AS index_type
					, ixO.partition_number
					, ixO.leaf_allocation_count
					, ixO.nonleaf_allocation_count INTO #t
			FROM sys.dm_db_index_operational_stats (db_id(), NULL, NULL, NULL) AS ixO
					INNER JOIN sys.indexes SI 
							ON ixO.[object_id] = SI.[object_id] 
									AND ixO.[index_id] = SI.[index_id] 
					INNER JOIN sys.objects SO ON SI.[object_id] = SO.[object_id]


			WAITFOR DELAY '00:01:00'


			SELECT TOP 1000 SO.[object_id]
					, SO.[name] AS TABLE_NAME
					, SI.index_id
					, SI.[name] AS index_name
					, SI.fill_factor
					, SI.type_desc AS index_type
					, ixO.partition_number
					, #t.leaf_allocation_count - ixO.leaf_allocation_count
					, #t.nonleaf_allocation_count - ixO.nonleaf_allocation_count
			FROM sys.dm_db_index_operational_stats (db_id(), NULL, NULL, NULL) AS ixO
					INNER JOIN sys.indexes SI 
							ON ixO.[object_id] = SI.[object_id] 
									AND ixO.[index_id] = SI.[index_id] 
					INNER JOIN sys.objects SO ON SI.[object_id] = SO.[object_id]
					INNER JOIN #t ON #t.object_id = so.object_id AND #t.index_id = si.index_id
					WHERE (#t.leaf_allocation_count - ixO.leaf_allocation_count) > 1 OR (#t.nonleaf_allocation_count - ixO.nonleaf_allocation_count) > 1	
	

-- PAD INDEX/PADINXE/PAD_INDEX
	- То же самое что и FILLFACTOR, только уровнем выше в b-tree
	
-- ALLOW_ROW_LOCKS и ALLOW_PAGE_LOCKS
	- Лучше выставляйте всегда в оба параметра в ON, иначе могут быть deadlock

-- Дата создания индекса (тут скорее возвращается дата создания таблицы, а не индекса)
	- Можно указать создание индекса онлайн, для этого нужно запретить ему блокировать строки и страницы
		SELECT 
			t.name,
			i.name 'Index Name',
			o.create_date
		FROM 
			sys.indexes i
		INNER JOIN 
			sys.objects o ON i.[object_id] = o.[object_id]
		INNER JOIN sys.tables t ON t.[object_id] = o.[object_id]
		WHERE 
			i.name like '%_dta_%' OR i.name LIKE '%xpktinstitution%' OR t.name = 'tInstitution'
			
-- Информация о количестве строк в индексе
	SELECT * FROM sys.dm_db_partition_stats WHERE
object_id=OBJECT_ID('HumanResources.Employee')    AND (index_id=0 or
index_id=1); 

-- Retrieving locking and blocking details for each index
	SELECT  '[' + DB_NAME(ddios.[database_id]) + '].[' + su.[name] + '].['
			+ o.[name] + ']' AS [statement] ,
			i.[name] AS 'index_name' ,
			ddios.[partition_number] ,
			ddios.[row_lock_count] ,
			ddios.[row_lock_wait_count] ,
			CAST (100.0 * ddios.[row_lock_wait_count]
			/ ( ddios.[row_lock_count] ) AS DECIMAL(5, 2)) AS [%_times_blocked] ,
			ddios.[row_lock_wait_in_ms] ,
			CAST (1.0 * ddios.[row_lock_wait_in_ms]
			/ ddios.[row_lock_wait_count] AS DECIMAL(15, 2))
				 AS [avg_row_lock_wait_in_ms]
	FROM    sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) ddios
			INNER JOIN sys.indexes i ON ddios.[object_id] = i.[object_id]
										 AND i.[index_id] = ddios.[index_id]
			INNER JOIN sys.objects o ON ddios.[object_id] = o.[object_id]
			INNER JOIN sys.sysusers su ON o.[schema_id] = su.[UID]
	WHERE   ddios.row_lock_wait_count > 0
			AND OBJECTPROPERTY(ddios.[object_id], 'IsUserTable') = 1
			AND i.[index_id] > 0
	ORDER BY ddios.[row_lock_wait_count] DESC ,
			su.[name] ,
			o.[name] ,
			i.[name ]


-- Investigating latch waits
	SELECT  '[' + DB_NAME() + '].[' + OBJECT_SCHEMA_NAME(ddios.[object_id])
			+ '].[' + OBJECT_NAME(ddios.[object_id]) + ']' AS [object_name] ,
			i.[name] AS index_name ,
			ddios.page_io_latch_wait_count ,
			ddios.page_io_latch_wait_in_ms ,
			( ddios.page_io_latch_wait_in_ms / ddios.page_io_latch_wait_count )
												 AS avg_page_io_latch_wait_in_ms
	FROM    sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) ddios
			INNER JOIN sys.indexes i ON ddios.[object_id] = i.[object_id]
										AND i.index_id = ddios.index_id
	WHERE   ddios.page_io_latch_wait_count > 0
			AND OBJECTPROPERTY(i.OBJECT_ID, 'IsUserTable') = 1
	ORDER BY ddios.page_io_latch_wait_count DESC ,
			avg_page_io_latch_wait_in_ms DESC


-- Identify lock escalations
	SELECT  OBJECT_NAME(ddios.[object_id], ddios.database_id) AS [object_name] ,
			i.name AS index_name ,
			ddios.index_id ,
			ddios.partition_number ,
			ddios.index_lock_promotion_attempt_count ,
			ddios.index_lock_promotion_count ,
			( ddios.index_lock_promotion_attempt_count
			  / ddios.index_lock_promotion_count ) AS percent_success
	FROM    sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) ddios
			INNER JOIN sys.indexes i ON ddios.OBJECT_ID = i.OBJECT_ID
										AND ddios.index_id = i.index_id
	WHERE   ddios.index_lock_promotion_count > 0


-- Identify indexes associated with lock contention
	SELECT  OBJECT_NAME(ddios.OBJECT_ID, ddios.database_id) AS OBJECT_NAME ,
			i.name AS index_name ,
			ddios.index_id ,
			ddios.partition_number ,
			ddios.page_lock_wait_count ,
			ddios.page_lock_wait_in_ms ,
			CASE WHEN DDMID.database_id IS NULL THEN 'N'
				 ELSE 'Y'
			END AS missing_index_identified
	FROM    sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) ddios
			INNER JOIN sys.indexes i ON ddios.OBJECT_ID = i.OBJECT_ID
										AND ddios.index_id = i.index_id
			LEFT OUTER JOIN ( SELECT DISTINCT
										database_id ,
										OBJECT_ID
							  FROM      sys.dm_db_missing_index_details
							) AS DDMID ON DDMID.database_id = ddios.database_id
										  AND DDMID.OBJECT_ID = ddios.OBJECT_ID
	WHERE   ddios.page_lock_wait_in_ms > 0
	ORDER BY ddios.page_lock_wait_count DESC ;

-- In-memory
	-- Hash
		- Goor for equality queries
		- For compisite indexes, must reference all columns
	-- Range
		- Good for:
			- Range searches and sorting
			- Unknown number of buckets
		- Storage overhead is proportional to number of distinct values
	-- Columnstore
		- Creates a copy of the data
		- Cood for analyticsCth`u
		
	-- Создать индекс
		-- Hash
			ALTER TABLE SupportEvent  
			ADD INDEX idx_hash_SupportEngineerName  
			HASH (SupportEngineerName) WITH (BUCKET_COUNT = 64);  -- Nonunique.  
		
		-- Bw-tree
			ALTER TABLE Sales.SalesOrderDetail_inmem  
			ADD INDEX ix_ModifiedDate (ModifiedDate); 
				
			ALTER TABLE Sales.SalesOrderDetail_inmem  
			ADD    CustomerID int NOT NULL DEFAULT -1 WITH VALUES,  
            ShipMethodID int NOT NULL DEFAULT -1 WITH VALUES,  
            INDEX ix_Customer (CustomerID);  

			
-- indexed views
	SELECT o.name as view_name, i.name as index_name
    FROM sysobjects o 
        INNER JOIN sysindexes i 
            ON o.id = i.id 
    WHERE o.xtype = 'V' -- View