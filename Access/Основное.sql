-- Открытие в режиме редактирования
- Двойной щелчок с зажатым Shift

-- Преобразование типов данных
Format(выражение [, формат ] [, первый_день_недели ] [, первая_неделя_года ] )

-- Аналог BETWEEN(его тут нет)
Date >'10/12/2012' AND Date <'15/12/2012'

CBool(expression) -- expression это тот столбец, который надо преобразовать
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

-- Дата
При вставлении пустой даты надо либо вставлять NULL, либо '00:00:00'

-- Текущая дата
Date()

-- Список таблиц
SELECT MSysObjects.Name 
FROM MSysObjects 
WHERE (((MSysObjects.Type)=1) AND ((MSysObjects.Flags)=0));