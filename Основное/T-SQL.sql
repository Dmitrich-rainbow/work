Литература:
1) Мартин Грабер. Введение в SQL
2) Джо Селко. Стиль программирования
3) Джо Селко. SQL для профессионалов

СУБД:
- Клиент-серверная
- Реляционная
- Многопользовательская

LTRIM() и RTRIM()

-- FORMAT (Sql Server 2012)
	- Возвращает значение, указанное в формате, языке и региональных параметрах (необязательно) в SQL Server 2012. Для выполнения форматирования значения даты, времени и чисел с учетом локали в виде строк используется функция FORMAT. Для общих преобразований типов данных продолжайте использовать CAST и CONVERT.
		SELECT FORMAT ( @d, 'd', 'en-US' ) AS 'US English Result'
		
-- Текущее время, можно прибавлять и отнимать дни простыми арифметическими знаками + -
GETDATE()
-- Получить дату без времени
SELECT CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 112)) --104/102
-- Формат даты/дата
HH:MIAM (or PM)	Default	SELECT CONVERT(VARCHAR(20), GETDATE(), 100)	Jan 1 2005 1:29PM 
MM/DD/YY	USA	SELECT CONVERT(VARCHAR(8), GETDATE(), 1) AS [MM/DD/YY]	11/23/98
MM/DD/YYYY	USA	SELECT CONVERT(VARCHAR(10), GETDATE(), 101) AS [MM/DD/YYYY]	11/23/1998
YY.MM.DD	ANSI	SELECT CONVERT(VARCHAR(8), GETDATE(), 2) AS [YY.MM.DD]	72.01.01
YYYY.MM.DD	ANSI	SELECT CONVERT(VARCHAR(10), GETDATE(), 102) AS [YYYY.MM.DD]	1972.01.01
DD/MM/YY	British/French	SELECT CONVERT(VARCHAR(8), GETDATE(), 3) AS [DD/MM/YY]	19/02/72
DD/MM/YYYY	British/French	SELECT CONVERT(VARCHAR(10), GETDATE(), 103) AS [DD/MM/YYYY]	19/02/1972
DD.MM.YY	German	SELECT CONVERT(VARCHAR(8), GETDATE(), 4) AS [DD.MM.YY]	25.12.05
DD.MM.YYYY	German	SELECT CONVERT(VARCHAR(10), GETDATE(), 104) AS [DD.MM.YYYY]	25.12.2015
DD-MM-YY	Italian	SELECT CONVERT(VARCHAR(8), GETDATE(), 5) AS [DD-MM-YY]	24-01-98
DD-MM-YYYY	Italian	SELECT CONVERT(VARCHAR(10), GETDATE(), 105) AS [DD-MM-YYYY]	24-01-1998
DD Mon YY 1	-	SELECT CONVERT(VARCHAR(9), GETDATE(), 6) AS [DD MON YY]	04 Jul 06 1
DD Mon YYYY 1	-	SELECT CONVERT(VARCHAR(11), GETDATE(), 106) AS [DD MON YYYY]	04 Jul 2006 1
Mon DD, YY 1	-	SELECT CONVERT(VARCHAR(10), GETDATE(), 7) AS [Mon DD, YY]	Jan 24, 98 1
Mon DD, YYYY 1	-	SELECT CONVERT(VARCHAR(12), GETDATE(), 107) AS [Mon DD, YYYY]	Jan 24, 1998 1
HH:MM:SS	-	SELECT CONVERT(VARCHAR(8), GETDATE(), 108)	03:24:53
Mon DD YYYY HH:MI:SS:MMMAM (or PM) 1	Default + 
milliseconds	SELECT CONVERT(VARCHAR(26), GETDATE(), 109)	Apr 28 2006 12:32:29:253PM 1
MM-DD-YY	USA	SELECT CONVERT(VARCHAR(8), GETDATE(), 10) AS [MM-DD-YY]	01-01-06
MM-DD-YYYY	USA	SELECT CONVERT(VARCHAR(10), GETDATE(), 110) AS [MM-DD-YYYY]	01-01-2006
YY/MM/DD	-	SELECT CONVERT(VARCHAR(8), GETDATE(), 11) AS [YY/MM/DD]	98/11/23
YYYY/MM/DD	-	SELECT CONVERT(VARCHAR(10), GETDATE(), 111) AS [YYYY/MM/DD]	1998/11/23
YYMMDD	ISO	SELECT CONVERT(VARCHAR(6), GETDATE(), 12) AS [YYMMDD]	980124
YYYYMMDD	ISO	SELECT CONVERT(VARCHAR(8), GETDATE(), 112) AS [YYYYMMDD]	19980124
DD Mon YYYY HH:MM:SS:MMM(24h) 1	Europe default + milliseconds	SELECT CONVERT(VARCHAR(24), GETDATE(), 113)	28 Apr 2006 00:34:55:190 1
HH:MI:SS:MMM(24H)	-	SELECT CONVERT(VARCHAR(12), GETDATE(), 114) AS [HH:MI:SS:MMM(24H)]	11:34:23:013
YYYY-MM-DD HH:MI:SS(24h)	ODBC Canonical	SELECT CONVERT(VARCHAR(19), GETDATE(), 120)	1972-01-01 13:42:24
YYYY-MM-DD HH:MI:SS.MMM(24h)	ODBC Canonical
(with milliseconds)	SELECT CONVERT(VARCHAR(23), GETDATE(), 121)	1972-02-19 06:35:24.489
YYYY-MM-DDTHH:MM:SS:MMM	ISO8601	SELECT CONVERT(VARCHAR(23), GETDATE(), 126)	1998-11-23T11:25:43:250
DD Mon YYYY HH:MI:SS:MMMAM 1	Kuwaiti	SELECT CONVERT(VARCHAR(26), GETDATE(), 130)	28 Apr 2006 12:39:32:429AM 1
DD/MM/YYYY HH:MI:SS:MMMAM	Kuwaiti	SELECT CONVERT(VARCHAR(25), GETDATE(), 131)	28/04/2006 12:39:32:429AM

--Некоторые полезные преобразования
set nocount on
declare @d datetime
set @d=convert(char(8),getdate(),112)
select 'Дата ',@d
 
select 'первый день месяца',
dateadd(day,1-day(@d),@d)
 
select  'последний день месяца',
dateadd(month,1,dateadd(day,1-day(@d),@d))-1
 
select 'первый день года',
dateadd(day,1-datepart(dayofyear,@d),@d),
convert(datetime,'1/1/'+convert(char(4),year(@d)),101)
 
select 'последний день года',
convert(datetime,'12/31/'+convert(char(4),year(@d)),101)
 

select 'первый день квартала',
convert(datetime,convert(varchar(2),(month(@d)-1)/3*3+1)+'/1/'+convert(char(4),year(@d)),101),
convert(datetime,convert(varchar(2),convert(varchar(2),(datepart(quarter,@d)-1)*3)+1)+'/1/'+convert(char(4),year(@d)),101)

 
select 'последний день квартала',
dateadd(month,3,convert(datetime,convert(varchar(2),(month(@d)-1)/3*3+1)+'/1/'+convert(char(4),year(@d)),101))-1
 
-- Вернуть понедельник переданной даты
	SET DATEFIRST 1
	DECLARE @d datetime = DATEADD(DAY,6, '2017-04-18')
	SELECT DATEADD(DAY, 1-DATEPART(WEEKDAY, @d), @d) 
 
print 'Русская нумерация дней недели'
SET DATEFIRST 1
select datepart(weekday,getdate())

go

declare @i int
declare @m char(2),@y char(4)
set @y='2002'

set nocount on
SET DATEFIRST 1
set @i=1
while @i <=12
begin
set @m=convert(char(2),@i)
select @i as Месяц, dateadd(d,
--Первое воскресенье месяца
7-datepart(dw,convert(datetime,@m+'/1/'+@y,101)), 
convert(datetime,@m+'/1/'+@y,101)) Первое
--Последнее воскресенье месяца
, dateadd(d,
7-datepart(dw,dateadd(m,1,convert(datetime,@m+'/1/'+@y,101))), 
dateadd(m,1,convert(datetime,@m+'/1/'+@y,101)))-7 Последнее
set @i=@i+1
end
go
-- Вариант, предложеный  SM
declare @m char(2),@y char(4)
select @y=convert(char(4),year(getdate()))

select @m=convert(varchar(2),month(getdate()))
DECLARE @firstWDay int
SET  @firstWDay=datepart(dw,convert(datetime,@m+'/1/'+@y,101))

DECLARE @FirstSunDay datetime
SET @FirstSunDay=dateadd(d,
CASE @firstWDay WHEN 1 THEN 0 ELSE 7-@firstWDay+1 END, 
convert(datetime,@m+'/1/'+@y,101))

DECLARE @lastWDay int
SET  @lastWDay=datepart(dw,dateadd(d,-1,dateadd(m,1, convert(datetime,@m+'/1/'+@y,101))))

DECLARE @lastSunDay datetime
SET @lastSunDay=dateadd(d,
CASE @lastWDay WHEN 1 THEN 0 ELSE -1 * @lastWDay + 1 END, 
dateadd(d,-1,dateadd(m,1, convert(datetime,@m+'/1/'+@y,101)))
)
SELECT @y, @FirstSunDay, @lastSunDay

-- Советы по работе с датами
- Используйте формат YYYYMMDD, чтобы он везде был воспринят правильно. Старые типа данных испольщуют YYYYDDMM(DATETIME и SMALLDATETIME). Новые - DATE,DATETIME,DATETIMEOFFSET
- Используйте вместо BETWEEN больше или меньшге
	WHERE col >= '20110101' AND col < '20120201'
	
-- Формат чисел
- см в SQL Server для профессионалов 201308

-- Разница в днях
DATEDIFF ( datepart , startdate , enddate )

-- День недели
	DATEPART(weekday,Погрузка.Дата)
		
		1 - Воскресенье
		2 - Понедельник
		...

-- CHARINDEX (возвращает(число) с какого символа начинается слово)
CHARINDEX ('hello',@string); -- 'hello' что ищем, @sring - где ищем 
CHARINDEX ('hello',@string,@n); -- @n с какого символа начинать поиск

-- SUBSTRING (выбирает произвольные символы)
SUBSTRING (@string,@start,@length); -- @string - где происходит поиск, @start - c какого символа начать выборку, @length - сколько символов выбрать

-- Количество символов с троке
SELECT LEN('Привет/мой/друг')-LEN(REPLACE('Привет/мой/друг','/',''))

-- NEWID и NEWSEQUENTIALID
	- Лучше использовать второе, так как там возможен порядок строк

