-��������� �������� ��������������
set nocount on
declare @d datetime
set @d=convert(char(8),getdate(),112)
select '���� ',@d
 
select '������ ���� ������',
dateadd(day,1-day(@d),@d)
 
select  '��������� ���� ������',
dateadd(month,1,dateadd(day,1-day(@d),@d))-1
 
select '������ ���� ����',
dateadd(day,1-datepart(dayofyear,@d),@d),
convert(datetime,'1/1/'+convert(char(4),year(@d)),101)
 
select '��������� ���� ����',
convert(datetime,'12/31/'+convert(char(4),year(@d)),101)
 

select '������ ���� ��������',
convert(datetime,convert(varchar(2),(month(@d)-1)/3*3+1)+'/1/'+convert(char(4),year(@d)),101),
convert(datetime,convert(varchar(2),convert(varchar(2),(datepart(quarter,@d)-1)*3)+1)+'/1/'+convert(char(4),year(@d)),101)

 
select '��������� ���� ��������',
dateadd(month,3,convert(datetime,convert(varchar(2),(month(@d)-1)/3*3+1)+'/1/'+convert(char(4),year(@d)),101))-1
 
print '������� ��������� ���� ������'
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
select @i as �����, dateadd(d,
--������ ����������� ������
7-datepart(dw,convert(datetime,@m+'/1/'+@y,101)), 
convert(datetime,@m+'/1/'+@y,101)) ������
--��������� ����������� ������
, dateadd(d,
7-datepart(dw,dateadd(m,1,convert(datetime,@m+'/1/'+@y,101))), 
dateadd(m,1,convert(datetime,@m+'/1/'+@y,101)))-7 ���������
set @i=@i+1
end
go
-- �������, �����������  SM
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