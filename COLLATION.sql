-- ������������� � ����� ��������� �����������
	https://msdn.microsoft.com/ru-ru/library/ms179886(v=sql.120).aspx

-- COLLATION (������ �������� � ��������� ������ � ��������)
	- SELECT * FROM fn_helpcollations();
	- ������ �� ����������, LIKE
	- ������� ����������� �� �������� ������
	- ��������� ��������� ����� ���� ����������� �����
	- ��������� �������� ����� ��� ������� �������������� �����

-- ����� ������
	1. ������ �������
	2. ������ ����
	3. ������ �������
	
-- ������� Collation
	1. ����� �������� ���� ������, �������� ���� � SINGLE_USER
	2.  ALTER DATABASE ���_�� SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		ALTER DATABASE ���_�� COLLATE ������_��������� 
		ALTER DATABASE ���_�� SET MULTI_USER

-- �������� COLLATE
select * from fn_helpcollations()
where name = 'SQL_Latin1_General_CP1_CI_AS'
or name = 'SQL_Latin1_General_CP1_CS_AS'

-- ��������
	1. �� ������������ �������
		- ���������� CAST(test as nvarchar(255)) -- Unicode
		- �������� ��������� �������� (Remote Collation)
		
-- �����������
	1. ����������� COLLATE ����� ��������� ������ � ����� ������ char, varchar, text, nchar, nvarchar � ntext.
	2. ��������� ��������� � ��������� MAX, MIN, BETWEEN, LIKE, IN ����������� � ������ ���������� ����������.
	3. �������� UNION ����������� � ������ ���������� ���������� 
	4. ��� ���������� �������� ������������ ����� ����������� �������� ��������� ����������.
	5. ��������� UNION ALL � CASE ����������� ��� ����� ���������� ����������
	6. ������� CAST, CONVERT � COLLATE ��������� ��������� ���������� ��� ������ � ������� ���� char, varchar � text
	7. BUT� if you go from case sensitive to case insensitive� be careful
	8. ���� ���������� � tempdb � ����� ����������, �� ����� ���� �������� ��� comparisons/lookups/joins
	
-- ���������� ��/containment DB
	������ COLLATION tempdb �� COLLATION user DB
	
