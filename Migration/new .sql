- Не переносятся ключи
- Требуется инициализация для Database Mail секьюрите. Достаточно пройти этап создания профайлера, выбрав забитые данные
- Прописать SPN для всех портов
	setspn -A MSSQLSvc/MSK-DB01-AXCLU.bk.local:1433 bk\sql
	setspn -A MSSQLSvc/MSK-DB01-AXCLU.bk.local:63818 bk\sql
	- Если прописать хост в ручную не удаётся, то можно выдать хосту/учётки права на уровне домена Write servicePrincipalName и Read servicePrincipalName
	- Если нужна локальная учётка 
		setspn -A MSSQLSvc/MSK-DB01-AXCLU.bk.local:63818 bk\hostname
	
	- Дать доступ одной командой
	dsacls "CN=sa_mssql-djin_msk,OU=Test&ServiceUsers,DC=msk,DC=rian" /G SELF:RPWP;”servicePrincipalName”

	
-https://msdn.microsoft.com/en-us/library/ms143702.aspx

Нужные 3 диска:
- Чтобы увидеть диски нужны их добавить не только в роль, но и зависимости
1. Data Root (должен быть в кластере)
2. Диск для MSDTC
3. Указывать локальный диск, например C:\, который не в кластере

-- Если появляется ошибка проверки кластера, то её можно пропустить
	setup /SkipRules=Cluster_VerifyForErrors /Action=AddNode
	Setup /SkipRules=RebootRequiredCheck /Action=AddNode
	Setup /SkipRules=Cluster_VerifyForErrors /Action=InstallFailoverCluster
	Setup /SkipRules=RebootRequiredCheck /Action=InstallFailoverCluster	
	Setup /SkipRules=Cluster_VerifyForErrors /Action=CompleteFailoverCluster
	setup /SkipRules=RebootRequiredCheck /Action=RemoveNode
	setup /SkipRules=RebootRequiredCheck /Action=Install	
	setup /ACTION=editionupgrade /SkipRules= EditionUpgradeMatrixCheck -- запустить обновление редакции и пропустить проверку
	
	-- На Windows Server 2012 Требуется ставить не менее SQL Server 2008 SP1
		http://blogs.msdn.com/b/petersad/archive/2011/07/13/how-to-slipstream-sql-server-2008-r2-and-a-sql-server-2008-r2-service-pack-1-sp1.aspx (как сделать из R2 > Sp1)

-- Ошибки
	- Нельзя добавлять фичи в кластер, нужно всё ставить изначально
	- E:\setup.exe /SkipRules=StandaloneInstall_HasClusteredOrPreparedInstanceCheck /Action=Install
	- http://blogs.msdn.com/b/sqlforum/archive/2011/04/19/forum-faq-why-do-i-get-rule-existing-clustered-or-clustered-prepared-instance-failed-error-while-adding-new-features-to-an-existing-instance-of-sql-server-failover-cluster.aspx
	- https://www.mssqltips.com/sqlservertip/2778/how-to-add-reporting-services-to-an-existing-sql-server-clustered-instance/

bk\sql JHG6ghK7tghj4as

MSDTC_CL
10

msk-db01-Temp

FH666-Y346V-7XFQ3-V69JM-RHW28


msk-db01-Temp$DBAXCL

net start MSSQL$DBAXCL /c /m --/T3608

RESTORE DATABASE master FROM DISK = 'J:\R10_01_msk-db01_AxDB_01\master.bak' WITH REPLACE




-- Tempdb 
- После перенесения файлов не забыть удалить старые
	SELECT * FROM sys.master_files (смотрим какие остались)
	ALTER DATABASE tempdb REMOVE FILE tempdev2; (удаляем лишние)
net start MSSQL$DBAXCL /f /c

sqlcmd -S msk-db01-Temp\DBAXCL 

use master
GO
ALTER DATABASE tempdb MODIFY FILE
(name = tempdev1, filename = N'J:\R10_01_msk-db01_TempDB_01\Data\tempdev1.mdf', SIZE = 100 Mb)
GO

use master
GO
ALTER DATABASE tempdb MODIFY FILE
(name = templog, filename = N'J:\R10_01_msk-db01_TempLogs\Logs\templog.ldf', SIZE = 100 Mb)
GO


-- Удаление ноды
	- требуется online диска с системными БД
	- Мне потребовалось убрать зависимости ip от имени,чтобы он смог их удалить
	- Видимо рерус во время удаления в online не переводил
	
	- *** Проверить удаление ноды без удаления кластера, так как мой опыт удаления ноды удалил службы и из кластера
	
-- Авария
	- Если вдруг сломался кластер, то можно создать тот же (имя, ip...), подключить к нему Template SQL Server и SQL Server Agent, настроить зависимости и будет работать. Переустановка не обязательна


-- Ручное перемещение логинов