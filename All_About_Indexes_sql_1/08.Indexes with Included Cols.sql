/**********************************************************************
SQL Server Internals from the Practical Angle

Dmitri Korotkevitch
http://aboutsqlserver.com
dmitri@aboutsqlserver.com

Tables and Indexes: Indexes with Included Columns
**********************************************************************/
use SqlServerInternals
go

set nocount on
go


if exists
(
	select * 
	from 
		sys.indexes i join sys.tables t on
			i.object_id = t.object_id
		join sys.schemas s on
			t.schema_id = s.schema_id
	where
		s.name = 'dbo' and t.name = 'Customers' and i.name = 'IDX_Customers_LastName_FirstName_PhoneIncluded'
)	
	drop index IDX_Customers_LastName_FirstName_PhoneIncluded on dbo.Customers
go


-- !! Enable INCLUDE ACTUAL EXECUTION PLAN !!

set statistics io on
go

select CustomerId, LastName, FirstName, Phone
from dbo.Customers
where LastName = 'Smith'
go

select CustomerId, LastName, FirstName, Phone
from dbo.Customers with (Index=IDX_Customers_LastName_FirstName)
where LastName = 'Smith'
go

create nonclustered index IDX_Customers_LastName_FirstName_PhoneIncluded
on dbo.Customers(LastName, FirstName)
include(Phone)
go

select CustomerId, LastName, FirstName, Phone
from dbo.Customers
where FirstName = 'Brian'
go