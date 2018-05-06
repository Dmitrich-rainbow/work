-- Error Severities/Уровни ошибок
	0-9 (Informational messages that return status information or report errors that are not severe. The Database Engine does not raise system errors with severities of 0 through 9)
	10 (Informational messages that return status information or report errors that are not severe. For compatibility reasons, the Database Engine converts severity 10 to severity 0 before returning the error information to the calling application.)
	11-16 (Indicate errors that can be corrected by the user)
	11 (Indicates that the given object or entity does not exist)
	12 (A special severity for queries that do not use locking because of special query hints. In some cases, read operations performed by these statements could result in inconsistent data, since locks are not taken to guarantee consistency)
	13 (Indicates transaction deadlock errors)
	14 (Indicates security-related errors, such as permission denied)
	15 (Indicates syntax errors in the Transact-SQL command)
	16 (Indicates general errors that can be corrected by the user)
	17-19 (Indicate software errors that cannot be corrected by the user. Inform your system administrator of the problem)
	17 (Indicates that the statement caused SQL Server to run out of resources (such as memory, locks, or disk space for the database) or to exceed some limit set by the system administrator)
	18 (Indicates a problem in the Database Engine software, but the statement completes execution, and the connection to the instance of the Database Engine is maintained. The system administrator should be informed every time a message with a severity level of 18 occurs)
	19 (Indicates that a nonconfigurable Database Engine limit has been exceeded and the current batch process has been terminated. Error messages with a severity level of 19 or higher stop the execution of the current batch. Severity level 19 errors are rare and must be corrected by the system administrator or your primary support provider. Contact your system administrator when a message with a severity level 19 is raised. Error messages with a severity level from 19 through 25 are written to the error log)
	20-24 (Indicate system problems and are fatal errors, which means that the Database Engine task that is executing a statement or batch is no longer running. The task records information about what occurred and then terminates. In most cases, the application connection to the instance of the Database Engine may also terminate. If this happens, depending on the problem, the application might not be able to reconnect.
	Error messages in this range can affect all of the processes accessing data in the same database and may indicate that a database or object is damaged. Error messages with a severity level from 19 through 24 are written to the error log)
	20 (Indicates that a statement has encountered a problem. Because the problem has affected only the current task, it is unlikely that the database itself has been damaged)
	21 (Indicates that a problem has been encountered that affects all tasks in the current database, but it is unlikely that the database itself has been damaged)
	22 (Indicates that the table or index specified in the message has been damaged by a software or hardware problem. Severity level 22 errors occur rarely. If one occurs, run DBCC CHECKDB to determine whether other objects in the database are also damaged. The problem might be in the buffer cache only and not on the disk itself. If so, restarting the instance of the Database Engine corrects the problem. To continue working, you must reconnect to the instance of the Database Engine; otherwise, use DBCC to repair the problem. In some cases, you may have to restore the database. If restarting the instance of the Database Engine does not correct the problem, then the problem is on the disk. Sometimes destroying the object specified in the error message can solve the problem. For example, if the message reports that the instance of the Database Engine has found a row with a length of 0 in a nonclustered index, delete the index and rebuild it)
	23 (Indicates that the integrity of the entire database is in question because of a hardware or software problem. Severity level 23 errors occur rarely. If one occurs, run DBCC CHECKDB to determine the extent of the damage. The problem might be in the cache only and not on the disk itself. If so, restarting the instance of the Database Engine corrects the problem. To continue working, you must reconnect to the instance of the Database Engine; otherwise, use DBCC to repair the problem. In some cases, you may have to restore the database)
	24 (Indicates a media failure. The system administrator may have to restore the database. You may also have to call your hardware vendor)

-- Ошибка SQL Server Managmetn Studion (WMI)
	%programfiles(x86)%\Microsoft SQL Server\number\Shared folder > cmd > mofcomp sqlmgmproviderxpsp2up.mof

-- Если не работает mmc/сервисы
	Изменить во всём реестре значение RestrictAuthorMode и RestrictToPermittedSnapins на 0	