-- Сортировка

	-- Произвольное значение/случайное значение
	
		SELECT TOP(1)* FROM test ORDER BY NEWID(); -- Плох тем, что каждоый строке будет присвоен NEWID()
		SELECT * FROM Products WHERE ProductID = (SELECT Ceiling(Count(*) * Rand()) FROM Products) -- Работает при условии что есть все значения от 1 до ... и нет удалённых номеров
		SELECT TOP(1) * FROM Products WHERE ProductID = (SELECT Ceiling(Count(*) * Rand()) FROM Products) -- Исключает возможность ошибки прошлого шага. Если надо более 1 строки, то между собой эти строки будут не уникальны, они будут идти последовательно
		SELECT * FROM Products TABLESAMPLE (100 Rows) -- Получить 100 строк, работает очень быстро. Сервер берёт страницу на физическом уровне и показывает результат. Проблема в том, что результат будет непредсказуемым, то есть вернёт от 0 до ... строк. Так же проблема может быть в том, что возвращает примерно одинаковые строки
	
	-- Основной способ, так как самый быстрый
	
		SELECT SELECT TOP(1) * FROM Products TABLESAMPLE (1000 Rows) ORDER BY NewID() -- Так можно устранить прошлые минусы, но тогда ухудшим скорость

-- Количество строк в таблице
	- SELECT Count(*) 
	- Узнать у системных представлений
	
-- Ожидание
WAITFOR DELAY '00:00:05'

