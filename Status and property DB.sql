-- Проверить в каком режиме работает БД
	SELECT USER_ACCESS_DESC FROM sys.databases
	WHERE name = 'DB Name';
	
-- Проверить состояние БД
	SELECT state_desc from sys.databases
	WHERE name = 'Arttour';

-- Перевести базу в одиночный режим и обратно (делать это из другой базы, лучше мастер)
	- Одновременно работать может только 1 пользователь 
	USE NameDB
	GO
	ALTER DATABASE NameDB SET SINGLE_USER WITH ROLLBACK immediate
	ALTER DATABASE NameDB SET MULTI_USER
	GO

-- RESTRICTED_USER
	- A database in RESTRICTED_USER mode can have connections only from users who are considered “qualified”—those
	
-- OFFLINE
	- Бд не может быть переведена в режим OFFLINE, пока не будут отключены все пользователи
	
-- SUSPECT
	- Переходит в данное состояние, когда БД повреждена
	- Можно перевести данную БД в EMERGENCY, чтобы можно было с ней что-то сделать. При этом БД может позволить пропустить ошибки и запуститься.
	
-- READ_ONLY
	- Переводит БД в режим только для чтения.
	- Не может быть переведено в данный режим если к ней установлены подключения
	
-- Отключение пользователей
	- ROLLBACK AFTER integer [SECONDS] (все транзакции будут отменены после Х секунд)
	- ROLLBACK IMMEDIATE (все транзакции будут отменены сейчас)
	- NO_WAIT (дефолтное поведение, означает что если БД занята, то она не будет переведена в спец. режим)
	
-- AUTO_CLOSE
	- Когда последний пользователь отключиться от БД, она полностью выгрузится из памяти и больше не будет потреблять ресурсы, кроме диска до момента, когда новый пользователь к ней не подключится
	