-- Посмотреть возможные команды
	Get-Command -Module dbatools
	 
	-- Отфильтровать по нужным  
		Get-Command -Module dbatools | where name -like get-*

-- Получить информацию из файла	в переменную и применить к каждому значений скрипт
	#server = Get-Content -Delimiter " " C:\distr\ps\servers.txt
	foreach ($s in $servers) {Get-DbaLogin -SqlServer $s | Format-Table -AutoSize}

-- Выгрузить логины в файл
	Get-DbaLogin -SqlServer AX2009MIA-SQL | Format-Table -AutoSize | Out-File 'C:\distr\ps\1.txt'

foreach ($s in $servers) {Test-SqlNetworkLatency -SqlServer AX2009MIA-SQL -Query "Select @@VERSION" | Format-Table -AutoSize | Out-File 'C:\distr\ps\1.txt' -Append}

-- Выполнить запрос на многих серверах
	$server = "<server>.database.windows.net"
	$db = "<database>"
	$sql = "SELECT TOP 5 * FROM [Index]"
	Invoke-SqlCommand -Server $server -Database $db -Username $user -Password $pass -Query $sql | Format-Table

	
	-- Пройтись по списку серверов
		foreach ($s in $servers) {Invoke-Sqlcmd -ServerInstance $s -Query "SELECT @@VERSION" | Format-Table -AutoSize}

-- Множество запросов на одном сервере		
	for ($i = 0; $i -lt 10; $i++) {Invoke-Sqlcmd -ServerInstance AX2009MIA-SQL -Query "SELECT @@VERSION" | Format-Table -AutoSize}