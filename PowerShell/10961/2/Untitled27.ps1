Dir C:\Windows | 
Where-Object Extension -EQ ".log" |
Get-Member -MemberType Method

Dir C:\Windows | 
Where-Object Extension -EQ ".log" |
ForEach-Object Delete

Dir C:\Windows\System32 | 
Where-Object Extension -EQ ".txt" |
ForEach-Object {$_.Delete()}

Get-Help ForEach-Object