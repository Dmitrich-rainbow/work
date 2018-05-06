-- Ссылки
	http://aboutsqlserver.com/lockingblocking/
	http://www.somewheresomehow.ru/fast-in-ssms-slow-in-app-part1/
	
-- Сайт
	- Миграция (статья)	
	- Новшесва 2016(статья)
	- Набор скриптов от SQLCOM.RU	

-- Узнать самому:
	- Use plan and recompile
	- SQLDIAG и PSSDIAG (позволяет создать свой шаблок и изменитьчужой от SQLDIAG)
	- На страницы ли накладываются латчи? А spin? (если на страницу, то это плохо из-за блокировок)
	- Какие операторы сильно используют процессор	
	- Что такое в Windows Server User Account Control?
	- Distributed Replay?
	- Принципы построения бд-хранилища
	- Лучше изучить Order By, а именно сложные условия сортировки
	- Как работает кэш в MS SQL
	- exec executesql N'...'
	- Атака "Lilupophilupop"
	- Секционирование таблиц (Более старые записи в одной, более новые в другой и можно хранить их на разных дисках)
	- Когда надо использовать многие-ко-многим
	- Managment -> Policy Managment
	- SharePoint
	- Файловая таблица
	- XML/OPENXML 
	- шифрование
	Эксперименты с Цепочкой владения
	переключение секций
	CAP/ACID/BASE?
	полнотекстовый поиск
	Service Broker
	нагружалка (StressOledb)
	оптимизация запросов
	архив хвоста журна, если была авария до любого архивирования - ?
	endpoint?
	sqlos?
	coreinfo (програ)?
	rammap (прога)?
	vmmap (прога)?
	табличные переменные?
	ожидание дисков asynch_io_completion,io_completion,logmgr,writelog,pageiolatch_x?
	Optimize fro Unknown?
	- Пример:
	- SELECT * FROM t WHERE .... ORDER...OPTION(Optimize FOR (@p1 UNKNOWN,@p2 UNKNOWN))

-- Получил ответ:
	- Почему batch/sec > recompile -- Потому recompile определяется по количеству statement, а batch может состоять из множества statement 
	- поэксперементировать с репликациями
	- Материализованный индекс/представление? - http://msdn.microsoft.com/ru-ru/library/ms187864(v=sql.90).aspx
	- Про его бесплатные семинары -- Ок
	- Как вмешатсья в автоинкремент -- Ок
	- Как убить процессы сервера -- Команда kill убивает все возможные процессы, которые сервер может технически завершить
	- Какой посоветуете курс для разработки БД --Курс Microsoft 20465 (Разработка решений баз данных для Microsoft SQL Server 2012)
	- Ограничение на использование HDD -- Сказал что возможно получится ограничить на уровне RAID/LUN
	- Работа с SSD на tempdb -- Можно использовать, если даёт хорошие скорости
	- Запретить SQL использовать файл подкачки. Нужно ли это и как сделать -- Это особо не повлияет на работу SQL Server
	- Колоночная СУБД -- http://www.specialist.ru/news/1864/microsoft-predstavlyaet-kolonochnuyu-subd
	- SQL Agent может ли работать с SSAS -- Может
	- "дисковая система хранения"/LUN -- МОжно разделить RAID на логические части и раздать разным машинам, при этом использование
									  -- диска нельзя ограничить Луной (чтение/запись)
	-WAITFOR DELAY '00:00:10' -- задержка перед стартом
	-DDL события - http://msdn.microsoft.com/ru-ru/library/bb522542.aspx
	-Версии сервера - http://www.sqlsecurity.com/faqs-1/sql-server-versions/2008
	-обновление - через инсталятор
	-написанная процедура, для выявления блокировок с сайта Microsoft - pss_blocker(http://support.microsoft.com/kb/271509)
	-Преимущества лицензии, тех. поддержка - Должны ответить на любой вопрос (https://support.microsoft.com/oas/default.aspx?st=1&as=1&as=1&tzone=-240&gprid=13165&timestmp=634656719346837419&ps=1&acty=ProductList&ctl=productlist&wf=PID&trl=PID~ProductList&sd=gn&c=SMC&ln=ru&prid=12543&gsaid=542172)
	- Виртуальный сервер для ms sql - Как правило, ведёт себя нормально. Можно пользовать.
	- потеря tempDB - Ничего страшного с данными не произойдёт, просто придётся службу перезапускать.
	- графические интерфейс Plan Guide - Programmability -> Plan Guides
	- как через команду вызвать изменение/генерацию скрипта на изменение процедуры - sp_helptext @objname = 'dbo.uspGetBillOfMaterials'
	- утилита для тестирования нагрузки серверов - SQLStressUtility.Так же есть Ostress и Read80Trace - перевод из Profiler формата в Ostress.
	- Включение MS SQL в домен - Включение в домен любого объекта всегда повышает управляемость этого объекта. Сервер не в домене - это как внештатный сотрудник, сам по себе. Его сложнее контролировать, им труднее управлять.
	- FAT или NTFS - FAT - это файловая система для фотоаппаратов, плееров и телефонов. Для компьютеров - NTFS.
	- Поключение к разным экземплярам через IFOS\MSSQSLSERVER
	- Page Verify - если был фул, потом ошибка, потмо фул,тогда придётся брать рваную страницу из 1 backup, тут ничего не поделать. Если включено обнаружение рваных страниц, то сервер не даст изменить данную страницу.
	- N'AdventureWorks2008R2.Production.WorkOrder' - N означает nvarchar
	- неравномерные данные в базе - Возможно речь шла о фрагментации
	-  фаил подкачки для SQL Server - Не играет роли, разве что гомеопатическую. :)
	- Где найти Ресурс toolkeet - сбросил в pdf формате
	- бинарные данные в sql server - это файлы самого sql server
	- AD (DHCP, DNS, DFS, Exchange желательно)
	- Динамические административные представления и функции - http://msdn.microsoft.com/ru-ru/library/ms188754.aspx
	- Настройка DHCP-сервера - http://www.rutut.com/allvideo/144-5-nastrojka-dhcp-servera.html

