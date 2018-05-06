-- Основное
	- https://msdn.microsoft.com/en-us/library/ms155866.aspx (Конфигурационные файлы)
	- https://msdn.microsoft.com/en-us/library/ms143724(v=sql.110).aspx
	- Reporting Services is not cluster-aware
	- Подробности следующего плана смотреть по ссылке выше
	1. Сохранить настройки(фото) "Reporting Services Manager" и учётки в нём
	2. Back up database, application, and configuration files.
	3. Back up the encryption key.
	4. Install a new instance of SQL Server 2012. If you are using the same hardware, you can install SQL Server 2012 side-by-side your existing SQL Server 2005, SQL Server 2008, or SQL Server 2008 R2 installation. Be aware that if you do this, you might need to install SQL Server 2012 as a named instance.
	5. Move the report server database and other application files from your existing installation to your new SQL Server 2012 installation.
	6. Move any custom application files to the new installation.
	7. Configure the report server.
	8. Edit RSReportServer.config to include any custom settings from your previous installation.
	9. Optionally, configure custom Access Control Lists (ACLs) for the new Reporting Services Windows service group.
	10. Test your installation.
	11. Remove unused applications and tools after you have confirmed that the new instance is fully operational.
	
	-- DAX
		https://technet.microsoft.com/en-us/library/hh389762.aspx
		
-- Права доступа/получить права администратора
	Запустить браузер от администратора и выдать права

-- Не забыть забрать данные из
	C:\Program Files\Microsoft Visual Studio 10.0\Common7\IDE\PrivateAssemblies
	C:\Program Files\Microsoft SQL Server\MSRS11.DBAXCLRS\Reporting Services\ReportServer\rssrvpolicy.config

-- План миграции
	1. Установить RS
	2. Обновить SQL Server
	2. Восстановить БД
	3. Скопировать из старого сервера в новый папку C:\Program Files\Microsoft SQL Server\MSRS11.DBAXCLRS\Reporting Services\ReportManager\bin 
	4. Скопировать из старого сервера в новый папку C:\Program Files\Microsoft SQL Server\MSRS11.DBAXCLRS\Reporting Services\ReportServer\bin
	5. Сранивнить файлы
		C:\Program Files\Microsoft SQL Server\MSRS11.DBAXCLRS\Reporting Services\ReportServer\rsreportserver.config
			<InstallationID>
			<Application>
			<UnattendedExecutionAccount>
			<Data>
		C:\Program Files\Microsoft SQL Server\MSRS11.DBAXCLRS\Reporting Services\ReportManager\RSWebApplication.config (в нашем случае одинаковы изначально)	
	
	6. Натравить RS на восстановленные Бд
	7. Восстановить ключ
	8. Применить Web Secvice URL и Report Manager URL
	9. Добавить всех тех же локальных администраторов
	
-- Remove Unused Programs and Files
	- Once you have successfully migrated your report server to a SQL Server 2012 Reporting Services instance, you might want to perform the following steps to remove programs and files that are no longer necessary.
	- Uninstall the previous version of Reporting Services if you no longer need it. This step does not delete the following items, but you can manually remove them if you no longer need them:
	- The old Report Server database
	- RsExec role
	- Report Server service accounts
	- Application pool for the Report Server Web service
	- Virtual directories for Report Manager and the report server
	- Report server log files
	- Remove IIS if you no longer need it on this computer.
