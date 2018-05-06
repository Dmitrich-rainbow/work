-- name from hex
	select * from msdb..sysjobs
	where job_id = 0x1292021D3C929A4CBBE3895A61FA68CC 

-- Посмотреть куда ссылается SQL Agent
select subsystem, subsystem_dll, agent_exe
from msdb.dbo.syssubsystems

-- Поменять место хранения нужных файлоы для SQL Agent
EXEC sp_configure 'allow updates', 1
reconfigure with override
GO

update msdb.dbo.syssubsystems
set subsystem_dll= replace(subsystem_dll,'MSSQL10_50.ONLINE','MSSQL10_50.MSSQLSERVER') -- MSSQL10_50.ONLINE(что меняем), MSSQL10_50.MSSQLSERVER(на что меняем)
FROM msdb.dbo.syssubsystems
where subsystem_dll like '%MSSQL10_50.ONLINE%'

EXEC sp_configure 'allow updates', 0
reconfigure with override
GO

-- Почта
	1. SQL Mail(устаревший), актуален до 2005, не было альтернативы. Использует Transport MAPI. Процедура xp_sendmail (6 видео 3:50). Данный метод часто зависает, чтобы вернуть к жизни надо будет перезагрузить SQL Server. Умеет отправлять и читать почту. Для этой конструкции должен стоять MAPI Client(Достаточно установить Outlook). Настройки находятся в Managment > Legacy > SQL Mail
	2. Database Mail. Использует SMTP. Процедура xp_sendDBmail. Умеет почту только отправлять. Настройки находятся в Managment > SQL Server Logs > Database Mail
	Чтобы включить в агенте почту, надо зайти в его настройки > Alert System > Enable mail profiler
	Почта придёт на профиль оператора SQL Agent > Operators, если из скрипта, то в процедурах есть параметры.

- Если есть проблемы с отправкой почты, то можно перезагрузить агента, если не помогает, то поперекдючать гачлоку
  "Enable mail profiler"