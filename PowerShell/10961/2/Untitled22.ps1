Dir "C:\Windows" |
Where-Object -FilterScript { $_.Extension -Like ".exe" }

Dir "C:\Windows" |
Where-Object -FilterScript { $_.Extension -Like ".exe" -and $_.Name -like "h*" -and $_.Length -ge 100000 }


Dir "C:\Windows" |
Where { $_.Extension -Like ".exe" -and $_.Name -like "h*" -and $_.Length -ge 100000 }

Help Where-Object