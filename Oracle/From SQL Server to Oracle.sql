-- Установка
	- http://blogs.msdn.com/b/dbrowne/archive/2013/10/02/creating-a-linked-server-for-oracle-in-64bit-sql-server.aspx
	1. Открыть порты
	2. Создать пользователя
		-- Узнать SERVICE_NAME (командная строка)
			lsnrctl status -- смотреть Instance
		
		-- Подключение
			sqlplus user_name/password@SERVICE_NAME -- SERVICE_NAME или имя БД Oracle
		
		-- Создание пользователя
			CREATE USER test IDENTIFIED BY myPassword
			GRANT CREATE SESSION TO test
			GRANT SELECT ANY TABLE TO test
			для доступа на VIEW нужна дополнительная команда
	
	3. Установить Oracle OleDB.dll
	
	4. exec master.dbo.sp_MSset_oledb_prop 'ORAOLEDB.Oracle', N'AllowInProcess', 1
	exec master.dbo.sp_MSset_oledb_prop 'ORAOLEDB.Oracle', N'DynamicParameters', 1
	
	5. Создать Linked Server
		exec sp_addlinkedserver N'MyOracle', 'Oracle', 'ORAOLEDB.Oracle', N'//193.124.4.233/arsys', N'FetchSize=2000', '' -- arsys это SERVICE_NAME в Oracle
		exec master.dbo.sp_serveroption @server=N'MyOracle', @optname=N'rpc out', @optvalue=N'true'
		exec sp_addlinkedsrvlogin @rmtsrvname='MyOracle', @useself=N'FALSE', @rmtuser=N'system', @rmtpassword='q1'    

	6. Проверить подключение
		exec ('select 1 a from dual') at MyOracle -- MyOracle - созданный нами Linked Server
		
		select * from openrowset('MyOracle', 'select * from T1') -- В прошлом варианте возможны проблемы при множественном возврате строк
		