-- Сбор строк в одну
	-- Объединение столбцов в строки(аналог GROUP_CONCAT в Mysql)
	(SELECT name +N';' as 'data()'
	FROM users
	WHERE id = 12
	for xml path('')) as names

	-- Позволяет вставить перенос строки корректно
		SELECT CHAR(13)+CHAR(10)+name FROM #output
			WHERE name IS NOT NULL
			FOR XML PATH(''),TYPE
			).value('.','NVARCHAR(MAX)'

Len()--длина строки
Left(Параметр, количество символов) --Вырезает левую часть строки
Right --Вырезает правую часть строки
IN (1,2,3,4,5) --Перечисляем все необходимые параметры перебота

BETWEEN 1 AND 5 --Всё от 1 до 5
	- https://sqlblog.org/2011/10/19/what-do-between-and-the-devil-have-in-common
1997-6-1 --Дата
Month()
RAND() -- Возвращает псевдослучайное значение типа float от 0 до 1
REPLICATE('zzz',3) -- Повторить значение произвольное количество раз. Результат - zzzzzzzzz

-- SET ROWCOUNT 4
	- После какого количества строк закончить обработку вывода
	- Чтобы отключить SET ROWCOUNT 0

-- NOCOUNT
	Если инструкция принимает значение ON, то количество строк (которые обработаны инструкцией Transact-SQL) не возвращается. Запрещает всем инструкциям хранимой процедуры отправлять клиенту сообщения DONE_IN_PROC. Если запросы выполняются из программы, то в результирующем наборе таких инструкций Transact-SQL как: SELECT, INSERT, UPDATE и DELETE значение: “nn rows affected” (строк обработано: nn) отображаться не будет. Для хранимых процедур с несколькими инструкциями, не возвращающих большое количество строк данных, это может значительно повысить производительность за счет существенного снижения объема сетевого трафика. Инструкция SET NOCOUNT устанавливается во время исполнения, а не на этапе синтаксического анализа.

-- QUOTED_IDENTIFIER
	ON по умолчанию. Идентификаторы можно заключать в двойные кавычки, а литералы должны быть разделены одинарными кавычками. Все строки, разделенные двойными кавычками, рассматриваются как идентификаторы объектов. Если в именах объектов базы данных используются зарезервированные ключевые слова, то параметру SET QUOTED_IDENTIFIER должно быть присвоено значение ON. При создании или изменении индексов в вычисляемых столбцах или индексированных представлениях параметру SET QUOTED_IDENTIFIER должно быть присвоено значение OFF. Драйвер ODBC и поставщик OLE DB для собственного клиента SQL Server при соединении автоматически присваивают параметру QUOTED_IDENTIFIER значение ON. По умолчанию параметр SET QUOTED_IDENTIFIER имеет значение OFF для соединений из приложений DB-Library. Когда создается хранимая процедура, параметры SET QUOTED_IDENTIFIER и SET ANSI_NULLS фиксируются и используются для последующих вызовов этой хранимой процедуры. При выполнении операций внутри хранимой процедуры значение SET QUOTED_IDENTIFIER не меняется. Если параметр SET ANSI_DEFAULTS имеет значение ON, параметр SET QUOTED_IDENTIFIER включается. Параметр SET QUOTED_IDENTIFIER устанавливается во время синтаксического анализа. Настройка на время синтаксического анализа означает, что если инструкция SET присутствует в пакете или хранимой процедуре, она выполняется вне зависимости от того, достигает ли выполнение кода фактически этой точки. Кроме того, инструкция SET выполняется до выполнения любых инструкций.

-- ANSI_NULLS
	Стандарт SQL-92 требует, чтобы операторы “=” и “<>” при использовании со значениями NULL всегда возвращали FALSE. SQL Server интерпретирует пустую строку как один пробел или действительно пустую строку в зависимости от настройки уровня совместимости. Директива SET ANSI_NULLS ON влияет только на сравнения, где в качестве одного из операндов используется NULL в виде переменной или литеральной константы. Если оба операнда представляют собой столбцы или составные выражения, эта настройка не влияет на результат сравнения. Для хранимых процедур SQL Server использует значение настройки SET ANSI_NULLS, которое действовало в момент создания процедуры. Значение SET ANSI_NULLS должно быть равно ON при выполнении распределенных запросов. SET ANSI_NULLS также должно быть ON при создании или изменении индексов вычисляемых столбцов или индексированных представлений (это один из семи обязательных для этого параметров директивы SET: ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, QUOTED_IDENTIFIER и CONCAT_NULL_YIELDS_NULL должны иметь значение ON, а параметр NUMERIC_ROUNDABORT – значение OFF). Драйвер ODBC и поставщик OLE DB собственного клиента SQL Server при соединении автоматически устанавливают параметру ANSI_NULLS значение ON. Для соединений из приложений DB-Library значением по умолчанию для параметра SET ANSI_NULLS является OFF. Установка значения SET ANSI_NULLS происходит во время запуска или выполнения, но не во время синтаксического анализа.

-- ANSI_WARNINGS
	Формирует предупреждающее сообщение, если значения NULL появляются в статистических функциях: SUM, AVG, MAX, MIN, STDEV, STDEVP, VAR, VARP или COUNT. Инструкции INSERT или UPDATE, выполнение которой привело к ошибке деления на ноль или арифметического переполнения, в соответствии со стандартом SQL-92 будут откачены и сформировано сообщение об ошибке. Конечные пробелы игнорируются для символьных столбцов, а конечные значения NULL игнорируются для бинарных столбцов. Значение ANSI_WARNINGS игнорируется при передаче аргументов хранимой процедуре или пользовательской функции, а также при объявлении и настройке переменных в инструкции пакетных заданий. Например, если объявить переменную как char(3), а затем присвоить ей значение длиннее трех символов, данные будут усечены до размера переменной, а инструкция INSERT или UPDATE завершится без ошибок. Параметр SET ANSI_WARNINGS должен иметь значение ON при создании или изменении индексов, основанных на вычисляемых столбцах или индексированных представлениях. Параметр ANSI_WARNINGS должен быть установлен в ON для выполнения распределенных запросов. Драйвер ODBC собственного клиента и поставщик OLE DB для собственного клиента SQL для SQL Server при соединении автоматически устанавливает параметр ANSI_WARNINGS в значение ON. Параметр SET ANSI_WARNINGS устанавливается во время выполнения, а не во время синтаксического анализа. Если значение параметра SET ARITHABORT или SET ARITHIGNORE установлено в OFF, а значение параметра SET ANSI_WARNINGS установлено в ON, то SQL Server возвращает сообщение об ошибке при обнаружении ошибок деления на ноль и переполнения.

-- ANSI_PADDING
	Контролирует способ хранения значений, которые короче, чем заданный размер поля, а также способ хранения в полях типов: char, varchar, binary и varbinary таких значений, которые имеют оконечные пробелы. Производитель рекомендует ON. Значение параметра инструкции SET ANSI_PADDING не оказывает влияния на значения типа nchar, nvarchar, ntext, text, image, а также на большие значения, для которых SET ANSI_PADDING всегда ON. Это означает, что оконечные пробелы и нули не отбрасываются. SET ANSI_PADDING ON необходимо при создании или изменении индексов по вычисляемым столбцам или индексированным представлениям. Драйвер ODBC и поставщик OLE DB для собственного клиента SQL Server при соединении автоматически устанавливают параметр ANSI_WARNINGS в значение ON. Значение параметра SET ANSI_PADDING устанавливается во время выполнения или запуска, а не во время синтаксического анализа.

-- ARITHABORT
	Ошибка в транзакции приведёт к её откату, а не к предупреждению. Если параметры SET ARITHABORT и SET ANSI WARNINGS установлены в ON, ошибка приведёт к завершению запроса. Если SET ARITHABORT ON а SET ANSI WARNINGS OFF, ошибка прервёт пакет. Установка параметра SET ARITHABORT происходит при запуске или во время исполнения, но не во время синтаксического анализа. SET ARITHABORT ON необходимо при создании или изменении индексов по вычисляемым столбцам или индексированным представлениям.

-- XACT_ABORT
	Если произошла ошибка при исполнении инструкции Transact-SQL, транзакция будет откачена целиком. Инструкция SET XACT_ABORT не влияет на компиляцию ошибок (например, синтаксических). Параметр XACT_ABORT должен иметь значение ON для инструкций изменения данных в явных или неявных транзакциях, применяющихся к большинству поставщиков OLE DB, включая SQL Server. Единственным случаем, когда этот параметр не требуется, является поддержка поставщиком вложенных транзакций. Дополнительные сведения см. в разделе Распределенные запросы и распределенные транзакции. Значение параметра XACT_ABORT устанавливается во время выполнения, а не во время синтаксического анализа. Включение этого параметра позволяет не заботиться об обработке ошибок при вставках и изменениях.

-- CONCAT_NULL_YIELDS_NULL
	При этой установке, сцепление значения NULL со строкой дает в результате NULL. Настройка SET CONCAT_NULL_YIELDS_NULL устанавливается во время выполнения или запуска, но не во время синтаксического анализа. SET CONCAT_NULL_YIELDS_NULL ON необходимо при создании или изменении индексов по вычисляемым столбцам или индексированным представлениям.

--	NUMERIC_ROUNDABORT
	Потеря точности не приводят к формированию сообщений об ошибках, а результат округляется с точностью столбца или переменной, в которых будет сохранен. Потеря точности происходит, когда выполняется попытка сохранения значения с фиксированной точностью в столбце или переменной с меньшей точностью. Если параметру SET NUMERIC_ROUNDABORT присвоено значение ON, параметр SET ARITHABORT определяет серьезность формируемой ошибки. В следующей таблице показано влияние этих двух параметров на сообщения об ошибках при потере точности. Значение параметра SET NUMERIC_ROUNDABORT задается на этапе выполнения или запуска, но не на этапе синтаксического анализа. При создании или изменении индексов вычисляемых столбцов или индексированных представлений параметр SET NUMERIC_ROUNDABORT должен принимать значение OFF.

-- Общие рекомендации
	1. Избегите использования звёздочки (*) в SELECT, всегда перечисляйте только необходимые столбцы.
	2. В инструкции INSERT всегда указывайте имена столбцов.
	3. Всегда присваивайте таблицам (а при необходимости и столбцам) псевдонимы – это позволяет избежать путаницы. При использовании псевдонима столбца обязательно добавляйте ключевое слово AS.
	4. При ссылке на объект всегда указывайте схему (владельца).
	5. Избегите использования non-SARGable предикатов (“IS NULL”, “<>”, “!=”, “!>”, “!<“, “NOT”, “NOT EXISTS”, “NOT IN”, “NOT LIKE”, “LIKE ‘%500′”, CONVERT и CAST, Строковые функции: LEFT(Column,2) = ‘GR’ , Функции даты/времени: DATEPART (mm, Datecolumn) = 5, Математические операции со столбцом: qty+1> 100 ).
	6. Для сокращения числа итераций старайтесь по возможности использовать строчный оператор CASE. Например:

	select sum(case when e.age < 20 then 1 else 0 end) as under_20

			, sum(case when e.age >= 20 and age <= 40 then 1 else 0 end) as between_20_40

		   , sum(case when e.age > 40 then 1 else 0 end) as over_40

	from dbo.employee e

	7. Используйте индексы. Что бы понять, работает ли индекс, всегда проверяйте планы исполнения разрабатываемых запросов.
	8. Используйте формат даты по стандарту ISO – yyyymmdd или ODBC – yyyy-mm-dd hh:mi:ss
	9. Используйте ANSI стиль соединений. Для левых соединений опускайте ключевое слово OUTER.
	10. Для форматирования кода используйте стандартный размер табуляции – четыре символа, и отделяйте логически независимые модули кода пустой строкой.
	11. Старайтесь не использовать недокументированные средства.
	12. Если важна безопасность, не используйте динамический SQL.
	13. Порядок сортировки задавайте только предложением ORDER BY.
	14. Старайтесь хранить скрипты объектов схемы и серверного кода в системе управления версиями (например: VSS или CVS), и включать теги редакций в блок описания назначения скрипта.
	15. Всегда располагайте все DLL команды в начале кода, дабы избежать лишних компиляций.
	16. Избегите использования триггеров и курсоров, оставьте эти инструменты на крайний случай, когда по-другому задачу решить невозможно. Если пришлось писать курсор, предпочтение отдавайте локальным, в режиме: FAST_FORWARD, они самые диетические из всех остальных.
	17. Для повышения производительности соединений, когда ничего другого уже не помогает, используйте индексированные представления соединяемых точно таким же образом таблиц (в не Enterprise редакциях нужно добавлять подсказку NOEXPAND).
	18. Следует помнить, что представления могут маскировать необходимые для оптимизации метаданные, например, когда они скрывают соединения/объединения таблиц из разных баз данных, или когда не задействованы используемые для внутреннего соединения столбцы. В подобных случаях, всегда проверяйте план исполнения запроса, что бы вовремя принять меры по исправлению ситуаций с не оптимальным планом запроса.
	19. Старайтесь делать определяемые пользователем функции детерминированными, они дают более эффективные планы исполнения.
	20. Никогда не используйте в именах процедур префикс “sp_”, он зарезервирован для системных процедур, которые вначале ищутся в базе master.

-- Неявное преобразование типов/implicit conversion
	- Если оператор связывает два выражения различных типов данных, то по правилам приоритета типов данных определяется, какой тип данных имеет меньший приоритет и будет преобразован в тип данных с большим приоритетом. Если неявное преобразование не поддерживается, возвращается ошибка. Если оба операнда выражения имеют одинаковый тип данных, результат операции будет иметь тот же тип данных. В SQL Server 2005 используется следующий приоритет типов данных:

	1. определяемые пользователем типы данных (высший приоритет);
	2. sql_variant;
	3. xml;
	4. datetime;
	5. smalldatetime;
	6. float;
	7. real;
	8. decimal;
	9. money;
	10. smallmoney;
	11. bigint;
	12. int;
	13. smallint;
	14. tinyint;
	15. bit;
	16. ntext;
	17. text;
	18. image;
	19. timestamp;
	20. uniqueidentifier;
	21. nvarchar;
	22. nchar;
	23. varchar;
	24. char;
	25. varbinary;
	26. binary (низший приоритет).
	
	-- Проблемы
		1. SQL Server будет вынужден сделать Scan вместо Seek. Возможно на первом операторе будет ворнинг (SQL Server 2012)
		
	-- Рекомендации
		1. Либо очень внимательно смотреть за приложением, либо использовать int и nvarchar

-- Существование временной таблицы
	if object_id('tempdb..#WWWHotel') is null
	if object_id('tempdb..#WWWHotel') is not null drop table #tmpTable

	SET NOCOUNT ON -- Отменить отчёт сервера о количестве обработанных строк, сильно уменьшает сетевой трафик

--Пробел в строке (возврат_каретки+перевод_строки)
	+char(10)+char(13)
	- Так же может быть CHAR(32), CHAR(160)

-- Поиск символов/Разбор строки на символы
	declare @s varchar(300) = 'http://censored.ru/hotel/the-beach-house-at-iruveli-maldives-5-deluxe /'

	;with nums as
	(
	select v3.n*8*8 + v4.n*8 + v5.n + 1 as n
	from 
		 (values (0),(1),(2),(3),(4),(5),(6),(7))v3(n),
		 (values (0),(1),(2),(3),(4),(5),(6),(7))v4(n),
		 (values (0),(1),(2),(3),(4),(5),(6),(7))v5(n)
	where v3.n*8*8 + v4.n*8 + v5.n < len(@s))


	select n, SUBSTRING(@s, n, 1), ASCII(SUBSTRING(@s, n, 1))
	from nums 

-- Включить Сервис брокера
USE msdb;--в msdb нужно активировать для отправки почты
GO
ALTER DATABASE msdb SET ENABLE_BROKER 

-- Размер таблиц
use Database
go
select object_name(id) tbl, indid ,
reserved/128. as reserv, 
dpages/128. as data,
(reserved - dpages)/128. as delta from sysindexes
where indid in (0,1)
order by 4 desc

-- Распарсить/разобрать строку
Declare @string nvarchar(255);
SET @string = ',10,20,100,30,40,9999,456714,445,';
Declare @n int;
SET @n = 1;
DECLARE @Current int
DECLARE @Current2 int
DECLARE @Result int

WHILE @n < LEN(@string)
BEGIN
SET @Current = CHARINDEX(',',@string,@n)+1; -- Берём первый символ и прибаляем 1, чтобы смотреть на данные
SET @Current2 = CHARINDEX(',',@string,@Current); -- Ищем следующий символ

IF @Current2 = 0 -- Необходимо, чтобы устранить "переполнение"
Return;

SET @Result = @Current2-@Current; -- Получем нужное количество символов, которое надо выбирать

SELECT SUBSTRING(@string,@Current,@Result); -- Выбираем нужные данные
SET @n = @n + @Result+1; -- Переходим к следующему символу
END

--
UNION --Соединяет 2 таблицы(A+B). Изначально считай с DISTINCT Есть ещё UNION ALL - Показать все дублицаты
SELECT 1,1
FROM ol
UNION
SELECT 2,2
FROM al

INTERSECT --Пересечение
EXCEPT --Где A - B

--Порядок выполнения запросов
WHERE > GROUP BY+Aggregation>HAVING>DISTINCT>UNION>ORDER BY>TOP
	
	-- Полный список
		FROM
		ON
		JOIN
		where
		GROUP BY
		WITH CUBE или WITH ROLLUP
		HAVING
		SELECT
		DISTINCT
		ORDER BY
		TOP

--Права доступа:
GRANT - даёт права
	GRANT SELECT -- На что даём
	ON Employees -- На какой объект
	TO Onegin -- Кому
	WITH GRANT OPTION -- Если надо дать возможность раздавать права на SELECT... (то, что указано в GRANT)
REVOKE - вернуть права
DENY - отклонить

- Посмотреть права
	sys.Server_Principals -- Все кому можно дать права
	sys.Database_Principals -- Субъекты уровня базы
	sys.Server_Permissions -- Какие права кому выданы уровня сервера
	sys.Database_Permissions -- Какие права кому выданы уровня базы


--Подзапрос:
1) Список чего я хочу видеть в результате?
2) Как только наткнулись на нехватку данных: "А в какой таблице эти данные лежат?"
SELECT 1, (SELECT ... FROM ... WHERE IN (....)) FROM

Шаги через 'Подзапросы', которые гарантированно приведут к нужному результат:
1) Список чего я хочу видеть в результате
2) Как только появиалсь нехватка данных > А в какой таблице они лежат, после чего начинаем обращаться к ней
Чтобы делать подзапрос к запросу, все столбцы должны иметь имя и сам запрос то же.

--JOIN:
	1) Нужно переджойнить все таблицы, которые упомянуты в задаче.
	2) Отфильтровать те пары, которые не имеют связи в реальной жизни.
	3) Задать вопрос: "Список, что я получил, что это?"(Если скажем заказ в этот список попал, то больше он сюда не упадёт, это значит я получил Список заказо) 
	4) Группировка
--Ошибки JOIN:
	1) Есть строки, которые не могут найти себе пары в другой таблице и выпадают. Решение(поставить LEFT JOIN или RIGHT JOIN).JOIN отбрасывает 0 значения
	2) Не делать Count(*) Совместо с LEFT и RIGHT JOIN. Писать надо примерно так Count(O.OrderID)
	2.1) Если начали ставить LEFT и RIGHT JOIN, то ведём их до конца.
	3) При использовании LEFT,FULL и RIGHT JOIN, может возникнуть ситуация, когда фильтруем по полям из одной таблицы, а складываем поля из другой таблицы, тогда велика вериятность что мы складываем не то, что фильтруем
	Решение: Не надо использовать без необходимости LEFT и RIGHT JOIN.1) Можно поставить скобочки, 2) Или закрутить JOIN в обратном направлении. Первый способ эффективнее
	CROSS JOIN --Столбцы(X+Y), строки (X*Y). Условие записываетсяв WHERE
	INNER JOIN ON --Столбцы(X+Y), строки (X*Y). Только фильтруем во время JOIN, после ON
	LEFT JOIN ON -- Есть ли строки в левой таблице, которые не подошли по условию. Он их сохраняет.
	RIGHT JOIN ON -- Спасает строки из правой таблицы
	FULL JOIN ON -- Спасает и левые и правые строки. Null будет с обеих сторон 

