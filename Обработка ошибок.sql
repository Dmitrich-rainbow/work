-- BEGIN TRY
	- Не ловит ошибки DBCC

-- SET XACT_ABORT OFF
	- Указывает, выполняет ли SQL Server автоматический откат текущей транзакции, если инструкция языка Transact-SQL вызывает ошибку выполнения.
	- Позволяет подтвердить выполнение операции при возникновении ошибки
	
-- Пример
	- Выключаем SET XACT_ABORT OFF
	- После чего TRY...CATCH будет работать исправно