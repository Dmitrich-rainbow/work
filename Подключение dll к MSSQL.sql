������������� SQLCLR ��� ���������� ������������������
������� c MS SQL Server 2005 � ������������ ������������� ��� ������ ���� ��������� ����� ������ ���������� SQL CLR.
��� ���������� ��������� ��������� ���������������� SQL ������� � ������� .NET ������, �������� C# ��� VB.NET.
��������� SQL CLR ����� ��������� ���������� �� ���������������������� ������ ���� �������� ���������, ��������, ���������������� ���� � �������, � ����� ��������. ��� ��������� �������� �������� ������������������ � ��������� ���������������� ������� �� ���������� ������.
���������� ������� ������: ������� ���������������� ������� ���������� ������ �� ����������� ��������� SQL ��������� � SQL CLR �� ���� C# � ������� ����������.

--���������������� �������, ������������ �������:

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


--��� ������� ��������� ������� ������ ��������� ����������� � ���������� �������. ��������� ����� ������� ����� ������, ��������, ��� �������� ���������� ��������� ������� ��������.
select part into #tmpIDs from SplitString('11,22,33,44', ',')

--� ���������� ������� #tmpIDs ����� ��������� 
11
22
33
44

--������ CLR ���������� �� C#:
--�������� ���� SplitString.cs �� ��������� ����������:
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


--������������ ������(����������� v2, ����� ������� �� ��������):
%SYSTEMROOT%\Microsoft.NET\Framework\v2.0.50727\csc.exe /target:library c:\SplitString.cs

�� ������ �������� SplitString.dll

--������, ���������� ��������� ������������� CLR � SQL Server:
sp_configure 'clr enabled', 1
go
reconfigure
go

--���, ����� ���������� ������.

CREATE ASSEMBLY CLRFunctions FROM 'C:\SplitString.dll' 
go

--� ��������� ���������������� �������.
CREATE FUNCTION [dbo].SplitStringCLR(@text [nvarchar](max), @delimiter [nchar](1))
RETURNS TABLE (
part nvarchar(max),
ID_ODER int
) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME CLRFunctions.UserDefinedFunctions.SplitString

--������� ������� 
SELECT * FROM SplitStringCLR('Hello my Friend', 'l') 


--������������� � CLR
1. ������ ����������� �� ������ � �������� ���. �������, ������� ��������� �� ������ ��� �������� � ����. ������� �����, ����� �� �������, ���� ����������� ����, ������ ���� ���������.
2. ��� �������� ������, ���� �����, ����������� �������� PERMISSION_SET, ������� ���������� ���������� ��� ������. ������� ���������� MSDN. �������: SAFE � ��������� �������� ������ � �����; EXTERNAL_ACCESS � ��������� �������� � ������� ���������, �������� �������� � �������� ���������; UNSAFE � ��� ��� ������, ������� WinAPI.
3. ���� ����������� ��� �������, ����� ������, ������� � MSDN.

������� �������� ������� ������ ��� SplitString ���������� 6.152 ��, � ��� SplitStringCLR 1.936 ��.
������� ����� ��� � 3 ����.
