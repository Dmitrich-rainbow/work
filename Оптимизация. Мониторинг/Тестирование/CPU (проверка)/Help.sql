-- ���������
	-- https://blogs.msdn.microsoft.com/sqlcat/2016/09/29/sqlsweet16-episode-8-how-sql-server-2016-cumulative-update-2-cu2-can-improve-performance-of-highly-concurrent-workloads/
	1. ���������� adksetup.exe (����� ������� �� ����� Windows ADK � ������� � ����������� Windows Performance Toolkit)
	2. ��������� cmd � ������ ���� ����������:	
		xperf -On Base
	3. ���������� ���� � ������������ ����� � �����:
		xperf -d c:\temp\highcpu.etl
	4. ������� ��������� ����� ����� "Windows Performance Analyser"
	5. ����� � ������ CPU > �������� ��� ���������