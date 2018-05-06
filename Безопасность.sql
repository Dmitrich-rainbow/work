-- Main
	- В SQL Server 2012 можно создавать свои серверные роли
	
	-- Встроенная в БД безопасность пользователей
		- Изначально создавалось для Azure

-- Шифрование резервных копий
		- SQL Serveer 2014
		- Защита носителя
		
		-- Реализация
			1. Tasks > Backup > Media Options > галочка "backup to a new media set,..." > Backup Options > галочка "Encryption backup"
			2. Создать ассиметричный ключ/certificate в master, но сначала надо создать master key
			3. Делаем backup certificate и master key
				Backup CERTIFICATE forBackup
				TO FILE = 'C:\Key1.txt'
				WITH PRIVATE KEY (
				FILE = 'C:\Key2.txt'
				ENCRYPTION BY PASSWORD = 'Pa$$w0rd'
				)
			4. Чтобы восстановить данную БД на другом сервере
				CREATE MASTER KEY 
				ENCRYPTION BY PASSWORD = 'Pa$$w0rd'
				
				CREATE CERTIFICATE forBackup
				FROM FILE = 'C:\Key1.txt'
				WITH PRIVATE KEY (
				FILE = 'C:\Key2.txt'
				DECRYPTION BY PASSWORD = 'Pa$$w0rd'
				)