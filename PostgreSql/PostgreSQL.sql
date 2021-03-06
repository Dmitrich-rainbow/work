-- Документация
	77 страница
	https://www.postgresql.org/docs/current/static/index.html
	http://postgresql.ru.net/
	https://www.youtube.com/watch?v=uha_uTmXslY&list=PLaFqU3KCWw6KzGwUubZm-9-vKsi6vh5qC
	https://www.youtube.com/watch?v=iODeKnTD1kA&list=PLaFqU3KCWw6JgufXBiW4dEB2-tDpmOXPH
	
-- Установка
	- https://www.postgresql.org/download/
	-- Для Red Hat 7
		Install the repository RPM:
		
			yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-redhat96-9.6-3.noarch.rpm
			
		Install the client packages:
		
			yum install postgresql96
		Optionally install the server packages:
		
			yum install postgresql96-server
		Optionally initialize the database and enable automatic start:
		
			/usr/pgsql-9.6/bin/postgresql96-setup initdb
			systemctl enable postgresql-9.6
			systemctl start postgresql-9.6
			
		Included in distribution
		These distributions all include PostgreSQL by default. To install PostgreSQL from these repositories, use the yum command on RHEL 5,6 and 7, or dnf command on Fedora 24+:

			yum install postgresql-server
			dnf install postgresql-server
			
		Post-installation
			Due to policies for Red Hat family distributions, the PostgreSQL installation will not be enabled for automatic start or have the database initialized automatically. To make your database installation complete, you need to perform these two steps:
			
			service postgresql initdb
			chkconfig postgresql on
			
-- Настройка подключений
	Зайти за учётку postgres и открыть pg_hba.conf (/etc/postgresql/9.6/main/pg_hba.conf или /var/lib/pgsql/9.6/data/pg_hba.conf)
	
-- PSQL
	-- Подключение
	psql mydb
	
	-- Список баз данных:
		select * from pg_database;
	
	-- Транзакция
		BEGIN...COMMIT
		
		BEGIN;
		UPDATE accounts SET balance = balance - 100.00
		WHERE name = 'Alice';
		SAVEPOINT my_savepoint;
		UPDATE accounts SET balance = balance + 100.00
		WHERE name = 'Bob';
		-- ошибочное действие... забыть его и использовать счёт Уолли
		ROLLBACK TO my_savepoint;
		UPDATE accounts SET balance = balance + 100.00
		WHERE name = 'Wally';
		COMMIT;
		
	-- Наследование
		CREATE TABLE capitals (
		state char(2)
		) INHERITS (cities);
		
		В данном случае строка таблицы capitals наследует все столбцы (name, population и altitude) от родительской таблицы cities.
		Здесь слово ONLY перед названием таблицы cities указывает, что запрос следует выполнять только для строк таблицы cities, не включая таблицы, унаследованные от cities.
		
	-- Таблица 
		- В каждой таблице есть несколько системных столбцов, неявно определённых системой.
		
			oid
			Идентификатор объекта (object ID) для строки. Этот столбец присутствует, только если таблица
			была создана с указанием WITH OIDS, или если в момент её создания была установлена пере-
			менная конфигурации default_with_oids. Этот столбец имеет тип oid (с тем же именем, что и
			сам столбец); подробнее об этом типе см. Раздел 8.18.
			tableoid
			Идентификатор объекта для таблицы, содержащей строку. Этот столбец особенно полезен для
			запросов, имеющих дело с иерархией наследования (см. Раздел 5.9), так как без него слож-
			но определить, из какой таблицы выбрана строка. Связав tableoid со столбцом oid в таблице
			pg_class, можно будет получить имя таблицы.
			xmin
			Идентификатор (код) транзакции, добавившей строку этой версии. (Версия строки — это её
			индивидуальное состояние; при каждом изменении создаётся новая версия одной и той же
			логической строки.)
			cmin
			Номер команды (начиная с нуля) внутри транзакции, добавившей строку.
			xmax
			Идентификатор транзакции, удалившей строку, или 0 для неудалённой версии строки. Значе-
			ние этого столбца может быть ненулевым и для видимой версии строки. Это обычно означает,
			что удаляющая транзакция ещё не была зафиксирована, или удаление было отменено.
			cmax
			Номер команды в удаляющей транзакции или ноль.
			ctid
			Физическое расположение данной версии строки в таблице. Заметьте, что хотя по ctid можно
			очень быстро найти версию строки, значение ctid изменится при выполнении VACUUM FULL.
			Таким образом, ctid нельзя применять в качестве долгосрочного идентификатора строки. Для
			идентификации логических строк лучше использовать OID или даже дополнительный последо-
			вательный номер.

	-- Схема
		- Схема по-умолчанию public
		- В дополнение к схеме public и схемам, создаваемым пользователями, любая база данных содержит схему pg_catalog, в которой находятся системные таблицы и все встроенные типы данных, функции и операторы.
		- Схема pg_temp -- хранение временные объекты
		- Чтобы узнать текущий тип поиска, выполните следующую команду:
			SHOW search_path;
			-- Изменить порядок	
				SET search_path TO myschema,public;	
		-- Список схем
			SELECT * FROM pg_namespace
		-- Список объектов в схеме
			\в schema.*
			
		-- Путь поиска схем	
			current_schema(true)
			
	-- Пользователи	
		-- Создать роль
			- Ролью является и пользователь и группа
			- Роли могут входить друг в друга
			createuser --interactive joe
			
			-- Создать роль, без логина
				createuser --no-login role
				
			-- Создать с доп. правами
				CREATE ROLE name_role [WITH] option :
					superuser
					createdb
					...
			
			-- Дать с правом 
				WITH ADMIN OPTION
		
		-- Список пользователей:
			select * from pg_shadow;		
			

	-- Загрузка в таблицу
		COPY weather FROM '/home/user/weather.txt';
		
