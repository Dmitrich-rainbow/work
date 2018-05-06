ClS
Dir "C:\Windows"     | 
Where-Object Length -GT 100000

Dir "C:\Windows"     | 
Where-Object Extension -EQ ".EXE"

Dir "C:\Windows"     | 
Where-Object Extension -CEQ ".EXE"

Dir "C:\Windows"     | 
Where-Object Name -Like "e*"

Dir "C:\Windows"     | 
Where-Object Name -Like "*a*b*"