-- Кластер/CLUSTER
- Кластер ничего не ускоряет
- В кластерной конфигурации за ранее установть FILE STREAM, иначе потом придётся всё пересобирать
	- Виды:
		1. Вычислительный, не то что нам нужно
		2. Балансирующий (NLB), не то, что нам нужно
		3. Файловер (отказоустойчивый)
			- Перевести сервер (инстанс) из обычного режима в кластерный невозможно
			- Нужен дополнительный сетевой интерфейс только между 2-м серверам (Heartbeat). Испольщуется
			для постоянного опрашивания второго сервера на существование
			- Нужен общий дисковый массив, который имеет интерфейс, который позволяет подключить к 2-м машинам. Работает только с одной машиной, при необходимости вторая может отнять этот массив себе. Требует обязательно протоколы iSCSI, можно воспользоваться следующими эмуляторами StarWind iSCSI Target for Microsoft Windows компании Rocket Division Software, MySAN компании Nimbus Data Systems, или решениям с открытым кодом Openfiler. При этом следует иметь в виду, что программная эмуляция целевых томов iSCSI способна существенно снижать производительность в зависимости от используемого сервера и имеющейся сетевой конфигурации.
			- В кластерной конфигурации каждый экземпляр SQL Server должен иметь собственный диск,
			- Ещё между серверам есть раздел, который подключен между серверами. Там хранится конфигурация
			кластерного хозяйства
			- Каждому узлу необходим рабочий IP-адрес и дополнительный IP-адрес для сигнала активности с целью определения работоспособности. Как правило, IP-адрес для уведомления об активности принадлежит другой подсети.
			- Устанавливаем службу кластеризации на оба компьютера. Программные файлы ставятся на локальный
			диск, а общие данные на сетевой
			- Так как они работают с одними файлами, на одном узле сервер запущен (находится в активном режиме),
			а на втором сервер находится в пассивном режиме
			- На первом сервере создаётся виртуальный IP, с которым работает пользователь
			- Если на Активном сервере что-то сломалось, то начинается процедура перевода нагрузки на второй
			сервер (отнимает жесткие диски), перерегистрируется виртуальный адрес. Все это переключается
			совместно
			- Узлов может быть больше чем 2
			- Чтобы сервера использовались по полной, можно поместить в кластер ещё и Exchange и сделать
			на пассивном для SQL, активный Exchange и наоборот
			- Управление кластером происходит через панель управления WINDOWS
	- Условия для кластеризованной программы
		1. Не должна долго хранить данные в памяти
		2. Должна уметь ставиться раздельно. Программы локально, данные на сетевой диск
		3. Должна уметь работать по TCPIP
		4. Клиентское приложение должно быть написано таким образом, чтобы оно нормально относилось к
		задержкам восстановления базы
		5. Локальные или создаваемые по умолчанию системные учетные записи в кластерной установке использоваться не могут.
		6. Установить "Диспетчер хранилища для сетей SAN" (VDS)
	- Плюсы:
		1. Автоматическое решение всех 3-х задач
	- Минусы:
		1. Дорого
		2. Большое время переключения (Более 10 секунд, но это идеал обычно более 30)
		3. Сложно раздвинуть узлы на большое расстрояние
	- Установка
		1. В ролях сервера установить Microsoft Distributed Transaction Coordinator (MSDTC), в первом меню выберите Application Server. Установите флажок Distributed Transactions, при этом автоматически будут включены функции Incoming and Outgoing Remote Transactions и WS-Atomic Transactions. Отключите все лишние. На следующем экране система запрашивает, требуется ли использование сертификата SSL для шифрования транзакций WS-Atomic Transactions. Вы можете указать имеющийся сертификат или выбрать самоподписанный сертификат. После выбора предпочтительного параметра щелкните Next.
		2. После того как служба MSDTC будет установлена на всех узлах кластера, необходимо вручную объединить MSDTC в кластер. В Server Manager щелкните Add Feature в правой панели для вызова мастера установки служб. Выберите вариант Failover Clustering и щелкните Next.
		3. Для работы кластера необходимы редакии сервера Server 2008 Enterprise или Server 2008 Datacenter.
		4. Failover Clustering (то ли роль, то ли служба)
		5. На первом узле запустите Failover Cluster Manger (Start, All Programs, Administrative Tools, Failover Cluster Manage)
		6. Возможно, придется изменить настройки Windows Firewall, чтобы разрешить доступ по RPC к серверу
		7. Для успешной установки SQL Server 2008 в кластерной конфигурации необходимо, чтобы кластер успешно прошел все проверочные тесты. В менеджере Failover Cluster Manager щелкните ссылку Validate a configuration, расположенную в правом верхнем углу.
		8. После успешных текстов пора переходить к установке кластера. В Failover Cluster Manager щелкните ссылку Create a Cluster в правом верхнем углу
		9. Настройка MSDTC для кластера
			Для настройки службы MSDTC запустите Failover Cluster Manager и подключитесь к только что настроенному кластеру. Найдите пункт Services and Applications, щелкните на нем правой кнопкой мыши и выберите Configure an Applicaton из контекстного меню. На информационном экране, где приведен список доступных для выбора служб, щелкните Next.

			На следующем экране введите имя и IP-адрес, с которым будет связана MSDTC. В данном примере мы используем имя SQL01 DTC и адрес 10.3.0.6.

			Щелкните Next для выбора диска, на котором будут размещены файлы настройки MSDTC.

			Это должен быть отдельный диск, не используемый как кворум и не задействованный сервером SQL Server. К этому диску не предъявляется особых требований — 512 Мбайт или 1 Гбайт вполне достаточно. Щелкните Next для подтверждения и завершения настройки службы MSDTC.
		10. Cluster Disk Selection. Здесь следует указать, на каких дисках будут размещены файлы данных экземпляра SQL Server.
		11. Установка других узлов не отличается от установки первого узла, за исключением того, что в начале процесса установки необходимо отметить вариант Add Node to a SQL Server failover cluster. Ко всем остальным узлам кластера предъявляются те же требования, и программа установки выполняет проверку и установку всех компонентов.
		12. Добавляем в ресурсную группу первой ноды SQL Server Agent. Для этого на первой ноде выполняем следующие действия:
			В командной строке запускаем cluster restype "SQL Server Agent" /create /DLL:sqagtres.dll
			В ветке реестра «HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL10.MSSQLSERVER\ConfigurationState» меняем все значения переменных с «2» на «1»
			В менеджере Failover Cluster Management подключаемся к кластеру и в левой панели позиционируемся на первую и пока что единственную ресурсную группу. Дальше добавляем новый ресурс, для чего жмем ссылку «Add a resource» - «More resources…» - «Add SQL Server Agent». Заходим в свойства появившегося агента New SQL Server Agent и в списке зависимостей указываем имя агента – SQL Server Agent, зависимости – SQL Server, в свойствах указываем Имя виртуального сервера и название инстанса – MSSQLSERVER, после чего жмем «OK». Теперь мы можем перевести SQL Server Agent в оперативный режим – статус поменяется на Online.
			
