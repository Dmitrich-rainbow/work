
 - Посмотреть какие права ты имеешь whoami /priv
 
-- Upgrade Advizor 2014
	- требования:
		- Windows Server 2008+
		- Windows Installer 4.5
		- .NET Framework 4
		- MicrosoftSQL ServerTransact-SQL ScriptDom (не забывать что нужно именно x64)
		
-- Ключи запуска
	setup.exe /ACTION=INSTALL /SkipRules=RebootRequiredCheck
	setup.exe /ACTION=InstallFailoverCluster /SkipRules=RebootRequiredCheck
	setup.exe /ACTION=RemoveNode /SkipRules=RebootRequiredCheck
	setup.exe /ACTION=AddNode /SkipRules=RebootRequiredCheck
	SQLServer2012-KB3037255-x64.exe /SkipRules=RebootRequiredCheck
	E:\setup.exe /SkipRules=Cluster_VerifyForErrors /Action=AddNode
	Setup /SkipRules=Cluster_VerifyForErrors /Action=InstallFailoverCluster
	Setup /SkipRules=Cluster_VerifyForErrors /Action=CompleteFailoverCluster
	Setup /SkipRules=Cluster_VerifyForErrors /Action=AddNode
	setup.exe /SkipRules=RebootRequiredCheck /Action=RemoveNode	
	setup /ACTION=editionupgrade /SkipRules= EditionUpgradeMatrixCheck -- запустить обновление редакции и пропустить проверку
	
-- SQL Server 2005
	setup /template e:\temp\template.ini
	setup PIDKEY=graeg534gbrae5