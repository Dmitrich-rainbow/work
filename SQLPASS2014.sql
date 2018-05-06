-- Обзор Power BI и примеры использования (Ivan Kosyakov)
	- powerbi.com
	- Power Query
		- Надстройка над Excel
	- Power Pivot
		- Быстрая аналитика в памяти
		- Встроен в Excel
		- Возможно 10 000 000 строк, если более 100 000 000, то будет работать медленно и лучше делать в SQL Server в табличном режиме
	- Power Map
		- Интерактивная визулизация на карте



		
-- План восстановления баз данных (Kirill Panov) 
	- master и model нужно иметь холодную копию, а потом восстановить из обычной копии. Чтобы это сделать нужно запустить сервер в режиме -m. С помощью sqlcmd выоплняет RESTORE master. Далее запускаем сервер в обычном режиме
	- Если холодной копии master нет, то нужно пересоздание системных баз. Нужно взять установочник вашей версии. Это медленно. Если master взять с другого сервера, то это Not Supported


	
-- Внутри оптимизатора: кардинальность и планы выполнения (Dmitry Pilugin)
	- Версия сервера важна. Рассматривается версия SQL Server 2012
	- Кардинальность - число строк. Ключевой параметр в определении стоимости запроса. Чем стоимость меньше, тем более вериятность его выбора SQL Server.
	- dbcc show_statistics('t1','ix_b') на её основе вычисляется кардинальность.
	- После использования статистики идёт модель (Теория вероятности, предположение, догадки)	
		- Теория вероятности
			- Селективность
			- Частота
			
		- Предположение
			- Предположение равномерности
			- Предположение независимости (атрибуты не считаются зависимыми до тех пор, пока зависимость не известна и может быть использована в модели)
			- Предположение включания 
			- Предположение содержания
		
		- Догадки (переменные)
			- Равенство с неивестными: where column = @c - density или 10% от входной кардинальности
			- Неравенство с неизвестным: where column > @c - 30% от входной кардинальности
			- Число строк в табличной переменной всегда 1
			
	- Вычисление кардинальности - Вычисляется всегда снизу вверх. Ищите самый низкорасположенный элемент, где возникла ошибка в оценке и запрос изменится
	- Целевое число строк...
	
	- T4137 (прочитать). Флаг трассировки
	- T2312(новый механизм рассчетов в Server 2014)/T9481 (вкл старый механизм для Server 2014)
		
	- Средства контроля и мониторинга
		- План
			1. Оценочный план vs Действительный
			2. Жирные стрелки
			3. Предупреждения в плане (расширено в 2012,2014)
		- События xEvent
			1. inaccurate_cardinality_estimate(2012)
			...
		- Представление dm_exec_query_profiles(2014)
	
	- Ошибки оценки кардинальности. Когда бывает
		1. Отсутствует статистика
			1.1. Табличная переменная (временная таблица, option (Recompile))
			1.2. Отключение авто-создание статистики (самим её создавать тогда надо)
			1.3. Удалённый сервер - нет прав (дать права, проверить флаг трассировки 9485)
			1.4. ReadOnly...
		2. Неверная статистика
			2.1. Устаревшая(обновить, использовать T2389,T2390,T2371 (глобальный флаг, чем больше таблица, тем чаще обновляется))
			2.2. Неполная (обновить с опцией fullscan)
			2.3. Кэшированная (перестроить временную таблицу (ALTER Table REBUILD), выполнить операцию DDL (перестроить индекс))
			2.4. Искажённая. Нетипичное распределение, большой объём данных - не хватает 200 шагов (фильтрованная статистика)
		3. Не может использоваться или используется не полностью
			3.1. Некоторые выражения в предикатах
			... см. презентацию
			
		- Посмотреть флаг T4137 и T2301, T4199 (проверить запрос)
		
-- Использование CDC для хранилищ данных с помощью SSIS (Eugene Polonichko)
	CDC - Change data capture
	- Работает только в Enterprise
	- На OLPT систему добавляет нагрузку
	- Не работает с репликациями
	- Ассинхронность
	- Должен работать SQL Server Agent
	- Создаёт себя в системных таблицах базы, в которой влючен	
		
