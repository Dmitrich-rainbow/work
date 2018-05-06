- Какие есть планые, готовые варианты
-- План
	-- Вступление 
		Меня зовут Зайцев Дмитрий, работаю с SQL Server с 2010 года, последние 4 года обслуживаю крупные организации. На данный момент тружусь в России Сегодня. Являюсь создателем проекта SQLCom.ru
		
		Полагаю что никто не сомневается в том, что мониторинг продуктивной системы нужен всегда и что от его качества зависит скорость реакции на проблему. Если всё же кто-то сомневается, то я вас уверяю, что просмотр логов далеко не всегда может сказать о корне проблемы, комплексный мониторинг, не только SQL Server, но и инфраструктуры, возволит вам значительно быстрее обнаружить причину проблемы.
		
		О чём мы не будем сегодня говорить:
			1. Какую систему мониторинга выбрать
			2. 
			
		О чём же тогда мы поговорим:
			1. Что наиболее важно для мониторинга SQL Server
			2. Как можно собирать и анализировать данные 
			3. Способы определения что проблемы уже есть или скоро появятся
			
	-- 1. Что наиболее важно для мониторинга SQL Server
		
		Проблема многих БД, SQL Server не исключение, в том, что очень сложно понять что было 5 минут назад, так как всегда ищется компромисс между производительность и сбором информации о работе системы. Если мы будем собирать все события, что происходят в SQL Server, то это может требовать от системы большое количество ресурсов. По этой причине детальный мониторинг изначально не активен и с ним надо работать. Сейчас этим мы с вами и займёмся.
		
		Первым делом я бы вам рекомендовал настроить аккаунт DatabaseMail. В интернете много инструкций, не буду останавливаться на этом вопросе. Далее необходимо настроить этот аккаунт для SQL Server Agent, чтобы мы могли высылать оповещения на почту при обнаруженных проблемах, инструкции так же можно найти в интернете.
		
		Для подобных событий мы создаём отдельную рассылку на почтовом сервере и подключаем всех заинтересованных пользователей. Прошу вас не пытаться запомнить все приведённые скрипты. Сама презентация и все скрипты уже доступны вот тут...
		
		**************************************************************************************
		
		Предварительную настройку закончили. Первым делом предлагаю настроить оповещение о важных ошибках на SQL Server. Это делается с помощью системы Alert, которая высылает оповещение, если возникло как-то событие на SQL Server. Система Alerts может реагировать не только на события SQL Server, но и на счётчики производительности Windows. По практике нам нужны события важностью выше 19, всего их получается 7 шт, с 19 по 25. Давайте посмотрим на код, который их создаёт (рассмотрим на примере 1 события важность 19): 
		
				USE [msdb]
				GO
				
				-- Проверяем что такого Alert ещё нет
				IF EXISTS (SELECT * FROM dbo.sysalerts WHERE name = 'Severity 19')
				EXEC dbo.sp_delete_alert
				   @name = N'Severity 19' 
				GO
				
				-- Создаём Alert
				EXEC msdb.dbo.sp_add_alert @name=N'Severity 19', 
						@message_id=0, 
						@severity=19, -- Срочность
						@enabled=1, -- Включён ли
						@delay_between_responses=300, -- Как часто высылать оповещение. могут быть ситуации, когда сообщения происходят постоянно, нет смысла высылать сотни сообщений на почту. Определите этот параметр для себя самостоятельно
						@include_event_description_in=1, 
						@job_id=N'00000000-0000-0000-0000-000000000000'
				GO
				
				-- Добавляем к Alert оператора, на которого будет высылаться оповещение
				EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 19', @operator_name=N'mssql-alerts', @notification_method = 1
				GO
		
		По аналогии создаём остальные подобные оповещения.
		
		
		**************************************************************************************
		
		Отдельного внимания заслуживает отслеживание изменение состояния БД:
		
				USE [msdb]
				GO

				IF (SELECT @@VERSION) NOT LIKE '%Express%'
				BEGIN

					-- Создаём задание для оповещения

					IF EXISTS (SELECT * FROM sysjobs WHERE name = 'Alert - alter database')
					exec sp_delete_job @job_name = 'Alert - alter database'

					/****** Object:  Job [Alert - alter database]    Script Date: 27.06.2016 11:17:20 ******/
					BEGIN TRANSACTION
					DECLARE @ReturnCode INT
					SELECT @ReturnCode = 0
					/****** Object:  JobCategory <a href="/wiki/2/Uncategorized_%28Local%29">Uncategorized (Local)</a>    Script Date: 27.06.2016 11:17:20 ******/
					IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
					BEGIN
					EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
					IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
					END

					DECLARE @jobId BINARY(16)
					EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Alert - alter database', 
							@enabled=1, 
							@notify_level_eventlog=0, 
							@notify_level_email=2, 
							@notify_level_netsend=0, 
							@notify_level_page=0, 
							@delete_level=0, 
							@description=N'No description available.', 
							@category_name=N'[Uncategorized (Local)]', 
							@owner_login_name=N'sa', 
							@notify_email_operator_name=N'mssql-alerts', @job_id = @jobId OUTPUT
					IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
					/****** Object:  Step [alter_db]    Script Date: 27.06.2016 11:17:20 ******/
					EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'alter_db', 
							@step_id=1, 
							@cmdexec_success_code=0, 
							@on_success_action=1, 
							@on_success_step_id=0, 
							@on_fail_action=2, 
							@on_fail_step_id=0, 
							@retry_attempts=0, 
							@retry_interval=0, 
							@os_run_priority=0, @subsystem=N'TSQL', 
							@command=N'DECLARE @profiler nvarchar(255), @my_query nvarchar(512)

					SET @profiler = (SELECT MAX(name) FROM msdb.dbo.sysmail_profile)

					IF (SELECT Count(*) FROM sys.databases WHERE state_desc <> ''ONLINE'') < 1
						SET @my_query = ''SET NOCOUNT ON;SELECT''''Bring online''''''
					ELSE
						SET @my_query = ''SET NOCOUNT ON;SELECT name + '''' -'''',state_desc FROM sys.databases db INNER JOIN sys.database_mirroring dbm ON db.database_id = dbm.database_id WHERE dbm.mirroring_state IS NULL AND state_desc <> ''''ONLINE''''''

					EXEC msdb..sp_send_dbmail 
					 @profile_name = @profiler
					,@recipients = ''mssql-alerts@rian.ru''
					,@subject = ''ALTER DATABASE''
					,@query = @my_query
					,@query_result_header = 0
					,@query_result_no_padding = 1', 
							@database_name=N'master', 
							@flags=0
					IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
					EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
					IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
					EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
					IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
					COMMIT TRANSACTION
					GOTO EndSave
					QuitWithRollback:
						IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
					EndSave:

					-- Создаём оповещение
					IF EXISTS (SELECT * FROM dbo.sysalerts WHERE name = 'Alter database')
					EXEC dbo.sp_delete_alert
					   @name = N'Alter database' 

					DECLARE @job_id uniqueidentifier
					DECLARE @service_name nvarchar(512)

					SET @service_name = N'\\.\root\Microsoft\SqlServer\ServerEvents\'+(SELECT @@SERVICENAME)

					SET @job_id = (SELECT job_id FROM msdb..sysjobs WHERE name = 'Alert - alter database')

					EXEC msdb.dbo.sp_add_alert @name=N'Alter database', 
							@message_id=0, 
							@severity=0, 
							@enabled=1, 
							@delay_between_responses=30, 
							@include_event_description_in=0, 
							@category_name=N'[Uncategorized]', 
							@wmi_namespace=@service_name, 
							@wmi_query=N'select * from ALTER_DATABASE', 
							@job_id=@job_id
				END
		'
		
		**************************************************************************************
		Будет здорово, если вы будете отслеживать изменение конфигурации сервера и пользователей. У меня это реализовано следующим образом: на одном из серверов есть система, которая собирает и хранит информацию обо всех экземплярах и каждый день сравнивает с тем что было вчера и что стало сегодня, если появляется расхождение, то система показывает его:
		
		cost threshold for parallelism Было - 5 Стало - 25
		max degree of parallelism Было - 0 Стало - 8
		max server memory (MB) Было - 16000 Стало - 23000
		
		**************************************************************************************
		
		Если вы используете Mirroring или AlwaysOn, то будет полезно понимать когда было переключение
		
		Для Mirroring потребуется использовать WMI
		
		USE [msdb]
		GO

		DECLARE @name_space nvarchar(512)
		SET @name_space = N'\\.\root\Microsoft\SqlServer\ServerEvents\'+(SELECT @@SERVICENAME)

		EXEC msdb.dbo.sp_add_alert @name=N'Database Mirroring Change State', 
				@message_id=0, 
				@severity=0, 
				@enabled=1, 
				@delay_between_responses=60, 
				@include_event_description_in=1, 
				@database_name=N'', 
				@notification_message=N'', 
				@event_description_keyword=N'', 
				@performance_condition=N'', 
				@wmi_namespace=@name_space, 
				@wmi_query=N'SELECT * FROM DATABASE_MIRRORING_STATE_CHANGE', 
				@job_id=N'00000000-0000-0000-0000-000000000000'
		GO

		EXEC msdb.dbo.sp_add_notification 
			@alert_name = N'Database Mirroring Change State', 
			@operator_name = N'mssql-alerts', 
			@notification_method = 1; 
			
		'
		
		Для AlwaysOn необходимо отслеживать несколько событий:
		
		-- 1480 - AG Role Change (failover)
		EXEC msdb.dbo.sp_add_alert
				@name = N'AG Role Change',
				@message_id = 1480,
			@severity = 0,
			@enabled = 1,
			@delay_between_responses = 0,
			@include_event_description_in = 1;
		GO
		EXEC msdb.dbo.sp_add_notification 
				@alert_name = N'AG Role Change', 
				@operator_name = N'mssql-alerts', 
				@notification_method = 1; 
		GO

		-- 35264 - AG Data Movement - Resumed
		EXEC msdb.dbo.sp_add_alert
				@name = N'AG Data Movement - Suspended',
				@message_id = 35264,
			@severity = 0,
			@enabled = 1,
			@delay_between_responses = 0,
			@include_event_description_in = 1;
		GO
		EXEC msdb.dbo.sp_add_notification 
				@alert_name = N'AG Data Movement - Suspended', 
				@operator_name = N'mssql-alerts', 
				@notification_method = 1; 
		GO

		-- 35265 - AG Data Movement - Resumed
		EXEC msdb.dbo.sp_add_alert
				@name = N'AG Data Movement - Resumed',
				@message_id = 35265,
			@severity = 0,
			@enabled = 1,
			@delay_between_responses = 0,
			@include_event_description_in = 1;
		GO
		EXEC msdb.dbo.sp_add_notification 
				@alert_name = N'AG Data Movement - Resumed', 
				@operator_name = N'mssql-alerts', 
				@notification_method = 1; 
		GO
		
-- 2. Как можно собирать и анализировать данные
	
	Ранее мы рассматривали сбор данных, о важных событиях на SQL Server, но для истории и понимания нашей нагрузки, желательно собирать и накапливать данные производительности и состояния экземпляра SQL Server.
	
	Для этого мы можем использовать несколько инструментов:
		1. SQL Server Performance Dashboard (http://sqlcom.ru/dba-tools/sql-server-dashboard-reports/). Видео от Microsoft (http://sqlcom.ru/video/stuff/sql-server-2012-performance-dashboard-reports/)
			Размещение его на SSRS 
			-- Плюсы
				1. Бесплатное решение
				2. Легка в установке
				3. Работает в основном инструменте работы с SQL Server (SSMS)
				4. Нет дополнительной нагрузки на сервер
			-- Минусы
				1. Нет истории 
				2. Нет возможности кастомизации
		2. DataCollection
			-- Плюсы
				1. Легка в установке
				2. Работает в основном инструменте работы с SQL Server (SSMS)
				3. Беслпатное решение
			-- Минусы
				1. Требует место для хранения истории
				2. Сервер, где будет хранится история, будет испытывать нагрузку
				3. Нет возможности кастомизации
		3. Extended Events
			-- Плюсы
				1. Бесплатное решение
				2. Работает в основном инструменте работы с SQL Server (SSMS)
				3. Небольшая дополнительная нагрузка на сервер
				4. Широкий набор возможностей
			-- Минусы
				1. Есть некоторые сложности с использованием и сбором информации
				2. Немного требует места для хранения
		4. Готовое решение
			Idera (ttps://www.idera.com)
			RedGate (http://www.red-gate.com)
			ApexSQL (http://www.apexsql.com)
			solarwinds (http://www.solarwinds.com/)
			и др
			-- Плюсы
				1. Данные решения писали специалисты, что позволит получить много полезной информации о работе вашего SQL Server
			-- Минусы
				1. Стоит денег
		5. Общая система мониторинга
			Zabbix
			Scom
			и тд
			-- Плюсы
				1. Кастомизация мониторинга
			-- Минусы
				1. Сложность установки и настройки
				2. Некоторые решения стоят денег и требуют компетенции
		

-- 3. Способы определения что проблемы уже есть или скоро появятся	
	
	В большинстве случаев мы, для сбора данных, пользуемся Zabbix, но вы легко можете воспользоваться любой другой технологией.
	
	Хотелось бы продемонстировать как у нас всё организовано:
		1. Мы собираем события performance monitor 
		2. В ряде важных случаев SQL Server отсылает на zabbix данные через Zabbix Agent на хосте
		3. Все метрики, триггеры, графики собраны в Шаблоны, которые подключаются к хостам
		4. Оповещения приходят на почту, в смс и на мониторы дежурной смены
		
	Показать как у нас выглядит Zabbix
	
	На каждый хост с SQL Server у нас настроены такие триггеры как:
		1. Использование процессора
		2. Активность служб SQL Server и SQL Server Agent
		3. Если экземпляр установлен в режиме Failover Cluster или AlwaysOn, то отслеживается факт failover
		4. Загрузка процессора
		5. Использование дисков и памяти
		
	В среднем на каждый хост мы используем чуть менее 100 счётчиков и около 30 триггеров. Данные собираются с частотой от 30 секунд до 1 часа.
	
	Обратите внимание, если на одном хосте используется много эксземпляров SQL Server, то рекомендую использовать способ сбора данных "Zabbix agent (active)" вместо обычного "Zabbix agent". Суть заключается в том, что Zabbix не будет дёргать каждый счётчик отдельно, а будет собирать данные на сервере и отравлять на сервер Zabbix. Это позволяет снизить нагрузку на Zabbix-сервер Нужно будет выполнить некоторые дополнительные настройки, но вы легко найдёте инструкцию в интернете. 

-- Заключение
		Хотелось бы в кратце рассмотреть что мы сегодня узнали:
			1. Обязательно настройте сбор информации о важных событиях на почту или в другие места оповещения/хранения
			2. 
		
		
