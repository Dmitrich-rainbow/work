- https://blogs.msdn.microsoft.com/san/2011/12/02/updated-guidance-on-microsoft-mpio-settings/
- http://www.c-amie.co.uk/technical/mpio-overview/
- https://docs.microsoft.com/en-us/powershell/module/mpio/set-mpiosetting?view=win10-ps

Set-MPIOSetting -NewPathRecoveryInterval 5
Set-MPIOSetting -CustomPathRecovery Enabled
Set-MPIOSetting -NewPDORemovePeriod 5
Set-MPIOSetting -NewDiskTimeout 5