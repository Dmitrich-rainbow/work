/**********************************************************************
SQL Server Internals from the Practical Angle

Dmitri Korotkevitch
http://aboutsqlserver.com
dmitri@aboutsqlserver.com

Tables and Indexes: Statistics
**********************************************************************/

use SqlServerInternals
go

set nocount on
go

-- Some dups - just for demo purposes
;with Prefix(Prefix)
as
(
	select Num 
	from (values(110),(110),(110),(110),(110)) Num(Num)
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
option (maxrecursion 0)
go

alter index IDX_Books_ISBN on dbo.Books rebuild
go

DBCC SHOW_STATISTICS('dbo.Books','IDX_Books_ISBN')
go

set statistics io on	
select * from dbo.Books where ISBN like '555%' 	
set statistics io off
go


;with Postfix(Postfix)
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
		'999-0' + CONVERT(char(9),Postfix)
		,'Title for ISBN 999-0' + CONVERT(char(9),Postfix)
	from Postfix
option (maxrecursion 0)
go

DBCC SHOW_STATISTICS('dbo.Books','IDX_Books_ISBN')
go

set statistics io on	
select * from dbo.Books where ISBN like '999%' 	
set statistics io off
go



