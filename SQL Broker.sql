-- Общее
	1. Создаём Message
	2. Создаём Contract
	3. Создаём Queue

-- Программа для понимания в чём проблемы
	sbdiagnose
	
-- Асинхронный триггер

Service Broker is a new feature from SQL Server 2005. Basically it is an integrated part of the database engine. The Service Broker also supports an asynchronous programming model used in single instances as well as for distributed applications. It also supports queuing and reliable direct asynchronous messaging between SQL Server instances only. 

In this article we learn how to use Service Broker and triggers to capture data changes.

Service Broker is used to create conversations for exchanging messages between two ends, in other words a source (initiator) and a target. Messages are used to transmit data and trigger processing when a message is received. The target and the initiator can be in the same database or different databases on the same instance of the Database Engine or in separate instances.

The Service Broker communicates with a protocol called "Dialog" that allows us bi-directional communication between two endpoints. The Dialog Protocol specifies the logical steps required for a reliable conversation, and ensure that messages are received in the order they were sent.

Image 1.jpg

How to create an asynchronous trigger

Step 1

Enable the Service Broker on the database, as in:

ALTER DATABASE [Database Name] SET ENABLE_BROKER

Sometimes the query above takes a long time to execute, the problem is that it is requires special access to the database. Also there might be a connection that is using this database with a shared lock on it; even if it is idle, it can block the ALTER DATABASE from completing. To fix the problem use ROLLBACK IMMEDIATE or a NO_WAIT statement at the termination options of ALTER DATABASE, as in:

ALTER DATABASE [Database Name] SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE;

Step 2

Create an audit log table and create a procedure that helps to receive messages from a queue, as in:

CREATE TABLE auditlog
(
            xmlstring xml
)
GO
CREATE PROCEDURE [dbo].[spMessageProcTest] 
AS 
BEGIN 
            DECLARE @message_type varchar(100) 
            DECLARE @dialog uniqueidentifier, @message_body XML; 
            WHILE (1 = 1) 
            BEGIN -- Receive the next available message from the queue 
            WAITFOR ( 
                        RECEIVE TOP(1) @message_type = message_type_name,     
                        @message_body = CAST(message_body AS XML),     
                        @dialog = conversation_handle
            FROM dbo.TestQueue ), TIMEOUT 500    if (@@ROWCOUNT = 0 OR @message_body IS NULL) 
            BEGIN 
                        BREAK 
            END 
            ELSE 
                        BEGIN 
                                    --process xml message here...
                                    INSERT INTO auditlog values(@message_body)
                        END
            END CONVERSATION @dialog 
            END
END

Step 3

The next step is to create a Message Type, as in:

-- Create Message Type 
CREATE MESSAGE TYPE TestMessage
AUTHORIZATION dbo 
VALIDATION = WELL_FORMED_XML;

-- Create Contract 
CREATE CONTRACT TestContract
AUTHORIZATION dbo
(TestMessage SENT BY INITIATOR);

-- Create Queue 
CREATE QUEUE dbo.TestQueue WITH STATUS=ON, ACTIVATION 
(STATUS = ON, MAX_QUEUE_READERS = 1, 
PROCEDURE_NAME = spMessageProcTest,   EXECUTE AS OWNER);

-- Create Service Initiator
CREATE SERVICE TestServiceInitiator
AUTHORIZATION dbo
ON QUEUE dbo.TestQueue (TestContract); 
-- Create target Service 
CREATE SERVICE [TestServiceTarget]
AUTHORIZATION dbo 
ON QUEUE dbo.TestQueue (TestContract);

Step 4

Now we can test our logic.

To do that we need to create a table and write a trigger on it. In the trigger we must send our message to the target. In this example I am sending updated data as XML. 

