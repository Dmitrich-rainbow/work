- �� ����������� �����
- ��������� ������������� ��� Database Mail ���������. ���������� ������ ���� �������� ����������, ������ ������� ������
- ��������� SPN ��� ���� ������
	setspn -A MSSQLSvc/MSK-DB01-AXCLU.bk.local:1433 bk\sql
	setspn -A MSSQLSvc/MSK-DB01-AXCLU.bk.local:63818 bk\sql
	- ���� ��������� ���� � ������ �� ������, �� ����� ������ �����/������ ����� �� ������ ������ Write servicePrincipalName � Read servicePrincipalName
	- ���� ����� ��������� ������ 
		setspn -A MSSQLSvc/MSK-DB01-AXCLU.bk.local:63818 bk\hostname
	
	- ���� ������ ����� ��������
	dsacls "CN=sa_mssql-djin_msk,OU=Test&ServiceUsers,DC=msk,DC=rian" /G SELF:RPWP;�servicePrincipalName�

	
-https://msdn.microsoft.com/en-us/library/ms143702.aspx

������ 3 �����:
- ����� ������� ����� ����� �� �������� �� ������ � ����, �� � �����������
1. Data Root (������ ���� � ��������)
2. ���� ��� MSDTC
3. ��������� ��������� ����, �������� C:\, ������� �� � ��������

-- ���� ���������� ������ �������� ��������, �� � ����� ����������
	setup /SkipRules=Cluster_VerifyForErrors /Action=AddNode
	Setup /SkipRules=RebootRequiredCheck /Action=AddNode
	Setup /SkipRules=Cluster_VerifyForErrors /Action=InstallFailoverCluster
	Setup /SkipRules=RebootRequiredCheck /Action=InstallFailoverCluster	
	Setup /SkipRules=Cluster_VerifyForErrors /Action=CompleteFailoverCluster
	setup /SkipRules=RebootRequiredCheck /Action=RemoveNode
	setup /SkipRules=RebootRequiredCheck /Action=Install	
	setup /ACTION=editionupgrade /SkipRules= EditionUpgradeMatrixCheck -- ��������� ���������� �������� � ���������� ��������
	
	-- �� Windows Server 2012 ��������� ������� �� ����� SQL Server 2008 SP1
		http://blogs.msdn.com/b/petersad/archive/2011/07/13/how-to-slipstream-sql-server-2008-r2-and-a-sql-server-2008-r2-service-pack-1-sp1.aspx (��� ������� �� R2 > Sp1)

-- ������
	- ������ ��������� ���� � �������, ����� �� ������� ����������
	- E:\setup.exe /SkipRules=StandaloneInstall_HasClusteredOrPreparedInstanceCheck /Action=Install
	- http://blogs.msdn.com/b/sqlforum/archive/2011/04/19/forum-faq-why-do-i-get-rule-existing-clustered-or-clustered-prepared-instance-failed-error-while-adding-new-features-to-an-existing-instance-of-sql-server-failover-cluster.aspx
	- https://www.mssqltips.com/sqlservertip/2778/how-to-add-reporting-services-to-an-existing-sql-server-clustered-instance/

bk\sql JHG6ghK7tghj4as

MSDTC_CL
10

msk-db01-Temp

FH666-Y346V-7XFQ3-V69JM-RHW28


msk-db01-Temp$DBAXCL

net start MSSQL$DBAXCL /c /m --/T3608

RESTORE DATABASE master FROM DISK = 'J:\R10_01_msk-db01_AxDB_01\master.bak' WITH REPLACE




-- Tempdb 
- ����� ����������� ������ �� ������ ������� ������
	SELECT * FROM sys.master_files (������� ����� ��������)
	ALTER DATABASE tempdb REMOVE FILE tempdev2; (������� ������)
net start MSSQL$DBAXCL /f /c

sqlcmd -S msk-db01-Temp\DBAXCL 

use master
GO
ALTER DATABASE tempdb MODIFY FILE
(name = tempdev1, filename = N'J:\R10_01_msk-db01_TempDB_01\Data\tempdev1.mdf', SIZE = 100 Mb)
GO

use master
GO
ALTER DATABASE tempdb MODIFY FILE
(name = templog, filename = N'J:\R10_01_msk-db01_TempLogs\Logs\templog.ldf', SIZE = 100 Mb)
GO


-- �������� ����
	- ��������� online ����� � ���������� ��
	- ��� ������������� ������ ����������� ip �� �����,����� �� ���� �� �������
	- ������ ����� �� ����� �������� � online �� ���������
	
	- *** ��������� �������� ���� ��� �������� ��������, ��� ��� ��� ���� �������� ���� ������ ������ � �� ��������
	
-- ������
	- ���� ����� �������� �������, �� ����� ������� ��� �� (���, ip...), ���������� � ���� Template SQL Server � SQL Server Agent, ��������� ����������� � ����� ��������. ������������� �� �����������


-- ������ ����������� �������