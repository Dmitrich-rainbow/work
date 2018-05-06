DECLARE @Path        nvarchar(260)
       ,@SessionName nvarchar(256) = 'Wait Statistics';

SET @Path = (SELECT LEFT(dxsoc.column_value, LEN(dxsoc.column_value) - CHARINDEX('.', REVERSE(dxsoc.column_value))) + '*.' + 
                    RIGHT(dxsoc.column_value, CHARINDEX('.', REVERSE(dxsoc.column_value)) - 1)
             FROM   sys.dm_xe_session_object_columns AS dxsoc 
                    INNER JOIN sys.dm_xe_sessions AS dxs 
                            ON dxs.address = dxsoc.event_session_address
             WHERE dxs.name = @SessionName
                   AND dxsoc.object_name = 'event_file'
                   AND dxsoc.column_name = 'filename');

;WITH TargetData
AS
(
    SELECT CONVERT(XML, event_data) AS event_data
          ,file_name
          ,file_offset
    FROM   sys.fn_xe_file_target_read_file(@Path, NULL, NULL, NULL)
)

SELECT event_data.value('/event[1]/@timestamp', 'datetime') AS timestamp
      ,event_data.value('/event[1]/@name', 'nvarchar(128)') AS name
      ,event_data.value('(/event[1]/action[@name="session_id"]/value)[1]', 'smallint') AS session_id
      ,event_data.value('(/event[1]/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS sql_text
      ,event_data.value('(/event[1]/data[@name="mode"]/text)[1]', 'nvarchar(max)') AS latch_mode
      ,event_data.value('(/event[1]/data[@name="duration"]/value)[1]', 'decimal(20,0)') AS duration
      ,event_data.value('(/event[1]/data[@name="database_id"]/value)[1]', 'bigint') AS database_id
      ,event_data.value('(/event[1]/data[@name="file_id"]/value)[1]', 'int') AS file_id
      ,event_data.value('(/event[1]/data[@name="page_id"]/value)[1]', 'bigint') AS page_id
      ,event_data.value('(/event[1]/data[@name="splitOperation"]/text)[1]', 'nvarchar(max)') AS splitOperation
      ,event_data.value('(/event[1]/data[@name="new_page_file_id"]/value)[1]', 'int') AS new_page_file_id
      ,event_data.value('(/event[1]/data[@name="new_page_page_id"]/value)[1]', 'bigint') AS new_page_page_id
FROM   TargetData
ORDER  BY timestamp;
GO