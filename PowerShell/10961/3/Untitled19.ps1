$SrvList = Get-Service
$SrvList | GM

$SrvList[10]
$SrvList[10].Status
$SrvList[10].Status.ToString().Length
$SrvList[10].Name.ToString().Length