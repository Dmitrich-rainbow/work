http://nikpatel.net/2013/09/05/use-latin1_general_ci_as_ks_ws-collation-for-sharepoint-database-engine/
SharePoint uses the Latin1_General_CI_AS_KS_WS collation because the Latin1_General_CI_AS_KS_WS collation most closely matches the Microsoft Windows NTFS file system collation – http://support.microsoft.com/kb/2008668
[16:28:54] Ренат (Jet): И, если администратору фермы шарика нельзя просто так дать sysadmin на сервере БД, то ему надо хотя бы дать:
Dbcreator fixed server role.
Securityadmin fixed server role.
db_owner for all SharePoint databases.
Тогда он сам будет создавать нужные ему базы с нужными правами и свойствами