-- Конкуретный доступ к структурам даных в памяти. Latch'и. (Evgeny Khabarov)	
	- Многоядерная система
		- Раньше было мално ядер и проблемы с Latch не было
		- С увеличением количества ядер может возникнуть ситуация уменьшения пропускной способности транзакций в секунду
	- Страница - 8кб (заголовок 96 байт, ID страницы, тип страницы, количество свободного места)
	- Экстент - блок из 8 страниц
	- Все изменения страниц происходят в памяти, потом идёт на диск
	- LATCH
		1. Для обеспечения физической целостности данных в памяти
		2. Бывают:
			- Буферный (чтение/записи страниц в boffer pool)
			- Небуферные 
			- ввода/вывода (чтение данных с диска в памяти)
		3. Поведение latch управляет sql server, но мы можем косвенно повлиять на них изменяя архитектуру приложения
		4. Нет уровня ихоляции и хинтов
		5. latch живёт на протяжении операции со страницей
	- BUF структура
		- обвес страницы некоторой информацией
		- для ослеживания состояний страницы
	- Режимы latch
		1. KP - keep (предотвращает удаление страницы из памяти, проверка наличии страницы в памяти)
		2. SH - shared (используется при чтении данных)
		3. UP - update (обновление только слежубной информации на странице)
		4. EX - exclusive (при обновлении данных)
		5. DT - destroy (при удалении страницы из памяти)
	- Для множественного доступа к странице используется очередь (почти FIFO очередь) для latch, чтобы очередь не была длинная, SQL выбирает совместимые latch и исполняет, все, кто не совместимы, будут ожидать своей очереди. keel latch получает доступ в обход очереди
	- dbcc page
		m_slotCnt - количество строк
		m_freeData - указатель, где должна начинаться следующая запись
	- Симптомы проблем с Latch
		1. Наличие в sys.dm_exec_requests/sys.dm_os_waiting_tasks PAGELATCH_*,PAGEIOLATCH_*,LATCH_*
		2. В sys.dm_os_wait_stats ожидания..
		3. См. презентацию
	- Места возникновения
		- Пользователськие базы. INSERT в таблицу в identity полем
			- Решение - увеличить размер записи (было varchar и сделать char чтобы занимало больше), уменьшить плотность запсии на страницы
		- Небольшая таблица. index page split
		- Приращение файла данных (Instant file initialization)
		- В tempdb. Если часто её используем.
			- Решение - создание нескольких файлов данных
					  - включить флаг T1118			
		- Табличные функции
			- Решение - создание нескольких файлов данных
		- Системные объекты 
			- Решение - пересмотр структуры приложения
	- Инструменты
		sys.dm_os_wait_stats
		sys.dm_os_latch_stats
		sys.dm_exec_requests
		sys.dm_os_waiting_tasks
		Perfomance monitro (SQL Server:Latch Average Latch Wait time(ms), Latch Waits/sec, Total Latch Wait Time (ms))
		xEvents			
			
