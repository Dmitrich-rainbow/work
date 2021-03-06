-- Получить значение, которое нужно скопировать в Hex Editor	
	SELECT 2784*8192 AS [My Offset] -- 2784 это страница
	
	-- После повреждения ошибка будет выглядеть следующим образом
		Table error: Object ID 2105058535, index ID 2, partition ID 72057594038910976, alloc unit ID 72057594039828480 (type In-row data), page (1:2784). Test (IS_OFF (BUF_IOERR, pBUF->bstat)) failed. Values are 12716041 and -4.
		

-- Прочитать данные со страницы
	DBCC TRACEON(3604)

	-- now read the page
		DBCC PAGE (Corrupt2K8, 1, 174, 1)
		
	-- Как получить start offset
		SELECT CONVERT (INT, 0x16d) as [END offset decimal] -- 0x16d берётся из Slot 15, Offset 0x1b5, Length 31 (вывод dbcc page)
		
	-- Длину строки так же получаем из DBCC page (LENGH)
	
-- Починка
	После нахождения проблемы, можно найти то же местои из backup и занименть проблемную точку