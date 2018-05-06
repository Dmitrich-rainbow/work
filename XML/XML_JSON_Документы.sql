-- XML
	- �����������, ����� ����� �������� � ������� ������� ���������������. ��� ������ ����� ������������ DocumentDB
	- ������������ �������
	- ������ � XML ����������� ����������� CPU
	
	-- ����� ��������� ������ �������� ������������ �������
		1. ������� ���������
		2. ��������� ���������� ���������

	-- ������
		1. � SQL Server ������ � XML ������� � ��������� ��������
		
-- ���� �� SQL (Joes2Pros), ���
	<NFC> -- root element
		<AFC Name="American Football Conference"> -- top level element with Attribute
		</AFC>
	</NFC>
	
	-- ������� ��������� xml �������� �� ������� ������.  ������ ��������� � ���������
		SELECT * FROM [claim] FOR XML RAW 
		SELECT * FROM [claim] FOR XML AUTO -- �� �� �����, ������ ������� ����� �� row, � �������� �������
		SELECT * FROM [claim] FOR XML RAW('claim') -- ������������� �������� � row �� claim
	
	-- JOIN
		- ���� ������������ JOIN � AUTO, �� �� ������ ��������� ���������. � ���� ������ ����� ������� ������ �����, ������ ������� ����� top level element
		
	-- ROOT
		- �������� ROOT �������
		SELECT * FROM [claim] FOR XML AUTO, ROOT('ART')
	
	-- ORDER BY. ����������
		- ���������� ������ ������������� ������ � �������
		
	-- ELEMENTS
		- ������� ����� ������ �� �������� ������ ���������
		- ���� �������� ���� NULL, �� �� �� ��������� ��� � ��� ����� ���� ������� ELEMENTS XSINIL
			SELECT c.imname,r.note,r.price FROM currency c INNER JOIN reklama r ON c.inc=r.currency AND c.imname IS NOT NULL FOR XML AUTO, ROOT('ART'), ELEMENTS
			
	-- PATH
		- ���������� ������� ELEMENTS,ROW	
		- ���� �� ����� ������� � ������� �����-�� ��������, �� ���� ������ ��� ��� [@MyName] ����� ������ � ����. ������
			SELECT c.imname,r.note,r.price FROM currency c INNER JOIN reklama r ON c.inc=r.currency AND c.imname IS NOT NULL FOR XML PATH
			
	-- RENAME/ALIAS/������������ ��������
		- ������ ��������������� ������
	
	-- ����������� ��������� ��� ���� �����
		- ������������� [Name/First] � [Name/Last]
		
	-- ������� ������ �� �������� � ���������� ��� �� ����������, ����� �������������� ����.
		- �� ��� ������ Top Element
		- ����� ��� ���������� - ���������� ������ ���/alias ������� as [*]
		
	-- Export/Import. �������/������
		- ������������� xml � ���� �������� SELECT		
			DECLARE @doc xml
			SET @Doc = '<Town name="�����, ��������" lname="Dubai, Jumeirah">
			  <Hotel name="JUMEIRAH BEACH HOTEL" partner="2490">
				<Main inc="39413" cost="17178.0000" />
				<Order inc="58942" cost="690.4000" />
			  </Hotel>
			  <Hotel name="Next Hotel" partner="2491">
				<Main inc="11" cost="33.0000" />
				<Order inc="22" cost="44.4000" />
			  </Hotel>
			</Town>'

			DECLARE @hDoc int -- �������� ����� �������� XML
			EXEC sp_xml_prepareDocument @hDoc OUTPUT, @Doc -- ����������� xml � �������� � ����. ��� ���� ������ ��� �������� ����� �������, � ������ �� ���������, ������� ���� �� �������� ������� �������

			SELECT @hDoc

			SELECT * FROM Openxml(@hDoc,'/Town/Hotel/Order') -- �������� ������ � ��������� ���������. ������ ������ �� Order
			WITH (inc int, cost decimal(8,2)) -- ��������� ������ ��������� � �������. �� ����� ������� ������ 1 �������. ����������� ��������� ����� ��� � XML. ������� �����.
			WITH (Number int '@inc',cost decimal(8,2)) -- ��� ����� ������������� �������� �������. inc > Number
			
			EXEC sp_xml_RemoveDocument @hDoc -- �������� XML ��������� �� ������, � ��������� ���������
			
		- ����� ���������� ���������
			SELECT * FROM Openxml(@hDoc,'/Town//Emp') -- ������ ����� ��� ��������� � Emp � �������� ��� ������, ������� �� ������ � WITH
		
		- ����� ������ �� 1 ������� ����
			WITH ([User] nvarchar(50), BossName nvarchar(50) '../@User') -- ���� ��� ���� ������ ���� User �� 1 ������� ����
			
		- ����� ������ �� 2 �������� ����
			'../../@User'
			
		- Openxml
			Openxml(@hDoc,'/Town/Hotel/Order',1) -- ������� ������ ��������
			Openxml(@hDoc,'/Town/Hotel/Order',2) -- ������� ������ ��������
			Openxml(@hDoc,'/Town/Hotel/Order',3) -- ������� � �� � ��
			
		- ������ � ����� XML
			-- query() ��������� � ������ � ��������, ���� � ����� ���� ���������, �� ����� �������� �������. ����� ������� ����� ���� ����������� �������� ����� �������� ;WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
			SELECT xmlField.query('/Songs/Song') FROM MyXML -- ������� ��� �������� ������ Song
			SELECT xmlField.query('(/Songs/Song)[2]') FROM MyXML -- �������� 2 ������� ������ Song
			SELECT xmlField.query('(/Songs/Song)[1]/WriterName') FROM MyXML -- �������� ������� WriterName � 1 ������ Song
			SELECT xmlField.query('(/Songs/Song)[1]/WriterName/text()') FROM MyXML -- �������� ������ �����
			SELECT xmlField.query('(/Songs/Song)[1]/WriterName/text())[1]') FROM MyXML -- �������� ������ ����� ������� ��������
			SELECT xmlField.query('(/Songs/Song)[2]/Singer[2]') FROM MyXML -- ��� �� ����� �������� ���������� ��������
			SELECT xmlField.query('(/Songs/Song[@TitleID=13160])') FROM MyXML -- �������� ��������� � ����������� �������
			SELECT @xml.query('data(/upperLevel/Company/Director[@Name = "Paul"]/@Age)') -- �������� ������ ������ �������� Age, ��� ��� Paul
			SELECT @xml.value('(/upperLevel/Company[1]/Director)[1]','nvarchar(50)') -- �������� �������� ������� �������� Company � ������� �������� Director
			SELECT @xml.exist('/upperLevel/Company[@Name1="Company1"]') -- �������� �� ������������� ������
			SET @xml.modify('replace value of (/upperLevel/Company[@Name1="Company1"]/Director/text())[1] with "Walk"') -- �������� ������ � XML
			SELECT @xml.query('for $ManyHits in /upperLevel/Company where count($ManyHits/Director) > 1 return $ManyHits') -- �������� ����� ��������, ������� ����� ����� 1 ��������
			SELECT @xml.query('<Delivery>{for $t in /upperLevel/Company return $t/Director}</Delivery>') -- �������� �������� �������
			SELECT @xml.query('<Delivery>{/upperLevel/Company}</Delivery>') -- �������� �������� �������
			SELECT xmlFrield.query('<Delivery><DriverName>{sql:column("Driver")}</DriverName>{/upperLevel/Company}</Delivery>') -- �������� �������� �� �������
		
		- CROSS APPLY -- �������� ������ ��� ������ ����� � ���� XML
			SELECT MusicTypeID, SongDetails.value('@TitleID', 'int'),SongDetails.value('WriterName[1]','varchar(max)')
			FROM MusicHistory
			CROSS APPLY MusicDetails.nodes('//Music/Song') as SongTable(SongDetails) -- MusicDetails - ������� XML
			
