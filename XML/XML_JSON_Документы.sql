-- XML
	- Применяется, когда нужно добавить в текущее решение документооборот. Для нового можно использовать DocumentDB
	- Поддерживает индексы
	- Работа с XML увеличивает потребление CPU
	
	-- Когда применять вместо обычного реляционного решения
		1. Сложная структура
		2. Постоянно меняющаяся структура

	-- Минусы
		1. В SQL Server работа с XML сложная и медленная операция
		
-- Курс по SQL (Joes2Pros), анг
	<NFC> -- root element
		<AFC Name="American Football Conference"> -- top level element with Attribute
		</AFC>
	</NFC>
	
	-- Создать посточный xml документ из выборки данных.  Данные находятся в атрибутах
		SELECT * FROM [claim] FOR XML RAW 
		SELECT * FROM [claim] FOR XML AUTO -- то же самое, только элемент будет не row, а название таблицы
		SELECT * FROM [claim] FOR XML RAW('claim') -- переименовать элементы с row на claim
	
	-- JOIN
		- Если использовать JOIN и AUTO, то он создат вложенную структуру. В этом случае важен порядок вывода строк, первый элемент будет top level element
		
	-- ROOT
		- Добавить ROOT элемент
		SELECT * FROM [claim] FOR XML AUTO, ROOT('ART')
	
	-- ORDER BY. Сортировка
		- Достаточно просто отсортировать данные в запросе
		
	-- ELEMENTS
		- Разбить набор данных на элементы вместо атрибутов
		- Если значение поля NULL, то он не отобразил это и для этого надо указать ELEMENTS XSINIL
			SELECT c.imname,r.note,r.price FROM currency c INNER JOIN reklama r ON c.inc=r.currency AND c.imname IS NOT NULL FOR XML AUTO, ROOT('ART'), ELEMENTS
			
	-- PATH
		- Изначально включён ELEMENTS,ROW	
		- Если мы хотим вынести в атрибут какое-то значение, то надо задать ему имя [@MyName] через скобки и спец. символ
			SELECT c.imname,r.note,r.price FROM currency c INNER JOIN reklama r ON c.inc=r.currency AND c.imname IS NOT NULL FOR XML PATH
			
	-- RENAME/ALIAS/Переименость элементы
		- Просто переименовываем стобцы
	
	-- Объединение элементов под один общий
		- Переименовать [Name/First] и [Name/Last]
		
	-- Вырезка текста из элемента и постановка его за предыдущим, после закрывающегося тэга.
		- Всё это внутри Top Element
		- Чтобы это релазивать - необходимо задать имя/alias столбцу as [*]
		
	-- Export/Import. Эскпорт/Импорт
		- Представление xml в виде обычного SELECT		
			DECLARE @doc xml
			SET @Doc = '<Town name="Дубай, Джумейра" lname="Dubai, Jumeirah">
			  <Hotel name="JUMEIRAH BEACH HOTEL" partner="2490">
				<Main inc="39413" cost="17178.0000" />
				<Order inc="58942" cost="690.4000" />
			  </Hotel>
			  <Hotel name="Next Hotel" partner="2491">
				<Main inc="11" cost="33.0000" />
				<Order inc="22" cost="44.4000" />
			  </Hotel>
			</Town>'

			DECLARE @hDoc int -- Получить номер хендлера XML
			EXEC sp_xml_prepareDocument @hDoc OUTPUT, @Doc -- Приготовить xml к загрузке в базу. При этом каждый раз создаётся новый хендлер, а старый не удаляется, поэтому надо не забывать удалить элемент

			SELECT @hDoc

			SELECT * FROM Openxml(@hDoc,'/Town/Hotel/Order') -- Получить данные в указанном фрагменте. Только Данные из Order
			WITH (inc int, cost decimal(8,2)) -- Помостить данные атрибутов в столбец. Мы можем указать только 1 столбец. Обязательно указывать имена как в XML. Регистр вашен.
			WITH (Number int '@inc',cost decimal(8,2)) -- Так можно переименовать входящий столбец. inc > Number
			
			EXEC sp_xml_RemoveDocument @hDoc -- Удаление XML документа из памяти, с указанным хендлером
			
		- Поиск одинаковых атрибутов
			SELECT * FROM Openxml(@hDoc,'/Town//Emp') -- Сервер найдёт все вхождения с Emp и достанет все данные, которые мы укажем в WITH
		
		- Найти данные на 1 элемент выше
			WITH ([User] nvarchar(50), BossName nvarchar(50) '../@User') -- Ищет для этой записи поле User на 1 элемент выше
			
		- Найти данные на 2 элемента выше
			'../../@User'
			
		- Openxml
			Openxml(@hDoc,'/Town/Hotel/Order',1) -- Достать только атрибуты
			Openxml(@hDoc,'/Town/Hotel/Order',2) -- Достать только элементы
			Openxml(@hDoc,'/Town/Hotel/Order',3) -- Достать и то и то
			
		- Работа с полем XML
			-- query() медленный и разбор с нюансами, если в корне есть атрибуиты, то может работать неверно. Чтобы работал верно надо обязательно добавить перед запросом ;WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
			SELECT xmlField.query('/Songs/Song') FROM MyXML -- Получим все значения уровня Song
			SELECT xmlField.query('(/Songs/Song)[2]') FROM MyXML -- Получить 2 элемент уровня Song
			SELECT xmlField.query('(/Songs/Song)[1]/WriterName') FROM MyXML -- Получить элемент WriterName в 1 уровне Song
			SELECT xmlField.query('(/Songs/Song)[1]/WriterName/text()') FROM MyXML -- Получить только текст
			SELECT xmlField.query('(/Songs/Song)[1]/WriterName/text())[1]') FROM MyXML -- Получить только текст первого элемента
			SELECT xmlField.query('(/Songs/Song)[2]/Singer[2]') FROM MyXML -- Так же можно получать дальнейшие вложения
			SELECT xmlField.query('(/Songs/Song[@TitleID=13160])') FROM MyXML -- Получить результат с конкретными данными
			SELECT @xml.query('data(/upperLevel/Company/Director[@Name = "Paul"]/@Age)') -- Получить только данные атрибута Age, где Имя Paul
			SELECT @xml.value('(/upperLevel/Company[1]/Director)[1]','nvarchar(50)') -- Получить значение первого элемента Company и первого элемента Director
			SELECT @xml.exist('/upperLevel/Company[@Name1="Company1"]') -- Проверка на существование данных
			SET @xml.modify('replace value of (/upperLevel/Company[@Name1="Company1"]/Director/text())[1] with "Walk"') -- Обновить данные в XML
			SELECT @xml.query('for $ManyHits in /upperLevel/Company where count($ManyHits/Director) > 1 return $ManyHits') -- Получить такие Компании, которые имеют более 1 диретора
			SELECT @xml.query('<Delivery>{for $t in /upperLevel/Company return $t/Director}</Delivery>') -- Добавить корневой элемент
			SELECT @xml.query('<Delivery>{/upperLevel/Company}</Delivery>') -- Добавить корневой элемент
			SELECT xmlFrield.query('<Delivery><DriverName>{sql:column("Driver")}</DriverName>{/upperLevel/Company}</Delivery>') -- Вставить значение из таблицы
		
		- CROSS APPLY -- Получаем строку для каждой песни в поле XML
			SELECT MusicTypeID, SongDetails.value('@TitleID', 'int'),SongDetails.value('WriterName[1]','varchar(max)')
			FROM MusicHistory
			CROSS APPLY MusicDetails.nodes('//Music/Song') as SongTable(SongDetails) -- MusicDetails - столбец XML
			
