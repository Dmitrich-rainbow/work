1. Открываем порты (3306)
2. Создаём пользователя в My SQL
3. Качаем и настраиваем ODBC 
	-- Не забыть создать в системном DNS, а не в пользовательском
	https://dbperf.wordpress.com/2010/07/22/link-mysql-to-ms-sql-server2008/
4. Добавляем Linked Server по данному ODBC
	Provider: Microsoft OLE DB Provider for ODBC Drivers
	Product name:  MySQL
	Data Source: MySQL (This the system dsn created earlier)
	Provider String:  DRIVER={MySQL ODBC 5.1 Driver};SERVER=localhost;PORT=3306;DATABASE=repltest; USER=user;PASSWORD=password;OPTION=3;
	(This string is providing all the information to connect to MySQL using the ODBC)
	Location: Null
	Catalog: repltest (Database name to access and query)
	
	Security - указываем логин и пароль
	
	Option: RCP out = True