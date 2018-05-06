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
