
-- Основное
	- Посмотреть информацию о серфтикатах в текущей БД
		SELECT * FROM sys.certificates
		
	- Посмотреть сертификаты уровня сервера
		mmc >> snap in >> certificates
		
	- Место расположения сертификатов	
		master >> security >> certificates
		
	- Сертификаты для сети		
		SSCM >> Protocol for MSSQLServer >> Properties