/****** Linked Server *****/
	- Команды выполняются локально
	- https://dba.stackexchange.com/questions/46289/which-one-is-more-efficient-select-from-linked-server-or-insert-into-linked-ser
	
-- Дать права на Linked Server
	- GRANT EXECUTE ON SYS.XP_PROP_OLEDB_PROVIDER TO [public]
	
--  Как настроить Linked Server на MySql базу
	https://dbperf.wordpress.com/2010/07/22/link-mysql-to-ms-sql-server2008/
	
	-- Предварительно нужно скачать  MySQL Connector/ODBC Drivers  для вашей версии MySql
		http://www.mysql.com/downloads/connector/odbc/
		
		
-- Настройка
	- SPN
	- https://technet.microsoft.com/en-us/library/ms189580%28v=sql.105%29.aspx?f=255&MSPPError=-2147217396
	- Могут быть проблемы если разные версии студии и сервера
		

/***** OPENROWSET ******/
		
-- Идентификатор
	INSERT INTO HumanResources.myDepartment
	   with (KEEPIDENTITY)
	   (DepartmentID, Name, GroupName, ModifiedDate)
	   SELECT *
		  FROM  OPENROWSET(BULK 'C:\myDepartment-n.Dat',
		  FORMATFILE='C:\myDepartment-f-n-x.Xml') as t1;
		  
-- NULL
	- По умолчанию инструкция INSERT ... SELECT * FROM OPENROWSET(BULK...) присваивает значение NULL любым столбцам, не участвующим в операции массового импорта. SELECT * FROM OPENROWSET(BULK...). Тем не менее можно указать, что вместо пустых значений необходимо вставить значения по умолчанию соответствующих столбцов (если оно задано).
	- WITH(KEEPDEFAULTS)
	
-- Файл форматирования format_file
	FORMATFILE = 'format_file_path'

	-- Минусы
		- Безопасность
		- динамический SQL
		- Подключение из подключения
		- SQL Server Agent Could Not Execute Jobs Containing OPENROWSET Properly
		- Заставляет удалённый сервер выполнять команды
	

/***** OPENQUERY ******/
	- Команды выполняются удалённо
	
	