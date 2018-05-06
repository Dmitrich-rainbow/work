Function Set-MyInfo
    {

[CmdletBinding()]
Param(
[Parameter(Mandatory=$True)]
[string]$FileName,
[Parameter(Mandatory=$True)]
[string]$Text)

    $Text | Out-File -FilePath $FileName

    }
############################################################
Function Get-MyInfo
    {

[CmdletBinding()]
Param(
[Parameter(Mandatory=$True)]
[string]$FileName
)

Get-Content -Path $FileName

    }

############################################################
Function Clear-MyInfo
    {
        Param(
        [Parameter(Mandatory=$True)]
        [string]$FileName
        )

    Remove-Item -Path $FileName
    }
#############################
ClS

Set-MyInfo -FileName "C:\MyFile.txt" -Text "Сочи-2014" # Записываем текст в файл
Get-MyInfo -FileName "C:\MyFile.txt"                   # Читаем текст из файла
Clear-MyInfo -FileName "C:\MyFile.txt"                 # Узаляем файл