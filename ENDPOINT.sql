CREATE Proc dbo.GetProductListing
AS
SELECT * FROM t1
GO

sp_reserve_http_namespace N'http://localhost:80/sql/products'

CREATE ENDPOINT GetProducts
STATE = STARTED AS HTTP (
SITE = 'localhost',
PATH = '/sql/products',
AUTHENTICATION = (Integrated),
PORTS=(CLEAR)
)
FOR SOAP (
WEBMETHOD 'GetProductListing'
(
name='test.dbo.GetProductListing',
schema=STANDARD
),
--   LOGIN_TYPE = MIXED, -- Поддерживается только в 2008 R2
WSDL = DEFAULT,
DATABASE = 'Test',
BATCHES = ENABLED,
NAMESPACE = 'http://tempUri.org/'
)

GRANT CONNECT ON ENDPOINT ::GetProducts TO test

SELECT * FROm sys.Server_Permissions
SELECT * FROM sys.Server_Principals
SELECT * FROM sys.HTTP_Endpoints
SELECT * FROM sys.Endpoints

