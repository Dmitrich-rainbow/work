function Get-PCUptime {
 
param($computer)

Trap {write-host "Cannot Connect to $computer" -Foregroundcolor Red;
	  continue} 
 
$lastboottime = (Get-WmiObject -Class Win32_OperatingSystem -computername $computer -ea "SilentlyContinue").LastBootUpTime
 
$sysuptime = (Get-Date) – [System.Management.ManagementDateTimeconverter]::ToDateTime($lastboottime)

if ($lastboottime -ne $NULL){
	Write-Host “System($computer) is Uptime since : ” $sysuptime.days “days” $sysuptime.hours `
	“hours” $sysuptime.minutes “minutes” $sysuptime.seconds “seconds” -Foregroundcolor Gray;
	}
}