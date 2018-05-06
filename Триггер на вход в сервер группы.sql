--Посмотреть триггеры уровня сервера
--select * from sys.server_triggers
--Удалить триггеры уровня сервера
--drop trigger tr2 on all server
--Помощь
--http://technet.microsoft.com/ru-ru/sqlserver/hh180922

--Создаём триггер, который пускает на сервер пользователей из группы sysadmin с условиями
if exists(select 1 from sys.server_triggers where name = 'tr1') drop trigger tr1 on all server
 
go
 
create trigger tr1 on all server for logon as 
 
begin
 
declare @x xml = EventData()
 
declare @login sysname = @x.value('(EVENT_INSTANCE/LoginName)[1]', 'sysname')
 
declare @address nvarchar(25) = @x.value('(EVENT_INSTANCE/ClientHost)[1]', 'nvarchar(25)')
 
if @login = 'sa' and @address NOT IN ('<local machine>','192.168.0.210','192.168.0.4') rollback
	
--if is_srvrolemember('sysadmin', @login) = 1 and @address IN ('<local machine>','192.168.0.210','192.168.0.4') commit
	
else commit
 
end
 
go