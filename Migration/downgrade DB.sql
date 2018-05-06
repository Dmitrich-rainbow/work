/*				RUN IS SQLCMD MODE	(In SSMS Query -> SQLCMD Mode)			*/

:connect target_server
USE [master]
GO
set nocount on
CREATE LOGIN [DOMAIN\SQLServiceAccount] FROM WINDOWS		-- Create service account login to allow bcp to connect to server, when run via xp_cmdshell
ALTER SERVER ROLE sysadmin ADD MEMBER [DOMAIN\SQLServiceAccount]
GO
select getdate(), 'Starting database and object creation'
GO

--			Insert create scripts here. Change db file locations and settings in the script if needed.
--			To generate scripts in object explorer right-click on db -> Tasks -> Generate scripts
--			Select script entire database, click Next, click Advanced, change to true the following:
--			Include system constraint names, script logins, object-level permissions, statistcs (only), Full-Text Indexes, triggers.
--			You may also want to scipt collations. And change version of SQL to desired one.





ALTER DATABASE [db1] SET RECOVERY SIMPLE		-- Switch to simple recovery mode to prevent excessive log growth
GO
/*############################################################################################################################################*/
--				DISABLING ALL NONCLUSTERED INDEXES TO SPEED UP FURTHER INSERTS
--				DISABLING CLUSTERED INDEXES WILL RESULT IN INABILITY TO MAKE INSERTS INTO TABLES

select getdate(), 'Disabling indexes on target'
GO

use [master]
GO
set nocount on 
if object_id('tempdb..databases_migrate') IS NOT NULL
DROP TABLE tempdb..databases_migrate
if object_id('tempdb..disable_idx') IS NOT NULL
DROP TABLE tempdb..disable_idx

CREATE TABLE tempdb..databases_migrate (db nvarchar(256))

insert into tempdb..databases_migrate
VALUES (N'db1'), (N'db2')			--		Enter db names to transfer here

create table tempdb..disable_idx (scr NVARCHAR(MAX))

declare @db nvarchar(256),
		@sql nvarchar(max)

select top 1 @db = db from tempdb..databases_migrate
while @@rowcount > 0
BEGIN
	set @sql = N'use ' + quotename(@db) + N';
	insert into tempdb..disable_idx
	select N''ALTER INDEX '' + quotename(i.name) + N'' on '' + quotename(db_name()) + N''.'' + quotename(schema_name(o.schema_id)) + N''.'' + quotename(object_name(i.object_id)) + N'' DISABLE;''
	from sys.indexes i join sys.objects o
		on (i.object_id = o.object_id)
	where i.type = 2
	and o.is_ms_shipped = 0'

	BEGIN TRY
		exec (@sql)
	END TRY

	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH

	delete from tempdb..databases_migrate where db = @db
	select top 1 @db = db from tempdb..databases_migrate
END
drop table tempdb..databases_migrate

select top 1 @sql = scr from tempdb..disable_idx
while @@rowcount > 0
BEGIN
	BEGIN TRY
		exec (@sql)
	END TRY

	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH

	delete from tempdb..disable_idx where scr = @sql
	select top 1 @sql = scr from tempdb..disable_idx
END
drop table tempdb..disable_idx
GO


/*############################################################################################################################################*/
:connect source_server

--			Export all tables using bcp.

use [db1]		-- The db you want to export. just copy and paste this peace of code, changing the use statement to export other db
GO
set nocount on
select getdate(), 'Starting export'
GO
declare @bcpout nvarchar(2048)

if object_id('tempdb..#bcpout') IS NOT NULL
DROP TABLE #bcpout

-- Make sure, sql server service account does have read/write permissions on \\server\share\
select N'exec master..xp_cmdshell ''bcp "' + db_name() + N'"."' + quotename(schema_name([schema_id])) + N'"' + N'."' + quotename(name) + N'" out "\\server\share\' + db_name() + N'_' + schema_name([schema_id]) + N'_' + name + N'.dat" -T -n'', NO_OUTPUT' as bcpout
into #bcpout
from sys.tables where is_ms_shipped = 0

