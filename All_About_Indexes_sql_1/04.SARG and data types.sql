/**********************************************************************
SQL Server Internals from the Practical Angle

Dmitri Korotkevitch
http://aboutsqlserver.com
dmitri@aboutsqlserver.com

Tables and Indexes: SARG and Data Types
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
		t.name = 'SARGDemo' and s.name = 'dbo'
)
	drop table dbo.SARGDemo
go

create table dbo.SARGDemo
(
	VarcharKey varchar(10) not null,
	Placeholder char(200)
);

create unique clustered index IDX_SARGDemo_VarcharKey
on dbo.SARGDemo(VarcharKey);

with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.SARGDemo(VarcharKey)
	select convert(varchar(10),ID)
	from IDs
go

declare
	@IntParam int = '200'

select * from dbo.SARGDemo where VarcharKey = @IntParam
select * from dbo.SARGDemo where VarcharKey = convert(varchar(10),@IntParam)
go

select * from dbo.SARGDemo where VarcharKey = '200'
select * from dbo.SARGDemo where VarcharKey = N'200' -- unicode parameter
go

