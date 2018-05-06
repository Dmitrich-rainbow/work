-- 
	- https://technet.microsoft.com/en-us/library/dd537533%28v=sql.100%29.aspx?f=255&MSPPError=-2147217396
	- https://technet.microsoft.com/en-us/library/dd425070(v=sql.100).aspx
	- BULK INSERT
	- SSIS
	- https://orderbyselectnull.com/2017/08/16/the-trillion-row-table/
	- ���� � ������ ������� �������, ������� ���������� -- ������ ������
	
	
	
	
������ ����� �������� ����������� ����������������. �������� ������� � ���� ����� 70 ��.  ��� ������ ����� � tablockx � T610 8 ���. ��� � ������� 25 ���.

������ �� �������� ������ �� ������ � ������ ������� ����������, � ����� �������� � ����. �.�. ��� tablockx �������� ������ ������ 1 �����. �� ��������� ���������� �� ����� � ��������� �������������� ������� ����� ���� ����������, ���� ����������. � ����������� �� ������ � ��������.



1 ������� (��������� ���������� ������ �� ������� �����):
DBCC SHRINKFILE (Test1data, EMPTYFILE);
2. 
-- ������� ����� �������� ������
-- ������� ����� ndf
-- ��������� ��� ������ ������
-- ��������� ������� ����������� ������� ndf-����
3. ������� Rebuld ��������� ��������� ������ �� ������
4. �������� � �������� �������

-- ����������� ������� �� �������� ������� 
	1. https://gallery.technet.microsoft.com/scriptcenter/c1da9334-2885-468c-a374-775da60f256f
	2. ������������ ����������� �������
	3. ���� ��� heap, �� ���������� �������/������� ���������� ������

-- ������������� ������������� ������
	- ��� ������� �� ���������� ������������ � ������ ������, ��� ��� ������, ��� ������ ������ �� ���������� � ������ �����
	
-- ���������� ������� ������ � ������ �� (SQL Server 2012, ����� �������� ��� ������� ������ ���������� ����� � ��������� � ������� ������ SHRINK)
	select
	db_name()           AS [DatabaseName],
	s.name              AS [DB_File_Name],
	s.physical_name     AS [FileName],
	s.size * CONVERT(float,8) AS [TotalSize],
	CAST(CASE s.type WHEN 2
			THEN s.size * CONVERT(float,8)
			ELSE dfs.allocated_extent_page_count*convert(float,8)
		END AS float)   AS [UsedSpace],
	CASE s.type WHEN 2
		THEN 0
		ELSE s.size * CONVERT(float,8) - dfs.allocated_extent_page_count*convert(float,8)
	END                 AS [AvailableFreeSpace]
	from sys.database_files AS s
	left outer join sys.dm_db_file_space_usage as dfs
	ON dfs.database_id = db_id()
	AND dfs.file_id = s.file_id
	where (s.drop_lsn IS NULL)
	
	
---   ������ ��������� ������������ � ������ ���� ������ ����� ���������� (�������� �� ���� ������� SQL)
	SELECT
		 name AS 'LogicalName'
		,physical_name AS 'PhysicalName'
		,CONVERT(INT,ROUND(size/128,0)) AS 'Size (MB)'
		,CONVERT(INT,ROUND(FILEPROPERTY(name,'SpaceUsed')/128,0)) AS 'SpaceUsed (MB)'
	FROM sys.database_files
	WHERE type = 0;
	
-- ������������� ������ �� ������ �� (������)
		SELECT DB_NAME(saf.database_id) AS [���� ������]
		, saf.name AS [���������� ���]
		, vfs.BytesWritten/1048576 AS [�������� (��)]
		, vfs.BytesOnDisk/1048576 AS [������ ��(M�)]
		, saf.physical_name AS [���� � �����]
		, 100*(vfs.BytesWritten/1048576)/(SELECT SUM(BytesWritten/1048576)
		FROM fn_virtualfilestats(NULL,NULL) AS vfs1
		WHERE vfs1.dbid = saf.database_id
		AND vfs1.fileid <> 2) AS '%'
		FROM sys.master_files AS saf
		JOIN fn_virtualfilestats(DB_ID(),NULL) AS vfs ON vfs.dbid = saf.database_id
		AND vfs.fileid = saf.file_id
		--AND saf.database_id NOT IN (1,3,4)
		AND saf.type < 2
		AND saf.file_id <> 2
		AND DB_NAME(saf.database_id) = DB_NAME()
		ORDER BY BytesWritten/1048576 DESC