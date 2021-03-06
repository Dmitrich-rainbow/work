
-- Ошибки	
	1. The process could not bulk copy into table 
		- Are the database collations the same on both sides?
		- Youll need to select the option to "DROP the existing table and recreate it" on the snapshot tab.
		- You will need to delete the data on the subscriber before the snapshot runs or you will need to use filters to remove the duplicate information.
	2. Если нужно добавить столбец без переинициализации репликации (SQL Server 2000, начиная с SQL server 2005 все DDL операции реплицируются без проблем, но это можно отключить, используя опцию Replicate schema changes)
		sp_repladdcolumn @source_object = N'Customers', @column = N'Cat1', @typetext =
		,N’varchar(25)’, @publication_to_add = N'data',@from_agent = 0,
		@schema_change_script = NULL, @force_invalidate_snapshot = 1 ,
		@force_reinit_subscription = 1		
		
		-- Для удаления 		
		sp_repldropcolumn @source_object = 'Customers' , @column = 'Cat1' ,
		@schema_change_script = NULL , @force_invalidate_snapshot = 1 ,
		@force_reinit_subscription = 1
		
		-- Для обновления нет хранимой процедуры, но можно сделать так. Однако столбец станет последним в таблице
			CREATE TABLE #TEMP (ID VARCHAR(15), DES VARCHAR(100))
			go
			INSERT INTO #TEMP Select CustomerID,Fax from Customers – Data will be stored in a
			temp table
			go
			sp_repldropcolumn @source_object = 'Customers'
			, @column = 'Fax'
			, @schema_change_script = NULL
			, @force_invalidate_snapshot = 1
			, @force_reinit_subscription = 1
			Go
			sp_repladdcolumn @source_object = N'Customers', @column = N'Fax', @typetext =
			,N'varchar(25)', @publication_to_add = N'data',@from_agent = 0,
			@schema_change_script = NULL, @force_invalidate_snapshot = 1 ,
			@force_reinit_subscription = 1
			go
			Update Customers Set Fax = (select DES from #TEMP where Id = Customers.CustomerID)
			— Data will be restored from the temp table
			drop TABLE #TEMP
	3. Репликация объектов 
		- Публикация может быть создана, даже если на подписчике нет объектов
	
		Представление Таблицы, на которых базируется представление, должны существовать на подписчике. Однако эти таблицы могут не участвовать в репликации.
		
		Индексированное Таблицы, на которых базируется представление, должпредставление ны существовать на подписчике. Однако эти таблицы не участвуют в репликации. На серверах – подписчиках должна быть установлена
		версия SQL Server 2000 и выше. Все подписчики должны использовать SQL Server в редакции Enterprise Edition.

		Хранимые процедуры, Все объекты, упомянутые в хранимой процедуре или определяемые пользовательской функции должны существовать на пользователем функции подписчике. Однако, эти объекты могут не участвовать
		в репликации.
	4. The initial snapshot for publication is not yet available
		- Your error is telling you that it cannot apply transactions that are marked for replication to the subscriber because the initial snapshot (and/or any of the subsequent snapshots) have not yet been applied. You need to troubleshoot why this snapshot is not being applied. There are many reasons why it could be happening.
		- Можно просто запустить переинициализацию
		- For merge replication: You will see this error when you have created or reinitialized a merge subscription and you started the Merge Agent before you started the Snapshot Agent or before the Snapshot Agent had completed.
		- For transactional replication:You have created or reinitialized a transactional subscription which was created with the Yes, initialize the schema and data option and you started the Distribution Agent before you started the Snapshot Agent or before the Snapshot Agent had completed. You will only get this error if the subscription is the only subscription associated with the Distribution Agent or if all subscriptions associated with the Distribution Agent are in the above state. As soon as any one of the subscriptions associated with the Distribution Agent has an available snapshot, the agent history message will instead say either, "No replicated transactions are available," or it will report the number of transactions and commands delivered for other subscriptions associated with this agent. If there is only one article in a transactional publication and that article meets the criteria described above, the error will instead be 21076, "The initial snapshot for article is not yet available."
	5. The process could not bulk copy into table 
		- Are the database collations the same on both sides?
		- Youll need to select the option to "DROP the existing table and recreate it" on the snapshot tab.
		- You will need to delete the data on the subscriber before the snapshot runs or you will need to use filters to remove the duplicate information.
	6. Named Pipes Provider: Could not open a connection to SQL Server []
		- Включить Named Pipes на обоих серверах
		- Пересоздать подписку
		- http://blog.sqlauthority.com/2009/05/21/sql-server-fix-error-provider-named-pipes-provider-error-40-could-not-open-a-connection-to-sql-server-microsoft-sql-server-error/