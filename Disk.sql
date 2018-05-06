-- ������������ ��������� NTFS � ������ RAID �������
	-- ���������� ������� ������
		- wmic partition get BlockSize, StartingOffset, Name, Index
		- fsutil fsinfo ntfsinfo d:
		
	-- ��������� ����������
		- ��� ������ ����� �������
		
		1. ������ ���� � ������ �������� �����
		2. DISKPART
		3: CREATE PARTITION PRIMARY ALIGN=64

-- ������ � ����� ����� cmd/���������� ������
	net use - ���������� ��� ��������� ����������� net use
	net use /delete \\10.0.1.1\backup - ������� ����
	net use \\10.0.1.1\backup Cgfyx,j,2012 /user:admuser - ������� ����������� �� net use
	exec xp_cmdshell 'net use B: \\10.0.1.1\backup Cgfyx,j,2012 /user:admuser /persistent:yes' - ������� ����, ������� ������ SQL

	-- ��� ������ ������������ ����� � ���������� �������
	sp_configure 'show advanced options', 1;
	GO
	RECONFIGURE;
	GO
	sp_configure 'Ole Automation Procedures', 1;
	GO
	RECONFIGURE;
	GO
	-- �������� ��������� ������� #drives �� ����� ������� �������
	SET NOCOUNT ON
	DECLARE @hr int
	DECLARE @fso int
	DECLARE @drive char(1)
	DECLARE @odrive int
	DECLARE @TotalSize varchar(20) DECLARE @MB Numeric ; SET @MB = 1048576
	CREATE TABLE #drives (drive char(1) PRIMARY KEY, FreeSpace int NULL,
	TotalSize int NULL) INSERT #drives(drive,FreeSpace) EXEC
	master.dbo.xp_fixeddrives EXEC @hr=sp_OACreate
	'Scripting.FileSystemObject',@fso OUT IF @hr <> 0 EXEC sp_OAGetErrorInfo
	@fso
	DECLARE dcur CURSOR LOCAL FAST_FORWARD
	FOR SELECT drive from #drives ORDER by drive
	OPEN dcur FETCH NEXT FROM dcur INTO @drive
	WHILE @@FETCH_STATUS=0
	BEGIN
	EXEC @hr = sp_OAMethod @fso,'GetDrive', @odrive OUT, @drive
	IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso EXEC @hr =
	sp_OAGetProperty
	@odrive,'TotalSize', @TotalSize OUT IF @hr <> 0 EXEC sp_OAGetErrorInfo
	@odrive UPDATE #drives SET TotalSize=@TotalSize/@MB WHERE
	drive=@drive FETCH NEXT FROM dcur INTO @drive
	End
	Close dcur
	DEALLOCATE dcur
	EXEC @hr=sp_OADestroy @fso IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso

	-- ��������� ���� �� �����, � ����� ������� � �������� �����
	if EXISTS (SELECT * FROM #drives WHERE FreeSpace < 10000)
	BEGIN 
	DECLARE @a nvarchar(Max); 
	SET @a = '������ ������� ����� ������ ������������. �� ���������� ����� 10 Gb. ���������� ���� - ';
	DECLARE @c nvarchar(50); 
	DECLARE cursor2 CURSOR FOR
	SELECT drive FROM #drives WHERE FreeSpace < 10000
	OPEN cursor2;
	FETCH NEXT FROM cursor2
	INTO @c;
	WHILE @@FETCH_STATUS = 0
	BEGIN

	SET @a = @a+@c;

	FETCH NEXT FROM cursor2
	INTO @c;
	END
	CLOSE cursor2;
	DEALLOCATE cursor2;

	EXEC msdb.dbo.sp_send_dbmail
		@recipients = 'DZaytsev@arttour.ru',
		@body = @a,
		@subject = '������������� ������ ����'
	END 
	 
	DROP TABLE #drives


-- SQLIO (http://blogs.msmvps.com/gladchenko/2009/06/09/sqlio/#more-66)
	- ��������� �����
		sqlio -dC -BH -kW -frandom -t1 -o1 -s60 -b64 testfile.dat -- write random
		sqlio -dC (����) -BH (���������� �����������) -kR  (����������� �������� ������)-fsequential -t1 (���������� �������) -o1 (���������� �������� � ����� ������) -s60 (��� ����� �����������) -b64 (������ �����) testfile.dat > myTest.log (����� ���������� ����������) --read sequential
		sqlio -kR -s300 -b64 -f1 -i2000000 -o1 -t1 -R1 -LP -a0xf �BN
		sqlio -kR -s300 -b64 -f1 -i2000000 -o1 -t1 -R1 -LP -a0xf -BN > R01-b64-f1-i2000000-o1-t1.log timeout /T 30 sqlio -kW -s300 -b64 -f1 -i2000000 -o1 -t1 -R1 -LP -a0xf -BN > W01-b64-f1-i2000000-o1-t1.log timeout /T 30 sqlio -kR -s300 -b64 -f1 -i2000000 -o1 -t1 -R2 -LP -a0xf -BN > R02-b64-f1-i2000000-o1-t1.log timeout /T 30 sqlio -kW -s300 -b64 -f1 -i2000000 -o1 -t1 -R2 -LP -a0xf -BN > W02-b64-f1-i2000000-o1-t1.log timeout /T 30 �� sqlio -kR -s300 -b64 -f1 -i2000000 -o1 -t1 -R13 -LP -a0xf -BN > R13-b64-f1-i2000000-o1-t1.log timeout /T 30 sqlio -kW -s300 -b64 -f1 -i2000000 -o1 -t1 -R13 -LP -a0xf -BN > W13-b64-f1-i2000000-o1-t1.log timeout /T 30 sqlio -kR -s300 -b64 -f1 -i2000000 -o1 -t1 -R14 -LP -a0xf -BN > R14-b64-f1-i2000000-o1-t1.log timeout /T 30 sqlio -kW -s300 -b64 -f1 -i2000000 -o1 -t1 -R14 -LP -a0xf -BN > W14-b64-f1-i2000000-o1-t1.log
		
	- ����� ������� ���� ������������ �� ������ ���� � ������ ��� ��������� ����������:
	
		sqlio -kR -s180 -b64 -f1 -i2000000 -o1 -t1 -R2,3 -LP -a0xf -BN > R23-b64-f1-i2000000-o1-t1.log timeout /T 30 sqlio -kW -s180 -b64 -f1 -i2000000 -o1 -t1 -R2,3 -LP -a0xf -BN > W23-b64-f1-i2000000-o1-t1.log timeout /T 30
		
	- ����� ������������:
		1. ����������. �����, ����� �� ������������� �������� ���������� ���� �� ���� ������, ����� ��������� ���������, �����, ��� ����� �������� � �������� �������� ������ �� ���� ��� ������������ � ����� ��������� �����������.  �������� ����������� ������ ���������������� �������� ����� ���������� ������������, ������� ����������� ���� ��� ����� ������������ ������� (����� ������� ������).
		2. ���������� ������. �������������� �������� ������� � ������ � ������� SQLIOSim. ��� ��� ��������:			
			- � ������� ������������ � �������� ������������ ������������������ ������, ������������� ��� ����� ����� ��� 14 �������� RAID0, ������ �� ������� ������ �������� �� ������ �����, ������ ������� ������� ���������� ������ ����� ���������� ������� �����, ������ ����� �������������� �������� (������ ��������) �������� ������ 64��, �������� ����������� ������ ��������� ����������� ������ � ������. � ��������� ������������ �������� �������� ����� ������� �������� ����� ���� ��������� ����������� ���������������� ����������. ����� ��������� ��������������� ��� ������� ������������ ��������, ��������, ��� ��� ������ ���������� ���������� ������ ����� � 128��, � ��� �������� ������������ ������ 256��. � ���� ������� ������� ������� ��������������� �������� ��������.
			- � ������� �������� ���������� �������, �������� � ������ mmc-������� ���������� �����������, � ��������� ������� DISKPART ���������� ������� ��� ������� ����������� ����� ����� RAW-������ (��� �������������� NTFS) ��������� �� ���� ����, � ��� ���������� ����� ����� (����� ����������� �����, �� ��� �� �����������, � ���� ��, ���� � �������� ����� ��������� ������ ����� ������). ������� ����� (����� ���� ��������) ����� ������������� �������������� ��������� � ��������� Online, � �������������� � GPT (GUID Partition Table). ��� ������������ ���������� �������� �� ���� MBR ����������� ��������� ������� DISKPART:

			SELECT DISK=1 

			CREATE PARTITION PRIMARY ALIGN=128 

			- � ���� ������� ������ ���� 1 � �������� ����������� � 128��. ����� �������� ������� �� ������� ��������. 
			- ���������� ��������� SQLIO. ����� �� ������ ��������� ������ �������������� ��������� sqlio.exe ������� ���������: C:\SQLIO\ sqlio.exe
			- ����������� ��������� ����, ������� ����� ��������� ��������� sqlio.exe � ������ ������� ��� ������� ����� � ��������� ���������� � �����. ������ ���������� ����� ����� ����� � ���������� 1.
			- ��������� ��������� ���� �� ����������, � ����� ������� ��������� � ����� ���������� � ����� �������, ��� ����������� ��������� � �������.
		3. ��������������� ������. ����, ����� ���������� ��������� ������������ ����� ����������� ���� ��� ����������, �� ������ �������, ������� ������ ���������� �������� � ���� ������.
		4. ����� ������� ��������. ��� �������� ������������ 64 ��
			�������� �������� |	������:	��������� / ���������������� | �����������:	������ / ������ | ������ ������� �����-������
			������ ���������� OLTP�������	����������������	������	512 � � 64 ��
			����� ������OLTP�������	���������	������ � ������	8 ��
			�������� �������	����������������	������	�� 8 �� �� 256 ��
			����������� ������, �������� �������	����������������	������	�� 8 �� �� 256 ��
			��������� �����������	����������������	������ / ������	1 ��
			���������� ������	����������������	������	�� 128 �� �� 2 ��
			�������������� �� �����	����������������	������ / ������	64 ��
			����������� �����	����������������	������	�� 8 �� �� 128 ��
			CREATE DATABASE	����������������	������	512 ��
			CHECKDB	����������������	������	8 �� � 64 ��
			DBREINDEX	����������������	������ / ������	������: �� 8 �� �� 256 �� ������: �� 8 �� �� 128 ��
			SHOWCONTIG	����������������	������	8 K� � 64 ��
					
	-k<R|W>
	� ������� ������������ �������� ��������������� ���������. ����� ����� �������, ������� �������� -k, ������� ����������, ����� �� �� ���� ���� ������������� ������ (R) ��� ������ (W). ������ ��� ������� ����� �.�. ����� ����������� ������, � ������ ���� - ������. �� ��������� ����������� -kR.

	-s<secs>
	������ ���������� -s �������� ����������������� ������������, ����������� � ��������. ������, ����������� �����, ����� ��������� � ���������� ���������� �����������������, ������� 360 ������. ��� ������� ��� ������������ � ���, �� ����� ���������� ��� ����� ��������������� � ���������� ������, ��� ������� ����������������� ����� ���� ����������� ���������. �� ���������, ����������� �������� -s30.

	-f<stripe factor>
	������ �������� -f ���������� ��� I/O (stripe factor), ������� ����� ���� ��������� (random) ��� ���������������� (sequential). �� ��������� ����������� �������� -f64. �������� ����� ��� ������������� I/O ������ ��������, � ���������� ����� ������ ����� ���������������� I/O. ��������, ��� ������������� ��������, �������������� � ������� Windows NT � �������� 64 ��, ����� �������� ��� -f ������ 32 (��� 2 �� ������), � � �� �� �����, ��� ������������� ��������� �������������� �������� ����������� �������� ��������, �������� � 128 ��, ��� ��������� -f ����� ������� �������� 64 (��� 2 �� ������). �������� ��������, ��� ������ ������� � SQLIO ������� � �� �������� ��������� -f � �� ������� I/O (���������� ���������� ������� ����� -b). ��� ������������� �������� -f1, ����������� ������ ���������������� I/O.
	� �������� ������������ �������� ������� �������, ����� ���������� ��������, ���: -frandom - ����� ����� � ����� ���������� ������������, ��� -fsequential - ����� ��������� (����������) ���� ���������� ����� ����������� I/O � ��� �� ����� �����.
	������, ������� ������ ����� ������, ����� �������� ������, ������� ����������� � ���, ��� stripe factor �� ������ ���� ������ ���������� ����� �������. �������, ��� ����������������� I/O (-f1) ����� ���� ����� ������ ���� �����, � � ������ ��������� ���������� ����� -f � -t �������� ��������� ����� ���������������� I/O, ��� ��� ������ ����� ����� �������� � I/O �� ����� �����, ������� �������� ���� ������. ������, ��������� ��� �������������� �������, �� ����� � �������������� ������������� ������ � ������ ������� - ����������������� I/O ���� �� ���������.

	-o<#outstanding>
	�������� ���������� -o ������� ���������� ������������ � ����� ������ �������� �� I/O. ���������� ������� ������� �������� ����� �������� � ����� ������� ����� ������������������, �� �� ����� ���� ������ ����������, �.�. ������� �� ������ ��������� ���� ������ ������ ������� ����� ��������, ����� �������� ��������� ���� ������� ������. �������� ����� �������������� ���������� �������� 8, 32 � 64. ������� �������� �� I/O ����� ����������� ���������� ��� ������� ������ �, ��������������, ����� � ��������� ���������� I/O, �� ������� ����, ��� ��� ����������� � ��������� ���������� ������ � SQL Server. ��� �������� ������ ������������ ��������� � ���������� -m (����������� �����), ������ ��� ������������ ������� Windows NT �� ������������ ������������� ���������� I/O ������������ Scatter/Gather.
	����� ������ ��������� �������� �� ����-����� � ����� ������, ����� ������ ����� ����� ���������� ����������� ����� ��� ��, ��� ���� �� �������� -o �� ��� �����. �������� ������� ������ � ���, ��� ������ ������� �� I/O ������ ����������� ��� ���������� �� ��� ����.
	���� �������� -o ��������������, I/O ���������������� ����������, � ������ ����� I/O ������� ���������� I/O (������������ GetOverlappedResult). ��� ����, ���� ����������� ��������� ������, I/O ����������� ��� ������� ����� ���, ��� �� �� ���� ���������� �������� �� I/O ����� ������� ����� ������. ��� ������������� ��������� -o ������� ��� �� "�����������".

	-b<io size(KB)>
	��������� �� ������� ���������� ������ -b, ������� ����� ������ ����� I/O, ���������� � ������. � ������������ ������������ ��� ������� ��������� ��������: 8, 64, 128, 256. �� ��������� ����������� �������� -b2.

	-L<[S|P][i|]>
	��������� �������� � ���������� ���� ������� ��� -LS (S = system, P = processor), ������� �������� �������� �������� �� �������� ��������� ���������� �� �������� ����������. ��� ���� �������� ����������, �.�. ��� ��������� ������������������ ������ ������� ����������, ������� �������� ����� ����������������. � ���� ���������� ����� ������������ ��� ��������� �������, ������� � ���������� (-LP ����� ������������ ������ � ����������� i386). �������� ��������, ��� �������� -LP ����� � ������������� ������������ �� SMP ��������, �.�. ��������� � ������� ���������� ���������� ������ ��� ��������� I/O �� ���� �� ���������� (���� �� ����������� �������� ����������), ��� ����� �������� � ������� �������������. ����� �������� �������� �� ��, ��� ���� �������� -LS ������� ������� SMP �������, �� ���� �� ������ ������ ������, � �������, ��� ���� ����� ����������� �� �� �����������, ��� � ��� -LP. � ������ ���� �������� ������� �����������, ������� � ������������ ����� ���������� ���������� ������� �� I/O, � �������� ����������� ������������� ������� ��������. ������ ������ ����������� (ms) ���������� ����� �� 0 �� 23 �����������, � �� ��� ��������� ����� ��������, ����� ���������� � �������� 24+. ������ ������ (%) ���������� ������� ������������� �������� �� I/O ��� ������������� ���� ����� ��������.
	� ���������� � S ��� P ����� ��������� ������ i ������� ��������� �������� �� ����� �������� ������� ������� �� ������������� ������� �� I/O.

	-F<paramfile>
	��������� �� ���������� ���������� -F ���������� ��� �����, � ������� ����������� ����� � ��������� �������� ��������� ����� ������ � ������� ����� �������� �� ����� ����� SQLIO. � ����� ������� � � �������, ���������� � ������������ � �������, ������������ ���� � ������ "param.txt", ������� ������ ������������� ��� ��, ��� ����������� ���� �������. � ����� ����� ���� ������� ��������� ������ �� ���� ���������� �������� ������ ��� �� ��������� LUN, ������� ������ ���� ����������� ���������������, ������ �� ����� ������. ����� ������� �������� ���� � ����� � ��� �����, ����������� ��� ��� ���������, ������������ ������� ����� � ��, ����� ����� ������� � ����������� ����� ������������� �������� ��� ������ � ������ �� ���� ������. ���� ����������� ��������� � ������������ � ������� ������ ����������� ����� param.txt:

	c:\sqlio_test.dat 4 0x0 100
	d:\sqlio_test. dat 4 0x0 100

	������ �� ��������� ���� � ����� ����� (��� LUN), ����������� ����� �������, ����������� �������� ��� ����� �����. ������������� ������������� ��� �������� ������ ����� ������������� � ������� �����������. � ��������� �� ������ ��������� ���� ������ ������ ������� ���� ������������� �������� ��� ������������� �������� ����������� ����� ������� �� ���� ������. � ������ �������, ����� ��������� ���������� ����� ������� �� ������ ��������, ����� ������ �����������.
	������ �� ������ �������, ����������� ����� ������������� ����� �����������. ��� �������� ���������� ����, ������� ����������� � ���������������� ���������� SQL Server. ��� ������ ���� ����������� ����� ������� ����� � ����� ����: 0x0.
	����� ����� ����������� ������ ����� �������� ������ � ����������. � ������, �� ������ � ��������� ��� ��������� ������ ���� ����������� ��������� �������, �� ������� ���� ���� �������������. � ������������ ������������� ������ ��� � ��� - ������ ���� ������ ����.
	����� ������� �����, ����� ������� �����������, ������� ������ ���� � ����� ������, ����� ������� �������� "*".
	��� ������� (�� ������������� �� RAW �������) ������, ����� �������������� ��������� ������ �����, ���� �� ������ �� ������ � ����� ����������.
	����� ������ �� ������ ��������� 256 ��������.

	����� ��� �������������, ���� � ������ ���������:

	-i<#IOs/run>
	���������, ������� �������� �� I/O ����� ��������, �� ��������� ����������� -i64. #IOs/run - ��� �������� ���� ���������, � ������� �������� �������� ����� �������� �� I/O ����� ���������, ������� ��� ������� ���������� ������� �� I/O ���� ������ � �����; ��������� ������ ������� ��������� ������ - ����. ������ ����� ������ ��� ����� � ������ �����, � ����� �������� � ������ ������� ��������������� ����� �������. � ��������� � ����������� -f � -b, ���� �������� ��������� ������ ������ � ������ ������� ��������, ������� ����� ���� ����� ��� ����, ����� ��������� ������� ���������� ������������ (��������, ���� ������� �������� �� ��������� -i64 -f64 -b2 - �������� �������� 8 ��). �������� ��������, ��� ������ � -i ������������ ������������ -frandom ��� -fsequential.

	SQLIO ����� ������������ ����� ������� �������� �������� ���������� ��������� I/O �� ������, ������ ��� �������� �� ��������� ������ ������� � 128 �� ����� ������ ������������ �������� �����������. �������, ����� �������������������� � ����������� -i � -f , �������� ����� �� ��������, ������� ������������� �� ����������� ����������.

	-t<threads>
	����� ����� ������������ � ����� �������, ������������ �������� - 256, �� ��������� ����������� �������� -t1. SQLIO ������������ ���������� ����� ����� � ���� ���������� �������, ��� ������ ����� ������������ ���������� -b, � ������� ������� ����� ���������� ���������������, � ����� ������ ������ ������������ ���������� -f (�� ��������� - 64), � ����� ����� ������������ ���������� -i (�� ��������� - 64). ���� ������ ��� ������ (-t2), �� ������ ����� ������ ������ �������� ������� ������ ������, � �� ����� ��� ������ ����� �������� � �������� �������.

	-d<drive1> .. <driveN>
	����� ����� ������ ��� ���������� ������, �� ������� ������� ������� ����� ������ (� ���� ������ ����� ���������� ���). ������������ ��� ����, ����� ������� �������� �� �������� ����, ��� ��� ����������� ���������� ����������� ������. ��������, �������: "sqlio -dDEF \test" ����� ����������� I/O �� ���� ������: D:\test, E:\test � F:\test. ������������ ����� ����� ������ - 256.

	-R<drive1>, <driveN>
	��� �������� ����� (RAW) �������� ���������� ������ ������, ��� ������� ����� ��������� ������� ������ ��� �� ������. ��� �������� ������ ������ � ����� ����������, ���������� � ������ ������ ��� � �� ������� ��������� ��������� ":", � ����������� �������� ����� ����� ������ ��������� ��� �������������. ��������, �������: "sqlio -RD,E,F,1,2,3", ������� ����� ������ ��� ������������ I/O �� ��������� RAW-��������: D:, E: � F:, � ����� ������ � ��������: 1:, 2: � 3: (��� �� ����� ����� ���� �� ������������ � ����� � ����������� �� �����������, ������ ��, ���: D: E: F: 1: 2: 3:). ������������ ����� ���������� ����� ������� ������ ���� �� ������ ��������� 256. ��� ������ �� RAW ��������, ������ ������ ������ ���� ��������� � ����� ����������.

	-p[I]<cpu affinity>
	���������� ����� ������ �� �����������, ������� ����� �������������� (0 - ������ �� �������; I - ��������� ������������). ���������� ��� ������ �������� sqlio ����������� �� ��������� ����������. ��������, ���� ������� 0, ����� �������������� ������ ���������, ���� ������� 1, ����� ������, � �.�. ������: 0, 1, 2 ��� 3 ����� �������������� ��� 4-� ������������� SMP �������. � ���������� � �������, � ����� �� ������������, ����� �������� ������ "I", ������� �������� ����� ��������� �������� � ����������, � ������� �� ������������� �� ��������� ������ ������� ��������.

	-a[R[I]]<cpu mask> 
	����� ����� ������������ �������� �������� SQLIO ����������� (R = ����������� �������� ������������� ����������� (I = ��������� ������������)). �� ������, �������� ����� ��������� ���������� ��������� ������������ SQL Server - affinity mask. �� ���������� �� ������������� ��������� -p ���, ��� ��������� ������������ ��� �������� ������������� � ����� ������ ������ ����������. ����� ������ ������������ � ����� ����������� ����� ��������� ���������� ��� ����������������� ������ � ��� �������� ����� ��������� � �������� ����� ����������� ��� ������� ������ SQLIO. ���� � ��������� -a �������� R, �� ����� �������������� ����� ����������� �����������. � ���� ������, ����� ����� �������� ����� �����������, ������� ������� ����� ������� ������ N. � ����� ������, 1/N ����� �� �������� ������� ����� �������� �� ������ �� ��������� �����������. ��������, ���� ������� � ����������: -a0xf -t16, �� ��� 16 ������� �������� SQLIO ����� ����������� �� ������ ������ ����������� (� 8-� ������������ �������). ���� �� ������: -aR0xf -t16, ����� ������ 1,5,9,13 ����� �������� �� ���������� 0, ������ 2,6,10,14 �� ���������� 1, ������ 3,7,11,15 �� ���������� 2, � ������ 4,8,12,16 �� ���������� 3. ���� � -aR �������� ������ "I", ��������� ����� ��������� �������� � ����������, ������� ������� ������������ �� ��������� ������ ������� ��������.

	-m<[C|S]><#sub-blks>
	��������� ������-�������� �������� I/O (C = copy, S = scatter/gather), �������� ����������� ����� ���������� ������� � ������� I/O (�������� -mC) ��� ���������� �������� �� I/O ��������������� ����� ������-�����, ����� ������������� ����� API scatter/gather (�������� -mS). ���� API �������� ������ ������� � Windows NT 4.0 SP2. ������ ����� ��������� -m ��������� ����� ���������, ����������� ������� I/O; �� ����, ���� ������ ����� I/O - 16 ��, ����� ����� -mC4, �� ��������� ������ ������-������� ������ 4 �� ������. �������� ��������, ��� � ������ ������������� ��������� -mS �������� ������ ���� ����� ��������� ��� ������������ ��������� ������� �������� (��������, 4 �� �� i386 � 8 �� ��� ALPHA). ����� ����, �������� -m ������ ������������ ��������� � ���������� -o.

	-U[p]
	�������� ���� � ����� ���������� ������������� ���������� ������� (p = � ������� �����������) �� ���������� ������� �������� (DPC), �� ������� �� ���������� � ����������� � �������, �� ������� � ����������������� � ���������������� ������, � �� ���������� �����������.

	-B<[N|Y|H|S]>
	��������� ���������� � ����������� ������������ (N = none, Y = all, H = hdwr, S = sfwr), � �� ��������� ��������� �������� -BN. ��������� ��������� ���������� �������� ������: FILE_FLAG_NO_BUFFERING � FILE_FLAG_WRITE_THROUGH. ������������ ��������� ��� ����� ����� ���������� -BN, ������� �� ��������� ������������� ���� NTFS � ����������� ���� ��������� �����������. ��� �� ��������� ������������� ����� ����� �����, ����������� �������� -BY. ��� ������������� -BH, � ������ ���������� �������� ����� �������������� ���������� ��� �����, �� �� ��� ����� (�� ���� ����� ���������� ������ FILE_FLAG_NO_BUFFERING). ��� ������������� -BS ����������� ����������� ��� �������� �������, �� �� ��� ����� (�� ����, ������ FILE_FLAG_WRITE_THROUGH). �������� �������� �� ��, ��� �� ��� ����� ����� ����������� ����, � SCSI ����������� � �����, ������������ ����������, ������ ���������� ���� FILE_FLAG_WRITE_THROUGH, � ����� ���������� � ����� ������.

	-S<#blocks>
	��������� ����� ���������� ����� ����� ������� �������� I/O, ����������� ���� ����� ������ �� �����, ������� ����� �������������� � �������� ������ ��� ���� �������� �� I/O; �������� ��������, ��� ����� ����� ����� ����� �� ������, ��� � � ������, ������� ������ � ��������� -b. �������� �� ��������� (��� �������� -S) ��������� �� ���� 0 �����.

	-64
	�������� ������������� 64-������ �������� � ������.

	-D<#level>
	�� ����������������� ��������, ������������ ��� �������. � ��� ����������� ������������ ������� ������� ����� (��������, -D11 ������������� ������� �� ���� ������� 1 - 10).

	1 - ���������� � ������������������ � ������� �������.
	2 - ����������� ���������� ��������.
	3 - ���������� � ������� �������� ������.
	4 - ����������� ������� �������� ������.
	9 - ����������� ������� �����.
	10 - ����������� ������������� ������.
	50 - ����������� I/O.
	100 - �������� int3 (������� ��� ������� ���������).
	
-- SQLIOSim
	- ������ ������������ ������ � ������� �� SQL Server ���������
	
	-- ��� ������ �����
		********** Final Summary for file C:\sqliosim.mdx ********** 
		Display Monitor File Attributes: Compression = No, Encryption = No, Sparse = No  
		Display Monitor Target IO Duration (ms) = 100, Running Average IO Duration (ms) = 93 (/*������� ����� �������, ������, ����� ������ Target IO Duration. ��� ���� ����� ����� ��� ����� 5, ��� ����� ������ ����� 15*/), Number of times IO throttled = 10323 /*������� ��� ������ ��� ����� ��-�� ���������� ������� ��������. ��� ������, ��� �����*/, IO request blocks = 16  /*������������ �������, 16 ��� ������, ����� ����� ��� ��������� ��������� 100*/
		Display Monitor Reads = 14768, Scatter Reads = 24920, Writes = 1917, Gather Writes = 24794 /*��� �������� � ���� ������ ��� ������ - ��� �����*/, Total IO Time (ms) = 105149492  /*��� ������, ��� ������� ���� �������� ��������� IO. �� ���� ��� ������ ��������, ��� �����*/
		Display Monitor DRIVE LEVEL: Sector size = 512, Cylinders = 30401, Media type = 12, Sectors per track = 63, Tracks per Cylinders = 255  
		Display Monitor DRIVE LEVEL: Read cache enabled = Yes, Write cache enabled = Yes  
		Display Monitor DRIVE LEVEL: Read count = 43748, Read time = 5136359, Write count = 41861, Write time = 102242119, Idle time = 2717, Bytes read = 7453225984, Bytes written = 7075483648, Split IO Count = 62, Storage number = 2, Storage manager name = VOLMGR   e:\yukon\sosbranch\sql\ntdbms\storeng\util\sqliosim\fileio.cpp 587 
		Display Monitor Closing file C:\sqliosim.ldx 

	
	-- File CONFIG
		Parameter	Default value	Description	Comments
		ErrorFile	sqliosim.log.xml	Name of the XML type log file	
		CPUCount	Number of CPUs on the computer	Number of logical CPUs to create	The maximum is 64 CPUs.
		Affinity	0	Physical CPU affinity mask to apply for logical CPUs	The affinity mask should be within the active CPU mask. A value of 0 means that all available CPUs will be used.
		MaxMemoryMB	Available physical memory when the SQLIOSim utility starts	Size of the buffer pool in MB	The value cannot exceed the total amount of physical memory on the computer.
		StopOnError	true	Stops the simulation when the first error occurs	
		TestCycles	1	Number of full test cycles to perform	A value of 0 indicates an infinite number of test cycles.
		TestCycleDuration	300	Duration of a test cycle in seconds, excluding the audit pass at the end of the cycle	
		CacheHitRatio	1000	Simulated cache hit ratio when the SQLIOSim utility reads from the disk	
		MaxOutstandingIO	0	Maximum number of outstanding I/O operations that are allowed process-wide	The value cannot exceed 140000. A value of 0 means that up to approximately 140,000 I/O operations are allowed. This is the limit of the utility.
		TargetIODuration	100	Duration of I/O operations, in milliseconds, that are targeted by throttling	If the average I/O duration exceeds the target I/O duration, the SQLIOSim utility throttles the number of outstanding I/O operations to decrease the load and to improve I/O completion time.
		AllowIOBursts	true	Allow for turning off throttling to post many I/O requests	I/O bursts are enabled during the initial update, initial checkpoint, and final checkpoint passes at the end of test cycles. The MaxOutstandingIO parameter is still honored. You can expect long I/O warnings.
		NoBuffering	true	Use the FILE_FLAG_NO_BUFFERING option	SQL Server opens database files by using FILE_FLAG_NO_BUFFERING == true. Some utilities and services, such as Analysis Services, use FILE_FLAG_NO_BUFFERING == false. To fully test a server, execute one test for each setting. 
		WriteThrough	true	Use the FILE_FLAG_WRITE_THROUGH option	SQL Server opens database files by using FILE_FLAG_WRITE_THROUGH == true. However, some utilities and services open the database files by using FILE_FLAG_WRITE_THROUGH == false. For example, SQL Server Analysis Services opens the database files by using FILE_FLAG_WRITE_THROUGH == false. To fully test a server, execute one test for each setting.
		ScatterGather	true	Use ReadScatter/WriteGather APIs	If this parameter is set to true, the NoBuffering parameter is also set to true.

		SQL Server uses scatter/gather I/Os for most I/O requests.
		ForceReadAhead	true	Perform a read-ahead operation even if the data is already read	The SQLIOSim utility issues the read command even if the data page is already in the buffer pool.

		Microsoft SQL Server Support has successfully used the true setting to expose I/O problems.
		DeleteFilesAtStartup	true	Delete files at startup if files exist	A file may contain multiple data streams. Only streams that are specified in the Filex FileName entry are truncated in the file. If the default stream is specified, all streams are deleted.
		DeleteFilesAtShutdown	false	Delete files after the test is finished	A file may contain multiple data streams. Only data streams that you specify in the Filex FileName entry are truncated in the file. If the default data stream is specified, the SQLIOSim utility deletes all data streams.
		StampFiles	false	Expand the file by stamping zeros	This process may take a long time if the file is very large. If you set this parameter to false, the SQLIOSim utility extends the file by setting a valid data marker.

		SQL Server 2005 uses the instant file initialization feature for data files. If the data file is a log file, or if instant file initialization is not enabled, SQL Server performs zero stamping. Versions of SQL Server earlier than SQL Server 2000 always perform zero stamping.

		You should switch the value of the StampFiles parameter during testing to make sure that both instant file initialization and zero stamping are operating correctly.
		
	-- Filex Selection
		- The SQLIOSim utility is designed to allow for multiple file testing. The Filex section is represented as [File1], [File2] for each file in the test. 
		Parameter	Default value	Description	Comments
		FileName	No default value	File name and path	The FileName parameter can be a long path or a UNC path. It can also include a secondary stream name and type. For example, the FileName parameter may be set to file.mdf:stream2.

		Note In SQL Server 2005, DBCC operations use streams. We recommend that you perform stream tests.
		InitialSize	No default value	Initial size in MB	If the existing file is larger than the value that is specified for the InitialSize parameter, the SQLIOSim utility does not shrink the existing file. If the existing file is smaller, the SQLIOSim utility expands the existing file.
		MaxSize	No default value	Maximum size in MB	A file cannot grow larger than the value that you specify for the MaxSize parameter.
		Increment	0	Size in MB of the increment by which the file grows or shrinks. For more information, see the "ShrinkUser section" part of this article.	The SQLIOSim utility adjusts the Increment parameter at startup so that the following situation is established:
		Increment * MaxExtents < MaxMemoryMB / NumberOfDataFiles
		If the result is 0, the SQLIOSim utility sets the file as non-shrinkable.
		Shrinkable	false	Indicates whether the file can be shrunk or expanded	If you set the Increment parameter to 0, you set the file to be non-shrinkable. In this case, you must set the Shrinkable parameter to false. If you set the Increment parameter to a value other than 0, you set the file to be shrinkable. In this case, you must set the Shrinkable parameter to true.
		Sparse	false	Indicates whether the Sparse attribute should be set on the files	For existing files, the SQLIOSim utility does not clear the Sparse attribute when you set the Sparse parameter to false.

		SQL Server 2005 uses sparse files to support snapshot databases and the secondary DBCC streams.

		We recommend that you enable both the sparse file and the streams, and then perform a test pass.

		Note If you set Sparse = true for the file settings, do not specify NoBuffering = false in the config section. If you use these two conflicting combinations, you may receive an error that resembles the following from the tool:

		Error:-=====Error: 0x80070467
		Error Text: While accessing the hard disk, a disk operation failed even after retries.
		Description: Buffer validation failed on C:\SQLIOSim.mdx Page: 28097
		LogFile	false	Indicates whether a file contains user or transaction log data
		
	-- Random User Selection
		- The SQLIOSim utility takes the values that you specify in the RandomUser section to simulate a SQL Server worker that is performing random query operations, such as Online Transaction Processing (OLTP) I/O patterns. 
		Parameter	Default value	Description	Comments
		UserCount	-1	Number of random access threads that are executing at the same time	The value cannot exceed the following value:
		CPUCount*1023-100
		The total number of all users also cannot exceed this value. A value of 0 means that you cannot create random access users. A value of -1 means that you must use the automatic configuration of the following value:
		min(CPUCount*2, 8)
		NoteA SQL Server system may have thousands of sessions. Most of the sessions do not have active requests. Use the count(*) function in queries against the sys.dm_exec_requests dynamic management view (DMV) as a baseline for establishing this test parameter value.

		CPUCount here refers to the value of the CPUCount parameter in the CONFIG section.

		The min(CPUCount*2, 8) value results in the smaller of the values between CPUCount*2 and 8.
		JumpToNewRegionPercentage	500	The chance of a jump to a new region of the file	The start of the region is randomly selected. The size of the region is a random value between the value of the MinIOChainLength parameter and the value of the MaxIOChainLength parameter.
		MinIOChainLength	1	Minimum region size in pages	
		MaxIOChainLength	100	Maximum region size in pages	SQL Server 2005 Enterprise Edition and SQL Server 2000 Enterprise Edition can read ahead up to 1,024 pages.

		The minimum value is 0. The maximum value is limited by system memory.

		Typically, random user activity causes small scanning operations to occur. Use the values that are specified in the ReadAheadUser section to simulate larger scanning operations.
		RandomUserReadWriteRatio	9000	Percentage of pages to be updated	A random-length chain is selected in the region and may be read. This parameter defines the percentage of the pages to be updated and written to disk.
		MinLogPerBuffer	64	Minimum log record size in bytes	The value must be either a multiple of the on-disk sector size or a size that fits evenly into the on-disk sector size.
		MaxLogPerBuffer	8192	Maximum log record size in bytes	This value cannot exceed 64000. The value must be a multiple of the on-disk sector size.
		RollbackChance	100	The chance that an in-memory operation will occur that causes a rollback operation to occur.	When this rollback operation occurs, SQL Server does not write to the log file.
		SleepAfter	5	Sleep time after each cycle, in milliseconds
		
	-- Audit User Selection
		- The SQLIOSim utility takes the values that you specify in the AuditUser section to simulate DBCC activity to read and to audit the information about the page. Validation occurs even if the value of the UserCount parameter is set to 0. 		
		Parameter	Default value	Description	Comments
		UserCount	2	Number of Audit threads	The value cannot exceed the following value:
		CPUCount*1023-100
		The total number of all users also cannot exceed this value. A value of 0 means that you cannot create random access users. A value of -1 means that you must use the automatic configuration of the following value:
		min(CPUCount*2, 8)
		NoteA SQL Server system may have thousands of sessions. Most of the sessions do not have active requests. Use the count(*) function in queries against the sys.dm_exec_requests DMV as a baseline for establishing this test parameter value.

		CPUCount here refers to the value of the CPUCount parameter in the CONFIG section.

		The min(CPUCount*2, 8) value results in the smaller of the values between CPUCount*2 and 8.
		BuffersValidated	64		
		DelayAfterCycles	2	Apply the AuditDelay parameter after the number of BuffersValidated cycles is completed	
		AuditDelay	200	Number of milliseconds to wait after each DelayAfterCycles operation
		
	-- ReadAheadUser section
		- The SQLIOSim utility takes the values that are specified in the ReadAheadUser section to simulate SQL Server read-ahead activity. SQL Server takes advantage of read-ahead activity to maximize asynchronous I/O capabilities and to limit query delays. 
		Parameter	Default value	Description	Comments
		UserCount	2	Number of read-ahead threads	The value cannot exceed the following value:
		CPUCount*1023-100
		The total number of all users also cannot exceed this value. A value of 0 means that you cannot create random access users. A value of -1 means that you must use the automatic configuration of the following value:
		min(CPUCount*2, 8)
		NoteA SQL Server system may have thousands of sessions. Most of the sessions do not have active requests. Use the count(*) function in queries against the sys.dm_exec_requests DMV as a baseline for establishing this test parameter value.

		CPUCount here refers to the value of the CPUCount parameter in the CONFIG section.

		The min(CPUCount*2, 8) value results in the smaller of the values between CPUCount*2 and 8.
		BuffersRAMin	32	Minimum number of pages to read per cycle	The minimum value is 0. The maximum value is limited by system memory.
		BuffersRAMax	64	Maximum number of pages to read per cycle	SQL Server Enterprise editions can read up to 1,024 pages in a single request. If you install SQL Server on a computer that has lots of CPU, memory, and disk resources, we recommend that you increase the file size and the read-ahead size.
		DelayAfterCycles	2	Apply the RADelay parameter after the specified number of cycles is completed	
		RADelay	200	Number of milliseconds to wait after each DelayAfterCycles operation
		
	-- BulkUpdateUser section
		- The SQLIOSim utility takes the values that you specify in the BulkUpdateUser section to simulate bulk operations, such as SELECT...INTO operations and BULK INSERT operations. 
		Parameter	Default value	Description	Comments
		UserCount	-1	Number of BULK UPDATE threads	The value cannot exceed the following value:
		CPUCount*1023-100
		A value of -1 means that you must use the automatic configuration of the following value:
		min(CPUCount*2, 8)
		NoteA SQL Server system may have thousands of sessions. Most of the sessions do not have active requests. Use the count(*) function in queries against the sys.dm_exec_requests DMV as a baseline for establishing this test parameter value.

		CPUCount here refers to the value of the CPUCount parameter in the CONFIG section.

		The min(CPUCount*2, 8) value results in the smaller of the values between CPUCount*2 and 8.
		BuffersBUMin	64	Minimum number of pages to update per cycle	
		BuffersBUMax	128	Maximum number of pages to update per cycle	The minimum value is 0. The maximum value is limited by system memory.
		DelayAfterCycles	2	Apply the BUDelay parameter after the specified number of cycles is completed	
		BUDelay	10	Number of milliseconds to wait after each DelayAfterCycles operation
		
	-- ShrinkUser section
		- The SQLIOSim utility takes the values that you specify in the ShrinkUser section to simulate DBCC shrink operations. The SQLIOSim utility can also use the ShrinkUser section to make the file grow. 
		Parameter	Default value	Description
		MinShrinkInterval	120	Minimum interval between shrink operations, in seconds
		MaxShrinkInterval	600	Maximum interval between shrink operations, in seconds
		MinExtends	1	Minimum number of increments by which the SQLIOSim utility will grow or shrink the file
		MaxExtends	20	Maximum number of increments by which the SQLIOSim utility will grow or shrink the file