-- Логический порядок выполнения операторов
	from>ON>JOIN>where>GROUP BY>WITH CUBE или WITH ROLLUP>HAVING>SELECT>DISTINCT>ORDER BY>TOP

	INSERT --Первое видео 4:15:00
	INTO      Stores(Stor_ID,Stor_Name)
	VALUES (1234,'sthrhjstj')

-- Вставка результата процедуры в таблицу
INSERT #test EXEC myproc

-- Update
UPDATE Stores
SET		  Stor_Name='gershshj'
WHERE  Stor_ID=144

-- OUTPUT (Ссылка на вставленные и удалённые данные)
	UPDATE MyTable SET my = 10 WHERE id = 7
	OUTPUT -- Выносим данные на ружу
	inserted.my, -- Получаем то, что будет после обновление поля
	deleted.my -- Получаем то, что было до обновления поля
	INTO #t1 -- тут или временная таблица или табличная переменная
	
	DELETE...OUTPUT -- Работает так же как и UPDATE, через табличную переменную
	INSERT...OUTPUT -- Можно вывести без табличной переменной

-- DELETE
	DELETE--Удаляет строки
	FROM    Store
	WHERE  Store_ID=1244

PIVOT -- Превращение столбцов с троки
SELECT ShipCountry,[1996],[1997],[1998]
FROM	  (
              SELECT Year(OrderDate) AS MyYear, ShipCountry, OrderID
              FROM    Orders
              ) MyTable
PIVOT    (
              Count(OrderID) FOR MyYear IN ([1996],[1997],[1998])
              ) Myreport
              
UNPIVOT -- Обратная операция. Функция группировку не убирает

Replace -- заменить в Title все буквы а, на буквы о
UPDATE Titles
SET		  Title=Replace(Title,'a','o')

Round (параметр, сколько знаков после запятой)--Округление
LIKE '%a%' --Есть буква а где угодно(WHERE Title LIKE '%a%b%')
TOP(3) --Первые 3. Пишем в SELECT (SELECT TOP(3)....)
TOP(3) WITH TIES --Если кто-то с одинаковым параметром вылетел, то он добавится в результат и будет не топ 11, а более
DISTINCT --Отбрасывает повторяющиеся строки

ISNULL(что выводим, чем заменяем) --Третьего параметра вводить нельзя. Это не стандартная функция SQL
Coalesce(что выводим, чем заменяем,чем заменяем...) --Сколько угодно замен, если предыдущий NULL. Это стандартная функция SQL
CAST (@Var as varchar(100)) --Сменить тип файла 

-- NULL
	- IS NULL --Если значение NULL
	- IS NOT NULL --Если значение не NULL
	- Запрос выполняемый поиск по <> Black, не учтёт NULL
	- CONSTRAINT при проверке значений использует понятие не FALSE, а NULL не является ни FALSE ни TRUE, поэтому будет вставлено. То есть NULL нужно описать в CONSTRAINT

-- LIKE
	- [1-9] -- найти символ от 1 до 9
	- [^5-7] -- найти где данный символ не в диапазоне от 5 до 7
	- [%] -- Найти символ %
	- _ -- любой один символ
	- '%тест%' -- найти слово или его часть, где есть фраза 'тест'
	- Примеры:
		WHERE Title LIKE '%a%b%' -- Где в Title сначала идёт буква 'a', потом любое количеством символов
								 --	и буква 'b', потом опять любое количество символов
		WHERE Title like '% eb[0-9][0-9]%' AND Note not Title '%[%]%' -- Где Title содержит пробел eb и две
													--	цифры от 1 до нуля потом любые символы и не содержит %

	ALTER - изменить
	CREATE - создать
	DROP - удалить
	RAISERROR - указывает/передаёт ошибку
	
	-- Оптимизация
		1. При необходимости искать %value%, нужно рассмотреться возможность использования бинарного Collation (все значения UPPER или LOW), до 3х раз быстрее

-- Временная таблица и табличная переменная
	- http://stackoverflow.com/questions/11857789/when-should-i-use-a-table-variable-vs-temporary-table-in-sql-server
	- http://dba.stackexchange.com/questions/16385/whats-the-difference-between-a-temp-table-and-table-variable-in-sql-server/16386#16386

	
--Подытог(WITH ROLLUP) - подытоги слева на право
SELECT      EmployeeID,Year(OrderDate),ShipCountry,Count(*)
FROM		   Orders
GROUP BY EmployeeID,Year(OrderDate),ShipCountry WITH ROLLUP --подытог для всех полей
--Подытог (WITH CUBE) - подытоги и слева на право и справа на лево
--Функция Grouping. Выдаёт либо 0(значение из базы), либо 1(подытог)
SELECT      EmployeeID,Year(OrderDate),ShipCountry,Count(*),
				   Grouping(Year(OrderDate)),Grouping(ShipCountry)
FROM		   Orders
GROUP BY EmployeeID,Year(OrderDate),ShipCountry WITH ROLLUP

-- Постраничный вывод результатов
- До SQl 2012
	- Ранжирующие функции
	- SELECT с запоминанием текущей страницы в приложении
	- Пример
	1. SQL 2000
	DECLARE @currentRow int = 0 -- Запоминание в приложении. В текущем варианте это дата
	SELECT TOP(10) * FROM Products WHERE OrderDate > @currentRow  ORDER BY OrderDate
	2. SQL 2005
	WITH MyScroller
	AS (
	SELECT *, Row_Number() OVER (ORDER BY OrderDate) as num FROM Products  -- Появляется доп. стоблец нумерации, по
																		   -- которому можно бегать
	)
	SELECT * FROM MyScroller WHERE num BETWEEN 41 AND 50 ORDER BY OrderDate
	
- В SQL 2012 (OFFSET...FETCH)
	- OFFSET сколько строк надо пропустить от начала (обязательное поле)
	- FETCH сколько строк выводить
	- Пример:
	SELECT * FROM Products ORDER BY OrderDate OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY

-- Оконная агрегация (нарастающий итог)
- До SQL 2012	
	- Курсор (курсор, переменные (складываем текущую сумму и прошлый, нарастающий итог) и временная таблица,
	  вставляем результаты в неё)
	- Соединения с множественным перебором строк (JOIN, подзапрос)
	
- В SQL 2012 (Агрегация применяя к какому-то Диапазону(окну) через OVER())
	- UNBOUNDED PRECEDING все предыдущие строки
	- CURRENT ROW текущая строка
	- 10 PRECEDING - 10 предыдущих
	- 10 FOLLOWING - 10 последующих
	- Пример:
	SELECT OrdeDate,SalesAmount,
	SUM(SalesAmount) OVER (ORDER BY OrdeDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
	AVG(SalesAmount) OVER (ORDER BY OrdeDate ROWS BETWEEN 10 PRECEDING AND 10 FOLLOWING)
	FROM Products
	
-- Перебор результирующего набора (обращение к предыдущей и последующей строке)
- До SQL 2012
	- Курсоры
	- Соединение таблицы самой с собой

- В SQL 2012
- Lag (последующая строка). Lag ('Какое поле искать', 5, 'Чем заменить отсутствующие значения') 5 - сколько позиций назад
- Lead (предыдущая строка). Lead ('Какое поле искать', 5, 'Чем заменить отсутствующие значения') 5 - сколько позиций вперед
	- Пример:
	SELECT OrdeDate,SalesAmount,
	Lag (SalesAmount) OVER (OrdeDate), -- OVER указывать серверу что считать следующим, а что предыдущим
	Lead (SalesAmount) OVER (OrdeDate),
	SalesAmount - Lag (SalesAmount) OVER (OrdeDate) -- Посчитать, ростёт/уменьшается ли выручка
	FROM Products

-- Последовательности (работа с суррогатными ключами)
- Автоинкремент. Проблемы:
	- Механизм противоестественный для реляционной модели
	- Если после добавления значения, нужно сразу что-то сделать с этим значением, то надо использовать
	
	  -- SELECT @@Identity
		(других пользователей мы не видим), но если на таблице висит триггер, который делает INSERT в другую таблицу, то мы получим другой автоинкремент. 
	  
	  -- Scope_Identity() 
		возвращает автоинкремент не только на моём соединении, но и в нашем програмном модуле для любой таблицы, но только в определённой области видимости (батч, триггер, процедура), триггеры не влияют на него. Если вызов был через процедуру, то мы не увидим значения
	  
	  -- IDENT_CURRENT()
		Возврат последнего значения идентификатора, созданного для указанной таблицы или представления. Последнее созданное значение идентификатора может относиться к любому сеансу и любой области.
			SELECT IDENT_CURRENT('dbo.Target') 
	  
	  
	- Хочу вставить своё значение, которое не нарущает последовательности, но сервер не даст это сделать,
	  без спец. указаний (SET IDENTITY_INSERT Orders ON)

	  
- В SQL 2012
	- Такие генерации ключей работают быстрее автоинкремента
	- Генерируем отдельно, а использовать отдельно. Можно найти Programmability>Sequements
	- Используем
	SELECT Next VALUE FOR MySequence -- Берём следующее значение
	
--Ранжирующие функции:
Row_Number() OVER (пишем по какому полю нумеровать поля(11,12,13)) . Условия для него записать в WHERE нельзя, поэтому необходим подзапрос.
Rank() OVER (пишем по какому полю нумеровать поля, если поля одинаковые то они получаю одинаковый номер. Но дальнейшая нумерация продолжится как будто были разные номера(11,11,13)) 
Dense_Rank() OVER(пишем по какому полю нумеровать поля, если поля одинаковые то они получаю одинаковый номер(11,11,12)) 
nTile(количество групп) OVER (пишем по какому полю нумеровать поля) - При этом будет всего 3 нумерации. Делит на 3 равные части, если nTile(3)
Так же в OVER можно добавить PARTITION BY поле, по которому они будут разбиваться и для каждоый разбивки нумерация будет своя. Пример:
SELECT ProductName, CategoryID, UnitPrice
              Row_Number( ) OVER (
                                                 PARTITION BY CategoryID
												ORDER BY UnitPrice DESC
												)
FROM     Products
ORDER BY CategoryID, UnitPrice DESC

SELECT *
FROM    (
			  SELECT ProductName, CategoryID, UnitPrice
							Row_Number( ) OVER (ORDER BY UnitPrice DESC) AS Num											)
			   FROM     Products
			   ) MyTable
