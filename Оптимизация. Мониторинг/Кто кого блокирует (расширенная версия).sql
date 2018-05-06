
-- Получение информации о блокирующих процессах
	SELECT DB_NAME(pr1.dbid) AS 'DB'
		  ,pr1.spid AS 'ID жертвы'
		  ,RTRIM(pr1.loginame) AS 'Login жертвы'      
		  ,pr1.waittime/1000 as 'Время ожидания жертвы, sec'
		  ,pr2.spid AS 'ID виновника'
		  ,RTRIM(pr2.loginame) AS 'Login виновника'
		  ,pr1.program_name AS 'программа жертвы'
		  ,pr2.program_name AS 'программа виновника'
		  ,txt.[text] AS 'Запрос виновника'
		  ,pr1_txt.[text] AS 'Запрос жертвы'
		  ,pr1.login_time
		  ,pr1.last_batch INTO #blocking_info
	FROM   MASTER.dbo.sysprocesses pr1(NOLOCK)
		   JOIN MASTER.dbo.sysprocesses pr2(NOLOCK)
				ON  (pr2.spid = pr1.blocked) 
		   OUTER APPLY sys.[dm_exec_sql_text](pr2.[sql_handle]) AS txt
		   OUTER APPLY sys.[dm_exec_sql_text](pr1.[sql_handle]) AS pr1_txt
	WHERE  pr1.blocked <> 0
	

-- Получение информации и объектах блокировки	
	SELECT s.[nt_username]
	  ,tran_locks.resource_database_id
      ,request_session_id
      ,tran_locks.[request_status]
      ,rd.[Description] + ' (' + tran_locks.resource_type + ' ' + tran_locks.request_mode + ')' [Object]
      ,txt_blocked.[text]
      ,COUNT(*) [COUNT] INTO #Blocking_detailed
FROM   sys.dm_tran_locks AS tran_locks WITH (NOLOCK)
       JOIN sys.sysprocesses AS s WITH (NOLOCK)
            ON  tran_locks.request_session_id = s.[spid]
       JOIN (
                SELECT 'KEY' AS sResource_type
                      ,p.[hobt_id] AS [id]
                      ,QUOTENAME(o.name) + '.' + QUOTENAME(i.name) AS [Description]
                FROM   sys.partitions p
                       JOIN sys.objects o
                            ON  p.object_id = o.object_id
                       JOIN sys.indexes i
                            ON  p.object_id = i.object_id
                            AND p.index_id = i.index_id
                UNION ALL
                SELECT 'RID' AS sResource_type
                      ,p.[hobt_id] AS [id]
                      ,QUOTENAME(o.name) + '.' + QUOTENAME(i.name) AS [Description]
                FROM   sys.partitions p
                       JOIN sys.objects o
                            ON  p.object_id = o.object_id
                       JOIN sys.indexes i
                            ON  p.object_id = i.object_id
                            AND p.index_id = i.index_id
                UNION ALL
                SELECT 'PAGE'
                      ,p.[hobt_id]
                      ,QUOTENAME(o.name) + '.' + QUOTENAME(i.name)
                FROM   sys.partitions p
                       JOIN sys.objects o
                            ON  p.object_id = o.object_id
                       JOIN sys.indexes i
                            ON  p.object_id = i.object_id
                            AND p.index_id = i.index_id
                
                UNION ALL
                SELECT 'OBJECT'
                      ,o.[object_id]
                      ,QUOTENAME(o.name)
                FROM   sys.objects o
            ) AS RD
            ON  RD.[sResource_type] = tran_locks.resource_type
            AND RD.[id] = tran_locks.resource_associated_entity_id
       OUTER APPLY sys.[dm_exec_sql_text](s.[sql_handle]) AS txt_Blocked
WHERE  (
           tran_locks.request_mode = 'X'
           AND tran_locks.resource_type = 'OBJECT'
       )
       OR  tran_locks.[request_status] = 'WAIT'
GROUP BY
       s.[nt_username]
      ,tran_locks.resource_database_id
      ,request_session_id
      ,tran_locks.[request_status]
      ,rd.[Description] + ' (' + tran_locks.resource_type + ' ' + tran_locks.request_mode + ')'
      ,txt_blocked.[text]

-- Сведение информации в одну таблицу
	SELECT bi.*, bd.[Object] FROM #blocking_info bi INNER JOIN #Blocking_detailed bd ON bi.[ID жертвы] = bd.request_session_id

-- Подробности и виновнике блокировок
	SELECT spid,loginame,lastwaittype,DB_NAME(er.[dbid]) as [DB_NAME],[status],cmd,[program_name],cpu,physical_io,login_time,last_batch,[text] FROM sys.sysprocesses er
	left join sys.dm_exec_query_stats qs on er.sql_handle=qs.sql_handle
	outer apply sys.dm_exec_sql_text((er.sql_handle)) st
	WHERE spid IN (SELECT DISTINCT [ID виновника] FROM #blocking_info)
	
	
	DROP TABLE #blocking_info
	DROP TABLE #Blocking_detailed 