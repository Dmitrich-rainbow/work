-- Настройка
	-- https://blogs.msdn.microsoft.com/sqlcat/2016/09/29/sqlsweet16-episode-8-how-sql-server-2016-cumulative-update-2-cu2-can-improve-performance-of-highly-concurrent-workloads/
	1. Установить adksetup.exe (можно скачать по фразе Windows ADK и выбрать в компонентах Windows Performance Toolkit)
	2. Запустить cmd и начать сбор информации:	
		xperf -On Base
	3. Остановить сбор и сформировать отчёт в папку:
		xperf -d c:\temp\highcpu.etl
	4. Открыть созданный отчёт через "Windows Performance Analyser"
	5. Зайти в раздел CPU > нагрузка про процессам