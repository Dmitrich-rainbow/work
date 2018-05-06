Param(
[string]$FRoot = "C:\",
[string]$FNew = "Специалист4"
)

# Для заданной папки создать в каждой из её подпапок вложенную папку с названием "Специалист".


$Dir = Dir $FRoot -Directory
ForEach ($F in $Dir)
    {
    New-Item -Name $FNew -ItemType Directory -Path $F.FullName
    }
