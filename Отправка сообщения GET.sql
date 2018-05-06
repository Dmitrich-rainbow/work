--–¿¡Œ◊»… ¬¿–»¿Õ“
	 - http://www.sql.ru/forum/682646/winhttp-winhttprequest-5-1-post-metod

DECLARE @URI varchar(2000), @methodName varchar(50)

SELECT @URI='http://www.arttour.ru/mssql_test.php?test=1',@methodName='GET'

DECLARE @objectID int, @hResult int
EXEC 	@hResult = sp_OACreate 'WinHttp.WinHttpRequest.5.1', @objectID OUT
EXEC    @hResult = sp_OAMethod @objectID, 'open', null, @methodName, @URI, 'false'
EXEC 	@hResult = sp_OAMethod @objectID, 'send', null

--Ã”—Œ–, Œ“ÕŒ—ﬂŸ»…—ﬂ   ›“Œ… “≈Ã≈

DECLARE @URI varchar(2000), @methodName varchar(50), @Request xml

SELECT @Request	= (SELECT * FROM dbo.best_filter FOR XML RAW ('Inc'), ROOT ('State'), ELEMENTS)

SELECT @URI='http://www.arttour.ru/mssql_test.php',@methodName='POST'

DECLARE @objectID int, @hResult int
EXEC 	@hResult = sp_OACreate 'MSXML2.ServerXMLHTTP', @objectID OUT
EXEC    @hResult = sp_OAMethod @objectID, 'open', null, @methodName, @URI, 'false'
EXEC 	@hResult = sp_OAMethod @objectID, 'send', null, @Request
--EXEC @hResult = sp_OAMethod @objectID ,'setRequestHeader'	,NULL ,'Content-Type'	,'text/xml; charset=utf-8'
--exec @hResult = sp_OASetProperty @objectID, 'Option', 0x100
--WinHttp.WinHttpRequest.5.1
--MSXML2.ServerXMLHTTP
--Microsoft.XMLHTTP
--MSXML2.XMLHttp
--SELECT @Request	= (SELECT * FROM dbo.best_filter FOR XML RAW ('Inc'), ROOT ('State'), ELEMENTS)
--, @Request xml



declare @obj int, @ret  int, @text varchar(max), @url varchar(max)

select @url = 'http://www.arttour.ru/mssql_test.php'

exec @ret = sp_OACreate 'MSXML2.ServerXMLHTTP', @obj out

exec @ret = sp_OAMethod @obj, 'Open', null, 'POST', @url, 'false'

exec @ret = sp_OAMethod @obj, 'setRequestHeader', null, 'Content-Type', 'text/xml; charset=utf-8'

exec @ret = sp_OAMethod @obj, 'setOption', null, 2 ,13056
EXEC 	@ret = sp_OAMethod @obj, 'send', null, 123


sp_configure 'clr enabled', '1'
RECONFIGURE;
