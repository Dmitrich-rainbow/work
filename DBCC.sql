-- Основное
	DBCC TRACEON (2588) -- Открыть для показа все возможные команды DBCC
	DBCC HELP ('?') -- Посмотреть все доступные DBCC команды
	DBCC HELP ('checkalloc') -- Подсказка по DBCC команде
	
-- Посмотреть активные транзакции в базе
	DBCC OPENTRAN ()	
	DBCC OPENTRAN (database_name) -- список транзакций в базе данных

-- Последний запрос/ last query
	DBCC INPUTBUFFER(117)
	
-- Другие 
	DBCC CHECKDB
	DBCC CHECKFILEGROUP
	DBCC CHECKTABLE
	DBCC INDEXDEFRAG
	DBCC SHRINKDATABASE
	DBCC SHRINKFILE
	
	DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS -- Удаляет все чистые буферы из буферного пула (то есть весь кэш, который не имеет грязных страниц). Чтобы удалить чистые буферы из буферного пула, необходимо сначала воспользоваться инструкцией CHECKPOINT для обеспечения холодного буферного кэша. Это вызовет принудительную запись всех «грязных» страниц текущей базы данных на диск и очистит буферы. После этого можно выполнить команду DBCC DROPCLEANBUFFERS, которая удалит все буферы из буферного пула.
	DBCC FLUSHPROCINDB(db_id) -- очистка кэша планов базы
	DBCC FREEPROCCACHE WITH NO_INFOMSGS; -- Сбросить весь кэш планов(стоит делать когда кэши изменяются сотнями тысяч)/план выполнения/перекомпиляция
	DBCC FREEPROCCACHE(0x05000F006FB9565D40615615050000000000000000000000) -- сбросить кэш определённого плана (plan_handle)
	DBCC FREESYSTEMCACHE ('All') -- Удаляет все неиспользуемые элементы из всех кэшей.
	DBCC FREESESSIONCACHE Flushes the distributed query connection cache. This has to do with distributed querie
	
-- Посмотреть статистику
	DBCC SHOW_STATISTICS (Films2,_WA_Sys_00000005_113584D1)
	DBCC SHOW_STATISTICS (Films2,_WA_Sys_00000005_113584D1) WITH HISTOGRAM -- посмотреть только гистограмму  
 
-- Сбросить значение автоинкремента
	DBCC CHECKIDENT('НазваниеТаблицы', RESEED, 0);
 
 -- DBCC PAGE/Системные страницы бд
	- Page 0 in any file is the File Header page, 1 is a Page Free Space (PFS), 3 страница (ID 2) GAM, 4 (ID 3) SGAM. Another GAM appears every 511,230 pages after the first GAM on page 2, and another SGAM appears every 511,230 pages after the first SGAM on page 3.
	DBCC TRACEON(3604)
	DBCC page(1,1,152)
	
	-- IAM (INDEX ALLOCATION MAP)
		Одна IAM на 4 Gb
	
-- реальное использование файлов логов баз
	DBCC SQLPERF (LOGSPACE)
	
-- покажет причину роста лога
	dbcc loginfo
	
 -- Проверка базы после сбоя
	DBCC CHECKCONSTRAINTS
 
 -- Информация о базе
	DBCC SHOWCONTIG

-- Проверка базы
	DBCC CHECKDB ('DATABASE_NAME') WITH NO_INFOMSGS, ALL_ERRORMSGS, PHYSICAL_ONLY;

-- Статистика использования памяти
	DBCC MEMORYSTATUS