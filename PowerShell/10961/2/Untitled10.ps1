Get-PSDrive
Get-Command -Noun PSDrive
Get-Help New-PSDrive

Dir "HKCU:\Control Panel\PowerCfg"
New-PSDrive Power -PSProvider Registry -Root "HKCU:\Control Panel\PowerCfg"
Dir Power:\