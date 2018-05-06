-- Обновление столбца	
	- drop any indexes/constraints pointing to the old column, and disable triggers
	- add a new nullable column with the new data type (even if it is meant to be NOT NULL)
	- update the new column setting it equal to the old columns value (and you can do this in chunks of individual transactions (say, affecting 10000 rows at a time using UPDATE TOP (10000) ... SET newcol = oldcol WHERE newcol IS NULL) and with CHECKPOINT to avoid overrunning your log)
	- once the updates are all done, drop the old column
	- rename the new column (and add a NOT NULL constraint if appropriate)
	- rebuild indexes and update statistics
	
-- Добавление столбца
	1. Перейти в Single User
	2. Подключиться к БД
	3. Создать копию таблицы с нужными столбцами, но без индексов и статистики
	4. Скопировать все данные из старой таблицы
	5. Построить индексы и статситику
	6. Заменить старую таблицу новой
	
	-- или
	1. Переименовать таблицу
	2. Произвести изменения с отключением/удалением статистики/индексов/зависимостей/триггеров
	3. Вернуть имя таблице
	
	-- 2012+
		-- изменение только на уровне метаданных
			ALTER TABLE [Doc].[Documents] ADD [OrganizationId] [int] NOT NULL CONSTRAINT DF_Constraint DEFAULT 1
		-- Проверить что реально в страницах
			select TOP 100 pc.* from sys.system_internals_partitions p
			join sys.system_internals_partition_columns pc on p.partition_id = pc.partition_id
			where p.object_id = object_id('Doc.Documents');
		
-- Что влияет на добавление столбца		
	- Лучше включать Single User
	- Если добавляет столбец NOT NULL, то производительность ухудшится
	- Можно сделать DEFAULT, то столбцу нужно разрешить NULL. При этом после вставки везде будет NULL. Далее можно добавить столбцу значение и после чего поставить ему NOT NULL
	- The longer the table row, the longer it will take.
	- The more indexes you have on that table, the longer it will take.
	- If you add a default value (which you did), it will take longer.
	- If you have heavy usage on the server it will take longer.
	- If you dont lock that database or put it in single user mode, it will take longer.
	
-- Что влияет при изменении столбца
	- Если разрешить NULL, то будет максимально быстро