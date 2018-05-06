New-Item "C:\File1.txt" -ItemType "File"
New-Item "C:\File10.txt" -ItemType "File"
New-Item "C:\File2.txt" -ItemType "File"

ClS
Dir C:\ | Sort-Object -Property Length, Name 