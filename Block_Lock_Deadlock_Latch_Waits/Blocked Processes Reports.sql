-- До 2012
	- Using SQL Trace You might know this as Profiler. Capture a trace with the “Blocked Process Report” event which is located in the Error and Warnings event list. But don’t forget! You first have to decide on what it means for your system to have excessive blocking and configure the blocked process threshold accordingly. I’ve learned very recently that peoples’ ideas of excessive blocking vary a lot. In my own environment, I often look for blocking longer than 10 seconds. Other people use a threshold of 10 minutes!
	
	- Analyzing Traces With Blocked Process Report Viewer This is the tool I wrote that I hope you find useful. Right now it tells you who the lead blocker is. And I hope to expand the features into analysis soon. -- http://sqlblockedprocesses.codeplex.com/
	
-- После 2012 
	-- Подготовка
	CREATE EVENT SESSION MonitorBlocking
	ON SERVER
	ADD EVENT sqlserver.blocked_process_report
	ADD TARGET package0.ring_buffer(SET MAX_MEMORY=2048)
	WITH (MAX_DISPATCH_LATENCY = 5SECONDS)
	GO
	ALTER EVENT SESSION MonitorBlocking
	ON SERVER
	STATE=START
	GO
	EXECUTE sp_configure 'blocked process threshold', 15
	GO
	RECONFIGURE
	GO
	
	-- Разбор данных
	-- Query the XML to get the Target Data
	SELECT 
		n.value('(event/@name)[1]', 'varchar(50)') AS event_name,
		n.value('(event/@package)[1]', 'varchar(50)') AS package_name,
		DATEADD(hh, 
				DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP), 
				n.value('(event/@timestamp)[1]', 'datetime2')) AS [timestamp],
		ISNULL(n.value('(event/data[@name="database_id"]/value)[1]', 'int'),
				n.value('(event/action[@name="database_id"]/value)[1]', 'int')) as [database_id],
		n.value('(event/data[@name="database_name"]/value)[1]', 'nvarchar(128)') as [database_name],
		n.value('(event/data[@name="object_id"]/value)[1]', 'int') as [object_id],
		n.value('(event/data[@name="index_id"]/value)[1]', 'int') as [index_id],
		CAST(n.value('(event/data[@name="duration"]/value)[1]', 'bigint')/1000000.0 AS decimal(6,2)) as [duration_seconds],
		n.value('(event/data[@name="lock_mode"]/text)[1]', 'nvarchar(10)') as [file_handle],
		n.value('(event/data[@name="transaction_id"]/value)[1]', 'bigint') as [transaction_id],
		n.value('(event/data[@name="resource_owner_type"]/text)[1]', 'nvarchar(10)') as [resource_owner_type],
		CAST(n.value('(event/data[@name="blocked_process"]/value)[1]', 'nvarchar(max)') as XML) as [blocked_process_report]
	FROM
	(    SELECT td.query('.') as n
		FROM 
		(
			SELECT CAST(target_data AS XML) as target_data
			FROM sys.dm_xe_sessions AS s    
			JOIN sys.dm_xe_session_targets AS t
				ON s.address = t.event_session_address
			WHERE s.name = 'MonitorBlocking'
			  AND t.target_name = 'ring_buffer'
		) AS sub
		CROSS APPLY target_data.nodes('RingBufferTarget/event') AS q(td)
	) as tab
	GO
	