-- Привилегии
	WITH GRANT OPTION -- с возможностью назначать права на объект
	
	-- Роль public
		- Если мы отобрали права на функции, после создания новой функции, public на неё получит доступ и надо его отнимать дополнительно -- Это можно решить с помощью правил, которые будут после создания объекта отнимать у public права на них
		-- БД
			CONNECT
			TEMPORARY
		-- Схема
			CREATE 
			USAGE
		-- pg_catalog
			USAGE (доступ к объектам)
		-- функции
			EXECUTE
	-- Дополнительные привилегии по-умолчанию
		ALTER DEFAULT PRIVILAGES
		\ddp		

-- Архитектура
	- Размер страниц по-умолчанию 8 Кб
		
	-- Хранение
		-- Табличное пространство
			- Есть особые, которые могут хранить объекты разных БД
			- Системная информация хранится в особом табличном пространстве, которое не принадлежит ниодной БД
			
		-- background writer
			- Сбрасывает "грязные" буфферы на диск
		
		-- Файлы
			- Максимальный размер файла данных 1 Гб
			- Файл лога по-умолчанию имеет размер 16 Мб
			
		-- Журнал (write-ahead-log)
		- процесс wal writer
	
	-- MVCC
		- Каждая строка имеет начальную транзакцию и конечную
		- Обновление это удаление и добавление
		
		-- autovacum
			- Очищает старые версии строк
			
