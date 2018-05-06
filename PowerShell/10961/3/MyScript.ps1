[CmdletBinding()]
Param(
[Parameter(Mandatory=$True)]
[string]$RootFolderName,

[string]$Ext = "*"

)

Write-Host ("Каталог: " + $RootFolderName)
Write-Host ("Расширение: " + $Ext)

$RootC = Dir $RootFolderName -Directory # Это массив папок верхнего уровня. Будем их перебирать.
# $RootC

$MaxCount = 0 # Тут будем запоминать максимальное найденное число податалогов
$MaxName = "" # Тут будем запоминать название папки с максимальным числом подкаталогов

ForEach ($F in $RootC) # Перебираем все каталоги верхнего уровня
    {
    $SubF = Dir -File ($F.FullName + "\*." + $Ext)

    if ($SubF.Count -gt $MaxCount) # Сравниваем число подпапок в текущем каталоге с папкой-"лидером"
        { # Если найден новый лидер гонки, запоминаем его параметры
        $MaxCount = $SubF.Count # Число подкаталогов у нового лидера
        $MaxName = $F.FullName # Название нового лидера
        }

    }

$MaxName # После перебора всех папок в этой переменной будет название папки-лидера