-- Основное
	Если функция табличная - SELECT * FROM FUNCTION_NAME
	Если скалярная - exec FUNCTION_NAME

	-- Новые функции 2012+
		- EXEC PROCNAME ... WITH RESULT SETS (позволяет поменять имена столбцов на свои)
		- THROW (обработка ошибок)
		- OFFSET FETCH (работа со страницами данных). Это расширение для ORDER BY
		- Sequence - счётчик(ID) для нескольких таблиц
		- OVER (оконные функции)
			SUM(OrderQuantity) OVER (PARTITION BY City ORDER BY OrderYear
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningQty
		- PARSE, TRY_PARSE, TRY_CONVERT
		- IIF, CHOOSE
		- CONCAT И FORMAT

