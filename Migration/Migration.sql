Способы:
	1. Detach/Attach 
		- Получилось сделать с 2000 на 20008 (нет возможности отката после Attach, только из backup)
	2. Миграция кластера
		- Установка нового кластера и перенос туда лунов и БД		

-- Что будет исключено в новых версиях
	SELECT instance_name   AS [Старый функционал]
		 , sum(cntr_value) AS [Число использований]
	FROM   sys.dm_os_performance_counters
	WHERE  object_name = 'SQLServer:Deprecated Features'
	AND    cntr_value <> 0
	GROUP BY instance_name
	ORDER BY [Число использований] DESC
	
-- SQL Server Data Migration Assistant
	- Помогает проанализировать возможность миграции с других СУБД
		https://msdn.microsoft.com/en-us/library/mt613434.aspx
	- Миграция между версия SQL Server
		https://www.microsoft.com/en-us/download/details.aspx?id=53595
		
-- Database Experimentation Assistant
	- Собирает счётчики и нагрузку и проигрывает её на новом SQL Server
		
-- Microsoft Assessment and Planning (MAP) Toolkit for SQL Server
	- map tool
	- Собирает excel
	- Получить доп. информацию для миграции
	- https://www.google.ru/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&ved=0ahUKEwjnxdfMqM7RAhXJd5oKHTjkBPIQFggcMAA&url=https%3A%2F%2Ftechnet.microsoft.com%2Fen-us%2Fsolutionaccelerators%2Fdd537572.aspx&usg=AFQjCNFGFr9iEpwBD2hmkw0QiPS7Q9uwsQ&sig2=1YkKi46qOUZPWxxckHL8iA
		
-- Проверка вашей нагрузки на другой версии SQL Server/Microsoft® Database Experimentation Assistant Technical Preview
	https://www.microsoft.com/en-us/download/details.aspx?id=54090
	
-- Возможность миграции
	- Большие версии не поддерживают все уровни совместимости в коде
	- По Collation. Если БД уже работает в другом COllation, то скорее всего она будет работать с любым другим
	- Те БД, которые не могут быть перенесены на поддерживаемую версию SQl, располагаются на виртуальной среде
	- Количество кластерных экземпляров максимум 21, по количеству букв в англ алфавите, начиная с 2014 можно использовать mount point для кластерного диска
		- SQL RPC: Completed и SQL: BatchCompleted и Duration > 0 + PerfMon (4 часа)
		- Геграфия подключений
		- Для динамического кода в Tuning Advizor > SQL: BatchCompleted (4 часа не более 100 Мб на файл иначе может подвиснуть)
	
-- Проверки после миграции
	1. Почта, бывает что не регистрируется сама
	2. Может перевести режим аутентификации с windows
	3. Не забыть снять FULL backup, так как пойдёт новая цепочка логов
	
-- Что нужно/Миграция stand alone instance
	0. Проверить совместимость с Windows
	0.1. Backup Windows, например Snapshot
	0.2. Скачать дистрибутивы
	1. Проверить код и структуру БД
		- Upgrade Advizor (Кроме просто проверки хранимок нужно собрать трассу SQL:BatchCompleted) (SQL:StmtCompleted, SQL:BatchCompleted, SP:Completed, RPC:Completed, SP:StmtCompleted). Можно запускать на рабочей системе
	1.1. Снять базовую нагрузку чтобы можно было сранить после миграции (SQL:BatchCompleted, RPC:Completed)
	1.2. Синтетическое нагрузочное тестирование
		- Distributed replay (подсовываем трассу и эмулируем нагрузку). В момент прогона трассы снимаем новую > засовываем в таблице > группируем > сравниваем с прошлым сервером
	1.3. SQL Server Data Migration Assistant
	2. Проверить изменения/Breaking Change
		https://technet.microsoft.com/en-us/library/ms143179%28v=sql.110%29.aspx?f=255&MSPPError=-2147217396
	3. Убедиться что у вас не Express и Developer Edition
	4. Запустить проверку DBCC CHECKDB WITH DATA_PURITY; на совместимость типов данных
	5. Запустить исправление неточностей определение занимаемого пространства DBCC UPDATEUSAGE(db_name);
	6. Обновить статистику
	7. sp_refreshview	
	
