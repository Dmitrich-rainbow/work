-- Параллелизм
	- Доходило до блокировок
	
-- Основное
	- В 1с 8.3. Изначально устанавливается свойство БД:
		ALTER DATABASE arttourv8base_company_new
		SET ALLOW_SNAPSHOT_ISOLATION ON


		ALTER DATABASE arttourv8base_company_new
		SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE
		
-- Встроенный мониторинг производительности
	http://v8.1c.ru/expert/pmc/pmc_overview.htm
	
-- Иногда помогает
	DBCC FREEPROCCACHE