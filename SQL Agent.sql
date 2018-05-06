-- name from hex
	select * from msdb..sysjobs
	where job_id = 0x1292021D3C929A4CBBE3895A61FA68CC 

-- ���������� ���� ��������� SQL Agent
select subsystem, subsystem_dll, agent_exe
from msdb.dbo.syssubsystems

-- �������� ����� �������� ������ ������ ��� SQL Agent
EXEC sp_configure 'allow updates', 1
reconfigure with override
GO

update msdb.dbo.syssubsystems
set subsystem_dll= replace(subsystem_dll,'MSSQL10_50.ONLINE','MSSQL10_50.MSSQLSERVER') -- MSSQL10_50.ONLINE(��� ������), MSSQL10_50.MSSQLSERVER(�� ��� ������)
FROM msdb.dbo.syssubsystems
where subsystem_dll like '%MSSQL10_50.ONLINE%'

EXEC sp_configure 'allow updates', 0
reconfigure with override
GO

-- �����
	1. SQL Mail(����������), �������� �� 2005, �� ���� ������������. ���������� Transport MAPI. ��������� xp_sendmail (6 ����� 3:50). ������ ����� ����� ��������, ����� ������� � ����� ���� ����� ������������� SQL Server. ����� ���������� � ������ �����. ��� ���� ����������� ������ ������ MAPI Client(���������� ���������� Outlook). ��������� ��������� � Managment > Legacy > SQL Mail
	2. Database Mail. ���������� SMTP. ��������� xp_sendDBmail. ����� ����� ������ ����������. ��������� ��������� � Managment > SQL Server Logs > Database Mail
	����� �������� � ������ �����, ���� ����� � ��� ��������� > Alert System > Enable mail profiler
	����� ����� �� ������� ��������� SQL Agent > Operators, ���� �� �������, �� � ���������� ���� ���������.

- ���� ���� �������� � ��������� �����, �� ����� ������������� ������, ���� �� ��������, �� ������������� �������
  "Enable mail profiler"