CREATE TABLE [dbo].[DepartmentMaster](
            [DepartmentId] [int] IDENTITY(1,1) NOT NULL,
            [Name] [varchar](50) NULL,
            [Description] [varchar](50) NULL,
 CONSTRAINT [PK_DepartmentMaster1] PRIMARY KEY CLUSTERED 
(
            [DepartmentId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

--Insert some dummy values in tables 
INSERT INTO DepartmentMaster VALUES ('Purchase','Purchase Department'),
 ('Sales','Sales Department'),
 ('Account','Account Department')

--Create trigger for update
CREATE  TRIGGER dbo.Trg_DepartmentMaster_Update 
ON  dbo.DepartmentMaster
FOR UPDATE 
AS 
BEGIN
            SET NOCOUNT ON;
            DECLARE @MessageBody XML  
            DECLARE @TableId int 

            --get relevant information from inserted/deleted and convert to xml message  
            SET @MessageBody = (SELECT DepartmentId,Name,Description FROM inserted  
            FOR XML AUTO)               

            If (@MessageBody IS NOT NULL)  
            BEGIN 

                        DECLARE @Handle UNIQUEIDENTIFIER;   
                        BEGIN DIALOG CONVERSATION @Handle   
                        FROM SERVICE [TestServiceInitiator]   
                        TO SERVICE 'TestServiceTarget'   
                        ON CONTRACT [TestContract]   
                        WITH ENCRYPTION = OFF;   
                        SEND ON CONVERSATION @Handle   
                        MESSAGE TYPE [TestMessage](@MessageBody);
            END
END


-- Мониторинг
	SQL Server Profiler
		Broker:Activation
			Cрабатывает, когда монитор очереди запускает хранимую процедуру активации.
		Broker:Connection
			Cообщает о состоянии транспортного соединения, управляемого Service Broker.
		Broker:Conversation
			Рассказывает о ходе диалога.
		Broker:Conversation Group
			Формируется, когда группа разговора создается или удаляется.
		Broker:Corrupted Message
			Cрабатывает при получении поврежденного сообщения.
		Broker:Forwarded Message Dropped
			Срабатывает, когда сообщение, предназначенное для пересылки, было удалено.
		Broker:Forwarded Message Sent
			Срабатывает, когда сообщение успешно отправлено.
		Broker:Message Classify
			Срабатывает, когда была определена маршрутизация сообщения.
		Broker:Message Undeliverable
			Cрабатывает, когда полученное сообщение, которое должно было быть доставлено службе в этом экземпляре, не может быть сохранено.
		Broker:Mirred Route State Changed
			Происходит, когда изменяется состояние активного зеркального маршрута.
		Broker:Queue Disabled
			Cрабатывает, когда полученное сообщение, которое должно было быть доставлено службе в этом экземпляре, не может быть сохранено.
		Broker:Remote Message Acknowledgement
			Cрабатывает, когда отправляется или принимается подтверждающее сообщение.
		Broker:Transmission
			Cрабатывает, когда на транспортном уровне возникает ошибка. Номер ошибки и значения состояния указывают на источник ошибки.
		Security Audit:Audit Broker Login
			Сообщает о сообщениях аудита, связанных с механизмом обеспечения безопасности транспорта, реализованным в компоненте Service Broker.
		Security Audit:Audit Broker Conversation
			Отчеты аудита, связанные с безопасностью диалога Service Broker.
		
	Extended Events
		
		SELECT dxp.name AS package_name
			  ,dxo.name AS event_name
			  ,dxo.description
		FROM   sys.dm_xe_packages AS dxp 
			   INNER JOIN sys.dm_xe_objects AS dxo 
					   ON dxo.package_guid = dxp.guid
		WHERE  (dxp.capabilities IS NULL
				OR dxp.capabilities & 1 = 0)     -- Exclude private packages.
			   AND (dxo.capabilities IS NULL
					OR dxo.capabilities & 1 = 0) -- Exclude private objects.
			   AND dxo.object_type = 'event'
			   AND dxo.name LIKE '%broker%'
		ORDER  BY dxp.name, dxo.name;
		
	ssbdiagnose

	Catalog Views
		sys.conversation_endpoints
			Это представление каталога содержит строку на конечную точку сеанса в базе данных.
		sys.conversation_groups
			Это представление каталога содержит строку для каждой группы разговоров.
		sys.conversation_priorities
			Содержит строку для каждого приоритета разговора, созданного в текущей базе данных.
		sys.remote_service_bindings
			Это представление каталога содержит строку для привязки к удаленной службе.
		sys.routes
			Представления этого каталога содержат одну строку для каждого маршрута.
		sys.service_contracts
			Это представление каталога содержит строку для каждого контракта в базе данных.
		sys.service_contract_message_usages
			В этом представлении каталога содержится пара строк (контракт, тип сообщения).
		sys.service_contract_usages
			В этом представлении каталога содержится строка за (услуга, контракт).
		sys.service_message_types
			Это представление каталога содержит строку на тип сообщения, зарегистрированную в сервис-брокере.
		sys.service_queue_usages
			Это представление каталога возвращает строку для каждой ссылки между служебной и служебной очередью. Служба может быть связана только с одной очередью. Очередь может быть связана с несколькими службами.
		sys.services
			Это представление каталога содержит строку для каждой службы в базе данных.
		sys.transmission_queue
			Это представление каталога содержит строку для каждого сообщения в очереди передачи.

	Dynamic Management Views (DMVs)
		sys.dm_broker_activated_tasks	
			Возвращает строку для каждой хранимой процедуры, активированной Service Broker.
		sys.dm_broker_forwarded_messages
			Возвращает строку для каждого сообщения Service Broker, что экземпляр SQL Server находится в процессе пересылки.
		sys.dm_broker_connections
			Возвращает строку для каждого сетевого подключения Service Broker.
		sys.dm_broker_queue_monitors
			Возвращает строку для каждого монитора очереди в экземпляре.

	Views
		sys.conversation_priorities
			Приоритеты разговора.
		sys.conversation_endpoints
			Конечные точки сеансов.
		sys.conversation_groups
			Группы разговоров.
		sys.transmission_queue
			Сообщения в очереди передачи.

		sys.service_message_types
		sys.service_contracts
		sys.service_contract_message_usages
		sys.service_queues
		sys.services
		sys.service_contract_usages