-- Особенности
	1. Менять все настройки при кластерной конфигурации через Configuration Managment (так как прозрачно поменяется на всех нодах и во всех местах)

-- Основное
	- Отказоустойчивость на уровне службы
	- Сначала устанавливаем кластер на Windows, потом устанавливаем службы/ресурсы SQL Server
	- Одно хранилище, разные сервера
	- http://blogs.msmvps.com/gladchenko/2008/05/01/%d0%ba%d0%b0%d0%ba-%d0%b2%d0%ba%d0%bb%d1%8e%d1%87%d0%b8%d1%82%d1%8c-sql-server-2005-%d0%b2-%d0%ba%d0%bb%d0%b0%d1%81%d1%82%d0%b5%d1%80/
	
-- Требочания
	1. Все участники кластера должны быть членами одного домена
	2. Должны работать на основе одной платформы, одной версии, одной сборки, одинаковое железо
	3. Enterprise Version
	4. Shared Store
	5. Hotfixes (Windows2008R2 SP1 - KB 2545685, Windows2012 - KB 2784261)
	6. IP адрес и Имя кластера для инстанса и для MSDTC
	
-- Посмотреть детальные логи кластера
	- http://blogs.msdn.com/b/clustering/archive/2008/09/24/8962934.aspx
	- C:\tmp>cluster log /g /copy:logs /span:360 /Node:"srv-node-a4"
	
-- Установка, особенности
	1. Дать доступ на диски
	2. Root instance directory должен отличаться от расположения файлов БД,tempdb, backiup
	3. Не забыть что в AD должно быть зарегистрировано имя кластера для SQL Server
	4. SQL Server требует доступ к System Volume Informatio (скрытая папка). Если не получается установить по данной причину, нужно получить owner данной папки
	
-- Удаление, особенности
	1. При удалении ноды на сервере останавливается служба SQL Browser
	