-- ���� xml/�������
	SELECT TOP 1000 xmleventdata.query('/EVENT_INSTANCE/TSQLCommand/CommandText') as xmll,*  FROM [abs_user].[dbo].[kDDActions]
	WHERE CONVERT(nvarchar(50),CONVERT(VARBINARY(MAX),xmleventdata.query('/EVENT_INSTANCE/TSQLCommand/CommandText'))) like '%_dta_%'
	OPTION (MAXDOP 4)
			
--������ � XML(Xquery)(���� �������, �������� ���������� �� XML)

	- ����� ���� � XML:
		1. ���� � ���� ���-�� � ����� ������� ����������, ���� �� ��������� ����� ������.
		2. ��������� ��������� �������� � �������� �������
		
	DECLARE @Doc XML
	SET @Doc='XML ������'
	SELECT @Doc.query('/Report/Period[1]'),@Doc.query('/Report/Period[2]/Person[1]')
	query --���������� ������ XML
	value --���������� ������
	SELECT @Doc.value('(/Report/Period[@Year="2010"])[1]/Person[1]/@SUM','money')
	@Year --��������� � ��������
	exist -- ���������� ���� �� ������� ��� ���. ���� 1 ���� 0
	nodes --�������� �������
	SELECT MyColumn.value('','')+''+MyColumn.value('',''),MyColumn.value('','')
	FROM @Doc.nodes('') MyTable(MyColumn)--���� ������� ������� � �������
	modify --�������������� XML
	SET @Doc.modify('insert <Person Name="shtsrhst"/> into (/Report/Period)[1]')
	replace = update
	SET @Doc.modify('replace value of (/Report/Period/Person[@LastName="htsrhjrsj"])[1]/Sum with "750"')
	SET @Doc.modify('delete /Report/Period[@Year="2010"]')

