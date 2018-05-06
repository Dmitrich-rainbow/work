-- Перемещение старых файловым (старше 7 дней)
	1. forfiles /p C:\Files /m *.sql /d -7 /c "cmd /c move @file C:\Files\RDP"
	
-- Получение содержимого папки
	create table #traceFileName(id int identity primary key, FileName nvarchar(255))

	declare @cmd nvarchar(1000), @ImportPath nvarchar(255)
	set @ImportPath = ''R:\SIEM\SQL Server''
	set @cmd = ''dir "'' + @ImportPath +''\*.*" /A-D /B /ON''

	insert into #traceFileName exec master..xp_cmdshell @cmd
	delete #traceFileName where FileName is null
	
	SELECT * FROM #traceFileName
	
	DROP TABLE #traceFileName

--	
	'F: & cd F:\SIEM\Export & forfiles -p "F:\SIEM\Export"  -m *.csv* -d -30 -c "cmd /c del @path"' -- 2 команды в одной строке + удаление старых файлов
	'cd "C:\Program Files\7-Zip\" & 7z.exe a -tzip -ssw -mx7 -r0 "F:\SIEM\Archive\test.zip" "F:\SIEM\Archive\SQLABS2C_ABS2C\ARC_SQLServerAudit.all_1.trc"' -- архивирование
	'del "F:\SIEM\Archive\test.txt"' -- удаление