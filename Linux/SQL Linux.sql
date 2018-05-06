-- Основное
	https://www.mssqltips.com/sql-server-tip-category/226/sql-server-on-linux/ -- общая информаци

-- Install on Linux
	https://docs.microsoft.com/en-us/sql/linux/
-- Install on Ubuntu
	https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup-ubuntu
-- Install on Red Hat
	https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup-red-hat
	
	sudo systemctl stop mssql-server
	sudo systemctl start mssql-server
	
	-- Требования
		- Минимум 3250 оперативной памяти, лучше просить 4 Гб
		- 4 Гб места на диске
		
	-- именованный экземпляр
		Рекомендуют использовать контейнер
		
	-- Пакетов
		1. С помощью pscp копируем в любую дирректорию файлы mssql-tools (https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools#ubuntu)
		2. Запускаем "установку"
			sudo yum localinstall mssql-tools.rpm
			sudo yum localinstall msodbcsql.rpm
		3. Далее выполняем 
			https://docs.microsoft.com/en-us/sql/linux/quickstart-install-connect-red-hat
		
-- Install SQL Server Agent
	https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup-sql-agent#RHEL
	
	yum info mssql-server-agent
	sudo yum install mssql-server-agent
	
-- Обновление
	sudo yum update mssql-server
	
-- Отличие от SQL on Windows
	Помимо того, что рут он диском ц обзывает
	
-- Мониторинг SQL Server на Linux
	https://blogs.msdn.microsoft.com/sqlcat/2017/07/03/how-the-sqlcat-customer-lab-is-monitoring-sql-on-linux/
	
	-- PssDiag for Linux
		https://blogs.msdn.microsoft.com/sqlcat/2017/08/11/collecting-performance-data-with-pssdiag-for-sql-server-on-linux/
	
-- Установка 
	-- Путь установки (обычно)
		/var/opt/mssql/data/
	

			
-- Получить информацию о SQL Server
	systemctl status mssql-server -- активность службы
	yum info mssql-server -- версию
	ps -ef | grep -v grep | grep sql -- Посмотреть запущенные процессы sql	
	systemctl | grep sql -- Посмотреть запущенные "службы" sql / статус

-- Конфиг	
	/opt/mssql/bin/mssql-conf list -- Посмотреть все параметры конфига
		-- Возможные опции
			set
			unset
			traceflag
			set-sa-password
			set-collation
			validate
			list
			setup
			start-service
			stop-service
			enable-service
			disable-service		
		
	-- Изменить COLLATION
		1. Перед запуском надо отключить все пользовательские БД, иначе не работает
		sudo /opt/mssql/bin/mssql-conf set-collation
			
-- sqlcmd
	запускать с параметром -W, чтобы было более менее удобно читать вывод
	
-- Uninstall / удаление
	sudo yum remove mssql-server
	
	-- Возможно придётся чистить руками остатки
		sudo rm -rf /var/opt/mssql/
	
-- По-умолчанию БД размещены
	/var/opt/mssql/data
	
-- Мониторинг
	top (https://www.mssqltips.com/sqlservertip/4683/linux-administration-for-sql-server-dbas-checking-cpu-usage/)
	iostat –d 4 (https://www.mssqltips.com/sqlservertip/4867/linux-administration-for-sql-server-dbas-checking-disk-io/)
		-x
	iotop
	netstat –i -- Информация по пакетам сети
	netstat -ltu -- Информация по открытым портам 

-- Top 10 Linux Commands for SQL Server DBAs
	https://www.mssqltips.com/sqlservertip/4816/top-10-linux-commands-for-sql-server-dbas/

-- Screen
	- Чтобы при закрытии сессии не пропадал результат работы
	- установка 
		sudo yum install screen
	-- Работа
		- Запуск 
			screen
		- Вызов справки
			ctrl+a затем ?
		- Потоки	
			Ctrl+a -> c Этой командой мы создали новый скрин и теперь они работают одновременно
			Ctrl+a -> 0 переведет нас на 0 скрин.
			Ctrl+a -> “ выдаст меню для выбора скрина
			Ctrl+a ->n переключит на следующий скрин
			Ctrl+a ->p переключит на предыдущий скрин
			Ctrl+a ->x убить текущий screen
			screen -X -S 30691 kill -- убить поток
		- Свернуть 
			Ctrl+a ->d
		- Вернуться в уже существующий
			screen -r -- если скринов несколько, то нужно указать к какому именно мы хотим подключиться
		- Вернуться к потеренному скрину
			screen -x NumberSession -- если скринов несколько, то нужно указать к какому именно мы хотим подключиться
		- Задать имя скрина
			screen -S MyName
		- Переименовать скрин
			Ctrl+a ->A
		- Регионы
			Ctrl+a ->S -- создать
			Ctrl+a ->Tab -- переключаться
			Если после переключения в новый регион ничего нельзя сделать, значит в этом регионе нет скрина, его можно либо добавить, либо выбрать из существующих (Ctrl+a -> “)
			Ctrl+a ->Q Закрыть все регионы кроме текущего
			Ctrl+a ->X Закрыть текущий регион

	
-- best practice

-- oom-killer
	To make SQL Server less susceptible for termination by oom-killer, we recommend one or both of the following suggestions.
		- Adjust memory.memorylimitmb configuration option carefully to leave enough memory on the system even if SQL Server were to use all of the memory configured through this setting.
		- Ensure that swap file exists and sized properly.