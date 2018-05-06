-- 
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = 'DurationOver5Sec')
	DROP EVENT SESSION [DurationOver5Sec] ON SERVER;
GO
CREATE EVENT SESSION [DurationOver5Sec]
ON SERVER
ADD EVENT sqlserver.rpc_completed(
	ACTION 
	(
		  sqlserver.client_app_name	-- ApplicationName from SQLTrace
		, sqlserver.client_hostname	-- HostName from SQLTrace
		, sqlserver.client_pid	-- ClientProcessID from SQLTrace
		, sqlserver.database_id	-- DatabaseID from SQLTrace
		, sqlserver.request_id	-- RequestID from SQLTrace
		, sqlserver.server_principal_name	-- LoginName from SQLTrace
		, sqlserver.session_id	-- SPID from SQLTrace
	)
	WHERE 
	(
			duration >= 5000000
	)
),
ADD EVENT sqlserver.sql_batch_completed(
	ACTION 
	(
		  sqlserver.client_app_name	-- ApplicationName from SQLTrace
		, sqlserver.client_hostname	-- HostName from SQLTrace
		, sqlserver.client_pid	-- ClientProcessID from SQLTrace
		, sqlserver.database_id	-- DatabaseID from SQLTrace
		, sqlserver.request_id	-- RequestID from SQLTrace
		, sqlserver.server_principal_name	-- LoginName from SQLTrace
		, sqlserver.session_id	-- SPID from SQLTrace
	)
	WHERE 
	(
		duration >= 5000000
	)
),
ADD EVENT sqlos.wait_info(
	ACTION 
	(
		  sqlserver.client_app_name	-- ApplicationName from SQLTrace
		, sqlserver.client_hostname	-- HostName from SQLTrace
		, sqlserver.client_pid	-- ClientProcessID from SQLTrace
		, sqlserver.database_id	-- DatabaseID from SQLTrace
		, sqlserver.request_id	-- RequestID from SQLTrace
		, sqlserver.server_principal_name	-- LoginName from SQLTrace
		, sqlserver.session_id	-- SPID from SQLTrace
	)
	WHERE
	(
		duration > 5000 --This one is in milliseconds, and I'm not happy about that
            AND ((wait_type > 0 AND wait_type < 22) -- LCK_ waits
                    OR (wait_type > 31 AND wait_type < 38) -- LATCH_ waits
                    OR (wait_type > 47 AND wait_type < 54) -- PAGELATCH_ waits
                    OR (wait_type > 63 AND wait_type < 70) -- PAGEIOLATCH_ waits
                    OR (wait_type > 96 AND wait_type < 100) -- IO (Disk/Network) waits
                    OR (wait_type = 107) -- RESOURCE_SEMAPHORE waits
                    OR (wait_type = 113) -- SOS_WORKER waits
                    OR (wait_type = 120) -- SOS_SCHEDULER_YIELD waits
                    OR (wait_type = 178) -- WRITELOG waits
                    OR (wait_type > 174 AND wait_type < 177) -- FCB_REPLICA_ waits
                    OR (wait_type = 186) -- CMEMTHREAD waits
                    OR (wait_type = 187) -- CXPACKET waits
                    OR (wait_type = 207) -- TRACEWRITE waits
                    OR (wait_type = 269) -- RESOURCE_SEMAPHORE_MUTEX waits
                    OR (wait_type = 283) -- RESOURCE_SEMAPHORE_QUERY_COMPILE waits
                    OR (wait_type = 284) -- RESOURCE_SEMAPHORE_SMALL_QUERY waits
	--OR (wait_type = 195) -- WAITFOR
                )
	)
)
ADD TARGET package0.event_file
(
	SET filename = 'DurationOver5Sec.xel',
		max_file_size = 10,
		max_rollover_files = 5
)
WITH 
(
	MAX_MEMORY = 10MB
	, MAX_EVENT_SIZE = 10MB
	, STARTUP_STATE = ON
	, MAX_DISPATCH_LATENCY = 5 SECONDS
	, EVENT_RETENTION_MODE = ALLOW_MULTIPLE_EVENT_LOSS
);

ALTER EVENT SESSION DurationOver5Sec
ON SERVER
STATE = START;
	
	
	
-- работа с данными
DECLARE 
	@SessionName SysName 
	, @TopCount Int = 1000

--SELECT @SessionName = 'UserErrors'
SELECT @SessionName = 'DurationOver5Sec'
--SELECT @SessionName = 'system_health'
/* 
SELECT * FROM sys.traces

SELECT  Session_Name = s.name, s.blocked_event_fire_time, s.dropped_buffer_count, s.dropped_event_count, s.pending_buffers
FROM sys.dm_xe_session_targets t
	INNER JOIN sys.dm_xe_sessions s ON s.address = t.event_session_address
WHERE target_name = 'event_file'
--*/

SET STATISTICS IO, TIME ON

IF OBJECT_ID('tempdb..#Events') IS NOT NULL BEGIN
	DROP TABLE #Events
END

IF OBJECT_ID('tempdb..#Queries') IS NOT NULL BEGIN
	DROP TABLE #Queries 
END

DECLARE @Target_File NVarChar(1000)
	, @Target_Dir NVarChar(1000)
	, @Target_File_WildCard NVarChar(1000)

