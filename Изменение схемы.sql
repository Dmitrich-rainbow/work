1. Если у вас редакция Enterprise, то добавление non-NULL колонки со значением по-умолчанию, происходит быстро и заполнеяется по мере обращения к строкам (http://rusanu.com/2011/07/13/online-non-null-with-values-column-add-in-sql-server-11/)
2. Через переключение секций. Даже таблица без секционирование имеет 1 секцию
	- начиная с 2014 версии доступно и в Standard
	BEGIN TRAN
		ALTER TABLE dbo.ProductionTable SWITCH PARTITION 1 TO dbo.ProductionTableOld PARTITION 1
			WITH ( WAIT_AT_LOW_PRIORITY ( MAX_DURATION = 1 MINUTES, ABORT_AFTER_WAIT = BLOCKERS ));  
		--Anyone who tries to query the table after the switch has happened and before
		--the transaction commits will be blocked: we've got a schema mod lock on the table
		ALTER TABLE dbo.StagingTable SWITCH PARTITION 1 TO dbo.ProductionTable PARTITION 1;
	COMMIT
3. Изменение PK с int на bigint
	- Просто изменить и ждать (осторожней с размером лога)
	- Сбросить нумерацию (rename)
	- Через другую таблицу (переливка)
	-   1. Set up a way to track changes to the table – either triggers that duplicate off modifications or Change Data Capture (Enterprise Edition)
		2. Create the new table with the new data type, set identity_insert on if needed
		3. Insert data into the new table. This is typically done in small batches, so that you don’t overwhelm the log or impact performance too much. You may use a snapshot from the point at which you started tracking changes.
		4. Start applying changed data to the new table
		5. Make sure you’re cleaning up from the changed data you’re catching and not running out of space
		6. Write scripts to compare data between the old and new tables to make sure you’re really in sync (possibly use a snapshot or a restored backup to compare a still point in time)
		7. Cut over in a quick downtime at some point using renames, schema transfer, etc. If it’s an identity column, don’t forget to fix that up properly.
	- Add a new column to the end of the table, populate it in batches, then remove the old column.
