/**********************************************************************
SQL Server Internals from the Practical Angle

Dmitri Korotkevitch
http://aboutsqlserver.com
dmitri@aboutsqlserver.com

Tables and Indexes: Partitioned Tables (1)
**********************************************************************/
use tempdb
go

IF EXISTS ( SELECT  *
            FROM    sys.tables t
                    JOIN sys.schemas s ON t.schema_id = s.schema_id
            WHERE   s.name = 'dbo'
                    AND t.name = 'Orders' ) 
   DROP TABLE dbo.Orders
go
  

CREATE TABLE dbo.Orders
(
	Id INT NOT NULL,
	OrderDate DATETIME NOT NULL,
	DateModified DATETIME NOT NULL,
	Placeholder CHAR(500) NOT NULL
		CONSTRAINT Def_Data_Placeholder 
		DEFAULT 'Placeholder',
)
go

CREATE UNIQUE CLUSTERED INDEX IDX_Orders_Id
ON dbo.Orders(ID)
go

DECLARE @StartDate DATETIME = '2012-01-01';

WITH N1(C) AS (SELECT 0 UNION ALL SELECT 0) -- 2 rows
,N2(C) AS (SELECT 0 FROM N1 AS T1 CROSS JOIN N1 AS T2) -- 4 rows
,N3(C) AS (SELECT 0 FROM N2 AS T1 CROSS JOIN N2 AS T2) -- 16 rows
,N4(C) AS (SELECT 0 FROM N3 AS T1 CROSS JOIN N3 AS T2) -- 256 rows
,N5(C) AS (SELECT 0 FROM N4 AS T1 CROSS JOIN N4 AS T2) -- 65,536 rows
,N6(C) AS (SELECT 0 FROM N5 AS T1 CROSS JOIN N2 AS T2 CROSS JOIN N1 AS T3) -- 524,288 rows
,IDs(ID) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM N6)
INSERT INTO dbo.Orders(ID,OrderDate,DateModified)
	SELECT  
	   ID, 
	   DATEADD(second,35 * ID,@StartDate),
	   CASE 
		  WHEN ID % 10 = 0 
		  THEN DATEADD(second,   
				24 * 60 * 60 * (ID % 31) + 11200 + ID % 59 + 35 * ID,
				@StartDate)
		  ELSE DATEADD(second,35 * ID,@StartDate)
	   END
	FROM IDs
go

CREATE UNIQUE NONCLUSTERED INDEX IDX_Orders_DateModified_Id
ON dbo.Orders(DateModified, Id)
go

-- Enable "Include Actual Execution Plan"
SET STATISTICS IO ON
SET STATISTICS TIME ON
DECLARE 
	@LastDateModified DATETIME = '2012-06-25'

SELECT TOP 100 ID, OrderDate, DateModified, PlaceHolder
FROM    dbo.Orders
WHERE   DateModified > @LastDateModified
ORDER BY DateModified,Id

SET STATISTICS TIME OFF
SET STATISTICS IO OFF
go

DROP INDEX IDX_Orders_DateModified_Id ON dbo.Orders
DROP INDEX IDX_Orders_Id ON dbo.Orders
go

CREATE PARTITION FUNCTION pfOrders(DATETIME)
AS RANGE RIGHT FOR VALUES 
('2012-02-01', '2012-03-01',
'2012-04-01','2012-05-01','2012-06-01',
'2012-07-01','2012-08-01')
go

CREATE PARTITION SCHEME psOrders 
AS PARTITION pfOrders
ALL TO ([primary])
go

CREATE UNIQUE CLUSTERED INDEX IDX_Orders_OrderDate_Id
ON dbo.Orders(OrderDate,ID)
ON psOrders(OrderDate)
go
	
CREATE UNIQUE INDEX IDX_Data_DateModified_Id_OrderDate
ON dbo.Orders(DateModified, ID, OrderDate)
ON psOrders(OrderDate)
go

-- Enable "Include Actual Execution Plan"
SET STATISTICS IO ON
SET STATISTICS TIME ON

DECLARE 
	@LastDateModified DATETIME = '2012-06-25'

SELECT TOP 100 ID, OrderDate, DateModified, PlaceHolder
FROM    dbo.Orders
WHERE   DateModified > @LastDateModified
ORDER BY DateModified,Id

SET STATISTICS TIME OFF
SET STATISTICS IO OFF
go

-- Enable "Include Actual Execution Plan"
SET STATISTICS IO ON
SET STATISTICS TIME ON
DECLARE 
	@LastDateModified DATETIME = '2012-06-25'

SELECT TOP 100 ID, OrderDate, DateModified, PlaceHolder
FROM    dbo.Orders WITH (INDEX = IDX_Data_DateModified_Id_OrderDate)
WHERE   DateModified > @LastDateModified
ORDER BY DateModified,Id

SET STATISTICS TIME OFF
SET STATISTICS IO OFF
go


-- Demo of "manual" partition elimination with $Partition function
-- selecting data from 1 partition only
SET STATISTICS IO ON
SET STATISTICS TIME ON
DECLARE 
	@LastDateModified DATETIME = '2012-06-25'

SELECT TOP 100 ID, OrderDate, DateModified, PlaceHolder
FROM    dbo.Orders 
WHERE   
	DateModified > @LastDateModified
	AND $partition.pfOrders(OrderDate) = 5
ORDER BY DateModified,Id

SET STATISTICS TIME OFF
SET STATISTICS IO OFF
go

-- Get number of partitions we have
DECLARE 
	@BoundaryCount INT 

SELECT  @BoundaryCount = MAX(boundary_id) + 1
FROM    sys.partition_functions pf
        JOIN sys.partition_range_values prf 
			ON pf.function_id = prf.function_id
