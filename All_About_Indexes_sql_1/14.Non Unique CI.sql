/**********************************************************************
SQL Server Internals from the Practical Angle

Dmitri Korotkevitch
http://aboutsqlserver.com
dmitri@aboutsqlserver.com

Tables and Indexes: Non-unique CI
**********************************************************************/

use SqlServerInternals
go

set nocount on
go


if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'UniqueCI' and s.name = 'dbo'
)
	drop table dbo.UniqueCI
go

if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'NonUniqueCINoDups' and s.name = 'dbo'
)
	drop table dbo.NonUniqueCINoDups
go

if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'NonUniqueCIDups' and s.name = 'dbo'
)
	drop table dbo.NonUniqueCIDups
go

create table dbo.UniqueCI
(
	KeyValue int not null,
	ID int not null,
	Data char(990) not null,
	VarData varchar(32) not null
		default 'v'
)
go

create unique clustered index IDX_UniqueCI_KeyValue
on dbo.UniqueCI(KeyValue)
go

create table dbo.NonUniqueCINoDups
(
	KeyValue int not null,
	ID int not null,
	Data char(990) not null,
	VarData varchar(32) not null
		default 'v'
)
go

create /*unique*/ clustered index IDX_NonUniqueCINoDups_KeyValue
on dbo.NonUniqueCINoDups(KeyValue)
go

create table dbo.NonUniqueCIDups
(
	KeyValue int not null,
	ID int not null,
	Data char(990) not null,
	VarData varchar(32) not null
		default 'v'
)
go

create /*unique*/ clustered index IDX_NonUniqueCIDups_KeyValue
on dbo.NonUniqueCIDups(KeyValue)
go

-- Populating data
begin tran
	;WITH N1(C) AS (SELECT 0 UNION ALL SELECT 0) -- 2 rows
	,N2(C) AS (SELECT 0 FROM N1 AS T1 CROSS JOIN N1 AS T2) -- 4 rows
	,N3(C) AS (SELECT 0 FROM N2 AS T1 CROSS JOIN N2 AS T2) -- 16 rows
	,N4(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N3 AS T2) -- 256 rows
	,N5(C) AS (SELECT 0 FROM N4 AS T1 CROSS JOIN N4 AS T2) -- 65,536 rows
	,IDs(ID) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM N5)	
	insert into dbo.UniqueCI(KeyValue, ID, Data)
		select ID, ID, REPLICATE('a',975)
		from IDs
	
	;WITH N1(C) AS (SELECT 0 UNION ALL SELECT 0) -- 2 rows
	,N2(C) AS (SELECT 0 FROM N1 AS T1 CROSS JOIN N1 AS T2) -- 4 rows
	,N3(C) AS (SELECT 0 FROM N2 AS T1 CROSS JOIN N2 AS T2) -- 16 rows
	,N4(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N3 AS T2) -- 256 rows
	,N5(C) AS (SELECT 0 FROM N4 AS T1 CROSS JOIN N4 AS T2) -- 65,536 rows
	,IDs(ID) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM N5)	
	insert into dbo.NonUniqueCINoDups(KeyValue, ID, Data)
		select ID, ID, REPLICATE('b',975)
		from IDs

	;WITH N1(C) AS (SELECT 0 UNION ALL SELECT 0) -- 2 rows
	,N2(C) AS (SELECT 0 FROM N1 AS T1 CROSS JOIN N1 AS T2) -- 4 rows
	,N3(C) AS (SELECT 0 FROM N2 AS T1 CROSS JOIN N2 AS T2) -- 16 rows
	,N4(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N3 AS T2) -- 256 rows
	,N5(C) AS (SELECT 0 FROM N4 AS T1 CROSS JOIN N4 AS T2) -- 65,536 rows
	,IDs(ID) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM N5)	
	insert into dbo.NonUniqueCIDups(KeyValue, ID, Data)
		select convert(int,ID / 1000) + 1, ID, REPLICATE('c',975)
		from IDs
	option (maxrecursion 0)	
commit
go

-- Let's check index statistics
SELECT index_level, page_count, min_record_size_in_bytes
	, max_record_size_in_bytes, avg_record_size_in_bytes, *
FROM sys.dm_db_index_physical_stats
(DB_ID(), OBJECT_ID(N'dbo.UniqueCI'), 1, NULL , 'DETAILED')

SELECT index_level, page_count, min_record_size_in_bytes
	, max_record_size_in_bytes, avg_record_size_in_bytes, *
FROM sys.dm_db_index_physical_stats
(DB_ID(), OBJECT_ID(N'dbo.NonUniqueCINoDups'), 1, NULL , 'DETAILED')

SELECT index_level, page_count, min_record_size_in_bytes
	, max_record_size_in_bytes, avg_record_size_in_bytes, *
FROM sys.dm_db_index_physical_stats
(DB_ID(), OBJECT_ID(N'dbo.NonUniqueCIDups'), 1, NULL , 'DETAILED')
go

-- Let's create non-clustered indexes on ID
create nonclustered index IDX_UniqueCI_ID
on dbo.UniqueCI(ID)

create nonclustered index IDX_NonUniqueCINoDups_ID
on dbo.NonUniqueCINoDups(ID)

create nonclustered index IDX_NonUniqueCIDups_ID
on dbo.NonUniqueCIDups(ID)
go

-- Let's check index statistics on NCI
SELECT index_level, page_count, min_record_size_in_bytes
	, max_record_size_in_bytes, avg_record_size_in_bytes, *
FROM sys.dm_db_index_physical_stats
(DB_ID(), OBJECT_ID(N'dbo.UniqueCI'), 2, NULL , 'DETAILED')

SELECT index_level, page_count, min_record_size_in_bytes
	, max_record_size_in_bytes, avg_record_size_in_bytes, *
FROM sys.dm_db_index_physical_stats
(DB_ID(), OBJECT_ID(N'dbo.NonUniqueCINoDups'), 2, NULL , 'DETAILED')

SELECT index_level, page_count, min_record_size_in_bytes
	, max_record_size_in_bytes, avg_record_size_in_bytes, *
FROM sys.dm_db_index_physical_stats
(DB_ID(), OBJECT_ID(N'dbo.NonUniqueCIDups'), 2, NULL , 'DETAILED')
go

-- Let's create non-clustered indexes on VarData
create nonclustered index IDX_UniqueCI_VarData
on dbo.UniqueCI(VarData)

create nonclustered index IDX_NonUniqueCINoDups_VarData
on dbo.NonUniqueCINoDups(VarData)

create nonclustered index IDX_NonUniqueCIDups_VarData
on dbo.NonUniqueCIDups(VarData)
go

-- Let's check index statistics on NCI
SELECT index_level, page_count, min_record_size_in_bytes
	, max_record_size_in_bytes, avg_record_size_in_bytes, *
FROM sys.dm_db_index_physical_stats
(DB_ID(), OBJECT_ID(N'dbo.UniqueCI'), 3, NULL , 'DETAILED')

SELECT index_level, page_count, min_record_size_in_bytes
	, max_record_size_in_bytes, avg_record_size_in_bytes, *
FROM sys.dm_db_index_physical_stats
(DB_ID(), OBJECT_ID(N'dbo.NonUniqueCINoDups'), 3, NULL , 'DETAILED')

SELECT index_level, page_count, min_record_size_in_bytes
	, max_record_size_in_bytes, avg_record_size_in_bytes, *
FROM sys.dm_db_index_physical_stats
(DB_ID(), OBJECT_ID(N'dbo.NonUniqueCIDups'), 3, NULL , 'DETAILED')
go
