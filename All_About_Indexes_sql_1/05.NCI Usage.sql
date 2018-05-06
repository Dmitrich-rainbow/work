/**********************************************************************
SQL Server Internals from the Practical Angle

Dmitri Korotkevitch
http://aboutsqlserver.com
dmitri@aboutsqlserver.com

Tables and Indexes: NCI Usage
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
		t.name = 'Books' and s.name = 'dbo'
)
	drop table dbo.Books
go

create table dbo.Books
(
	BookId int identity(1,1) not null,
	Title nvarchar(256) not null,
	-- International Standard Book Number
	ISBN char(14) not null, 
	Placeholder char(100) null
)
go

create unique clustered index IDX_Books_BookId
on dbo.Books(BookId)
go

-- 1,252,000 rows
;with Prefix(Prefix)
as
(
	select 100 
	union all
	select Prefix + 1
	from Prefix
	where Prefix < 600
)
,Postfix(Postfix)
as
(
	select 100000001
	union all
	select Postfix + 1
	from Postfix
	where Postfix < 100002500
)
insert into dbo.Books(ISBN, Title)
	select 
		CONVERT(char(3), Prefix) + '-0' + CONVERT(char(9),Postfix)
		,'Title for ISBN' + CONVERT(char(3), Prefix) + '-0' + CONVERT(char(9),Postfix)
	from Prefix cross join Postfix
option (maxrecursion 0);

create nonclustered index IDX_Books_ISBN on dbo.Books(ISBN);
go

-- How data looks like
select top 10 * from dbo.Books order by BookId
select top 10 * from dbo.Books order by ISBN
go

-- !! Enable: INCLUDE ACTUAL EXECUTION PLAN !!
-- Scan entire table
set statistics io on	
select count(*) from dbo.Books with (index=1) 
set statistics io off
go

set statistics io on	
select * from dbo.Books where ISBN like '210%' 	-- 2,500
set statistics io off
go

select * from sys.dm_db_index_physical_stats(DB_ID(),Object_ID(N'dbo.Books'),1,null,'DETAILED')
go

set statistics io on	
select * from dbo.Books where ISBN like '21[0-2]%' -- 7,500
set statistics io off
go

set statistics io on	
select * from dbo.Books where ISBN like '21[0-4]%' -- 12,500
select * from dbo.Books with (index = IDX_BOOKS_ISBN) where ISBN like '21[0-4]%' 
set statistics io off
go

select 12500./COUNT(*) from dbo.Books	
go



