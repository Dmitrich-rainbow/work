-- Полнотекстовый поиск/индекс. Full-text search (FTS/iFTS) (Integrated Full-Text Search)
- https://docs.microsoft.com/ru-ru/sql/relational-databases/search/improve-the-performance-of-full-text-queries
- Можно выбрать автоматическое или ручное обновление индекса. Ручное стоит ставить когда большая нагрузка
- Стоп списки - слова не учитывающиеся полнотекстовым поиском
- Чтобы узнать какие язык есть и какие цифры они имеют используем - sys.fulltext_languages
- Можно искать в документах
- Список всех поддерживаемых документов для полнотекстового поиска - sys.fulltext_document_types
- sys.sp_fulltext_load_thesaurus_file -- Перезагрузить файл
- sys.sp_fulltext_resetfdhostaccount -- Обновить имя пользователя для запуска демона фильрации
- sys.fulltext_index_fragments -- Фрагменты и их состояние
- sys.fulltext_stoplist и sys.fulltext_stopwords -- Просмотреть стопслова и стоплист
- sys.fulltext_system_stopwords -- Строка для каждого стоп слова
- sys.dm_fts_parser 
	1. Зайти в базу>Starage>Full Text Catalog>New Full Text Catalog
		или
		CREATE FULLTEXT CATALOG MyCatalog
		ON FILEGROUP [PRIMARY]
		WITH ACCENT_SENSITIVITY = ON
		AUTHORIZATION [dbo]
	2. На нужной таблцы Full-Text index> Define Full-Text index 
		CREATE FULLTEXT INDEX Products
		(
			NAME LANGUAGE 1033,
			CatalogDescription LANGUE 1033
		)
		KEY INDEX PK_ProductModel ON (MyCatalog)
		WITH
		(
			CHANGE_Tracking AUTO
		)
		GO
		ALTER FULLTEXT INDEX ON Products ENABLE
- Пример:
	SELECT Name, SOCR FROM Street WHERE freetext(*,'дом') -- Находит как точное, так и приближенное соответсвие
	SELECT Name, SOCR FROM Street WHERE CONTAINS(*,'дом') -- Более сложный поиск. не ищет синонимы
	SELECT Name, SOCR FROM Street WHERE CONTAINS(*,'дом near -й') -- near поиск слова рядом с другим, до 50 слов 
 - Стоп списки:
	CREATE FULLTEXT STOPLIST MyStopList
	FROM SYSTEM STOPLIST
	GO
	ALTER FULLTEXT STOPLIST MyStopList
	ADD N'дома' LANGUAGE 1049
	GO
	ALTER FULLTEXT INDEX ON Street
	SET STOPLIST MyStopList
	
	ALTER FULLTEXT STOPLIST MyStopList
	DROP N'дома' LANGUAGE 1049 -- Удалить слово из стоп листа
	DROP N'дома' LANGUAGE 1049 -- Удалить слово из стоп листа
	
-- Найти Fulltext в БД
	SELECT
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName, 
    c.name AS FTCatalogName ,
    f.name AS FileGroupName,
    i.name AS UniqueIdxName,
    cl.name AS ColumnName
	FROM 
		sys.tables t 
	INNER JOIN 
		sys.fulltext_indexes fi 
	ON 
		t.[object_id] = fi.[object_id] 
	INNER JOIN 
		sys.fulltext_index_columns ic
	ON 
		ic.[object_id] = t.[object_id]
	INNER JOIN
		sys.columns cl
	ON 
		ic.column_id = cl.column_id
		AND ic.[object_id] = cl.[object_id]
	INNER JOIN 
		sys.fulltext_catalogs c 
	ON 
		fi.fulltext_catalog_id = c.fulltext_catalog_id
	INNER JOIN 
		sys.filegroups f
	ON
		fi.data_space_id = f.data_space_id
	INNER JOIN 
		sys.indexes i
	ON 
		fi.unique_index_id = i.index_id
		AND fi.[object_id] = i.[object_id];