-- Main
	- � SQL Server 2012 ����� ��������� ���� ��������� ����
	
	-- ���������� � �� ������������ �������������
		- ���������� ����������� ��� Azure

-- ���������� ��������� �����
		- SQL Serveer 2014
		- ������ ��������
		
		-- ����������
			1. Tasks > Backup > Media Options > ������� "backup to a new media set,..." > Backup Options > ������� "Encryption backup"
			2. ������� ������������� ����/certificate � master, �� ������� ���� ������� master key
			3. ������ backup certificate � master key
				Backup CERTIFICATE forBackup
				TO FILE = 'C:\Key1.txt'
				WITH PRIVATE KEY (
				FILE = 'C:\Key2.txt'
				ENCRYPTION BY PASSWORD = 'Pa$$w0rd'
				)
			4. ����� ������������ ������ �� �� ������ �������
				CREATE MASTER KEY 
				ENCRYPTION BY PASSWORD = 'Pa$$w0rd'
				
				CREATE CERTIFICATE forBackup
				FROM FILE = 'C:\Key1.txt'
				WITH PRIVATE KEY (
				FILE = 'C:\Key2.txt'
				DECRYPTION BY PASSWORD = 'Pa$$w0rd'
				)