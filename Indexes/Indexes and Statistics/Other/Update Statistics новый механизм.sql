	WHEN (ssi2.rows < 25000)
		THEN (sqrt((ssi2.rows) * 1000))
	WHEN ((ssi2.rows) > 25000 AND (ssi2.rows) <= 10000000)
		THEN ((ssi2.rows) * 0.15 + 500)
	WHEN ((ssi2.rows) > 10000000 AND (ssi2.rows) <= 100000000)
		THEN ((ssi2.rows) * 0.03 + 500)
	WHEN ((ssi2.rows) > 100000000)
		THEN ((ssi2.rows) * 0.01 + 500)
	END
	
	AND sp.modification_counter > CASE WHEN (sp.rows < 25000)
		THEN (sqrt((sp.rows) * 1000))
	WHEN ((sp.rows) > 25000 AND (sp.rows) <= 10000000)
		THEN ((sp.rows) * 0.15 + 500)
	WHEN ((sp.rows) > 10000000 AND (sp.rows) <= 100000000)
		THEN ((sp.rows) * 0.03 + 500)
	WHEN ((sp.rows) > 100000000)
		THEN ((sp.rows) * 0.01 + 500) END
		
		
		
		
SELECT
    sch.name  AS 'Schema',
    so.name as 'Table',
    ss.name AS 'Statistic'
FROM sys.stats ss
JOIN sys.objects so ON ss.object_id = so.object_id
JOIN sys.schemas sch ON so.schema_id = sch.schema_id
OUTER APPLY sys.dm_db_stats_properties(so.object_id, ss.stats_id) AS sp
WHERE so.TYPE = 'U'
AND sp.modification_counter >  CASE WHEN (sp.rows < 25000)
		THEN (sqrt((sp.rows) * 1000))
	WHEN ((sp.rows) > 25000 AND (sp.rows) <= 10000000)
		THEN ((sp.rows) * 0.10 + 500)
	WHEN ((sp.rows) > 10000000 AND (sp.rows) <= 100000000)
		THEN ((sp.rows) * 0.03 + 500)
	WHEN ((sp.rows) > 100000000)
		THEN ((sp.rows) * 0.01 + 500) END
AND sp.last_updated < getdate() - 1 -- как давно последний раз обновлялась статистика
ORDER BY sp.last_updated