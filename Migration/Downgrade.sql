-- Основное
	- Описание и возможные миграции https://msdn.microsoft.com/en-us/library/ms143393.aspx?f=255&MSPPError=-2147217396
	- В кластерной конфигурации могут не поддерживаться любые изменения редакции, нужно проверять
	- https://msdn.microsoft.com/ru-ru/library/cc645993(v=sql.120).aspx -- Что поддерживается какой версией
	
-- Поддерживается только подъём вверх по версиям
	https://msdn.microsoft.com/ru-ru/library/ms143393(SQL.105).aspx
	
-- Как понять можно ли делать donwgrade
	- https://msdn.microsoft.com/en-us/library/cc645993(v=sql.105).aspx
	- https://www.brentozar.com/archive/2014/08/sql-server-edition-change-standard-edition-enterprise-evaluation/
		- SELECT * FROM sys.dm_db_persisted_sku_features -- использует ли БД возможности Enterprise
			CREATE TABLE #AllTables(DB_Name nvarchar(100),feature_name NVARCHAR(4000),feature_id int );  
			EXEC sp_msforeachdb N'use [?]  
			INSERT #AllTables SELECT db_name() DN_Name,feature_name, ''1'' FROM sys.dm_db_persisted_sku_features';
			SELECT * FROM #AllTables ORDER BY 1;
			DROP TABLE #AllTables; 
			
	-- SQL Server 2005
		EXEC sp_msforeachdb N'use [?]  
					select name, object_id, type_desc
		from sys.objects
		where objectproperty(object_id, N''TableHasVarDecimalStorageFormat'') = 1

			select case
					 when max(partition_number) > 1
					   then ''Partitioning''
					 else ''''
				   end
			  from sys.partitions
		';
			
		
-- Способы
	1. Через удаление-установку
		- обязательно сохранить копии системных БД
	2. Через создание другого экземпляра, перевода всё туда и перенаправления в AD
		
-- Общий скрипт поиска используемых возможностей Enterprise
	SELECT * FROM sys.server_audits -- Audit
	SELECT * FROM sys.dm_hadr_availability_replica_states -- AOM
	SELECT * FROM sys.databases WHERE source_database_id IS NOT NULL -- Snapshot
	SELECT st.name, st.object_id, sp.partition_id, sp.partition_number, sp.data_compression, sp.data_compression_desc FROM sys.partitions SP INNER JOIN sys.tables ST ON st.object_id = sp.object_id WHERE data_compression <> 0 -- Compress
	SELECT * FROM sys.dm_resource_governor_resource_pools WHERE name NOT IN ('internal','default') -- Resource Governor
	-- Перестроение индексов онлайн
	
		SELECT * FROM sys.dm_db_persisted_sku_features -- Фичи по БД
	
	
-- Ограничения
	1. Нельзя в кластерной конфигурации установить Standard на вторую ноду и перевести первую с Enterprise туда. На выходе даже если пытаемся добавить нову с лицензией Standard, устанавливается Enterprise
	