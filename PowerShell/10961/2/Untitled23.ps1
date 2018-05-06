ClS
Dir "C:\Windows" |
Where-Object Extension -Like ".exe" |
Measure-Object -Property Length -Sum -Maximum -Minimum -Average