-- Парс xml/парсинг
	SELECT TOP 1000 xmleventdata.query('/EVENT_INSTANCE/TSQLCommand/CommandText') as xmll,*  FROM [abs_user].[dbo].[kDDActions]
	WHERE CONVERT(nvarchar(50),CONVERT(VARBINARY(MAX),xmleventdata.query('/EVENT_INSTANCE/TSQLCommand/CommandText'))) like '%_dta_%'
	OPTION (MAXDOP 4)
			
--Работа с XML(Xquery)(Иван Никитин, отличный специалист по XML)

	- Зачем база в XML:
		1. Если в базе что-то с очень сложной структурой, дабы не создавать сотни таблиц.
		2. Структура документа меняется с течением времени
		
	DECLARE @Doc XML
	SET @Doc='XML данные'
	SELECT @Doc.query('/Report/Period[1]'),@Doc.query('/Report/Period[2]/Person[1]')
	query --возвращает всегда XML
	value --возвращает данные
	SELECT @Doc.value('(/Report/Period[@Year="2010"])[1]/Person[1]/@SUM','money')
	@Year --обращение к атрибуту
	exist -- показывает есть ли атрибут или нет. Либо 1 либо 0
	nodes --вытащить таблицу
	SELECT MyColumn.value('','')+''+MyColumn.value('',''),MyColumn.value('','')
	FROM @Doc.nodes('') MyTable(MyColumn)--Надо назвать таблицу и столбец
	modify --модифицировать XML
	SET @Doc.modify('insert <Person Name="shtsrhst"/> into (/Report/Period)[1]')
	replace = update
	SET @Doc.modify('replace value of (/Report/Period/Person[@LastName="htsrhjrsj"])[1]/Sum with "750"')
	SET @Doc.modify('delete /Report/Period[@Year="2010"]')

-- FOR XML
- Это атрибут команды SELECT
	SELECT ProductID, ProductName
	FROM Products Product
	FOR XML AUTO
	
	вернёт
	
	<Product ProductID="1" ProductName="Widget"/>
	<Product ProductID="2" ProductName="Sprocket"/>

