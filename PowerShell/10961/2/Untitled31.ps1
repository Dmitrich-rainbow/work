ClS
Get-Service | Format-List -Property Name, Status 

Get-Service | Sort Status | Format-Wide -Property Name -Column 5 -GroupBy Status