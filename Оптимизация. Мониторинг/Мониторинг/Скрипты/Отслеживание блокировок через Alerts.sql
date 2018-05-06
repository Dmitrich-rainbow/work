USE [master]
GO

CREATE TABLE [dbo].[blocking_info](
	[ID] [int] NULL,
	[DB] [nvarchar](128) NULL,
	[ID жертвы] [int] NULL,
	[Login жертвы] [nvarchar](512) NULL,
	[Время ожидания жертвы, sec] [bigint] NULL,
	[ID виновника] [int] NULL,
	[Login виновника] [nvarchar](512) NULL,
	[HostName жертвы] [nvarchar](512) NULL,
	[HostName вновника] [nvarchar](521) NULL,
	[программа жертвы] [nvarchar](512) NULL,
	[программа виновника] [nvarchar](512) NULL,
	[Запрос виновника] [nvarchar](max) NULL,
	[Запрос жертвы] [nvarchar](max) NULL,
	[login_time] [datetime] NULL,
	[last_batch] [datetime] NULL,
	[Время проблемы] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE [dbo].[responsible_info](
	[id] [int] NULL,
	[spid] [int] NULL,
	[loginame] [nvarchar](512) NULL,
	[lastwaittype] [nvarchar](512) NULL,
	[DB_NAME] [nvarchar](512) NULL,
	[status] [nvarchar](512) NULL,
	[cmd] [nvarchar](512) NULL,
	[hostname] [nvarchar](512) NULL,
	[program_name] [nvarchar](512) NULL,
	[cpu] [bigint] NULL,
	[physical_io] [bigint] NULL,
	[login_time] [datetime] NULL,
	[last_batch] [datetime] NULL,
	[text] [nvarchar](max) NULL,
	[date] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

USE [msdb]
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Alert - blocking processes', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'При возникновении блокировок собирает информацию в таблицы:

master.dbo.blocking_info
master.dbo.responsible_info', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'mssql-alerts', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [collect]    Script Date: 12.12.2017 13:13:18 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'collect', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Удаляем данные старше месяца
DELETE FROM master.dbo.blocking_info WHERE [Время проблемы] < GETDATE()-30
DELETE FROM master.dbo.responsible_info WHERE [date] < GETDATE()-30
		
DECLARE @id int = 0
	
SELECT @id = ISNULL(MAX(id)+1,1) FROM master.dbo.blocking_info

INSERT INTO master.dbo.blocking_info
	SELECT 
		  @id as ''ID''
		  ,DB_NAME(pr1.dbid) AS ''DB''
		  ,pr1.spid AS ''ID жертвы''
		  ,RTRIM(pr1.loginame) AS ''Login жертвы''      
		  ,pr1.waittime/1000 as ''Время ожидания жертвы, sec''
		  ,pr2.spid AS ''ID виновника''
		  ,RTRIM(pr2.loginame) AS ''Login виновника''
		  ,pr1.hostname as ''HostName жертвы''
		  ,pr2.hostname as ''HostName вновника''
		  ,pr1.program_name AS ''программа жертвы''
		  ,pr2.program_name AS ''программа виновника''
		  ,txt.[text] AS ''Запрос виновника''
		  ,pr1_txt.[text] AS ''Запрос жертвы''
		  ,pr1.login_time
		  ,pr1.last_batch
		  ,GETDATE() as ''Время проблемы''
		  --INTO master.dbo.blocking_info
	FROM   MASTER.dbo.sysprocesses pr1(NOLOCK)
		   JOIN MASTER.dbo.sysprocesses pr2(NOLOCK)
				ON  (pr2.spid = pr1.blocked) 
		   OUTER APPLY sys.[dm_exec_sql_text](pr2.[sql_handle]) AS txt
		   OUTER APPLY sys.[dm_exec_sql_text](pr1.[sql_handle]) AS pr1_txt
	WHERE  pr1.blocked <> 0


 INSERT INTO master.dbo.responsible_info
	SELECT @id as id, spid,loginame,lastwaittype,DB_NAME(er.[dbid]) as [DB_NAME],[status],cmd,hostname,[program_name],cpu,physical_io,login_time,last_batch,[text],GETDATE() as [date]	
	--INTO dbo.responsible_info
	FROM sys.sysprocesses er
	left join sys.dm_exec_query_stats qs on er.sql_handle=qs.sql_handle
	outer apply sys.dm_exec_sql_text((er.sql_handle)) st
	WHERE spid IN (SELECT DISTINCT [ID виновника] FROM master.dbo.blocking_info WHERE id = @id)', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


DECLARE @job_id nvarchar(512) = (SELECT job_id FROM msdb..sysjobs WHERE name = 'Alert - blocking processes')


EXEC msdb.dbo.sp_add_alert @name=N'Blocking processes', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=30, 
		@include_event_description_in=0, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'General Statistics|Processes blocked||>|0', 
		@job_id= @job_id
GO