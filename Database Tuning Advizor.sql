-- Основное
	- Не подсовывать трассу более 100 мб
	- Может зависнуть, необходимо звершить сессию и удалить остатки проверки

-- Найти остатки от проверок
	WITH hi AS (
	SELECT QUOTENAME(SCHEMA_NAME(o.[schema_id])) +'.'+ QUOTENAME(OBJECT_NAME(i.[object_id])) AS [Table] , QUOTENAME([i].[name]) AS [Index_or_Statistics], 1 AS [Type]
	FROM sys.[indexes] AS [i]
	JOIN sys.[objects] AS [o]
	ON i.[object_id] = o.[object_id]
	WHERE 1=1 
	AND INDEXPROPERTY(i.[object_id], i.[name], 'IsHypothetical') = 1
	AND OBJECTPROPERTY([o].[object_id], 'IsUserTable') = 1
	UNION ALL
	SELECT QUOTENAME(SCHEMA_NAME(o.[schema_id])) +'.'+ QUOTENAME(OBJECT_NAME(o.[object_id])) AS [Table], QUOTENAME([s].[name]) AS [Index_or_Statistics], 2 AS [Type]
	FROM sys.[stats] AS [s]
	JOIN sys.[objects] AS [o]
	ON [o].[object_id] = [s].[object_id]
	WHERE [s].[user_created] = 0
	AND [o].[name] LIKE '[_]dta[_]%'
	AND OBJECTPROPERTY([o].[object_id], 'IsUserTable') = 1
	)
	SELECT [hi].[Table] ,
		   [hi].[Index_or_Statistics] ,
		   CASE [hi].[Type] 
		   WHEN 1 THEN 'DROP INDEX ' + [hi].[Index_or_Statistics] + ' ON ' + [hi].[Table] + ';'
		   WHEN 2 THEN 'DROP STATISTICS ' + hi.[Table] + '.' + hi.[Index_or_Statistics] + ';'
		   ELSE 'DEAR GOD WHAT HAVE YOU DONE?'
		   END AS [T-SQL Drop Command]
	FROM [hi]