/**********************************************************************
SQL Server Internals from the Practical Angle

Dmitri Korotkevitch
http://aboutsqlserver.com
dmitri@aboutsqlserver.com

Tables and Indexes: Keys greater than 900 bytes & "Truly Random" values optimization
**********************************************************************/

use SqlServerInternals
go

set nocount on
go

/* Keys greater than 900 bytes */

if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'LargeKey' and s.name = 'dbo'
)
	drop table dbo.LargeKey
go


create table dbo.LargeKey
(
	Id int not null identity(1,1),
	LargeField nvarchar(540) not null,
	Placeholder char(200) null
		constraint DEF_LargeKey_Placeholder
		default 'Placeholder',
	 
	constraint PK_Data
	primary key clustered(ID)
)
go

;WITH N1(C) AS (SELECT 0 UNION ALL SELECT 0) -- 2 rows
,N2(C) AS (SELECT 0 FROM N1 AS T1 CROSS JOIN N1 AS T2) -- 4 rows
,N3(C) AS (SELECT 0 FROM N2 AS T1 CROSS JOIN N2 AS T2) -- 16 rows
,N4(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N3 AS T2) -- 256 rows
,N5(C) AS (SELECT 0 FROM N4 AS T1 CROSS JOIN N4 AS T2) -- 65,536 rows
,IDs(ID) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM N5)	
insert into dbo.LargeKey(LargeField) 
	select REPLICATE(convert(nvarchar(36),NEWID()),15)
	from IDs
go

/* Enable execution plan */
set statistics io on
go

/* Table Scan */

declare
	@Param nvarchar(540)
	
select @Param = LargeField from dbo.LargeKey where Id = 100

select * from dbo.LargeKey where LargeField = @Param
go

/* You cannot create the index - key size > 900 bytes*/
create unique nonclustered index IDX_LargeKey_LargeField
on dbo.LargeKey(LargeField)
go

/* Add calculated persistent column */
alter table dbo.LargeKey
add
	LargeFieldCheckSum as CHECKSUM(LargeField)
	PERSISTED
go

/* Don't forget to rebuild the clustered index */
alter index PK_Data on dbo.LargeKey REBUILD
go

/* Create the index on the column */
create index IDX_LargeKey_LargeFieldCheckSum 
on dbo.LargeKey(LargeFieldCheckSum)
go

/* Now let's modify select a little bit */
declare
	@Param nvarchar(540)
	
select @Param = LargeField from dbo.LargeKey where Id = 100

select * 
from dbo.LargeKey 
where LargeField = @Param and LargeFieldCheckSum  = CHECKSUM(@Param)
go



/*"Truly Random" values optimization*/

alter table dbo.UniqueidentifierCI
	drop constraint PK_UniqueidentifierCI
go

alter table dbo.UniqueidentifierCI
add
	IDCheckSum as CHECKSUM(ID)
	PERSISTED
go

create nonclustered index IDX_UniqueidentifierCI_IDCheckSum
on dbo.UniqueidentifierCI(IDCheckSum)
go

declare
	@Param uniqueidentifier
	
select top 1 @Param = ID from dbo.UniqueidentifierCI

select * 
from dbo.UniqueidentifierCI 
where ID = @Param and IDCheckSum  = CHECKSUM(@Param)
go