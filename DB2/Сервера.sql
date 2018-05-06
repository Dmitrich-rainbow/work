-- PRODUCTION:
	db2inst1@fsrumosdp0001 - продуктивные FLC 3,3 Тб, EDO 1,2 Гб -- TSM node fsrumosdp0001_db2i1
	db2inst2@fsrumosdp0002 - продуктивная DWH 400 Гб
	db2inst1@fsrumosdp0003 - продуктивная FED


-- UAT:
	db2inst1@fsrumosdt0001 - UAT FLC2C, EDO2C
	db2inst2@fsrumosdt0001 - UAT DWH2C 
	db2inst1@fsrumosat0006 - UAT FED2C


-- TEST-DEV:
	db2inst1@fsrumosdt0004 - TEST-DEV FLC2T, EDO2T
	db2inst2@fsrumosdt0004 - TEST-DEV DWH2C
	db2inst2@fsrumosat0006 - TEST-DEV FED2T


-- Дополнительные БД:
	db2inst2@fsrumosdt0001 - DWH2B - db for penetration test
	db2inst4@fsrumosdt0001 - testdb - db for multisession backup test


-- Скипт автоматического восстановления
	/home/db2inst1/restoreFLC2C/scriptFLC2C.sh
	
FLC 3,3 Тб
EDO 1,2 Гб
DWH 390 Гб
FED 200 Мб


ITO-4348 (EDO) место есть