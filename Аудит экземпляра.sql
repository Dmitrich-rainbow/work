-- Основное
	-- sp_blitz
	-- Glen berry
	-- E:\SQL Scripts\Оптимизация. Мониторинг\Экспресс данные о экземпляре.sql
	- Дисковая подсистема справляется
	- Настроен регулярный backup
	- Размер БД
	
-- Результаты Аудита DIGISPOTSQL.voice.ru
	1. Характер нагрузки БД ruvrask - чтение:запись 400:1
	2. Среднее использование процессора под SQL Server - 54%, максимальное 77 (4 ядра)
	3. Отсутствие мониторинга и оповещений о важных ошибках SQL Server
	4. Почти все пользователи имеют права sysadmin
	5. Backup и сами БД лежат на одном диске
	6. Активное использование tempdb без оптимальной настройки
	7. SQL Server 2005, поддержка данной версии SQL Server закончилась 12.04.2016
	8. 32 битная версия SQL Server не позволяет съесть более 2х Гб оперативной памяти в штатном режиме и не более 3 Гб с использованием AWE технологии 