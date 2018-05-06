-- ***** TRACE-PROFILER *****

-- ��������� �������� ������ (sqltrace)
	http://www.sommarskog.se/sqlutil/sqltrace.html

-- ���������� ��� �������� ����������
	SELECT * FROM sys.trace_events
	
-- ������� (EventClass)
	- 65534 Trace start 
	- 65528 First file in trace sequence, seems to appear after all the existing connections events. A bit like this is the start of the live events. 
	- 65527 Trace Rollover (i.e. a new file has been started 
	- 65533 Trace Stop 
	- 18 -- ��������� ������� SQL Server �������


-- ����� ������� �� Profiler
	- ����������
		Use master
		Go
		Grant Alter Trace to [Domain\Username]

-- ���������� ������ ������ ��������
USE master;
GO
EXEC sp_configure 'show advanced option', '1';

RECONFIGURE;
EXEC sp_configure;

-- ���������� ����������� ��������
exec sp_configure 'default trace enabled', 1

-- ����� ����������� ��������
	C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\log_1524.trc

-- �������� ������ ����������� � �������
	SELECT * INTO #SIEMAudit
	FROM fn_trace_gettable(N'R:\SIEM\SQL Server\name'+(select TOP 1 [filename] from #traceFileName ORDER BY [filename] ASC), default )

-- ����� ���������� �� ����� SSMS
SELECT * FROM fn_trace_gettable
('C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\log_1524.trc', default)
GO

-- ����������� TSQL
	- ����� �������� �������� ����������� � ���� T-SQL, ����� ��������� ���� ��������� �� ����� '%sp_trace%' � ��������� ������ template
	- ���� ��������� ������� "Server processes trace data" (Profiler), ����� ������ ������ ������ �������������� � � ����� ����� ���������� �����:
		select * from sys.traces
	- ���������� ������
		sp_trace_setstatus @traceid = 6, @status = 0
	- �������� ������
		sp_trace_setstatus @traceid = 6, @status = 2
		
	-- ��������� ���������� � ������
	SELECT * FROM ::fn_trace_getinfo(NULL)
	SELECT * FROM ::fn_trace_getinfo(default)
	
	-- ���������� � ��������
		sys.fn_trace_getfilterinfo(trace_id)
		
	-- �������� ��� �������
		sp_trace_setfilter 1, Null, 0,0, NULL -- ��� 1 = trace_id
	
-- ����� �������� �������� ��� ������
	SELECT *
	FROM ::fn_trace_geteventinfo(trace_id)

-- ������� ������
	sp_trace_create [ @traceid = ] trace_id OUTPUT 
          , [ @options = ] option_value  
          , [ @tracefile = ] 'trace_file' 
     [ , [ @maxfilesize = ] max_file_size ]
     [ , [ @stoptime = ] 'stop_time' ]
     [ , [ @filecount = ] 'max_rollover_files' ]

	declare @trace_id int
	DECLARE @max_files_size bigint
	DECLARE @stop_time datetime
	SET @stop_time = GETDATE()
	SET @max_files_size = 50
	set @trace_id=3 -- �������� 1, ��� ��������� � fn_trace_getinfo
	exec sp_trace_create @trace_id output,2,N'R:\MSSQL.1\MSSQL\LOG\app\Night',@max_files_size,@stop_time,10
	
-- �������� ������� � ������
	sp_trace_setevent [ @traceid = ] trace_id  
          , [ @eventid = ] event_id 
          , [ @columnid = ] column_id 
          , [ @on = ] on
	
	DECLARE @on bit
	SET @on = 1
	exec sp_trace_setevent 2,10,2,@on
	go
	
-- �������� ������ � ������
sp_trace_setfilter [ @traceid = ] trace_id  
          , [ @columnid = ] column_id -- �������� ������ �������, �� �������� �������� ��� ������ ��� @value
          , [ @logical_operator = ] logical_operator -- Specifies whether the AND (0) or OR (1) operator is applied. logical_operator is int, with no default
          , [ @comparison_operator = ] comparison_operator 
          , [ @value = ] value -- ���� ������ �� 3000 (��) * 1000. ���� ����� ���������� ����������, ��� ������� ������� �� column_id

	-- comparison_operator
	0 = (Equal) 
	1 <> (Not Equal)	 
	2 > (Greater Than)
	3 < (Less Than)
	4 >= (Greater Than Or Equal)
	5 <= (Less Than Or Equal)
	6 LIKE 
	7 NOT LIKE 

	-- column_id (�� �������� )
	1 TextData Text value dependent on the event class that is captured in the trace. 
	2 BinaryData Binary value dependent on the event class captured in the trace. 
	3 DatabaseID ID of the database specified by the USE database statement, or the default database if no USE database statement is issued for a given connection. 
	4 TransactionID System-assigned ID of the transaction. 
	6 NTUserName Microsoft Windows NT� user name. 
	7 NTDomainName Windows NT domain to which the user belongs. 
	8 ClientHostName Name of the client computer that originated the request. 
	9 ClientProcessID ID assigned by the client computer to the process in which the client application is running. 
	10 ApplicationName Name of the client application that created the connection to an instance of SQL Server. This column is populated with the values passed by the application rather than the displayed name of the program. 
	11 SQLSecurityLoginName SQL Server login name of the client. 
	12 SPID Server Process ID assigned by SQL Server to the process associated with the client. 
	13 Duration Amount of elapsed time (in milliseconds) taken by the event. This data column is not populated by the Hash Warning event. 
	14 StartTime Time at which the event started, when available. 
	15 EndTime Time at which the event ended. This column is not populated for starting event classes, such as SQL:BatchStarting or SP:Starting. It is also not populated by the Hash Warning event. 
	16 Reads Number of logical disk reads performed by the server on behalf of the event. This column is not populated by the Lock:Released event. 
	17 Writes Number of physical disk writes performed by the server on behalf of the event. 
	18 CPU Amount of CPU time (in milliseconds) used by the event. 
	19 Permissions Represents the bitmap of permissions; used by Security Auditing. 
	20 Severity Severity level of an exception. 
	21 EventSubClass Type of event subclass. This data column is not populated for all event classes. 
	22 ObjectID System-assigned ID of the object. 
	23 Success Success of the permissions usage attempt; used for auditing. 
	24 IndexID ID for the index on the object affected by the event. To determine the index ID for an object, use the indid column of the sysindexes system table. 
	25 IntegerData Integer value dependent on the event class captured in the trace. 
	26 ServerName Name of the instance of SQL Server (either servername or servername\instancename) being traced. 
	27 EventClass Type of event class being recorded. 
	28 ObjectType Type of object (such as table, function, or stored procedure). 
	29 NestLevel Nest Level 
	30 State Server state, in case of an error. 
	31 Error Error number. 
	32 Mode Lock mode of the lock acquired. This column is not populated by the Lock:Released event. 
	33 Handle Handle of the object referenced in the event. 
	34 ObjectName Name of object accessed. 
	35 DatabaseName Name of the database specified in the USE database statement. 
	36 Filename Logical name of the file name modified. 
	37 ObjectOwner Owner ID of the object referenced. 
	38 TargetRoleName Name of the database or server-wide role targeted by a statement. 
	39 TargetUserName User name of the target of some action. 
	40 DatabaseUserName SQL Server database username of the client. 
	41 LoginSID Security identification number (SID) of the logged-in user. 
	42 TargetLoginName Login name of the target of some action. 
	43 TargetLoginSID SID of the login that is the target of some action. 
	44 ColumnPermissionsSet Column-level permissions status; used by Security Auditing 

-- ���������� ������
	sp_trace_setstatus @TraceID , 0
-- �������
	sp_trace_setstatus @TraceID , 2
	
-- �����
	1. ����� ������ ��������� �����
	
-- ������
	1. �� ����������. ���������� ������������ ���������� ����� � �������� � ������ ����� ����� ������������� ������
	2. �� ��������, �� ������������		

-- �������� ������ �� ����� ����������� � ������������ ������� � ������ ��������.
	select * into trn from fn_trace_gettable ('c:\temp\204.trc', default)  where EventClass=45 or EventClass=41
	select * into trn1 from fn_trace_gettable ('c:\temp\458.trc', default)  where EventClass=45 or EventClass=41
	select * into trn2 from fn_trace_gettable ('c:\temp\217.trc', default)  where EventClass=45 or EventClass=41
	insert  into obr select * from fn_trace_gettable ('c:\temp\trace_all_1.trc', default)  where EventClass=45 or EventClass=41
	insert  into obr select * from fn_trace_gettable ('c:\temp\trace_all_2.trc', default)  where EventClass=45 or EventClass=41
	insert  into obr select * from fn_trace_gettable ('c:\temp\trace_all_3.trc', default)  where EventClass=45 or EventClass=41

-- ��� �� ����� ��������� � ������������ SELECT ������ �� ����� �����������.
	select * from fn_trace_gettable ('������� ��� ����� �����������', default)  

	select top 100 * from obr

-- ������ ����������� ������� ����������� � �������� �� ������ �������(EventClass 43 - �������  SP:Completed )
	select    OBJECTNAME,SUM(reads) ,round(convert(float, avg(duration),1)/1000000,1) as[������� ����� ���������� � ��������], count(ObjectName)as [���-�� ����������],round(convert(float,sum (duration))/1000000,1) as[����� ����� ���������� � ��������]    from obr
	where EventClass = 45
	group by OBJECTNAME
	order by  SUM(reads) desc
	
-- �������� �� ������ ������� ��������� � ������������� �� ���
	UPDATE TraceResults
	   SET ProcedureName = 
	   LEFT(
		  RIGHT(TextData, LEN(TextData) - CHARINDEX(' ',TextData, CHARINDEX('Exec',TextData))),
		  CHARINDEX(' ', RIGHT(TextData, LEN(TextData) - CHARINDEX(' ',TextData, CHARINDEX('Exec',TextData))) + ' ')
	   )
	where TextData like '%exec%'


-- ������ ����������� ������� ����������� � �������� �� ������ �������(EventClass 45,41 - ������� SQL:StmtCompleted,	SP:StmtCompleted )
	-- 1
		select  [applicationname] as [����������],round(convert(float,sum (duration))/1000000,1) as[����� ����� ���������� � ��������]
		,count(cast(Textdata as varchar(4000)))as [���-�� ����������]
		,round(convert(float, avg(duration),1)/1000000,1) as[������� ����� ���������� � ��������]
		,round(convert(float, Max(duration),1)/1000000,1) as[������������ ����� ���������� � ��������]
		,round(convert(float, Min(duration),1)/1000000,1) as[����������� ����� ���������� � ��������]
		,SUM(reads) as [����� ���������� ������] 
		,sum(writes) as [����� ���������� �������], cast(Textdata as varchar(8000)) as [����� �������] 
		from #PerfMon
		where (EventClass = 45 or EventClass = 41)
		--and cast(Textdata as varchar(4000)) not like 'exec%'
		group by cast(Textdata as varchar(8000)),[applicationname]
		order by  [����� ����� ���������� � ��������] desc

	-- 2
		select  [applicationname],OBJECTNAME,SUM(reads) as [����� ���������� ������] ,sum(writes),round(convert(float, avg(duration),1)/1000000,1) as[������� ����� ���������� � ��������], count(cast(Textdata as varchar(4000)))as [���-�� ����������],round(convert(float,sum (duration))/1000000,1) as[����� ����� ���������� � ��������], cast(Textdata as varchar(4000)) as [����� �������]   from trn2
		where (EventClass = 45 or EventClass = 41)
		and cast(Textdata as varchar(4000)) not like 'exec%'
		group by cast(Textdata as varchar(4000)),OBJECTNAME,[applicationname]
		order by  [����� ����� ���������� � ��������] desc
		
	-- 3
		select  [applicationname],OBJECTNAME,SUM(reads) as [����� ���������� ������] ,sum(writes),round(convert(float, avg(duration),1)/1000000,1) as[������� ����� ���������� � ��������], count(cast(Textdata as varchar(4000)))as [���-�� ����������],round(convert(float,sum (duration))/1000000,1) as[����� ����� ���������� � ��������], cast(Textdata as varchar(4000)) as [����� �������]   from trn2
		where (EventClass = 45 or EventClass = 41)
		and cast(Textdata as varchar(4000)) not like 'exec%'
		group by cast(Textdata as varchar(4000)),OBJECTNAME,[applicationname]
		order by  [����� ����� ���������� � ��������] desc

		
-- ����� ������� ��������
	RPC:Completed
	SP:StmtCompleted
	SQL:BatchStarting 
	SQL:BatchCompleted ��� TSQL:BatchCompleted
	Showplan XML
	
	-- Perfomance Monitor
		- LogicalDisk: % Disk Time � Indicates the activity level of a particular logical disk. The higher the number, the more likely there is an I/O bottleneck. Be sure to select those counters for the logical drives that contain your mdf and ldf files. If you have these separated on different logical disks, then you will need to add this counter for each logical disk.
		- LogicalDisk: Avg. Disk Queue Length � If a logical disk gets very busy, then I/O requests have to be queued. The longer the queue, the more likely there is an I/O bottleneck. Again, be sure to select those counters for each logical drive that contains your mdf and ldf files.
		- Processor: % Processor Time: _Total � Measures the percentage of available CPUs in the computer that are busy. Generally speaking, if this number exceeds 80% for long periods of time, this may be an indication of a CPU bottleneck.
		- System: Processor Queue Length � If the CPUs get very busy, then CPU requests have to be queued, waiting their turn to execute. The longer the queue, the more likely there is a CPU bottleneck.
	
-- ***** Extended Events *****

-- �����
	1. ���������� ������ ���������� ������ ����� ������ ����� ������ ������. ��� ������ 1 ������� �� �������, ����� ��������, �� ����������� ������ �������
	2. ��� ������������� ���������, ����� �������� � ����� ������ ����� ������ ������

-- ������
	1. ������ ������� ������

-- ��� �����
	- Managment >> Extended Events -- ������� � SQL Server 2012
	
-- ���������� ���������
	SQL Server 2008 Extended Events SSMS Addin
	GUI Extended Events

-- ����������� �������/extended events (11 �������� �� 09.2013 SQL Server ��� ���������������)
http://msdn.microsoft.com/ru-ru/library/bb630317(v=sql.105).aspx

-- ��� ����������� ID ����, ������� ����� �����������
	SELECT DB_ID('DbName')
	
-- ������ �������/events
	SELECT * FROM sys.dm_xe_objects WHERE [object_type] = 'event' ORDER BY [name]

-- ���������� ������������ ������� ������� ��������
	SELECT * FROM sys.dm_xe_object_columns WHERE [object_name] = 'sql_statement_completed'
	
-- ��� �� ����� ����������� (What database and resource governor actions are there)
	SELECT * FROM sys.dm_xe_objects WHERE [object_type] = 'action' ORDER BY [name]
	
-- ����/.���� ����������� (target)
	SELECT * FROM sys.dm_xe_objects WHERE [object_type] = 'target' ORDER BY [name]
	- asynchronous_file_target -- ������ � ����
	
-- �����
	-- Spill
		sort_warning
		hash_warning 
		hash_spill_details
		exchange_spill
		
-- �������� ������
	IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name = 'EventName')
		DROP EVENT SESSION EventNama ON SERVER
		
	CREATE EVENT SESSION EventName ON SERVER
	ADD EVENT sqlserver.sql_statement_completed
		(ACTION(sqlserver.sql_text,sqlserver.plan_handle)
			WHERE sqlserver.database_id=12
			AND cpu > 10) -- total ms of CPU time
	ADD TARGET package0.asynchronous_file_target
		(SET FILENAME = N'D:\EE_ExpensiveQueries.xel',
		METADATAFILE = N'D:\EE_ExpensiveQueries.xem')
	WITH (max_dispatch_latency = 1 seconds)
	
-- ��������� ������
	ALTER EVENT SESSION EventName ON SERVER 
	STATE = START
	
-- ���������� ������
	ALTER EVENT SESSION EventName ON SERVER 
	STATE = STOP
	
-- ������� ������
	DROP EVENT Session EventName ON SERVER
	
-- ��������� ������� ������� ���� ���������
	SELECT Count(*) FROM sys.fn_xe_file_target_read_file
	('D:\EE_ExpensiveQueries*.xel',
	'D:\EE_ExpensiveQueries*.xem',null,null)
	
-- ���������� ����������� � xml �������
	SELECT data FROM (SELECT CONVERT (XML,event_data) as data
			FROM sys.fn_xe_file_target_read_file
				('D:\EE_ExpensiveQueries*.xel',
				'D:\EE_ExpensiveQueries*.xem',null,null)
			) entries
			
-- ������� ���������� � ��������� ��� � ������� XQuery
	SELECT 
		data.value('(/event[@name=''sql_statement_completed'']/@timestamp)[1]','DATETIME') AS [Time],
		data.value('(/event/data[@name=''cpu'']/value)[1]','INT') AS [CPU (ms)],
		CONVERT(FLOAT,data.value('(/event/data[@name=''duration'']/value)[1]','BIGINT'))/1 as [Duration (s)],
		data.value('(/event/action[@name=''sql_text'']/value)[1]','VARCHAR(MAX)') AS [SQL Statement],
		SUBSTRING(data.value('(/event/action[@name=''plan_handle'']/value)[1]','VARCHAR(100)'),15,50) as [Plan Handle]
	FROM 
		(SELECT CONVERT (XML,event_data) as data
			FROM sys.fn_xe_file_target_read_file
				('D:\EE_ExpensiveQueries*.xel',
				'D:\EE_ExpensiveQueries*.xem',null,null)) as t1
				
-- ������ ��������� � XML �������. ����� ��������� �� ����� � ������� � ������� sys.fn_xe_file_target_read_file, �� ��� �� ������� �� ������ �������, ������� XQuery ������� ����������. �����������:
	SELECT
	ed.value('(@name)[1]', 'varchar(50)') AS event_name,
	ed.value('(data[@name="source_database_id"]/value)[1]', 'bigint') AS source_database_id,
	ed.value('(data[@name="object_id"]/value)[1]', 'bigint') AS object_id,
	ed.value('(data[@name="object_type"]/value)[1]', 'bigint') AS object_type,
	COALESCE(ed.value('(data[@name="cpu"]/value)[1]', 'bigint'),
	ed.value('(data[@name="cpu_time"]/value)[1]', 'bigint')) AS cpu,
	ed.value('(data[@name="duration"]/value)[1]', 'bigint') AS duration,
	COALESCE(ed.value('(data[@name="reads"]/value)[1]', 'bigint'),
	ed.value('(data[@name="logical_reads"]/value)[1]', 'bigint')) AS reads,
	ed.value('(data[@name="writes"]/value)[1]', 'bigint') AS writes,
	ed.value('(action[@name="session_id"]/value)[1]', 'int') AS session_id,
	ed.value('(data[@name="statement"]/value)[1]', 'varchar(50)') AS statement
	FROM
	(
	SELECT
	CONVERT(XML, st.target_data) AS target_data
	FROM sys.dm_xe_sessions s
	INNER JOIN sys.dm_xe_session_targets st ON
	s.address = st.event_session_address
	WHERE s.name = N'statement_completed'
	AND st.target_name = N'ring_buffer'
	) AS tab
	CROSS APPLY target_data.nodes('//RingBufferTarget/event') t(ed);
	
-- ��� ���������� Action ����� ��������� ���. ��������, ��� ��� Action ����������� � ���������� ������. ������ ��������� Action:
	SELECT p.name AS package_name,
	o.name AS action_name,
	o.description
	FROM sys.dm_xe_packages AS p
	INNER JOIN sys.dm_xe_objects AS o
	ON p.guid = o.package_guid
	WHERE (p.capabilities IS NULL
	OR p.capabilities & 1 = 0)
	AND (o.capabilities IS NULL
	OR o.capabilities & 1 = 0)
	AND o.object_type = N'action';

-- Predicate/������.
	SELECT p.name AS package_name,
	o.name AS source_name,
	o.description
	FROM sys.dm_xe_objects AS o
	INNER JOIN sys.dm_xe_packages AS p
	ON o.package_guid = p.guid
	WHERE (p.capabilities IS NULL
	OR p.capabilities & 1 = 0)
	AND (o.capabilities IS NULL
	OR o.capabilities & 1 = 0)
	AND o.object_type = N'pred_%';


--
	SELECT *
	FROM sys.dm_xe_packages AS p
	WHERE (p.capabilities IS NULL
	OR p.capabilities & 1 = 0);
	
-- Default events/������ ��-���������
-- ���������� ����������� � xml �������
	DECLARE @location nvarchar(4000), @look nvarchar(4000)

	SET @location = CAST(SERVERPROPERTY('ErrorLogFileName') as nvarchar(4000))

	SELECT @look = SUBSTRING(@location,0,CHARINDEX('ERRORLOG',@location))
		
		
	SELECT data FROM (SELECT event_data as data
			FROM sys.fn_xe_file_target_read_file
				(@look+'system_health*.xel',
				null,null,null)
			) entries



	-- 
	SELECT 
		DATEADD(hh,3,data.value('(/event)[1]/@timestamp','DATETIME')) AS [Time],
		data.value('(/event/action[@name=''session_id'']/value)[1]','INT') AS [session_id],
		CONVERT(FLOAT,data.value('(/event/data[@name=''duration'']/value)[1]','BIGINT'))/1 as [Duration (ms)],
		data.value('(/event/action[@name=''sql_text'']/value)[1]','VARCHAR(MAX)') AS [SQL Statement]
	FROM 
		(SELECT CONVERT (XML,event_data) as data,event_data
			FROM sys.fn_xe_file_target_read_file
				('D:\DATA\MSSQL12.MSSQLSERVER\MSSQL\Log\system_health_0_13*.xel',
				null,null,null)) as t1

				WHERE t1.event_data like '%WRITELOG%'
				ORDER BY [Duration (ms)] DESC

-- ������������ �������/path/location
	SELECT * FROM sys.server_event_sessions  AS ses INNER JOIN sys.server_event_session_fields sesf ON ses.event_session_id = sesf.event_session_id WHERE sesf.name = 'filename'