-- Конфигурирование сервера
	-- Основной Файл конфигурации postgresql.conf
		- По-умолчанию в дирректории с данными $PGDATA
		- Посмотреть SHOW config_file
		- Чтобы внести правки:
			- Изменить в самом файле
			- Попросить сервер перечитать файл
				- pg_ctl reload
				- $kill -HUP
				- SELECT pg_reload_conf()
		- Некоторые настройки требуют перезагрузку
		- Добавить другие конфигурационный файлы -- Читается сверху-вниз, последний прочтённый заменит те параметры, что было у него внутри
			include filename
			include_if_exists filename
			include_dir -- все файлы .conf
		
	-- postgresql.auto.conf (ALTER SYSTEM)
		- По-умолчанию в дирректории с данными $PGDATA
		- Считывается после postgresql.conf и будет иметь предпочтение
		- Постгрес будет страться проверять корректность значений
		- Не рекомендуется редактировать вручную
			ALTER SYSTEM SET ...
			ALTER SYSTEM RESET
		- Применить SELECT pg_reload_conf()
		
	-- Узнать с какими параметрами запущен сервер
		pg_ctl status
		Посмотреть в файл postmaster.opts
		
	-- Текущие параметры сервера
		SELECT * FROM pg_settings
		SHOW;
		current_setting('conf_parameter')
		
	-- установить параметры
		SET [LOCAL] conf_parameter to 'value' -- LOCAL (только в рамках текущей транзакции)
		set_config('conf_parameter','value',true/false)
		
		UPDATE pg_settings...
		
		RESET conf_parameter | ALL;
		
		-- Для БД или роли
			ALTER DATABASE [dbname] SET conf_parameter to 'value'
			ALTER ROLE [rolename] [IN DATABASE dbname] SET conf_parameter to 'value'
			ALTER FUNCTION funcname SET conf_parameter to value
			
			Информация сохраняется в таблице pg_db_role_setting и pg_proc.proconfig
		
			-- Удалить
				ALTER DATABASE [dbname] RESET conf_parameter | ALL
				ALTER ROLE [rolename] [IN DATABASE dbname] RESET conf_parameter | ALL
				ALTER FUNCTION funcname RESET conf_parameter | ALL
				
		-- Для функции
		
-- Аутентификация/Доступ к Postrges
	$PGDATA/*.conf      */ pg_hba.conf
	
	SELECT name, setting FROM pg_settings WHERE category = ''
	
	-- Тип подключения
		- local
		- host
			- hostssl
			- hostnossl
		

-- Вывод ошибки
	RAISE NOTICE 'work_mem %', current_setting('work_mem');
		
-- Материализованные представления
	- Просто хранит результат запроса в таблице
	- Не обновляется
	- Обновить материализованное представление
		refresh
		
-- План запроса
	- Изначально не кэшируется
	- Чтобы кэшировался нужно создать prepared statement
	
-- Оптимизация
	- https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server
	- listern_adresses -- слушает только локальные подключения, изначально только localhost
	- work_mem -- сортировки и тд в пользовательской сессии, 4 Мб по-умолчанию (это мало)
	- max_connections -- по-умолчанию 100
	- maintenance_work_mem -- для фоновых процессов (вакум)
	- shared_buffers -- изначально установлено мало. Примерно 25% о тпамяти
	- effective_cache_size -- сколько оперативная память может выделить под кэш операционной системы (нужно ли использовать индекса, чем больше, тем больше вероятность что индекс будет использоваться). Рекомендации начинать от 50% памяти
	
	
-- autovacuum
	- Чем интенсивнее используется таблица, тем чаще приходит autovacuum
	- Он не блокирует таблицу, обрататывает по страницам
	- Автовакум практически никгогда не сжимает файл на диске, только очищает место внутри
	
	-- Ручной запуск
		vacuum 
		vacuumdb
		vacumm full 
			-- сжимает страницы, которые очистил. Полностью перестраивает таблицу  и индексы
			-- Требует эксклюзивной блокировки
			-- После TRUCANTE вакус не нужен
			
	-- Расширение
		- pg_repack -- Создаёт рядом таблицу, перегоняет данные и заменяет указатели. Всё это онлайн
		
	-- Статистика
		- При вакуме обновляется статистика
		- ANALYZE или vacuumdb --analyze-only

	-- Карта видимости (vm)
		- Так же выполняется при вакуме
		
	-- Карта свободного пространства
		- Так же выполняется при вакуме
		
	-- Номер транзакции
		- Так же выполняется при вакуме. Помечает транзакции как завершённые (замороженные)
		- Максимум 32 бита (9.4)
		
-- Мониторинг индексов
	- Не используемые
		pg_stat_all_indexes.idx_scan
	- Дублирующиеся/пересекающиеся
		pg_index
		
	pg_relation_size()
	
	-- REINDEX
		- Перестроить индекс с нуля
		- Устанавливает эксклюзивную блокировку
		- vacuum full так же перестраивает все индексы 
		
	-- Постройка индекса без эксклюзивной блокировки
		CREATE INDEX name on ... concurrently
		- Если индекс не смог построиться и была ошибка, то индекс останется и нужно не забыть его удалить (drop index)
		- Не все индексы поддерживаются в построении онлайн
		- Инедксы с ограничением
			ALTER TABLE drop constraint old,add constraint new using index new
			
