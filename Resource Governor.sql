--Квотирование/Resource Governor
	- В старых версиях можно было создать несколько экземпляром и разделить ресурсы между ними.
	- В новых(начиная с 2005) есть система квотирования. С 2008 версии полное квотирование.
	(Resourse Governor)Если сервер перегрузили и невозможно зайти, то используем подключение DAC.
	-Ресурсом кватирования считается память и процессор. Они делятся на пулы(зона/обёъм в % от процессора/памяти).
	На самом деле пулы динамические, если сервер свободен, используется нижняя и верхняя граница.
	При подключении пользователь попадает в группу(WorkLoad Group), которая подключается к пулам с помощью
	функции(в базе master), которую надо написать. Для распределения по группам можно использовать что угодно,
	что можно вытащить с помощью функций T-SQL(имя, Application Role...). Он находится в Managment>Resourse Governor. Там его надо включить и присвоить ему функцию.
	- Если подключиться к одному пулу, а потом необходимо переключиться на другой, то необходимо переподключиться
	- Изначально есть defaulr pool, в который попадают все пользователи и 1 нагружающая группа
	- Сумма нижних границ не должна превышать 100%	
	- В функции можно отлавливать имя приложения и что угодно, чтобы разделять популам
	- Необходимо включить его в свойствах и привязать к нашей функции
		CREATE RESOURCE POOL Silver
			WITH (
				 MIN_CPU_PERCENT = 5,
				 MAX_CPU_PERCENT = 50
				)
				
		CREATE WORKLOAD GROUP LOw
			USING Silver
			
		USE MASTER
		GO
		CREATE FUNCTION MyFunction ()
			RETURNS SysName
			WITH SCHEMABINDING -- если мы приписали данный параметр View, то мы не сможем удалить таблицу, к котороый
							   -- ссылается данная View. То есть жёстко цепляется к объектам на которые ссылается
		AS
			BEGIN
					DECLARE @GroupName varchar(100)
					SET @GroupName = 'Hight'
					IF SUser_Name () LIKE 'Onegin'
					SET @GroupName = 'Low'
					RETURN @GroupName
			END
			
		-- Включить функцию
			USE master
			GO
			ALTER RESOURCE GOVERNOR
			WITH (CLASSIFIER_FUNCTION=dbo.MyFunction);
			GO
			ALTER RESOURCE GOVERNOR RECONFIGURE
			GO
			
	- SQL Server всегда резервирует минимальное количество памяти под каждый pool, даже если этот пул ни кем не используется, на CPU это не распространяется
	- При обычной конфигурации пула, мы не можем гарантировать жесткую раздачу CPU, для жесткой раздачи нужно использовать CAP_CPU_PERCENT, что соответсвует максимальному значению
	- Если хотим чтобы Resource Governor отсавался всегда отключенным, то нужно использовать флаг 8040. При этому следует иметь ввиду:
		Only the internal workload group and resource pool exist.
		Resource Governor configuration metadata isn’t loaded into memory.
		Your classifier function is never executed automatically.
		The Resource Governor metadata is visible and can be manipulated.

	CREATE WORKLOAD GROUP LOw
	WITH
	( [ IMPORTANCE = { LOW | MEDIUM | HIGH } ] -- 1/3/9  каждая следующая группа будет вызываться в 3 раза чаще предыдущей
	  [ [ , ] REQUEST_MAX_MEMORY_GRANT_PERCENT = value ] -- This value specifies the maximum amount of memory that a single task from this group can take from the resource pool
	  [ [ , ] REQUEST_MAX_CPU_TIME_SEC = value ]
	  [ [ , ] REQUEST_MEMORY_GRANT_TIMEOUT_SEC = value ] -- This value is the maximum time in seconds that a query waits for a resource to become available.
	  [ [ , ] MAX_DOP = value ]
	  [ [ , ] GROUP_MAX_REQUESTS = value ] -- This value is the maximum number of requests allowed to be simultaneously executing in the workload group.
		USING Silver

-- Мониторинг
	-- Пользователи и группы
		SELECT rp.name,* FROM sys.dm_exec_sessions as es
		INNER JOIN sys.dm_resource_governor_resource_pools rp ON es.group_id = rp.pool_id
		WHERE group_id > 1
	
	-- Использование ресурсов по пулам
		SELECT
				rpool.name as PoolName,
				COALESCE(SUM(rgroup.total_request_count), 0) as TotalRequest,
				COALESCE(SUM(rgroup.total_cpu_usage_ms), 0) as TotalCPUinMS,
				CASE 
					  WHEN SUM(rgroup.total_request_count) > 0 THEN
							SUM(rgroup.total_cpu_usage_ms) / SUM(rgroup.total_request_count)
							ELSE
							0 
					  END as AvgCPUinMS
		  FROM
		  sys.dm_resource_governor_resource_pools AS rpool
		  LEFT OUTER JOIN
		  sys.dm_resource_governor_workload_groups  AS rgroup
		  ON 
			  rpool.pool_id = rgroup.pool_id
		  GROUP BY
			  rpool.name;
	
		
	sys.resource_governor_configuration This view returns the stored Resource Governor state.

	sys.resource_governor_resource_pools This view returns the stored resource pool configuration. Each row of the view determines the configuration of an individual pool.

	sys.resource_governor_workload_groups This view returns the stored workload group configuration.
	Also, three DMVs are devoted to the Resource Governor.

	sys.dm_resource_governor_workload_groups This view returns workload group statistics and the current in-memory configuration of the workload group.

	sys.dm_resource_governor_resource_pools This view returns information about the current resource pool state, the current configuration of resource pools, and resource pool statistics.

	sys.dm_resource_governor_configuration This view returns a row that contains the current in-memory configuration state for the Resource Governor.
	Finally, six other DMVs contain information related to the Resource Governor.

	sys.dm_exec_query_memory_grants This view returns information about the queries that have acquired a memory grant or that still require a memory grant to execute. Queries that don’t have to wait for a memory grant don’t appear in this view. The following columns are added for the Resource Governor: group_id, pool_id, is_small, and ideal_memory_kb.

	sys.dm_exec_query_resource_semaphores This view returns the information about the current query-resource semaphore status. It provides general query-execution memory status information and allows you to determine whether the system can access enough memory. The pool_id column has been added for the Resource Governor.

	sys.dm_exec_sessions This view returns one row per authenticated session on SQL Server. The group_id column has been added for the Resource Governor.

	sys.dm_exec_requests This view returns information about each request executing within SQL Server. The group_id column is added for the Resource Governor.

	sys.dm_exec_cached_plans This view returns a row for each query plan cached by SQL Server for faster query execution. The pool_id column is added for the Resource Governor.

	sys.dm_os_memory_brokers This view returns information about allocations internal to SQL Server that use the SQL Server Memory Manager. The following columns are added for the Resource Governor: pool_id, allocations_kb_per_sec, predicated_allocations_kb, and overall_limit_kb.

	-- MAXDOP
	1. Можно выставлять через Resource Governor