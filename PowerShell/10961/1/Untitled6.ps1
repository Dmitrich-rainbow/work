Get-Service | Get-Member -MemberType Method
Get-Service | Select-Object -First 3 | ForEach-Object Stop
Get-Service | Select-Object -First 3 | ForEach-Object Start