select top 1 @bcpout = bcpout from #bcpout
while @@rowcount > 0
BEGIN
	BEGIN TRY
		exec (@bcpout)
	END TRY

	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH

	delete from #bcpout where bcpout = @bcpout
	select top 1 @bcpout = bcpout from #bcpout
END

DROP TABLE #bcpout

select getdate(), 'db1 was exported'
GO
/*############################################################################################################################################*/
--			Import all tables using bcp.

USE [db1]	-- The db you want to import. just copy and paste this peace of code, changing the use statement to import other db
select getdate(), 'Starting import'
GO
declare @bcpin nvarchar(2048)

if object_id('tempdb..#bcpin') IS NOT NULL
DROP TABLE #bcpin

-- Make sure, sql server service account does have read/write permissions on \\server\share\ AND CHANGE the server into which you want to import (-S parameter)
select N'exec master..xp_cmdshell ''bcp "' + db_name() + N'"."' + quotename(schema_name([schema_id])) + N'"' + N'."' + quotename(name) + N'" in "\\server\share\' + db_name() + N'_' + schema_name([schema_id]) + N'_' + name + N'.dat" -T -n -E -S targetserver'', NO_OUTPUT' as bcpin
into #bcpin
from sys.tables where is_ms_shipped = 0

select top 1 @bcpin = bcpin from #bcpin
while @@rowcount > 0
BEGIN
	BEGIN TRY
		exec (@bcpin)
	END TRY

	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH

	delete from #bcpin where bcpin = @bcpin
	select top 1 @bcpin = bcpin from #bcpin
END

DROP TABLE #bcpin
select getdate(), 'db1 was imported'
GO

/*############################################################################################################################################*/
--				REBUILDING ALL INDEXES ON TARGET SERVER
:connect target_server
use [master]
GO
set nocount on 
if object_id('tempdb..databases_migrate') IS NOT NULL
DROP TABLE tempdb..databases_migrate
if object_id('tempdb..rebuild_idx') IS NOT NULL
DROP TABLE tempdb..rebuild_idx

CREATE TABLE tempdb..databases_migrate (db nvarchar(256))

insert into tempdb..databases_migrate
VALUES (N'db1'), (N'db2')							--		Enter db names to rebuild indexes here

create table tempdb..rebuild_idx (scr NVARCHAR(MAX))

declare @db nvarchar(256),
		@sql nvarchar(max)

select top 1 @db = db from tempdb..databases_migrate
while @@rowcount > 0
BEGIN
	set @sql = N'use ' + quotename(@db) + N';
	insert into tempdb..rebuild_idx
	select N''ALTER INDEX '' + quotename(i.name) + N'' on '' + quotename(db_name()) + N''.'' + quotename(schema_name(o.schema_id)) + N''.'' + quotename(object_name(i.object_id)) + N'' REBUILD WITH (SORT_IN_TEMPDB = OFF, STATISTICS_NORECOMPUTE = OFF, ONLINE = OFF, MAXDOP = 8);''
	from sys.indexes i join sys.objects o
		on (i.object_id = o.object_id)
	where i.type in (1,2)
	and o.is_ms_shipped = 0'

	BEGIN TRY
		exec (@sql)
	END TRY

	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH

	delete from tempdb..databases_migrate where db = @db
	select top 1 @db = db from tempdb..databases_migrate
END
drop table tempdb..databases_migrate

select top 1 @sql = scr from tempdb..rebuild_idx
while @@rowcount > 0
BEGIN
	BEGIN TRY
		exec (@sql)
	END TRY

	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH

	delete from tempdb..rebuild_idx where scr = @sql
	select top 1 @sql = scr from tempdb..rebuild_idx
END
drop table tempdb..rebuild_idx
GO

DROP LOGIN [DOMAIN\SQLServiceAccount]		-- Drop login we've created in the beginning
GO
select getdate(), 'Shrinking files'
GO
use [db1]
GO
DBCC SHRINKFILE ('db1_log', 2048)		-- Shrink log file
GO
use [db2]
GO
DBCC SHRINKFILE ('db2_log', 4096)		-- Shrink log file
GO
ALTER DATABASE [db1] SET RECOVERY FULL
GO
ALTER DATABASE [db2] SET RECOVERY FULL
GO
select getdate(), 'Finished!'
GO