WHERE Num BETWEEN 31 AND 40

Универсальная функция для разбивки вывода результата по страницам(универсальный скроллер):
DECLARE @Page int=5, @PageSize int=7
SELECT *
FROM    (
			  SELECT ProductName, CategoryID, UnitPrice
							Row_Number( ) OVER (ORDER BY UnitPrice DESC) AS Num											)
			   FROM     Products
			   ) MyTable
WHERE Num BETWEEN (@Page -1)*@PageSize+1 AND @Page*@PageSize


--Транзакция(неделимые, связанные операции):

SET XACT_ABORT ON --Отменить всю транзакцию, а не последнюю операцию
BEGIN TRANSACTION
		UPDATE Titles
		SET        Price = Price -1
		WHERE Title_ID = 'lol1'
		
		UPDATE Titles
		SET        Price = Price +1
		WHERE Title_ID = 'lol2'
COMMIT TRANSACTION

Если не написать COMMIT TRANSACTION, то можно отменить оперцию с помощью ROLLBACK, то есть откат транзакции
Есть 3 режима работы Транзакций:
1) AutoCOMMIT --Каждый оператор начало и конец(COMMIT) транзакции. Работает всегда(автокоммит)
2) Explicit_transactions --Когда мы пишем BEGIN TRANSACTION(явные транзакции)
3)SET Implicit_transactions --Сервер за нас делает BEGIN, но не делает COMMIT(неявные транзакции)

-- REVERT
	- Переключает контекст выполнения в контекст участника, вызывавшего последнюю инструкцию EXECUTE AS.
	- Сбрасывает EXECUTE AS LOGIN = 'Paul', на те, с которыми подключился

Объявление переменных:
DECLARE @Var int --Момжно объявлять переменные через запятую
SET @Var = 5 (При SET можно брать любое значение, кроме как из таблицы)
SELECT @Var=COUNT(*)
FROM Orders
если @@ это системные пеменные (например @@Version)

--Оператор ветвления:
DECLARE @Var int
SET @Var = 5
IF @Var>3
	IF @Var<7
	SELECT '1'
ELSE--Всегда относится к самому внутреннему IF
	SELECT '2'
	
--Операторные скобки:
--Если сделать
IF...
SELECT 1
SELECT 1
SELECT 1
--К IF отнесётся только первый оператор


IF...
BEGIN
...
END

--Циклы:
WHILE @Var >0
BEGIN
...
END

--CASE
SELECT ProductName, CASE CategoryID
										WHEN 1 THEN UnitPrice*1.1
										WHEN 2 THEN UnitPrice*1.2									
										WHEN 3 THEN UnitPrice*1.3	
									ELSE UnitPrice*1.4
									END AS Price2,
									CASE
										 WHEN CategoryID=1 AND UnitPrice < 20 THEN UnitPrice*1.1
										 WHEN CategoryID=1 AND UnitPrice < 20 THEN UnitPrice*1.2
										 ELSE UnitPrice*1.3
								    END
FROM Products									
WHERE CASE 	CategoryID
				WHERE 1 THEN UnitPrice*1.1
				WHERE 2 THEN UnitPrice*1.15
				ELSE UnitPrice*1.2
			  END >200


--Динамические запросы(Сначала формируем один запрос и потом он выполняется):
DECLARE @Column varchar(100)
SET @Column = 'UnitPrice'
EXECUTE		('SELECT '+@Column+' FROM Products')

DECLARE @Column varchar(100)
SET @Column = 'UnitPrice'
DECLARE @MyQuary varchar(MAX)
SET @MyQuary='SELECT '+@Column+' FROM Products'
EXECUTE		(@MyQuary)

-- exec для переменной, будет помещено значение
DECLARE @a nvarchar(max)
SET @a = 'Hello'
exec('select * from Names where Name = '''+@a+'''')

-- exec и like
exec('select * from Names where Name like ''%Hello%''')
exec('select * from Names where Name like ''%'+@a+'%''') 

-- Замена функции AVG()/Среднее значение
	- AVG минусы:
		1. Не даёт реального представления о распределении значений в множественным
		2. Неустойчивая величина (легко поддаётся колебаниям)
	- AVG не всегда верно вычисляет среднее арифметическое, потому что числа могут сильно отличаться. Поэтому вместо неё лучше использовать PERCENTILE_CONT, но данная функция трудоёмка для сервера и для записи, не везде её получится использовать
	  SELECT TOP(1) PERCENTILE_CONT(0.5) -- SQL Server 2012
		  WITHIN GROUP (ORDER BY Зарплата)
		  OVER()
		  AS Медиана
	  FROM Сотрудники
		- Недостатки медианы:
			1. 

--Курсор(замена массиву)/CURSOR
DECLARE MyCursor CURSOR FOR
	SELECT ProductName, UnitPrice
	FROM Products
	ORDER BY UnitPrice DESC
OPEN MyCursor --показывается курсор
	FETCH NEXT FROM MyCursor
	FETCH NEXT FROM MyCursor
	FETCH NEXT FROM MyCursor
CLOSE MyCursor --удаляется из отображения, обязательно, иначе место на жёстком диске заполнится
DEALLOCATE MyCursor --Удаляет напоминание о курсоре

--Универсальный запрос:
DECLARE @Name varchar(100), @Price money
DECLARE MyCursor CURSOR FOR
	SELECT ProductName, UnitPrice
	FROM Products
	ORDER BY UnitPrice DESC
OPEN MyCursor
	FETCH NEXT FROM MyCursor INTO @Name, @Price
WHILE @@FETCH_STATUS = 0
    BEGIN
--    PRINT @Name--выводит одно значение
    SELECT @Name, @Price
	FETCH NEXT FROM MyCursor INTO @Name, @Price
	END
CLOSE MyCursor
DEALLOCATE MyCursor

	-- Узнать статус курсора
		select CURSOR_STATUS('variable','@mycursor')

-- Альтернативы курсору
	1. SELECT
	2. WHILE
	3. CASE
	4. Рекурсивные запросы
	
-- Ускорение курсора
	1. Уменьшение количества данных в курсорах (количество столюцов и строк)
	2. Параметры параллелизма READ_ONLY (в случае когда не планируем изменение данных с помощью курсора). DECLARE myCursor CURSOR READ_ONLY FOR SELECT... Если данные всё-таки надо обновлять, то используйте параметр OPTIMISTIC
	3. FORWARD_ONLY READ_ONLY (позволяет двигаться по курсору только сверху вниз) или FAST_FORWARD (перемещение курсора только в одном направлении)
	4. Закрывать (CLOSE) и уничтожать (DEALLOCATE) курсор как только это возможно
	5. TempDB на быстрый диск
	
-- Открытые курсоры в данный момент
	select * from sys.dm_exec_cursors(0) -- Все открытые курсоры
	
	SELECT creation_time, cursor_id, name, c.session_id, login_name -- Все открырые курсоры с указанием сессии
	FROM sys.dm_exec_cursors(0) AS c 
	JOIN sys.dm_exec_sessions AS s ON c.session_id = s.session_id 

-- Когда курсоры оправданы
	1. Прокрутка вперёд-назад. FETCH FIRST/LAST/NEXT/PRIOR/ABSOLUTE n/RELATIVE. Такой курсор определяется с указанием SCROLL.
	2. Построчная обработка данных (например включая INSERT)
	3. Динамический SQL
	
-- Ещё типы курсоров
	1. Forward Only
	2. Static
	3. Keyset-driven
	4. Dynamic
	
-- Параметры параллелизма
	1. READ_ONLY
	2. OPTIMISTIC
	3. SCROLL_LOCKS
	4. SCROLL (прокручиваемый курсор)
	
-- Обновляемый курсор
	DYNAMIC SCROLL_LICKS
	
-- Необновляемый
	INSENSITIVE CURSOR
	
-- Количество строк в курсоре
	@@CURSOR_ROWS (указывается в выборке курсора)
	
-- Диагностика курсора
	Profiler > раздел Cursor > Выбрать 3 пункта (CursorClose,CursorExecute,CursorOpen)

--Для удобства отображения можно данные заносить в таблицу. 4 видео 1:24:00

--Программные объекты(VIEW сохраняет текст)/VIEW:
	Должны:
	1) Не должен содержать сортировки(ORDER BY)
	2) 1 Селект
	3) У каждого столбца должно быть имя
	4) Результат - таблица
	5. Не может ссылаться на несколько баз данных
	6. Не работает UNION

	CREATE VIEW MyView01
	AS
	...
	--Вызов:
	SELECT *
	FROM    MyView01
	WHERE...
	
	-- Индексированное представление/Индексированное VIEW
		- Индексированные представления можно создавать в любом выпуске SQL Server 2008. В SQL Server 2008 Enterprise оптимизатор запросов учитывает индексированные представления автоматически. Чтобы использовать индексированные представления в любых других выпусках, следует применить табличную подсказку NOEXPAND.
		- Расход на поддержку индексированного представления может оказаться больше, чем на поддержку обычного индекса
	-- Секционированное представление/федеративные сервера (множество серверов)
		- Чтобы секционированное представление возвращало верные результаты, ограничения CHECK не нужны. Однако если ограничения CHECK не определены, оптимизатор запросов будет вынужден выполнять поиск по всем таблицам, а не только по тем, которые соответствуют условию поиска по столбцу секционирования
		- Если все таблицы-элементы, на которые ссылается секционированное представление, находятся на одном сервере, представление называется локальным секционированным представлением. Если же таблицы-элементы расположены на нескольких серверах, представление называется распределенным секционированным представлением.
		- Лучше использовать правило 80/20. То есть 80% данных хранится на одном сервере
		- Если секционируем скажем по региону, то всё данные, которые могут потребоваться при выборке по этому региону, должны хранится на федеративном сервере. То есть таблица Customer может не иметь региона, но она будет использована в азапросе
	

--Процедуры(PROCEDURE сохраняется как подпрограмма, ничего кроме вызова, зато можно накладывать любые условия и сортировку . Результат - программа):
- Начинайте текст процедуры с инструкции SET NOCOUNT ON (она должна следовать сразу за ключевым словом AS)
- При создании или упоминании объектов базы данных в процедуре используйте имена схем. Отсутствие необходимости поиска в нескольких схемах
  экономит время обработки, затрачиваемое компонентом Database Engine на разрешение имен объектов
