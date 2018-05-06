Get-Service | Out-File "C:\Users\Administrator\Desktop\10961 (июль 2015)\1\Сервисы.txt"
Get-Service | Export-CSV "C:\Users\Administrator\Desktop\10961 (июль 2015)\1\Сервисы.csv"

Import-CSV "C:\Users\Administrator\Desktop\10961 (июль 2015)\1\Сервисы.csv"
Import-CSV "C:\Users\Administrator\Desktop\10961 (июль 2015)\1\Сервисы.csv" | Get-Member
Import-CSV "C:\Users\Administrator\Desktop\10961 (июль 2015)\1\Сервисы.csv" | Select-Object -First 1 | Format-Wide
Import-CSV "C:\Users\Administrator\Desktop\10961 (июль 2015)\1\Сервисы.csv" | Select-Object -First 1 

Import-CSV "C:\Users\Administrator\Desktop\10961 (июль 2015)\1\Сервисы.csv" | Select-Object -First 1 | ForEach-Object Start
Get-Service | Select-Object -First 1