-- Checklist
	1. Админы
		- скрипт Пернос пользователей на др. сервер (Microsoft) - Основной.sql
	2. Например может быть x86 и не подойдёт для миграции
	4. Collation
	5. Изменение конфигурации
		SELECT * FROM sys.configurations c1 INNER JOIN [MS-CLUSTER1-LNC\MSLYNC].master.sys.configurations c2 ON c1.configuration_id = c2.configuration_id
		WHERE c1.value_in_use <> c2.value_in_use
	6. Пользовательские сообщения об ошибках
		SELECT * FROM sys.messages ORDER BY message_id DESC
	7. Linked Server, важно что могут быть х32, на х64
		SELECT * FROM sys.servers
	8. Уровень совместимости
	9. Jobs
	10. Mirroring, Log Shipping, Replication, SSIS пакеты
		Select * from sysssispackages
	11. assembly
		-- Найти assembly/найти dll
			SELECT 
				assembly = a.name, 
				path     = f.name
			FROM sys.assemblies AS a
			INNER JOIN sys.assembly_files AS f
			ON a.assembly_id = f.assembly_id
			WHERE a.is_user_defined = 1;
	12. Проверить наличие ключей
		-- Как посмотреть ключи/Keys
			SELECT * FROM [sys].[openkeys]
	
		-- Проверить есть ли шифрование в БД
			USE [master]
			GO
			SELECT db.[name]
			, db.[is_encrypted]
			, dm.[encryption_state]
			, dm.[percent_complete]
			, dm.[key_algorithm]
			, dm.[key_length]
			FROM [sys].[databases] db
			LEFT OUTER JOIN [sys].[dm_database_encryption_keys] dm
			ON db.[database_id] = dm.[database_id];
			GO	
	13. Убедиться что сервер не использует AWE, так как он усечен в 2012 версии
		SELECT * FROM sys.configurations WHERE name like '%awe%'
	14. Используется ли аутентификация SQL или нет
	15. По мимо названия экземпляра уточнить необходимость статического порта, так же проверить на каком порту сейчас работает
	16. Не забыть снять FULL backup, так как пойдёт новая цепочка логов
	17. Права учётной записи SQL Server на 'perform volume task' и 'lock page in memory'
	18. Базовые флаги трассировки
		-T1117 -- Позволяет активировать рост сразу всех файлов бд одновременно, может применяться для равномерного роста файлов tempdb	
		-T1118 -- увеличение параллелизма для Tempdb
		-T2371 -- Изменить автоматическое обновление статистики, чтобы было чаще, а не при 20% изменений
		-T3226 -- отключение записи в лог успешного резервного копирования
		-T8048 -- Обязательно включить если 8 и более CPU на сокет
		-T4199 -- влючить все хотфиксы для оптимизатора, которые были сделаны 'on-demand'
	19. Replication/репликация
	20. SELECT * FROM Sys.Plan_Guides
	21. Сохранить системные БД если их нужно перенести, так как если мы устанавливаем экземпляр в ту же папку, то они будут перезаписаны

		
-- Автоматизация переноса
	1. На хосте1 делаем backup LOG перед работами
	2. На хосте2 делаем Restore LOG
	3. На хосте1 переводим БД в SINGLE USER
	4. На хосте1 делаем backup LOG перед работами
	5. На хосте1 переводим БД в offline
	6. На хосте2 делаем Restore LOG
	7. На хосте2 переводим БД в MULTI USER
	
-- Устаревшие механизмы
	- На 2000 можно было делать отсортированные VIEW с top, сейчас это не поддерживается
	
-- Изменение hostname	
	- Для Stand-alone
		1. Не поддерживается для SQL Server, который вовлечён в репликацию
		2. Если на сервере работает и Reporting Services, то нужно выполнить ещё и https://msdn.microsoft.com/en-us/library/ms345235.aspx?f=255&MSPPError=-2147217396
		3. When you rename a computer that is configured to use database mirroring, you must turn off database mirroring before the renaming operation. Then, re-establish database mirroring with the new computer name. Metadata for database mirroring will not be updated automatically to reflect the new computer name. Use the following steps to update system metadata.
		4. Поменять на стороне приложения hostname		
		5. Для линкед серверов так же необходимо будет выполнить следующие настройки https://msdn.microsoft.com/en-us/library/ms190318.aspx?f=255&MSPPError=-2147217396
		
		- Для SQL Server с default instance name
			sp_dropserver <old_name>;
			GO
			sp_addserver <new_name>, local;
			GO
			
