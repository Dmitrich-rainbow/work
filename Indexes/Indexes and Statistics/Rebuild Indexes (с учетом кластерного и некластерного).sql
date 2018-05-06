-- http://blogs.msmvps.com/gladchenko/2008/03/30/tips-for-dba-using-sys-dm_db_index_physical_stats-in-a-script-to-rebuild-or-reorganize-indexes-no-partitions-sql-server-2005/

SELECT 'ALTER INDEX ALL ON [' + OBJECT_NAME(afp.OBJECT_ID) + '] REBUILD WITH ( ONLINE = ON );' AS [Инструкция T-SQL]
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, 'SAMPLED') AS afp
WHERE afp.database_id = DB_ID()
AND afp.index_type_desc IN ('CLUSTERED INDEX')
AND (afp.avg_fragmentation_in_percent >= 15 OR afp.avg_page_space_used_in_percent <= 60)
AND afp.page_count > 12
UNION ALL
SELECT [Инструкция T-SQL] = 
 CASE 
  WHEN afp.avg_fragmentation_in_percent >= 15 
  OR afp.avg_page_space_used_in_percent <= 60
  THEN 'ALTER INDEX [' + i.name + '] ON [' + OBJECT_NAME(afp.OBJECT_ID) + '] REBUILD WITH (ONLINE = ON);' 
  WHEN (afp.avg_fragmentation_in_percent < 15 AND afp.avg_fragmentation_in_percent >= 10)
  OR (afp.avg_page_space_used_in_percent > 60 AND afp.avg_page_space_used_in_percent < 75)
  THEN 'ALTER INDEX [' + i.name + '] ON [' + OBJECT_NAME(afp.OBJECT_ID) + '] REORGANIZE;'
 END
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, 'SAMPLED') AS afp
JOIN sys.indexes AS i 
ON (afp.OBJECT_ID = i.OBJECT_ID AND afp.index_id = i.index_id)
AND afp.database_id = DB_ID()
AND afp.index_type_desc IN ('NONCLUSTERED INDEX')
AND (
  (afp.avg_fragmentation_in_percent >= 10 AND afp.avg_fragmentation_in_percent < 15)
 OR (afp.avg_page_space_used_in_percent > 60 AND afp.avg_page_space_used_in_percent < 75)
 )
AND afp.page_count > 12
AND afp.OBJECT_ID NOT IN ( 
     SELECT OBJECT_ID 
     FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, 'SAMPLED') 
     WHERE database_id = DB_ID()
     AND index_type_desc IN ('CLUSTERED INDEX')
     AND (avg_fragmentation_in_percent >= 15 OR avg_page_space_used_in_percent < 60)
     AND page_count > 1
    )
ORDER BY [Инструкция T-SQL]
