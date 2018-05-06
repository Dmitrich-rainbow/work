/**********************************************************************
SQL Server Internals from the Practical Angle

Dmitri Korotkevitch
http://aboutsqlserver.com
dmitri@aboutsqlserver.com

Tables and Indexes: Heap Tables
**********************************************************************/
use SqlServerInternals
go

set nocount on
go

/* PFS Demo */
if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'PFSDemo' and s.name = 'dbo'
)
	drop table dbo.PFSDemo
go

create table dbo.PFSDemo
(
   Val varchar(8000) not null
);

;with CTE(ID,Val)
as
(
   select 1, replicate('0',4089)
   union all
   select ID + 1, Val from CTE where ID < 20
)
insert into dbo.PFSDemo
   select Val from CTE;

select page_count, avg_record_size_in_bytes, avg_page_space_used_in_percent
from sys.dm_db_index_physical_stats(db_id(),object_id(N'dbo.PFSDemo'),0,null,'DETAILED');
go

-- 111 bytes row: ~1.4% of page size
insert into dbo.PFSDemo(Val) values(replicate('1',100));

select page_count, avg_record_size_in_bytes, avg_page_space_used_in_percent
from sys.dm_db_index_physical_stats(db_id(),object_id(N'dbo.PFSDemo'),0,null,'DETAILED');
go

-- 2011 bytes row: ~25% of page size
insert into dbo.PFSDemo(Val) values(replicate('2',2000));

select page_count, avg_record_size_in_bytes, avg_page_space_used_in_percent
from sys.dm_db_index_physical_stats(db_id(),object_id(N'dbo.PFSDemo'),0,null,'DETAILED');
go


-- Forwarding pointers
if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'HeapTable' and s.name = 'dbo'
)
	drop table dbo.HeapTable
go

create table dbo.HeapTable
(
	Placeholder char(100) not null
		constraint DEF_HeapTable_Placeholder
		default 'Placeholder',
	IntVal int not null,
	Data varchar(255) null
)
go

;with CTE(IntVal)
as
(
	select 1
	
	union all
	
	select IntVal + 1
	from CTE
	where IntVal < 99999
)
insert into dbo.HeapTable(IntVal)
	select IntVal
	from CTE
option (maxrecursion 0)
go

select page_count, forwarded_record_count, * 
from sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(N'dbo.HeapTable'),0,null,'DETAILED')
go

set statistics io on
set statistics time on
select COUNT(*) from dbo.HeapTable
set statistics time off
set statistics io off
go

update dbo.HeapTable
set Data = REPLICATE('a',255)
go

select page_count, forwarded_record_count, * 
from sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(N'dbo.HeapTable'),0,null,'DETAILED')
go

set statistics io on
set statistics time on
select COUNT(*) from dbo.HeapTable
set statistics time off
set statistics io off
go
