-- Если используется версия ниже SQL Server R2(Sp2), то там нет DMV sys.dm_db_stats_properties

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
AND [rows] > 1000 -- Ограничиваем выборку 1000 строками, так как на таком малом объёме автоматическое обновление работает корректно, если auto_update statistics отключено, то можно рассмотреть отключение данного фильтра, но auto_update statistics отключать не рекомендуется без доп. тестов и без взятия на себя ответственности за её обновление
AND (sp.modification_counter >  CASE WHEN (sp.rows < 25000)
		THEN (sqrt((sp.rows) * 1000))
	WHEN ((sp.rows) > 25000 AND (sp.rows) <= 10000000)
		THEN ((sp.rows) * 0.10 + 500)
	WHEN ((sp.rows) > 10000000 AND (sp.rows) <= 100000000)
		THEN ((sp.rows) * 0.03 + 500)
	WHEN ((sp.rows) > 100000000)
		THEN ((sp.rows) * 0.01 + 500) END
OR (rows_sampled < rows/2 and ss.name NOT LIKE '_WA_Sys%')) -- Сделано для исправления проблем auto_update statistics. При auto_update statistics сбарсывается счётчик sp.modification_counter и сервер считает что статистика обновлена, но она может быть обновлена с очень плохим SAMPLE. В данном скрипте обрабатывается ситуация когда SAMPLE < 50%
AND sp.last_updated < getdate() - 1 -- Ограничиваем отбор статистикой обновляемой более деня назад
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