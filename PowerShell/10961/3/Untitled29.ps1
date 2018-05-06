ClS
[int]$Test9 = 3
$Test9

If ($Test9 -GT 3)
    {
        Write-Host "Раз"
    }
ElseIf ($Test9 -GT 1)
    {
        Write-Host "Два"
    }
ElseIf ($Test9 -GT -1)
    {
        Write-Host "Три"
    }
Else
    {
        Write-Host "Четыре"
    }