-- FOR XML
- ��� ������� ������� SELECT
	SELECT ProductID, ProductName
	FROM Products Product
	FOR XML AUTO
	
	�����
	
	<Product ProductID="1" ProductName="Widget"/>
	<Product ProductID="2" ProductName="Sprocket"/>

-- OPENXML
- ������������� ��� �������� ������ �� ������ ����������� �� XML-���������
	DECLARE @doc nvarchar(1000)
	SET @doc = '<Order OrderID = "1011">
	<Item ProductID="1" Quantity="2"/>
	<Item ProductID="2" Quantity="1"/>
	</Order>'
	DECLARE @xmlDoc int
	EXEC sp_XML_preparedocument @xmlDoc OUTPUT, @doc -- ������ XML �������� � ������
	SELECT * FROM
	OPENXML (@xmlDoc, 'Order/Item', 1)
	WITH
	(OrderID int '../@OrderID',
	ProductID int,
	Quantity int)
	EXEC sp_XML_removedocument @xmlDoc -- ������� XML �������� �� ������
	
		
-- XML
WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelManuInstructions' as AW) -- ��������� ����� ������ xml
SELECT [ProductModelID]
      ,[Name]
      ,[CatalogDescription]
      ,[Instructions].query('AW:root/AW:Location[@LaborHours >2.5]') as greg -- ������� ��� ���������, ��� LaborHours > 2.5. ��� ���� ��������� ������ �� �� ����� ��������, ������ �� �������� NULL � ��� ������. ���������� xml ���
      ,[rowguid]
      ,[ModifiedDate]
  FROM [AdventureWorks].[Production].[ProductModel]
 
- .query -- ���������� xml ���
- .value -- ���������� sql ���
 
