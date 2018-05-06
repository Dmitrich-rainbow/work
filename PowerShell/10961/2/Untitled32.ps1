Get-Command -Verb Export -Module Microsoft.PowerShell.Utility
Get-Command -Verb ConvertTo 
Get-Command -Verb Out 

Get-Content "C:\Users\Administrator\Desktop\10961 (июль 2015)\2\Службы.html"

Get-Content "C:\Users\Administrator\Desktop\10961 (июль 2015)\2\Службы.csv" |
    ConvertFrom-Csv

Get-Command -Verb Import