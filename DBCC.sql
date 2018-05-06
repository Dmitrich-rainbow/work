-- ��������
	DBCC TRACEON (2588) -- ������� ��� ������ ��� ��������� ������� DBCC
	DBCC HELP ('?') -- ���������� ��� ��������� DBCC �������
	DBCC HELP ('checkalloc') -- ��������� �� DBCC �������
	
-- ���������� �������� ���������� � ����
	DBCC OPENTRAN ()	
	DBCC OPENTRAN (database_name) -- ������ ���������� � ���� ������

-- ��������� ������/ last query
	DBCC INPUTBUFFER(117)
	
-- ������ 
	DBCC CHECKDB
	DBCC CHECKFILEGROUP
	DBCC CHECKTABLE
	DBCC INDEXDEFRAG
	DBCC SHRINKDATABASE
	DBCC SHRINKFILE
	
	DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS -- ������� ��� ������ ������ �� ��������� ���� (�� ���� ���� ���, ������� �� ����� ������� �������). ����� ������� ������ ������ �� ��������� ����, ���������� ������� ��������������� ����������� CHECKPOINT ��� ����������� ��������� ��������� ����. ��� ������� �������������� ������ ���� ��������� ������� ������� ���� ������ �� ���� � ������� ������. ����� ����� ����� ��������� ������� DBCC DROPCLEANBUFFERS, ������� ������ ��� ������ �� ��������� ����.
	DBCC FLUSHPROCINDB(db_id) -- ������� ���� ������ ����
	DBCC FREEPROCCACHE WITH NO_INFOMSGS; -- �������� ���� ��� ������(����� ������ ����� ���� ���������� ������� �����)/���� ����������/��������������
	DBCC FREEPROCCACHE(0x05000F006FB9565D40615615050000000000000000000000) -- �������� ��� ������������� ����� (plan_handle)
	DBCC FREESYSTEMCACHE ('All') -- ������� ��� �������������� �������� �� ���� �����.
	DBCC FREESESSIONCACHE Flushes the distributed query connection cache. This has to do with distributed querie
	
-- ���������� ����������
	DBCC SHOW_STATISTICS (Films2,_WA_Sys_00000005_113584D1)
	DBCC SHOW_STATISTICS (Films2,_WA_Sys_00000005_113584D1) WITH HISTOGRAM -- ���������� ������ �����������  
 
-- �������� �������� ��������������
	DBCC CHECKIDENT('��������������', RESEED, 0);
 
 -- DBCC PAGE/��������� �������� ��
	- Page 0 in any file is the File Header page, 1 is a Page Free Space (PFS), 3 �������� (ID 2) GAM, 4 (ID 3) SGAM. Another GAM appears every 511,230 pages after the first GAM on page 2, and another SGAM appears every 511,230 pages after the first SGAM on page 3.
	DBCC TRACEON(3604)
	DBCC page(1,1,152)
	
	-- IAM (INDEX ALLOCATION MAP)
		���� IAM �� 4 Gb
	
-- �������� ������������� ������ ����� ���
	DBCC SQLPERF (LOGSPACE)
	
-- ������� ������� ����� ����
	dbcc loginfo
	
 -- �������� ���� ����� ����
	DBCC CHECKCONSTRAINTS
 
 -- ���������� � ����
	DBCC SHOWCONTIG

-- �������� ����
	DBCC CHECKDB ('DATABASE_NAME') WITH NO_INFOMSGS, ALL_ERRORMSGS, PHYSICAL_ONLY;

-- ���������� ������������� ������
	DBCC MEMORYSTATUS