- ����� �������� ���������� � XML ������ ���� ������������ sql:variable("@ID") 
- �������� �� ������������� ���������� (���������� 0 ��� 1) WHERE Instructions.exist('AW:root/AW:Location[@LaborHours >2.5]') = 1
- ������� ������ � xml � SELECT
	SELECT Name,ProductNumber, ListPrice FROM Production.Product WHERE ProductID = 1 FOR XML RAW -- ����� ��������� ������� � xml, ������ ��������� � ��������
	SELECT Name,ProductNumber, ListPrice FROM Production.Product WHERE ProductID = 1 FOR XML RAW, ELEMENTS -- ������� ��������� � ��������
	SELECT * FROM Purchasing.PurchaseOrderHeader as [Order] INNER JOIN Purchasing.Vendor as Vendor ON [Order].VendorID = Vendor.VendorID FOR XML AUTO -- ��� ������� ���������. �������������� ����� ������� �� �� ������
	SELECT * FROM Purchasing.PurchaseOrderHeader as [Order] INNER JOIN Purchasing.Vendor as Vendor ON [Order].VendorID = Vendor.VendorID FOR XML Path('Order'), ROOT ('PurchaseOrders') -- ������ PurchaseOrders, �������� - Order
	
	FOR XML AUTO -- �������������� ��������
	FRO XML AUTO, TYPE -- ��� ������� ���
	FOR XML AUTO, TYPE, Elements -- ������� �� ���������
	FOR XML AUTO, TYPE, Elements, ROOT -- �� ��������� � ������. ����� �������� ROOT('myRoot')
	SELECT Name as MyName... -- ��� ����� ������������� ����� ��������� � XML
	FOR XML RAW('myEmployee'), Type, ELEMENTS,ROOT ('myRoot') -- ��� ���� ����������� ������������� �������� �������
	
- ������� xml ����
	-- ������� xml ��������
	DECLARE @x xml
	SELECT @x = P FROM OPENROWSET (BULK 'C:\\Myxml.xml', SINGLE_BLOB) as Products(P) 
	
	-- ������� �� xml ��������� ���. �������� � ����������
	DECLARE @hdoc int
	exec sp_xml_preparedocument @hdoc OUTPUT,@x -- ������ ������������������ xml, ������� � ������
	SELECT * FROM OPENXML (@hdoc,'/Subcategories/Subcategory',1) WITH ( ProductSubcategoryID int, Name varchar(100)) -- WITH ��������� �������, ������� � ���� �������. ����� 1 ������� � ���, ��� ��� ��������
	exec sp_xml_removedocument @hdoc -- ������� ��������, ���������� ������
	
	-- ������� �� xml ��������� ���. �������� � ����������
	DECLARE @hdoc int
	exec sp_xml_preparedocument @hdoc OUTPUT,@x -- ������ ������������������ xml, ������� � ������	
	SELECT * FROM OPENXML (@hdoc,'/Subcategories/Subcategory/Products/Product',1) WITH ( ProductID int, Name varchar(100), ProductNumber varchar(100)) -- WITH ��������� �������, ������� � ���� �������. ����� 2 ������� � ���, ��� ��� ��������
	exec sp_xml_removedocument @hdoc -- ������� ��������, ���������� ������
	
	-- ������� �� xml ��������� ���. �������� � ���������� � ����������
	DECLARE @hdoc int
	exec sp_xml_preparedocument @hdoc OUTPUT,@x -- ������ ������������������ xml, ������� � ������	
	SELECT * FROM OPENXML (@hdoc,'/Subcategories/Subcategory/Products/Product',2)
	WITH ( ProductSubcategoryID int '../../@ProductSubcategoryID', SubName varchar(100) '../../@Name',ProductID int, Name varchar(100), ProductNumber varchar(100)) -- ��������� ��� ������� � ��� ��������� �������
	exec sp_xml_removedocument @hdoc -- ������� ��������, ���������� ������
	
	
-- JSON
	- ���� ����� ����� ������ ��� �������� ����������, �� ����� ������������ DocumentDB
	- ����� � �������� � ������� �������, �� ��� ��������, ��������� ����� � varchar, ����������� ��������� �������