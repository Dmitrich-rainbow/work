	1. Выгрузить все процедуры
		А. SELECT r.Routine_Definition
			FROM INFORMATION_SCHEMA.Routines r 
			
		Б. SELECT m.object_id
				 ,o.name
				 ,m.definition
			FROM sys.sql_modules AS m
			INNER JOIN sys.objects AS o
				ON m.object_id = o.object_id
			WHERE o.type = 'P'