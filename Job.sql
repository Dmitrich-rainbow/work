--активация более детальной статистики Job
	USE master;
	GO
	EXEC sp_configure 'Ad Hoc Distributed Queries', '1';

	RECONFIGURE;
	EXEC sp_configure;
	
-- отключение задания
	EXEC msdb.dbo.sp_update_job @job_name='Your job name',@enabled = 0

-- текущее состояние job
	sp_help_job/sp_help_jobactivity

-- запущен ли job?

	-- 1 --	
		SELECT a.*
		FROM OPENROWSET('SQLNCLI', 'Server=(local);Trusted_Connection=yes;',
		   'set fmtonly off exec msdb..sp_help_job @job_name = N''job_name'',@execution_status = 1 ') AS a
	   
	-- 2 --	
		SELECT
			Count(*)
		FROM
			msdb.dbo.sysjobs_view job 
				INNER JOIN msdb.dbo.sysjobactivity activity
				ON (job.job_id = activity.job_id)
		WHERE
			run_Requested_date is not null 
			AND stop_execution_date is null
			AND job.name = 'Paral'

-- Владельцы заданий
	SELECT sp.name,* FROM msdb..sysjobs_view sv INNER JOIN sys.syslogins sp ON sp.[sid] = sv.owner_sid
	   
-- Активность определённого Job
	SELECT sj.name
	   , sja.*
		FROM msdb.dbo.sysjobactivity AS sja
		INNER JOIN msdb.dbo.sysjobs AS sj ON sja.job_id = sj.job_id
		WHERE sja.start_execution_date IS NOT NULL
		   AND sja.stop_execution_date IS NULL
			AND name = 'test'
   
-- узнать о job по его id
	DECLARE @JobName varchar(max)
	SELECT @JobName = [name] 
	FROM msdb.dbo.sysjobs WHERE job_id = cast(0xD9A903F7C2DBB941A4AB642738A55535 AS uniqueidentifier)
	EXECUTE msdb..sp_help_job @job_name = @JobName
	EXECUTE msdb..sp_help_jobstep @job_name = @JobName
	
-- Системные представления
	1. MSDB.dbo.sysjobs (Primary table for job related information)
	2. MSDB.dbo.sysjobsteps (Entry for each step in a specific job)
	3. MSDB.dbo.sysjobschedules (Schedule(s) for each job)
	4. MSDB.dbo.sysjobservers (Local or remote servers where the job executes)
	5. MSDB.dbo.sysjobhistory (Historical record of the jobs execution)
	6. MSDB.dbo.sysjobactivity (Current job status, next run date\time, queued date, etc.)
	7. MSDB.dbo.sysjobstepslogs (Historical job step log information for all job steps configured to write to this table)

