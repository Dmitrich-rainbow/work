﻿-- Основное
	- Обычно это данные только на чтение

-- ROLAP (реляционные OLAP системы)
	- Лишены запаздывания в части листовых данных
	- Получение агрегатов и листовых данных происходит медленно

-- MOLAP (многомерные OLAP)
	- Есть запаздывание данных, так как требуется загрузка их в OLAP систему
	- Весит больше
	
-- HOLAP (гибридные OLAP)
	- Нет запаздывания данных
	- Листовые данных хранятся в ветрине, поэтому нет загрузки их в OLAP систему
	
-- UDM 
	- Структура, развёрнутая поверх витрины данных для конечных пользователе, чтобы обходить витрину и работать сразу с OLTP. Выглядит как OLAP.
	
	-- Ситуации, когда нельзя использовать UDM
		1. Нет подключения к OLTP системе через OLE DB
		2. Нет OLTP БД, а есть файлы данных. Данные сторонних источников
		3. Нет физического, постоянного подключения
		4. Есть грязные данные, которые должны очищаться службами интеграции