/**********************************************************************
SQL Server Internals from the Practical Angle

Dmitri Korotkevitch
http://aboutsqlserver.com
dmitri@aboutsqlserver.com

Tables and Indexes: Partitioned Tables (2)
**********************************************************************/

use SqlServerInternals
go

set nocount on
go

if exists(
	select *
	from sys.views v join sys.schemas s on
		v.schema_id = s.schema_id
	where
		v.name = 'vPostalCodeSales' and s.name = 'dbo'
)
	drop view dbo.vPostalCodeSales
go

if exists(
	select *
	from sys.tables t join sys.schemas s on
		t.schema_id = s.schema_id
	where
		t.name = 'PostalCodeSales' and s.name = 'dbo'
)
	drop table dbo.PostalCodeSales
go

if exists(
	select *
	from sys.partition_schemes 
	where name = 'psPostalCodes'
)
	drop partition scheme psPostalCodes

go


if exists(
	select *
	from sys.partition_functions
	where name = 'pfPostalCodes'
)
	drop partition function pfPostalCodes
go

create partition function pfPostalCodes(int)
as range right for values 
(10000,10001,10002,10003,10004,10005,
10006,10007,10008,10009,10010)
go

create partition scheme psPostalCodes
as partition pfPostalCodes
all to ([primary])
go

create table dbo.PostalCodeSales
(
	PostalCode int not null,
	ID int not null identity(1,1),
	TranAmount float not null,
	PlaceHolder char(200) not null,
	
	constraint PK_PostalCodeSales
	primary key clustered(PostalCode, ID)
	on psPostalCodes(PostalCode)
)
go

;with PostalCodes(PostalCode)
as
(
	select 10000
	union all
	select PostalCode + 1
	from PostalCodes
	where PostalCode < 10010
)
,Nums(Num)
as
(
	select 1
	union all
	select Num + 1
	from Nums
	where Num < 200000
)
insert into dbo.PostalCodeSales(PostalCode, TranAmount, PlaceHolder)
	select pc.PostalCode, 1 + convert(int,Num / 2)
		,convert(char(5),PostalCode) + ': ' + convert(char(20),1 + convert(int,Num / 2))
	from PostalCodes pc cross join Nums n
option (maxrecursion 0)
go


create index IDX_PostalCodeSales_TranAmount_PostalCode
on dbo.PostalCodeSales(TranAmount, PostalCode)
on psPostalCodes(PostalCode)
go


set statistics io on
select PostalCode, Max(TranAmount) as MaxAmount
from dbo.PostalCodeSales
group by PostalCode
set statistics io off
go

select *
from sys.partition_functions pf join sys.partition_range_values prf on
	pf.function_id = prf.function_id
where pf.name = 'pfPostalCodes'		
go

set statistics io on
;with PostalCodes(PostalCode, boundary)
as
(
	select convert(int,value) as PostalCode, boundary_id
	from sys.partition_functions pf join sys.partition_range_values prf on
		pf.function_id = prf.function_id
	where pf.name = 'pfPostalCodes'		
)
select p.PostalCode, s.TranAmount
from PostalCodes p
	cross apply
	(
		select top 1 s.TranAmount 
		from dbo.PostalCodeSales s
		where $Partition.pfPostalCodes(PostalCode) = p.boundary
		order by TranAmount desc
	) s
set statistics io off
go