-- Restoring pages/восстановление страниц
	- Damaged pages can be detected when activities such as the following take place.
		- A query needs to read a page.
		- DBCC CHECKDB or DBCC CHECKTABLE is being run.
		- BACKUP or RESTORE is being run.
		- You are trying to repair a database with DBCC DBREPAIR.
	- Если проблема в индексах, то их можно просто перестроить
	- Если повреждено много страниц, то лучше восстановиться из backup
	- Большая часть страниц может быть восстановлена в онлайне. Online доступно только в Enterprise
	- Start a page restore with a full, file, or filegroup backup that contains the page or pages to be restored. In the RESTORE DATABASE statement, use the PAGE clause to list the page IDs of all pages to be restored. The maximum number of pages that can be restored in a single file is 1,000.

-- Первый метод
NB! Данный метод работает только для версии SQL2000
1. Создаем новую базу с таким же именем и такимиже по именам и расположению .mdf и .ldf файлами 
2. Останавливаем сервер, подменяем файл .mdf 
3. Стартуем сервер, не обращаем внимания на статус базы 
4. Из QA выполняем скрипт 
	Use master 
	go 
	sp_configure 'allow updates', 1 
	reconfigure with override 
	go 

4. Там же выполняем 
select status from sysdatabases where name = '<db_name>' 
и запоминаем/записываем значение на случай неудачи ребилда лога 

5.Там же выполняем 
update sysdatabases set status= 32768 where name = '<db_name>' 

6. Перезапускаем SQL Server 

7. В принципе база должна быть видна (в emergency mode). Можно, например, заскриптовать все объекты 

8. Из QA выполняем 
DBCC REBUILD_LOG('<db_name>', '<имя нового лога с указанием полного пути>')
SQL Server скажет - Warning: The log for database '<db_name>' has been rebuilt. 

9. Если все нормально, то там же выполняем 
Use master 
go 
sp_dboption '<db_name>', 'single user', 'true' 
go 
USE <db_name> 
GO 
DBCC CHECKDB('<db_name>', REPAIR_ALLOW_DATA_LOSS) 
go 

9a.
Если Вам не удалось перевести базу в single user mode, то для проверки целостности данных можно попробовать dbo only mode
sp_dboption '<db_name>', 'dbo use only', 'true' 

10. Если все в порядке, то 
sp_dboption '<db_name>', 'single user', 'false' 
go 
Use master 
go 
sp_configure 'allow updates', 0 
go

alter database DataBaseName set ONLINE, MULTI_USER

-- Второй(что-то из следующего)
DBCC CHECKDB (uyar)
DBCC CHECKDB (uyar) WITH NO_INFOMSGS, ALL_ERRORMSGS
DBCC CHECKDB (uyar, REPAIR_FAST)
DBCC CHECKDB (uyar, REPAIR_REBUILD)

-- Ещё вариант
EXEC sp_resetstatus uyar; 
ALTER DATABASE uyar SET EMERGENCY
DBCC checkdb(uyar) 
ALTER DATABASE uyar SET SINGLE_USER WITH ROLLBACK IMMEDIATE 
DBCC CheckDB (uyar, REPAIR_ALLOW_DATA_LOSS) 
ALTER DATABASE uyar SET MULTI_USER

-- Ещё вариант
Use master 
go 
sp_configure 'allow updates', 1 
reconfigure with override 
go 
Use master 
go
alter database WWWBRON set emergency
go 
use master 
go 
sp_dboption 'WWWBRON', 'single_user', 'true' 
go 
USE WWWBRON
GO 
DBCC CHECKDB('WWWBRON', REPAIR_ALLOW_DATA_LOSS) 
go 
sp_dboption 'WWWBRON', 'single_user', 'false' 
Use master 
go 
sp_configure 'allow updates', 0 
go

-- One more
	ALTER DATABASE abs_V1 SET EMERGENCY;
	ALTER DATABASE abs_V1 SET SINGLE_USER;
	DBCC CHECKDB (abs_V1, REPAIR_ALLOW_DATA_LOSS) WITH NO_INFOMSGS, ALL_ERRORMSGS;
