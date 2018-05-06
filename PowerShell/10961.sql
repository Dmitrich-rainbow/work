https://vimeo.com/album/3542605
Логин: -
Пароль: gDUQ2uqlTF

-- Оснастка для SQL Server
	https://www.simple-talk.com/sql/database-administration/the-posh-dba-sqlpsx-sql-server-powershell-extensions/

Get-NetIPAddress | FT

-- Получить версию
	$PSVersionTable
	
-- Посмотреть всех поставщиков (с чем взаимодействует система)
	get-psprovider

-- Установка PowerShell Gallery
	https://www.powershellgallery.com/	
	
-- Вопросы
	1. Посмотреть как получать что же случилась за ошибка в блоке Catch, $Error не подходит
	2. Переменные постоянны или временны при классическом объявлении?
	3. Где смотреть возможные значения типа [Parameter(Mandatory=$True)] 
	4. Если я хочу продолжать работать после ошибки
	5. Закрепить модуль, функцию

-- Основное
	Проект Мунат раньше, начиная с 2008 и Vista он уже есть
	Комментарий #	
	Конкатинация +
	Указание порядка выполнения (), то есть необходимо заключить в скобки совместные операторы
	У всех есть параметры -Verbose -Debug. Это дополнительная информация которая может быть выведена по желанию пользователя, но для распозначания данных опций требует указать в скрипте [CmdletBinding()]  (в самом начале)
	Get-help .\myscript.ps1 -- посмотреть какие параметры ожидает скрипт
	- Команды Windows PowerShell состоят из глагола и существительного (всегда в единственном числе), разделенных тире. Команды записываются на английском языке. Пример:
		Get-Help вызывает интерактивную справку по синтаксису Windows PowerShell
	- Перед параметрами ставится символ «-»:
		Get-Help -Detailed
	- Разные варианты Help
		Get-Help команда
		Get-Help * -- Показать все команды
	- Передать набор данных в другую команду
		Get-Help * | Get-Help -Detailed -- Каждое значение из Get-Help * будет передано в Get-Help -Detailed
	- Передать в файл
		Get-Help * | Out-File c:\PS\test.txt
		
	- Позволяет перемещаться по SQL, как по файловой системе
	- http://powershell.org/wp/
	- Книга Learn Windows PowerShell 3 in a Month of Lunches (http://www.manning.com/jones3/)
	- Более серьёзня книга PowerShell in Depth
	
	
-- Плюсы (почему пошло)
	1. Единобразие (экономит ресурсы Администратора). Глагол(действие)-Существительное(над чем совершать действие). Благодаря этому легко читая скрипт(текст сценария) понять логику
	2. Всё является объектом. Есть свойства, методы, функции. Благодаря этому легко работать с выводом, так как это будет не текст, а объекты(список...)

-- Вывод сообщений
	Write-Host -- просто вывод информации на экран
	Write-Error -- сообщение будет красным и будет сопровождаться сопроводительным(дополнительного) текстом
	Write-Warning 'bbb' -- Текст будет желтём и без сопроводительного(дополнительного) текста
	Write-Verbose -- Добавить отладочную информацию (просто диагностическая информация), которая изначально не видна, только при передаче параметру метода -Verbose и добавлении [CmdletBinding()]
	Write-Debug -- Добавить отладочную информацию (выполнить по шагам, более детальный анализ проблем), которая изначально не видна, только при передаче параметру метода -Debug и добавлении [CmdletBinding()]
	
-- Командлеты
	Get-Command	
		-Verb -- Получить все команды с глаголом Get	
		-Noun -- Получить все команды с существительными Get
		-Module
		
	Get-Module
		-ListAvailable -- Вывести все доступные модули
		Get-Command -Module nettcpip
		
	Update-Help -- Обновить help, сделать его более расширенным

	Get-Help 
		"Название команды"
		-Detailed
		-Full
		-Examples
		-Online
		about_* -- доп. справки
			Get-Help about about_aliases
			
	Get-Member -- анализирует что приходит к ней на вход
		Get-Service | Get-Member
			
	New-Item c:\temp\1 -type directory -- создать дирректорию
	New-Item -Name 'Hello3' -Path $_.FullName -ItemType directory -- При таком подходе не обязательно писать полный путь
	foreach CreateSundirectory "Hello" -- Встроенный метод
	
-- Вспомогательные команды
	через символ '-' указываются параметры
	можно написать часть имени и написать '*', что вывести всё что содержит указанное до или после
	Get-Alias -- посмотреть все синонимы
	| more
	| Format-Table -- вернуть табличный вариант
	
-- Примеры
	Write-Host -- Вывести на экран
	$a = Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 10
	Get-Process > c:\test.txt
	Write-Warning "error".
	Get-Service | Sort-Object -Property status -Descending | ForEach-Object { Write-Host $_.Name $_.status -ForegroundColor yellow } -- ForEach-Object не может работать с командлетами на прямую, поэтому используем цикл
	Get-Service | Sort-Object -Property status -Descending | ForEach-Object {IF ($_.Status -eq "stopped") {Write-Host $_.Name -ForegroundColor yellow } IF($_.Status -eq "running") {Write-Host $_.Name -ForegroundColor green}} -- Вывести запущеные процессы зелёным, а остальные желтым
	Get-Service | ConvertTo-Html -Property Name,Status| Out-File c:\PS\A8.html -- данные в виде HTML
	New-PSdrive -Name FK -Psprovider FileSystem -Root c:\PS -- создать устройство
	Remove-PSDrive FK -- удалить устройство
	Get-ChildItem * -Exclude *.txt -- Вывести содержимое папки за иксключением
	
-- Пример
	dir C:\Windows | Get-Member -MemberType Properties -- узнать свойства/тип/методы входящего объекта
								-MemberType Method
	$PSItem -- текущий элемент списка с которым работаем
	{}  -- Везде, где встречается сложное выражение 
								
-- Export/Import
	Get-Service | Out-File 'C:\Temp\1.txt' -- Выгрузить в читаемом варианте
	Get-Service | Export-Csv 'C:\Temp\1.csv' -- Выгрузка для дальнейшей обработки
	Import-Csv 'C:\Temp\1.csv' | Get-Member --  Можно при импорте понять что за сущность была импортирована
	ConvertTo-... -- Отличие от Export это то, что данная команда не завершает конвеер
	Out-...
		dir C:\Windows | Out-GridView -- Откроется графическая оболочка где можно будет фильтровать и тд.
	
-- Сравнения
	-Eq -- Равно
	-Match -- Сравнение по регулярному выражению
		-cmatch -- если нужно добавить регистрозависимость
	-Ne -- Не равно
	-Notmatch -- Не совпадает с регулярным выражением
	-Gt -Ge -- Больше / Больше или равно
	-Lt -Le -- Меньше / Меньше или равно		
		
-- Конвеер
	Нужно понимать что за объект движется, какие есть свойства и методы у него
	Get-Service | Sort-Object Status | Select-Object -First 10
	Sort-Object -- order by
		-Property
		-Descending
	Select-Object
		-Property
		@{n="..."; e={...}}
			dir C:\Windows -File | Select-Object Name,Length,@{n='Size,kb';e={$PSItem.Length*100}}
			dir C:\Windows | Where-Object -FilterScript {$_.Length -gt 15000 -and $_.Name -like '*.exe' } -- Двойное условие
		-First
		-Last
		-Skip -- Пропустить количество строк из вывода
	Where-Object -- find/fileter
		-EQ, -NE, -GT, -Like...
			 dir C:\Windows | Where-Object Length -gt 15000
		-FilterScript {...}		
		-- Исключить объекты
			ls | select name | where -Property name  -NotLike *.sql
	Measure-Object -- Это агрегация. Считает, но не схлопывает как Group. 
		-Property
		-Sum, -Minimum, Maximum, Average
			dir C:\Windows | Measure-Object Length -Sum	
	Group-Object
		-Property
	ForEach-Object
		dir C:\Temp\ | ForEach-Object {$_.Delete()}
		-MemberName		
		-Process {...}
	Format -- Это конечный этап в конвеере и при создании новых столбцов они дальше не передадутся
		-- Дополнительно позволяет использовать больше форматирования нежели SELECT
		-List
			dir C:\Windows\ | fl Name -- fl это сокращение
			-Property
			-Autosize
		-Table
			 dir C:\Windows\ | ft Name -- ft это сокращение
			-Property
			-Autosize
		-Wide
			dir C:\Windows\ | fw Name -- fw это сокращение
			-Property
			-Autosize
			
-- switch
	- Аналог CASE
	- Перебор значений
		switch($n){
    1 {"Hello"}
    2 {"Hello again"}
	}
			

-- PSProvider
	По сути этодрайверы для источника данных
	Get-PSProvider -- Возвращает установленные драйвера на операционной системе
	Get-PSDrive -- После подключения работаем с источниками как с диском
		New-PSDrive -Name Power -PSProvider Registry -Root 'HKCU:\Control Panel\PowerCfg' -- Регистрация нового пути
	dir HKCU:\ -- посмотреть ветку реестра, для этого ссылка на него должна быть в Get-PSDrive
	
-- Файловая система
	dir = Get-ChildItem
		-Recurse -- Перебрать все вложенности
		 dir C:\Drivers -Directory -- Показать только папки
	New-Item -ItemType file 'c:\Temp\tttttt.txt' -- Создать файл
	Set-Content -Path 'c:\Temp\tttttt.txt' -Value 'Hello, WOrld'
	Get-Content 'c:\Temp\tttttt.txt' -- открыть файл 
	Get-ItemProperty 'c:\Temp\tttttt.txt' -- Показывает свойства папки
	Add-Content 1.txt -- дописать в файл
	
		-- запись в файл/ проверка записи в файл
			while (1 -eq 1) {sleep -Milliseconds 500; date | Add-Content 1.txt }

-- Задержка
	sleep 10 -- 10 сек
	sleep -Milliseconds 100;
			
-- Параметры
	"*win*" | Get-Service
	Sort-Object -InputObject (dir C:\Windows)
	-- В начале PS пытается использовать те свойства параметров, которые имеют "By value", дальше остальные
	By value -- определяет тип данные и благодаря этому использует свойство, например если передаёт "*win*", то PS будет использовать тот By value, где принимается параметр String
	
-- Переменные
	-- Можно менять тип данных в переменной на ходу, что запрещено в программировании, но разрешено в PS
	-- Типы данных как в .Net
	-- Переменные удаляются при отключении сессии
	[int]$Test5 = 100 -- Строго указать тип данных, чтобы нельзя было менять тип данных на ходу
	Get-Variable -- список объявленных переменных
	New-Variable
	$Test4 = 100 -- короткая запись инициализации переменной
	$a -- вызвать переменную с целью получения значения
	$a.GetType() -- получить тип переменной (функция)
	$a.Length -- получить число символов в переменной (свойство указывается без скобочек)
	
	-- Массивы
		$Test7 = 1,2,3,4
			$Test7[0]...
		$Test7.Count -- Количество элементов в массиве
		$Test7[$Test7.Count - 1]
		
	-- Результат
		$SrvList = Get-Service
		$SrvList[0].Stop()

-- Удаленное управление/Удаленный доступ/remote
	- Может потребоваться на удалённом компьютере выполнить "enable-psremoting"
	Удалённый компьютер надо подготовить для управления им через PS. Для этого есть программа WinRM QuickConfig (в таком варианте открывает порты, запускает нужный службы и тд, всё чтобы заработал PS удалённо)
	-ComputerName -- Ключ у большинства командлетов
	PSSession -- войти в интерактивную сессию
		Enter-PSSession CTC-A41KUR084QB
		Exit-PSSession
	Invoke-Command -- для работы с большим количеством компьютеров
		Invoke-Command -ComputerName CTC-A41KUR084QB, localhost -ScriptBlock {Get-Service | select -First 3; Get-Process| select -First 3}

-- Фоновое исполнение команд
	Get-Command -Noun job*
	Start-Job {dir 'C:\Program Files' -Recurse -Directory | Measure-Object} -- Выполнить команду в фоновом режиме
	Get-Job -- Получить данные о фоновых заданий
		HasMoreData -- Этот столбец показывает есть ли вывод в результате выполнения данного задания, который можно посмотреть через Receive-Job
	Receive-Job 4 -- вернуть результат выполнения job_id = 4
	Remove-Job -State Completed -- удалить все завершенные фоновые задания
		Get-job | Remove-Job -- удалить все фоновые задания
	
-- Планировщик/PS Agent/Powershell Agent
	Get-Command -Noun scheduledjo
	taskschd.msc -- Task Scheduler (Windows окно)


-- Циклы
	[int]$Index = 8
	While ($Index -gt 0)
	{
		$Index;
		$Index = $Index - 1;
	}
	----------------------------------------------------------------------------------------------------------------
	do	
		{
			$Index;
			$Index = $Index - 1;
		}
	While ($Index -gt 0) -- Разница в том, что условие проверки происходит в конце (крутится пока условие выполняется)
	----------------------------------------------------------------------------------------------------------------
	do	
		{
			$Index;
			$Index = $Index - 1;
		}
	until ($Index -eq 1) -- Работает пока условие ложное
	----------------------------------------------------------------------------------------------------------------
	For ($Index = 8;$Index -gt 0;$Index = $Index - 1) -- То же самое, но полезная нагрузка не смешивается с перебором
		{
			$Index
		}
	----------------------------------------------------------------------------------------------------------------
	$srv = Get-Service
	foreach ($s in $srv) -- Перебрать все элементы массива
	{
		$s.Name
	}
	----------------------------------------------------------------------------------------------------------------
	Get-Service | Select-Object -First 3 | ForEach-Object {$_.start} -- В конвейере
	----------------------------------------------------------------------------------------------------------------
	$Test9 = 1

	IF ($Test9 -gt 3) -- Начинает выполнятся скрипт при первом попадении в условие, если попали на 1 этапе, все остальные инстуркции отпадают
	{
		Write-Host "Hi"
	}
	ELSEIF ($Test9 -gt 5) 
	{
		'No'
	}
	ELSEIF ($Test9 -gt 7)
	{
		'No 1'
	}
	ELSE
	{
		'End'
	}

	
-- ***** Сценарии/Скрипты *****	
	- Get-ExecutionPolicy
	- Изначально запрещен запуск ps1 скриптов, чтобы включить нужно выставить  Set-ExecutionPolicy Unrestricted
	- Сохраняем файл как ps1, открываем через PS и он возвращает результат, то есть выполняется
		
	-- Передача параметров в скрипт
		Param ([string]$my, [string]$echo)
			$i = dir $my -Directory
			$i.Count
			$echo
		
		-- Вызов 
			.\myscript.ps1 "C:\Program Files" "Hi"
			.\myscript.ps1 -my "C:\Program Files" -echo "Hi"
			
	-- Можно указать значения по-умолчанию, обязательные или не обязательные и множество других возможностей
		[CmdletBinding()] -- Включение подробную работу с параметрами
		Param (
		[Parameter(Mandatory=$True)] -- Указать что параметр обязательный
		[string]$my,
		[string]$echo='Укажи вывод') -- Указать значение по-умолчанию 
		

		
-- ***** Обработка ошибок *****
	Try
	{
	5/0
	}
	Catch
	{
	}
	-----------------------------------------------------------------
	$Error -- встроенная переменная, которая возвращает список ошибок

-- ***** Модули/Функции *****
	Function Get-MyInfo -- Выполнение данного скрипта создаст/перезапищет функцию Get-MyInfo, после чего мы сможем её вызывать
	{
	[CmdletBinding()]
	Param([string]$FileName)

	Get-Content $FileName
	}
	-- Закрепление модулей
		1. Только администратор может помещать модуди в папку установки
			C:\Windows\system32\WindowsPowerShell\v1.0\Modules\
		2. Создать папку по пути C:\Users\Administrator\Documents\WindowsPowerShell\Modules, данному пути может не быть, тогда необходимо его создать, далее необходимо в эту папку скопировать скрипт функции с расширением .psm1 и назвать так же как название вашей папки
		3. С помощью переменных окружения можно настроить где PS будет искать модули
			dir env:\PSModulePath -- Посмотреть куда сейчас смотрит PS
	Get-Module -ListAvailable My* -- посмотреть активировался ли модуль или нет
	Import-Module ModuleName -- импортировть модуль, если уже помещён в папке (часто этого не требуется, так как подключается автоматически)
	
	-- Добавление описания модуля
		- Требуется перезайти в PS, чтобы обновился файл
		Function Get-MyInfo
		{
		<#
		.SYNOPSIS
			Краткая сводка
		.DESCRIPTION
			Подробное описание
		.PARAMETER FileName
			Параметр расположения файла
		.EXAMPLE
			Тут пример
		#>

		[CmdletBinding()]
		Param([string]$FileName)

		Get-Content $FileName
		}
		
-- WMI/CIM
	#Get-Command -Noun CIMInstance -- замена WMI
	#Get-Command -Noun WMIObject -- устаревший механизм (тяжело управляется удалённо)

	-- Список всех WMI
		Get-WmiObject -Class * -List
	
-- Active Directory/AD

-- Готовые пакеты/готовые наборы
	https://dbatools.io/getting-started/ -- выгрузка БД, логины, sql agent jobs
	
-- Кластер/Cluster
	- Возможно надо будет установить RSAT и включить компоненты удалённого администирования кластера

	-- остановить ресурс без остановки роли
	Get-Cluster <dnsRoleName> | Get-ClusterResource | where name -EQ 'SQL Server (<instanceName>)' | Stop-ClusterResource
	
	-- поднять ресурс
	Get-Cluster <dnsRoleName> | Get-ClusterResource | where name -EQ 'SQL Server (<instanceName>)' | Start-ClusterResource
	нюанс - в процессе упадёт агент, поднять можно так же
	
	-- Получить все роли в кластере 
		Get-Cluster crmria-db2 | Get-ClusterGroup -- crmria-db2 (одна из ролей)
		
	-- 	Перевод роли кластера на другую ноду
		get-cluster <dnsRoleName> | Get-ClusterGroup | where name -like '<partOfGroupName>*' | Move-ClusterGroup -Name [название роли] -node <nodename>
		
	-- Посмотреть ресурсы роли
		Get-Cluster crmria-db2 | Get-ClusterResource | where ownergroup -like *mscrm*

		
-- Оценить времы выполнения команд/time
	Measure-Command {Get-Command}
	
-- Обращение к SQL Serever
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True;"
	$SqlQuery = "SELECT * FROM dbo.Category WHERE id = 1"
	-- 	$SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; User ID = $uid; Password = $pwd;"
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand

	$SqlCmd.CommandText = $SqlQuery
	$SqlCmd.Connection = $SqlConnection
	$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
	$SqlAdapter.SelectCommand = $SqlCmd
	$DataSet = New-Object System.Data.DataSet
	$SqlAdapter.Fill($DataSet)
	echo $DataSet.Tables

	-- Множественное обращение
		 for ($i = 0; $i -lt 10; $i++) {hello}		 
	
	-- Подробности по Логину
		PS SQLSERVER:\sql\samoxml\default> dir Logins | where {$_.name -match "samorepl"} | Select Name,CreateDate,DatelastModified,DefaultDatabase | format-list

	-- Посмотреть инфомрацию о базах данных во внешнем окне
		PS SQLSERVER:\sql\samoxml\default> dir databases | sort Size | Select Name,CreateDate, Status, RecoveryModel,Size,Owner| out-gridview

	-- В разделе mail, посмотреть/открыть настройки почты. Посмоттреть свойства
		PS SQLSERVER:\sql\samoxml\default\mail> dir ConfigurationValues | get-member

	-- Получить данные о mail на основе просмотра содержимого файла
		PS SQLSERVER:\sql\samoxml\default\mail> dir ConfigurationValues | SELECT Name,Value

	-- Сохранение в переменную. Эта переменная является массивом
		$config = dir ConfigurationValues

	-- Получение первого значения переменной $config
		PS SQLSERVER:\sql\samoxml\default\mail> $config[0].value

	-- Задания значения $config
		PS SQLSERVER:\sql\samoxml\default\mail> $config[0].value=3

	-- Узнать время
		$(get-date)

	-- Дата последнего backup
		PS C:\> dir sqlserver:\sql\samoxml\default\databases | select Name,LastBackupDate

	-- Сделать backup
		PS C:\> backup-sqldatabase -ServerInstance samoxml -Database Arttour -BackupFile "C:\Arttour.bak"

	-- Восстановить базу/Restore
		PS C:\> restore-sqldatabase -ServerInstance samoxml -database Arttour -BackupFile "C:\Arttour.bak" -RestoreAction Databa
		se -ReplaceDatabase
		
		
--******** Работа черезе командлеты sqlps ********

	-- Конфигурирование политики выполнения работы сценаривев
		set-executionpolicy remotesigned -force
	
	-- Импортирование модуля sqlps
		import-module sqlps (нужно установить netFramework 4.5, PowerShell 3.0 и модуль SQL (его кинуть в папку C:\Windows\system32\WindowsPowerShell\v1.0\Modules\))
		Import-Module “sqlps” -DisableNameChecking 

	-- Выполнение локального запроса
	PS C:\> invoke-sqlcmd -query "select @@version"

	-- Выполнение удалённого запроса
	PS C:\> invoke-sqlcmd -query "select @@version" -ServerInstance "art-base"

	-- Выполнение сценария из файла
	PS C:\> invoke-sqlcmd -InputFile C:\Test.sql

	-- Создание таблицы
	- В $query помещаем текст создания таблицы: $query=@"..."@
	- invoke-sqlcmd -query @query - ServerInstance art-base -Database ComputerData

	-- Перезагрузка
		- SQL Server allows all administrator (sa) level commands to complete before the SQL Server is shutdown
		
-- Ожидание, остановка/sleep/delay
	Start-Sleep -s 2
	
-- Поиск по файлам
	Select-String -Path *.sql -Pattern "Ошибка по заявке"
	-- рекурсивно
		 Get-ChildItem -Path .\* -Recurse | Select-String -Pattern Вним
	
-- Синхронизация папок
	robocopy \\10.0.1.10\forsetup\"sql server" \\10.0.1.29\backup\sql_server  /E /M

		Get-ChildItem -recurse | Select-String -Pattern "Ошибка по заявке"
		
-- Зачем изучать
	1. Не всё в Azure можно сделать через кнопочки, следующий вариант - PS
	