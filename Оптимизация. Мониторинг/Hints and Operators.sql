	ПЛАН ВЫПОЛНЕНИЯ!
	
1. Тонкая проблемы - Join(логическая операция). А файлы на диске Джойнятся по 3-м механизмам(Merge Join, Nested Loops, Hash Match):
	- Самый медленный Nested Loops, но простой и универсальный (реализует точно так же как выглядит в теории Join). Сервер применяет когда либо таблицы оч малые, либо когда сервер не может применить другие Join, либо хинтом заставили сделать. Подсказка пишется вот так - option(loop join);
	- Самый быстрый Merge, использовать в FULL JOIN нельзя и условие должно быть простое (1=2), обе таблицы должны прийти отсортированы, по сравниваемым столбцам(должны быть индексы по этим столбцам). 3 видео, 53 минута (как реализован механизм)
	- Средний, но намного быстрее Nested Loops - Hash, но высокие накладные расходы (доп работа), нет смысла делать на малых таблицах. Создаёт хэш-таблицы в памяти и работает с ними. Если памяти не хватает, то скидывает на диск. Из-за постоянно проверки где находятся данные, могут быть сильные замедления
2. Хинты (спорное решение и конечно нельзя зашивать в приложение): INNER MERGE JOIN, INNER LOOP JOIN
3. Как бороться с хинтами (Plan Guides) - подменять план запроса
	- SELECT * FROM Sys.Plan_Guides
	- EXECUTE sp_Create_Plan_Guide (создание плана) @hints N'Option(USE PLAN N"xml plan")', чтобы для OPTION получить xml план, надо сделать верный запрос и в соединении поставить флаг SET SHOWPLAN_XML ON
	- EXECUTE sp_control_plan_guide