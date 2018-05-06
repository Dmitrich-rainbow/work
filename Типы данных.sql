
	
-- NULL 
	- Стараться писать с NOT NULL или с default
	- При создании объекта всегда явно указывайте NULL or NOT NULL, чтобы избежать ошибок настроек пользовательских интерфейсов, которые могут менять дефолтное поведение
	- When CONCAT_NULL_YIELDS_NULL is on, concatenating a NULL value with a string yields a NULL result, если OFF, то возвразается только string:
		1. Сессия:
			- SET CONCAT_NULL_YIELDS_NULL ON 
			- SELECT SESSIONPROPERTY('CONCAT_NULL_YIELDS_NULL');
		2. БД:
			- SELECT name,is_concat_null_yields_null_on FROM sys.databases
			- SELECT DATABASEPROPERTYEX('sdb', 'IsNullConcat')
			- ALTER DATABASE sdb SET CONCAT_NULL_YIELDS_NULL OFF
	- Все сравнения с NULL дают UNKNOWN, если CONCAT_NULL_YIELDS_NULL is on
	- Если CONCAT_NULL_YIELDS_NULL is OFF и сравниваются 2 NULL, то будет TRUE
	- When this option is set to OFF, SQL Server allows = NULL as a synonym for IS NULL and <> NULL as a synonym for IS NOT NULL
	- В строгих типах данных NULL будет занимать указанное число символов всё равно (char(200))
	-- Советы:
		- Never allow NULL values in your tables.
		- Include a specific NOT NULL qualification in your table definitions.
		- Don’t rely on database properties to control the behavior of NULL values
		
-- IDENTITY
	1. @@IDENTITY which contains the last identity value used by that connection
	2. IDENT_CURRENT last identity value inserted in a specific table from any application or user
	3. SCOPE_IDENTITY Возвращает последнее значение идентификатора, вставленное в столбец идентификаторов в той же области. Областью является модуль, что подразумевает хранимую процедуру, триггер, функцию или пакет. Таким образом, две инструкции принадлежат одной и той же области, если они находятся в одной и той же хранимой процедуре, функции или пакете.
	4. DBCC CHECKIDENT command to reset the identity value to the appropriate number
	