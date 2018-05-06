[int]$Test6 = 3
$Test6

$Test6 = 15

Dir C:\Windows | Select-Object -First $Test6

$Test6 * ($Test6 - 1)