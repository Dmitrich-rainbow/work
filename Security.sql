-- Основное
	1. Каталог пользователей sys.server_principals
	2. Показать всех пользователей БД
		SELECT s.name as [Login Name], d.name as [User Name],
		default_schema_name as [Default Schema]
		FROM sys.database_principals d
		LEFT JOIN sys.server_principals s
		ON s.sid = d.sid
		WHERE d.type_description = 'SQL_USER';
		
-- Узнать какие права у пользователя

	-- ***** 1 *****

	Select * from sys.server_permissions
	where grantor_principal_id =
	(Select principal_id from sys.server_principals where name = N'MSK-RIAN\dzaytsev')

	
	-- Передаём сюда из предыдущего запроса ID
	Select * from sys.server_principals where principal_id IN (269,259)

	-- ***** 2 ******
	-- проверить и поменять владельца endpoint

	USE master;
	SELECT 
	 SUSER_NAME(principal_id) AS endpoint_owner
	,name AS endpoint_name
	FROM sys.database_mirroring_endpoints;

	USE master;
	ALTER AUTHORIZATION ON ENDPOINT::Hadr_endpoint TO sa;

	-- ***** 3 ******
	-- Проверить во владельцах БД
	sp_helpdb
	

-- Узнать всех кто входит в серверную группу
	sp_helpsrvrolemember @srvrolename =  'sysadmin'
	
-- Узнать всех кто входит в роль БД
	sp_helprolemember @rolename = 'db_owner'
	
-- Отображает разрешения предопределенной роли базы данных. Процедура sp_dbfixedrolepermission возвращает правильные сведения в SQL Server 2000. Изменения в иерархии разрешений, реализованные в SQL Server 2005, не отражаются.
	sp_dbfixedrolepermission 'db_owner'
	
-- sp_srvrolepermission
	Отображает разрешения предопределенной роли сервера
	
-- Предоставить доступ
	GRANT EXECUTE TO vbr1c
	GRANT EXECUTE ON SCHEMA ::[vbr1c] TO user_test -- https://msdn.microsoft.com/ru-ru/library/ms187940(v=sql.120).aspx

-- NT Service\SQLWriter
	С помощью имени входа NT Service\SQLWriter процесс записи SQL может запускаться на более низком уровне прав доступа в учетной записи, помеченной как без имени входа, что снижает потенциальную уязвимость.Если модуль записи SQL отключен, то каждая служебная программа, которая полагается на моментальные снимки VSS, например System Center Data Protection Manager, а также некоторые другие продукты сторонних поставщиков, перестанет работать и будет сбоить с риском принятия нецелостных резервных копий баз данных
	
-- NT SERVICE\winmgmt
	Windows Management Instrumentation (WMI) must be able to connect to the Database Engine. To support this, the per-service SID of the Windows WMI provider (NT SERVICE\winmgmt) is provisioned in the Database Engine.
	The SQL WMI provider requires the following permissions:
	Membership in the db_ddladmin or db_owner fixed database roles in the msdb database.
	CREATE DDL EVENT NOTIFICATION permission in the server.
	CREATE TRACE EVENT NOTIFICATION permission in the Database Engine.
	VIEW ANY DATABASE server-level permission.
	SQL Server setup creates a SQL WMI namespace and grants read permission to the SQL Server Agent service-SID.
	
	
-- Обзор вариантов
	- SQL Server Encryption: Always Encrypted
		https://www.red-gate.com/simple-talk/sql/database-administration/sql-server-encryption-always-encrypted/
	- Encrypting SQL Server: Using an Encryption Hierarchy to Protect Column Data
		https://www.red-gate.com/simple-talk/sql/sql-development/encrypting-sql-server-using-encryption-hierarchy-protect-column-data/
	- Encrypting SQL Server: Transparent Data Encryption (TDE)
		https://www.red-gate.com/simple-talk/sql/sql-development/encrypting-sql-server-transparent-data-encryption-tde/