-- Память
	1. Процент использования памяти -- Alert > 95% дольше 10-30 минут
	2. Page life expectancy по каждой NUMA Node (SQLServer:Buffer Node - Page life expectancy) -- Сбор статистики. Может возвращать более 1 значение
	
-- CPU
	1. Процент использования CPU -- Сбор статистики
	
-- Диски
	1. Процент свободного места -- Alert < 10% 
	2. Задержки на чтение/запись (LogicalDisk:Avg.Disk sec\Write и LogicalDisk:Avg.Disk sec\Read) -- Сбор статистики
	3. Очередь дисков (LogicalDisk:Avg. Disk Write Queue Length и LogicalDisk:Avg. Disk Read Queue Length) -- Сбор статистики
	4. Количество чтений/записи (LogicalDisk:Disk Writes\sec и LogicalDisk:Disk Reads\sec)-- Сбор статистики
	
-- Блокировки
	1. Количество блокировок (SQL Server:General Statistics - Process blocked) -- Сбор статистики
	2. Время, затраченное на блокировки (SQLServer: Locks - Average Wait Time) -- Сбор статистики
	3. Deadlock (SQLServer: Locks - Number of Deadlocks/sec)-- Сбор статистики
	
-- Доступность
	1. SQL Server -- Alert if OFF
	2. SQL Server Agent -- Alert if OFF
	3. Windows Server -- Alert if OFF
	
-- Задания (если требуется)
	1. При неудачном завершении задания, включить опцию писать в Application Log для определённых заданий (например автоматическое восстановление БД). Application Log парсить на предмет Source: "MSSQL" или "SQLAgent" и Level: "Error". Исключить где EventID: 995 или в теле сообщения содержится "SQLVDI" -- Оповещать на почту/смс (Требуется тестирование такого шаблона, так как точно будут падать избыточные сообщения)
	
-- Кластер
	1. Failover (как это делается по-моему описано тут http://habrahabr.ru/sandbox/20567/)


