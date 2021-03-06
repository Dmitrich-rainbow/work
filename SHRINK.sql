-- Основное
	- Сжимайте несколько файлов в одной базе данных последовательно, а не одновременно. Состязание в системных таблицах может привести к задержке из-за блокировки.
	- Сжатие файла данных должно быть редкой операцией так как вызывает массивную фрагментацию индексов. auto-shrink вызывает тот же эффект, просто в меньших масштабах так как освобождает мало места. Сжатие лога не приводит к негативным последствиям
	- Эта операция генерирует много I/O, создаёт нагрузку на CPU и на transaction log
	- Операции DBCC SHRINKFILE могут быть остановлены на любом этапе процесса, при этом вся выполненная работа сохраняется.
		BCC SHRINKFILE(MyAlert_log,3)
	- Сжатие БД
		- Сжимает все файловые группы и файл лога
		- Без параметров сначала перещает данные в свободное, пропущенное пространство, потом усекает конец журнала. Но место на диске будет высвобождено не более чем мин. размер файла
			DBCC SHRINKDATABASE (tempdb)

-- Узнать сколько можно освободить
	SELECT name ,size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS AvailableSpaceInMB
	FROM sys.database_files;

-- Аргументы
	- NOTRUNCATE
		- Перемещает распределенные страницы из конца файла на место нераспределенных страниц в начале файла данных с параметром target_percent или без него. Свободное место в конце файла операционной системе не возвращается, и физический размер файла не изменяется. Следовательно, если указан аргумент NOTRUNCATE, файл сжимается незначительно.
		- Аргумент NOTRUNCATE применим только к файлам данных. На файлы журнала он не влияет.
		- Этот параметр не поддерживается для контейнеров файловых групп FILESTREAM.
	- TRUNCATEONLY
		- Освобождает все свободное пространство в конце файла операционной системе, но не перемещает страницы внутри файла. Файл данных сокращается только до последнего выделенного предела.
		- Аргумент target_size не обрабатывается, если указан аргумент TRUNCATEONLY.
		- Аргумент TRUNCATEONLY применим только к файлам данных. Этот параметр не поддерживается для контейнеров файловых групп FILESTREAM.
	
-- Минусы
	1. Сжатие выполняется в однопоточном режиме
	2. Если есть non-clustered index, но нет clustered, то при shrink будут оновляться все non-clustered, что очень долго. Необходимо сначала удалить все некластерные индексы
	3. Каждая перемещённая страница логируется
	
-- Ускорение
	1. Перестроить большие таблицы до shrink
		SELECT * INTO Alpha FROM RenamedAlpha (drop RenamedAlpha)
	2. CREATE INDEX … WITH DROP_EXISTING в другую файловую группу, а текущую можно удалить
	3. Создайте индексы такие же с удалением текущих	

-- Как правильно выполнить сжатие:
	- Create a new filegroup
	- Move all affected tables and indexes into the new filegroup using the CREATE INDEX … WITH (DROP_EXISTING = ON) ON syntax, to move the tables and remove fragmentation from them at the same time
	- Drop the old filegroup that you were going to shrink anyway (or shrink it way down if its the primary filegroup)
	
-- Причины не сжимания файла данных
	1. Попытка сжатия до меньшего размера, чем начально заданный
	2. При сжатии во время backup, операция сжатия завершается с ошибкой
	3. Репликация
	4. select name,log_reuse_wait_desc from sys.databases -- Посмотреть почему не усекается лог
	
-- Best practics
	1. На больших объёмах сжимать небольшими частями
	

-- Сжатие/SHRINK
	-- Способ 1	(на работает, если включён DATABASE SNAPSHOT на БД, смотри Способ 3)
		USE [tempdb]
		GO
		CHECKPOINT; 
		GO
		-- Clean all buffers and caches
		DBCC DROPCLEANBUFFERS; 
		DBCC FREEPROCCACHE;
		DBCC FREESYSTEMCACHE('ALL');
		DBCC FREESESSIONCACHE;
		GO
		DBCC SHRINKFILE (N'tempdev' , 1000)
		
	-- Способ 2
		- Перезагрузка
		
	-- Способ 3
		-- Проверить сколько места занимают версси строк
			SELECT SUM(version_store_reserved_page_count) AS [version store pages used],
			(SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB]
			FROM sys.dm_db_file_space_usage;		

		-- Какие БД надо отключать
			select  name, is_read_committed_snapshot_on, snapshot_isolation_state, snapshot_isolation_state_desc, *
			from  sys.databases
			order  by 1

	
	
		--check which dbs are in snapshot isoation mode
		select  name, is_read_committed_snapshot_on, snapshot_isolation_state, snapshot_isolation_state_desc, *
		  from  sys.databases
		 order  by 1
		go
		--take DB out of this mode temprarily in order to shrink it
		alter database MY_USER_DB set READ_COMMITTED_SNAPSHOT off with rollback after 30 seconds
		go
		use tempdb
		go
		--select 16* 1024 --(convert GB to MB)
		dbcc shrinkfile (tempdev, 16384)
		go
		select (size*8)/1024 as FileSizeMB from sys.database_files	--check new size
		go
		--restore original DB settings
		alter database MY_USER_DB set READ_COMMITTED_SNAPSHOT on with rollback after 30 seconds
		go
		
	-- Способ 4
		1. Создать database snapshot
		2. Вернуться к нему. При этом будет начат новый лог с 2 VLF файлами размером с 0.25 Мб. /*ОСТОРОЖНО*/ Начнётся новая цепочка backup
