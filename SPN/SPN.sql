-- spn/Kerberos
	https://dbasimple.blogspot.ru/2015/04/spn-ms-sql-server.html
	https://mssqlwiki.com/2013/12/09/sql-server-connectivity-kerberos-authentication-and-sql-server-spn-service-principal-name-for-sql-server/
	
	SPN - ��� ������ ����������� ������� ������ Windows, ������������� �� ������ ���������� ������, � �������� � �������. ����� ������������� ����������, ��� ��� ������ ������� ��������� SPN �� ����� ���� � �����, � �������� ������������ ������. ��� �������� �������� ����������� Kerberos ������� ������������ Windows ������ ���������� ������� ������, ������� ���������� ������. ��������� ������������� SPN, ������������� � Active Directory (AD), ������� ������ Windows, ������������� �� ������, ����� ���� ������������ � ������������ ��� �������� ����������� Kerberos. �� ���� ������� ������ ������ ������������ ����� SPN; ��������, Microsoft SQL Server ������������ SPN, ���� ������������ �������� TCP/IP � ��������� ����������� Kerberos, ��� ��������� ���������� �� NTLM.

	��� ������ �� ���� Microsoft - https://msdn.microsoft.com/en-us/library/ms677949(v=vs.85).aspx
	
	-- ���� ����� ����� ��������
		dsacls "CN=sa_mssql-djin_msk,OU=Test&ServiceUsers,DC=msk,DC=rian" /G SELF:RPWP;�servicePrincipalName� -- OU - organization unit (��� ����� ������������)
		
		setspn -A MSSQLSvc/MSK-DB01-AXCLU.bk.local:1433 bk\sql
	setspn -A MSSQLSvc/MSK-DB01-AXCLU.bk.local:63818 bk\sql
	- ���� ��������� ���� � ������ �� �������, �� ����� ������ �����/������ ����� �� ������ ������ Write servicePrincipalName � Read servicePrincipalName
	- ���� ����� ��������� ������ 
		setspn -A MSSQLSvc/MSK-DB01-AXCLU.bk.local:63818 bk\hostname

-- ������ ����� �����
	1. ���������� Kerberos Configuration Manager
	2. ����� ������� ADSI
	
-- Errors/������
	https://blogs.technet.microsoft.com/askds/2008/06/13/understanding-kerberos-double-hop/