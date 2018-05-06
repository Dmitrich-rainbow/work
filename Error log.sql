-- ErrorLog	
	DECLARE @date datetime
	DECLARE @date2 datetime
	SET @date = GETDATE()-1;
	SET @date2 = GETDATE() +1 

	CREATE TABLE #LogCheck
	(dat datetime,
	info nvarchar(50),
	text nvarchar(4000))

	INSERT INTO #LogCheck
	exec xp_readerrorlog -1, 1, NULL, NULL, @date,@date2

	SELECT * FROM #LogCheck WHERE text NOT LIKE '%Login succeeded for user%' AND text NOT LIKE '%DBCC CHECKTABLE%' AND text not like '%transactions rolled forward in database%' AND text not like '%transactions rolled back in database%'
	AND text NOT LIKE '%Log was backed up%'

	DROP TABLE #LogCheck
	
-- xp_readerrorlog
	5) '20120401' - StartTime
	6) '20120401 18:00' - EndTime
	
-- Cluster error log
	WINDOWS Server 2005: %systemroot%\cluster\cluster.log
	Windows Server 2008: Cluster Console Manager > ‚ыбрать нужный ресурс и в правой части > Show the critical events for this resource
	
-- Журнал сервера и журнал агента/обрезать лог/cut errorlog
	- Начать новый журнал сервера sp_Cycle_ErrorLog 
	- Начать новый журнал агента sp_Cycle_Agent_ErrorLog
	
-- Установить максимальный размер Error log (Начиная с SQL Server 2012) + Максимальное количество файлов Error log
	USE [master];
	GO
	-- Limit size of each file
	EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE',
	N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQLServer',
	N'ErrorLogSizeInKb', REG_DWORD, 1024;
	GO
	 
	-- Number of ErrorLog Files
	EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE',
	N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQLServer',
	N'NumErrorLogs', REG_DWORD, 8;
	GO 

-- Более сложный поиск по errorlog
	/*Если вам необходимо произвести поиск по ErrorLog с помощью T-SQL, то можно воспользоваться следующим решением.
	
	P.S. Обратите внимание, что этот способ может выполняться значительное время и, возможно, вы быстрее разберётесь в ситуации без подобных ухищрений.*/
	
	-- Создаём таблицу для ErrorLog
	CREATE TABLE #error_log (d datetime,p nvarchar(50),t nvarchar(max))

	-- Вставляем в таблицу данные из ErrorLog
	INSERT INTO #error_log
	EXEC sp_readerrorlog

	-- Выполняем фильтрацию (исключение "шума")
	SELECT * FROM #error_log WHERE t not like '%Login failed for user%' and t not like '%Error: 18456%'