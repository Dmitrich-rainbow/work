Использование SQLCLR для увеличения производительности
Начиная c MS SQL Server 2005 в распоряжение разработчиков баз данных была добавлена очень мощная технология SQL CLR.
Эта технология позволяет расширять функциональность SQL сервера с помощью .NET языков, например C# или VB.NET.
Используя SQL CLR можно создавать написанные на высокопроизводительных языках свои хранимые процедуры, триггеры, пользовательские типы и функции, а также агрегаты. Это позволяет серьезно повысить производительность и расширить функциональность сервера до немыслимых границ.
Рассмотрим простой пример: напишем пользовательскую функцию разрезания строки по разделителю используя SQL синтаксис и SQL CLR на базе C# и сравним результаты.

--Пользовательская функция, возвращающая таблицу:

CREATE FUNCTION SplitString (@text NVARCHAR(max), @delimiter nchar(1))
RETURNS @Tbl TABLE (part nvarchar(max), ID_ORDER integer) AS
BEGIN
  declare @index integer
  declare @part  nvarchar(max)
  declare @i   integer
  set @index = -1
  set @i=1
  while (LEN(@text) > 0) begin
    set @index = CHARINDEX(@delimiter, @text)
    if (@index = 0) AND (LEN(@text) > 0) BEGIN
      set @part = @text
      set @text = ''
    end else if (@index > 1) begin
      set @part = LEFT(@text, @index - 1)
      set @text = RIGHT(@text, (LEN(@text) - @index))
    end else begin
      set @text = RIGHT(@text, (LEN(@text) - @index)) 
    end
    insert into @Tbl(part, ID_ORDER) values(@part, @i)
    set @i=@i+1
  end
  RETURN
END
go


--Эта функция разрезает входную строку используя разделитель и возвращает таблицу. Применять такую функцию очень удобно, например, для быстрого заполнения временной таблицы записями.
select part into #tmpIDs from SplitString('11,22,33,44', ',')

--В результате таблица #tmpIDs будет содержать 
11
22
33
44

--Модуль CLR написанный на C#:
--Создадим файл SplitString.cs со следующим содержимым:
using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
public class UserDefinedFunctions {
  [SqlFunction(FillRowMethodName = "SplitStringFillRow", TableDefinition = "part NVARCHAR(MAX), ID_ORDER INT")]
  static public IEnumerator SplitString(SqlString text, char[] delimiter)
  {
    if(text.IsNull) yield break;
    int valueIndex = 1;
    foreach(string s in text.Value.Split(delimiter, StringSplitOptions.RemoveEmptyEntries)) {
      yield return new KeyValuePair<int, string>(valueIndex++, s.Trim());
    }
  }
  static public void SplitStringFillRow(object oKeyValuePair, out SqlString value, out SqlInt32 valueIndex)
  {
    KeyValuePair<int, string> keyValuePair = (KeyValuePair<int, string>) oKeyValuePair;
    valueIndex = keyValuePair.Key;
    value = keyValuePair.Value;
  }
} 


--Скомпилируем модуль(обязательно v2, более высокие не работают):
%SYSTEMROOT%\Microsoft.NET\Framework\v2.0.50727\csc.exe /target:library c:\SplitString.cs

На выходе получаем SplitString.dll

--Теперь, необходимо разрешить использование CLR в SQL Server:
sp_configure 'clr enabled', 1
go
reconfigure
go

--Все, можно подключать модуль.

CREATE ASSEMBLY CLRFunctions FROM 'C:\SplitString.dll' 
go

--И создавать пользовательскую функцию.
CREATE FUNCTION [dbo].SplitStringCLR(@text [nvarchar](max), @delimiter [nchar](1))
RETURNS TABLE (
part nvarchar(max),
ID_ODER int
) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME CLRFunctions.UserDefinedFunctions.SplitString

--Вызвать функцию 
SELECT * FROM SplitStringCLR('Hello my Friend', 'l') 


--Дополнительно о CLR
1. Сборка загружается на сервер и хранится там. Функции, которые ссылаются на сборку уже хранятся в базе. Поэтому нужно, чтобы на сервере, куда переносится база, сборка была загружена.
2. При создании сборки, если нужно, указывается аргумент PERMISSION_SET, который определяет разрешения для сборки. Советую посмотреть MSDN. Вкратце: SAFE — разрешает работать только с базой; EXTERNAL_ACCESS — разрешает работать с другими серверами, файловой системой и сетевыми ресурсами; UNSAFE — все что угодно, включая WinAPI.
3. Есть особенности при отладке, какие именно, указано в MSDN.

Среднее значение времени работы для SplitString получилось 6.152 мс, а для SplitStringCLR 1.936 мс.
Разница более чем в 3 раза.
