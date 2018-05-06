/**********************************************************************
SQL Server Internals from the Practical Angle

Dmitri Korotkevitch
http://aboutsqlserver.com
dmitri@aboutsqlserver.com

Tables and Indexes: Uniquefiers
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
		t.name = 'IdentityCI' and s.name = 'dbo'
)
	drop table dbo.IdentityCI
go

create table dbo.IdentityCI
(
	ID int not null identity(1,1),
	Val int not null,
	Placeholder char(100) not null
		constraint DEF_IdentityCI_Placeholder
		default 'Placeholder'  
		
	constraint PK_IdentityCI
	primary key clustered(ID)
)
go


if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'UniqueidentifierCI' and s.name = 'dbo'
)
	drop table dbo.UniqueidentifierCI
go

create table dbo.UniqueidentifierCI
(
	ID uniqueidentifier not null
		constraint DEF_UniqueidentifierCI_ID
		default newid(),  
	Val int not null,
	Placeholder char(100) not null
		constraint DEF_UniqueidentifierCI_Placeholder
		default 'Placeholder'  
		
	constraint PK_UniqueidentifierCI
	primary key clustered(ID)
)
go


set statistics io on
set statistics time on

;WITH N1(C) AS (SELECT 0 UNION ALL SELECT 0) -- 2 rows
,N2(C) AS (SELECT 0 FROM N1 AS T1 CROSS JOIN N1 AS T2) -- 4 rows
,N3(C) AS (SELECT 0 FROM N2 AS T1 CROSS JOIN N2 AS T2) -- 16 rows
,N4(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N3 AS T2) -- 256 rows
,N5(C) AS (SELECT 0 FROM N4 AS T1 CROSS JOIN N4 AS T2) -- 65,536 rows
,IDs(ID) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM N5)
insert into dbo.IdentityCI(Val)
	select ID from IDs

;WITH N1(C) AS (SELECT 0 UNION ALL SELECT 0) -- 2 rows
,N2(C) AS (SELECT 0 FROM N1 AS T1 CROSS JOIN N1 AS T2) -- 4 rows
,N3(C) AS (SELECT 0 FROM N2 AS T1 CROSS JOIN N2 AS T2) -- 16 rows
,N4(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N3 AS T2) -- 256 rows
,N5(C) AS (SELECT 0 FROM N4 AS T1 CROSS JOIN N4 AS T2) -- 65,536 rows
,IDs(ID) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM N5)
insert into dbo.UniqueidentifierCI(Val)
	select ID from IDs

set statistics io off
set statistics time off
go

select page_count, avg_page_space_used_in_percent, avg_fragmentation_in_percent, * 
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'IdentityCI'),1,null,'DETAILED')
select page_count, avg_page_space_used_in_percent, avg_fragmentation_in_percent, * 
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'UniqueidentifierCI'),1,null,'DETAILED')
go
