ClS
Dir "C:\Windows" | Get-Member -MemberType Property

ClS
Dir "C:\Windows" | Select-Object -Property FullName, Extension

Dir "C:\Windows" | Select-Object -Property FullName, Extension, Length

Dir "C:\Windows" | Select-Object -Property Name, Length, @{n="Size in KB"; e={$PSItem.Length}}
Dir "C:\Windows" | Select-Object -Property Name, Length, @{n="Size in KB"; e={$_.Length / 1024}}