-- OPENXML
- Предназначена для создания записи на основе переданного ей XML-документа
	DECLARE @doc nvarchar(1000)
	SET @doc = '<Order OrderID = "1011">
	<Item ProductID="1" Quantity="2"/>
	<Item ProductID="2" Quantity="1"/>
	</Order>'
	DECLARE @xmlDoc int
	EXEC sp_XML_preparedocument @xmlDoc OUTPUT, @doc -- Создаём XML документ в памяти
	SELECT * FROM
	OPENXML (@xmlDoc, 'Order/Item', 1)
	WITH
	(OrderID int '../@OrderID',
	ProductID int,
	Quantity int)
	EXEC sp_XML_removedocument @xmlDoc -- Удаляем XML документ из памяти
	
		
-- XML
WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelManuInstructions' as AW) -- Указывает схему внутри xml
SELECT [ProductModelID]
      ,[Name]
      ,[CatalogDescription]
      ,[Instructions].query('AW:root/AW:Location[@LaborHours >2.5]') as greg -- Выведет все вхождения, где LaborHours > 2.5. При этом остальные строки то же будут выведены, просто со значение NULL в это строке. Возвращает xml вид
      ,[rowguid]
      ,[ModifiedDate]
  FROM [AdventureWorks].[Production].[ProductModel]
 
- .query -- возвращает xml вид
- .value -- возвращает sql вид
 
- Чтобы вставить переменную в XML запрос надо использовать sql:variable("@ID") 
- Проверка на существование результата (возвращает 0 или 1) WHERE Instructions.exist('AW:root/AW:Location[@LaborHours >2.5]') = 1
- Вернуть данных в xml в SELECT
	SELECT Name,ProductNumber, ListPrice FROM Production.Product WHERE ProductID = 1 FOR XML RAW -- вернёт результат запроса в xml, стобцы запишутся в атрибуты
	SELECT Name,ProductNumber, ListPrice FROM Production.Product WHERE ProductID = 1 FOR XML RAW, ELEMENTS -- столбца запишутся в элементы
	SELECT * FROM Purchasing.PurchaseOrderHeader as [Order] INNER JOIN Purchasing.Vendor as Vendor ON [Order].VendorID = Vendor.VendorID FOR XML AUTO -- Для сложной структуры. Контролировать такой процесс мы не сможем
	SELECT * FROM Purchasing.PurchaseOrderHeader as [Order] INNER JOIN Purchasing.Vendor as Vendor ON [Order].VendorID = Vendor.VendorID FOR XML Path('Order'), ROOT ('PurchaseOrders') -- Корень PurchaseOrders, элементы - Order
	
	FOR XML AUTO -- автоматическое создание
	FRO XML AUTO, TYPE -- без понятия что
	FOR XML AUTO, TYPE, Elements -- Разбить по элементам
	FOR XML AUTO, TYPE, Elements, ROOT -- по элементам с корнем. Можно написать ROOT('myRoot')
	SELECT Name as MyName... -- Так можно переименовать имена элементов в XML
	FOR XML RAW('myEmployee'), Type, ELEMENTS,ROOT ('myRoot') -- Это даст возможность переименовать корневой элемент
	
- Открыть xml файл
	-- вывести xml документ
	DECLARE @x xml
	SELECT @x = P FROM OPENROWSET (BULK 'C:\\Myxml.xml', SINGLE_BLOB) as Products(P) 
	
	-- Сделать из xml табличный вид. Работаем с атрибутами
	DECLARE @hdoc int
	exec sp_xml_preparedocument @hdoc OUTPUT,@x -- делает проанализированный xml, готовый к работе
	SELECT * FROM OPENXML (@hdoc,'/Subcategories/Subcategory',1) WITH ( ProductSubcategoryID int, Name varchar(100)) -- WITH указывает колонки, которые я хочу вернуть. Цифра 1 говорит о том, что это атрибуты
	exec sp_xml_removedocument @hdoc -- удаляет документ, освобождая память
	
	-- Сделать из xml табличный вид. Работаем с элементами
	DECLARE @hdoc int
	exec sp_xml_preparedocument @hdoc OUTPUT,@x -- делает проанализированный xml, готовый к работе	
	SELECT * FROM OPENXML (@hdoc,'/Subcategories/Subcategory/Products/Product',1) WITH ( ProductID int, Name varchar(100), ProductNumber varchar(100)) -- WITH указывает колонки, которые я хочу вернуть. Цифра 2 говорит о том, что это элементы
	exec sp_xml_removedocument @hdoc -- удаляет документ, освобождая память
	
	-- Сделать из xml табличный вид. Работаем с атрибутами и элементами
	DECLARE @hdoc int
	exec sp_xml_preparedocument @hdoc OUTPUT,@x -- делает проанализированный xml, готовый к работе	
	SELECT * FROM OPENXML (@hdoc,'/Subcategories/Subcategory/Products/Product',2)
	WITH ( ProductSubcategoryID int '../../@ProductSubcategoryID', SubName varchar(100) '../../@Name',ProductID int, Name varchar(100), ProductNumber varchar(100)) -- Указываем имя столбца и где находится атрибут
	exec sp_xml_removedocument @hdoc -- удаляет документ, освобождая память
	
	
-- JSON
	- Если нужен новый проект для хранения документов, то можно использовать DocumentDB
	- Можно и встроить в текущее решение, но нет индексов, храниться будет в varchar, потребуется написание функций