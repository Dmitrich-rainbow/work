-- Выравнивание кластеров NTFS и блоков RAID массива
	-- Посмотреть размеры блоков
		- wmic partition get BlockSize, StartingOffset, Name, Index
		- fsutil fsinfo ntfsinfo d:
		
	-- Выполнить калибровку
		- Все данные будут удалены
		
		1. Создаём диск с нужным размером блока
		2. DISKPART
		3: CREATE PARTITION PRIMARY ALIGN=64

-- Работа с шарой через cmd/командрная строка
	net use - посмотреть все созданные подключения net use
	net use /delete \\10.0.1.1\backup - удалить шару
	net use \\10.0.1.1\backup Cgfyx,j,2012 /user:admuser - создать подключение по net use
	exec xp_cmdshell 'net use B: \\10.0.1.1\backup Cgfyx,j,2012 /user:admuser /persistent:yes' - Создать диск, который увидит SQL

	-- Для начала активировать опцию в настройках сервера
	sp_configure 'show advanced options', 1;
	GO
	RECONFIGURE;
	GO
	sp_configure 'Ole Automation Procedures', 1;
	GO
	RECONFIGURE;
	GO
	-- Создаётся временная таблица #drives со всеми жёсткими дисками
	SET NOCOUNT ON
	DECLARE @hr int
	DECLARE @fso int
	DECLARE @drive char(1)
	DECLARE @odrive int
	DECLARE @TotalSize varchar(20) DECLARE @MB Numeric ; SET @MB = 1048576
	CREATE TABLE #drives (drive char(1) PRIMARY KEY, FreeSpace int NULL,
	TotalSize int NULL) INSERT #drives(drive,FreeSpace) EXEC
	master.dbo.xp_fixeddrives EXEC @hr=sp_OACreate
	'Scripting.FileSystemObject',@fso OUT IF @hr <> 0 EXEC sp_OAGetErrorInfo
	@fso
	DECLARE dcur CURSOR LOCAL FAST_FORWARD
	FOR SELECT drive from #drives ORDER by drive
	OPEN dcur FETCH NEXT FROM dcur INTO @drive
	WHILE @@FETCH_STATUS=0
	BEGIN
	EXEC @hr = sp_OAMethod @fso,'GetDrive', @odrive OUT, @drive
	IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso EXEC @hr =
	sp_OAGetProperty
	@odrive,'TotalSize', @TotalSize OUT IF @hr <> 0 EXEC sp_OAGetErrorInfo
	@odrive UPDATE #drives SET TotalSize=@TotalSize/@MB WHERE
	drive=@drive FETCH NEXT FROM dcur INTO @drive
	End
	Close dcur
	DEALLOCATE dcur
	EXEC @hr=sp_OADestroy @fso IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso

	-- Проверяем есть ли диски, с малым объёмом и посылаем почту
	if EXISTS (SELECT * FROM #drives WHERE FreeSpace < 10000)
	BEGIN 
	DECLARE @a nvarchar(Max); 
	SET @a = 'Размер жёсткого диска достиг критического. Он составляет менее 10 Gb. Проблемный диск - ';
	DECLARE @c nvarchar(50); 
	DECLARE cursor2 CURSOR FOR
	SELECT drive FROM #drives WHERE FreeSpace < 10000
	OPEN cursor2;
	FETCH NEXT FROM cursor2
	INTO @c;
	WHILE @@FETCH_STATUS = 0
	BEGIN

	SET @a = @a+@c;

	FETCH NEXT FROM cursor2
	INTO @c;
	END
	CLOSE cursor2;
	DEALLOCATE cursor2;

	EXEC msdb.dbo.sp_send_dbmail
		@recipients = 'DZaytsev@arttour.ru',
		@body = @a,
		@subject = 'Заканчивается жёсткий диск'
	END 
	 
	DROP TABLE #drives


-- SQLIO (http://blogs.msmvps.com/gladchenko/2009/06/09/sqlio/#more-66)
	- Эталонный теста
		sqlio -dC -BH -kW -frandom -t1 -o1 -s60 -b64 testfile.dat -- write random
		sqlio -dC (диск) -BH (управление кэширование) -kR  (тестировать операции чтения)-fsequential -t1 (количество потоков) -o1 (количество запросов в одном потоке) -s60 (как долго тестировать) -b64 (размер блока) testfile.dat > myTest.log (место сохранения результата) --read sequential
		sqlio -kR -s300 -b64 -f1 -i2000000 -o1 -t1 -R1 -LP -a0xf –BN
		sqlio -kR -s300 -b64 -f1 -i2000000 -o1 -t1 -R1 -LP -a0xf -BN > R01-b64-f1-i2000000-o1-t1.log timeout /T 30 sqlio -kW -s300 -b64 -f1 -i2000000 -o1 -t1 -R1 -LP -a0xf -BN > W01-b64-f1-i2000000-o1-t1.log timeout /T 30 sqlio -kR -s300 -b64 -f1 -i2000000 -o1 -t1 -R2 -LP -a0xf -BN > R02-b64-f1-i2000000-o1-t1.log timeout /T 30 sqlio -kW -s300 -b64 -f1 -i2000000 -o1 -t1 -R2 -LP -a0xf -BN > W02-b64-f1-i2000000-o1-t1.log timeout /T 30 …… sqlio -kR -s300 -b64 -f1 -i2000000 -o1 -t1 -R13 -LP -a0xf -BN > R13-b64-f1-i2000000-o1-t1.log timeout /T 30 sqlio -kW -s300 -b64 -f1 -i2000000 -o1 -t1 -R13 -LP -a0xf -BN > W13-b64-f1-i2000000-o1-t1.log timeout /T 30 sqlio -kR -s300 -b64 -f1 -i2000000 -o1 -t1 -R14 -LP -a0xf -BN > R14-b64-f1-i2000000-o1-t1.log timeout /T 30 sqlio -kW -s300 -b64 -f1 -i2000000 -o1 -t1 -R14 -LP -a0xf -BN > W14-b64-f1-i2000000-o1-t1.log
		
	- Чтобы разбить файл тестирования на каждый диск и каждый раз проверять результаты:
	
		sqlio -kR -s180 -b64 -f1 -i2000000 -o1 -t1 -R2,3 -LP -a0xf -BN > R23-b64-f1-i2000000-o1-t1.log timeout /T 30 sqlio -kW -s180 -b64 -f1 -i2000000 -o1 -t1 -R2,3 -LP -a0xf -BN > W23-b64-f1-i2000000-o1-t1.log timeout /T 30
		
	- Этапы тестирования:
		1. Подготовка. Важно, чтобы на обслуживающей дисковый контроллер шине не было других, более медленных устройств, иначе, это может привести к снижению скорости обмена по шине для выравнивания с более медленным устройством.  Дисковые контроллеры должны регистрироваться системой после встроенных контроллеров, которые обслуживают диск или диски операционной системы (иметь большие номера).
		2. Калибровка дисков. Протестировать дисковую систему и сервер с помозью SQLIOSim. Как это делается:			
			- С помощью поставляемых с дисковым контроллером специализированных утилит, конфигурируем все диски полки как 14 массивов RAID0, каждый из которых должен состоять из одного диска, размер каждого массива выбирается равным всему доступному размеру диска, размер блока низкоуровневой разметки (размер сегмента) выбираем равным 64Кб, политики кэширования должны исключать кэширование чтения и записи. В некоторых контроллерах дисковых массивов выбор размера сегмента может быть ограничен несколькими предопределёнными значениями. Можно встретить рекомендованные для типовых конфигураций значения, например, для баз данных предлагают установить размер блока в 128Кб, а для хранения видеофильмов задать 256Кб. В этих случаях резонно выбрать рекомендованные вендором значения.
			- С помощью оснастки управления дисками, входящей в состав mmc-консоли управления компьютером, и системной утилиты DISKPART необходимо создать для каждого физического диска полки RAW-раздел (без форматирования NTFS) величиной на весь диск, и без присвоения буквы диска (буквы присваивать можно, но это не обязательно, к тому же, букв в алфавите может оказаться меньше числа дисков). Большие диски (более двух Терабайт) может потребоваться предварительно перевести в состояние Online, и конвертировать в GPT (GUID Partition Table). Для выравнивания начального смещения за счёт MBR используйте следующие команды DISKPART:

			SELECT DISK=1 

			CREATE PARTITION PRIMARY ALIGN=128 

			- В этом примере выбран диск 1 и смещение установлено в 128Кб. Выбор смещения зависит от размера сегмента. 
			- Установить программу SQLIO. Везде по тексту настоящей статьи местоположение программы sqlio.exe выбрано следующее: C:\SQLIO\ sqlio.exe
			- Подготовьте командный файл, который будет запускать программу sqlio.exe в разных режимах для каждого диска и сохранять результаты в файлы. Пример командного файла можно найти в Приложении 1.
			- Запустите командный файл на исполнении, а потом сведите собранные в файлы результаты в общую таблицу, для дальнейшего сравнения и анализа.
		3. Масштабирование дисков. Зная, какое количество шпинделей потенциально может «запрудить» шину или контроллер, вы можете выбрать, сколько дисков оптимально собирать в один массив.
		4. Выбор размера сегмента. Как основная рекомендация 64 Кб
			Характер нагрузки |	Доступ:	случайный / последовательный | Преобладает:	чтение / запись | Размер запроса ввода-вывода
			Журнал транзакций OLTPсистемы	последовательный	запись	512 Б – 64 КБ
			Файлы данныхOLTPсистемы	случайный	чтение – запись	8 КБ
			Массовая вставка	последовательный	запись	от 8 КБ до 256 КБ
			Упреждающее чтение, просмотр индекса	последовательный	чтение	от 8 КБ до 256 КБ
			Резервное копирование	последовательный	чтение / запись	1 МБ
			Отложенная запись	последовательный	запись	от 128 КБ до 2 МБ
			Восстановление из копии	последовательный	чтение / запись	64 КБ
			Контрольная точка	последовательный	запись	от 8 КБ до 128 КБ
			CREATE DATABASE	последовательный	запись	512 КБ
			CHECKDB	последовательный	чтение	8 КБ – 64 КБ
			DBREINDEX	последовательный	чтение / запись	чтение: от 8 КБ до 256 КБ запись: от 8 КБ до 128 КБ
			SHOWCONTIG	последовательный	чтение	8 KБ – 64 КБ
					
	-k<R|W>
	В примере представлены наиболее распространённые параметры. После имени утилиты, следует параметр -k, который определяет, будет ли на этом шаге производиться чтение (R) или запись (W). Первые два запуска теста т.о. будут тестировать запись, а вторая пара - чтение. По умолчанию принимается -kR.

	-s<secs>
	Вторым параметром -s является продолжительность тестирования, указываемая в секундах. Первые, прикидочные тесты, стоит проводить с небольшими значениями продолжительности, порядка 360 секунд. Это поможет Вам определиться с тем, на каких параметрах Вам стоит сосредоточиться в дальнейших тестах, для которых продолжительность может быть существенно увеличена. По умолчанию, принимается значение -s30.

	-f<stripe factor>
	Третий параметр -f определяет тип I/O (stripe factor), который может быть случайным (random) или последовательным (sequential). По умолчанию принимается значение -f64. Параметр нужен для сопоставления I/O набору страйпов, и определяет число блоков между последовательным I/O. Например, при использовании страйпов, организованных с помощью Windows NT с размером 64 КБ, нужно задавать для -f размер 32 (для 2 КБ блоков), и в то же время, при использовании аппаратно организованных страйпов контроллера дисковых массивов, размером в 128 КБ, для параметра -f стоит указать значение 64 (для 2 КБ блоков). Обратите внимание, что размер страйпа в SQLIO основан и на значение параметра -f и на размере I/O (задаваемом параметром размера блока -b). При использовании значения -f1, результатом станет последовательный I/O.
	В качестве альтернативы указанию размера страйпа, можно определять параметр, как: -frandom - когда блоки в файле выбираются беспорядочно, или -fsequential - когда следующий (логический) блок выбирается после предыдущего I/O в том же самом файле.
	Способ, которым потоки делят страйп, имеет побочный эффект, который заключается в том, что stripe factor не должен быть меньше указанного числа потоков. Поэтому, для последовательного I/O (-f1) может быть задан только один поток, и в случае равенства задаваемых через -f и -t значений получится почти последовательный I/O, так как каждый поток будет работать с I/O на одном блоке, который занимает весь страйп. Однако, поскольку нет упорядочивания потоков, не будет и упорядоченного использования блоков и потому истинно - последовательного I/O тоже не получится.

	-o<#outstanding>
	Четвёртым параметром -o указано количество отправляемых в одном потоке запросов на I/O. Увеличение глубины очереди запросов может привести к более высокой общей производительности, но не стоит этим сильно увлекаться, т.к. текущая на момент написания этой статьи версия утилиты имела проблемы, когда значение параметра было слишком высоко. Наиболее часто применяющимися значениями являются 8, 32 и 64. Очередь запросов на I/O будут выполняться асинхронно для каждого потока и, соответственно, файла с ожиданием завершения I/O, на подобие того, как это реализовано у механизма отложенной записи в SQL Server. Это параметр нельзя использовать совместно с параметром -m (многомерный буфер), потому что операционная система Windows NT не поддерживает обслуживающие завершения I/O подпрограммы Scatter/Gather.
	Когда задано несколько запросов на ввод-вывод в одном потоке, тогда каждый поток будет исполнятся практически точно так же, как если бы параметр -o не был задан. Различие состоит только в том, что другие запросы на I/O смогут завершаться или начинаться на его фоне.
	Если параметр -o неиспользуется, I/O инициализируется асинхронно, и каждый поток I/O ожидает завершения I/O (используется GetOverlappedResult). При этом, если тестируется несколько файлов, I/O запускается для каждого файла так, что бы не было перекрытия запросов на I/O между файлами этого потока. При использовании параметра -o запросы как бы "склеиваются".

	-b<io size(KB)>
	Следующим по порядку параметром указан -b, который задаёт размер блока I/O, измеряемый в байтах. В документации используются для примера следующие значения: 8, 64, 128, 256. По умолчанию принимается значение -b2.

	-L<[S|P][i|]>
	Следующий параметр в приведённом выше примере это -LS (S = system, P = processor), который включает фиксацию задержек на ожидание получения информации от дисковой подсистемы. Это тоже полезная информации, т.к. при сравнимой производительности разных наборов параметров, меньшие задержки будут предпочтительней. С этим параметром можно использовать два возможных таймера, системы и процессора (-LP можно использовать только в архитектуре i386). Обратите внимание, что параметр -LP нужно с осторожностью использовать на SMP серверах, т.к. обращаясь к таймеру процессора невозможно начать или закончить I/O на этом же процессоре (если не установлена привязка процессора), что может привести к ошибкам синхронизации. Также обратите внимание на то, что хотя параметр -LS призван уберечь SMP системы, он тоже не всегда бывает надёжен, и поэтому, для него стоит предъявлять те же ограничения, что и для -LP. В отчёте этот параметр выводит минимальное, среднее и максимальное время завершения исполнения запроса на I/O, и включает гистограмму синхронизаций времени ожидания. Первая строка гистограммы (ms) изображает шкалу от 0 до 23 миллисекунд, а всё что превышает такие задержки, будет относиться к значению 24+. Вторая строка (%) показывает процент завершившихся запросов на I/O для расположенной выше шкалы задержек.
	В дополнении к S или P можно поставить символ i который разрешает включать во время задержки затраты времени на инициализацию запроса на I/O.

	-F<paramfile>
	Последний из приведённых параметров -F определяет имя файла, в котором указывается место и параметры создания тестового файла данных с которым будет работать во время теста SQLIO. В нашем примере и в примере, приводимом в документации к утилите, используется файл с именем "param.txt", который должен располагаться там же, где расположена сама утилита. В файле может быть указано несколько ссылок на пути размещения тестовых данных или на несколько LUN, которые должны быть расположены последовательно, каждый на своей строке. Кроме полного указания пути к файлу и его имени, указываются ещё три параметра, определяющие размеры файла и то, какое число потоков и процессоров будет задействовано сервером для работы с каждым из этих файлов. Ниже представлен имеющийся в документации к утилите пример содержимого файла param.txt:

	c:\sqlio_test.dat 4 0x0 100
	d:\sqlio_test. dat 4 0x0 100

	Следом за указанием пути и имени файла (или LUN), указывается число потоков, открываемых утилитой для этого файла. Рекомендуется устанавливать это значение равным числу установленных в сервере процессоров. В имеющееся на момент написания этой статьи версии утилиты были зафиксированы проблемы при использовании большого совокупного числа потоков по всем файлом. В случае отказов, нужно уменьшать совокупное число потоков до такого значения, когда отказы прекратятся.
	Следом за числом потоков, указывается маска используемого числа процессоров. Это значение аналогично тому, которое указывается в конфигурационных параметрах SQL Server. Для выбора всех процессоров можно указать маску в таком виде: 0x0.
	После маски указывается размер файла тестовых данных в мегабайтах. В идеале, он должен в несколько раз превышать размер кэша контроллера дискового массива, на котором этот файл располагается. В документации рекомендуется делать его в два - четыре раза больше кэша.
	После размера файла, можно указать комментарии, которые должны быть в конце строки, после символа звёздочка "*".
	Для обычных (не расположенных на RAW разделе) файлов, будет использоваться указанный размер файла, если их размер не указан в файле параметров.
	Имена файлов не должны превышать 256 символов.

	Кроме уже перечисленных, есть и другие параметры:

	-i<#IOs/run>
	Указывает, сколько запросов на I/O будет запущено, по умолчанию принимается -i64. #IOs/run - это основной цикл программы, в течение которого заданное число запросов на I/O будет выполнено, выбирая для каждого следующего запроса на I/O один страйп в файле; следующий запрос получит следующий страйп - блок. Каждый поток читает или пишет в другой набор, и число запусков в потоке обратно пропорционально числу потоков. В сочетании с параметрами -f и -b, этот параметр позволяет задать размер в байтах рабочей нагрузки, которая может быть важна для того, чтобы исключить влияние кэширующих контроллеров (например, если принять значения по умолчанию -i64 -f64 -b2 - нагрузка составит 8 МБ). Обратите внимание, что вместе с -i бессмысленно использовать -frandom или -fsequential.

	SQLIO может генерировать очень большую нагрузку дисковой подсистемы запросами I/O на чтение, потому что заданный по умолчанию размер страйпа в 128 КБ может хорошо кэшироваться дисковой подсистемой. Поэтому, стоит поэкспериментировать с параметрами -i и -f , подбирая такие их варианты, которые гарантировали бы достоверные результаты.

	-t<threads>
	Задаёт число используемых в тесте потоков, максимальное значение - 256, по умолчанию принимается значение -t1. SQLIO представляет логические блоки диска в виде двумерного массива, где размер блока определяется параметром -b, в строках массива блоки нумеруются последовательно, и длина каждой строки определяется параметром -f (по умолчанию - 64), а число строк определяется параметром -i (по умолчанию - 64). Если задано два потока (-t2), то первый поток пройдёт только половину страйпа каждой строки, в то время как второй поток начнется с середины страйпа.

	-d<drive1> .. <driveN>
	Задаёт буквы одного или нескольких дисков, на которых утилита создаст файлы данных (у всех файлов будет одинаковое имя). Используется для того, чтобы указать отличный от текущего диск, или для определения нескольких тестируемых дисков. Например, команда: "sqlio -dDEF \test" будет тестировать I/O по трем файлам: D:\test, E:\test и F:\test. Максимальное число таких файлов - 256.

	-R<drive1>, <driveN>
	Для указания сырых (RAW) партиций размещения файлов данных, для которых можно указывать символы дисков или их номера. При указании файлов данных в файле параметров, необходимо к буквам дисков или к их номерам добавлять двоеточие ":", а стандартный параметр имени файла данных указывать нет необходимости. Например, команда: "sqlio -RD,E,F,1,2,3", создаст файлы данных для тестирования I/O на следующих RAW-разделах: D:, E: и F:, а также дисках с номерами: 1:, 2: и 3: (эти же файлы можно было бы использовать в файле с параметрами по отдельности, указав их, как: D: E: F: 1: 2: 3:). Максимальное число задаваемых таким образом файлов тоже не должно превышать 256. Для файлов на RAW разделах, размер файлов должен быть определен в файле параметров.

	-p[I]<cpu affinity>
	Порядковый номер одного из процессоров, который будет использоваться (0 - первый по порядку; I - идеальная афинитизация). Заставляет все потоки процесса sqlio выполняться на указанном процессоре. Например, если указать 0, будет использоваться первый процессор, если указать 1, будет второй, и т.д. Номера: 0, 1, 2 или 3 могут использоваться для 4-х процессорного SMP сервера. В дополнение к номерам, в конец их перечисления, можно добавить символ "I", который включает режим идеальной привязки к процессору, в отличие от предлагаемого по умолчанию режима жесткой привязки.

	-a[R[I]]<cpu mask> 
	Задаёт маску используемых потоками процесса SQLIO процессоров (R = циклический алгоритм использования процессоров (I = идеальная афинитизация)). По смыслу, значения этого параметра аналогичны параметру конфигурации SQL Server - affinity mask. Он отличается от использования параметра -p тем, что последний предназначен для указания использования в тесте только одного процессора. Маску набора используемых в тесте процессоров можно указывать десятичным или шестнадцатеричным числом и это значение будет применено в качестве маски процессоров для каждого потока SQLIO. Если к параметру -a добавить R, то будет использоваться режим чередования процессоров. В этом случае, маска будет задавать число процессоров, которое давайте будем считать равным N. В таком случае, 1/N часть от заданных потоков будут запущена на каждом из указанных процессоров. Например, если указать в параметрах: -a0xf -t16, то все 16 потоков процесса SQLIO будут запускаться на первых четырёх процессорах (в 8-и процессорном сервере). Если же задать: -aR0xf -t16, тогда потоки 1,5,9,13 будут запущены на процессоре 0, потоки 2,6,10,14 на процессоре 1, потоки 3,7,11,15 на процессоре 2, а потоки 4,8,12,16 на процессоре 3. Если к -aR добавить символ "I", включится режим идеальной привязки к процессору, который заменит предлагаемый по умолчанию режима жесткой привязки.

	-m<[C|S]><#sub-blks>
	Разрешает мульти-буферные операции I/O (C = copy, S = scatter/gather), возможно копирование между множеством буферов и буфером I/O (параметр -mC) или исполнение запросов на I/O непосредственно через мульти-буфер, когда задействуется новое API scatter/gather (параметр -mS). Этот API доступен только начиная с Windows NT 4.0 SP2. Вторая часть параметра -m указывает число подблоков, позволяющих дробить I/O; то есть, если размер блока I/O - 16 КБ, тогда задав -mC4, мы установим размер мульти-буферов равным 4 КБ каждый. Обратите внимание, что в случае использования параметра -mS подблоки должны быть равны принятому для используемой платформы размеру страницы (например, 4 КБ на i386 и 8 КБ для ALPHA). Кроме того, параметр -m нельзя использовать совместно с параметром -o.

	-U[p]
	Включает сбор и вывод статистики использования системного времени (p = в разрезе процессоров) по отложенным вызовам процедур (DPC), по времени на прерывание и прерываниям в секунду, по времени в привилегированном и пользовательском режиме, и по утилизации процессоров.

	-B<[N|Y|H|S]>
	Управляет аппаратным и программным кэшированием (N = none, Y = all, H = hdwr, S = sfwr), и по умолчанию принимает значение -BN. Позволяет управлять атрибутами открытия файлов: FILE_FLAG_NO_BUFFERING и FILE_FLAG_WRITE_THROUGH. Одновременно отключить оба флага можно параметром -BN, который не разрешает использование кэша NTFS и встроенного кэша дискового контроллера. Что бы разрешить использование обоих типов кэшей, используйте параметр -BY. При использовании -BH, в период наибольшей нагрузки будет использоваться аппаратный кэш диска, но не кэш файла (то есть будет установлен только FILE_FLAG_NO_BUFFERING). При использовании -BS разрешается программный кэш файловой системы, но не кэш диска (то есть, только FILE_FLAG_WRITE_THROUGH). Обратите внимание на то, что не все диски имеют собственный кэши, а SCSI контроллеры с кэшем, обеспеченным батарейкой, обычно игнорируют флаг FILE_FLAG_WRITE_THROUGH, и будут кэшировать в любом случае.

	-S<#blocks>
	Указывает номер стартового блока файла рабочей нагрузки I/O, ограничивая этим число блоков из файла, которые будут использоваться в качестве основы для всех запросов на I/O; обратите внимание, что блоки здесь имеют такой же размер, как и у блоков, которые заданы в параметре -b. Значение по умолчанию (без указания -S) указывает на блок 0 файла.

	-64
	Включает использование 64-битных операций в памяти.

	-D<#level>
	Не документированный параметр, используемый для отладки. С ним указывается обозначающее уровень отладки число (например, -D11 устанавливает отладку по двум уровням 1 - 10).

	1 - информация о производительности в разрезе потоков.
	2 - детализация калибровки таймеров.
	3 - информация о времени ожидания потока.
	4 - гистограмма времени ожидания потока.
	9 - подробности размера диска.
	10 - подробности распределения памяти.
	50 - подробности I/O.
	100 - вызывает int3 (полезно для ловушек отладчика).
	
-- SQLIOSim
	- Стресс тестирование дисков с похожей на SQL Server нагрузкой
	
	-- Как читать вывод
		********** Final Summary for file C:\sqliosim.mdx ********** 
		Display Monitor File Attributes: Compression = No, Encryption = No, Sparse = No  
		Display Monitor Target IO Duration (ms) = 100, Running Average IO Duration (ms) = 93 (/*среднее время отклика, хорошо, когда меньше Target IO Duration. Для лога лучше когда это менее 5, для файла данных менее 15*/), Number of times IO throttled = 10323 /*Сколько раз запрос был удалён из-за превышения времени ожидания. Чем меньше, тем лучше*/, IO request blocks = 16  /*конкурентные запросу, 16 это хорошо, плохо когда это значениее превышает 100*/
		Display Monitor Reads = 14768, Scatter Reads = 24920, Writes = 1917, Gather Writes = 24794 /*все значения в этой строке чем больше - тем лучше*/, Total IO Time (ms) = 105149492  /*Чем меньше, тем быстрее диск обслужил указанные IO. То есть чем меньше значение, тем лучше*/
		Display Monitor DRIVE LEVEL: Sector size = 512, Cylinders = 30401, Media type = 12, Sectors per track = 63, Tracks per Cylinders = 255  
		Display Monitor DRIVE LEVEL: Read cache enabled = Yes, Write cache enabled = Yes  
		Display Monitor DRIVE LEVEL: Read count = 43748, Read time = 5136359, Write count = 41861, Write time = 102242119, Idle time = 2717, Bytes read = 7453225984, Bytes written = 7075483648, Split IO Count = 62, Storage number = 2, Storage manager name = VOLMGR   e:\yukon\sosbranch\sql\ntdbms\storeng\util\sqliosim\fileio.cpp 587 
		Display Monitor Closing file C:\sqliosim.ldx 

	
	-- File CONFIG
		Parameter	Default value	Description	Comments
		ErrorFile	sqliosim.log.xml	Name of the XML type log file	
		CPUCount	Number of CPUs on the computer	Number of logical CPUs to create	The maximum is 64 CPUs.
		Affinity	0	Physical CPU affinity mask to apply for logical CPUs	The affinity mask should be within the active CPU mask. A value of 0 means that all available CPUs will be used.
		MaxMemoryMB	Available physical memory when the SQLIOSim utility starts	Size of the buffer pool in MB	The value cannot exceed the total amount of physical memory on the computer.
		StopOnError	true	Stops the simulation when the first error occurs	
		TestCycles	1	Number of full test cycles to perform	A value of 0 indicates an infinite number of test cycles.
		TestCycleDuration	300	Duration of a test cycle in seconds, excluding the audit pass at the end of the cycle	
		CacheHitRatio	1000	Simulated cache hit ratio when the SQLIOSim utility reads from the disk	
		MaxOutstandingIO	0	Maximum number of outstanding I/O operations that are allowed process-wide	The value cannot exceed 140000. A value of 0 means that up to approximately 140,000 I/O operations are allowed. This is the limit of the utility.
		TargetIODuration	100	Duration of I/O operations, in milliseconds, that are targeted by throttling	If the average I/O duration exceeds the target I/O duration, the SQLIOSim utility throttles the number of outstanding I/O operations to decrease the load and to improve I/O completion time.
		AllowIOBursts	true	Allow for turning off throttling to post many I/O requests	I/O bursts are enabled during the initial update, initial checkpoint, and final checkpoint passes at the end of test cycles. The MaxOutstandingIO parameter is still honored. You can expect long I/O warnings.
		NoBuffering	true	Use the FILE_FLAG_NO_BUFFERING option	SQL Server opens database files by using FILE_FLAG_NO_BUFFERING == true. Some utilities and services, such as Analysis Services, use FILE_FLAG_NO_BUFFERING == false. To fully test a server, execute one test for each setting. 
		WriteThrough	true	Use the FILE_FLAG_WRITE_THROUGH option	SQL Server opens database files by using FILE_FLAG_WRITE_THROUGH == true. However, some utilities and services open the database files by using FILE_FLAG_WRITE_THROUGH == false. For example, SQL Server Analysis Services opens the database files by using FILE_FLAG_WRITE_THROUGH == false. To fully test a server, execute one test for each setting.
		ScatterGather	true	Use ReadScatter/WriteGather APIs	If this parameter is set to true, the NoBuffering parameter is also set to true.

		SQL Server uses scatter/gather I/Os for most I/O requests.
		ForceReadAhead	true	Perform a read-ahead operation even if the data is already read	The SQLIOSim utility issues the read command even if the data page is already in the buffer pool.

		Microsoft SQL Server Support has successfully used the true setting to expose I/O problems.
		DeleteFilesAtStartup	true	Delete files at startup if files exist	A file may contain multiple data streams. Only streams that are specified in the Filex FileName entry are truncated in the file. If the default stream is specified, all streams are deleted.
		DeleteFilesAtShutdown	false	Delete files after the test is finished	A file may contain multiple data streams. Only data streams that you specify in the Filex FileName entry are truncated in the file. If the default data stream is specified, the SQLIOSim utility deletes all data streams.
		StampFiles	false	Expand the file by stamping zeros	This process may take a long time if the file is very large. If you set this parameter to false, the SQLIOSim utility extends the file by setting a valid data marker.

		SQL Server 2005 uses the instant file initialization feature for data files. If the data file is a log file, or if instant file initialization is not enabled, SQL Server performs zero stamping. Versions of SQL Server earlier than SQL Server 2000 always perform zero stamping.

		You should switch the value of the StampFiles parameter during testing to make sure that both instant file initialization and zero stamping are operating correctly.
		
	-- Filex Selection
		- The SQLIOSim utility is designed to allow for multiple file testing. The Filex section is represented as [File1], [File2] for each file in the test. 
		Parameter	Default value	Description	Comments
		FileName	No default value	File name and path	The FileName parameter can be a long path or a UNC path. It can also include a secondary stream name and type. For example, the FileName parameter may be set to file.mdf:stream2.

		Note In SQL Server 2005, DBCC operations use streams. We recommend that you perform stream tests.
		InitialSize	No default value	Initial size in MB	If the existing file is larger than the value that is specified for the InitialSize parameter, the SQLIOSim utility does not shrink the existing file. If the existing file is smaller, the SQLIOSim utility expands the existing file.
		MaxSize	No default value	Maximum size in MB	A file cannot grow larger than the value that you specify for the MaxSize parameter.
		Increment	0	Size in MB of the increment by which the file grows or shrinks. For more information, see the "ShrinkUser section" part of this article.	The SQLIOSim utility adjusts the Increment parameter at startup so that the following situation is established:
		Increment * MaxExtents < MaxMemoryMB / NumberOfDataFiles
		If the result is 0, the SQLIOSim utility sets the file as non-shrinkable.
		Shrinkable	false	Indicates whether the file can be shrunk or expanded	If you set the Increment parameter to 0, you set the file to be non-shrinkable. In this case, you must set the Shrinkable parameter to false. If you set the Increment parameter to a value other than 0, you set the file to be shrinkable. In this case, you must set the Shrinkable parameter to true.
		Sparse	false	Indicates whether the Sparse attribute should be set on the files	For existing files, the SQLIOSim utility does not clear the Sparse attribute when you set the Sparse parameter to false.

		SQL Server 2005 uses sparse files to support snapshot databases and the secondary DBCC streams.

		We recommend that you enable both the sparse file and the streams, and then perform a test pass.

		Note If you set Sparse = true for the file settings, do not specify NoBuffering = false in the config section. If you use these two conflicting combinations, you may receive an error that resembles the following from the tool:

		Error:-=====Error: 0x80070467
		Error Text: While accessing the hard disk, a disk operation failed even after retries.
		Description: Buffer validation failed on C:\SQLIOSim.mdx Page: 28097
		LogFile	false	Indicates whether a file contains user or transaction log data
		
	-- Random User Selection
		- The SQLIOSim utility takes the values that you specify in the RandomUser section to simulate a SQL Server worker that is performing random query operations, such as Online Transaction Processing (OLTP) I/O patterns. 
		Parameter	Default value	Description	Comments
		UserCount	-1	Number of random access threads that are executing at the same time	The value cannot exceed the following value:
		CPUCount*1023-100
		The total number of all users also cannot exceed this value. A value of 0 means that you cannot create random access users. A value of -1 means that you must use the automatic configuration of the following value:
		min(CPUCount*2, 8)
		NoteA SQL Server system may have thousands of sessions. Most of the sessions do not have active requests. Use the count(*) function in queries against the sys.dm_exec_requests dynamic management view (DMV) as a baseline for establishing this test parameter value.

		CPUCount here refers to the value of the CPUCount parameter in the CONFIG section.

		The min(CPUCount*2, 8) value results in the smaller of the values between CPUCount*2 and 8.
		JumpToNewRegionPercentage	500	The chance of a jump to a new region of the file	The start of the region is randomly selected. The size of the region is a random value between the value of the MinIOChainLength parameter and the value of the MaxIOChainLength parameter.
		MinIOChainLength	1	Minimum region size in pages	
		MaxIOChainLength	100	Maximum region size in pages	SQL Server 2005 Enterprise Edition and SQL Server 2000 Enterprise Edition can read ahead up to 1,024 pages.

		The minimum value is 0. The maximum value is limited by system memory.

		Typically, random user activity causes small scanning operations to occur. Use the values that are specified in the ReadAheadUser section to simulate larger scanning operations.
		RandomUserReadWriteRatio	9000	Percentage of pages to be updated	A random-length chain is selected in the region and may be read. This parameter defines the percentage of the pages to be updated and written to disk.
		MinLogPerBuffer	64	Minimum log record size in bytes	The value must be either a multiple of the on-disk sector size or a size that fits evenly into the on-disk sector size.
		MaxLogPerBuffer	8192	Maximum log record size in bytes	This value cannot exceed 64000. The value must be a multiple of the on-disk sector size.
		RollbackChance	100	The chance that an in-memory operation will occur that causes a rollback operation to occur.	When this rollback operation occurs, SQL Server does not write to the log file.
		SleepAfter	5	Sleep time after each cycle, in milliseconds
		
	-- Audit User Selection
		- The SQLIOSim utility takes the values that you specify in the AuditUser section to simulate DBCC activity to read and to audit the information about the page. Validation occurs even if the value of the UserCount parameter is set to 0. 		
		Parameter	Default value	Description	Comments
		UserCount	2	Number of Audit threads	The value cannot exceed the following value:
		CPUCount*1023-100
		The total number of all users also cannot exceed this value. A value of 0 means that you cannot create random access users. A value of -1 means that you must use the automatic configuration of the following value:
		min(CPUCount*2, 8)
		NoteA SQL Server system may have thousands of sessions. Most of the sessions do not have active requests. Use the count(*) function in queries against the sys.dm_exec_requests DMV as a baseline for establishing this test parameter value.

		CPUCount here refers to the value of the CPUCount parameter in the CONFIG section.

		The min(CPUCount*2, 8) value results in the smaller of the values between CPUCount*2 and 8.
		BuffersValidated	64		
		DelayAfterCycles	2	Apply the AuditDelay parameter after the number of BuffersValidated cycles is completed	
		AuditDelay	200	Number of milliseconds to wait after each DelayAfterCycles operation
		
	-- ReadAheadUser section
		- The SQLIOSim utility takes the values that are specified in the ReadAheadUser section to simulate SQL Server read-ahead activity. SQL Server takes advantage of read-ahead activity to maximize asynchronous I/O capabilities and to limit query delays. 
		Parameter	Default value	Description	Comments
		UserCount	2	Number of read-ahead threads	The value cannot exceed the following value:
		CPUCount*1023-100
		The total number of all users also cannot exceed this value. A value of 0 means that you cannot create random access users. A value of -1 means that you must use the automatic configuration of the following value:
		min(CPUCount*2, 8)
		NoteA SQL Server system may have thousands of sessions. Most of the sessions do not have active requests. Use the count(*) function in queries against the sys.dm_exec_requests DMV as a baseline for establishing this test parameter value.

		CPUCount here refers to the value of the CPUCount parameter in the CONFIG section.

		The min(CPUCount*2, 8) value results in the smaller of the values between CPUCount*2 and 8.
		BuffersRAMin	32	Minimum number of pages to read per cycle	The minimum value is 0. The maximum value is limited by system memory.
		BuffersRAMax	64	Maximum number of pages to read per cycle	SQL Server Enterprise editions can read up to 1,024 pages in a single request. If you install SQL Server on a computer that has lots of CPU, memory, and disk resources, we recommend that you increase the file size and the read-ahead size.
		DelayAfterCycles	2	Apply the RADelay parameter after the specified number of cycles is completed	
		RADelay	200	Number of milliseconds to wait after each DelayAfterCycles operation
		
	-- BulkUpdateUser section
		- The SQLIOSim utility takes the values that you specify in the BulkUpdateUser section to simulate bulk operations, such as SELECT...INTO operations and BULK INSERT operations. 
		Parameter	Default value	Description	Comments
		UserCount	-1	Number of BULK UPDATE threads	The value cannot exceed the following value:
		CPUCount*1023-100
		A value of -1 means that you must use the automatic configuration of the following value:
		min(CPUCount*2, 8)
		NoteA SQL Server system may have thousands of sessions. Most of the sessions do not have active requests. Use the count(*) function in queries against the sys.dm_exec_requests DMV as a baseline for establishing this test parameter value.

		CPUCount here refers to the value of the CPUCount parameter in the CONFIG section.

		The min(CPUCount*2, 8) value results in the smaller of the values between CPUCount*2 and 8.
		BuffersBUMin	64	Minimum number of pages to update per cycle	
		BuffersBUMax	128	Maximum number of pages to update per cycle	The minimum value is 0. The maximum value is limited by system memory.
		DelayAfterCycles	2	Apply the BUDelay parameter after the specified number of cycles is completed	
		BUDelay	10	Number of milliseconds to wait after each DelayAfterCycles operation
		
	-- ShrinkUser section
		- The SQLIOSim utility takes the values that you specify in the ShrinkUser section to simulate DBCC shrink operations. The SQLIOSim utility can also use the ShrinkUser section to make the file grow. 
		Parameter	Default value	Description
		MinShrinkInterval	120	Minimum interval between shrink operations, in seconds
		MaxShrinkInterval	600	Maximum interval between shrink operations, in seconds
		MinExtends	1	Minimum number of increments by which the SQLIOSim utility will grow or shrink the file
		MaxExtends	20	Maximum number of increments by which the SQLIOSim utility will grow or shrink the file