SELECT @Target_File = CAST(t.target_data as XML).value('EventFileTarget[1]/File[1]/@name', 'NVARCHAR(256)')
FROM sys.dm_xe_session_targets t
	INNER JOIN sys.dm_xe_sessions s ON s.address = t.event_session_address
WHERE s.name = @SessionName
	AND t.target_name = 'event_file'

SELECT @Target_Dir = LEFT(@Target_File, Len(@Target_File) - CHARINDEX('\', REVERSE(@Target_File))) 

SELECT @Target_File_WildCard = @Target_Dir + '\'  + @SessionName + '_*.xel'

--SELECT @Target_File_WildCard

SELECT TOP (@TopCount) CAST(event_data AS XML) AS event_data_XML
INTO #Events
FROM sys.fn_xe_file_target_read_file(@Target_File_WildCard, null, null, null) AS F
ORDER BY File_name DESC
	, file_offset DESC 

SELECT  EventType = event_data_XML.value('(event/@name)[1]', 'varchar(50)')
	, Duration_sec = CAST(event_data_XML.value ('(/event/data[@name=''duration'']/value)[1]', 'BIGINT')/CASE WHEN event_data_XML.value('(event/@name)[1]', 'varchar(50)') LIKE 'wait%' THEN 1000.0 ELSE 1000000.0 END as DEC(20,3)) 
	, CPU_sec = CAST(event_data_XML.value ('(/event/data[@name=''cpu_time'']/value)[1]', 'BIGINT')/1000000.0 as DEC(20,3))
	, physical_reads_k = CAST(event_data_XML.value ('(/event/data  [@name=''physical_reads'']/value)[1]', 'BIGINT')/1000.0 as DEC(20,3))
	, logical_reads_k = CAST(event_data_XML.value ('(/event/data  [@name=''logical_reads'']/value)[1]', 'BIGINT') /1000.0 as DEC(20,3))
	, writes_k = CAST(event_data_XML.value ('(/event/data  [@name=''writes'']/value)[1]', 'BIGINT')/1000.0 as DEC(20,3))
	, row_count = event_data_XML.value ('(/event/data  [@name=''row_count'']/value)[1]', 'BIGINT')
	, Statement_Text = ISNULL(event_data_XML.value ('(/event/data  [@name=''statement'']/value)[1]', 'NVARCHAR(4000)'), event_data_XML.value ('(/event/data  [@name=''batch_text''     ]/value)[1]', 'NVARCHAR(4000)')) 
	, TimeStamp = DateAdd(Hour, DateDiff(Hour, GetUTCDate(), GetDate()) , CAST(event_data_XML.value('(event/@timestamp)[1]', 'varchar(50)') as DateTime2))
	, SPID = event_data_XML.value ('(/event/action  [@name=''session_id'']/value)[1]', 'BIGINT')
	, Username = event_data_XML.value ('(/event/action  [@name=''server_principal_name'']/value)[1]', 'NVARCHAR(256)')
	, Database_Name = DB_Name(event_data_XML.value ('(/event/action  [@name=''database_id'']/value)[1]', 'BIGINT'))
	, client_app_name = event_data_XML.value ('(/event/action  [@name=''client_app_name'']/value)[1]', 'NVARCHAR(256)')
	, client_hostname = event_data_XML.value ('(/event/action  [@name=''client_hostname'']/value)[1]', 'NVARCHAR(256)')
	, result = ISNULL(event_data_XML.value('(/event/data  [@name=''result'']/text)[1]', 'NVARCHAR(256)'),event_data_XML.value('(/event/data  [@name=''message'']/value)[1]', 'NVARCHAR(256)'))
	, Error = event_data_XML.value ('(/event/data  [@name=''error_number'']/value)[1]', 'BIGINT')
	, Severity = event_data_XML.value ('(/event/data  [@name=''severity'']/value)[1]', 'BIGINT')
	, EventDetails = event_data_XML 
INTO #Queries
FROM #Events

SELECT q.EventType
	, q.Duration_sec
	, q.CPU_sec
	, q.physical_reads_k
	, q.logical_reads_k
	, q.writes_k
	, q.row_count
	, q.Statement_Text
	, q.TimeStamp
	, q.SPID
	, q.Username
	, q.Database_Name
	, client_app_name = CASE LEFT(q.client_app_name, 29)
					WHEN 'SQLAgent - TSQL JobStep (Job '
						THEN 'SQLAgent Job: ' + (SELECT name FROM msdb..sysjobs sj WHERE substring(q.client_app_name,32,32)=(substring(sys.fn_varbintohexstr(sj.job_id),3,100))) + ' - ' + SUBSTRING(q.client_app_name, 67, len(q.client_app_name)-67)
					ELSE q.client_app_name
					END  
	, q.client_hostname
	, q.result
	, q.Error
	, q.Severity
	, q.EventDetails
FROM #Queries q
--WHERE eventtype NOT IN /*rather typical filtering*/ ('security_error_ring_buffer_recorded', 'sp_server_diagnostics_component_result', 'scheduler_monitor_system_health_ring_buffer_record')
	--AND eventtype NOT IN /*specific troubleshooting filtering*/ ('connectivity_ring_buffer_recorded', 'wait_info')
ORDER BY TimeStamp DESC 