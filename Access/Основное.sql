-- �������� � ������ ��������������
- ������� ������ � ������� Shift

-- �������������� ����� ������
Format(��������� [, ������ ] [, ������_����_������ ] [, ������_������_���� ] )

-- ������ BETWEEN(��� ��� ���)
Date >'10/12/2012' AND Date <'15/12/2012'

CBool(expression) -- expression ��� ��� �������, ������� ���� �������������
CByte(expression)
CCur(expression)
CDate(expression)
CDbl(expression)
CDec(expression)
CInt(expression)
CLng(expression)
CSng(expression)
CStr(expression)
CVar(expression)

-- ����
��� ���������� ������ ���� ���� ���� ��������� NULL, ���� '00:00:00'

-- ������� ����
Date()

-- ������ ������
SELECT MSysObjects.Name 
FROM MSysObjects 
WHERE (((MSysObjects.Type)=1) AND ((MSysObjects.Flags)=0));