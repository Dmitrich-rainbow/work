-- Если используется версия ниже SQL Server R2(Sp2), то там нет DMV sys.dm_db_stats_properties

DECLARE @schema nvarchar(255), @table nvarchar(255), @statistic nvarchar(255), @query  nvarchar(4000)

DECLARE CursUpdateStatistic CURSOR FOR
select DISTINCT SCHEMA_NAME(uid) as gerg, -- Обязательно указать DISTINCT, чтобы убрать дубликаты
		object_name (i.id)as objectname,		
		i.name as indexname
		from sysindexes i INNER JOIN dbo.sysobjects o ON i.id = o.id
		LEFT JOIN sysindexes si ON si.id = i.id AND si.rows > 0 -- добавлено для анализа статистики столбцов
		where i.rowmodctr > 
		CASE WHEN (si.rows < 25000)
			THEN (sqrt((i.rows) * 1000))
		WHEN ((si.rows) > 25000 AND (si.rows) <= 10000000)
			THEN ((si.rows) * 0.10 + 500)
		WHEN ((si.rows) > 10000000 AND (si.rows) <= 100000000)
			THEN ((si.rows) * 0.03 + 500)
		WHEN ((si.rows) > 100000000)
			THEN ((si.rows) * 0.01 + 500)
		END
		AND i.name not like 'sys%'
		AND object_name(i.id) not like 'sys%'
		AND STATS_DATE(i.id, i.indid) < GetDATE()-1

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