-- Ошибка
	The activated proc '[dbo].[sp_syspolicy_events_reader]' running on queue 'msdb.dbo.syspolicy_event_queue' output the following:  'Cannot execute as the database principal because the principal "##MS_PolicyEventProcessingLogin##" does not exist, this type of principal cannot be impersonated, or you do not have permission.'

	-- Решение
		A user for the system login "##MS_PolicyEventProcessingLogin##" in the same name must exist in both master and msdb databases. If they dont exitst this error might occur. 
		Even if a user with sam name exist in master and msdb databases, a link between this user and the SQL server login must exist. If not this error will occur. To fix the missing link issue do the following:

		Use msdb;
		GO
		EXEC sp_change_users_login 'Auto_Fix', '##MS_PolicyEventProcessingLogin##', NULL,'Password01!'

		This should relink the user and fix the problem.

		http://social.msdn.microsoft.com/Forums/ru-RU/sqlservicebroker/thread/4be7eb6f-1346-4f6c-8184-a86f39b43e20

-- Ошибка
	The operating system returned error 38(failed to retrieve text for this error. Reason: 15105) 
	
	-- Причины
		1. При попытке восстановить backup возникает эта ошибка. Это может означать, что файл backup повреждён или что-то ещё
		2. Проблемы с чтением диска.
	
	-- Решение
		1. Стоит запустить диагностику SAN или диска
		2. Стоит снять новый backup
		
-- Ошибка
	Login failed for user. Reason: Failed to open the explicitly specified database.
	
	-- Причины
		1. Нет доступа к указанной в коннекте БД
		
	-- Решение
		1. В SQL Server error log нет указания к какой БД идёт подключение. Первым делом надо проверить дефолтную БД для данного пользователя
		2. Если дефолтное значение не помогло, то нужно использовать Profiler (Error and Warning > User Error Message и Security Audit > Audit Login Failed)
		
