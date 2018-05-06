-- Enable Service Broker and switch to the database
USE master;
GO

IF DB_ID('SingleDB_Broker') IS NOT NULL
BEGIN
	ALTER DATABASE SingleDB_Broker SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE SingleDB_Broker;
END
GO

CREATE DATABASE SingleDB_Broker;
GO

ALTER DATABASE SingleDB_Broker
      SET ENABLE_BROKER;
GO

USE SingleDB_Broker;
GO

-- Create the message types
CREATE MESSAGE TYPE [http://www.sqlskills.com/InsiderDemos/AsyncRequest]
VALIDATION = WELL_FORMED_XML;
GO

CREATE MESSAGE TYPE [http://www.sqlskills.com/InsiderDemos/AsyncResult]
VALIDATION = WELL_FORMED_XML;
GO

-- Create the contract
CREATE CONTRACT [http://www.sqlskills.com/InsiderDemos/AsyncContract]
      ([http://www.sqlskills.com/InsiderDemos/AsyncRequest] SENT BY INITIATOR,
       [http://www.sqlskills.com/InsiderDemos/AsyncResult]  SENT BY TARGET);
GO

-- Create the processing queue and service
CREATE QUEUE SQLskills_Demos_ProcessingQueue;
GO
CREATE SERVICE [http://www.sqlskills.com/InsiderDemos/ProcessingService]
ON QUEUE SQLskills_Demos_ProcessingQueue ([http://www.sqlskills.com/InsiderDemos/AsyncContract]);
GO

-- Create the request queue and service
CREATE QUEUE SQLskills_Demos_RequestQueue;
GO
CREATE SERVICE [http://www.sqlskills.com/InsiderDemos/RequestService]
ON QUEUE SQLskills_Demos_RequestQueue;
GO

-- Create processing procedure for processing queue
CREATE PROCEDURE SQLskills_Demos_ProcessingQueueActivation
AS

  DECLARE @conversation_handle UNIQUEIDENTIFIER;
  DECLARE @message_body XML;
  DECLARE @message_type_name sysname;

  WHILE (1=1)
  BEGIN

    BEGIN TRANSACTION;

    WAITFOR
    ( RECEIVE TOP(1)
        @conversation_handle = conversation_handle,
        @message_body = CAST(message_body AS XML),
        @message_type_name = message_type_name
      FROM SQLskills_Demos_ProcessingQueue
    ), TIMEOUT 5000;

    IF (@@ROWCOUNT = 0)
    BEGIN
      ROLLBACK TRANSACTION;
      BREAK;
    END

    IF @message_type_name = N'http://www.sqlskills.com/InsiderDemos/AsyncRequest'
    BEGIN

		-- Handle complex long processing here
		DECLARE @AccountNumber INT = @message_body.value('(AsyncRequest/AccountNumber)[1]', 'INT') -- Get AccountNumber

		-- Build reply message and send back
		DECLARE @reply_message_body XML = N'<AsyncResult>
	<AccountNumber>' + CAST(@AccountNumber AS NVARCHAR) + '</AccountNumber>
</AsyncResult>';
 
       SEND ON CONVERSATION @conversation_handle
              MESSAGE TYPE [http://www.sqlskills.com/InsiderDemos/AsyncResult] (@reply_message_body);
    END

	-- If end dialog message, end the dialog
    ELSE IF @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
    BEGIN
       END CONVERSATION @conversation_handle;
    END

	-- If error message, log and end conversation
    ELSE IF @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error'
    BEGIN

		-- Log the error code here

		END CONVERSATION @conversation_handle;
    END
      
    COMMIT TRANSACTION;

  END
GO

-- Create procedure for processing replies to the request queue
CREATE PROCEDURE SQLskills_Demos_RequestQueueActivation
AS

  DECLARE @conversation_handle UNIQUEIDENTIFIER;
  DECLARE @message_body XML;
  DECLARE @message_type_name sysname;

  WHILE (1=1)
  BEGIN

    BEGIN TRANSACTION;

    WAITFOR
    ( RECEIVE TOP(1)
        @conversation_handle = conversation_handle,
        @message_body = CAST(message_body AS XML),
        @message_type_name = message_type_name
      FROM SQLskills_Demos_RequestQueue
    ), TIMEOUT 5000;

    IF (@@ROWCOUNT = 0)
    BEGIN
      ROLLBACK TRANSACTION;
      BREAK;
    END

    IF @message_type_name = N'http://www.sqlskills.com/InsiderDemos/AsyncResult'
    BEGIN
		-- If necessary handle the reply here
		DECLARE @AccountNumber INT = @message_body.value('(AsyncResult/AccountNumber)[1]', 'INT') -- Get AccountNumber
		DECLARE @Result NVARCHAR(250) = N'Processing for AccountNumber: ' + CAST(@AccountNumber AS NVARCHAR) + ' completed.';
		RAISERROR(@Result, 10, 1) WITH LOG;

		SELECT @message_body AS AsyncResultMessage
    END

	-- If end dialog message, end the dialog
    ELSE IF @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
    BEGIN
       END CONVERSATION @conversation_handle;
    END

	-- If error message, log and end conversation
    ELSE IF @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error'
    BEGIN
       END CONVERSATION @conversation_handle;
    END
      
    COMMIT TRANSACTION;

  END
GO





-- TEST THINGS OUT




EXECUTE sp_cycle_errorlog;  -- Clear log for simplicity here

-- Begin a conversation and send a request message
DECLARE @conversation_handle UNIQUEIDENTIFIER;
DECLARE @request_message_body XML;

BEGIN TRANSACTION;

BEGIN DIALOG @conversation_handle
	FROM SERVICE [http://www.sqlskills.com/InsiderDemos/RequestService]
	TO SERVICE N'http://www.sqlskills.com/InsiderDemos/ProcessingService'
	ON CONTRACT [http://www.sqlskills.com/InsiderDemos/AsyncContract]
	WITH ENCRYPTION = OFF;

SELECT @request_message_body = N'<AsyncRequest>
	<AccountNumber>12345</AccountNumber>
</AsyncRequest>';

SEND ON CONVERSATION @conversation_handle
     MESSAGE TYPE [http://www.sqlskills.com/InsiderDemos/AsyncRequest]
     (@request_message_body);

SELECT @request_message_body AS RequestMessageSent;

COMMIT TRANSACTION;
GO

-- Check for message on processing queue
SELECT CAST(message_body AS XML)
FROM SQLskills_Demos_ProcessingQueue;
GO

-- Process the message from the processing queue
EXECUTE SQLskills_Demos_ProcessingQueueActivation;
GO

-- Check for reply message on request queue
SELECT CAST(message_body AS XML)
FROM SQLskills_Demos_RequestQueue;
GO

-- Process the message from the request queue
EXECUTE SQLskills_Demos_RequestQueueActivation;
GO

-- Check the log for message
EXECUTE xp_readerrorlog;

-- Alter the target queue to specify internal activation
ALTER QUEUE SQLskills_Demos_ProcessingQueue
    WITH ACTIVATION
    ( STATUS = ON,
      PROCEDURE_NAME = SQLskills_Demos_ProcessingQueueActivation,
      MAX_QUEUE_READERS = 10,
      EXECUTE AS SELF
    );
GO

-- Alter the target queue to specify internal activation
ALTER QUEUE SQLskills_Demos_RequestQueue
    WITH ACTIVATION
    ( STATUS = ON,
      PROCEDURE_NAME = SQLskills_Demos_RequestQueueActivation,
      MAX_QUEUE_READERS = 10,
      EXECUTE AS SELF
    );
GO


-- Test automated activation
-- Begin a conversation and send a request message
DECLARE @conversation_handle UNIQUEIDENTIFIER;
DECLARE @request_message_body XML;

BEGIN TRANSACTION;

BEGIN DIALOG @conversation_handle
	FROM SERVICE [http://www.sqlskills.com/InsiderDemos/RequestService]
	TO SERVICE N'http://www.sqlskills.com/InsiderDemos/ProcessingService'
	ON CONTRACT [http://www.sqlskills.com/InsiderDemos/AsyncContract]
	WITH ENCRYPTION = OFF;

SELECT @request_message_body = N'<AsyncRequest>
	<AccountNumber>98765</AccountNumber>
</AsyncRequest>';

SEND ON CONVERSATION @conversation_handle
     MESSAGE TYPE [http://www.sqlskills.com/InsiderDemos/AsyncRequest]
     (@request_message_body);

SELECT @request_message_body AS RequestMessageSent;

COMMIT TRANSACTION;
GO


-- Check for message on processing queue
SELECT CAST(message_body AS XML)
FROM SQLskills_Demos_ProcessingQueue;
GO

-- Check for reply message on request queue
SELECT CAST(message_body AS XML)
FROM SQLskills_Demos_RequestQueue;
GO

-- Check for processing completed message in ErrorLog
EXECUTE xp_readerrorlog;
GO