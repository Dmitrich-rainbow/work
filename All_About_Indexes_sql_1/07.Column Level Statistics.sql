/**********************************************************************
SQL Server Internals from the Practical Angle

Dmitri Korotkevitch
http://aboutsqlserver.com
dmitri@aboutsqlserver.com

Tables and Indexes: Column Level Statistics
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
		t.name = 'Customers' and s.name = 'dbo'
)
	drop table dbo.Customers
go

create table dbo.Customers
(
	CustomerId int not null identity(1,1),
	FirstName  nvarchar(64) not null,
	LastName nvarchar(128) not null,
	Phone varchar(32) null,
	Placeholder char(200) not null
		constraint PK_Customers_Placeholder
		default 'This is the placeholder'
)
go

create unique clustered index IDX_Customers_CustomerId
on dbo.Customers(CustomerId)
go


;with FirstNames(FirstName)
as
(
	select Names.Name
	from 
	(
		values('Andrew'),('Andy'),('Anton'),('Ashley'),('Boris'),
		('Brian'),('Cristopher'),('Cathy'),('Daniel'),('Donny'),
		('Edward'),('Eddy'),('Emy'),('Frank'),('George'),('Harry'),
		('Henry'),('Ida'),('John'),('Jimmy'),('Jenny'),('Jack'),
		('Kathy'),('Kim'),('Larry'),('Mary'),('Max'),('Nancy'),
		('Olivia'),('Olga'),('Peter'),('Patrick'),('Robert'),
		('Ron'),('Steve'),('Shawn'),('Tom'),('Timothy'),
		('Uri'),('Vincent')
	) Names(Name)
)
,LastNames(LastName)
as
(
	select Names.Name
	from 
	(
		values('Smith'),('Johnson'),('Williams'),('Jones'),('Brown'),
			('Davis'),('Miller'),('Wilson'),('Moore'),('Taylor'),
			('Anderson'),('Jackson'),('White'),('Harris')
	) Names(Name)
)
insert into dbo.Customers(LastName, FirstName)
	select LastName, FirstName
	from FirstNames cross join LastNames 		
go 50

insert into dbo.Customers(LastName, FirstName)
values('Korotkevitch','Dmitri')
go	


create nonclustered index IDX_Customers_LastName_FirstName
on dbo.Customers(LastName, FirstName)
go

-- !! Enable INCLUDE ACTUAL EXECUTION PLAN !!

select *
from dbo.Customers
where FirstName = 'Brian'
go

select *
from dbo.Customers
where FirstName = 'Dmitri'
go

DBCC SHOW_STATISTICS('dbo.Customers', '<<')
go
