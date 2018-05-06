-- Основное
	- Теперь (SQL Server 2012) нужно создавать БД для SSIS, и размещать пакеты там
	- Для размещения пакета требуется доступ public и роль в БД sss
	- Файл размещения имеет разрешение .ispac -- C:\Temp\New folder\Integration Services Project1\Integration Services Project1\bin\Development. Размещается через SQL Server Management Studio


-- Доступ
	1. Добавить пользователей в группу Windows - "DCOM User Group Membership"
	2. Next, I started the Windows Component Services Applet. To get there, you can navigate from Start > All Programs > Administrative Tools > Component Services. From the left pane, I expanded the DCOM Config node under Component Services > Computers > My Computer > DCOM  Config
	3. Ищем MsDtsServer или всё, что связано с Integration Server
	4. В свойствах поставить галочку "Run application on this computer"
	5. В разделе "Security" везде добавить пользователя
	6. Перезагрузить Integration Services

-- Процедуры/Stored Procedure
- Чтобы их вызывать без ошибок, надо использовать
	SET FMTONLY OFF EXEC [dbo].[up_WEB_2_best_List_our] @FILTER = 1397
	
-- Подключение
	-- изменить C:\Program Files (x86)\Microsoft SQL Server\130\DTS\BIN файл MsDtsSrvr.ini.xml (может не 130, а 120 и меньше)
	<?xml version="1.0" encoding="utf-8"?>  
	<DtsServiceConfiguration xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">  
	  <StopExecutingPackagesOnShutdown>true</StopExecutingPackagesOnShutdown>  
	  <TopLevelFolders>  
		<Folder xsi:type="SqlServerFolder">  
		  <Name>MSDB</Name>  
		  <ServerName>ServerName\InstanceName</ServerName>  
		</Folder>  
		<Folder xsi:type="FileSystemFolder">  
		  <Name>File System</Name>  
		  <StorePath>..\Packages</StorePath>  
		</Folder>  
	  </TopLevelFolders>    
	</DtsServiceConfiguration>  
	
-- Мониторинг 
	https://blogs.msdn.microsoft.com/sqlcat/2013/09/16/top-10-sql-server-integration-services-best-practices/
	https://blogs.msdn.microsoft.com/sqlperf/2007/05/01/something-about-ssis-performance-counters/
	http://sqlblog.com/blogs/kevin_kline/archive/2008/10/09/ssis-packages-need-love-too-er-memory-too.aspx
	
-- Открыть проект
	После подключения к SSIS, можно выгрузить проект в dtsx, после чего его можно открыть SSDT