-- Чтобы включить возможность отправки почты:
1. Настроить Managment>Database Mail (чтобы включить сервс брокер надо отключить всех от msdb)
2.
EXEC sp_configure 'show advanced option', '1'  -- Включаем дополнительные опции
GO 
RECONFIGURE;
GO   
  sp_configure 'Database Mail XPs', 1; -- Включаем возможность отправки почты
GO
RECONFIGURE;
GO
3. В SQl-Agent настроить Оператора

   EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'ARTTOUR',
        @recipients = 'DZaytsev@arttour.ru',
        @body = 'Текст сообщения',
        @subject = 'Заголовок';

      SELECT * FROM msdb.dbo.sysmail_profile --Просмотр возможных профайлеров почты
	  
-- Автоматический выбор профайлов почты
	DECLARE @profile nvarchar(512)
	SET @profile = (SELECT TOP 1 name FROM msdb.dbo.sysmail_profile)

	   EXEC msdb.dbo.sp_send_dbmail
			@profile_name = @profile,
			@recipients = '.zaytsev@rian.ru',
			@body = 'Текст сообщения',
			@subject = 'Заголовок';
	 
	  
-- Если хотим отправить результат запроса
- Заметьте, что запрос выполняется в отдельном сеансе, так что локальные переменные в скрипте, вызываемом процедурой sp_send_dbmail, недоступны для запроса.
- @attach_query_result_as_file = 1 вложить ответ запроса в файл
- @query_result_header = 0 -- убрать заголовки столбца
- @query_result_no_padding = 1 -- убрать лишние пробелы в ячейках


   EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'ARTTOUR',
        @recipients = 'soft@arttour.ru',
        @query = 'SELECT StateName,HotelName,TownName FROM ##filters WHERE WWW = ''''',
        @subject = 'up_WEB_2_best_List_all_temp';		

	-- В формате HTML
		SET @body = ''
		
		DECLARE @tableHTML varchar(4000)
		SET @tableHTML =
		N'<table border="1">' +
		N'<tr><th>Заявка</th><th>№ Квитанции</th><th>Владелец</th><th>Дата и время создания__</th>' +
		N'<th>ФИО плательщика</th><th>Сумма 1</th>' +
		N'<th>Валюта 1</th><th>Сумма 2</th>' +
		N'<th>Валюта 2</th><th>Курс</th>' +
		N'<th>Подтверждение банком</th><th>Загружено в САМО</th>' +
		N'<th>Код платежа</th></tr>' +
		CAST ( ( SELECT   
						td = ISNULL(Claim,''),'',
						td = ISNULL(INumber,''),'',						
						td = 'Привет','',						
						td = ISNULL(CONVERT(VARCHAR(19), IDateTime, 120),''), '',               
						td = ISNULL(Payer,''), '',
						td = ISNULL(CurSum,''), '',
						td = ISNULL(i1.currency,''), '',
						td = ISNULL(RubSum,''),'',
						td = ISNULL(RubCurrency,''), '',
						td = ISNULL(Rate,''), '',
						td = ISNULL(CONVERT(VARCHAR(19), ConfirmDateTime, 120),''), '',
						td = ISNULL(CONVERT(VARCHAR(19), LoadToSamoDateTime, 120),''), '',
						td = ISNULL(PaymentInSAMO,''), ''
				  FROM  invoices i1 INNER JOIN [InvDetail] inv1 ON i1.id = inv1.InvoiceId WHERE Claim = @claim
				  FOR XML PATH('tr'), TYPE
		) AS NVARCHAR(MAX) ) +
		N'</table>' ;   
		
		
		exec msdb.dbo.sp_send_dbmail
		@profile_name = 'Partners',
		@recipients='dzaytsev@arttour.ru;Dmitry@arttour.ru',
		@subject = @subject,
		@body = @tableHTML,
		@body_format = 'HTML' ;
	  
-- Настройка почты
	sysmail_configure_sp

-- Отобразить текущие настройки почты
	EXECUTE msdb.dbo.sysmail_help_configure_sp

-- Список profiles
	SELECT * FROM msdb.dbo.sysmail_allitems
	
-- Лог почты
	SELECT * FROM msdb..sysmail_event_log ORDER BY log_id DESC

-- Смотреть очередь
	SELECT *  FROM sys.dm_broker_queue_monitors

-- Очередь почты
	EXEC msdb.dbo.sysmail_help_queue_sp @queue_type = 'mail';

-- Список отправленных писем
	SELECT TOP 100 sent_status, * FROM msdb.dbo.sysmail_allitems ORDER BY mailitem_id DESC
	
	-- Группировка по дням
		SELECT CONVERT(VARCHAR(10), send_request_date, 111), COUNT(*) FROM msdb.dbo.sysmail_allitems GROUP BY CONVERT(VARCHAR(10), send_request_date, 111) ORDER BY CONVERT(VARCHAR(10), send_request_date, 111) DESC

-- Список проблемных писем	
	SELECT sent_status, sent_date, * FROM msdb.dbo.sysmail_allitems WHERE sent_status<> 'sent' ORDER BY mailitem_id DESC 	
	
-- Посмотреть статус почты
	EXEC msdb.dbo.sysmail_help_status_sp;

-- Все сообщения в очереди
	EXEC msdb.dbo.sysmail_help_queue_sp @queue_type = 'mail';
	
-- Очистка старых данных
	SELECT * FROm msdb.dbo.sysmail_mailitems 
	DECLARE @d datetime = GETDATE()
	exec sysmail_delete_mailitems_sp @sent_before=@d
