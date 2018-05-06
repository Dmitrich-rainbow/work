-- Основное
	1. Рентабельность
	2. Масштабируемость
	3. Мощность
	
	- Можно  платно купить Azure Management Studio
	
	-- SaaS
		- Сама программа в облаке
		- Ничего создавать не надо, даже никаких БД, просто выбираем услугу и пользуемся
		
	-- IaaS (Виртуальные машины, Инфраструктура)
		- Виртуалка с SQL Server с RDP
		
	-- PaaS (Платформа)
		- Облачная версия SQL Server (услуга)
		- Добавить в исключения IP подключающегося

-- Azure Data Factory
	- Сбор данных со всех источников и работа с ними
	
-- Доступ на уровне строк/row level security
	1. Создаём функцию. 
	2. С помощью политики прикрепляем эту функцию к таблице. 
	3. Теперь при любом селекте БД будет использовать эту функцию
	
	-- Минусы
		1. Ослабление безопасности (немного)
		2. При отключении политики, открывается доступ ко всем строкам
		3. В функции могут быть сложные условия
		4. В функциях можно обращаться и к другим таблицам/объектам
		5. Сказывается на производительности
	
	-- Плюсы
		1. Политика может регулировать доступ к нескольким таблицам
			CREATE SECURITY POLICY
			ADD FILTER...,
			ADD FILTER
			
	-- Особенности
		1. Может состоять только из 1 SELECT
		2. В одной политике 1 функция к одной таблице
		3. DELETE работает с учётом условий
		4. Ограничения на INSERT не действуют
		5. UPDATE работает корректно, с учётом условий
	
-- Посмотреть политики
	SELECT * FROM sys.Security_Policies
	SELECT * FROM sys.Security_Predicates -- Более подробно
	
-- Backup
	- https://docs.microsoft.com/en-us/azure/sql-database/sql-database-automated-backups
	- backup теперь делается не через page blocks, а через blob blocks. Это значительно ускоряет backup -- Точно в SQL Server 2016, возможно и ранее, но только в Azure
	- Автоматические Backup хранятся не более 35 дней, если требуется хранить дольше, то можно автоматически создавать и хранить .bacpac в хранилище BLOB-объектов 
	- Можно делать snapshot backup, что значительно быстрее. Условия:
		1. Все backup хранятся в Azure
		2. Требуется только в самом начале сделать FULL
		3. Далее требуется только backup LOG
		4. При ресторе пишем восстановление БД, а не лога, хотя по факту будут браться файлы логов
		5. Для RESTORE point in time требуется не вся цепочка LOG, а только 2, которые между ними. То есть LOG Рассматривается как самостоятельный файл
		6. При удалении БД, ломается данный backup
		
	-- Преимущества
		1. Дешевле
		2. Намного быстрее (почти моментально)
		
	-- Недостатки
		1. Удаление БД приводит к невозможности воспользоваться backup
		2. Не работает backup encryption, если БД не FULL encryption
		3. Не понятно как с повреждениями в backup?
		
-- Расширение AlwaysOn в Azure
	https://docs.microsoft.com/ru-ru/azure/virtual-machines/windows/sqlclassic/virtual-machines-windows-classic-sql-onprem-availability
	
--  Restore/Mitration
	- Для переноса БД с классического SQL Server, необходимо выполнить экспорт Бд в файл .bacpac и мипортировать его в Azure
	
-- Availability
	-- Активная георепликация	
		- Работает в асинхронном режиме
		- Реплицирует только зафиксированные транзакции
		
-- DMV
	-- Производительность
		sys.resource_stats -- Возвращает загрузку ЦП и данные хранилища для базы данных SQL Azure
		sys.dm_db_resource_stats -- Возвращает использование ЦП, ввода-вывода и памяти для База данных SQL Azure базы данных. 
		
