-- Основы
	- http://msdn.microsoft.com/ru-ru/library/windowsazure/ee336281.aspx
	- В SQL Azure отказались от кучи и все данные хранятся в сбалансированных деревьях (B-tree)
	- Облако далеко 
	- Надо брать не сколько дают, а сколько надо
	- Только SQL аутентификация
	- Не поддерживается CLR, SQL Agent

-- Не поддерживается
	- SELECT INTO
	- Переключение между базами в одном подключении. USE поддерживается, но работает только если вы уже подключены к нужной базе данных
	- Не разрешён прямой доступ к tempdb. Создавать временные таблицы и объявлять табличные переменные можно, но нельзя создавать пользовательские объекты
	- Read committed = read committed snapshot

-- iaas
	- SQL Server как VM
	- Особенности:
		1. Полноценный сервер
		2. Расположение в Azure STORAGE. Можно работать с RAID
		3. Готовый образ, оптимизированный под текущую платформу. Можно использовать свой образ

-- paas
	- SQL Server как сервис
	- Особенности:
		1. Железом и слоем над железом управляет вендор
		2. Данные ресурсы используются не только вами с вытекающими
		3. Ресурсы лимитируются
		

