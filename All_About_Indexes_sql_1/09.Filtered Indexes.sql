/**********************************************************************
SQL Server Internals from the Practical Angle

Dmitri Korotkevitch
http://aboutsqlserver.com
dmitri@aboutsqlserver.com

Tables and Indexes: Filtered Indexes
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
		t.name = 'Clients' and s.name = 'dbo'
)
	drop table dbo.Clients
go

create table dbo.Clients1
(
	ClientId int not null,
	Name nvarchar(128) not null,
	SSN varchar(11) null
)
go

insert into dbo.Clients1(ClientId, Name, SSN)
values
	(1, 'Client 1', '123-45-6789'),
	(2, 'Client 2', null),
	(3, 'Client 3', null)
go

create unique index IDX_Clients_SSN
on dbo.Clients1(SSN)
go

create unique index IDX_Clients_SSN
on dbo.Clients1(SSN)
where SSN is not null
go

insert into dbo.Clients1(ClientId, Name, SSN)
values
	(4, 'Client 4', '123-45-6789')
go

insert into dbo.Clients1(ClientId, Name, SSN)
values
	(5, 'Client 5', null)
go