-- Пользователи и логины
	- Если прав на БД нет, пользователь её не видит
	-- Создать логин	
		CREATE LOGIN <SQL_login_name, sysname, login_name> WITH PASSWORD = '<password, sysname, Change_Password>' 
	-- Создать пользователя 
		CREATE USER <user_name, sysname, user_name>	FOR LOGIN <login_name, sysname, login_name> WITH DEFAULT_SCHEMA = <default_schema, sysname, dbo>
	-- Дать права на уровне БД
		EXEC sp_addrolemember N'db_owner', N'<user_name, sysname, user_name>'
		ALTER ROLE db_owner ADD MEMBER blankdbadmin; 
	-- Посмотреть права пользователей
		SELECT prm.permission_name
		   , prm.class_desc
		   , prm.state_desc
		   , p2.name as 'Database role'
		   , p3.name as 'Additional database role' 
		FROM sys.database_principals p
		JOIN sys.database_permissions prm
		   ON p.principal_id = prm.grantee_principal_id
		   LEFT JOIN sys.database_principals p2
		   ON prm.major_id = p2.principal_id
		   LEFT JOIN sys.database_role_members r
		   ON p.principal_id = r.member_principal_id
		   LEFT JOIN sys.database_principals p3
		   ON r.role_principal_id = p3.principal_id
		WHERE p.name = 'sqladmin';
	-- Изменить БД по-умолчнаию
		Изменить строку подключения

-- firewall
	-- Уровень сервера
	EXEC sp_set_database_firewall_rule @name = N'sqldbtutorialdbFirewallRule', 
	  @start_ip_address = 'x.x.x.x', @end_ip_address = 'x.x.x.x';
	-- Уровень БД
		https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-set-database-firewall-rule-azure-sql-database
		
-- Отказоустойчивость
	- Сначала можно купить слабую машину, чтобы норм шла репликация данных и если будет проблема, её можно усилить и перевести туда нагрузку
	-- Георепликация (Geo-Replication)
		- Отказоустойчивость 1 БД
		- До 4 реплик на чтение
		- Только 1 БД в "группе"
		- Требует другого экземпляра
	-- Гибридные сценарии
		-- Azure
			1. Создать сеть
			2. Создать VPN на этой сети и подключиться к домену on-premiss
			3. Подключить Azure VM к новосозданной виртуальной сети
		
-- Подключение
	-- Azure Database
		- открыть порт
	-- Azure VM
		- Активировать внутреннюю безопасность SQL Server
		- создать endpoint
		- открыть порт на VM в Firewall
		
-- Мониторинг/monitor
	- Попробовать включить Thread Detections (Security). Система будет оповещать, если было странное поведение на SQl Server в целом (AI)
	
-- Миграция/ migration
	https://www.microsoft.com/en-us/download/details.aspx?id=53595 (Microsoft® Data Migration Assistant v3.3)
	https://docs.microsoft.com/en-us/azure/sql-database/sql-database-features 
	
-- What kind of workload is appropriate for Azure SQL Database?
	Most of the time, Azure SQL Database is positioned as most appropriate for transactional OLTP workloads, i.e. the workloads consisting primarily of many short transactions occurring at a high rate. While such workloads do indeed run well in Azure SQL Database, some types of analytical and data warehousing workloads can also use the service. In the Premium service tier, Azure SQL Database supports columnstore indexes, providing high compression ratios for large data volumes, and memory-optimized non-durable tables, which can be used for staging data without persisting it to disk. At higher Premium performance tiers, the level of query concurrency is similar to what can be achieved on a traditional SQL Server instance in a large VM, albeit without the ability to fine-tune resource consumption using Resource Governor.

	There are several limiting factors that determine whether an analytical workload can run efficiently, or at all, in Azure SQL Database:

	1. Database size limitations. Today, the largest available database size is 4 TB, currently ruling out the service as the platform for larger data warehouses. At the same time, if your data warehouse database exceeds this limit, but currently does not use columnstore indexes, then the compression benefit of columnstore may well put it comfortably within the limit even if the actual uncompressed data volume is much higher than 4 TB.

	2. Analytical workloads often use tempdb heavily. However, the size of tempdb is limited in Azure SQL Database.

	3. As mentioned in the earlier question about large data loads, the governance of transaction log writes, and mandatory full recovery model can make data loads slower.

	If your analytical or data warehousing workload can work within these limits, then Azure SQL Database may be a good choice. Otherwise, you may consider SQL Server running in an Azure VM, or, for larger data volumes measured in multiple terabytes, Azure SQL Data Warehouse with its MPP architecture.
	
-- Масштабирование
	https://docs.microsoft.com/en-us/azure/sql-database/sql-database-elastic-database-client-library
	https://docs.microsoft.com/en-us/azure/sql-database/sql-database-elastic-scale-introduction (Scaling out with Azure SQL Database)
	
	-- Минусы
		1. не поддерживает выборку данных из нескольких баз данных одновременно.
		
-- Extend on-premises Always On Availability Groups to Azure
	https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sqlclassic/virtual-machines-windows-classic-sql-onprem-availability
	