-- Backup	
	
	- Логический
		- Восстановление через SQL-команды
		-- Плюсы
			- Частичная резервная копия
			- Можно восстановить на другой версии или архитектуре
		-- Минусы
			- Медленно
			
			-- Работа с данными
				
		-- Копирование
			- Загружает в существующую таблицу
			copy table to file -- серверная
			\copy table to file -- pg sql
			
		-- Восстановление
			copy table from file -- серверная
			\copy table from file -- pg sql
			
		-- pg_dump
			- Работает только с 1 БД
		
			-- Резервирование
				pg_dump --table=tbl -d db -- таблицы по шаблону
				pg_dump --schema=scm -d db -- схема + объекты
					--data-only
					--schema-only
					--create -- включить команду создания БД
				
				-- Частичное резервирование
					pg_dump --format=custom -f dump -d db
					pg_dump --format=directory --jobs=N -f dump -d db -- позволяет выгружать в несколько потоков
					
			-- Восстановление
				- После восстановления есть смысл выполнить ANALYSE (она не сохраняется при дампе)
				- Заранее должны быть созданы роли и табличные пространства
				- Новая Бд должна быть создана из template0 (можно не заботиться если дам был сделан с --create )
					
				psql -f dump
					
				-- Частичное восстановление
					pg_restore -d db dump
						--clean -- включает удаление объектов из БД
						--create предварительное создание БД
						--list dump > db.list -- оглавление
						--use-list=db.list -d db dump
						
					pg_restore -d db --jobs=N dump	
			
		-- pg_dumpall	
			- Работает со всем кластером
				--globals-only --Позволит перенести роли и табличные пространства
			
			
	- Физический
		- Копирование файлов на файловой системе
			%p полный путь к сегменту WAL
			%f имя файла для сегмента WAL
			%% -- символ %
			
			-- Пример
				test ! -f /архив/%f && cp %p /архив/%f
				gzip < %p > /архив/%f
				my_backup_script.sh "%p" "%f"
			
		- Если делаем резервирование журналов отдельно, то при backup параметр --xlog-mothod не указываем
		
		- Так как линукс кэширует даже файлы данных по сети, может случится так, что PG получит успешное завершение копирования, произойдёт сбой, а Linux не успеет сбросить на диск. Чтобы это предотвратить нужно выполнять sync того что на PG и на шаре (сброс буферов на диск)
		
		
		-- Плюсы
			- Быстро
			- На момент времени
		-- Медленно
			- Только весь кластер
			- Много места

		-- Восстановление
			- После каждого восстановления создаётся новая ветка WAL и номер этой ветки попадает в название WAL (pg_xlog/N.history). Далее кожно восстановиться на любую из этих веток
				- recovery_target_timeline = 'latest'/'номер'
		
			1. Останавливаем сервер
			2. Удаляем из $PGDATA все кроме pg_xlog (могли остаться необработанные сегменты)
			3. Восстанавливаем файлы из базовой резервной копии, кроме pg_xlog/
			4. Создаём управляющий файл $PGDATA/recovery.conf
			5. Запускаем сервер, видит recovery.conf > начинает восстановление > если успешно переименовывает recovery.conf в recovery.done (если этого не произошло, ищем причину)
			
			-- backup_label
				- Создаётся при резервной копии
				- Содержит название, время создания копии и начальный сегмент WAL
				
			-- recovery.conf
				- Пишется самостоятельно
				- restore_command (обратная команде копирования). Является обязательной командой
				- По-умолчанию накатываются все сегменты WAL, которые есть в архиве
				
				
				-- Пример
					cp /архив/%f %p
					gunzip < /архив/%f > %p
					
			-- Восстановление на точку
				- Добавляем в recovery.conf
					recovery_target = 'immediate'
					recovery_target_name = 'время'
			
				
		
