﻿
-- Фёдор Самородов. Как не следует писать на T-SQL (Врденые советы по SQL)
-- Часть 1 (Для пользователей БД)
- Любой пример, что сегодня будет, рано или поздно будет лучшим положительным для конкретной ситуации
Вредные советы:
1. SELECT *
	За этот совет:
	- Быстрое решение
	- Нет необходимости структуру таблицы
	- Меньше печатать текста
	- Чем проще текст, тем лучше
	Против:
	- Дублирование имён полей
	- Проблемы с индексами. Сильно влияет на планы выполнения
	- Количество передаваемых данных
	- Вычисляемые столбцы, которые не сохранены на диске, то есть они будут каждый раз рассчитываться
	  при вызове
2. При сортировке обращайтесь к столбцам по номерам
SELECT Name,Price FROM Products ORDER BY 2,1
- Не указывать при вызове процедуры параметры, а просто перечислять цифры. При этом процедура может
  измениться и параметры по счёту то же изменятся, тогда процедура будет работать неверно
	За:
	- Простое решение
	- Меньше печатать
	Против:
	- Порядок всегда может измениться
3. Упрощённый синтаксис в INSERT
INSERT INTO Products VALUES (15,'Чайник',99)
	Против:
	- При изменении таблицы, всё это будет работать неверно, а если параметры по-умолчанию не будет
	  указано - вообще сломается
4. Всегда старайтесь решить задача одним запросом
	За:
	- Сразу видно что автор профессионал
	- Более лучшая производительность
	Против:
	- Легко совершить ошибку
	- Сложно поддерживать
	- Сложно отлаживать
	- Решение перестаёт помещаться в голове
	- Блокировки. При большом % блокировок будет заблокирована таблица
5. Получить случайное значение
SELECT Top(10)* FROM Products ORDER BY NEWID()
	За:
	- Получает действительно случайную строку
	- Лёгкое решение
	Против:
	- Для всех строк генерируются NEWID(), а мы используем только 1. На большой таблице использовать
	  в реальном времени это невозможно
	- Индексы не помогут
6. Применяйте скалярные функции к столбцам в секциях WHERE и ORDER BY
SELECT * FROM Orders WHERE DateDiff(day,'1977-12-11',OrderDate) > 120
	За:
	- Простое решение
	- Легко читается
	- Легко модифицируется
	Против:
	- Для каждой строки вычисляется. Лучше указывать это в SELECT, тогда это будет вычисляться в конце
	- В сложных случаях скорее всего не будут использоваться индексы
	- Лучше переписать так (здесь граница диапазона вычисляется без столбцов, поэтому сервер может
	  вычислить это 1 раз, а не для каждой строки):
	SELECT OrderID FROM Orders WHERE OrderDate BETWEEN '19771211' AND DateAdd(day,10,'19771211')
7.
- Используйте LIKE для поиска по тексту
- Используйте регулярные выражения для поиска по тексту
	За:
	- Легко писать и использовать
	Против:
	- Сложно задействовать индексы
	- Работает медленно
	- Не найдём того, что нам нужно, LIKE не ищет слова, он ищет последовательность букв. Если захотим
	  искать слова, то надо будет писать много LIKE с разными условиями
	Правильное решение:
	- Симантический и полнотекстовый поиск
8. Используйте NULL, как обычное значение
- Null нужно использовать только для того, чтобы показать что данные отсутвуют
   SELECT * FROM Orders WHERE ShipCity IN('Berlin','Paris',Null). Здесь может быть подзапрос, который
   вернёт NULL
   Против:
   - Null это не значение
   - Если используем NOT NULL, то сервер не выведет ниодного значения
   
-- Часть 2 (архитектура и проектирование баз данных) 
1. В стобцах множество однотипных значений. (ID рукводителя, множество в одном столбце из int в string. Вместо 53 будет 53,57,86,98) 
	За:
		- Это не потребует серьёзных изменений в существующей базе
	Против:
		- Нарушается ссылочная целостность, решается с помощь хранимых процедур и триггеров
		- Непонятно как его индексировать
		- Аномалии вставки и удаления(UPDATE). Как добавить кого-то и удалить
		- Торможения при JOIN
		- Простой SELECT уже потребуют особых конструкций
		- Агрегация
		- Ограничение длины строки
2. Хранение в таблице многозначные атрибуты. Телефоны в разных столбцах
	За:
		- Не противоестественный для реляционных БД
		- Структура БД остаётся простой
		- Не потребует серьёзных изменений в существующей БД
	Против:
		- Как модифицировать телефон. Непонятно какой телефон UPDATE, INSERT
		- А как делать поиск?
		- Как много столбцов будет в итоге, если не хватит, ещё добавлять?
		- Как обеспечить уникальность значений
3. Применяйте атрибутную схему (Entity-Attribute-Value/Attribute Value). Общие столбцы в одной таблице, список значений в другой (Attribute) (ID, Название(Пар, цвет, диагональ)), а связка этих таблиц в третьей (Values) (ID 1 таблицы, ID 2 таблицы, Значение)
	За:
		- Универсальное решение, можно хранить всё что угодно, любой товар
		- Нет NULL
		- Хорошо масштабируется
	Против:
		- Как узнать заполнены ли все атрибцты у товара? Ответ - никак (Как реализовать NOT NULL)
		- Как проверять
		- Как обработать разные атрибуты в одном запросе (Чёрного цвета и с разной диагональю экрана)
		- Как обеспечить целостность данных. Как проверить в Values плавильно ли введены значения
		- Что с типами атрибутов (типизация)?
		- Как быть с внешними ключами на атрибуты?. Ответ - никак
		- Целостность в Attribute. Ответ - никак
		- Как восстановить эталонную таблицу (прайст лист)? Ответ - CASE или PIVOT
4. Применяйте полиморфные ассоциации. Есть таблица товара и магазина. Есть комментарии, которые должны ссылаться на обе таблица. Мы делаем столбец, куда вставляется ID товара или магазина и столбец, который указывает откуда этот ID.
	За:
		- Универсальное
		- Не потребует особых услисий для доработки базы
	Против:
		- Ключ товара или магазина не будет поддерживать целостность. Так как это не внешний ключ. То есть можно добавить комментарий к товару, которого нет. Не будет каскадного удаления комментариев
		- Усложняет JOIN. Сложность ускорения серверов JOIN. Потребует много сил на оптимизацию
5. Клонируйте таблицы. Заказы_2002, Заказы_2003,Заказы_2004... При этом пользователи ищут всегда в пределах одного года, им никогда не надо задействовать несколько
	За:
		- Нету
	Против:
		- Нужно будет писать UNION, если вдруг надо будет несколько лет и не факт что сервер сможет его ускорить
		- Перенос заказа из одного года в другой или UPDATE
		- Как искать заказы по другим атрибутам
		- На каждый год придётся писать доп. объект в базе (процедуры)
		- Как осуществить контроль целостности?
		- Как контролировать первичный ключ, на что будут ссылаться?
		- Как обновлять метаданные? Нужно перебрать все таблицы и везде это проделать и вся доп. обвязка обновлена

--	 Прежде чем делать новшество надо проверить:
	1. Целостность
	2. Не смешивайте данных и метаданных. Данные нужно хранить в строках, а методанных в названиях столбцов
	3. Не используйте ООП в БД.