-- Рекомендации по ускорению
	1. EXEC sp_configure 'max degree of parallelism', 1; (https://technet.microsoft.com/en-us/library/dd309734.aspx)
	2. Enable the Lock Pages in Memory Option (https://technet.microsoft.com/en-us/library/dd309734.aspx)
	-- 3. Database Instant File Initialization (https://technet.microsoft.com/en-us/library/dd309734.aspx)
	4. Set COMPATIBILITY_LEVEL to 110 for SQL Server 2012, or to 100 for SQL Server 2008 or SQL Server 2008 R2. (https://technet.microsoft.com/en-us/library/dd309734.aspx)
	5. Set READ_COMMITTED_SNAPSHOT to on. Performance testing has shown that Microsoft Dynamics AX performs better when the READ_COMMITTED_SNAPSHOT isolation option is set to on. You must use an ALTER DATABASE statement to set this option. This option cannot be set by using SQL Server Management Studio. (https://technet.microsoft.com/en-us/library/dd309734.aspx)
		ALTER DATABASE <database name>
		SET READ_COMMITTED_SNAPSHOT ON;
	6. Set AUTO_CREATE_STATISTICS and AUTO_UPDATE_STATISTICS to on. Set AUTO_UPDATE_STATISTICS_ASYNC to off. Performance testing has shown that Microsoft Dynamics AX performs better when the options have these settings. (https://technet.microsoft.com/en-us/library/dd309734.aspx)