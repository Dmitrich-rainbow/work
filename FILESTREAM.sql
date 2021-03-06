-- Основное
	- https://msdn.microsoft.com/en-us/library/cc645923(v=sql.120).aspx
	- FS не использует Buffer pool SQL Server, но использует Windows NT system cache
	- UPDATE создаёт новый файл, а старый удалится, когда все ссылки на него будут очищены после backup log
	
-- Высокая доступность/Availability
	-- Поддерживает
		1. AG
		2. Log shipping
	-- Не поддерживает
		1. Mirroring
		
-- Partition
	- FILESTREAM поддерживает секционирование
		- при создании таблицы требуется указать группы для обычных данных и группу для FS
		- возможно при создании потребуется отключить уникальный индекс
	- FILETABLE не поддерживает секционирование


-- Backup
	1. Изначально всё попадает в backup
	2. transaction log doesn’t contain the actual FILESTREAM data, and only the FILESTREAM data has the redo information for the actual FILESTREAM contents. In general, if your database isn’t in the SIMPLE recovery mode, you need to back up the log twice before the Garbage Collector can remove unneeded data files from your FILESTREAM folders. То есть любой UPDATE и INSERT будет иметь размер лога в зависимости от затронутых файлов, пропорционально их размеру.
	3. Кроме того, что для освобождения файлов (удаления) требуется произвести backup log дважды, ещё требуется вызывать CHECKPOINT:
		BACKUP LOG  MyFileStreamDB to disk = 'C:\backups\FBDB_log.bak'; 
		CHECKPOINT;
		
		- В SQL Server 2012 появилась функция, которая позволяет очистить файлы без лишних backup sp_filestream_force_garbage_collection

-- FileStream, FileTable
	- FileStream:
		- SQL Server 2008		
		Плюсы:
			- Транзакционная целостность
			- Удаляя базу, мы удаляем все файлы, что к ней относятся
			- В бэкапе хранятся все файлы
		Недостатки:
			- Не можем найти файл, который относится к конкретной строке через файловую систему, но можно написать функцию/программу, которая это сделает
			- Однострочная ссылочка целостность. Со стороны базы. Если удалим файл, строка в базе не исчезнет. При этом если удалим файл через файловую систему, база нарушит целостность
			- Неудобный достук со стороный файловой системы
			
	- FileTable
		- SQL Server 2012
		- Надстройка над FileStream
		- Удобная работа с именем файла
		- Двусторонняя ссылочная целостность
		Плюсы: 		
			- Удаляя базу, мы удаляем все файлы, что к ней относятся
			- Транзакционная целостность			
			- Удобная работа с именем файла
			- Двусторонняя ссылочная целостность
		Недостатки:
			- Эффективен, если мы работаем с документами большого размера, если документов много и они маленькие, то мы можем
			  не получить преимущества
			- Требует SQL Server 2012
		
		
-- FileStream
	- Может резервировать только таблицу, для этого резервируем нужные файловые группы
	- Нельзя читать файлы в режиме отображения в память (так работают некоторые приложения)
	- По сути FS это каталог, а не файл
	- Если мы разрешили, то можно редактировать файлы со стороны файловой системы
	1. Включить FileSteam (в настройках Configuration Manager > Экземпляр сервера > В настройках ключить FileSteam, если хотим работать не только со стороны SQL, а ещё и со стороны файловой системы, то вкл вторую галочку, третья - удалённый доступ других серверов).
	   При этом создаётся общая папка.
	2. Свойства в SSMS > Свойства сервера > Advanced > активировать FileStream Access Level
	2.1 EXEC sp_configure filestream_access_level, 2   RECONFIGURE  
	3. Настроить БД
		- Нужно создать спец. файловую группу (нижний список в свойствах базы). Они ничем не отличаются от обычный фаловых групп
		- Включить хотя бы 1 файл в группу. Такой файл, файлом не является, это каталог, указать сможем только логическое имя.
	4. Создать файловую таблицу
		- Надо сделать хотя бы 1 поле varbinary(Max) FILESTREAM
		- Надо добавить спец. столбец, который похож будет на первичный ключ(ID uniqueidentifier NOT NULL ROWGUIDCOL UNIQUE)
		- ROWGUIDCOL - позволяет обращаться к столбцу, не зная его имени, может быть только 1
		- Можем файлово хранить только varbinary(MAX)
		CREATE TABLE fs
		(
			[Id] [uniqueidentifier] ROWGUIDCOL NOT NULL UNIQUE, -- ROWGUIDCOL позволяет обращаться к колонке без названия столбца, для пользователя это бесполезно
			[SerialNumber] INTEGER UNIQUE,
			[Chart] VARBINARY(MAX) FILESTREAM NULL -- указывает что это не просто VARBINARY, а именно FS
		)
	5. Чтобы вставить данные, в поле varbinary(MAX), всё что вставляем, надо преобразовывать к данному типу
	6. Чтобы выбрать данные надо поле varbinary(MAX) обратно преобразовать в нужный формат
	7. Файлы храняться на файловой системе в непонятном формате, хотя я могу открыть данные блокнотом
	8. 	Проверка на вставку данных
		INSERT INTO fs
		VALUES (newid (), 2, 
		  CAST ('' as varbinary(max)));
		  
	-- Интересно
		- http://msdn.microsoft.com/en-us/library/cc949109.aspx
		Filestream file data distribution algorithm is mainly round robin but with a proportional fill element in an effort to try to parallelize the IO activity. What it means is when a new empty container is added, it may be favored more for INSERTs (while still avoiding all INSERTs to be targeted to same). Once new container catches up with the old ones in terms of size, INSERTs would again be fair across containers.

-- FileTable
	- Надстройка над FileStream, поэтому он должен быть включён в настройках
	- Индексы уже настроены и обычно нет смысла их менять
	- Структура уже задана и похожа на структуру файловой системы
	- Так как это надстройка, то в папке FileStream всё равно будут создаваться непонятные файлы, но мы можем работать через шару, где имена будут переводиться в нормальные
	- Можем в шаре создавать файлы/папки и будут появляться строки в базе и наоборот. Удаление работает так же
	- Содержимое хранится в стоблце file_stream
	- Может резервировать только таблицу, для этого резервируем нужные файловые группы
	- Нельзя читать файлы в режиме отображения в память (так работают некоторые приложения)
	1. Включить FileSteam на уровне сервера
	2. Включить FileSteam на уровне базы
	3. Настроить БД (в настройках, основное, FILESTREAM 2 поля)
	4. Теперь можно получать доступ к базе через шару, но для этого в настройках базы указать FileStream Directory Name,
	   внутри этой папке, для каждой таблицы создаётся своя папка
	5. В SSMS теперь отдельная ветка - FileTables
	6. Создаём таблицу. Здесь не указываем структуру таблицы, структура за ранее известна.
		CREATE TABLE MyTable as FILETABLE
		WITH
		(
			FILETABLE_DIRECTORY = 'Имя что указали в FileStream Directory Name (настройки БД)'
		)

	-- Запуск командной строки из SQL
	USE master
	EXEC master.dbo.sp_configure 'show advanced options', 1
	RECONFIGURE
	EXEC master.dbo.sp_configure 'xp_cmdshell', 1
	RECONFIGURE
	GO

	xp_cmdshell