-- Если используется версия ниже SQL Server R2(Sp2), то там нет DMV sys.dm_db_stats_properties

sp_configure 'cost threshold for parallelism', 30
GO
sp_configure 'max degree of parallelism', 4
RECONFIGURE

DECLARE @schema nvarchar(255), @table nvarchar(255), @statistic nvarchar(255), @query  nvarchar(4000)

DECLARE CursUpdateStatistic CURSOR FOR
SELECT
    sch.name  AS 'Schema',
    so.name as 'Table',
    ss.name AS 'Statistic'
FROM sys.stats ss
JOIN sys.objects so ON ss.object_id = so.object_id
JOIN sys.schemas sch ON so.schema_id = sch.schema_id
OUTER APPLY sys.dm_db_stats_properties(so.object_id, ss.stats_id) AS sp
WHERE so.TYPE = 'U'
AND sp.modification_counter > 3000
ORDER BY sp.last_updated
DESC

OPEN CursUpdateStatistic

FETCH NEXT FROM CursUpdateStatistic INTO @schema,@table,@statistic

WHILE @@FETCH_STATUS = 0
	BEGIN
	
		SET @query= 'UPDATE STATISTICS ['+ @schema+'].[' + @table+ '] [' + @statistic +'] WITH FULLSCAN'
		exec(@query)		
	
		FETCH NEXT FROM CursUpdateStatistic INTO @schema,@table,@statistic
	END
	
CLOSE CursUpdateStatistic
DEALLOCATE CursUpdateStatistic

GO
sp_configure 'cost threshold for parallelism', 32767
GO
sp_configure 'max degree of parallelism', 4
RECONFIGURE