-- Добавление ноды
	- To add a node to an existing SQL Server failover cluster, you must run SQL Server Setup on the node that is to be added to the SQL Server failover cluster instance. Do not run Setup on the active node.
	
	1. Insert the SQL Server installation media, and from the root folder, double-click Setup.exe. To install from a network share, navigate to the root folder on the share, and then double-click Setup.exe.
	2. The Installation Wizard will launch the SQL Server Installation Center. To add a node to an existing failover cluster instance, click Installation in the left-hand pane. Then, select Add node to a SQL Server failover cluster.
	3. The System Configuration Checker will run a discovery operation on your computer. To continue, Click OK. .
	4. On the Language Selection page, you can specify the language for your instance of SQL Server if you are installing on a localized operating system and the installation media includes language packs for both English and the language corresponding to the operating system. For more information about cross-language support and installation considerations, see Local Language Versions in SQL Server.
	5. To continue, click Next.
	6. On the Product key page, specify the PID key for a production version of the product. Note that the product key you enter for this installation must be for the same SQL Server edition as that which is installed on the active node.
	7. On the License Terms page, read the license agreement, and then select the check box to accept the licensing terms and conditions. To help improve SQL Server, you can also enable the feature usage option and send reports to Microsoft. To continue, click Next. To end Setup, click Cancel.
	8. The System Configuration Checker will verify the system state of your computer before Setup continues. After the check is complete, click Next to continue.
	9. On the Cluster Node Configuration page, use the drop-down box to specify the name of the SQL Server failover cluster instance that will be modified during this Setup operation.
	10. On the Server Configuration — Service Accounts page, specify login accounts for SQL Server services. The actual services that are configured on this page depend on the features you selected to install. For failover cluster installations, account name and startup type information will be pre-populated on this page based on settings provided for the active node. You must provide passwords for each account. For more information, see Server Configuration - Service Accounts and Configure Windows Service Accounts and Permissions.
	11. Security Note   Do not use a blank password. Use a strong password.
	12. When you are finished specifying login information for SQL Server services, click Next.
	13. On the Reporting page, specify the information you would like to send to Microsoft to improve SQL Server. By default, option for error reporting is enabled.
	14. The System Configuration Checker will run one more set of rules to validate your computer configuration with the SQL Server features you have specified.
	15. The Ready to Add Node page displays a tree view of installation options that were specified during Setup.
	16. Add Node Progress page provides status so you can monitor installation progress as Setup proceeds.
	17. After installation, the Complete page provides a link to the summary log file for the installation and other important notes. To complete the SQL Server installation process, click Close.
	18. If you are instructed to restart the computer, do so now. It is important to read the message from the Installation Wizard when you are done with Setup. For more information about Setup log files, see View and Read SQL Server Setup Log Files.
	
-- Удаление ноды
	- To remove a node from an existing SQL Server failover cluster, you must run SQL Server Setup on the node that is to be removed from the SQL Server failover cluster instance.
	
	1. Insert the SQL Server installation media. From the root folder, double-click setup.exe. To install from a network share, navigate to the root folder on the share, and then double-click Setup.exe.
	2. The Installation Wizard launches the SQL Server Installation Center. To remove a node to an existing failover cluster instance, click Maintenance in the left-hand pane, and then select Remove node from a SQL Server failover cluster.
	3. The System Configuration Checker will run a discovery operation on your computer. To continue, Click OK. .
	4. After you click install on the Setup Support Files page, the System Configuration Checker verifies the system state of your computer before Setup continues. After the check is complete, click Next to continue.
	5. On the Cluster Node Configuration page, use the drop-down box to specify the name of the SQL Server failover cluster instance to be modified during this Setup operation. The node to be removed is listed in the Name of this node field.
	6. The Ready to Remove Node page displays a tree view of options that were specified during Setup. To continue, click Remove.
	7. During the remove operation, the Remove Node Progress page provides status.
	8. The Complete page provides a link to the summary log file for the remove node operation and other important notes. To complete the SQL Server remove node, click Close. For more information about Setup log files, see View and Read SQL Server Setup Log Files.
	
-- Добавить к кластеру template роли SQL Server и SQL Server Agent	
	1. Запускаем PowerShell
	Import-Module FailoverClusters -- подключение модуля
	Add-ClusterResourceType "SQL Server Agent" C:\Windows\system32\SQAGTRES.DLL
	Add-ClusterResourceType "SQL Server" C:\Windows\system32\SQSRVRES.DLL

-- quorum/кворум
	/* конфигурация */ - /* мод */
	Odd number of nodes - Node Majority
	Even number of nodes (but not a multi-site cluster) - Node and Disk Majority
	Even number of nodes, multi-site cluster - Node and File Share Majority
	Even number of nodes, no shared storage - Node and File Share Majority
	Exchange CCR cluster (two nodes) - Node and File Share Majority
	
-- Cluster SQL Server Express
	1. Создать кластер
	2. Добавить ноды
	3. Установить на 1 ноду SQL Server Express на выделенный диск, но бинарные данные всё равно устанавливает по классическому пути
	4. Добавить порт 1433
	5. Включить протокол TCP\IP
	6. Отключить выделенный диск и активировать его на 2 ноде
	7. Произвести установку на выделенный диск второго экземпляра. Но потребуется удалить старые системные БД
	8. Порт + TCP\IP
	9. Перевести диск в offline
	10. Добавить диск к кластеру
	11. Создать пустую роль, дать роли имя и ip. Подключить диск и службу SQLEXPRESS
	12. Настроить зависимости SQLEXPRESS от других ресурсов, чтобы он не останавливался/запускался раньше времени
	13. Настроить сколько может быть failover у кластерной роли
	14. Влючаем SQLEXPRESS и тестируем переводы
	
	- Логи подключаются корректно
	- Могу быть ошибки в реестре и в поддержании синхронизации настроек (порт, протоколы) между разными нодами
