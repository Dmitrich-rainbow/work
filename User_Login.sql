-- Найти тех пользователей БД, от которых запускаются процедуры и тд
	select user_name(execute_as_principal_id) 'execute as user', * from sys.system_sql_modules where execute_as_principal_id is not null
	select user_name(execute_as_principal_id) 'execute as user', *  from sys.service_queues where execute_as_principal_id is not null
	select user_name(execute_as_principal_id) 'execute as user', * from sys.assembly_modules where execute_as_principal_id is not null
	select user_name(execute_as_principal_id) 'execute as user', * from sys.sql_modules where execute_as_principal_id is not null
	select user_name(execute_as_principal_id) 'execute as user', * from sys.server_assembly_modules where execute_as_principal_id is not null
	select user_name(execute_as_principal_id) 'execute as user', * from sys.server_sql_modules where execute_as_principal_id is not null
	
-- Атрибуты у объектов
	select object_name(object_id) 'view name' from sys.system_views where object_definition (object_id) like '%execute_as_principal_id%'