-- ��������� COLLATION
	- https://msdn.microsoft.com/ru-ru/library/dd207003(v=sql.120).aspx
	- �� �� ������ �������� COLLATION �� model, �� ������ �������� ������� tempdb ��� restart
	- ��� ���� ������� ��� ����������� � ������ �������� ����� ��� ����������� �����, ��������������� �����, ����� � ������������ CHECK ��� ������� ������. ���������� ������� ������� ��, � ����� ��������� ����� ������������� ������ �������. ��� ��� ������ ����� ����� ���� ��������� ������� � ���������.
	1. �������� �� ��
		alter database OLD_BASE collate Cyrillic_General_CI_AS
	2. �������� �� ���� ��������
		alter table Report alter column char_key char(5) collate Cyrillic_General_CI_AS
	3. ����� ������� View, ������� ����������� COLLATION �� ������ ���������� � ������
		create view View1 as select Col3, Col4 collate French_CI_AS as Col4 from 
	4. ����� ��������� �������������� COLLATION ����� ������ ������� � tempdb
	5. ����� ����� �� model �� ������� ���������� � ����� �� ������� � � ������ COLLATION � ������������ �� ������.
	
	-- You cannot change the collation of a column that is currently referenced by any one of the following:
		- A computed column
		- An index
		- Distribution statistics, either generated automatically or by the CREATE STATISTICS statement
		- A CHECK constraint
		- A FOREIGN KEY constraint
				
	-- ��������� ���������� ���������� �������	���� REBUILD (�������� �����, ��������)			
			-- ����� ������� �����
				1. ������������� SELECT * FROM sys.configurations;
				2. ������������� ������� ����������
					SELECT
					SERVERPROPERTY('ProductVersion ') AS ProductVersion,
					SERVERPROPERTY('ProductLevel') AS ProductLevel,
					SERVERPROPERTY('ResourceVersion') AS ResourceVersion,
					SERVERPROPERTY('ResourceLastUpdateDateTime') AS ResourceLastUpdateDateTime,
					SERVERPROPERTY('Collation') AS Collation;
				3. ��������������� ������� ������������ ���� ������ ������ � �������� ��� ��������� ��� ������.��� ������������ ��������� ��� ������ ��� ��������������� � �������� ������������.���� ��������� ����� ������ � �������� ���� ���������� � ������ ������������, ���������� ������� �� � �������� �����.
				
			-- ���� �����
				1. ��������� ������� ������ � ��������, ����������� ��� ���������� �������� ���������������� ���� ������ � ���� �� ��������.
				2. ������������� ��� ������ � ������� ������ ��������, ��� ��������� bcp.�������������� �������� ��. � ������� �������� ������ � ������� ������ (SQL Server).
				3. ����������� ������� master,msdb...
				4. ������� ��� ���������������� ���� ������.
				5. ����������� ���� ������ master, ����� ����� ��������� ���������� � �������� SQLCOLLATION ������� setup (�� ����� ������� � ������� ������). ��������:
					Setup /QUIET /ACTION=REBUILDDATABASE /INSTANCENAME=InstanceName /SQLSYSADMINACCOUNTS=accounts /[SAPWD= StrongPassword] /SQLCOLLATION=CollationName
				
			-- ����� �����
				1. ������������ ��������� ��������� ����� ��������� ��. ��� ���� ������������� � COLLATION, �� COLLATION tempdb ��������� �������
				2. ���������������, ��� ��� ����� ����� SQL Server ����� �� ����������� � ������ �� ������ � ���
				2. ��������� ���������� ������������� ����� -- � ���� ������ ��� �� ���������
					setup > Maintenance > Repair > Select instance > Repair
				3. ����������� ��������� �� � ������ �����
		
		- �������������� �������� ��. � ������� ������������ ��������� ��� ������ (https://msdn.microsoft.com/ru-ru/library/dd207003(v=sql.120).aspx).
		- �������� ��� ���� ������ � ��� �� �������.
		- ������������ ��� ������.
	
		-- ������ ������ (��������� ������, ��� ��� ������ ��� �������� � �����-�� ����)
			- ��������� COLLATION ��������� ��
			sqlservr -m -T4022 -T3659 -s"SQLEXP2014" -q"SQL_Latin1_General_CP1_CI_AI" 
	
-- ����� �������������� ����� � ������/implicit conversion
	
	-- ��� (�������������� ����� � �������)
	
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		SELECT TOP 50 SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
			((CASE qs.statement_end_offset
			WHEN -1 THEN DATALENGTH(qt.TEXT)
			ELSE qs.statement_end_offset
			END - qs.statement_start_offset)/2)+1),
			qs.execution_count,
			qs.total_elapsed_time/1000 total_elapsed_time_ms,
			qs.last_elapsed_time/1000 last_elapsed_time_ms,
			qs.max_elapsed_time/1000 max_elapsed_time_ms,
			qs.min_elapsed_time/1000 min_elapsed_time_ms,
			qs.max_worker_time/1000 max_worker_time_ms,
			qs.min_worker_time/1000 min_worker_time_ms,
			qs.last_worker_time/1000 last_worker_time_ms,
			qs.total_worker_time/1000 total_worker_time_ms,
			qs.total_logical_reads, qs.last_logical_reads,
			qs.total_logical_writes, qs.last_logical_writes,
			qs.last_execution_time,
			CAST(qp.query_plan as XML),
			--CAST(qp.query_plan as XML).value('(.//ScalarOperator/@ScalarString)[3]', 'varchar(8000)') ,
			qt.[objectid] -- �� ������� id ����� ��������� ��� �� ������ SELECT name FROM sys.objects WHERE [object_id] = 238623893
			,qp.dbid
			,qt.dbid
		FROM sys.dm_exec_query_stats qs
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
		CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
		WHERE last_execution_time > GETDATE()-1
		AND qp.query_plan.value('(.//@Expression)[1]', 'varchar(8000)') like '%CONVERT_IMPLICIT%'		
		--ORDER BY (qs.total_logical_reads + qs.total_logical_writes) / qs.execution_count  DESC-- ��-���������
		-- ORDER BY qs.total_logical_writes DESC -- logical writes
		--AND CAST(qp.query_plan as varchar(8000)) like '%Convert_impli%'
		ORDER BY qs.total_worker_time DESC -- CPU time
	
	-- ��� (��� ��������� �������������� �����)
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		SELECT TOP 30 SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
			((CASE qs.statement_end_offset
			WHEN -1 THEN DATALENGTH(qt.TEXT)
			ELSE qs.statement_end_offset
			END - qs.statement_start_offset)/2)+1),
			qs.execution_count,
			qs.total_elapsed_time/1000 total_elapsed_time_ms,
			qs.last_elapsed_time/1000 last_elapsed_time_ms,
			qs.max_elapsed_time/1000 max_elapsed_time_ms,
			qs.min_elapsed_time/1000 min_elapsed_time_ms,
			qs.max_worker_time/1000 max_worker_time_ms,
			qs.min_worker_time/1000 min_worker_time_ms,
			qs.last_worker_time/1000 last_worker_time_ms,
			qs.total_worker_time/1000 total_worker_time_ms,
			qs.total_logical_reads, qs.last_logical_reads,
			qs.total_logical_writes, qs.last_logical_writes,
			qs.total_elapsed_time/1000000 total_elapsed_time_in_S,
			qs.last_elapsed_time/1000000 last_elapsed_time_in_S,
			qs.last_execution_time,
			CAST(qp.query_plan as XML),
			--CAST(qp.query_plan as XML).value('(.//ScalarOperator/@ScalarString)[3]', 'varchar(8000)') ,
			qt.[objectid] -- �� ������� id ����� ��������� ��� �� ������ SELECT name FROM sys.objects WHERE [object_id] = 238623893
		FROM sys.dm_exec_query_stats qs
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
		CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
		WHERE last_execution_time > GETDATE()-1
		AND qp.query_plan.value('(.//@ScalarString)[2]', 'varchar(8000)') like '%CONVERT_IMPLICIT%'
		--ORDER BY (qs.total_logical_reads + qs.total_logical_writes) / qs.execution_count -- ��-���������
		-- ORDER BY qs.total_logical_writes DESC -- logical writes
		--AND CAST(qp.query_plan as varchar(8000)) like '%Convert_impli%'
		ORDER BY qs.total_worker_time DESC -- CPU time
		
		
	
	-- ������	
	-- ����������� ������� �������� �� �� ������

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @dbname SYSNAME 
	SET @dbname = QUOTENAME(DB_NAME());

	WITH XMLNAMESPACES 
	   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan') 
	SELECT 
	   stmt.value('(@StatementText)[1]', 'varchar(max)'), 
	   t.value('(ScalarOperator/Identifier/ColumnReference/@Schema)[1]', 'varchar(128)'), 
	   t.value('(ScalarOperator/Identifier/ColumnReference/@Table)[1]', 'varchar(128)'), 
	   t.value('(ScalarOperator/Identifier/ColumnReference/@Column)[1]', 'varchar(128)'), 
	   ic.DATA_TYPE AS ConvertFrom, 
	   ic.CHARACTER_MAXIMUM_LENGTH AS ConvertFromLength, 
	   t.value('(@DataType)[1]', 'varchar(128)') AS ConvertTo, 
	   t.value('(@Length)[1]', 'int') AS ConvertToLength, 
	   query_plan 
	FROM sys.dm_exec_cached_plans AS cp 
	CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
	CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS batch(stmt) 
	CROSS APPLY stmt.nodes('.//Convert[@Implicit="1"]') AS n(t) 
	JOIN INFORMATION_SCHEMA.COLUMNS AS ic 
	   ON QUOTENAME(ic.TABLE_SCHEMA) = t.value('(ScalarOperator/Identifier/ColumnReference/@Schema)[1]', 'varchar(128)') 
	   AND QUOTENAME(ic.TABLE_NAME) = t.value('(ScalarOperator/Identifier/ColumnReference/@Table)[1]', 'varchar(128)') 
	   AND ic.COLUMN_NAME = t.value('(ScalarOperator/Identifier/ColumnReference/@Column)[1]', 'varchar(128)') 
	WHERE t.exist('ScalarOperator/Identifier/ColumnReference[@Database=sql:variable("@dbname")][@Schema!="[sys]"]') = 1

		
