ClS
Dir "C:\Windows"     | 
Select-Object -Property Name, Length, @{n="Size in KB"; e={$_.Length / 1024}}     | 
Sort-Object -Property "Size in KB" -Descending |
Select-Object -Skip 10 -First 10