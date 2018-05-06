Get-Command -Noun Item
Get-Help New-Item

New-Item "C:\MyFile.txt" -ItemType "File"

Get-Command -Noun Content
Get-Help Set-Content

Set-Content "C:\MyFile.txt" -Value "Specialist"
Dir C:\
Get-Content "C:\MyFile.txt" 