-- выдать на определённый список джобов полные права управления определённому человеку без включения этого человека в роль сисадминс.
	--Нюанс в том, что роль SQLAgentOperatorRole и владение джобом не дают права на управление шедулерами, созданными в рамка джоба кем-то другим.

	use msdb
	go
	select 'EXEC msdb.dbo.sp_update_job @job_id=N''' + cast(a.job_id as nvarchar(max)) + ''',@owner_login_name=N''<login>'';' 'changeJobOwner'
	, 'EXEC dbo.sp_update_schedule @schedule_id = ''' + cast(a.schedule_id as nvarchar(max)) + ''', @owner_login_name = N''<login>'';' 'changeShedOwner'
	, a.job_id 'jobId'
	, a.schedule_id 'shedId'
	, b.name 'jobName'
	, c.name 'shedName'
	, e.name 'jobOwner'
	, d.name 'shedOwnerName'  from sysjobschedules a
	join sysjobs b
	on a.job_id = b.job_id
	join sysschedules c
	on a.schedule_id = c.schedule_id
	join sys.syslogins d
	on c.owner_sid = d.sid
	join sys.syslogins e on b.owner_sid = e.sid
	

			
			
-- Активность задания в данный момент	
	SELECT
	ja.job_id,
	j.name AS job_name,
	ja.start_execution_date,      
	ISNULL(last_executed_step_id,0)+1 AS current_executed_step_id,
	Js.step_name
	FROM msdb.dbo.sysjobactivity ja 
	LEFT JOIN msdb.dbo.sysjobhistory jh 
	ON ja.job_history_id = jh.instance_id
	JOIN msdb.dbo.sysjobs j 
	ON ja.job_id = j.job_id
	JOIN msdb.dbo.sysjobsteps js
	ON ja.job_id = js.job_id
	AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
	WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions   ORDER BY agent_start_date DESC)
	AND start_execution_date is not null
	AND stop_execution_date is null
			
-- Выводит список запущенных заданий
	IF OBJECT_ID('tempdb.dbo.#RunningJobs') IS NOT NULL
	DROP TABLE #RunningJobs
	CREATE TABLE #RunningJobs (
	Job_ID UNIQUEIDENTIFIER,
	Last_Run_Date INT,
	Last_Run_Time INT,
	Next_Run_Date INT,
	Next_Run_Time INT,
	Next_Run_Schedule_ID INT,
	Requested_To_Run INT,
	Request_Source INT,
	Request_Source_ID VARCHAR(100),
	Running INT,
	Current_Step INT,
	Current_Retry_Attempt INT,
	State INT )INSERT INTO #RunningJobs EXEC master.dbo.xp_sqlagent_enum_jobs 1,garbage
	SELECT
	name AS [Job Name]
	,CASE WHEN next_run_date=0 THEN '[Not scheduled]' ELSE
	CONVERT(VARCHAR,DATEADD(S,(next_run_time/10000)*60*60 /* hours */
	+((next_run_time - (next_run_time/10000) * 10000)/100) * 60 /* mins */
	+ (next_run_time - (next_run_time/100) * 100)  /* secs */,
	CONVERT(DATETIME,RTRIM(next_run_date),112)),100) END AS [Start Time]
	FROM     #RunningJobs JSR
	JOIN     msdb.dbo.sysjobs
	ON       JSR.Job_ID=sysjobs.job_id
	WHERE    Running=1 -- i.e. still running
	ORDER BY name,next_run_date,next_run_time
	
-- Запущенные в данный момент jobs
	IF OBJECT_ID('tempdb.dbo.#RunningJobs') IS NOT NULL
		  DROP TABLE #RunningJobs
	CREATE TABLE #RunningJobs (   
	Job_ID UNIQUEIDENTIFIER,   
	Last_Run_Date INT,   
	Last_Run_Time INT,   
	Next_Run_Date INT,   
	Next_Run_Time INT,   
	Next_Run_Schedule_ID INT,   
	Requested_To_Run INT,   
	Request_Source INT,   
	Request_Source_ID VARCHAR(100),   
	Running INT,   
	Current_Step INT,   
	Current_Retry_Attempt INT,   
	State INT )     
		  
	INSERT INTO #RunningJobs EXEC master.dbo.xp_sqlagent_enum_jobs 1,garbage   
	  
	SELECT     
	  name AS [Job Name]
	 ,*
	FROM     #RunningJobs JSR  
	JOIN     msdb.dbo.sysjobs  
	ON       JSR.Job_ID=sysjobs.job_id  
	WHERE    Running=1 -- i.e. still running  
	ORDER BY name,next_run_date,next_run_time 
	
-- Посмотреть ошибки в job за последние 7 дней/job failure
	SELECT   j.[name], 
			 s.step_name, 
			 h.step_id, 
			 h.step_name, 
			 h.run_date, 
			 h.run_time, 
			 h.sql_severity, 
			 h.message, 
			 h.server 
	FROM     msdb.dbo.sysjobhistory h 
			 INNER JOIN msdb.dbo.sysjobs j 
			   ON h.job_id = j.job_id 
			 INNER JOIN msdb.dbo.sysjobsteps s 
			   ON j.job_id = s.job_id
			   AND h.step_id = s.step_id
	WHERE    h.run_status = 0 -- Failure 
			 AND h.run_date > CONVERT(VARCHAR(30), Dateadd(dd, -7, Getdate()), 112) -- Можно изменить 7 на любое число, за которое необходимо собрать статистику
	ORDER BY h.instance_id DESC 

-- Удалить ошибки заданий за последние 7 дней
	SELECT * FROM  msdb.dbo.sysjobhistory WHERE run_date > CONVERT(VARCHAR(30), Dateadd(dd, -7, Getdate()), 112) AND run_status = 0
	   

-- sp_help_job
	- Можно передать параметры sp_help_job @job_name='Unload_CATALOG_TO_XML_2'
	- Чтобы получить данные о времени нужно узнать job_id и поискать в SELECT * FROM msdb..sysjobhistory
	
sp_help_jobactivity
sp_help_jobcount 
sp_help_jobhistory 
sp_help_jobs_in_schedule 
sp_help_jobschedule 
sp_help_jobserver 
sp_help_jobstep 
sp_help_jobsteplog
msdb..sp_start_job @job_name = 'Мониторинг дискового пространства'
sp_stop_job @job_name = 'Diff Backup WWWBRON.1'
exec msdb..sp_update_job  @job_name = 'Database Mirroring Monitor Job', @enabled = 0;  -- отключить job