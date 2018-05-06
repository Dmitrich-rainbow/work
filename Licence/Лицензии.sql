-- ��������
	- ������ �������� �� ����������� �� Standart �� Enterprise. ����� ������ ������ ����� � ������� ���������
	- ������ ���� �� �����������
	- ����� ������������� ���� ������, �� ���� ��� ����������� ������, �� �� �� ���������� ����, ������� ����� ����������� ������
	- ����� � datasheet ������ F:\SQL Scripts\�����

-- SQL Server 2012
	1. Enterprise �� 2 ���� � ������� ������ CALL - 416 000. ������������� ������ ��������� ��� ���� �� �������
	   ,�� �� ����� ��� �� 4 ����. � ����������� ������ ������� �����.
	2. Standart �� 2 ���� � ������� ������ CALL - 108 600
	3. Standart �� ����� ���������� ����, �� � ������ - 27 000
	4. Call 1 �� - 6326

-- Standard
	1. WFCI �� 2 ����
	
-- CAL
	-- ���������� ���������� ���������
		SELECT Count(*) FROM
			(
			SELECT [host_name] as g
			FROM sys.dm_exec_connections eC 
					CROSS APPLY sys.dm_exec_sql_text (eC.most_recent_sql_handle) ST
					LEFT JOIN sys.dm_exec_sessions eS 
							ON eC.most_recent_session_id = eS.session_id
			WHERE [host_name] <> SUBSTRING(@@SERVERNAME,0,8)
			GROUP BY [host_name]
			) as t
			
-- ���������/Passive
	- https://www.mssqltips.com/sqlservertip/2942/understanding-the-sql-server-2012-licensing-model/
	- https://www.brentozar.com/archive/2014/04/sql-server-2014-licensing-changes/
	- https://social.msdn.microsoft.com/Forums/sqlserver/en-US/51bae798-0c68-4cfa-981d-da574e167dca/licensing-questions-for-mirroring-and-logshipping?forum=sqldisasterrecovery
	- ACTIVE -> PASSIVE configurations, such as mirrored configurations or active-passive cluster/failover configurations, do not require licenses on the mirror. Note this doesnt apply if you are using a combination of mirrored and active databases on your servers in the same instance. �� ������� � SQL Server 2014 ��� ������ ���� ����� ���������� �������� (SA)
	- The passive server can take the duties of the active server for 30 days
	- Note that you do NOT need an extra SQL Server license for the mirroring server
	- Log shipping, mirroring, and even failover clustering allowed for an unlicensed passive node, provided that the passive node didn�t become the primary for more than 28 days.
	- Log shipping, mirroring, and even failover clustering allowed for an unlicensed passive node, provided that the passive node didn�t become the primary for more than 28 days.
	
	-- ���� ��������� downgrade, �� ������� �������� ����������� �� ������ ������, � �����
	
-- ������ �������
	�� ������� ����������:
		1. 1 ���� rsnews-db1
		2. ������ ���� �����