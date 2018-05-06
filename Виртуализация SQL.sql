http://sqlmag.com/database-virtualization/sql-server-virtualization-faqs

-- Советы по мониторингу
	https://msdn.microsoft.com/en-us/library/windows/hardware/dn529134

-- Советы
1. Установите на хосте 64-разрядные процессоры с поддержкой SLAT (повышает производительность и масштабируемость виртуально машины)
2. Обеспечьте один-к-одному между ядрами физического процессора и виртуальными процессорами
3. Используйте динамическую память
4. Используйте фиксированные вируальные жесткие диски
5. Разносите файлы данных, ОС и журналов
6. отключайте гипертрейдинг, если не хотите обрести лишних проблем с cxpackage

-- Нагрузка 
	1. Издержки будут от 9% до 19% (CPU)
	2. Есть издержки с фиксированными дисками от 15%
	
-- Минусы
	1. Сложно мониторить призводительность без доступа к виртуальной среде
	