- Не используйте инструкцию SELECT *. Вместо этого указывайте имена нужных столбцов  
- Используйте функцию Transact-SQL TRY…CATCH для обработки ошибок в пределах процедуры
	- Ловит ошибки серьёзностью выше 10.
	- Errors that terminate the database connection, usually with severity from 20 through 25, are not handled by the CATCH block because execution is aborted when the connection terminates.
	- Чтобы получить серьёзность ошибки, в блоке TRY...CATCH можно использовать функцию ERROR_SEVERITY, работает только в данном блоке
- Используйте ключевые слова NULL и NOT NULL для каждого столбца во временной таблице
- Процедура может ссылаться на таблицы, которые еще не существуют.
- Если процедура вносит изменения на удаленном экземпляре SQL Server, то откат этих изменений будет невозможен
CREATE PROCEDURE MyProc01
AS
...

EXECUTE MyProc01 --Запустить

--В процедуру можно передавать данные: 
CREATE PROCEDURE MyProc02 @Title varchar(100)
													@MinQty int
AS
...
EXECUTE MyProc02 'a', 50

-- Можно присвоить параметру дефолтное значение, если данные не были переданы
create proc MyProc2
( 
	@Title int = 50, -- дефолтное значение
	@Title1 int
)
AS
...
-- Скрыть процедуру
CREATE PROCEDURE HumanResources.uspEncryptThis
WITH ENCRYPTION
AS

-- obj/id объекта
SELECT OBJECT_ID (N'dbo.temp_table', N'U')


--Функция(всегда возвращает только 1 значение. Это позволяет встраивать в SELECT. Объединяет преимущество VIEW и PROCEDURE. Функция не может менять базу)/функции:
	- Лучше не использовать функции, а если использует то WITH SCHEMABINDING 
	CREATE FUNCTION MyFunc01	(
													@Title varchar(100),
													@MinQty int = 0 --0 будет значением по умолчанию и можно вызывать функцию только с 1 значением
													)
	RETURNS TABLE
	AS
	RETURN
	....
	SELECT *
	FROM    MyFunc01 ('a', 50) -- Вызов
	WHERE ...
	
	- Табличная функция работает быстро, так как не происходит множественного вызова



--Выходной параметр(Когда от процедуры ожидаем атамарное значение, то есть число)
CREATE PROCEDURE MyProc01 @Count int OUTPUT
AS
...

DECLARE @MyCount int
EXECUTE MyProc01 @MyCount OUTPUT
SELECT @MyCount


--Общее/обобщённое табличное выражение(способ сохранения запроса в базе, но в базе не сохраняется, а живёт в момент запроса):/;with/CTE
 WITH MyCTE(Title,TotalQty)--В скобках столбцы
AS	(
        SELECT...
		) 
		MyCTE1(Name)
AS
		(
		SELECT
		)
        

SELECT *
FROM	  MyCTE --Вызов
WHERE....
--или
SELECT *
FROM	  MyCTE INNER JOIN MyCTE1 ON...
WHERE....

--Триггер(нельзя вызвать, его запускает сам сервер. Используют для журналирования действий пользователей и контроль целостности):
	CREATE TRIGGER MyTrigger
		ON Titles--Таблица
		FOR UPDATE --Можно INSERT, UPDATE
	AS
	--  SET NOCOUNT ON --Сделать триггер невидимым
		SELECT 'HELLO!'
	go
	--При обновлении таблицы выполняется данный триггер
	
	-- Установка первого и последнего выполняющегося триггера, все остальные будут выполнены в произвольном порядке. Только для параметра AFTER
		- После изменения триггера необходимо заного установить ему порядок вызова
		sp_settriggerorder @triggername= 'Sales.uSalesOrderHeader', @order='First', @stmttype = 'UPDATE';
		sp_settriggerorder @triggername= 'ddlDatabaseTriggerLog', @order='First', @stmttype = 'ALTER_TABLE', @namespace = 'DATABASE';
	
	-- Посмотреть является ли триггер первым/последним
		- Определяет id объекта только в контексте текущей базы данных, запрос OBJECT_ID(N'Arttour.dbo.TR_ndog_arttour') вернёт неверные результаты
		SELECT OBJECTPROPERTY(OBJECT_ID(N'dbo.TR_ndog_arttour'),'ExecIsFirstInsertTrigger') as FirstInsert, OBJECTPROPERTY(OBJECT_ID(N'dbo.TR_ndog_arttour'),'ExecIsLastInsertTrigger') as LastInsert
		
	-- Внимание
		- if @@RowCount = 0 return
		- update(filed_name) (Returns a Boolean value that indicates whether an INSERT or UPDATE attempt was made on a specified column of a table or view. UPDATE() is used anywhere inside the body of a Transact-SQL INSERT or UPDATE trigger to test whether the trigger should execute certain actions.)

-- Функция WITH
- Временная View/табличное выражение
	- Что-то типа View, которое временно существует во время SELECT`a, не хранится в базе, а потом удаляется.
	  Работает только на следующий селект, если написать 2 селекта, то второй селект не подхватит WITH.
	  Это позволяет отделить бизнес логику от элементарных действий	  
	  WITH MyCustomers (ID,Name)
	  AS
		(
			Select CustomerKey, FirstName+' '+LastName
			FROM dimCustomer
		)	
	Select * FROM MyCustomers

-- Распределенные транзации
	- В одном подключении
		BEGIN TRANSACTION
		DECLARE @test varchar(255)
		EXEC sp_getbindtoken @test OUTPUT -- Получаем код транзакции
	- В другом подключении
		DECLARE @test2 varchar(255) = '`O_k@JeJf1k3EL5GTWBd?=5---.SG---' -- Вставляем код транзакции
		exec sp_bindsession @test2 -- Привязываемся к транзакции с кодом
		... -- Здесь даже можно открывать и закрывать другие транзакции
		COMMIT TRAN -- Завершаем привязанную транзакцию

-- Работа с файлами
	EXEC sp_configure 'show advanced option', '1'  -- Включаем дополнительные опции
	GO 
	RECONFIGURE;
	GO   
	EXEC sp_configure 'Ole Automation Procedures', 1; -- Включаем возможность работы с Ole объектами
	GO
	RECONFIGURE;
	GO
	
	- Код:
		DECLARE @FileID int, @FileSystem int, @String varchar(1000)

		- /*Работа с файловой системой*/
			EXECUTE sp_OACreate 'Scripting.FileSystemObject', @FileSystem OUTPUT

		- /*Открываем текстовый файл в режиме чтения*/
			EXECUTE SP_OAMethod @FileSystem, 'OpenTextFile', @FileID OUTPUT,'D:\тест.txt',1, False,0

		- /*Читаем первую строку*/
			EXEC sp_OAMethod @FileID, 'ReadLine', @String OUTPUT
			PRINT @String
		- /*Читаем первую строку*/
			EXEC sp_OAMethod @FileID, 'ReadLine', @String OUTPUT
			PRINT @String

		-- /*Сборка мусора*/
			EXECUTE sp_OADestroy @FileID
			EXECUTE sp_OADestroy @FileSystem
			
-- Пересечение интервалов
IF((@a2>@b1) AND (@b2 >= @a1))
BEGIN
	SELECT 'Попал'
END
ELSE
BEGIN
	SELECT 'Фигня'
END

-- MERGE
	MERGE dbo.TargetTable tgt   -- Target Table
	USING dbo.SourceTable src   -- Source Table
	ON tgt.ID = src.ID          -- Main comparison criteria
	WHEN MATCHED AND 1=1	-- When ID's exist in both tables
	THEN -- DO SOMETHING
	WHEN NOT MATCHED  AND 1=1	-- When ID's from Source do not exist in Target
	THEN -- DO SOMETHING
	WHEN NOT MATCHED BY SOURCE AND 1=1  -- When ID's from Target do not exist in Source
	THEN -- DO SOMETHING
	WHEN NOT MATCHED BY TARGET AND 1=1   -- When ID's from Source do not exist in Targete
	THEN -- DO SOMETHING
	WHEN MATCHED AND tgt.Name != src.Name -- Двойное условие
	THEN -- DO SOMETHING
	OUTPUT $action, inserted.*, deleted.*; -- вывести какие действия были выполнены
	
	-- Используем
	1. Для условной вставки или обновления строк в целевой таблице.
		Если в целевой таблице существует строка, то обновляется один или насколько столбцов. В противном случае данные вставляются в новую строку.
	2. Для синхронизации двух таблиц.
		Для вставки, обновления или удаления строк в целевой таблице в зависимости от различий по сравнению с исходными данными
		
	-- Важно
		1. Чтобы использовать инструкцию MERGE, необходима точка с запятой (;) как признак конца инструкции. Возникает ошибка 10713, если инструкция MERGE выполняется без признака конца конструкции.
		
		2. Чтобы использовать инструкцию MERGE, необходима точка с запятой (;) как признак конца инструкции. Возникает ошибка 10713, если инструкция MERGE выполняется без признака конца конструкции.
		
		3. Для каждой операции вставки, обновления или удаления, указанной в инструкции MERGE, SQL Server запускает все соответствующие триггеры AFTER, 
		
		4. Если INSTEAD OF UPDATE или определены триггеры INSTEAD OF DELETE на target_table, не выполняются операции обновления или удаления. Вместо этого запускаются триггеры и вставлены и удалены заполняются соответствующим образом.
		
		5. Укажите в предложении ON <merge_search_condition> только те условия поиска, которые определяют критерий совпадения данных в исходных и целевых таблицах. То есть необходимо указать только те столбцы целевой таблицы, которые сравниваются с соответствующими столбцами исходной таблицы.

		6. Не включайте сравнения с другими значениями, такими как константа.
		

- /*Сложности:*/
	- Если есть проблемы с отслеживанием тем, что произошло, то можно ввести доп. поле для этого
	- Посчитать сколько строк было добавлено/удалено. 
		- /*Пример реализации*/
			CREATE TABLE #ActionCount
			(
				[action] VARCHAR(50)
			)			 
			INSERT INTO #ActionCount
			(
				[action]
			)
			SELECT [action]
			FROM (
				MERGE dbo.TargetTable tgt           
				USING dbo.SourceTable src           
				ON tgt.ID = src.ID                  
				WHEN NOT MATCHED BY TARGET          
					THEN INSERT                     
					(
						ID,
						Name
					)
					VALUES
					(
						ID,
						Name
					)
				WHEN MATCHED                        
				AND tgt.Name != src.Name
					THEN UPDATE
					SET 
						tgt.Name = src.Name
				OUTPUT
				$action
			) t
			(
				[action]
			)
			SELECT
			RowsUpdated = COUNT(CASE [action]
			WHEN 'UPDATE' THEN 1 END)
			,RowsInserted = COUNT(CASE [action]
			WHEN 'INSERT' THEN 1 END)
			FROM #actioncount			

