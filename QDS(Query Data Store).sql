-- Question: For example if you have Query Data Store (QDS) enabled for user database participating in Always On Availability Groups and you Forced Plan for specific query, what happened if same query running on readable secondary will it use Forced Plan?
	Answer: QDS is not supported on Readable Secondary, so though you have Forced Plan on Primary Replica you “may” see different plan on secondary database because QDS do not force same plan on readable secondary.
	
-- Question: Will QDS retain FORCED Plan information when Database failover from Primary replica to secondary Replica?
	Answer: Yes, QDS store Forced Plan information in sys.query_store_plan table, so in case of failover you will continue to see same behavior on new Primary.
	
-- Best practice
	- https://docs.microsoft.com/en-us/sql/relational-databases/performance/best-practice-with-the-query-store
	- Considering switching capture mode to “Auto” if you are not troubleshooting any ongoing issue for which you needs to capture all queries stats.
	- If your workload contain lot of ad-hoc batch then considering using “auto” capture mode as capturing detail for ad-hoc workload will not provide much benefit.
	- Enable Trace Flag 7745 which Forces Query Store to not flush data to disk on database shutdown. Note: Using this trace may cause Query Store data not previously flushed to disk to be lost in case of shutdown. For a SQL Server shutdown, the command SHUTDOWN WITH NOWAIT can be used instead of this trace flag to force an immediate shutdown.
	- Enable Trace Flag 7752 to Enables asynchronous load of Query Store. Note: Use this trace flag if SQL Server is experiencing high number of QDS_LOADDB waits related to Query Store synchronous load (default behavior).
	
-- Состояние
	SELECT actual_state_desc, desired_state_desc, current_storage_size_mb,   
    max_storage_size_mb, readonly_reason, interval_length_minutes,   
    stale_query_threshold_days, size_based_cleanup_mode_desc,   
    query_capture_mode_desc  
	FROM sys.database_query_store_options;  
	
-- Очистка
	SET QUERY_STORE CLEAR;  
	
-- Разница Is_Forced и Use Plan = True
	https://sqlworkbooks.com/2018/03/forced-plan-confusion-is_forced-vs-use-plan-true/

-- DMV --
	sys.query_store_plan -- Разбивка запросов по планам