/**********************************************************************
SQL Server Internals from the Practical Angle

Dmitri Korotkevitch
http://aboutsqlserver.com
dmitri@aboutsqlserver.com

Tables and Indexes: Fragmentation
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
		t.name = 'Positions' and s.name = 'dbo'
)
	drop table dbo.Positions
go

create table dbo.Positions
(
	ID int not null identity(1,1),
	Latitude decimal(9,6) not null,
	Longitude decimal(9,6) not null,
	Point geography null,
	Placeholder char(200)
		constraint DEF_Positions_Placeholder
		default 'Placeholder',
		
	constraint PK_Positions
	primary key clustered(ID)
)
go

;with Lats(Lat)
as
(
	select CONVERT(decimal(9,6),-90.0)
	
	union all
	
	select CONVERT(decimal(9,6),Lat + 1)
	from Lats
	where Lat < 90.0
)
,Lons(Lon)
as
(
	select CONVERT(decimal(9,6),-180.0)
	
	union all
	
	select CONVERT(decimal(9,6),Lon + 1)
	from Lons
	where Lon < 180.0
)
insert into dbo.Positions(Latitude, Longitude)
	select Lats.Lat, Lons.Lon
	from Lats cross join Lons
option (maxrecursion 0)
go


select page_count, avg_page_space_used_in_percent, avg_fragmentation_in_percent, * 
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'Positions'),1,null,'DETAILED')
go

update dbo.Positions
set
	Point = geography::Point(Latitude, Longitude, 4326)
go

select page_count, avg_page_space_used_in_percent, avg_fragmentation_in_percent, * 
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'Positions'),1,null,'DETAILED')
go



truncate table dbo.Positions
go

;with Lats(Lat)
as
(
	select CONVERT(decimal(9,6),-90.0)
	
	union all
	
	select CONVERT(decimal(9,6),Lat + 1)
	from Lats
	where Lat < 90.0
)
,Lons(Lon)
as
(
	select CONVERT(decimal(9,6),-180.0)
	
	union all
	
	select CONVERT(decimal(9,6),Lon + 1)
	from Lons
	where Lon < 180.0
)
insert into dbo.Positions(Latitude, Longitude, Point)
	select Lats.Lat, Lons.Lon, geography::Point(0,0,4326)
	from Lats cross join Lons
option (maxrecursion 0)
go


update dbo.Positions
set
	Point = geography::Point(Latitude, Longitude, 4326)
go

select page_count, avg_page_space_used_in_percent, avg_fragmentation_in_percent, * 
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'Positions'),1,null,'DETAILED')
go

select avg(datalength(Point))
from dbo.Positions
go

truncate table dbo.Positions
go

alter table dbo.Positions
add Dummy varbinary(22) null
go

;with Lats(Lat)
as
(
	select CONVERT(decimal(9,6),-90.0)
	
	union all
	
	select CONVERT(decimal(9,6),Lat + 1)
	from Lats
	where Lat < 90.0
)
,Lons(Lon)
as
(
	select CONVERT(decimal(9,6),-180.0)
	
	union all
	
	select CONVERT(decimal(9,6),Lon + 1)
	from Lons
	where Lon < 180.0
)
insert into dbo.Positions(Latitude, Longitude, Dummy)
	select Lats.Lat, Lons.Lon, convert(varbinary(22),replicate('0',22))
	from Lats cross join Lons
option (maxrecursion 0)
go


update dbo.Positions
set
	Point = geography::Point(Latitude, Longitude, 4326)
	,Dummy = null
go

select page_count, avg_page_space_used_in_percent, avg_fragmentation_in_percent, * 
from sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID(N'Positions'),1,null,'DETAILED')
go