- /*Пример:*/
	- /*Первый */
		MERGE dbo.TargetTable tgt           -- Target Table
		USING dbo.SourceTable src           -- Source Table
		ON tgt.ID = src.ID                  -- Main Comparison
		WHEN NOT MATCHED BY TARGET          -- ID's from Source do not exist in Target
			THEN INSERT                     -- Insert records from source
			(
				ID,
				Name
			)
			VALUES
			(
				ID,
				Name
			)
		WHEN MATCHED                        -- Update the records where the names do not match
		AND tgt.Name != src.Name
			THEN UPDATE
			SET 
				tgt.Name = src.Name
		WHEN NOT MATCHED BY SOURCE          -- Delete records in target that do not exist in source
			THEN DELETE;

			
-- Extended Properties/расширенные свойства
USE AdventureWorks2008R2;
GO
EXEC sys.sp_addextendedproperty 
@name = N'MS_DescriptionExample', 
@value = N'Nonclustered index on StateProvinceID.', 
@level0type = N'SCHEMA', @level0name = Person,  -- Схема
@level1type = N'TABLE',  @level1name = Address, -- Таблица
@level2type = N'INDEX',  @level2name = IX_Address_StateProvinceID; -- Индекс
GO

-- Для процедур
- Предназначен для работы процедур с программами 
- Можно использовать и без приложений, для удобного хранения и отображения той информации, с которой вам было бы комфортно работать
  в графическом интерфейсе
- Теория: создаём поля в Extended Properties и через саму вызывающую процедуру их обновляем
- Практика:
	- Выбор значения из Extended Properties
		SELECT value FROM fn_ListextEndedProperty(N'название свойства',N'SCHEMA',N'dbo',N'PROCEDURE',N'название процедуры',null,null)
	- Обновление значения Extended Properties
		EXECUTE sys.sp_UpdateExtendedProperty @name=N'название свйоства', @value=значение,@level0type=N'SCHEMA',
		@level0name=N'dbo',@level1type=N'PROCEDURE',@level1name=N'название процедуры'
		
-- Перекомпиляция процедуры
1. При создании
	CREATE PROCEDURE dbo.uspProductByVendor @Name varchar(30) = '%'
	WITH RECOMPILE
	AS...
2. При вызове
	EXECUTE HumanResources.uspGetAllEmployees WITH RECOMPILE;

-- Перекомпиляция запроса
	SELECT * FROM Users WHERE id > 500 OPTION (Recompile)
	SELECT * FROM Users WHERE id > 500 OPTION (OPTIMIZE FOR (@LastName='Anderson'))
	SELECT * FROM Users WHERE id > 500 OPTION (OPTIMIZE FOR UNKNOWN) -- оптимизирует среднее значение для всех

-- Перекомпиляция любого объекта
	sp_recompile
	
-- SELECT INTO
- Создаёт таблицу на основе выделенных данных
SELECT c.FirstName, c.LastName, e.JobTitle, a.AddressLine1, a.City, 
       sp.Name AS [State/Province], a.PostalCode
INTO dbo.EmployeeAddresses
FROM Person.Person AS c
- Чтобы не нагружать журнал, можно отключить журналирование на момент создания таблицы
ALTER DATABASE AdventureWorks2012 SET RECOVERY BULK_LOGGED;
GO
SELECT * INTO dbo.NewProducts
FROM Production.Product
WHERE ListPrice > $25 
AND ListPrice < $100;
GO
ALTER DATABASE AdventureWorks2012 SET RECOVERY FULL;

-- Hints/WITH/OPTION/Подсказки
	-- Table hints/Табличные указатели
		SELECT * FROM Table WITH (NOEXPAND) - указать оптимизатору чтобы он не тыпался понять страуткру данных
		SELECT * FROM Table WITH (index(ci)) - указать какой индекс использоваться
	-- Query hints/ Указатели для запроса
		SELECT * FROM Table OPTION(RECOMPILE) -- Каждый раз перекомпелирвать запрос
		SELECT * FROM Table OPTION(LOOP JOIN) -- Использование LOOP JOIN
	-- KEEP PLAN
		Заставляет оптимизатор запросов снизить приблизительный порог повторной компиляции для запроса. Предполагаемое пороговое значение повторной компиляции — это точка, в которой запрос автоматически перекомпилируется, если в таблице при выполнении инструкций UPDATE, DELETE или INSERT изменилось ожидаемое количество индексированных столбцов. Указание подсказки KEEP PLAN гарантирует, что запрос не будет часто перекомпилирован при выполнении множественных обновлений в таблице.
	-- KEEPFIXED PLAN
		Принуждает оптимизатор запросов не перекомпилировать запрос при изменении статистики. Указание подсказки KEEPFIXED PLAN гарантирует, что запрос будет перекомпилирован только при изменении схемы базовых таблиц или если по отношению к ним выполнена процедура sp_recompile.

-- xp_cdmshell 
- Конмандная строка через sql

-- Хакерство/SQL инъекции
--Передача параметра в триггер
- Это делается через CONTEXT_INFO
- CONTEXT_INFO может содержать только varbinary(128), которое можно перевести в varchar(128)
- Как работает:
	1. Сначала перед действием с базой зададим CONTEXT_INFO
		DECLARE @test varbinary(128)
		SET @test = CAST('Тестирование' as varbinary(128))
		SET CONTEXT_INFO @test
	2. Изменим триггер, чтобы он отлавливал CONTEXT_INFO
		DECLARE @test2 varchar(128)
		SET @test2 = CONTEXT_INFO()
		SELECT @test2
	3. Организуем логику для значения @test2
	
-- Отключить всех пользователей
alter database IntraTV set RESTRICTED_USER with rollback immediate

--SQL-инъекция:оборона и нападение
- Когда что-то open source, то мы можем смотреть запросы и подбирать инъекции
1. В логине
	XAKER' OR 1=1';--
	XAKER' OR 1=1'; далее можно создать пользователя и всё что угодно
	
2. В поиске (хорошо знать таблицы/столбцы)
	fish' OR 1=1 UNION ALL SELECT login_name,password FROM Login;--
	fish' OR 1=1-- DROP TABLE Logins;--
	
3. Можно выполнять cmd команды через SQL, если отключена - включаем. При этом даже если база удалилилась, мы можем его взять и создать
	
	Решения:
		1. Сделать первым пользователем гостя без прав
		2. Использовать хранимые процедуры
		3. Не давать пользователю SQL сервера администраторских прав
		4. Экранировать/заменить/удалить(Replace) одинарную кавычку в полях для ввода
		5. Явное преобразование типов полей ввода
		6. Параметризированные запросы(EXECUTE sp_ExecuteSQL(прочитать))
		7. Откажитесь от динамических запросов
		8. Не доверяйте никому, проверяйте пользователя
		9. Принцип минимальных привилегий
		10. Эшелонированная оборона

4. У хакера есть специальные программы, которые будут перебирать

5. Можно зарегить пользователя " OR 1=1-- и потом им зайти
"
-- Узнать тип колонки
execute sp_MShelpcolumns 'dbo.aaatest'
-или
select
 sc.name  column_name,st.name type_name
from
 syscolumns sc,
 sysobjects so,
 systypes st
where
 so.id=sc.id
 and
 sc.type=st.type
 and
 sc.usertype=st.usertype
AND so.name  ='claim'
AND so.type = 'U'

-- Ускорить запрос
	1. Не включать функцию в столбец поиска (WHERE SUBSTRING(name 1,1)='b'). Это может вызвать неверное использование индексов

-- CROSS APPLY
	- позволяет вызывать табличную функцию для каждой строки, возвращаемой внешним табличным выражением запроса. 
	- OUTER CROSS APPLY вернёт и те строки, для которых не нашлась пара
	- Отличается от подзапроса тем, что может вывести более 1 столбца
		SELECT *
		 FROM laptop L1
		 CROSS APPLY
		 (SELECT MAX(price) max_price, MIN(price) min_price  FROM Laptop L2
		JOIN  Product P1 ON L2.model=P1.model 
		WHERE maker = (SELECT maker FROM Product P2 WHERE P2.model= L1.model)) X;
		
	- Соединить каждую строку из таблицы Laptop со следующей строкой в порядке, заданном сортировкой (model, code).
		SELECT * FROM laptop L1
		CROSS APPLY
		(SELECT TOP 1 * FROM Laptop L2 
		WHERE L1.model < L2.model OR (L1.model = L2.model AND L1.code < L2.code) 
		ORDER BY model, code) X
		ORDER BY L1.model;
		
-- OUTER APPLY
	- Отличается от CROSS APPLY тем, что возвращает и те строки, которым не нашлось совпадение
	

-- Список городов для каждой страны	
select * from dbo.Countries c 
cross apply dbo.GetCities ( c.CountryID ) ap -- Функция возвращает список городов, для переданной страны. При этом это будет 1 результирующий набор данных

-- Как вывести по 3 города для каждой страны, отсортированных по алфавиту!? С помощью оператора APPLY это сделать достаточно легко
select * from dbo.Countries c
cross apply (select top 3 City from dbo.Cities 
                where CountryID = c.CountryID order by City) ap

-- Выведем первую букву каждого из 3х городов каждой страны и общее количество этих букв среди ВСЕХ городов текущей страны
select * from dbo.Countries c
cross apply ( select top 3 City from dbo.Cities where CountryID = c.CountryID order by City 
            ) ap
cross apply ( select l 'Letter', sum (cl) 'LetterCount'
                from
                (select left( ap.City, 1 ) l,
                        len( City ) - len ( replace ( City, left( ap.City, 1 ) ,'' ) )  cl
                   from dbo.Cities where CountryID = c.CountryID
                 ) t 
              group by l
            ) apLetters
	
