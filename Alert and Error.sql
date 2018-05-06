-- Alert
	- ќсновное
		- „тобы регистрировались событи€, которые не регистрируютс€ сейчас, можно через sp_alterMessage указать параметр WITH_LOG	
	
	- ≈сли мы хотим использовать данные от Alert в Job, то можно воспользоватьс€ следующими параметрами:
		- ƒл€ работы данных подсказок необходимо включить в SQL Agent "Replcate tokens for all jobs responses to alerts"
		set @Server = N'$(ESCAPE_SQUOTE(A-MSG))'
		(A-DBN) The Database name is passed to the Job from the alert in this macro
		(A-SVR)	The Server name is passed to the Job from the alert in this macro
		(A-ERR)	The Error number is passed to the Job from the alert in this macro
		(A-SEV)	The Error severity is passed to the Job from the alert in this macro
		(A-MSG)	The Message text is passed to the Job from the alert in this macro (this will include the error number and severity as strings)
		(DATE)	The Current date (in YYYYMMDD format).
		(INST)	The Instance name. For a default instance, this token is empty.
		(JOBID)	The Job ID
		(MACH)	Computer name.
		(MSSA)	Master SQLServerAgent service name.
		(OSCMD)	Prefix for the program used to run CmdExec job steps.
		(SQLDIR) The directory in which SQL Server is installed. (By default, this value is C:\Program Files\Microsoft SQL Server\MSSQL.)
		(STEPCT) Step Count: A count of the number of times this step has executed (excluding retries). (Can be used by the step command to force termination of a multistep loop.)
		(STEPID) Step ID.
		(SRVR)	The Server. Name of the computer running SQL Server. If the SQL Server instance is a named instance, this includes the instance name. This can be different from the server that was the source of the event
		(TIME)	Current time (in HHMMSS format).
		(STRTTM) The time (in HHMMSS format) that the job began executing.
		(STRTDT) The date (in YYYYMMDD format) that the job began executing.
		(WMI( property )) WMI Property. For jobs that run in response to WMI alerts, the value of the property specified by property. For example, $(WMI(DatabaseName)) provides the value of the DatabaseName property for the WMI event that caused the alert to run.
	- ћакросы	
		$(ESCAPE_SQUOTE( token_name )) 	Escapes single quotation marks (') in the token replacement string. Replaces one single quotation mark with two single quotation marks. '
		$(ESCAPE_DQUOTE( token_name ))	Escapes double quotation marks (") in the token replacement string. Replaces one double quotation mark with two double quotation marks. "
		$(ESCAPE_RBRACKET( token_name ))	Escapes right brackets (]) in the token replacement string. Replaces one right bracket with two right brackets.
		$(ESCAPE_NONE( token_name ))	Replaces token without escaping any characters in the string. This macro is provided to support backward compatibility in environments where token replacement strings are only expected from trusted users. For more information, see "Updating Job Steps to Use Macros," later in this topic.
			