-- ������
WHERE tt1.inc = tt2.Partner AND tt3.Dog = tt2.NDog COLLATE SQL_Latin1_General_CP1251_CI_AS

SELECT * FROM T1 AS t1 INNER JOIN T2 AS t2
ON t1.Name=t2.Name COLLATE [collation_name];
--
SELECT name COLLATE SQL_Latin1_General_CP1_CI_AS FROM testTable
--
SELECT * FROM T1
WHERE Name='sqlCMD' COLLATE [collation_name1] AND EmailAddress='SqLcMd' COLLATE [collation_name2]
--
SELECT * FROM T1
WHERE (Name COLLATE [collation_name1])='sqlCMD' AND EmailAddress='SqLcMd' COLLATE [collation_name2]
--
SELECT * FROM T1
WHERE Name COLLATE [collation_name1]='sqlCMD' COLLATE [collation_name2] AND EmailAddress='SqLcMd' COLLATE [collation_name3]
--
SELECT * FROM T1
ORDER BY Name COLLATE [collation_name]
--
SELECT * FROM T1
ORDER BY Name COLLATE [collation_name1], EmailAddress COLLATE [collation_name2]

-- UNICODE
	-- UTF
		- https://msdn.microsoft.com/ru-ru/library/bb330962.aspx
		- https://msdn.microsoft.com/ru-ru/library/ms143726.aspx?f=255&MSPPError=-2147217396
		- UTF-16 ������� � �������� ����������� ��������� � ���������� ����������, SQL Server �� �������� �����������
		- ���� ���������� ��������� ������ � ������ ���������, ��� ���� ������ ��������� ����������� �������������� (�������� � UTF-8)
		- ����� ������� ������ � UTF, ���������� ���������� �� � N'', ��� �� ����� �������� �� ���� �������� �� UTF, ���� ����������� c N''

	-- UCS-2.
		- ��� �������, SQL Server ������ ������� ������� � ������� ����� ����������� UCS-2 (https://msdn.microsoft.com/ru-ru/library/bb330962.aspx)
	
	-- � Html
		- XML-������ SQL Server 2005 �������� � ������� ������� (UTF-16).
		- ����� ����������� <?xml version="1.0" encoding="utf-8"?>
		
	-- UTF-8
		������ � ����� Windows �������� � ������� UTF-8 ����� ��������� �����������:
			- ���������� ������ COM, ������� API, ������������ ������ ��������� UTF-16/UCS-2. �������������, ���� ������ �������� � ������� UTF-8, ��������� �� ���������� ��������������. ��� �������� ����� �����, ������ ����� ������������ ������ COM, �� ������ ���� ���� ������ SQL Server � �� ����������� �� ����������.
			- ���� ������������ ������� ��� � Windows XP, ��� � � Windows Server 2003 ���������� ������. ��� Windows 2000, Windows XP � Windows Server 2003 � �������� ����������� ��������� ������������ UTF-16. ������ ��� ������������ ������� ���������� � UTF-8. ������� ������������� � �������� ������� �������� ������ ��������� UTF-8 ������� ��������� ������ ��������������. ������ ������ ������� ��������, ����������� ��� ����� ��������������, �� ������ �� ������ ���� ���� ������ SQL Server, �� ����� ������� ������� �� ������ ��������, ����������� �� ������� �������.
			- ������������� UTF-8 ����� ��������� � ���������� ������ �������� �� ��������. ����������, ��������� �, ����������, ����� ������ �������� �� ������� ����� �������� ��������� ��-�� ����, ��� ������� �� ����� ������������� ������.
			- ����� ��� ��������� UTF-8 ��������� ����� 2 ������, � ���������� ������� ����� ����� � ���������� ������������� ��������� ������������ � ������.
	
-- ������ COLLATE ����
SELECT DATABASEPROPERTYEX('ADMIN_SITE' , 'collation')