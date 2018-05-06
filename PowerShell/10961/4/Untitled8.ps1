[int]$A = 0

Try 
    {

    $A + 1
    $A * 2
    10 / $A
    $A - 1

    Write-Host "Ошибок не было."

    }
Catch
    {

#    Write-Host "Случилась ошибка!"
#    Write-Error "Случилась ошибка!"
    Write-Warning "Случилась ошибка!"

    $Error| GM
    #$Error.categoryInfo

    }