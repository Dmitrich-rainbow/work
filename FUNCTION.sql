-- ��������
	���� ������� ��������� - SELECT * FROM FUNCTION_NAME
	���� ��������� - exec FUNCTION_NAME

	-- ����� ������� 2012+
		- EXEC PROCNAME ... WITH RESULT SETS (��������� �������� ����� �������� �� ����)
		- THROW (��������� ������)
		- OFFSET FETCH (������ �� ���������� ������). ��� ���������� ��� ORDER BY
		- Sequence - �������(ID) ��� ���������� ������
		- OVER (������� �������)
			SUM(OrderQuantity) OVER (PARTITION BY City ORDER BY OrderYear
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningQty
		- PARSE, TRY_PARSE, TRY_CONVERT
		- IIF, CHOOSE
		- CONCAT � FORMAT