-- Все, что вы хотели узнать об объектах БД, но всегда боялись спросить. (Короткевич Дмитрий (Тампа))
	- Функции
		- Функции, которые содержат BEGIN...END (содержит несколько операторов) - зло. Если изменить невозможно, то используйте with schemabinding
			- Убивает возможность эффективного поиска по индексам, что ухудшает производительность
			- План выполнения не покажет, на сколько большая нагрузка идёт от функции
		- Функции Inline нормальные
			create function myfunction
			(
				@id int
			)
			return table
			as
			return
			(
				SELECT name from...
			)
	- Ограничения
		- Первичный ключ и Unique Constrait
			- Unique Constrait -> элемент логического дизайна
			- Unique Index -> элемент физического дизайна
			- Unique Constrait не позволяет использовать влюченные поля (included column)
		- Использовать уникальный констрейнт или уникальный индекс не имеет значения
		- Check Constraint
			- Помогает избегать ошибок на момент разработки
			- Помогает оптимизатору (ядру сервера, например если указать какие значения есть в такой таблице, то сервер это будет использовать)
			- Влечёт дополнительную нагрузки при пакетных операциях 
			- Создание на таблице с даными произведёт её блокировку пока не будет произведена полная проверка
		- Foreing Key Constraints
			- В некоторых случаях помогают оптимизатору
			- Помогают обнаружить ошибки на ранней стадии
			- Не совместимы с Partition Switch
			- Добавляет нагрузку на сервер. Обычно не имеет значения
			- ОБЯЗАТЕЛЬНО СОЗДАВАЙТЕ ИНДЕКС НА ССЫЛАЮЩЕЙСЯ ТАБЛИЦЕ
	- Представления (View)
		- Обычные представления
		- Индексные представления - данные хранятся подобно обычным таблицам/индексам
			- Большие ограничения при создании ограничений
			- Поведение зависит от редакции сервера. В Standard требуется использовать Noexpand хинт
			- Оптимизация агрегации данных
			- Оптимизация соединений
			- Оптимизация стороннего кода (Enterprise Edition)
			- Хорошие для статистики
			- Дополнительная нагрузка, так как оно требует поддержания. Лучше использовать на статичных данных
		- Хорошо	
			- Нужно изолировать таблицы от кого-то, скажем какой-то столбец
			- Безопасность
		- Плохо
			- Сопровождаемость (особенно при обновляемых представлениях)
			- Потенцильано лишние соединения (Доп. нагрузка на сервер)		
		
-- SQL Server 2014. Resource Governor. Князев Алексей (Екатеринбург)
	- Начиная с Server 2014 можно управлять IO, увеличено число пулов с 12(14) до 62
	- ALTER RESOURCE GOVERNOR RECONFIGURE (чтобы обновить)
	- ALTER RESOURCE GOVERNOR reset statistics (сбросить статистику по Resource Governor)
	- Рекомендации
		- Учитывайте общее использование ресурсов приложениями
		- Избегайте совместного выполнения смешанных рабочих нагрузок на одних и тех же процессорах
		- Всегда перенастраивайте сходство пулов после изменения конфигурации ЦП
		
-- Внутри оптимизатора: стоимость и планы выполнени. Пилюгин Дмитрий (Москва)	
	- Стоимость - оценочная величина, отражающая предполагаемые затраты ресурсов сервера на выполнение. Измеряется в условных единицах
	- Скрытая стоимость
		- Scalar Operators
		- Batch To Row Adapter, Row to Batch Adapter (2014)
	- Зачем используется стоимость
		- Выбираем наиболее дешёвый
		- Неверная стоимость - медленный запрос
	- Good Plan (не документировано)
		- Есть верхние и нижние границы(F(Cost)). Почти всегда Good Enough plan когда это значение < 1
	- Time Out (количество операций, а не времени)
		- Отражает не время, а количество задач оптимизации
		- Не зависит от нагрузки
		- F(Cost) = Optimizer Tasks
		- Каждый раз для новой стадии поиска
		- Имеет верхний предел 3 072 000 операций (по-умолчанию 614 400 операций). Для этого можно включить флаг, но тогда построение плана может быть очень долгим и не рекомендуется делать это на промышленных серверах (8780 или 8675):
			SELECT * FROM Goods OPTION(recompile,querytraceon 3604,querytraceon 8615,querytraceon 8609,querytraceon 8739)
		- Узнать что за флаг T2335 (KB 2413549)
		- Узнать что за флаг T8649 (только для разработки)
		- dbcc optimizer_whatif('memoryMBs',128) with no_infomsgs - сказать серверу что у нас 128 мб памяти
		- DOP
			- При построении плана
			- Уже в момент генерации последнего executable плана
		- Parallelism Threshold (взять из докалада)
			...
		- Выводы
			- Не нужно напрямую отождествлять стоимость и время выполнения
			- Не нужно сравнивать стоимость семантически разных запросов
			- Query Cost - наиболее сбивающая с толку вещь, отражает только предполагаемые затраты
			- При анализе планов учитывайте параметры влияющие на стоимость и ограничения модели (оборудование, структура базы)