-- Ошибка
	- EventID 26073: TCP connection closed but a child process of SQL Server may be holding a duplicate of the connection's socket.  Consider enabling the TcpAbortiveClose SQL Server registry setting and restarting SQL Server. If the problem persists, contact Technical Support.'
		
		-- Решение
			Ошибка, которая появляется в следствии использования SQL Server Native Client 10.0 при неудачном закрытии/обрыве связи приложения и SQL Server.  Никаких действий не требуется так как ошибка единичная, при многократном повторении - необходимо обновить SQL Server до последней версии. (http://support.microsoft.com/kb/307197)
			
-- Ошибка
	- The process could not execute 'sp_replcmds' on 'SQLSERVERA3\SRVHARMON'. (Source: MSSQL_REPL, Error number: MSSQL_REPL20011). Get help: http://help/MSSQL_REPL20011
    - Could not obtain information about Windows NT group/user 'ORON\sqlsrvadmin', error code 0x5. (Source: MSSQLServer, Error number: 15404) Get help: http://help/15404
	
	-- Решение
		- Настроить доступ к БД нужного пользователя
		- Поставить владельца БД - sa и dbo должен владеть sa
		
-- Could not obtain information about Windows NT group/user 'domain\domain user'
	
	-- Решение
		- Сделать владельцем задания sa
		
	-- Объяснение
		- http://support.microsoft.com/kb/834124
		
	-- Возможные причины		
		- Проблемы сети.
		- Проблема с именем локальной группы Windows или глобальную группу Windows.
		- Конфликт с группы EVERYONE.
		- Процедура xp_sendmail расширенные ошибки хранимой процедуры.
		- Сбой задания агента SQL Server.
		- Сбой настройки репликации.

-- SQL Server has encountered N occurrence(s) of I/O requests taking longer than 15 seconds
	- Look at the below perfmon counters:
		a. Disk Sec/Read
		b. Disk Sec/write
		c. Disk queues
	- Check SQL error log for any IO
	- Check Windows event log for disk subsystems error
	- Check Virtual file stats DMV.
	- Index and Statistics update
	- Возможны проблемы из-за SAN, USB, Drivers
	- Detach the database and perform a file-level defragmentation of the MDF and LDF files (e.g. use the SYSINTERNALS contig.exe application). Then reattach the database.

-- Database 'OEMF_PDT' is in transition. Try the statement later.
	- Перезапустить все открыте Managment Studio
	
-- HY008
	http://blogs.msdn.com/b/jason_howell/archive/2012/06/11/analysis-services-cube-processing-fails-with-error-quot-ole-db-error-ole-db-or-odbc-error-operation-canceled-hy008-quot.aspx
	
-- TCP Provider: The semaphore timeout period has expired (http://sqlserverscribbles.com/2013/02/15/tcp-provider-the-semaphore-timeout-period-has-expired/)
	1. Disable TCP Chimney.Refer KB:942861 (http://support.microsoft.com/kb/892100/en-us)
	2. If you are in windows 2003 Change the value of the processor affinity to match the number of processors in the system.Follow KB:892100 (http://support.microsoft.com/kb/892100/en-us)
	{
	1.Click Start, click Run, type regedit, and then click OK.
	2.Expand the following registry subkey:
	HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\NDIS\Parameters
	3.Right-click ProcessorAffinityMask, and then click Modify.
	4.In the Value data box, type one of the following values, and then click OK:
	?If you have two processors, use the binary value 0b11, or hex value 0x3.
	?If you have three processors, use the binary value 0b111, or hex value 0x7.
	?If you have four processors, use the binary value 0b1111, or hex value 0xF.
	5.Quit Registry Editor.
	Note The 0x0 or 0xFFFFFFFF values are used to disable the ProcessorAffinityMask entry.
	}
	3. Check if priority boost is enabled for SQL Server. If yes disable it.
	4. Make sure there is no working set trim and system wide memory pressure. You can use second query in significant part of sql server process memory has been paged out to identify and follow the same blog to fix it)
	5. Check if paged pool and non-paged is empty. (Event ID:  2019  in event log)
	6. If you see this problem in cluster make sure you have set the network priority of “private heart beat” network higher than the “public” network.Refer KB:258750 (http://support2.microsoft.com/?kbid=258750) (там где показаны сетевые подключение >> Alt >> advanced >> advanced settings >> там поднять нужную сеть выше)
	
 /*2006-04-20 18:42:26.15 Server      TDSSNIClient initialization failed with error 0x7e, status code 0x1.
2006-04-20 18:42:26.15 Server      Error: 17826, Severity: 18, State: 3.
2006-04-20 18:42:26.15 Server      Could not start the network library because of an internal error in the network library. To determine the cause, review the errors immediately preceding this one in the error log.
2006-04-20 18:42:26.15 Server      Error: 17120, Severity: 16, State: 1.
2006-04-20 18:42:26.15 Server      SQL Server could not spawn FRunCM thread. Check the SQL Server error log and the Windows event logs for information about possible related problems.*/

	http://blogs.technet.com/b/isv_team/archive/2011/05/29/3432245.aspx
	http://blogs.msdn.com/b/sql_protocols/archive/2006/04/28/585835.aspx
	http://blogs.technet.com/b/isv_team/archive/2011/05/17/3429675.aspx
-- Ошибка	
	Msg 16943, Sev 16, State 4, Line 77 : Could not complete cursor operation because the table schema changed after the cursor was declared. [SQLSTATE 42000]
		
	-- Решение
		Достаточно триггер удалить или добавить, удалить или добавить индекс... Создать индексированное представление по таблице
		
-- Error 3930
	- Скорее всего ошибка в блоке Try...Catch. Данный блок скрывает реальную ошибку и чтобы её обнаружить нужно воспользоваться PRINT ERROR_MESSAGE()
	
-- Ошибка автоувеличения файла журнала до SQL Server 2012
	- Если размер автоувеличения более 3-4 гб, то создаётся огромное число vlf вместо ожидаемого
	Баг для блога http://www.geniiius.com/blog/autogrow-bug-fixed-with-denali
	
-- Ќе показываетс€ статус сервера через Management Studio
	- «апустить от администратора
	- ќтключить UAC
	- http://blogs.msdn.com/b/psssql/archive/2013/08/22/service-status-watcher-in-sql-server-management-studio-how-it-works.aspx
	
-- Windows Restart
	System > 6006 (когда был restart), 1074 (кто выполнил restart)
	
-- Ошибка входа
	-- Token-based server access validation failed with an infrastructure error
		1. SPN
		2. UAC (в поиске написать и подождать)
		3. Запустить программу от администратора
		4. Зайти удалённо
	
-- insufficient system memory in resource pool default
1.
	DBCC FREESYSTEMCACHE ('ALL') 
	DBCC FREESESSIONCACHE
	DBCC FREEPROCCACHE
	DBCC DROPCLEANBUFFERS
2. Обновление
3. Возможно проблемы с Виртуалкой
4. DBCC MEMORYSTATUS
5. Если это 2014Express
	ALTER WORKLOAD GROUP [default] WITH(request_max_memory_grant_percent=5) 
	ALTER RESOURCE GOVERNOR RESET STATISTICS 
	ALTER RESOURCE GOVERNOR RECONFIGURE 
	
-- dbghelp.dll или утечка памяти
	- https://support.microsoft.com/kb/2878139
	- установить обновление
	
-- подключение/connection errors
	- https://support.microsoft.com/en-us/help/4009936/solving-connectivity-errors-to-sql-server
		