WHERE   pf.name = 'pfOrders'

;WITH  Boundaries(boundary_id)
AS 
(
	SELECT  1
	UNION ALL
	SELECT  boundary_id + 1
	FROM    Boundaries
	WHERE   boundary_id < @BoundaryCount
)
SELECT *
FROM   Boundaries
go

-- Step 1 of "Ideal" algorithm 
DECLARE 
	@LastDateModified DATETIME = '2012-06-25',
	@BoundaryCount INT 
	
SELECT  @BoundaryCount = MAX(boundary_id) + 1
FROM    sys.partition_functions pf
        JOIN sys.partition_range_values prf 
			ON pf.function_id = prf.function_id
WHERE   pf.name = 'pfOrders'

;WITH  Boundaries(boundary_id)
AS 
(
	SELECT  1
	UNION ALL
	SELECT  boundary_id + 1
	FROM    Boundaries
	WHERE   boundary_id < @BoundaryCount
)
SELECT part.ID, part.OrderDate, part.DateModified,
	   $partition.pfOrders(part.OrderDate) AS [Partition Number]
FROM   Boundaries b
	   CROSS APPLY 
       (
		SELECT TOP 100 ID, OrderDate, DateModified
		FROM   dbo.Orders
		WHERE  DateModified > @LastDateModified
			   AND $Partition.pfOrders(OrderDate) = b.boundary_id
		ORDER BY DateModified, ID
		) part
go

-- Final Version
SET STATISTICS IO ON
SET STATISTICS TIME ON

DECLARE 
	@LastDateModified DATETIME = '2012-06-25',
	@BoundaryCount INT 
	
SELECT  @BoundaryCount = MAX(boundary_id) + 1
FROM    sys.partition_functions pf
        JOIN sys.partition_range_values prf 
			ON pf.function_id = prf.function_id
WHERE   pf.name = 'pfOrders'

;WITH  Boundaries(boundary_id)
AS 
(
	SELECT  1
	UNION ALL
	SELECT  boundary_id + 1
	FROM    Boundaries
	WHERE   boundary_id < @BoundaryCount
)
,Top100(ID,OrderDate,DateModified)
AS 
(
	SELECT TOP 100 part.ID, part.OrderDate, part.DateModified
	FROM    Boundaries b
			CROSS APPLY 
			(
				SELECT TOP 100 ID, OrderDate, DateModified
				FROM   dbo.Orders
				WHERE  DateModified > @LastDateModified
						AND $Partition.pfOrders(OrderDate) = 
							b.boundary_id
				ORDER BY DateModified, ID
			) part
	ORDER BY part.DateModified, part.ID
)
SELECT d.Id, d.OrderDate, d.DateModified, d.Placeholder
FROM   dbo.Orders d 
	   JOIN Top100 t ON d.Id = t.Id
			AND d.OrderDate = t.OrderDate
ORDER BY d.DateModified, d.ID
SET STATISTICS TIME OFF
SET STATISTICS IO OFF
go

-- using temp table to improve estimations
CREATE TABLE #T
(
	ID INT NOT NULL PRIMARY KEY
)

DECLARE 
	@LastDateModified DATETIME = '2012-06-25',
	@BoundaryCount INT 

SELECT  @BoundaryCount = MAX(boundary_id) + 1
FROM    sys.partition_functions pf
        JOIN sys.partition_range_values prf 
			ON pf.function_id = prf.function_id
WHERE   pf.name = 'pfOrders'

;WITH  Boundaries(boundary_id)
AS 
(
	SELECT  1
	UNION ALL
	SELECT  boundary_id + 1
	FROM    Boundaries
	WHERE   boundary_id < @BoundaryCount
)
INSERT INTO #T(ID)
	SELECT  boundary_id
    FROM    Boundaries
    
;WITH Top100(ID,OrderDate,DateModified)
AS 
(
	SELECT TOP 100 part.ID, part.OrderDate, part.DateModified
	FROM    #T b
			CROSS APPLY 
			(
				SELECT TOP 100 ID, OrderDate, DateModified
				FROM   dbo.Orders
				WHERE  DateModified > @LastDateModified
						AND $Partition.pfOrders(OrderDate) = 
							b.id
				ORDER BY DateModified, ID
			) part
	ORDER BY part.DateModified, part.ID
)
SELECT d.Id, d.OrderDate, d.DateModified, d.Placeholder
FROM   dbo.Orders d 
	   JOIN Top100 t ON d.Id = t.Id
			AND d.OrderDate = t.OrderDate
ORDER BY d.DateModified, d.ID

DROP TABLE #T
go


-- If number of partitions is static
DECLARE 
	@LastDateModified DATETIME = '2012-06-25'

;WITH  Boundaries(boundary_id)
AS 
(
	SELECT  V.v
    FROM 
		(VALUES (1),(2),(3),(4),(5),(6),(7),(8)) AS V (v)
)
,Top100(ID,OrderDate,DateModified)
AS 
(
	SELECT TOP 100 part.ID, part.OrderDate, part.DateModified
	FROM    Boundaries b
			CROSS APPLY 
			(
				SELECT TOP 100 ID, OrderDate, DateModified
				FROM   dbo.Orders
				WHERE  DateModified > @LastDateModified
						AND $Partition.pfOrders(OrderDate) = 
							b.boundary_id
				ORDER BY DateModified, ID
			) part
	ORDER BY part.DateModified, part.ID
)
SELECT d.Id, d.OrderDate, d.DateModified, d.Placeholder
FROM   dbo.Orders d 
	   JOIN Top100 t ON d.Id = t.Id
			AND d.OrderDate = t.OrderDate
ORDER BY d.DateModified, d.ID
GO
