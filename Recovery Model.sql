-- Переключение recovery model
	1. Для подтверждения изменений нужно сделать backup

-- BULK-LOGGED
	-- Особенности
		- Перед тем, как начать оперативное восстановление, рекомендуется переключиться к модели полного восстановления
		- Перед backup лога в данном режиме лучше перейти в FULL, но это поможет только со 2 backup
		-- Плюсы
			- Можно переходить в данный режим для предотвращения роста лога в момент REBUILD INDEX/UPDATE STATISTICS
			- Использовать для массовых операций вставки BCP...
				- Когда включена репликация транзакций, операции BULK INSERT полностью протоколируются даже в модели восстановления с неполным протоколированием.
			- Операции SELECT INTO
				- Когда включена репликация транзакций, операции SELECT INTO полностью протоколируются даже в модели восстановления с неполным протоколированием.
			- Работает с Log Shipping
		-- Минусы
			- Восстановление будет дольше
			- Размер backup может быть значительно больше, так как он просматривает страницы ML (min log) и забирает указанные там данные. За счёт этого и может существовать данный режим
			- Backup лога может весить больше, так как при REBUILD INDEX/UPDATE/ALTER TABLE так как будет содержать начальные и изменённые данные столбцов. Если после этого переключить в FULL и сделать backup, то это спасёт ситуацию, но только со второго backup. Первый будет весить как будто вы остались в bulk-logged
			- Минимально протоколируются ALTER INDEX/CREATE INDEX/DROP INDEX
			- Рекомендуется как можно меньше использовать модель восстановления с неполным протоколированием
			- Однако модель восстановления с неполным протоколированием повышает риск потери данных при операциях массового копирования, потому что массовые операции с неполной регистрацией исключают повторную запись изменений в зависимости от транзакций. Если в резервное копирование журнала входят операции с неполным протоколированием, то нельзя восстановить данную резервную копию журнала до момента времени, можно восстановить только резервную копию журнала целиком.
			- Нет возможности снять tail-of-the-log, такой backup будет повреждён
			- Если в модели восстановления с неполным протоколированием в резервной копии журнала содержатся изменения с неполным протоколированием, восстановление до момента времени невозможно. Попытка восстановления до момента времени из резервной копии журнала, содержащей массовые изменения, приводит к сбою операции восстановления.
			- Если файловая группа, содержащая зарегистрированные массовые изменения, переводится в состояние только для чтения до резервного копирования журнала, все последующие резервные копии журнала содержат экстенты, измененные зарегистрированными массовыми операциями, пока она остается доступной только для чтения. Тем не менее, такие резервные копии журнала занимают больше места и дольше записываются, чем при модели полного восстановления. Чтобы избежать этой ситуации, переключитесь на модель полного восстановления, прежде чем сделать файловую группу доступной только для чтения и создать резервную копию журнала. Только после этого сделайте файловую группу доступной только для чтения.
			- Перед тем как перевести базу данных в режим только для чтения, перейдите в режим модели полного восстановления и сделайте резервную копию журналов. Затем сделайте базу данных доступной только для чтения. На практике не имеет смысла выполнять резервное копирование журналов базы данных только для чтения. Вместо этого создайте полную резервную копию базы данных или полный набор резервных копий файлов после перевода базы данных в режим только для чтения
			- Инструкции WRITETEXT и UPDATETEXT для вставки или добавления новых данных в столбцы с типом данных text, ntext или image. Обратите внимание, что минимальное протоколирование не используется при обновлении существующих значений.
	-- Переключение между BULK-LOGGED и Full
		- Базу данных можно в любой момент переключить в другую модель восстановления. Если переключение происходит во время массовой операции, соответствующим образом изменяется процесс ее регистрации.
	-- Ограничения
		- Для работы некоторых функций (например зеркального отображения) в базе данных должна применяться модель полного восстановления.
		- Когда включена репликация транзакций, операции SELECT INTO и BULK INSERT полностью протоколируются даже в модели восстановления с неполным протоколированием.
		- Минимальное протоколирование не поддерживается для оптимизированных для памяти таблиц.
	-- Рекомендации
		- Перед переходом на модель восстановления с неполным протоколированием создайте резервную копию журнала.
		- После выполнения массовых операций немедленно переключитесь обратно на модель полного восстановления.
		- После переключения с модели восстановления с неполным протоколированием на модель полного восстановления снова создается резервная копия журнала.
		
-- FULL
	If you are building or rebuilding an index in ONLINE mode, SQL Server writes every new index row to the log. (Chapter 7, “Indexes: internals and management,” covers ONLINE index operations.)
	If you are performing a SELECT INTO operation that creates a new table with an IDENTITY
	
-- SIMPLE
	- truncate log происходит когда выполняется checkpoint
		
-- Minimally logged operations
	- SELECT INTO This command always creates a new table in the default filegroup.
	- Bulk import operations These include the BULK INSERT command and the bcp executable.
	- INSERT INTO . . . SELECT This command is used in the following situations.
	- Partial updates Columns having a large value data type receive partial updates (as discussed in Chapter 8, “Special storage”).
	- .WRITE This clause is used in the UPDATE statement when inserting or appending new data.
	- WRITETEXT and UPDATETEXT These statements are used when inserting or appending new data into LOB data columns (text, ntext, or image). Minimal logging isn’t used in these cases when existing data is updated.
	- Index operations These include the following.

-- files and filegroups
	- Individual files and filegroups with the read-write property can be backed up only when your database is in FULL or BULK_LOGGED recovery model because you must apply log backups after you restore a file or filegroup, and you can’t make log backups in SIMPLE recovery. Read-only filegroups and the files in them can be backed up in SIMPLE recovery.
	- You can restore individual file or filegroup backups from a full database backup.
	- Immediately before restoring an individual file or filegroup, you must back up the transaction log. You must have an unbroken chain of log backups from the time the file or filegroup backup was made.
	- After restoring a file or filegroup backup, you must restore all transaction log backups made between the time you backed up the file or filegroup and the time you restored
	
-- WITH STANDBY
	- Вы можете воспользоваться этим методом, чтобы посмотреть состояние данных по середине backup, после чего продолжить его