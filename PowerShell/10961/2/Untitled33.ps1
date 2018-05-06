Get-Service | 
    ConvertTo-Html -Title "Список служб" -PreContent "<h1>Мои службы</h1>" | 
        Out-File "C:\Users\Administrator\Desktop\10961 (июль 2015)\2\Службы.html"

Get-Service | 
    ConvertTo-JSON | 
        Out-File "C:\Users\Administrator\Desktop\10961 (июль 2015)\2\Службы.JSON"

Get-Service | Out-GridView