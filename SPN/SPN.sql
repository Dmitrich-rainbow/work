-- spn/Kerberos
	https://dbasimple.blogspot.ru/2015/04/spn-ms-sql-server.html
	https://mssqlwiki.com/2013/12/09/sql-server-connectivity-kerberos-authentication-and-sql-server-spn-service-principal-name-for-sql-server/
	
	SPN - Это способ сопоставить учетную запись Windows, ответственную за запуск экземпляра службы, с сервером и службой. Такое сопоставление необходимо, так как многие клиенты формируют SPN из имени узла и порта, к которому подключается клиент. Для взаимной проверки подлинности Kerberos уровень безопасности Windows должен определить учетную запись, которую использует служба. Благодаря сопоставлению SPN, определенному в Active Directory (AD), учетная запись Windows, ответственная за службу, может быть удостоверена и использована для проверки подлинности Kerberos. По этой причине многие службы регистрируют имена SPN; например, Microsoft SQL Server регистрирует SPN, если используется протокол TCP/IP с проверкой подлинности Kerberos, что позволяет отказаться от NTLM.

	Вот ссылка на сайт Microsoft - https://msdn.microsoft.com/en-us/library/ms677949(v=vs.85).aspx
	
	-- Дать права одной командой
		dsacls "CN=sa_mssql-djin_msk,OU=Test&ServiceUsers,DC=msk,DC=rian" /G SELF:RPWP;”servicePrincipalName” -- OU - organization unit (где лежит пользователь)
		
		setspn -A MSSQLSvc/MSK-DB01-AXCLU.bk.local:1433 bk\sql
	setspn -A MSSQLSvc/MSK-DB01-AXCLU.bk.local:63818 bk\sql
	- Если прописать хост в ручную не удаётся, то можно выдать хосту/учётки права на уровне домена Write servicePrincipalName и Read servicePrincipalName
	- Если нужна локальная учётка 
		setspn -A MSSQLSvc/MSK-DB01-AXCLU.bk.local:63818 bk\hostname

-- Выдать права легко
	1. Приложение Kerberos Configuration Manager
	2. Через консоль ADSI
	
-- Errors/Ошибки
	https://blogs.technet.microsoft.com/askds/2008/06/13/understanding-kerberos-double-hop/