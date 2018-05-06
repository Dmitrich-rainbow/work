-- ErrorLog	
	DECLARE @date datetime
	DECLARE @date2 datetime
	SET @date = GETDATE()-1;
	SET @date2 = GETDATE() +1 

	CREATE TABLE #LogCheck
	(dat datetime,
	info nvarchar(50),
	text nvarchar(4000))

	INSERT INTO #LogCheck
	exec xp_readerrorlog -1, 1, NULL, NULL, @date,@date2

	SELECT * FROM #LogCheck WHERE text NOT LIKE '%Login succeeded for user%' AND text NOT LIKE '%DBCC CHECKTABLE%' AND text not like '%transactions rolled forward in database%' AND text not like '%transactions rolled back in database%'
	AND text NOT LIKE '%Log was backed up%'

	DROP TABLE #LogCheck
	
-- xp_readerrorlog
	5) '20120401' - StartTime
	6) '20120401 18:00' - EndTime
	
-- Cluster error log
	WINDOWS Server 2005: %systemroot%\cluster\cluster.log
	Windows Server 2008: Cluster Console Manager > ������� ������ ������ � � ������ ����� > Show the critical events for this resource
	
-- ������ ������� � ������ ������/�������� ���/cut errorlog
	- ������ ����� ������ ������� sp_Cycle_ErrorLog 
	- ������ ����� ������ ������ sp_Cycle_Agent_ErrorLog
	
-- ���������� ������������ ������ Error log (������� � SQL Server 2012) + ������������ ���������� ������ Error log
	USE [master];
	GO
	-- Limit size of each file
	EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE',
	N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQLServer',
	N'ErrorLogSizeInKb', REG_DWORD, 1024;
	GO
	 
	-- Number of ErrorLog Files
	EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE',
	N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQLServer',
	N'NumErrorLogs', REG_DWORD, 8;
	GO 

-- ����� ������� ����� �� errorlog
	/*���� ��� ���������� ���������� ����� �� ErrorLog � ������� T-SQL, �� ����� ��������������� ��������� ��������.
	
	P.S. �������� ��������, ��� ���� ������ ����� ����������� ������������ ����� �, ��������, �� ������� ���������� � �������� ��� �������� ���������.*/
	
	-- ������ ������� ��� ErrorLog
	CREATE TABLE #error_log (d datetime,p nvarchar(50),t nvarchar(max))

	-- ��������� � ������� ������ �� ErrorLog
	INSERT INTO #error_log
	EXEC sp_readerrorlog

	-- ��������� ���������� (���������� "����")
	SELECT * FROM #error_log WHERE t not like '%Login failed for user%' and t not like '%Error: 18456%'