-- Сводные таблицы
	- Способы работы:
		1. PIVOT (удобно)
		2. Подзапросы для групп по столбцам (просто)
		3. CASE для групп по столбцам (производительно)
		
	-- PIVOT
		- Влючает в себя группировку и разворачивание осей перпендикулярно друг другу
		- Нужно ответить что будет по горизонтали, по вертикали и внутри
		- По горизонтали надо выводить то, чего меньше или что ведёт себя более предсказуемо
		- То, что поместим по горизонтали нужно всегда значить значения, если не знаете - ничего страшного, просто не посчитается агрегация
		
		SELECT [Category],[2005],[2006],[2007],[2008],[2009] FROM -- Указываем столбцы, которые надо знать или динамически вычислять
		(
		SELECT [Category]
			  ,year([ModifiedDate]) as [year]
			  , SpecialOfferID      
		  FROM [AdventureWorks2008R2].[Sales].[SpecialOffer])  tempt
		 PIVOT (
				Count(SpecialOfferID) FOR [year] IN ([2005],[2006],[2007],[2008],[2009]) -- Указываем группировку
			) PivotName
	
	-- Подзапросы для групп по столбцам
		SELECT DISTINCT [Category]
		,(SELECT  Count(SpecialOfferID) FROM [AdventureWorks2008R2].[Sales].[SpecialOffer] as s2 WHERE YEAR(ModifiedDate) = 2005 AND s2.[Category] = s1.[Category]) as [2005]
		,(SELECT  Count(SpecialOfferID) FROM [AdventureWorks2008R2].[Sales].[SpecialOffer] as s2 WHERE YEAR(ModifiedDate) = 2006 AND s2.[Category] = s1.[Category]) as [2006]
		,(SELECT  Count(SpecialOfferID) FROM [AdventureWorks2008R2].[Sales].[SpecialOffer] as s2 WHERE YEAR(ModifiedDate) = 2007 AND s2.[Category] = s1.[Category]) as [2007]
		,(SELECT  Count(SpecialOfferID) FROM [AdventureWorks2008R2].[Sales].[SpecialOffer] as s2 WHERE YEAR(ModifiedDate) = 2008 AND s2.[Category] = s1.[Category]) as [2008]      
		  FROM [AdventureWorks2008R2].[Sales].[SpecialOffer] as s1	
		  
		- Плюсы
			1. Простой
			2. Без GROUP BY
			
	-- CASE для групп по столбцам
		SELECT [Category],
		COUNT(CASE YEAR(ModifiedDate) WHEN 2005 THEN SpecialOfferID END) as [2005],
		COUNT(CASE YEAR(ModifiedDate) WHEN 2006 THEN SpecialOfferID END) as [2006],  
		COUNT(CASE YEAR(ModifiedDate) WHEN 2007 THEN SpecialOfferID END) as [2007],  
		COUNT(CASE YEAR(ModifiedDate) WHEN 2008 THEN SpecialOfferID END) as [2008] 
		FROM [AdventureWorks2008R2].[Sales].[SpecialOffer]
		GROUP BY [Category]
		
-- sp_executesql (also known as “Forced Statement Caching”)
	- Позволяет параметризировать запрос
	- Имеет строгий тип переменных, что может снизить риски инъекций и предложить некоторые выгоды производительности
	- Быть аккуратнее, так как оптимизатор может неверно выбирать план по разным параметрам
	- Creates a plan on first execution (similar to stored procedures) and subsequent executions reuse this plan
	- Forced SQL Server to do caching
	- Пример:
		DECLARE @ExecStr NVARCHAR(4000);
		SELECT @ExecStr = 'SELECT * FROM dbo.member WHERE lastname LIKE @lastname';
		EXEC sp_executesql @ExecStr, N'@lastname varchar(15)', 'Tripp';
	
-- EXEC (also known as “Dynamic String Execution” or DSE)
	- Позволяет строить любые конструкции
	- Не имеет строгих типов параметров в adhoc 
	- "Не сохраняет" кэш плана. Это и плохо и хорошо
	
	
-- QUOTENAME
	- Обернуть название в квадратные скобки, что позволяет избежать SQL инъекций
		QUOTENAME(@nn, N']')
		
-- DATABASEPROPERTYEX. Проверка существования базы
	IF DATABASEPROPERTYEX (N'DBMaint2008', N'Version') IS NOT NULL
   		DROP DATABASE [DBMaint2008];

-- Вставить дефолтные/DEFAULT значения в базу
	INSERT INTO [FillerTable] DEFAULT VALUES;
	GO 1280 -- повторяет эту операцию 1280 раз
	
-- RETURN and output
	--Создаём процедуру с выходным параметром и с RETURN
		ALTER PROC MyProcedure @a int, @b int output
		AS
		SET @b = @a+@a
		RETURN @b

	--Получение выходного параметра
		DECLARE @b int
		exec MyProcedure 3,@b output
		IF @b >= 3 PRINT 'HELLO' 
		ELSE
		PRINT 'OH NO'

	--Получение значения RETURN
		DECLARE @test int
		EXECUTE @test = MyProcedure 7, 3
		SELECT @test
		
-- LAG
	- Обращается к данным из предыдущей строки того же результирующего набора без использования самосоединения в SQL Server 2012. Функция LAG обеспечивает доступ к строке с заданным физическим смещением перед началом текущей строки. Используйте данную аналитическую функцию в инструкции SELECT для сравнения значений текущей строки со значениями из предыдущей.
	
		SELECT BusinessEntityID, YEAR(QuotaDate) AS SalesYear, SalesQuota AS CurrentQuota, 
		   LAG(SalesQuota, 1,0) OVER (ORDER BY YEAR(QuotaDate)) AS PreviousQuota -- 1 означает сколько строк вверх брать, 0 - какое значение подставлять при NULL. Over разбивает на секции по полю
		FROM Sales.SalesPersonQuotaHistory
		WHERE BusinessEntityID = 275 and YEAR(QuotaDate) IN ('2005','2006');
		

		SELECT TerritoryName, BusinessEntityID, SalesYTD, 
			   LAG (SalesYTD, 1, 0) OVER (PARTITION BY TerritoryName ORDER BY SalesYTD DESC) AS PrevRepSales -- Partition разбивает на секции, а потом к ним применяет ORDER BY
		FROM Sales.vSalesPerson
		WHERE TerritoryName IN (N'Northwest', N'Canada') 
		ORDER BY TerritoryName;
		
-- LEAD
	- Обращается к данным из последующей строки того же результирующего набора данных без использования самосоединения в SQL Server 2014
	- Формулы как и в LAG
	
-- NTILE	
	- Распределяет строки упорядоченной секции в заданное количество групп. Группы нумеруются, начиная с единицы. Для каждой строки функция NTILE возвращает номер группы, которой принадлежит строка.
	
		SELECT p.FirstName, p.LastName
		,NTILE(4) OVER(ORDER BY SalesYTD DESC) AS Quartile -- Разбить на 4 группы
		,CONVERT(nvarchar(20),s.SalesYTD,1) AS SalesYTD
		, a.PostalCode
		FROM Sales.SalesPerson AS s 
		INNER JOIN Person.Person AS p 
			ON s.BusinessEntityID = p.BusinessEntityID
		INNER JOIN Person.Address AS a 
			ON a.AddressID = p.BusinessEntityID
		WHERE TerritoryID IS NOT NULL 
			AND SalesYTD <> 0;
			
-- RANK
	- Возвращает ранг каждой строки в секции результирующего набора. Ранг строки вычисляется как единица плюс количество рангов, находящихся до этой строки. Если две и более строки претендуют на один ранг, то все они получат одинаковый ранг.
	
		SELECT TOP(10) BusinessEntityID, Rate, 
        RANK() OVER (ORDER BY Rate DESC) AS RankBySalary -- Можно так же использовать PARTITION
		FROM HumanResources.EmployeePayHistory AS eph1
		WHERE RateChangeDate = (SELECT MAX(RateChangeDate) 
								FROM HumanResources.EmployeePayHistory AS eph2
								WHERE eph1.BusinessEntityID = eph2.BusinessEntityID)
		ORDER BY BusinessEntityID;

-- DENSE_RANK 
	- Возвращает ранг строк в секции результирующего набора без промежутков в ранжировании. Ранг строки равен количеству различных значений рангов, предшествующих строке, увеличенному на единицу.
		DENSE_RANK() OVER (PARTITION BY i.LocationID ORDER BY i.Quantity DESC) AS Rank
		
-- EOMONTH 
	- Возвращает последний день месяца, содержащего указанную дату, с необязательным смещением.
	
-- Обратотка ошибок/ошибки
	- Используется конструкция TRY...CATCH
		BEGIN TRY
		
		END TRY
		BEGIN CATCH
		END CATCH
	- Работает с серьёзностью ошибок более 10
	- Охватывает только 1 пакет. Это значит что 2 конструкции BEGIN...END одним обработчиком ошибок охватить не получится
	- можно использовать следующие системные функции:
		функция ERROR_NUMBER() возвращает номер ошибки.
		Функция ERROR_SEVERITY() возвращает степень серьезности ошибки.
		Функция ERROR_STATE() возвращает код состояния ошибки.
		Функция ERROR_PROCEDURE() возвращает имя хранимой процедуры или триггера, в котором произошла ошибка.
		Функция ERROR_LINE() возвращает номер строки, которая вызвала ошибку, внутри подпрограммы.
		Функция ERROR_MESSAGE() возвращает полный текст сообщения об ошибке. Текст содержит значения подставляемых параметров, таких как длина, имена объектов или время.
	
-- OPENROWSET 
  
	SELECT a.* FROM OPENROWSET('SQLNCLI', 'Server=DC1-DB-CL5\SQL1C;uid=loc_info;pwd=111111',
     'SELECT *
      FROM [replica].[sbl].[tt] tt') AS a;
	  
-- CREATE TYPE 
	- Работает в пакетном режиме. По скорости совпадает с BULK COPY. 
	- Можно поместить в память с 2014
	- Табличный тип
	- Хорошо для загрузки данных из приложения
	- CREATE TYPE LocationTableType AS TABLE
	
-- Побитовые операторы сравнения
	https://msdn.microsoft.com/ru-ru/library/ms176122.aspx
	
-- Операторы ANY,SOME,ALL
	https://technet.microsoft.com/ru-ru/library/ms187074(v=sql.105).aspx
	
--

-- ***** JSON
	-- Плюсы
		1. Занимает меньше места
		2. JSON работает быстрее
	-- Эффективный поиск
		1. Вычисляемый столбец (постоянный) с частью данных из JSON и построить по нему индекс
		2. FULLTExt
		
-- Вернуть все значения или то, которое пришло
	DECLARE @i int = NULL

	SELECT * FROM sys.tables t1
	INNER JOIN sys.tables t2  ON (t1.uses_ansi_nulls = @i OR @i is null) and t1.object_id = t2.object_id
	
-- Почему SELECT TOP без ORDER BY не гарантирует порядок даже с индексом
-- Почему SELECT TOP без ORDER BY не гарантирует порядок даже с индексом
	https://blogs.technet.microsoft.com/wardpond/2007/07/19/database-programming-top-without-order-by/
	
-- Получить текст процедуры
	SELECT *  FROM sys.sql_modules m
       INNER JOIN
       sys.objects o
         ON m.object_id = o.object_id
	-- WHERE m.definition Like '%[ABD]%';