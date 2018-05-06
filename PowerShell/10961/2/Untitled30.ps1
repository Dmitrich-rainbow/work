ClS
Get-Service | FT Status, CanStop, CanShutdown, @{n="Имя"; e={$_.Name}; align="right"} -AutoSize 
Get-Help FT -Online