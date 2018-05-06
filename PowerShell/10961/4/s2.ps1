Param(
[string]$FRoot = "C:\",
[string]$FNew = "Специалист3"
)

# Для заданной папки создать в каждой из её подпапок вложенную папку с названием "Специалист".

Dir $FRoot -Directory | 
    ForEach-Object CreateSubdirectory $FNew
