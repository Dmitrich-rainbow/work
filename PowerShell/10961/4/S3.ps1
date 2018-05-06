[CmdletBinding()]
Param(
[int]$A,
[int]$B,
[switch]$C
)

#ClS

Write-Verbose ("Параметр A: " + $A)
$A | Get-Member | Write-Debug

Write-Verbose ("Параметр B: " + $B)
$B | Get-Member | Write-Debug 

Write-Verbose ("Параметр C: " + $C)