-- Обновление ключа
	- Запустить Upgrade Edition
	- Перезапустить SQL
	- Если это кластерная конфигурация, то необходимо перевести ноду на другую ноду, чтобы новый ключ применился и там
			
		- Для именнованного экземпляра
			sp_dropserver <old_name\instancename>;
			GO
			sp_addserver <new_name\instancename>, local;
			GO
			
		- Может потребоваться отключить всех пользователей от сервера, чтобы сработала процедура sp_dropserver
			sp_dropremotelogin old_name;
			sp_dropremotelogin old_name\instancename;
			
-- Миграция на другой кластер
	1. Build the new cluster with the new OS and SQL Server versions with SQL as a clustered instance with the same instance name (the OS name will be different, but well deal with that later).
	2. Copy all the logins, SSIS packages and jobs to the new clustered instance. (можно восстановить системные БД)
	3. On the night of the upgrade take the old clustered instance offline.
	4. Take a SAN snapshot of the LUN (this will be your rollback)
	5. Move the LUNs from the old cluster to the new cluster and bring the LUNs online and add them as clustered resources.
	6. Put the new clustered disks into the SQL Server resource group.
	7. Make the SQL Server service dependent on the clustered disks within the failover cluster manager.
	8. Attach the databases to the new clustered instance.
	9. Add a new network name resource to the cluster based on the old clustered instances network name (this will probably require that you delete the network name from Active Directory first).
	10. Add a new network IP resource to the cluster based on the old clustered instances IP address (optional)
	11. Test
	12. Once testing is complete delete the SAN snapshot.
	13. Done
	14. Проверить наличие assembly
	15. Проверить наличие ключей
	16. Upgrade Advizor
	
-- Миграция в облако
	- Migration from SQL Server to Azure SQL Database Using Transactional Replication (https://blogs.msdn.microsoft.com/sqlcat/2017/02/03/migration-from-sql-server-to-azure-sql-database-using-transactional-replication/)	
		
-- Где провёл:
	1. Эксар
		Вопросы после миграции: 
			- SQL Server Managment Studio 2008 является обычной программой и её наличие и отсутствие никак не влияет на работу SQL Server, но касательно второго вопроса, только с Managment Studio 2008 вы сможете подключиться к Integration Services 10.

			-  Это не должно стать проблемой. Обе службы оставлены для обратной совместимости и для работы старых пакетов в новом сервере. Обе они корректно работают с системной БД msdb. В идеале обновить все пакеты Integration Services до SQL Server 2012.

			- NT Service\MsDtsServer120 это сервисный аккаунт, который автоматически подхватывается службой в момент установки. Если не будет возникать ислючительных ситуаций, то аккаунт стоит оставить текущий, если будут проблемы с запуском от NT Service\MsDtsServer120, то можно поменять на Network Service.
			
	2. БургерРус (План миграции SQL Server 2012 на другой кластер)
		1. Установка нового кластера 
		2. Установка кластерного экземпляра SQL Server с тем же Instance Name, но с другим Cluster Resource Name и IP на выделенный диск/LUN 15 Гб. Имя диска должно быть P:\ (аналог текущего пути установки)
		3. Сравнение конфигураций старого и нового экземпляров SQL Server
		4. Создание backup БД
		5. Остановка старого экземпляра SQL Server
		6. Копирование системных БД во временную папку
		7. Переименование старого SQL Server и подмена IP или отключение ресурсной группы
		8. Остановка нового экземпляра SQL Server
		9. Перенос дисков со старого кластера на новый, подключение их в ресурсную группу SQL Server, настройка зависимостей
		10. Подмена системных БД со старого экземпляра SQL Server на новый (из временной папки). При возникновении проблем будет произведена операция Restore системных БД вместо подмены
		11. Запуск нового экземпляра SQL Server
		12. Проверка работы нового экземпляра SQL Server
		13. Подключение пользовательских БД (Attach Database)
		14. Проверка работы нового экземпляра SQL Server
		15. Переименование нового SQL Server и подмена IP
		16. Обновление DNS
		
	3. Volkswagen (2005-2012)
		- Чере новую установку, с новыми именами
		
-- Upgrade Advizor
	- Скачать и установить SQLDOM для нужной версии SQL и системы. Нужную ссылку подскажем сам установочник
	- Можно запускать на рабочей системе
	
-- Oracle, Sybase ASE, DB2, MySQL and Access
	- Скачать https://blogs.msdn.microsoft.com/ssma/2016/03/09/preview-release-of-sql-server-migration-assistant-ssma-for-sql-server-2016-rc0/
	- Как пользоваться https://msdn.microsoft.com/en-us/library/hh313041(v=sql.110).aspx