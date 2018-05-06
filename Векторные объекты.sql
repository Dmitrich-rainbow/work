- Можно использовать JOIN. В ON можно вычислять пересечение

DECLARE @F1 geometry,
		@F2 geometry,
		@F3 geometry

SET @F1 = 'LINESTRING (0 0,1 2,2 3, 3 4)' -- линия
SET @F1 = 'POINT (0 0)' -- точка
SET @F1 = 'POLYGON((0 0,3 2,2 4, 0 0))' -- треугольник
SET @F2 = 'POLYGON((10 1,40 3,30 3, 10 1))'
SET @F3 = @F1.STUnion(@F2) -- объединение	

SELECT @F3, @F3.ToString() -- Показывает показать как он выглядит в команде

SELECT @F1
	UNION ALL
SELECT @F2

SET @F1 = 'POLYGON((0 0,3 2,2 4, 0 0))'
SET @F2 = 'POLYGON((1 1,4 3,3 3, 1 1))'
SET @F3 = @F1.STIntersection(@F2) -- Пересечение
	
SET @F1 = 'POLYGON((0 0,3 2,2 4, 0 0))'
SET @F2 = 'POLYGON((1 1,4 3,3 3, 1 1))'	
SET @F3 = @F1.STDifference(@F2) -- Вырезать

-- Работа с данными из таблицы

CREATE DATABASE SpatialDB
go
USE SpatialDB
go

CREATE TABLE Figures
(
	Name varchar(100),
	Figure geometry
)

-- Добавляем данные
	DECLARE @F1 geometry,
			@F2 geometry,
			@F3 geometry

	SET @F1 = 'POLYGON((0 0,3 2,2 4, 0 0))'
	SET @F2 = 'POLYGON((1 1,4 3,3 3, 1 1))'
	SET @F3 = 'POLYGON((1 2,1 3,0 1,1 2))'

	INSERT INTO
	Figures (Name,Figure)
	VALUES ('Tr1',@F1),('Tr2',@F2),('Tr3',@F3)
	
	SELECT geometry::UnionAggregate(Figure) FROM Figures -- агрегация
	SELECT geometry::UnionAggregate(Figure).ToString() FROM Figures -- Получим текстовое представление
	SELECT geometry::EnvelopeAggregate(Figure) FROM Figures -- охватывающая область
	SELECT geometry::ConvexHullAggregate(Figure) FROM Figures -- выпуклый многоугольник
	SELECT geometry::CollectionAggregate(Figure) FROM Figures -- Собирается массив из исходных фигур
	
	SELECT @AllF = @AllF.STUnion(Figure) -- объединение. Выбирается каждая строка и она суммируется с результатом
	FROM Figures
	
	SELECT @AllF
	
	
	