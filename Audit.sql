-- Варианты
	1. TRACE
		- Сбор в файла, потом из файла в таблицу
	2. C2 AUDIT
		- Не конфигурируется
		- Пишется в файла
		- Можно поменять место расположения трасы только если переместить БД master, лежит рядом с master. 
	3. DDL
		- Блокировки
		- Если хотим без блокировок, то нужно использовать Брокера, а это уже сложность разработки
		- Даёт возможность писать в таблицу
	4. Готовое решение Audit (Начиная с 2008)
	
-- Влючение аудита в security log
	1. Предоставление учётке SQL Server к ветке реестра HKLM\SYSTEM\CurrentControlSet\Services\EventLog\Security
	2. cmd > secpol.msc > UAC > Local Security Policy > Security Settings > Local POlicrs > User Rights Assignment > двойной клик Generate security log > Добавить группу или пользователя
	3. Создание спецификации
	4. Создание Аудита